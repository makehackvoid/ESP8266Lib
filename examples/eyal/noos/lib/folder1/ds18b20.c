#include "user_config.h"
#include "onewire.h"

static uint8		ow_pin = 255;
static const char	ds_msg[] = "ds18b20 -";

uint8
ds18b20_setup(uint8 pin)
{
	if (pin > 16)
		return 0;
	ow_pin = gpio_num[pin];

	onewire_init(ow_pin);
	return onewire_reset(ow_pin);
}

static const uint8 *
addr_check(const uint8 *ow_addr)
{
	if (NULL == ow_addr) return NULL;

	if (onewire_crc8(ow_addr, 8)) {
		errPrintf("%s bad ow_addr crc8\n", ds_msg);
		return NULL;
	}

	return ow_addr;		// dummy
}

static uint8 *
get_scratchpad(const uint8 *ow_addr)
{
	static uint8	scratchpad[9];

	if (!onewire_reset(ow_pin)) return NULL;
        onewire_select(ow_pin, ow_addr);
        onewire_write(ow_pin, 0xBE, 1);	// READ SCRATCHPAD

	onewire_read_bytes(ow_pin, scratchpad, 9);
	if (onewire_crc8(scratchpad, 9)) {
		errPrintf("%s bad scratchpad crc8\n", ds_msg);
		return NULL;
	}

	return scratchpad;
}

static uint8
convert_t(const uint8 *ow_addr)
{
	if (!onewire_reset(ow_pin)) return 0;
	onewire_select(ow_pin, ow_addr);
	onewire_write(ow_pin, 0x44, 1);	// CONVERT T

	return 1;
}

sint32	// fixed point, 4 decimal fractions
ds18b20_read(const uint8 *ow_addr)
{
	sint32		frac;
	uint8		*data;
	sint32		t;

	if (255 == ow_pin) {
		errPrintf("%s onewire pin not set\n", ds_msg);
		return BAD_RET;
	}

	if (NULL == (ow_addr = addr_check (ow_addr))) return BAD_RET;

	switch (ow_addr[0]) {
	case 0x28:
		frac = 10000/16;	// DS18B20, 4 fractional bits
		break;
	case 0x10:
		frac = 10000/2;		// DS18S20, 1 fractional bit
		break;
	default:
		errPrintf("%s unkown device %x\n", ds_msg, ow_addr[0]);
		return BAD_RET;
	}

	if (NULL == (data = get_scratchpad(ow_addr))) return BAD_RET;

	(void)convert_t(ow_addr);	// start next conversion

	t = frac * (sint16)(data[0] | data[1]<<8);
	return t == 850000 ? BAD_RET : t;
}
