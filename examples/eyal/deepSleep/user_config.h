#ifndef deepSleep_user_config_H
#define deepSleep_user_config_H
/*
 * User configuration
 */

#define OW_PIN            4         // D2=GPIO4 one-wire data pin
static byte               addr[8] = {40, 24, 158, 118, 6, 0, 0, 129}; // DS18b20 ID

#define TIME_PIN          13        // D7=GPIO13 output timing pin

#define SERIAL_BAUD       115200    // use 74880 to see the SDK messages
//#define SERIAL_CHATTY

#define WIFI_SSID         "esp"    // your access point
#define WIFI_PASSWORD     "esp8266wifi"

#define WIFI_SERVER       "192.168.2.7"
//#define WIFI_SERVER       "192.168.173.1"  // on Windows
#define WIFI_PORT         21883

//#define WIFI_USE_DHCP
#define HOSTNAME          "d1-mini"
static IPAddress          ip(192,168,2,51);  // static IP config
static IPAddress          gw(192,168,2,7);
static IPAddress          dns(192,168,2,7);

#define UDP_DELAY_MS      10        // Work around SDK UDP bug
#define SLEEP_MS          300       // DS18B20 needs 600ms to convert
#define WIFI_WAIT_MS      1         // how often to check wifi when waiting
#define WIFI_TIMEOUT_MS   (10*1000) // how long to wait before giving up

#endif
