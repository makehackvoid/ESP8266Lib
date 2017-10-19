#include "udp.h"
#include "wifi.h"

#include <sys/socket.h>
#include <esp_wifi.h>
#include <esp_event_loop.h>	// esp_event_loop_init()
#include <nvs_flash.h>

// best to provide in CFLAGS: AP_SSID AP_PASS MY_IP
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

#ifdef MY_IP					// client IP

#ifndef MY_NM
#define MY_NM			"255.255.255.0"	// netmask
#endif

#ifndef MY_GW
#define MY_GW			SVR_IP		// gateway
#endif

#define USE_DHCPC		0		// use static IP
#else // ifdef MY_IP
#define USE_DHCPC		1		// use dhcp
#endif // ifndef MY_IP

void wifi_send_message (char * message, int mlen)
{
	int mysocket;
	struct sockaddr_in remote_addr;

	mysocket = socket(AF_INET, SOCK_DGRAM, 0);
	remote_addr.sin_family = AF_INET;
	remote_addr.sin_port = htons(SVR_PORT);
	remote_addr.sin_addr.s_addr = inet_addr(SVR_IP);

Log ("sending '%s'", message);
	toggle(2);
	sendto(mysocket, message, mlen, 0,
		(struct sockaddr *)&remote_addr, sizeof(remote_addr));
}

static esp_err_t set_ip (void)
{
#if !USE_DHCPC
Log ("tcpip_adapter_dhcpc_stop");
	DbgR (tcpip_adapter_dhcpc_stop(TCPIP_ADAPTER_IF_STA));

Log ("tcpip_adapter_set_ip_info ip=%s nm=%s gw=%s", MY_IP, MY_NM, MY_GW);
	tcpip_adapter_ip_info_t ip_info_new;
	memset (&ip_info_new, 0, sizeof(ip_info_new));
	ip4addr_aton(MY_IP, &ip_info_new.ip);
	ip4addr_aton(MY_NM, &ip_info_new.netmask);
	ip4addr_aton(MY_GW, &ip_info_new.gw);
	DbgR (tcpip_adapter_set_ip_info(TCPIP_ADAPTER_IF_STA, &ip_info_new));
#endif	/* if !USE_DHCPC */

	return ESP_OK;
}

static esp_err_t event_handler (void *ctx, system_event_t *event)
{
Log("event_handler: SYSTEM_EVENT %d", event->event_id);
	switch(event->event_id) {
	case SYSTEM_EVENT_STA_START:
		toggle(1);
Log ("SYSTEM_EVENT_STA_START");
		break;
	case SYSTEM_EVENT_STA_CONNECTED:
		toggle(1);
		time_wifi_us = gettimeofday_us() - time_wifi_us;
{
		wifi_ap_record_t wifidata;
		DbgR (esp_wifi_sta_get_ap_info(&wifidata));
		rssi = wifidata.rssi;
		channel = event->event_info.connected.channel;
Log("SYSTEM_EVENT_STA_CONNECTED rssi=%d channel=%d", rssi, channel);
}
		break;
	case SYSTEM_EVENT_STA_GOT_IP:
		toggle(1);
{
char ip[16], nm[16], gw[16];
Log ("SYSTEM_EVENT_STA_GOT_IP ip=%s nm=%s gw=%s",
	ip4addr_ntoa_r(&event->event_info.got_ip.ip_info.ip, ip, sizeof(ip)),
	ip4addr_ntoa_r(&event->event_info.got_ip.ip_info.netmask, nm, sizeof(nm)),
	ip4addr_ntoa_r(&event->event_info.got_ip.ip_info.gw, gw, sizeof(gw)));
}
Log("xEventGroupSetBits");
		xEventGroupSetBits(event_group, HAVE_WIFI);
		break;
	case SYSTEM_EVENT_STA_DISCONNECTED:
Log ("SYSTEM_EVENT_STA_DISCONNECTED reason %d", event->event_info.disconnected.reason);
// see https://dl.espressif.com/doc/esp-idf/latest/api-guides/wifi.html#wi-fi-reason-code
		xEventGroupClearBits(event_group, HAVE_WIFI);

		if (sent || ++retry_count > 1)
			xEventGroupSetBits(event_group, NO_WIFI);
		else {
Log ("esp_wifi_connect retry");
			DbgR (esp_wifi_connect());	// try once again
		}
		break;
	default:
Log ("ignoring SYSTEM_EVENT %d", event->event_id);
		break;
	}

	return ESP_OK;
}

esp_err_t wifi_setup (void)
{
#if 000		// no effect
Log ("esp_phy_load_cal_and_init");
	esp_phy_load_cal_and_init();	// no effect
#endif

Log ("esp_event_loop_init");
	DbgR (esp_event_loop_init(event_handler, NULL));

Log ("tcpip_adapter_init");
	tcpip_adapter_init();

Log ("nvs_flash_init");
	DbgR (nvs_flash_init());

	wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
Log ("esp_wifi_init");
	DbgR (esp_wifi_init(&cfg));

	DbgR (set_ip());

	if (!woke_up) {	// otherwise this was saved in flash
Log ("esp_wifi_set_storage(WIFI_STORAGE_FLASH)");
		DbgR (esp_wifi_set_storage(WIFI_STORAGE_FLASH));

Log ("esp_wifi_set_mode(WIFI_MODE_STA)");
		DbgR (esp_wifi_set_mode(WIFI_MODE_STA));

		wifi_config_t wifi_config = {
			.sta = {
				.ssid     = AP_SSID,
				.password = AP_PASS,
				.bssid_set = 0,
				.channel = 6
			},
		};
Log ("esp_wifi_set_config(ESP_IF_WIFI_STA) ap='%s' ch=%d",
	wifi_config.sta.ssid, wifi_config.sta.channel);
		DbgR (esp_wifi_set_config(ESP_IF_WIFI_STA, &wifi_config));

//Log ("esp_wifi_set_auto_connect(true)");
//		DbgR (esp_wifi_set_auto_connect(true));
	}

Log ("esp_wifi_start");
	time_wifi_us = gettimeofday_us();
	DbgR (esp_wifi_start());

Log ("esp_wifi_connect");
	DbgR (esp_wifi_connect());

	return ESP_OK;
}

esp_err_t wifi_disconnect (void)
{
Log ("esp_wifi_disconnect");
	return esp_wifi_disconnect();
}

