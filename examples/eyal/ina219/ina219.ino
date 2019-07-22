#include <Wire.h>
#include <Adafruit_INA219.h>

Adafruit_INA219 ina219;


#define HOUR_US           ((unsigned long)(1000000*60*60)) // us * sec * min

#define REPORT_LONG       0   // one report a second
#define REPORT_SHORT      0   // one report a second
#define REPORT_VERY_SHORT 0   // one report a second
#define REPORT_CURRENT    1   // report every reading (every about 2ms)

static unsigned long micros_start  = 0;
static unsigned long micros_prev   = 0;
static unsigned long print_next_ms = 0;


void setup(void) 
{
  micros_start = micros();
  micros_prev = micros_start;

  Serial.begin(115200);
  while (!Serial) {
      // will pause Zero, Leonardo, etc until serial console opens
      delay(1);
  }

  Serial.println("Hello!");
  
  // Initialize the INA219.
  // By default the initialization will use the largest range (32V, 2A).  However
  // you can call a setCalibration function to change this range (see comments).
  ina219.begin();
  // To use a slightly lower 32V, 1A range (higher precision on amps):
  //ina219.setCalibration_32V_1A();
  // Or to use a lower 16V, 400mA range (higher precision on volts and amps):
  ina219.setCalibration_16V_400mA();

  Serial.println("Measuring voltage and current with INA219 ...");

  print_next_ms = millis();
}

void loop(void) 
{
  unsigned long interval_us;
  float interval_h;
  float shuntvoltage;
  float busvoltage;
  float current_mA;
  float loadvoltage;
  float power_mW;
  unsigned long delta;

  static unsigned int micros_high = 0;  // number of micros() overflows, not used.

  static unsigned long now_us = 0;      // time now, us part of hour
  static unsigned int  now_h  = 0;      // time now, hours

  static unsigned long micros_now = 0;
  static float current_max = 0;
  static unsigned long count = 0;
#if REPORT_LONG  || REPORT_SHORT || REPORT_VERY_SHORT
  static unsigned long old_count = 0;
#endif
  static float current_mAh = 0;
  static float power_mWh = 0;

#if REPORT_LONG || REPORT_SHORT || REPORT_VERY_SHORT
  ++count;
#endif

  busvoltage = ina219.getBusVoltage_V();
  current_mA = ina219.getCurrent_mA();
    if (current_mA < 0) current_mA = 0;

#if REPORT_LONG || REPORT_SHORT
  power_mW   = ina219.getPower_mW();
    if (power_mW   < 0)   power_mW = 0;
#endif

#if REPORT_LONG
  shuntvoltage = ina219.getShuntVoltage_mV();
  loadvoltage = busvoltage + (shuntvoltage / 1000);

  if (current_max < current_mA)
    current_max = current_mA;
#endif

  micros_now = micros();
  if (micros_now < micros_prev) {
    ++micros_high;
    interval_us = micros_now + (0xffffffff - micros_prev) + 1;
  } else
    interval_us = micros_now - micros_prev;

  now_us += interval_us;
  if (now_us > HOUR_US) {
    ++now_h;
    now_us -= HOUR_US;
  }
  
  interval_h = interval_us/(float)HOUR_US;

  current_mAh += current_mA * interval_h;
#if REPORT_LONG || REPORT_SHORT
  power_mWh   += power_mW   * interval_h;
#endif

  micros_prev = micros_now;

#if REPORT_LONG
  if (millis() >= print_next_ms) {
    unsigned long seconds;

    print_next_ms += 1000;   // every 1s

    if (now_h > 0) {
      Serial.print(now_h) ; Serial.print("h");
    }
    seconds = now_us/1000000;
    Serial.print(seconds/60); Serial.print("m"); Serial.print(seconds%60); Serial.print("s, n=");
        Serial.print(count); Serial.print("(+"); Serial.print(count-old_count); Serial.println(")");
    old_count = count;            

    Serial.print("Bus Voltage:   "); Serial.print(busvoltage);   Serial.println(" V");
    Serial.print("Shunt Voltage: "); Serial.print(shuntvoltage); Serial.println(" mV");
    Serial.print("Load Voltage:  "); Serial.print(loadvoltage);  Serial.println(" V");
    Serial.print("Current:       "); Serial.print(current_mA);   Serial.println(" mA");
    Serial.print("Power:         "); Serial.print(power_mW);     Serial.println(" mW");
    Serial.print("Current max:   "); Serial.print(current_max);  Serial.println(" mA");
    Serial.print("Current total: "); Serial.print(current_mAh);  Serial.println(" mAh");
    Serial.print("Power   total: "); Serial.print(power_mWh);    Serial.println(" mWh");
    Serial.println("");
  }
#endif

#if REPORT_SHORT
  if (millis() >= print_next_ms) {
    unsigned int seconds;
    char str[100];

    print_next_ms += 1000;   // every 1s

    seconds = now_us/1000000;
    sprintf (str, "%lu:%02u:%02u %lu %.3f %.2f %.3f %.3f",
      now_h, seconds/60, seconds%60,
      count,
      busvoltage,
      current_mA,
      current_mAh,
      power_mWh);
   Serial.println(str);
  }
#endif

#if REPORT_VERY_SHORT
  if (millis() >= print_next_ms) {
    unsigned long now_s;
    char str[100];

    print_next_ms += 1000;   // every 1s

    now_s = now_us/1000000 + now_h*60*60;
    sprintf (str, "%lu.%06lu %lu %.3f %.3f",
      now_s, now_us%1000000,
      count - old_count,
      busvoltage,
      current_mAh);
    Serial.println(str);

    old_count = count;            
  }
#endif

#if REPORT_CURRENT
  {                       // every reading (about 2ms)
    unsigned long now_s;
    char str[100];

    now_s = now_us/1000000 + now_h*60*60;
    sprintf (str, "%lu.%03lu %.8f",
      now_s, (now_us%1000000)/1000,
      current_mA);
    Serial.println(str);
  }
#endif
}
