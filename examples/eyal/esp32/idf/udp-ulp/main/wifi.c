#include "udp.h"
#include "wifi.h"

#include <sys/socket.h>
#include <esp_wifi.h>
#include <esp_event.h>		// esp_event_loop_init()
#include <nvs_flash.h>

#ifndef AP_SSID
#error undefined AP_SSID
#endif

#ifndef AP_PASS
#error undefined AP_SSID
#endif

#ifndef SVR_IP
#define SVR_IP			"192.168.2.7"	// server IP
#endif

#ifndef SVR_PORT
#define SVR_PORT		21883		// server port
#endif

#ifndef USE_DHCPC				// client IP

#ifndef MY_NM
#define MY_NM			"255.255.255.0"	// netmask
#endif

#ifndef MY_GW
#define MY_GW			SVR_IP		// gateway
#endif

#endif // ifndef USE_DHCPC

#define WIFI_TIMEOUT_MS		5000	// time to wait for WiFi connection

//extern int rssi;
//extern RTC_DATA_ATTR int channel;

static uint64_t wifi_start_us;

void wifi_send_message (char * message, int mlen)
{
	int mysocket;
	struct sockaddr_in remote_addr;

	mysocket = socket(AF_INET, SOCK_DGRAM, 0);
	remote_addr.sin_family = AF_INET;
	remote_addr.sin_port = htons(SVR_PORT);
	remote_addr.sin_addr.s_addr = inet_addr(SVR_IP);

Log ("sending to %s:%d: '%s'", SVR_IP, SVR_PORT, message);
	toggle(2);
	sendto(mysocket, message, mlen, 0,
		(struct sockaddr *)&remote_addr, sizeof(remote_addr));
}

static esp_err_t set_ip (void)
{
#ifndef USE_DHCPC
	char my_ip[] = "123.123.123.123";

Log ("tcpip_adapter_dhcpc_stop");
	DbgR (tcpip_adapter_dhcpc_stop(TCPIP_ADAPTER_IF_STA));

	snprintf (my_ip, sizeof(my_ip), "%s.%d", MY_SUBNET, MY_HOST);
Log ("tcpip_adapter_set_ip_info ip=%s nm=%s gw=%s", my_ip, MY_NM, MY_GW);
	tcpip_adapter_ip_info_t ip_info_new;
	memset (&ip_info_new, 0, sizeof(ip_info_new));
	ip4addr_aton(my_ip, &ip_info_new.ip);
	ip4addr_aton(MY_NM, &ip_info_new.netmask);
	ip4addr_aton(MY_GW, &ip_info_new.gw);
	DbgR (tcpip_adapter_set_ip_info(TCPIP_ADAPTER_IF_STA, &ip_info_new));
#endif	/* ifndef USE_DHCPC */

	return ESP_OK;
}

static void have_wifi(void)
{
	Log("have WiFi");

	wifi_ap_record_t ap_info;
	esp_wifi_sta_get_ap_info(&ap_info);
	rssi = ap_info.rssi;
	channel = ap_info.primary;
Log("connection info: rssi=%d channel=%d", rssi, channel);

	esp_netif_ip_info_t ip_info;
	esp_netif_get_ip_info(esp_netif_get_handle_from_ifkey("WIFI_STA_DEF"), &ip_info);
Log ("station info: ip=" IPSTR " nm=" IPSTR " gw=" IPSTR,
	IP2STR(&ip_info.ip),
	IP2STR(&ip_info.netmask),
	IP2STR(&ip_info.gw));

Log("xEventGroupSetBits (HAVE_WIFI)");
	xEventGroupSetBits(event_group, HAVE_WIFI);
}

//static esp_err_t event_handler (void *ctx, system_event_t *event)
static void event_handler(void *arg, esp_event_base_t event, int32_t event_id, void *data)
{
Log("event_handler: SYSTEM_EVENT %d", event_id);
	switch(event_id) {
	case SYSTEM_EVENT_STA_START:
		toggle(1);
Log ("SYSTEM_EVENT_STA_START");
		break;
	case SYSTEM_EVENT_STA_CONNECTED:
		toggle(1);
		time_wifi_us = gettimeofday_64() - wifi_start_us;
Log("SYSTEM_EVENT_STA_CONNECTED after %lums", time_wifi_us/1000);
#ifndef USE_DHCPC	// treat this as SYSTEM_EVENT_STA_GOT_IP event
		have_wifi();
#endif
		break;
	case SYSTEM_EVENT_STA_GOT_IP:
		toggle(1);
if (0) {
const ip_event_got_ip_t *event = (const ip_event_got_ip_t *) data;
Log ("SYSTEM_EVENT_STA_GOT_IP ip=" IPSTR " nm=" IPSTR " gw=" IPSTR,
	IP2STR(&event->ip_info.ip),
	IP2STR(&event->ip_info.netmask),
	IP2STR(&event->ip_info.gw));
}
		have_wifi();
		break;
	case SYSTEM_EVENT_STA_DISCONNECTED:
{
		wifi_event_sta_disconnected_t* disconnected = (wifi_event_sta_disconnected_t*) data;
Log ("SYSTEM_EVENT_STA_DISCONNECTED reason %d", disconnected->reason);
// see https://dl.espressif.com/doc/esp-idf/latest/api-guides/wifi.html#wi-fi-reason-code
}
		xEventGroupClearBits(event_group, HAVE_WIFI);

		if (sent || ++retry_count > 1)
			xEventGroupSetBits(event_group, NO_WIFI);
		else {
Log ("esp_wifi_connect retry");
			/*DbgR*/ (esp_wifi_connect());	// try once again
		}
		break;
	default:
Log ("ignoring SYSTEM_EVENT %d", event_id);
		break;
	}

	return ;	//ESP_OK;
}

