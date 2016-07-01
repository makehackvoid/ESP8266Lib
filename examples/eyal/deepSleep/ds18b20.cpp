#include "deepSleep.h"

#define ONEWIRE_SEARCH    0
#include <OneWire.h>

static OneWire            ds(OW_PIN);

/* DS18x20 registers
 */
#define CONVERT_T         0x44
#define COPY_SCRATCHPAD   0x48
#define WRITE_SCRATCHPAD  0x4E
#define RECALL_EEPROM     0xB8
#define READ_SCRATCHPAD   0xBE
#define CHIP_DS18B20      0x10  // 16
#define CHIP_DS18S20      0x28  // 40

uint32_t time_read;       // us

static float
ds18b20_read(byte addr[8])
{
  if (!ds.reset()) {
    ++rtcMem.failRead;
    return (86.0);
  }
  ds.select(addr);
  ds.write(READ_SCRATCHPAD);

  byte data[9];
  for (int i = 0; i < 9; ++i)
    data[i] = ds.read();

  if (ds.crc8(data, 9)) {
    ++rtcMem.failRead;
    return (87.0);
  }

  int16_t dCi = (data[1] << 8) | data[0];  // 12 bit temp
  return ((float)dCi / 16.0);
}

static bool
ds18b20_convert(byte addr[8])
{
  if (!ds.reset()) return false;
  ds.select(addr);
  ds.write(CONVERT_T, 1);

  return true;
}

bool
read_temp(int n, byte addr[][8], float temp[])
{
  time_read = micros();

  for (int i = 0; i < n; ++i) {
    temp[i] = ds18b20_read(addr[i]);     // read old conversion
    (void)ds18b20_convert(addr[i]);      // start next conversion
  }

  time_read = micros() - time_read;

#ifdef SERIAL_CHATTY
  Serial.print("\nTemperature = ");
  Serial.print(temp);
  Serial.println("dC");
#endif
  return true;
}
