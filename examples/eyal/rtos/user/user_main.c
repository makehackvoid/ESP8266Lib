#include "esp_common.h"
#include "user_config.h"
#include <espconn.h>

extern char	*ffp(int res, uint32 v);
extern uint32	time_now(void);
extern char *	time_now_f(void);
extern uint16	read_tout(int unused);
extern uint16	read_vdd(void);
extern uint8	set_cpu_freq(uint8 freq);

static struct espconn	espconn;
static esp_udp		udp;
static uint32		start_time;
static uint32		wifi_time;
static uint32		wifi_count;
static uint16		vdd;
static uint16		adc;

#define SSID		"SSID"				//// EDIT
#define PASS		"PASS"				//// EDIT

// on 'e4' I run
//	ncat -l4u 31883
// or, to measure timing:
//	ncat -l4u 31883 | while read msg ; do echo "`date +%T.%N` $msg" ; done

static uint8		e4[4] = {192,168,3,4};		//// EDIT
#define SERVER		e4
//#define SERVER		env->gateway

#define PORT		31883		// for ncat, or [1|2]1883
#define MSG_EOL		"\n"		// for ncat, or ""

static void
die(void)
{
	logPrintf("%s ### sleeping 2s ###\n", ffp(6, time_now()));
//	system_deep_sleep_set_option(2);	// no RFCAL
	system_deep_sleep(2*1000000);
	vTaskDelete(NULL);
}

// show esp-witty times=s0.083,w1.000,c17,t2.070 adc=0.418 vdd=3.460 0.0000

static char *
format_msg(void)
{
	static uint8	msg[80];

       	snprintf(msg, sizeof(msg), "show %s times=s%s",
		env->clientID, ffp(3, start_time/1000));

	strncat(msg, ",w", sizeof(msg));
	strncat(msg, ffp(3, wifi_time/1000), sizeof(msg));

	strncat(msg, ",c", sizeof(msg));
	strncat(msg, ffp(0, wifi_count), sizeof(msg));

	strncat(msg, ",t", sizeof(msg));
	strncat(msg, ffp(3, (time_now()-start_time)/1000), sizeof(msg));

	strncat(msg, " adc=", sizeof(msg));
	strncat(msg, ffp(3, adc), sizeof(msg));

	strncat(msg, " vdd=", sizeof(msg));
	strncat(msg, ffp(3, vdd), sizeof(msg));

	strncat(msg, " 0.0000", sizeof(msg));	// temp

	logPrintf("msg='%s'\n", msg);

	strncat(msg, MSG_EOL, sizeof(msg));

	return(msg);
}

static int
set_ip (int force)
{
	struct ip_info	info[1];

	if (!force && wifi_get_ip_info(STATION_MODE, info) && 0 != info->ip.addr) {
		printf("have wifi_get_ip_info\n");
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
		printf("wifi_set_ip_info failed\n");
		return 0;
	}
	wifi_station_dhcpc_stop();

	return 1;
}

static int
set_ap (int force)
{
	struct station_config sta_conf[1];

	if (!force && wifi_station_get_config_default(sta_conf) && sta_conf->ssid[0] != 0) {
		printf("have wifi_station_get_config_default\n");
		return 1;
	}

	logPrintf("station config\n");
	memset (sta_conf, 0, sizeof(sta_conf));
	sta_conf->bssid_set = 0;
	sprintf(sta_conf->ssid, SSID);
	sprintf(sta_conf->password, PASS);
	logPrintf("wifi_station_set_config\n");
	if (!wifi_station_set_config(sta_conf)) {
		printf("wifi_station_set_config failed\n");
		return 0;
	}

	return 1;
}

static int
wifi_reset()
{
	logPrintf ("\n### wifi_reset ###\n");

	wifi_station_disconnect();
	set_ip(1);
	wifi_set_opmode(STATION_MODE);
	set_ap(1);
	wifi_station_connect();

	return 1;
}

