/*
 * This sketch used to measure the Arduino performance on the esp8266.
 */

#include <ESP8266WiFi.h>
#include <WiFiUDP.h>

#define ONEWIRE_SEARCH    0
#include <OneWire.h>

/* DS18x20 registers
 */
#define CONVERT_T         0x44
#define COPY_SCRATCHPAD   0x48
#define WRITE_SCRATCHPAD  0x4E
#define RECALL_EEPROM     0xB8
#define READ_SCRATCHPAD   0xBE
#define CHIP_DS18B20      0x10  // 16
#define CHIP_DS18S20      0x28  // 40

#define OW_PIN            4     // D2=GPIO4
#define TIME_PIN          13    // D7=GPIO13

#define SERIAL_BAUD       115200  // use 74880 to see the SDK messages
//#define SERIAL_CHATTY

#define WIFI_SSID         "esp"
#define WIFI_PASSWORD     "esp8266wifi"

#define WIFI_SERVER       "192.168.2.7"
#define WIFI_PORT         21883

//#define WIFI_USE_DHCP
#define HOSTNAME          "d1-mini"
static IPAddress          ip(192,168,2,51);  // static IP config
static IPAddress          gw(192,168,2,7);
static IPAddress          dns(192,168,2,7);

#define SLEEP_MS          300     // DS18B20 needs 650ms to convert, sleep/wake takes 350ms
#define WIFI_WAIT_MS      1
#define WIFI_TIMEOUT_MS   (10*1000)

static OneWire            ds(OW_PIN);
static byte               addr[8] = {40, 24, 158, 118, 6, 0, 0, 129};	// DS18B20 ID

static WiFiUDP            UDP;

static unsigned long      time_start;
static unsigned long      time_read;
static unsigned long      time_wifi;
static float              dCf;	// temperature in degrees Celsius


static void
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
    snprintf (buf, bsize, "%lu", v);
    return;
  }
  long int u = v/scale;
  long int f = v -u*scale;
  char  fmt[16];
  sprintf (fmt, "%%ld.%%0%dld", precision);
 
  snprintf (buf, bsize, fmt, u, f);
}

/* first invocation will raise the pin
 */
static void
toggle()
{
  static byte level = 0;  // LOW

  digitalWrite(TIME_PIN, (level = ~level) ? HIGH : LOW);
}

static float
ds18b20_read(void)
{
  if (!ds.reset()) return (85.0);
  ds.select(addr);
  ds.write(READ_SCRATCHPAD);

  byte i, data[9];
  for (i = 0; i < 9; ++i)
    data[i] = ds.read();

  // if (OneWire::crc8(data, 9)) ERROR...

  int16_t dCi = (data[1] << 8) | data[0];  // 12 bit temp
  return ((float)dCi / 16.0);
}

static void
ds18b20_convert(void)
{
  if (!ds.reset()) return;
  ds.select(addr);
  ds.write(CONVERT_T, 1);
}

static boolean
wait_for_wifi(void)
{
  time_wifi = micros();

#ifndef WIFI_USE_DHCP
    WiFi.config(ip, gw, dns);     // set static IP
#endif

#ifdef WIFI_SSID
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
#endif

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
      return false;
    }
  }
  time_wifi = micros() - time_wifi;
  digitalWrite(TIME_PIN, LOW);
  Serial.println(wstatus);

#ifdef SERIAL_CHATTY
  Serial.print(" have WiFi in ");
  Serial.print(time_wifi);
  Serial.print("us, ip=");
  Serial.println(WiFi.localIP());
#endif

  return true;
}

static boolean
send_udp(char *message)
{
  UDP.beginPacket(WIFI_SERVER, WIFI_PORT);
  UDP.write(message);
  UDP.endPacket();
  delay(50);  // work around SDK bug

  return true;
}

static boolean
format_message(char *buf, unsigned int bsize)
{
  char starts[16];
  show_frac (starts, sizeof(starts), 3, time_start/1000);

  char reads[16];
  show_frac (reads, sizeof(reads), 3, time_read/1000);

  char wifis[16];
  show_frac (wifis, sizeof(wifis), 3, time_wifi/1000);

  char dCs[16];
  show_frac (dCs, sizeof(dCs), 4, (long)(dCf*10000));

  unsigned long time_now = micros();
  char nows[16];
  show_frac (nows, sizeof(nows), 3, (time_now-time_start)/1000);

  snprintf (buf, bsize,
      "show %s times=s%s,u0.000,r%s,w%s,t%s %s",
      HOSTNAME, starts, reads, wifis, nows, dCs);

  return true;
}

static boolean
send_message(char *message)
{
  if (!send_udp(message))
    return false;

  return true;
}

static boolean
read_temp(void)
{
  time_read = micros();
  dCf = ds18b20_read(); // read old conversion
  ds18b20_convert();          // start next conversion
  time_read = micros()- time_read;

#ifdef SERIAL_CHATTY
  Serial.print("\nTemperature = ");
  Serial.print(dCf);
  Serial.println("dC");
#endif
  return true;
}

static void
do_stuff()
{
  char message[100];

  if (!read_temp())
    return;

  if (!wait_for_wifi())
    return;

  if (!format_message(message, sizeof(message)))
    return;

  if (!send_message(message))
    return;
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

#ifdef SERIAL_CHATTY
  Serial.print("start at ");
  Serial.print(time_start);
  Serial.println("us");
#endif

  do_stuff();

  digitalWrite(TIME_PIN, HIGH);   // end marker
  delay(1);
  digitalWrite(TIME_PIN, LOW);

#ifdef SERIAL_CHATTY
  unsigned long time_now = micros();
  Serial.print("sleeping ");
  Serial.print(SLEEP_MS);
  Serial.print("ms at ");
  Serial.print(time_now);
  Serial.print("(+");
  Serial.print(time_now-time_start);
  Serial.println(")us");
#endif

// WAKE_RF_DEFAULT, WAKE_RFCAL, WAKE_NO_RFCAL, WAKE_RF_DISABLED
  ESP.deepSleep(SLEEP_MS*1000, WAKE_RFCAL);
}

void
loop() {
  // sleeping so wont get here
}

