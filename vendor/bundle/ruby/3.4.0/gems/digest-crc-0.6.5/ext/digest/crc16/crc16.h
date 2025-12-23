#ifndef _CRC16_H_
#define _CRC16_H_

#include <stdint.h>
#include <stddef.h>

typedef uint16_t crc16_t;

crc16_t crc16_update(crc16_t crc, const void *data, size_t data_len);

#endif
