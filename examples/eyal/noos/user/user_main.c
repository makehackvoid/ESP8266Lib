#include "user_config.h"
#include <espconn.h>

static uint32		runCount = 0;
static uint8		cpu_mhz = 160;
static struct espconn	espconn;
static esp_udp		udp;
static uint32		sleep_time;
static uint32		start_time;
static uint32		wifi_time;
static uint32		read_time;
static uint32		send_time;
static uint16		vdd;
static uint16		adc;
static sint32		temp;

#define SSID		"SSID"
#define PASS		"PASSPHRASE"

static const uint8		SERVER[4] =
	{192,168,3,4};		// e4
//	{192,168,3,7};		// e7
//	{192,168,3,249};	// el Virtual Box
//#define SERVER		env->gateway

#define PORT		31883

// #define DUMMY_MSG	"show esp-witty times=s0.000,w0.000,c0,t0.000 adc=0.000 vdd=0.000 0.0000"
#define MSG_EOL		"\n"		// for ncat, or ""
#define WAIT_TIMEOUT_MS	(5*1000000)	// 5s

#define RTCMEM_MAGIC		0xf0fafee
#define RTCMEM_MAGIC_ADDR	64
#define RTCMEM_COUNT_ADDR	65
#define RTCMEM_LAST_ADDR	66
#define RTCMEM_TOTAL_ADDR	67

static void
die(void)
{
	uint32	now;
	uint32	v;

	now = time_now();
	logPrintf("### sleeping %ds ###\n", sleep_time);

	system_rtc_mem_write (RTCMEM_LAST_ADDR, &now, 4);
	system_rtc_mem_read (RTCMEM_TOTAL_ADDR, &v, 4);
	v += now/1000;
	system_rtc_mem_write (RTCMEM_TOTAL_ADDR, &v, 4);

//	system_deep_sleep_set_option(2);	// no RFCAL
	system_deep_sleep(1000000*sleep_time);
}

////////////////////////////// send message /////////////////////////

#define FMSG(title, res, val) \
	do { \
		strncat(msg, title, sizeof(msg)); \
		strncat(msg, ffp((res), (val)), sizeof(msg)); \
	} while (0)

static char *
format_msg(void)
{
	static uint8	msg[80];
	uint32	v;

#ifdef DUMMY_MSG
	strncpy (msg, DUMMY_MSG, sizeof(msg));
#else
	system_rtc_mem_read (RTCMEM_LAST_ADDR, &v, 4);
////   	os_snprintf(msg, sizeof(msg), "show %s %3d times=L%s",
	os_sprintf (msg,              "show %s %3d times=L%s",
		env->clientID, runCount, ffp(3, v/1000));

	system_rtc_mem_read (RTCMEM_TOTAL_ADDR, &v, 4);
	FMSG (",T",    0, v/1000);
	FMSG (",s",    3, start_time/1000);
	FMSG (",z",    0, cpu_mhz);
	FMSG (",r",    3, read_time/1000);
	FMSG (",w",    3, wifi_time/1000);
	FMSG (",S",    3, send_time/1000);
	FMSG (",t",    3, (time_now()-start_time)/1000);
	FMSG (" adc=", 3, adc);
	FMSG (" vdd=", 3, vdd);
	FMSG (" ",     4, temp);
#endif

	logPrintf("msg='%s'\n", msg);

	strncat(msg, MSG_EOL, sizeof(msg));

	return(msg);
}
#undef FMSG

static os_timer_t	send_delay_timer[1];
static void
send_delay(void *arg)
{
	os_timer_disarm(send_delay_timer);
	espconn_delete(&espconn);	// needed?

	die();
}

static void
udp_sent_callback(void *arg)
{
	logPrintf("UDP sent\n");

	send_time = time_now() - send_time;
	os_timer_setfn(send_delay_timer, (os_timer_func_t *)send_delay, NULL);
	os_timer_arm(send_delay_timer, env->udp_grace_ms, 0);
}

static int
set_ip (int force)
{
	struct ip_info	info[1];

	wifi_station_dhcpc_stop();

	if (!force && wifi_get_ip_info(STATION_MODE, info) && 0 != info->ip.addr) {
		logPrintf("have wifi_get_ip_info\n");
		return 1;
	}

	logPrintf("wifi_set_ip_info\n");
	IP4_ADDR(&info->ip,
		env->clientIP[0], env->clientIP[1], env->clientIP[2], env->clientIP[3]);
	IP4_ADDR(&info->gw,
		env->gateway[0], env->gateway[1], env->gateway[2], env->gateway[3]);
	IP4_ADDR(&info->netmask,
		env->netmask[0], env->netmask[1], env->netmask[2], env->netmask[3]);
	if (!wifi_set_ip_info(STATION_IF, info)) {
		errPrintf("wifi_set_ip_info failed\n");
		return 0;
	}

	return 1;
}

static int
set_ap (int force)
{
	struct station_config sta_conf[1];

	if (!force && wifi_station_get_config_default(sta_conf) && sta_conf->ssid[0] != 0) {
		logPrintf("have wifi_station_get_config_default\n");
		return 1;
	}

	logPrintf("station config\n");
	memset (sta_conf, 0, sizeof(sta_conf));
	sta_conf->bssid_set = 0;
	os_sprintf(sta_conf->ssid, SSID);
	os_sprintf(sta_conf->password, PASS);
	logPrintf("wifi_station_set_config\n");
	if (!wifi_station_set_config(sta_conf)) {
		errPrintf("wifi_station_set_config failed\n");
		return 0;
	}

	return 1;
}

