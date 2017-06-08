/*
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
     along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/*
 no support for DS18S20
 no ow search
 Only reading temp (12 bits) supported
 Does not deal with parasitic power properly
*/

#include "driver/gpio.h"
#include "rom/ets_sys.h"

#include "udp.h"
#include "ds18b20.h"
#include "onewire.h"

#define DS18B20_DEVICE_ID		0x28
#define DS18S20_DEVICE_ID		0x10

#define DS18B20_SEARCH_ROM		0xF0
#define DS18B20_READ_ROM		0x33
#define DS18B20_MATCH_ROM		0x55
#define DS18B20_SKIP_ROM		0xCC
#define DS18B20_ALARM_SEARCH		0xEC
#define DS18B20_CONVERT_T		0x44
#define DS18B20_WRITE_SCRATCHPAD	0x4E
#define DS18B20_READ_SCRATCHPAD		0xBE
#define DS18B20_COPY_SCRATCHPAD		0x48
#define DS18B20_RECALL_E		0xB8
#define DS18B20_READ_POWER_SUPPLY	0xB4

static int inited = 0;
static uint8_t rom_id[8] = {0};

static esp_err_t ds18b20_send_command(uint8_t cmd)
{
	uint8_t	b[1];

	DbgR (ow_reset());

	if (DS18B20_READ_ROM == cmd)
		{}
	else if (0 != rom_id[0]) {
		b[0] = DS18B20_MATCH_ROM;
		DbgR (ow_write_byte(b));
		DbgR (ow_write_bytes(8, rom_id));
	} else {
		b[0] = DS18B20_SKIP_ROM;
		DbgR (ow_write_byte(b));
	}

	b[0] = cmd;
	DbgR (ow_write_byte(b));

	return ESP_OK;
}

static esp_err_t ds18b20_read_scratchpad(uint8_t *scratchpad)
{
	uint8_t crc;

	if(!inited) DbgR (ESP_FAIL);

	DbgR (ds18b20_send_command (DS18B20_READ_SCRATCHPAD));
	DbgR (ow_read_bytes (9, scratchpad));

	if (scratchpad[8] != (crc = onewire_crc8(scratchpad, 8))) {
		Log ("### %s:%d: bad scratchpad crc %02x, read %02x",
			__FILE__, __LINE__, crc, scratchpad[8]);
		return ESP_FAIL;
	}

	return ESP_OK;
}

esp_err_t ds18b20_read_temp(float *temp)
{
	uint8_t scratchpad[9];
	int16_t t;

	*temp = BAD_TEMP;
	DbgR (ds18b20_read_scratchpad(scratchpad));
	t = ((int16_t)scratchpad[1]<<8) | scratchpad[0];
	if (85*16 == t || 0x07ff == t) {	// common bad readings
		*temp = BAD_TEMP + .01;
		Log ("### %s:%d: bad temp %.4f 0x%04x", __FILE__, __LINE__, t/16., t);
		return ESP_FAIL;
	}
	*temp = t / 16.0;

	return ESP_OK;
}

esp_err_t ds18b20_convert (int wait)
{
	if(!inited) DbgR (ESP_FAIL);

	DbgR (ds18b20_send_command (DS18B20_CONVERT_T));

	if (wait) {
		uint8_t ready;
		int ms = 750;

		do {
			if (ms-- <= 0) DbgR (ESP_FAIL);
			delay_ms (1);
			DbgR (ow_read_bits (1, &ready));
		} while (!ready);
	}

	return ESP_OK;
}

esp_err_t ds18b20_depower (void)
{
	DbgR (ow_depower());

	return ESP_OK;
}

esp_err_t ds18b20_read_id (uint8_t *id)
{
	uint8_t crc;

	DbgR (ds18b20_send_command (DS18B20_READ_ROM));
	DbgR (ow_read_bytes (8, id));
	if (id[7] != (crc = onewire_crc8(id, 7))) {
		Log ("### %s:%d: bad id crc %02x, read %02x",
			__FILE__, __LINE__, crc, id[7]);
		return ESP_FAIL;
	}

	return ESP_OK;
}

esp_err_t ds18b20_init (uint8_t pin, uint8_t *id)
{
	DbgR (ow_init (pin));

	if (NULL != id) {
		if (id[7] != onewire_crc8(id, 7)) {
			Log ("### %s:%d: bad id, crc check failed",
				__FILE__, __LINE__);
			return ESP_FAIL;
		}
		if (id[0] != DS18B20_DEVICE_ID) {	// not a ds18b20
			Log ("### %s:%d: device type %02x not a ds18b20 (%02x)",
				__FILE__, __LINE__, id[0], DS18B20_DEVICE_ID);
			return ESP_FAIL;
		}
		memcpy (rom_id, id, 8);
	}

	inited = 1;

	return ESP_OK;
}

