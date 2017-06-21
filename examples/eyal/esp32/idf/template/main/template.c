/* Based of this template
 *	https://github.com/espressif/esp-idf-template
*/

#include "freertos/FreeRTOS.h"
#include "esp_wifi.h"
#include "esp_system.h"
#include "esp_event.h"
#include "esp_event_loop.h"
#include "nvs_flash.h"
#include <sys/time.h>
#include <string.h>	// memset()
#include <rom/uart.h>	// uart_tx_wait_idle()
#include <freertos/event_groups.h>

static struct timeval app_start;

static EventGroupHandle_t event_group;
const int HAVE_WIFI = BIT0;

esp_err_t event_handler(void *ctx, system_event_t *event)
{
    struct timeval tv;

    gettimeofday (&tv, NULL);
    tv.tv_sec  -= app_start.tv_sec;
    tv.tv_usec -= app_start.tv_usec;
    if (tv.tv_usec < 0) {
	    tv.tv_usec += 1000000;
	    --tv.tv_sec;
    }

    printf ("%ld.%06ld Event %d\n", tv.tv_sec, tv.tv_usec, event->event_id);

    if (SYSTEM_EVENT_STA_GOT_IP == event->event_id)
        xEventGroupSetBits(event_group, HAVE_WIFI);

    return ESP_OK;
}

void app_main(void)
{
    gettimeofday (&app_start, NULL);
    printf ("%d.%06d started at %ld.%06ld\n", 0, 0, app_start.tv_sec, app_start.tv_usec );

    event_group = xEventGroupCreate();

    nvs_flash_init();
    tcpip_adapter_init();

#if 001		// provide static IP
    printf ("using static IP\n");
    ESP_ERROR_CHECK( tcpip_adapter_dhcpc_stop(TCPIP_ADAPTER_IF_STA) ); 
    tcpip_adapter_ip_info_t ip_info_new;
    memset (&ip_info_new, 0, sizeof(ip_info_new));
    ip4addr_aton("192.168.2.65", &ip_info_new.ip);
    ip4addr_aton("255.255.255.0", &ip_info_new.netmask);
    ip4addr_aton("192.168.2.7", &ip_info_new.gw);
    ESP_ERROR_CHECK( tcpip_adapter_set_ip_info(TCPIP_ADAPTER_IF_STA, &ip_info_new) );
#else
    printf ("using DHCP\n");
#endif

    ESP_ERROR_CHECK( esp_event_loop_init(event_handler, NULL) );
    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK( esp_wifi_init(&cfg) );
    ESP_ERROR_CHECK( esp_wifi_set_storage(WIFI_STORAGE_RAM) );
    ESP_ERROR_CHECK( esp_wifi_set_mode(WIFI_MODE_STA) );
    wifi_config_t sta_config = {
        .sta = {
            .ssid = AP_SSID,		// from CFLAGS
            .password = AP_PASS,	// from CFLAGS
            .bssid_set = false,
            .channel = 6
        }
    };
    ESP_ERROR_CHECK( esp_wifi_set_config(WIFI_IF_STA, &sta_config) );
    ESP_ERROR_CHECK( esp_wifi_start() );
    ESP_ERROR_CHECK( esp_wifi_connect() );

    xEventGroupWaitBits(event_group, HAVE_WIFI,
	false, false, 5000 / portTICK_PERIOD_MS);	// 5s timeout

    fflush(stdout);		// allow prints to finish
    uart_tx_wait_idle(CONFIG_CONSOLE_UART_NUM);
    ets_delay_us (5000);

    esp_deep_sleep(2*1000000);
}

