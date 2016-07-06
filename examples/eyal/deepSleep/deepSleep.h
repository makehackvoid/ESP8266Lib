#ifndef deepSleep_deepSleep_H
#define deepSleep_deepSleep_H

#include <ESP8266WiFi.h>

extern "C" {
  #include <user_interface.h>   // for core functions
}

#define rangeof(a) (sizeof(a)/sizeof(a[0]))

#include "user_config.h"


extern bool read_temp(int n, byte addr[][8], float temp[]);
extern uint32_t time_read;    // us
extern void show_state(void);

/*
 * Change the value of RTC_magic in rtc.cpp when you change this structure
 */
struct rtcMem {
  uint32_t magic;
  RFMode   wakeType;
  uint32_t runCount;      // count
  uint32_t failSoft;      // count
  uint32_t failHard;      // count
  uint32_t failRead;      // count
  uint32_t lastTime;      // us
  uint32_t totalTime;     // ms
};
extern struct rtcMem rtcMem;

extern bool rtc_init(void);
extern void rtc_commit(void);

#endif
