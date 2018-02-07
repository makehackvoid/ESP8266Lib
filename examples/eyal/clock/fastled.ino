#include <FastLED.h>

#include "RTClib.h"
static RTC_DS3231 rtc;

#define LED_PIN     5
#define NUM_LEDS    180
#define BRIGHTNESS  16  // 64
#define LED_TYPE    WS2812B
#define COLOR_ORDER GRB
// MILLI_PER_SEC should be 1000, but smaller numbers make debugging easier/more interesting.
#define MILLIS_PER_SEC 1000
static CRGB leds[NUM_LEDS];
static CRGB leds_static[NUM_LEDS];
#define UPDATES_PER_SECOND 1
TBlendType    currentBlending;
extern CRGBPalette16 myRedWhiteBluePalette;
extern const TProgmemPalette16 myRedWhiteBluePalette_p PROGMEM;

static void set_static_leds (void)
{
    int i;

    for (i = 0; i < NUM_LEDS; ++i) {
        leds_static[i] = CRGB::Black;
    }
    for (i = 0; i < 60; i += 5) { // hour markers
        leds_static[pos(i)].red   = 255;
        leds_static[pos(i)].green = 255;
        leds_static[pos(i)].blue  = 255;
    }
}

// adjust led index if it wraps around
//
static uint8_t canon (int index)
{
    index %= NUM_LEDS;
    return index < 0
        ? index+NUM_LEDS
        : index;
}

#define LEDS_CCW  1

// map logical led (60) to physical led (NUM_LEDS)
//
static int pos (int led)
{
    led *= NUM_LEDS / 60;
    return LEDS_CCW
        ? (NUM_LEDS-1) - led
        : led;
}

static int blink_intensity  = 0;

static void new_time (uint8_t hour, uint8_t minute, uint8_t second)
{
    int hourled;

    memcpy (leds, leds_static, sizeof(leds));
   
    hourled   = hour * 5 + minute/12;
    leds[canon(pos(hourled)-1)].red = 255-blink_intensity;  // maybe use leds[] += CRGB::Red ?
    leds[canon(pos(hourled)  )].red = blink_intensity;
    leds[canon(pos(hourled)+1)].red = 255-blink_intensity;
    leds[pos(minute)+ (LEDS_CCW ? -second/20 : second/20)].green = blink_intensity;
    leds[pos(second)].blue          = 255;
}

void setup() {
    Serial.begin(115200);
    
    if (! rtc.begin()) {
        Serial.println("Couldn't find RTC");
        while (1);
    }

    FastLED.addLeds<LED_TYPE, LED_PIN, COLOR_ORDER>(leds, NUM_LEDS).setCorrection( TypicalLEDStrip );
    FastLED.setBrightness( BRIGHTNESS );
    currentBlending = LINEARBLEND;

    set_static_leds ();

    memcpy (leds, leds_static, sizeof(leds));
    FastLED.show();
}

void loop ()
{
    blink_intensity = 255 - blink_intensity;

//  now = millis() / MILLIS_PER_SEC;	// to be replaced with RTC time

    static uint8_t last_hour = 0,
      last_minute = 0,
      last_second = 0;

    DateTime now = rtc.now();
    uint8_t hour   = now.hour();
    if (hour >= 12) hour -= 12;
    uint8_t minute = now.minute();
    uint8_t second = now.second();

    if (second != last_second ||
        minute != last_minute ||
        hour   != last_hour) {
        last_hour   = hour;
        last_minute = minute;
        last_second = second;
    }
    new_time (hour, minute, second);
    FastLED.show();

    delay ((unsigned long)(MILLIS_PER_SEC/10));	// ?
}

