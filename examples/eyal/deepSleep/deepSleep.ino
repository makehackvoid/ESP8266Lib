/*
 * This sketch used to measure the Arduino performance on the esp8266.
 */

#include "deepSleep.h"

#include <WiFiUDP.h>

static WiFiUDP            UDP;

static bool               woken_up = true;
static uint32_t           time_start;   // us
static uint32_t           time_wifi;    // us
static uint32_t           time_save;    // us

static uint32_t           time_udp_bug; // ms

ADC_MODE(ADC_VCC);
static uint16_t           vdd;          // mv

static float              temp[rangeof(addr)]; // degrees Celcius
static bool               wifing = false;

static int
show_frac(char *buf, int bsize, const char *title, byte precision, long v)
{
  long scale = 1;
  switch (precision) {
  case 4:
    scale *= 10;
  case 3:
    scale *= 10;
  case 2:
    scale *= 10;
  case 1:
    scale *= 10;
    break;
  case 0:
  default:
    return snprintf (buf, bsize, "%s%lu", title, v);
  }
  char  fmt[16];
  int n = snprintf (fmt, sizeof(fmt), "%%s%%s%%ld.%%0%dld", precision);
  if (n < 0 || n >= sizeof(fmt)) {
    if (bsize > 0)
      *buf = '\0';
    return bsize;
  }

  char *sign;
  if (v < 0) {
    sign = "-";
    v = -v;
  } else
    sign = "";

  long int u = v/scale;
  long int f = v -u*scale;
 
  return snprintf (buf, bsize, fmt, title, sign, u, f);
}

/* first invocation will set the pin HIGH
 */
static void
toggle()
{
  static byte level = 0;  // LOW

  digitalWrite(TIME_PIN, (level = ~level) ? HIGH : LOW);
}

static void
mark_start()
{
  /* after power up the pin is HIGH
   */
  pinMode(TIME_PIN, OUTPUT);
  digitalWrite(TIME_PIN, LOW);    // start marker
}

static void
mark_end()
{
  digitalWrite(TIME_PIN, HIGH);   // end marker
  delay(1);
  digitalWrite(TIME_PIN, LOW);
}

static bool
set_up_wifi(void)
{
  time_wifi = micros();

#ifdef SERIAL_CHATTY
Serial.print("before set_up_wifi ssid='");
Serial.print(WiFi.SSID());
Serial.print("', lip=");
Serial.print(WiFi.localIP());
Serial.print(", ip=");
Serial.println(ip);
#endif

#ifdef WIFI_SSID
  if (WiFi.SSID() != WIFI_SSID) {
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
//    if (!WiFi.getAutoConnect()) {
//Serial.println("WiFi.setAutoConnect");
//      WiFi.setAutoConnect(true);
//    }
  }
#endif

#ifndef WIFI_USE_DHCP
  if (WiFi.localIP() != ip)
    WiFi.config(ip, gw, dns);     // set static IP
  if (WiFi.hostname() != HOSTNAME)
    WiFi.hostname(HOSTNAME);
#endif

#ifdef SERIAL_CHATTY
Serial.print("after set_up_wifi ssid='");
Serial.print(WiFi.SSID());
Serial.print("', lip=");
Serial.print(WiFi.localIP());
Serial.print(", ip=");
Serial.println(ip);
#endif

  return true;
}

static bool
wait_for_wifi(void)
{
  int timeout = WIFI_TIMEOUT_MS;
  byte wstatus;
  byte old_wstatus = 100;
  Serial.print(WL_CONNECTED);
  Serial.print(": ");
  while ((wstatus = WiFi.status()) != WL_CONNECTED) {
    if (old_wstatus != wstatus) {
      Serial.print(wstatus);
      old_wstatus = wstatus;
    }
    toggle();
    delay(WIFI_WAIT_MS);
    if ((timeout -= WIFI_WAIT_MS) <= 0) {
      Serial.println(" no WiFi");
      ++rtcMem.failHard;
      return false;
    }
  }
  time_wifi = micros() - time_wifi;
  digitalWrite(TIME_PIN, LOW);
  Serial.print(wstatus);
  Serial.print(" time_wifi=");
  Serial.println(time_wifi);

#ifdef SERIAL_CHATTY
  Serial.print(" have WiFi in ");
  Serial.print(time_wifi);
  Serial.print("us, ip=");
  Serial.println(WiFi.localIP());
#endif

  return true;
}

static bool
send_udp(char *message)
{
  UDP.beginPacket(WIFI_SERVER, WIFI_PORT);
  UDP.write(message);
  UDP.endPacket();
  time_udp_bug = millis() + UDP_DELAY_MS; // do not sleep earlier than this

  return true;
}

#define CHECK \
do { \
  if (n < 0 || n >= l) return false; \
  p += n; \
  l -= n; \
} while (0)
#define SHOW(...) \
do { \
  n = show_frac (p, l, __VA_ARGS__); \
  CHECK; \
} while (0)
#define PRINT(...) \
do { \
  n = snprintf (p, l, __VA_ARGS__); \
  CHECK; \
} while (0)
  
