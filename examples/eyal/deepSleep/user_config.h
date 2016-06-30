#ifndef deepSleep_user_config_H
#define deepSleep_user_config_H
/*
 * User configuration
 */

#define OW_PIN            4         // D2=GPIO4 one-wire data pin
static byte               addr[][8] = {
  {40, 197,  62, 118,   6,   0,   0,  60}, // DS18b20 IDs
  {40,  24, 158, 118,   6,   0,   0, 129},
  {40,  62,   6, 242,   6,   0,   0, 219},
  {40,   4,  99, 242,   6,   0,   0,  58},
  {40,  95, 190, 242,   6,   0,   0,  94},
};

#define MAGIC_PIN          5        // D1=GPIO5  magic pin
#define TIME_PIN          14        // D5=GPIO14 output timing pin

#define SERIAL_BAUD       115200    // use 74880 to see the SDK messages
//#define SERIAL_CHATTY

#define WIFI_SSID         "esp"    // your access point
#define WIFI_PASSWORD     "esp8266wifi"

#define WIFI_SERVER       "192.168.2.7"
//#define WIFI_SERVER       "192.168.173.1" // on Windows
#define WIFI_PORT         21883

//#define WIFI_USE_DHCP
#define HOSTNAME          "esp-12c"
static IPAddress          ip(192,168,2,52);  // static IP config
static IPAddress          gw(192,168,2,7);
static IPAddress          dns(192,168,2,7);

#define UDP_DELAY_MS      10        // work around SDK UDP bug
#define WAKEUP_MS         60        // unaccounted wakeup time [measured]
#define DSLEEP_MS         110       // time to enter dsleep [measured]
#define TIME_RATE         (60/58.8) // RTC/WallClock for this host [measured]

#define SLEEP_MS          (60*1000) // time between wakeups
#define WIFI_WAIT_MS      1         // how often to check wifi when waiting
#define WIFI_TIMEOUT_MS   (10*1000) // how long to wait before giving up
#define WIFI_ON_RATE      3         // WiFi on every n cycles, 1=always

//#define                   DO_NOTHING

#define WIFI_OP           "store"   // or "show"

#endif
