// Lifted from NodeMCU:
// https://github.com/nodemcu/nodemcu-firmware/blob/dev-esp32/components/modules/ow.c
// which is based on Maxim's code.
//---------------------------------------------------------------------------
// Copyright (C) 2000 Dallas Semiconductor Corporation, All Rights Reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL DALLAS SEMICONDUCTOR BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
// Except as contained in this notice, the name of Dallas Semiconductor
// shall not be used except as stated in the Dallas Semiconductor
// Branding Policy.
//--------------------------------------------------------------------------

#include "udp.h"
#include "onewire.h"

#define ONEWIRE_INTERNAL_PULLUP	1	// 0=using external pullup
#define ONEWIRE_POWERED		0	// do not enable
#define ONEWIRE_RECOVERY_US	2

#define ONEWIRE_CRC		1	// do not disable
#define ONEWIRE_CRC8_TABLE	1
#define ONEWIRE_CRC16		1

#define OW_GO_INPUT() \
do { \
	if (ONEWIRE_INTERNAL_PULLUP) \
		gpio_set_pull_mode(ow_pin, GPIO_PULLUP_ONLY); \
	gpio_set_direction(ow_pin, GPIO_MODE_INPUT); \
} while (0)

#define OW_NO_PIN		0xFF
static uint8_t ow_pin = OW_NO_PIN;

esp_err_t ow_write_bits (int nbits, uint8_t *data)
{
	int i, b;
	uint8_t d;

	if (OW_NO_PIN == ow_pin) DbgR (ESP_FAIL);
	if (nbits < 0) DbgR (ESP_FAIL);
toggle_short (2);

#if ONEWIRE_POWERED
	gpio_set_direction (ow_pin, GPIO_MODE_OUTPUT);
	gpio_set_level (ow_pin, 1);
#endif

	d = *data++;
	for (i = 0, b = 0; i < nbits; ++i, ++b, d >>= 1) {
		if (8 == b) {
			b = 0;
			d = *data++;
		}

		delay_us (ONEWIRE_RECOVERY_US);

#if !ONEWIRE_POWERED
		gpio_set_direction (ow_pin, GPIO_MODE_OUTPUT);
#endif // if !ONEWIRE_POWERED

toggle_short (1);
		gpio_set_level (ow_pin, 0);
		delay_us (3);

		if (d & 1) gpio_set_level (ow_pin, 1);
		delay_us (60-3);

#if ONEWIRE_POWERED
		gpio_set_level (ow_pin, 1);
#else
		OW_GO_INPUT ();
#endif
	}

#if ONEWIRE_POWERED
	OW_GO_INPUT ();
#endif

	return ESP_OK;
}

esp_err_t ow_read_bits (int nbits, uint8_t *data)
{
	int i, b;
	uint8_t d = 0;	// stupid compiler wants this...

	if (OW_NO_PIN == ow_pin) DbgR (ESP_FAIL);
	if (nbits < 0) DbgR (ESP_FAIL);
toggle_short(3);

	for (i = 0, b = 0; i < nbits; ++i, ++b) {
		if (8 == b) {
			b = 0;
			*data++ = d;
			d = 0;
		}
		delay_us (ONEWIRE_RECOVERY_US);

toggle_short(1);
		gpio_set_direction(ow_pin, GPIO_MODE_OUTPUT);
		gpio_set_level(ow_pin, 0);
		delay_us(3);

		OW_GO_INPUT ();
		delay_us(7);		// measured: data ready in 4us, gone in 28us
		d |= gpio_get_level (ow_pin) << b;

		delay_us (60-3-7);		// 60us read time slot
	}
	if (b > 0)				// last byte or part of
		*data = d;

	return ESP_OK;
}

esp_err_t ow_reset(void)
{
	if (OW_NO_PIN == ow_pin) DbgR (ESP_FAIL);
toggle_short(4);

	gpio_set_direction(ow_pin, GPIO_MODE_OUTPUT);
	gpio_set_level(ow_pin, 0);
	delay_us(480);

toggle_short(1);
	OW_GO_INPUT ();
	delay_us(70);	// measured: low in 30us, high in 140us
toggle_short(1);
	if (gpio_get_level(ow_pin))
		LogR (ESP_FAIL, "reset timeout 1");
	delay_us(410);
toggle_short(1);
//	if (!gpio_get_level(ow_pin))	// TESTING
//		LogR (ESP_FAIL, "reset timeout 2");

	return ESP_OK;
}

esp_err_t ow_depower (void)
{
	if (OW_NO_PIN == ow_pin) DbgR (ESP_FAIL);

	OW_GO_INPUT ();

	return ESP_OK;
}

static esp_err_t ow_wait_for_high (int us)
{
	for (; !gpio_get_level (ow_pin); --us) {
		if (us <= 0)
			LogR (ESP_FAIL, "wait_for_high timeout");
		delay_us(1);
	}

	return ESP_OK;
}

esp_err_t ow_init (uint8_t pin)
{
	esp_err_t ret;

	ow_pin = pin;
	gpio_pad_select_gpio(ow_pin);

	OW_GO_INPUT ();
	delay_us(10);	// or else I see:
			//  E (238) gpio: gpio_set_pull_mode(211): GPIO number error
			//  E (248) gpio: gpio_set_direction(241): GPIO number error

	(void)ow_wait_for_high (480);

	Dbg (ow_reset());
	if (ESP_OK != ret)
		ow_pin = OW_NO_PIN;

	return ESP_OK;
}

#if ONEWIRE_CRC
// The 1-Wire CRC scheme is described in Maxim Application Note 27:
// "Understanding and Using Cyclic Redundancy Checks with Maxim iButton Products"
//

