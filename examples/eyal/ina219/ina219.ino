#include <Wire.h>
#include <Adafruit_INA219.h>

Adafruit_INA219 ina219;


#define HOUR_US           ((unsigned long)(1000000*60*60)) // us * sec * min

#define REPORT_LONG         0   // one report a second
#define REPORT_SHORT        0   // one report a second
#define REPORT_VERY_SHORT   1   // one report a second
#define REPORT_FAST         0   // report every reading
#define REPORT_CURRENT_ONLY 1   // report only current mAh

#if REPORT_FAST
#define REPORT_CURRENT_ONLY 1   // report only current mAh
#endif

#define REPORT_PERIOD_MS  1000   // report every so many ms (0= always)

// getCurrent_mA      is the standard function.
// getCurrentFast_mA  is faster, does not reset the calibration register.
// setCalibration_16V_400mA     is the standard function, continuous voltage and current.
// setCalibrationFast_16V_400mA is faster, continuous current only
#if REPORT_CURRENT_ONLY
#define GET_CURRENT_MA  getCurrentFast_mA
#define SET_CALIBRATION setCalibrationFast_16V_400mA
#else
#define GET_CURRENT_MA  getCurrent_mA
#define SET_CALIBRATION setCalibration_16V_400mA
#endif

static unsigned long micros_start  = 0;
static unsigned long micros_prev   = 0;
static unsigned long print_next_ms = 0;

static HardwareSerial& serial = Serial1;   // Serial1 when commissioned

void setup(void) 
{
  micros_start = micros();
  micros_prev = micros_start;

  serial.begin(2*115200);
  while (!serial) {
      // will pause Zero, Leonardo, etc until serial console opens
      delay(1);
  }

  serial.println("Hello!");
  
  // Initialize the INA219.
  // By default the initialization will use the largest range (32V, 2A).  However
  // you can call a setCalibration function to change this range (see comments).
  ina219.begin();
  // To use a slightly lower 32V, 1A range (higher precision on amps):
  //ina219.setCalibration_32V_1A();
  // Or to use a lower 16V, 400mA range (higher precision on volts and amps):
  ina219.SET_CALIBRATION();

  serial.println("Measuring voltage and current with INA219 ...");

  print_next_ms = millis();
}

void loop(void) 
{
  unsigned long micros_now;         // micros()
  unsigned long interval_us;        // us   increment in this cycle
  double interval_h;                 // hour increment in this cycle
  float busvoltage;
  float current_mA;
  float power_mW;
  unsigned long delta;

  static unsigned int  micros_high = 0;  // number of micros() overflows, not used.
  static unsigned long now_us = 0;      // time now, us part of hour
  static unsigned int  now_h  = 0;      // time now, hours
  static unsigned long count = 0;
#if REPORT_LONG  || REPORT_VERY_SHORT
  static unsigned long old_count = 0;
#endif
#if REPORT_LONG || REPORT_SHORT
  static double power_mWh = 0;
#endif
  static double current_mAh = 0;


  ++count;

///// get time as us [micros_high:micros_now] and as h:s [now_h:now_us]

  micros_now = micros();
  if (micros_now < micros_prev) {     // overflow ever 1.19 hours
    ++micros_high;
    interval_us = micros_now + (0xffffffff - micros_prev) + 1;
  } else
    interval_us = micros_now - micros_prev;
  micros_prev = micros_now;
  interval_h = interval_us/(float)HOUR_US;

  now_us += interval_us;
  if (now_us > HOUR_US) {
    ++now_h;
    now_us -= HOUR_US;
  }

///// get ina219 readings and report

  current_mA = ina219.GET_CURRENT_MA();
    if (current_mA < 0) current_mA = 0;
  current_mAh += current_mA * interval_h;

#if REPORT_LONG || REPORT_SHORT
  power_mW = ina219.getPower_mW();
    if (power_mW   < 0)   power_mW = 0;
  power_mWh += power_mW * interval_h;
#endif

  if (millis() >= print_next_ms) {
    print_next_ms += REPORT_PERIOD_MS;

    ina219.reCalibrate();   // in case we lost the register
  
#if !REPORT_CURRENT_ONLY
    busvoltage = ina219.getBusVoltage_V();
#endif

#if REPORT_LONG
  {
    unsigned long now_s;
    static float current_max = 0;
    float shuntvoltage;
    float loadvoltage;

    shuntvoltage = ina219.getShuntVoltage_mV();
    loadvoltage = busvoltage + (shuntvoltage / 1000);

    if (now_h > 0) {
      serial.print(now_h) ; serial.print("h");
    }
    now_s = now_us/1000000;
    serial.print(now_s/60); serial.print("m"); serial.print(now_s%60); serial.print("s, n=");
        serial.print(count); serial.print("(+"); serial.print(count-old_count); serial.println(")");
    old_count = count;            

    if (current_max < current_mA)
      current_max = current_mA;

    serial.print("Bus Voltage:   "); serial.print(busvoltage);   serial.println(" V");
    serial.print("Shunt Voltage: "); serial.print(shuntvoltage); serial.println(" mV");
    serial.print("Load Voltage:  "); serial.print(loadvoltage);  serial.println(" V");
    serial.print("Current:       "); serial.print(current_mA);   serial.println(" mA");
    serial.print("Power:         "); serial.print(power_mW);     serial.println(" mW");
    serial.print("Current max:   "); serial.print(current_max);  serial.println(" mA");
    serial.print("Current total: "); serial.print(current_mAh);  serial.println(" mAh");
    serial.print("Power   total: "); serial.print(power_mWh);    serial.println(" mWh");
    serial.println("");
  }
#endif

#if REPORT_SHORT
  {
    unsigned int now_s;
    char str[100];

    now_s = now_us/1000000;             // part of hour
    sprintf (str, "%lu:%02u:%02u %lu %.3f %.2f %.3f %.3f",
      now_h, now_s/60, now_s%60,
      count,
      busvoltage,
      current_mA,
      current_mAh,
      power_mWh);
   serial.println(str);
  }
#endif

#if REPORT_VERY_SHORT
  {
    unsigned long now_s;
    char str[100];

    now_s = now_us/1000000 + now_h*60*60;

#if REPORT_CURRENT_ONLY
    sprintf (str, "%lu.%06lu %lu %.3f - %.3fmA %luus",
      now_s, now_us%1000000,
      count - old_count,
      current_mAh,
      current_mA, interval_us);
#else
    sprintf (str, "%lu.%06lu %lu %.3f %.3f",
      now_s, now_us%1000000,
      count - old_count,
      busvoltage,
      current_mAh);
    serial.println(str);
#endif
    serial.println(str);
    old_count = count;
  }
#endif  // REPORT_VERY_SHORT
  }

#if REPORT_FAST     // run only for a short time, "now_us" wraps around after 1.19h
  serial.print(now_us); serial.print(" "); serial.println(current_mA);
#endif
}
