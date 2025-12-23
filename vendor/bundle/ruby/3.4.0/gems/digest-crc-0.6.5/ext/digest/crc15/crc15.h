#ifndef _CRC15_H_
#define _CRC15_H_

#include <stdint.h>
#include <stddef.h>

typedef uint16_t crc15_t;

crc15_t crc15_update(crc15_t crc, const void *data, size_t data_len);

#endif