static bool
format_message(char *buf, unsigned int bsize)
{
  char *p = buf;
  unsigned int l = bsize;
  int n;

  PRINT ("%s %s %lu",
    WIFI_OP, HOSTNAME, rtcMem.runCount);
    
#ifdef SEND_TIMES
  SHOW (" times=L", 3, rtcMem.lastTime/1000);
  SHOW (",T", 3, rtcMem.totalTime);
  SHOW (",s", 3, time_start/1000);
  SHOW (",u", 3, 0);      // no user time
  SHOW (",r", 3, time_read/1000);
  SHOW (",w", 3, time_wifi/1000);
  SHOW (",F", 3, 0);      // no "First"
  SHOW (",S", 3, (micros() - time_save)/1000);
  SHOW (",d", 3, 0);      // no "dofile"
  SHOW (",t", 3, (micros() - time_start)/1000);
#endif
  
#ifdef SEND_STATS
  PRINT (" stats=fs%lu,fh%lu,fr%lu",
    rtcMem.failSoft, rtcMem.failHard, rtcMem.failRead);
#endif

#ifdef SEND_ADC
  SHOW (" adc=", 3, 0);   // no adc
#endif

  SHOW (" vdd=", 3, vdd);

  for (int i = 0; i < rangeof(temp); ++i)
    SHOW ((i > 0 ? "," : " "), 4, (long)(temp[i]*10000));

  return true;
}

static bool
send_message(void)
{
  char message[200];

  time_save = micros();

  if (!format_message(message, sizeof(message)))
    return false;

  if (wifing) {
    if (!send_udp(message))
      return false;
  }

#ifdef PRINT_MESSAGE
  Serial.println(message);
#endif

  return true;
}

static bool
read_vdd(void)
{
//vdd = readvdd33();
  vdd = system_get_vdd33();

  return true;
}

static bool
do_stuff()
{
  if (wifing && !set_up_wifi())
    return false;

  if (!read_temp(rangeof(addr), addr, temp)) // read while wifi comes up
    return false;

  if (!read_vdd()) // read while wifi comes up
    return false;

  if (wifing && !wait_for_wifi())
    return false;

  if (!send_message())
    return false;

  return true;
}

static bool
do_nothing()
{
  if (wifing) {
    if (!set_up_wifi())
      return false;
    if (!wait_for_wifi())
      return false;
  }

  return true;
}

#define WAKEUP_US         (uint32_t)(1000*WAKEUP_MS*TIME_SPEED)
#define DSLEEP_US         (uint32_t)(1000*DSLEEP_MS*TIME_SPEED)
#define SLEEP_US          (uint32_t)(1000*SLEEP_MS*TIME_SPEED)

static void
cycle(void)
{
  ++rtcMem.runCount;
  wifing = (rtcMem.wakeType != WAKE_RF_DISABLED);

//Serial.print("### cycle, wifing=");
//Serial.println(wifing);
  show_state();

#ifdef SERIAL_CHATTY
  Serial.print("start at ");
  Serial.print(time_start);
  Serial.println("us");
#endif

#ifdef DO_NOTHING
  bool did_ok = do_nothing();
#else
  bool did_ok = do_stuff();   // put actual work there
#endif

#ifdef SERIAL_CHATTY
  uint32_t time_now = micros();
  Serial.print("sleeping ");
  Serial.print(SLEEP_MS);
  Serial.print("ms at ");
  Serial.print(time_now);
  Serial.print("(+");
  Serial.print(time_now-time_start);
  Serial.println(")us");
#endif

  uint32_t now = millis();
  if (now < time_udp_bug)
    delay (time_udp_bug - now);

  uint32_t last_wake_type = rtcMem.wakeType;
  rtcMem.wakeType = WIFI_ON_RATE
    ? ((rtcMem.runCount%WIFI_ON_RATE) ? WAKE_RF_DISABLED : WAKE_RFCAL)
    : WAKE_RF_DISABLED;

  rtc_commit();
  mark_end();

  uint32_t time_so_far = woken_up
        ? (micros() + WAKEUP_US)
        : (micros() - time_start);

//Serial.print("time_so_far+DS=");
//Serial.println(time_so_far+DSLEEP_US);

  if (time_so_far+DSLEEP_US < SLEEP_US) {   // sleep until next cycle
//  Serial.println("### normal dsleep");
    ESP.deepSleep(SLEEP_US-(time_so_far+DSLEEP_US), rtcMem.wakeType);
    return;
  }

  if (last_wake_type != rtcMem.wakeType) {  // must change mode now
    Serial.println("### mode change dsleep");

    mark_end();
    ESP.deepSleep(1, rtcMem.wakeType);
    return;
  }

  if (time_so_far < SLEEP_US) {             // just wait until next cycle
    delay((SLEEP_US-time_so_far)/1000);
    return;
  }

  Serial.println("### no dsleep");         // we are late, start new cycle NOW
}

void
setup() {
  time_start = micros();

  mark_start();

  Serial.begin(SERIAL_BAUD);
  Serial.println("");

  pinMode(MAGIC_PIN, INPUT_PULLUP);
  if (LOW == digitalRead(MAGIC_PIN)) {
    Serial.println("Stopped by magic");
    ESP.deepSleep(0xFFFFFFFFUL, WAKE_RF_DISABLED); // about 80 minutes
  }

//Serial.println("### setup");

  if (!rtc_init()) {  // first time
    Serial.println("### first run dsleep");
    show_state();
    ESP.deepSleep(1, rtcMem.wakeType);
  }
}

void
loop() {
  if (!woken_up)
    time_start = micros();

  cycle();

  woken_up = false;
}

