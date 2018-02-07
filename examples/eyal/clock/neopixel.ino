#define fastLED   1
#define NeoPixel  0

#if NeoPixel
#include <Adafruit_NeoPixel.h>
#elif fastLED
#include <FastLED.h>
#else
#error Must select a LED library
#endif

#include "RTClib.h"

const int LedDataPin = 5;
const int LedCount = 180;

#if NeoPixel
Adafruit_NeoPixel leds = Adafruit_NeoPixel(LedCount, LedDataPin, NEO_GRB + NEO_KHZ800);
#elif fastLED
#define LED_TYPE    WS2812B
#define COLOR_ORDER GRB
static CRGB leds[LedCount];
#endif

static RTC_DS3231 rtc;

const float pulsePeriod = 6.0f;

const float MilliSecondDisplayWidth = 7.5f / LedCount;
const int MilliSecondRed = 16;
const int MilliSecondGreen = 16;
const int MilliSecondBlue = 16;

const float SecondDisplayWidth = 15.0f / LedCount;
const int SecondRed = 131;
const int SecondGreen = 215;
const int SecondBlue = 32;
const float SecondPulseOffset = pulsePeriod / 4.0f;

const float MinuteDisplayWidth = 30.0f / LedCount;
const int MinuteRed = 222;
const int MinuteGreen = 24;
const int MinuteBlue = 121;
const float MinutePulseOffset = pulsePeriod / 2.0f;

const float HourDisplayWidth = 45.0f / LedCount;
const int HourRed = 12;
const int HourGreen = 68;
const int HourBlue = 245;
const float HourPulseOffset = 3.0f * pulsePeriod / 4.0f;

int hour;
int minute;
int second;
int milliSecond;
long lastTime;

int red;
int green;
int blue;
int ledIndex;

void setup()
{
  Serial.begin(115200);
  Serial.println("setup");

  if (!rtc.begin()) {
    Serial.println("Couldn't find RTC");
    while (1);
  }

#if NeoPixel
  leds.begin();
#elif fastLED
  FastLED.addLeds<LED_TYPE, LedDataPin, COLOR_ORDER>(leds, LedCount).setCorrection(TypicalLEDStrip);
  FastLED.setBrightness(255);
#endif

  minute = 0;
  second = 0;
}

void loop()
{
  if (minute == 0 && second == 0)
  {
    ReadExternalTime();
  }

  ProgressInternalTime();
  TrailingFadeHandDisplay();

#if NeoPixel
  leds.show();
#elif fastLED
  FastLED.show();
#endif
}

void ReadExternalTime()
{
  Serial.println("ReadExternalTime");
  
  DateTime previousTime = rtc.now();
  uint8_t previousSecond = previousTime.second();
  Serial.print("previousSecond=");
  Serial.println(previousSecond);

  DateTime nextTime;
  while (true)
  {
    nextTime = rtc.now();

    uint8_t nextSecond = nextTime.second();

    if (nextSecond != previousSecond)
    {
      Serial.print("nextSecond=");
      Serial.println(nextSecond);
      break;
    }
  }

  hour = nextTime.hour() % 12;
  minute = nextTime.minute();
  second = nextTime.second();
  milliSecond = 0;
  lastTime = millis();

  Serial.print("ReadExternalTime finished");
}

void ProgressInternalTime()
{
  long currentTime = millis();
  int timeDifference = (int)(currentTime - lastTime);
  lastTime = currentTime;
/*
  if (timeDifference > 100)
  {
    return;
  }
*/
  milliSecond += timeDifference;
  while (milliSecond >= 1000)
  {
    milliSecond -= 1000;
    second++;
    if (second >= 60)
    {
      second -= 60;
      minute++;
      if (minute >= 60)
      {
        minute -= 60;
        hour++;
        if (hour >= 12)
        {
          hour -= 12;
        }
      }
    }
  }
}

void TrailingFadeHandDisplay()
{
  float milliSecondEnd = milliSecond / 1000.0f;
  float secondEnd = (second + milliSecond / 1000.0f) / 60.0f;
  float minuteEnd = (minute + secondEnd) / 60.0f;
  float hourEnd = (hour + minuteEnd) / 12.0f;

  for (ledIndex = 0; ledIndex < LedCount; ledIndex++)
  {
    ClearColour();

    //TrailingFadeHandAddColour(milliSecondEnd, MilliSecondDisplayWidth, MilliSecondRed, MilliSecondGreen, MilliSecondBlue, 0);
    TrailingFadeHandAddColour(secondEnd, SecondDisplayWidth, SecondRed, SecondGreen, SecondBlue, SecondPulseOffset);
    TrailingFadeHandAddColour(minuteEnd, MinuteDisplayWidth, MinuteRed, MinuteGreen, MinuteBlue, MinutePulseOffset);
    TrailingFadeHandAddColour(hourEnd, HourDisplayWidth, HourRed, HourGreen, HourBlue, HourPulseOffset);

    PulsingFiveMinuteMarker();

    ApplyColourToLed();
  }
}

