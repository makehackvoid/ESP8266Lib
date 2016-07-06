#ifndef deepSleep_user_config_H
#define deepSleep_user_config_H
/*
 * User configuration
 */

#define OW_PIN            4         // D2=GPIO4 one-wire data pin
static byte               addr[][8] = {
  {40,  95, 190, 242,   6,   0,   0,  94}, // DS18b20 IDs
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

/*
 * The following three are wall clock ms
 */

/*
 * Without WiFi the program reports  78ms at the start, but the DSO shows 136ms.
 * With    WiFi the program reports 245ms at the start, but the DSO shows 300ms.
 */
#define WAKEUP_MS         55        // unaccounted wakeup time [measured]

/*
 * On the DSO we see sleep starting 104ms after program end.
 */
#define DSLEEP_MS         104       // time to enter dsleep [measured]

#define SLEEP_MS          10000     // time between wakeups [wall clock]

/*
 * RTC/WallClock ratio for this host [measured]
 */
#define TIME_SPEED        1.0175    // esp-12c, 60s cycle

/*
 * The following _MS are in RTC units
 */

#define UDP_DELAY_MS      10        // work around SDK UDP bug
#define WIFI_WAIT_MS      1         // how often to check wifi when waiting
#define WIFI_TIMEOUT_MS   (10*1000) // how long to wait before giving up
#define WIFI_ON_RATE      6         // WiFi on every n cycles, 1=always, 0=never

//#define                   DO_NOTHING

#define SEND_TIMES                  // include "times=" in message
#define SEND_STATS                  // include "stats=" in message
#define SEND_ADC                    // include "adc=" in message
//#define PRINT_MESSAGE               // print message on console

#define WIFI_OP           "store"   // or "show"

#endif