static void
setup_connection(void)
{
	memset (&udp, 0, sizeof(udp));
//	udp.local_port = espconn_port();	// ncat does not like this
//	errPrintf("espconn_port=%d\n", udp.local_port);
	memcpy(udp.remote_ip, SERVER, sizeof(udp.remote_ip));
	udp.remote_port = PORT;
	logPrintf("connect to %d.%d.%d.%d:%d\n",
	udp.remote_ip[0], udp.remote_ip[1], udp.remote_ip[2], udp.remote_ip[3],
		udp.remote_port);

	memset (&espconn, 0, sizeof(espconn));
	espconn.type = ESPCONN_UDP;
	espconn.state = ESPCONN_NONE;
	espconn.proto.udp = &udp;
	espconn.sent_callback = udp_sent_callback;
//	espconn.link_cnt = ?;
//	espconn.reserve = NULL;
	if (espconn_create(&espconn)) {
		errPrintf("espconn_create failed\n");
		die();
	}
}

static void
have_wifi(void)
{
	char	*psent;

	wifi_time =  time_now() - wifi_time;
	logPrintf("have_wifi after %dus\n", wifi_time);

	setup_connection();

	psent = format_msg();
	send_time = time_now();
	if (espconn_sendto(&espconn, psent, strlen(psent))) {
		errPrintf("espconn_sendto failed\n");
		die();
	}
}

////////////////////////////// get wifi /////////////////////////

static int
wifi_reset()
{
	errPrintf ("wifi_reset ###\n");

	wifi_station_disconnect();
	wifi_set_opmode(STATION_MODE);
	if (!set_ap(1))
		return 0;
	if (!set_ip(1))
		return 0;
	wifi_station_set_auto_connect(1);
	wifi_station_connect();

	return 1;
}

static int		tries = 0;
static os_timer_t	wait_for_wifi_timer[1];
static uint32		timeout;

static void
wait_for_wifi(void *arg)
{
	uint8		status;
	uint32		now = time_now();

//	wifi_station_connect();

	if (STATION_GOT_IP == (status = wifi_station_get_connect_status())) {
		os_timer_disarm(wait_for_wifi_timer);
		have_wifi();
	} else if (now > timeout) {
		os_timer_disarm(wait_for_wifi_timer);
		errPrintf("wifi wait timeout status=%d %dus\n", status, now-wifi_time);
		if (1 == tries) {	// reset and retry
			if (!wifi_reset())
				errPrintf("wifi_reset failed\n");
			++tries;
			timeout = now + WAIT_TIMEOUT_MS;
			os_timer_arm(wait_for_wifi_timer, 1, 1);	// 1ms, rearmed
			return;
		}
		die();
	}
}

static void
have_temp(void)
{
	wifi_time =  time_now();
	read_time = wifi_time - read_time;

	tries = 1;
	timeout = wifi_time + WAIT_TIMEOUT_MS;
	os_timer_setfn(wait_for_wifi_timer, (os_timer_func_t *)wait_for_wifi, NULL);
	os_timer_arm(wait_for_wifi_timer, 1, 1);	// 1ms, rearmed
}

////////////////////////////// read temp /////////////////////////

static os_timer_t	wait_for_temp_timer[1];
static void
wait_for_temp(void *arg)
{
	if (!ds18b20_setup(env->ow_pin))
		return;
	temp = ds18b20_read(env->ow_addrs[0]);
	if (BAD_RET != temp) {
		os_timer_disarm(wait_for_temp_timer);
		have_temp();
	}
}

static void
read_temp (void)
{
	read_time = time_now();
	if (!ds18b20_setup(env->ow_pin) && !ds18b20_setup(env->ow_pin)) {
		logPrintf("no onewire on gpio %d\n", env->ow_pin);
		temp = 850000;	// failed twice
		have_temp();
		return;
	}

	os_timer_setfn(wait_for_temp_timer, (os_timer_func_t *)wait_for_temp, NULL);
	os_timer_arm(wait_for_temp_timer, 1, 1);
}

void
set_rtcmem(void)
{
	uint32	v;

	system_rtc_mem_read (RTCMEM_MAGIC_ADDR, &v, 4);
	if (v != RTCMEM_MAGIC) {
		errPrintf("initialising rtcmem\n");
		v = runCount = 1;
		system_rtc_mem_write (RTCMEM_COUNT_ADDR, &v, 4);
		v = 0;
		system_rtc_mem_write (RTCMEM_LAST_ADDR, &v, 4);
		system_rtc_mem_write (RTCMEM_TOTAL_ADDR, &v, 4);
		v = RTCMEM_MAGIC;
		system_rtc_mem_write (RTCMEM_MAGIC_ADDR, &v, 4);
	} else {
		system_rtc_mem_read (RTCMEM_COUNT_ADDR, &v, 4);
		runCount = ++v;
		system_rtc_mem_write (RTCMEM_COUNT_ADDR, &v, 4);
	}
}

////////////////////////////// main program /////////////////////////

void
test_station(void)
{
	if (!setup_env())
		die();

	sleep_time = env->sleep_time;

//// DEBUG overrides start ////
	sleep_time = 2;
//// DEBUG overrides end   ////

	set_rtcmem();

	logPrintf("auto_connect is %s\n",
		wifi_station_get_auto_connect () ? "on" : "off");
	logPrintf("DHCPC is %s\n",
		DHCP_STARTED == wifi_station_dhcpc_status () ? "on" : "off");

	(void)set_ip(0);	// start wifi in the background

	read_temp();
}

void
user_init(void)
{
	start_time = time_now();

	cpu_mhz = set_cpu_freq(cpu_mhz);

//	logPrintf("SDK version: %s\n", system_get_sdk_version());	// already shown
	logPrintf("APP version: %s built: %s %s\n", BUILD_DATE, __DATE__, __TIME__);

	adc = read_tout(0) * 120/10;	// ratio 12.0
	vdd = read_vdd();

	test_station();
}

