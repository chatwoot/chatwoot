#ifndef _CRC24_H_
#define _CRC24_H_

#include <stdint.h>
#include <stddef.h>

typedef uint32_t crc24_t;

crc24_t crc24_update(crc24_t crc, const void *data, size_t data_len);

#endif
