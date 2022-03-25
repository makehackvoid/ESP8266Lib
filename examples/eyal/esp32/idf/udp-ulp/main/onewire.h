#ifndef _ONEWIRE_H
#define _ONEWIRE_H

#define ow_read_bytes(n, data)	ow_read_bits((n)*8, data)
#define ow_read_byte(data)	ow_read_bytes(1, data)

#define ow_write_bytes(n, data)	ow_write_bits((n)*8, data)
#define ow_write_byte(data)	ow_write_bytes(1, data)

esp_err_t ow_write_bits (int nbits, uint8_t *data);
esp_err_t ow_read_bits (int nbits, uint8_t *data);
esp_err_t ow_reset(void);
esp_err_t ow_depower (void);
esp_err_t ow_init (uint8_t pin);

uint8_t onewire_crc8(const uint8_t *addr, uint8_t len);
uint16_t onewire_crc16(const uint8_t* input, uint16_t len, uint16_t crc);
bool onewire_check_crc16(const uint8_t* input, uint16_t len, const uint8_t* inverted_crc, uint16_t crc);

#endif // _ONEWIRE_H
