#include "deepSleep.h"

  #define RTC_magic         0xd1dad1d1  // L
//#define RTC_magic         0xdad1d1da  // X
struct rtcMem rtcMem;

static bool
rtc_read(void)
{
  system_rtc_mem_read (64, &rtcMem, sizeof(rtcMem));
  return true;
}

static bool
rtc_write(void)
{
  system_rtc_mem_write (64, &rtcMem, sizeof(rtcMem));
  return true;
}

/*
 * return 'false' if initialised now
 */
bool
rtc_init(void)
{
  rtc_read ();

  if (RTC_magic != rtcMem.magic) {
    rtcMem.magic     = RTC_magic;
    rtcMem.wakeType  = WAKE_RF_DISABLED;  // first time
    rtcMem.runCount  = 0;
    rtcMem.failSoft  = 0;
    rtcMem.failHard  = 0;
    rtcMem.failRead  = 0;
    rtcMem.lastTime  = 0;
    rtcMem.totalTime = 0;
    rtc_write ();
    return false;
  }

  return true;
}

void
rtc_commit(void)
{
  rtcMem.lastTime = micros();
  rtcMem.totalTime += rtcMem.lastTime/1000;
  rtc_write();
}