esp_err_t wifi_setup (void)
{
#if 000		// no effect
Log ("esp_phy_load_cal_and_init");
	esp_phy_load_cal_and_init();	// no effect
#endif

Log ("esp_event_loop_create_default");
	DbgR(esp_event_loop_create_default());
Log ("esp_netif_create_default_wifi_sta");
	esp_netif_create_default_wifi_sta();

Log("esp_event_handler_register");
	DbgR(esp_event_handler_register(WIFI_EVENT,
		ESP_EVENT_ANY_ID,
		&event_handler,
		NULL));

//Log ("esp_event_loop_init");
//	DbgR (esp_event_loop_init(event_handler, NULL));

//Log ("tcpip_adapter_init");
//	tcpip_adapter_init();

Log ("esp_netif_init");
	esp_netif_init();

Log ("nvs_flash_init");
	DbgR (nvs_flash_init());

	wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
Log ("esp_wifi_init");
	DbgR (esp_wifi_init(&cfg));

	DbgR (set_ip());

	if (1||!woke_up) {	// otherwise this was saved in flash
Log ("esp_wifi_set_storage(WIFI_STORAGE_FLASH)");
		DbgR (esp_wifi_set_storage(WIFI_STORAGE_FLASH));

Log ("esp_wifi_set_mode(WIFI_MODE_STA)");
		DbgR (esp_wifi_set_mode(WIFI_MODE_STA));

		wifi_config_t wifi_config = {
			.sta = {
				.ssid     = AP_SSID,
				.password = AP_PASS,
				.bssid_set = 0,
				.channel = channel
			},
		};
Log ("esp_wifi_set_config(ESP_IF_WIFI_STA) ap='%s' ch=%d",
	wifi_config.sta.ssid, wifi_config.sta.channel);
		DbgR (esp_wifi_set_config(ESP_IF_WIFI_STA, &wifi_config));

//Log ("esp_wifi_set_auto_connect(true)");
//		DbgR (esp_wifi_set_auto_connect(true));
	}

Log ("esp_wifi_start");
	wifi_start_us = gettimeofday_64();
	DbgR (esp_wifi_start());

Log ("esp_wifi_connect");
	DbgR (esp_wifi_connect());

	return ESP_OK;
}

esp_err_t wait_for_wifi (void)
{
	EventBits_t bits;

Log("xEventGroupWaitBits(HAVE_WIFI|NO_WIFI)");
	xEventGroupWaitBits(event_group, HAVE_WIFI|NO_WIFI,
		false, false, WIFI_TIMEOUT_MS / portTICK_PERIOD_MS);
	bits = xEventGroupGetBits (event_group);
	if (0 == bits)
		LogR (ESP_FAIL, "WiFi timed out, aborting");
	if (!(HAVE_WIFI & bits))
		LogR (ESP_FAIL, "no WiFi, aborting");
//Log ("have WiFi");

	return ESP_OK;
}

esp_err_t wifi_disconnect (void)
{
Log ("esp_wifi_disconnect");
	return esp_wifi_disconnect();
}

/*
 * In components/esp_phy/src/phy_init.c after line 190 insert:
 *
 * uint8_t read_phy_state()
 * {
 *    return s_phy_access_ref;
 * }
*/

void stop_wifi (void)
{
	uint8_t read_phy_state(void);
	struct timeval tv0;
	struct timeval tv1;
	struct timeval tv2;

	gettimeofday(&tv0, NULL);
	while (0 != read_phy_state()) {}
	gettimeofday(&tv1, NULL);

	esp_wifi_stop();
	esp_wifi_deinit();
	gettimeofday(&tv2, NULL);

	uint ms1 = (tv1.tv_sec-tv0.tv_sec)*1000 + (tv1.tv_usec-tv0.tv_usec)/1000;
	uint ms2 = (tv2.tv_sec-tv1.tv_sec)*1000 + (tv2.tv_usec-tv1.tv_usec)/1000;
Log ("stop_wifi: %ums (drain) %ums (stop)", ms1, ms2);
}

