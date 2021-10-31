
#include <WiFi.h>
#include <WiFiUdp.h>

#include <rom/rtc.h>  // for DEEPSLEEP_RESET and rtc_get_reset_reason()

#include "config.h"

#define CPU_MHz         80
#define SLEEP_TIME_S    10      // s
#define SLEEP_TIME_US   (1000000*SLEEP_TIME_S)
#define WIFI_TIMEOUT_MS  5000
#define COUNT_LIMIT     0       // non-zero to stop after so many messages

RTC_DATA_ATTR static ulong count = 0;

static WiFiUDP udp;

static int haveWiFi;
static ulong time_wifi_us;


void setup()
{
  setCpuFrequencyMhz(CPU_MHz);

  Serial.begin(115200);
  Serial.print("\nI am "); Serial.println(CL_NAME);

  haveWiFi = 0;
  time_wifi_us = micros();
  if (DEEPSLEEP_RESET != rtc_get_reset_reason(0)) {   // woke up
    Serial.println("WiFi.config");
    if (!WiFi.config(CL_IP, SVR_GW, SVR_SUB, SVR_GW, SVR_GW)) {    // we really do not need DNS
      Serial.println("configure WiFi failed");
      return;
    }

    WiFi.mode(WIFI_STA);

//  WiFi.persistent(true);        // TESTING, no change
//  WiFi.setAutoConnect(true);    // TESTING, no change
//  WiFi.setAutoReconnect(true);  // TESTING, no change

    Serial.println("WiFi.begin(...)");
    uint8_t bssid[6] = AP_BSSID;
    WiFi.begin(AP_SSID, AP_PASS, 6, bssid, true);
  } else {
    Serial.println("WiFi.begin()");
    WiFi.begin();
  }
 
  Serial.println("connecting");
  for (int w = 0; !WiFi.isConnected();) {
    if ((w += 10) > WIFI_TIMEOUT_MS) {
      Serial.println("connection timeout");
      return;
    }
    delay(10);
  }
  time_wifi_us = micros() - time_wifi_us;
  haveWiFi = 1;
  Serial.print("connected after "); Serial.print(time_wifi_us/1000); Serial.println("ms");

  btStop();

  udp.begin(SVR_PORT);  // use same port locally
}

static char message[500];    // too large for auto
static int mlen;

static void sendMessage (void)
{
  if (haveWiFi) {
    Serial.print("sending to IP ");
    Serial.print(SVR_IP);
    Serial.print(":");
    Serial.print(SVR_PORT);
    Serial.print(" using AP ");
    Serial.println(AP_SSID);
  
    udp.beginPacket(SVR_IP,SVR_PORT);
    udp.write((unsigned char *)message, mlen);
    udp.endPacket();
  
    delay (10);    // time for UDP packet to go. Is there an API for wifi tx flush?
    Serial.println("sent");
  } else
    Serial.println("no WiFi, not sent");

  Serial.println((char *)message);
}

void loop ()
{
  ++count;
  if (COUNT_LIMIT && count >= COUNT_LIMIT) {     // limit number of loops?
    delay(SLEEP_TIME_S*1000);
    return;
  }

  mlen = snprintf (message, sizeof(message),
      "%3lu: Hello World! WiFi took %lums",
      count, time_wifi_us/1000);
  
  sendMessage();

  ulong timeEnd = micros();
  timeEnd = (timeEnd >= SLEEP_TIME_US) ? 0 : SLEEP_TIME_US - timeEnd;
  Serial.print("sleeping ");  Serial.print(timeEnd/1000); Serial.println("ms");
  Serial.flush();

  esp_sleep_enable_timer_wakeup (timeEnd < 10 ? 10 : timeEnd);
  esp_deep_sleep_start();
}
