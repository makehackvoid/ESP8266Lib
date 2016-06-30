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
show_frac(char *buf, int bsize, byte precision, long v)
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
    return snprintf (buf, bsize, "%lu", v);
  }
  char  fmt[16];
  sprintf (fmt, "%%s%%ld.%%0%dld", precision);

  char *sign;
  if (v < 0) {
    sign = "-";
    v = -v;
  } else
    sign = "";

  long int u = v/scale;
  long int f = v -u*scale;
 
  return snprintf (buf, bsize, fmt, sign, u, f);
}

/* first invocation will set the pin HIGH
 */
static void
toggle()
{
  static byte level = 0;  // LOW

  digitalWrite(TIME_PIN, (level = ~level) ? HIGH : LOW);
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
  int i = WIFI_TIMEOUT_MS;
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
    if ((i -= WIFI_WAIT_MS) <= 0) {
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
  time_udp_bug = millis() + UDP_DELAY_MS;

  return true;
}

static bool
format_message(char *buf, unsigned int bsize)
{
  char s_last[16];
  show_frac (s_last, sizeof(s_last), 3, rtcMem.lastTime/1000);

  char s_total[16];
  show_frac (s_total, sizeof(s_total), 3, rtcMem.totalTime);

  char s_start[16];
  show_frac (s_start, sizeof(s_start), 3, time_start/1000);

  char s_read[16];
  show_frac (s_read, sizeof(s_read), 3, time_read/1000);

  char s_wifi[16];
  show_frac (s_wifi, sizeof(s_wifi), 3, time_wifi/1000);

  char s_temp[1+10*rangeof(temp)] = ""; // 1=room for empty string
  char *p = s_temp;
  for (int i = 0; i < rangeof(temp); ++i) {
    *p++ = i > 0 ? ',' : ' ';
    p += show_frac (p, 9, 4, (long)(temp[i]*10000));
  }

  char s_vdd[16];
  show_frac (s_vdd, sizeof(s_vdd), 3, vdd);

  time_save = micros() - time_save;
  char s_save[16];
  show_frac (s_save, sizeof(s_save), 3, time_save/1000);

  uint32_t time_now = micros();  // do this last
  char s_now[16];
  show_frac (s_now, sizeof(s_now), 3, (time_now-time_start)/1000);

  snprintf (buf, bsize,
      "%s %s %lu times=L%s,T%s,s%s,u0.000,r%s,w%s,F0.000,S%s,d0.000,t%s stats=fs%lu,fh%lu,fr%lu adc=0.000 vdd=%s%s",
      WIFI_OP, HOSTNAME, rtcMem.runCount, s_last, s_total, s_start, s_read, s_wifi, s_save, s_now,
      rtcMem.failSoft, rtcMem.failHard, rtcMem.failRead,
      s_vdd, s_temp);

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
  } else
    Serial.println(message);

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

#define WAKEUP_US         (uint32_t)(1000*WAKEUP_MS*TIME_RATE)
#define DSLEEP_US         (uint32_t)(1000*DSLEEP_MS*TIME_RATE)
#define SLEEP_US          (uint32_t)(1000*SLEEP_MS*TIME_RATE)

static void
cycle(void)
{
  ++rtcMem.runCount;
  wifing = (rtcMem.wakeType != WAKE_RF_DISABLED);

  Serial.print("### cycle, wifing=");
  Serial.println(wifing);
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

  digitalWrite(TIME_PIN, HIGH);   // end marker
  delay(1);
  digitalWrite(TIME_PIN, LOW);

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

  uint32_t time_so_far = woken_up
        ? (micros() + WAKEUP_US) : (micros() - time_start);

  Serial.print("time_so_far+DS=");
  Serial.println(time_so_far+DSLEEP_US);

  uint32_t last_wake_type = rtcMem.wakeType;
  rtcMem.wakeType = (rtcMem.runCount%WIFI_ON_RATE) ? WAKE_RF_DISABLED : WAKE_RFCAL;  // WiFi every 3 cycles
  rtc_commit();

  if (time_so_far+DSLEEP_US < SLEEP_US) {
    Serial.println("### normal dsleep");
    ESP.deepSleep(SLEEP_US-(time_so_far+DSLEEP_US), rtcMem.wakeType);
  }

  if (last_wake_type != rtcMem.wakeType) {
    Serial.println("### mode change dsleep");
    ESP.deepSleep(1, rtcMem.wakeType);  // must change mode now
  }

  if (time_so_far < SLEEP_US)
    delay((SLEEP_US-time_so_far)/1000);

  Serial.println("### no dsleep");
}

void
setup() {
  time_start = micros();

  /* after power up the pin is HIGH
   */
  pinMode(TIME_PIN, OUTPUT);
  digitalWrite(TIME_PIN, LOW);    // start marker

  Serial.begin(SERIAL_BAUD);
  Serial.println("");

  pinMode(MAGIC_PIN, INPUT_PULLUP);
  if (LOW == digitalRead(MAGIC_PIN)) {
    Serial.println("Stopped by magic");
    ESP.deepSleep(0xFFFFFFFFUL, WAKE_RF_DISABLED); // about 80 minutes
  }

  Serial.println("### setup");

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