#if ONEWIRE_CRC8_TABLE
// This table comes from Dallas sample code where it is freely reusable,
// though Copyright (C) 2000 Dallas Semiconductor Corporation
static const uint8_t dscrc_table[] = {
      0, 94,188,226, 97, 63,221,131,194,156,126, 32,163,253, 31, 65,
    157,195, 33,127,252,162, 64, 30, 95,  1,227,189, 62, 96,130,220,
     35,125,159,193, 66, 28,254,160,225,191, 93,  3,128,222, 60, 98,
    190,224,  2, 92,223,129, 99, 61,124, 34,192,158, 29, 67,161,255,
     70, 24,250,164, 39,121,155,197,132,218, 56,102,229,187, 89,  7,
    219,133,103, 57,186,228,  6, 88, 25, 71,165,251,120, 38,196,154,
    101, 59,217,135,  4, 90,184,230,167,249, 27, 69,198,152,122, 36,
    248,166, 68, 26,153,199, 37,123, 58,100,134,216, 91,  5,231,185,
    140,210, 48,110,237,179, 81, 15, 78, 16,242,172, 47,113,147,205,
     17, 79,173,243,112, 46,204,146,211,141,111, 49,178,236, 14, 80,
    175,241, 19, 77,206,144,114, 44,109, 51,209,143, 12, 82,176,238,
     50,108,142,208, 83, 13,239,177,240,174, 76, 18,145,207, 45,115,
    202,148,118, 40,171,245, 23, 73,  8, 86,180,234,105, 55,213,139,
     87,  9,235,181, 54,104,138,212,149,203, 41,119,244,170, 72, 22,
    233,183, 85, 11,136,214, 52,106, 43,117,151,201, 74, 20,246,168,
    116, 42,200,150, 21, 75,169,247,182,232, 10, 84,215,137,107, 53};

#ifndef pgm_read_byte
#define pgm_read_byte(addr) (*(const uint8_t *)(addr))
#endif

//
// Compute a Dallas Semiconductor 8 bit CRC. These show up in the ROM
// and the registers.  (note: this might better be done without to
// table, it would probably be smaller and certainly fast enough
// compared to all those delayMicrosecond() calls.  But I got
// confused, so I use this table from the examples.)
//
uint8_t onewire_crc8(const uint8_t *addr, uint8_t len)
{
	uint8_t crc = 0;

	while (len--) {
		crc = pgm_read_byte(dscrc_table + (crc ^ *addr++));
	}
	return crc;
}
#else	// if ONEWIRE_CRC8_TABLE
//
// Compute a Dallas Semiconductor 8 bit CRC directly.
// this is much slower, but much smaller, than the lookup table.
//
uint8_t onewire_crc8(const uint8_t *addr, uint8_t len)
{
	uint8_t crc = 0;

	while (len--) {
		uint8_t inbyte = *addr++;
    uint8_t i;
		for (i = 8; i; i--) {
			uint8_t mix = (crc ^ inbyte) & 0x01;
			crc >>= 1;
			if (mix) crc ^= 0x8C;
			inbyte >>= 1;
		}
	}
	return crc;
}
#endif	// else ONEWIRE_CRC8_TABLE

#if ONEWIRE_CRC16
// Compute a Dallas Semiconductor 16 bit CRC.  This is required to check
// the integrity of data received from many 1-Wire devices.  Note that the
// CRC computed here is *not* what you'll get from the 1-Wire network,
// for two reasons:
//   1) The CRC is transmitted bitwise inverted.
//   2) Depending on the endian-ness of your processor, the binary
//      representation of the two-byte return value may have a different
//      byte order than the two bytes you get from 1-Wire.
// @param input - Array of bytes to checksum.
// @param len - How many bytes to use.
// @param crc - The crc starting value (optional)
// @return The CRC16, as defined by Dallas Semiconductor.
uint16_t onewire_crc16(const uint8_t* input, uint16_t len, uint16_t crc)
{
    static const uint8_t oddparity[16] =
	{ 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0 };

    uint16_t i;
    for (i = 0 ; i < len ; i++) {
      // Even though we're just copying a byte from the input,
      // we'll be doing 16-bit computation with it.
      uint16_t cdata = input[i];
      cdata = (cdata ^ crc) & 0xff;
      crc >>= 8;

      if (oddparity[cdata & 0x0F] ^ oddparity[cdata >> 4])
	crc ^= 0xC001;

      cdata <<= 6;
      crc ^= cdata;
      cdata <<= 1;
      crc ^= cdata;
    }
    return crc;
}

// Compute the 1-Wire CRC16 and compare it against the received CRC.
// Example usage (reading a DS2408):
    //    // Put everything in a buffer so we can compute the CRC easily.
//    uint8_t buf[13];
//    buf[0] = 0xF0;    // Read PIO Registers
//    buf[1] = 0x88;    // LSB address
//    buf[2] = 0x00;    // MSB address
//    WriteBytes(net, buf, 3);    // Write 3 cmd bytes
//    ReadBytes(net, buf+3, 10);  // Read 6 data bytes, 2 0xFF, 2 CRC16
//    if (!CheckCRC16(buf, 11, &buf[11])) {
//	// Handle error.
//    }
//
// @param input - Array of bytes to checksum.
// @param len - How many bytes to use.
// @param inverted_crc - The two CRC16 bytes in the received data.
//		This should just point into the received data,
//		*not* at a 16-bit integer.
// @param crc - The crc starting value (optional)
// @return True, iff the CRC matches.
bool onewire_check_crc16(const uint8_t* input, uint16_t len, const uint8_t* inverted_crc, uint16_t crc)
{
    crc = ~onewire_crc16(input, len, crc);
    return (crc & 0xFF) == inverted_crc[0] && (crc >> 8) == inverted_crc[1];
}
#endif

#endif