static void
udp_sent_callback(void *arg)
{
	logPrintf("UDP sent\n");
	espconn_delete(&espconn);	// needed?

	die();
}

static int
setup_connection(void)
{
	memset (&udp, 0, sizeof(udp));
//	udp.local_port = esconn_port();
	memcpy(udp.remote_ip, SERVER, sizeof(SERVER));
	udp.remote_port = PORT;

	memset (&espconn, 0, sizeof(espconn));
	espconn.type = ESPCONN_UDP;
	espconn.state = ESPCONN_NONE;
	espconn.proto.udp = &udp;
	espconn.sent_callback = udp_sent_callback;
//	espconn.link_cnt = ?;
//	espconn.reserve = NULL;
	if (espconn_create(&espconn)) {
		printf("espconn_create failed\n");
		return 0;
	}

	return 1;
}

#include "freertos/task.h"

static int
wait_for_wifi(void)
{
	uint8		status;

//wifi_station_connect();

	wifi_time =  time_now();
uint32 timeout = time_now() + 5*1000000;
	for (wifi_count = 0;; ++wifi_count) {
//uint32 vTaskDelay_time;
//vTaskDelay_time =  time_now();
	       if (STATION_GOT_IP == (status = wifi_station_get_connect_status()))
		       break;
		if (time_now() > timeout) {
//		if (wifi_count > 300) {
			printf("wifi wait timeout %d %d\n", status, time_now()-wifi_time);
			return 0;
		}
//printf(">>> %d %d before \n", wifi_count, vTaskDelay_time - wifi_time);
		vTaskDelay(10 / portTICK_RATE_MS);
//		taskYIELD();
//printf(">>> %d %d after\n", wifi_count, time_now() - vTaskDelay_time);
//printf(">>> %d loop %d %d \n", wifi_count,  vTaskDelay_time, time_now() - vTaskDelay_time);
	}
	wifi_time =  time_now() - wifi_time;
	logPrintf(">>> %d %d done\n", wifi_count, wifi_time);
//printf(">>> %d %d done %d\n", wifi_count, wifi_time, time_now());

	return 1;
}

static void
send_message(void)
{
	char *	psent = format_msg();

	if (espconn_sendto(&espconn, psent, strlen(psent))) {
		printf("espconn_sendto failed\n");
		die();
	}
}

void
test_sta_task_delay(void *pvParameters)
{
	logPrintf ("test_sta_task_delay: status=%d\n", wifi_station_get_connect_status());

	if (!setup_env())
		die();

	wifi_station_dhcpc_stop();
//	wifi_station_set_auto_connect(1);

	logPrintf("auto_connect is %s\n",
		wifi_station_get_auto_connect () ? "on" : "off");
	logPrintf("DHCPC is %s\n",
		DHCP_STARTED == wifi_station_dhcpc_status () ? "on" : "off");

	if (!set_ip(0)) {
		wifi_reset();
		if (!set_ip(0))
			die();
	}

        if (!wait_for_wifi()) {
		wifi_reset();
		if (!wait_for_wifi())
			die();
	}

// the following delay is required or no packets are sent (and no error is indicated)!
	logPrintf (">>> before stupid vTaskDelay\n");
	vTaskDelay(260 / portTICK_RATE_MS);
	logPrintf (">>> after  stupid vTaskDelay\n");
// 260 y
// 250 y mostly
// 240 y/n
// 230 n
// 220 n
// 200 n

	if (!setup_connection())
		die();

	send_message();
}

void
user_init(void)
{
	start_time = time_now();
//	set_cpu_freq(80);

	adc = read_tout(0) * 120/10;	// ratio 12.0
	vdd = read_vdd();

//	logPrintf("portTICK_RATE_MS=%d\n", portTICK_RATE_MS);	// is 10

	xTaskCreate(test_sta_task_delay, "test_sta_task", 256, NULL, 2, NULL);
}