void ClearColour()
{
  red = 0;
  green = 0;
  blue = 0;
}

void AddColour(int sectionRed, int sectionGreen, int sectionBlue, float percent)
{
  percent = percent * percent;
  red = min((int)255, red + (int)(percent * sectionRed));
  green = min((int)255, green + (int)(percent * sectionGreen));
  blue = min((int)255, blue + (int)(percent * sectionBlue));
}

void ApplyColourToLed()
{
  int ledPosition = IndexToLed(ledIndex);
#if NeoPixel
  leds.setPixelColor(ledPosition, 0
        | (long)red << 16
        | (long)green << 8
        | (long)blue
        );
#elif fastLED
  leds[ledPosition].red = red;
  leds[ledPosition].green = green;
  leds[ledPosition].blue = blue;
#endif
}

int IndexToLed(int ledPosition)
{
  return (2 * LedCount - 1 - ledPosition) % LedCount;
}

void TrailingFadeHandAddColour(float sectionEnd, float sectionWidth, int sectionRed, int sectionGreen, int sectionBlue, float pulseOffset)
{
  const float LedWidth = 1.0f / LedCount;
  float sectionStart = sectionEnd - sectionWidth;

  float ledMin = (float)ledIndex / LedCount;
  ledMin = RoundToComparable(sectionStart, ledMin);
  float ledMax = ledMin + LedWidth;

  if (ledMin <= sectionEnd && sectionEnd < ledMax)
  {
    float percent = (sectionEnd - ledMin) / LedWidth + 0.25f * PulsePercent(sectionEnd, ledMin, ledMax, pulseOffset);
    AddColour(sectionRed, sectionGreen, sectionBlue, percent);
  } else if (sectionStart <= ledMin && ledMax < sectionEnd)
  {
    float percent = 1.0f - (sectionEnd - ledMax) / sectionWidth + 0.25f * PulsePercent(sectionEnd, ledMin, ledMax, pulseOffset);
    AddColour(sectionRed, sectionGreen, sectionBlue, percent);
  } else if (ledMin < sectionStart && sectionStart < ledMax)
  {
    float percent = 1.0f - (sectionEnd - ledMax) / sectionWidth + 0.25f * PulsePercent(sectionEnd, ledMin, ledMax, pulseOffset);
    AddColour(sectionRed, sectionGreen, sectionBlue, percent);
  }
}

float PulsePercent(float sectionEnd, float ledMin, float ledMax, float pulseOffset)
{
  float pulseSeconds = second + milliSecond / 1000.0f + pulseOffset;
  float pulsePosition = sectionEnd + SquareWave(pulseSeconds, pulsePeriod);
  pulsePosition = RoundToComparable(ledMax, pulsePosition);

  float pulsePercent;
  if (pulsePosition > ledMax)
  {
    pulsePercent = 1.0f - 2.0f * (pulsePosition - ledMax);
  } else if (pulsePosition < ledMin)
  {
    pulsePercent = 1.0f - 2.0f * (ledMin - pulsePosition);
  } else
  {
    pulsePercent = 1.0f;
  }

  pulsePercent = pow(pulsePercent, 16.0f);
  return pulsePercent;
}

float SquareWave(float seconds, float period)
{
  return (seconds - period * (int)(seconds / period)) / period;
}

float RoundToComparable(float baseValue, float value)
{
  while (value - baseValue >= 0.5f)
  {
    value -= 1;
  }
  while (baseValue - value >= 0.5f)
  {
    value += 1;
  }

  return value;
}

void PulsingFiveMinuteMarker()
{
  const float pulseMin = 0.5f;
  const float pulseMax = 1.0f;
  const float pulseRange = pulseMax - pulseMin;

  if ((ledIndex % (LedCount / 12)) == 0)
  {
    float pulseSeconds = second + milliSecond / 1000.0f;
    float percent = 2 * SquareWave(pulseSeconds, pulsePeriod) - 1;
    if (percent < 0)
    {
      percent = -percent;
    }
    percent = pulseMin + percent * pulseRange;
    percent = pow(percent, 7);
    AddColour(0xff, 0xff, 0xff, percent);
  }
}

