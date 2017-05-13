#include <esp_deep_sleep.h>
#include <esp_wifi.h>
#include <esp_event_loop.h>
#include <sys/socket.h>
//#include <lwip/udp.h>

#define AP_SSID   "SSID"
#define AP_PASS   "PASS"
#define SVR_IP    "192.168.2.7"
#define SVR_PORT  21883

#define MY_IP     "192.168.2.62"
#define MY_NM     "255.255.255.0"
#define MY_GW     SVR_IP

#define SLEEP_S   5
#define GRACE_MS  10    // 5ms is too short

#define USE_DHCPC 0     // 0=no

static int mysocket;
static struct sockaddr_in remote_addr;
static RTC_DATA_ATTR int n;

static void send_msg(void) {
      char msg[20];

      snprintf (msg, sizeof(msg), "show esp-32a %d", n);
      mysocket = socket(AF_INET, SOCK_DGRAM, 0);
      remote_addr.sin_family = AF_INET;
      remote_addr.sin_port = htons(SVR_PORT);
      remote_addr.sin_addr.s_addr = inet_addr(SVR_IP);
Serial.print(micros());
Serial.println(" Sending");
      sendto(mysocket, msg, strlen(msg), 0,
        (struct sockaddr *)&remote_addr, sizeof(remote_addr));
Serial.print(micros());
Serial.println(" Sent");
      ++n;
      delay(GRACE_MS);
      esp_deep_sleep(SLEEP_S*1000000);      
}

static esp_err_t event_handler(void *ctx, system_event_t *event)
{
    switch(event->event_id) {
    case SYSTEM_EVENT_STA_START:
Serial.print(micros());
Serial.println(" SYSTEM_EVENT_STA_START");

#if !USE_DHCPC
Serial.print(micros());
Serial.println(" tcpip_adapter_dhcpc_stop");
      tcpip_adapter_dhcpc_stop(TCPIP_ADAPTER_IF_STA);

Serial.print(micros());
Serial.println(" tcpip_adapter_set_ip_info");
      tcpip_adapter_ip_info_t ip_info_new;
      memset (&ip_info_new, 0, sizeof(ip_info_new));
      ip4addr_aton(MY_IP, &ip_info_new.ip);
      ip4addr_aton(MY_NM, &ip_info_new.netmask);
      ip4addr_aton(MY_GW, &ip_info_new.gw);
      tcpip_adapter_set_ip_info(TCPIP_ADAPTER_IF_STA, &ip_info_new);
#endif

Serial.print(micros());
Serial.println(" esp_wifi_connect");
      esp_wifi_connect();
      break;
    case SYSTEM_EVENT_STA_CONNECTED:
Serial.print(micros());
Serial.println(" SYSTEM_EVENT_STA_CONNECTED");
      break;
    case SYSTEM_EVENT_STA_GOT_IP:
Serial.print(micros());
Serial.print(" SYSTEM_EVENT_STA_GOT_IP ip=");
Serial.print   (ip4addr_ntoa(&event->event_info.got_ip.ip_info.ip));
Serial.print(" nm=");
Serial.print   (ip4addr_ntoa(&event->event_info.got_ip.ip_info.netmask));
Serial.print(" gw=");
Serial.println(ip4addr_ntoa(&event->event_info.got_ip.ip_info.gw));
      send_msg();
      break;
    case SYSTEM_EVENT_STA_DISCONNECTED:
Serial.print(micros());
Serial.println(" SYSTEM_EVENT_STA_DISCONNECTED");
      esp_wifi_connect();
      break;
    default:
Serial.print(micros());
Serial.print(" ignoring SYSTEM_EVENT ");
Serial.println(event->event_id);
      break;
    }
    return ESP_OK;
}

void setup() {
  Serial.begin(115200);
  Serial.println("");

Serial.print(micros());
Serial.println(" tcpip_adapter_init");
  tcpip_adapter_init();

Serial.print(micros());
Serial.println(" esp_event_loop_init");
  esp_event_loop_init(event_handler, NULL);

Serial.print(micros());
Serial.println(" esp_wifi_init");
  wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
  esp_wifi_init(&cfg);

//  struct station_config sta_config;
//  wifi_station_set_config(&sta_config);

Serial.print(micros());
Serial.println(" esp_wifi_set_mode");
  esp_wifi_set_mode(WIFI_MODE_STA);

/*
Serial.print(micros());
Serial.println(" esp_wifi_set_config");
  wifi_config_t wifi_config = {.sta = {AP_SSID, AP_PASS}};
  esp_wifi_set_config(ESP_IF_WIFI_STA, &wifi_config);
*/

Serial.print(micros());
Serial.println(" esp_wifi_start");
  esp_wifi_start();

Serial.print(micros());
Serial.println(" setup end");
}

// the loop function runs over and over again forever
void loop() {
  delay(1*1000);
}
