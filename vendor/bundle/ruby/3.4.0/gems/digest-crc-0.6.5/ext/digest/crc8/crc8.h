#ifndef _CRC8_H_
#define _CRC8_H_

#include <stdint.h>
#include <stddef.h>

typedef uint8_t crc8_t;

crc8_t crc8_update(crc8_t crc, const void *data, size_t data_len);

#endif
