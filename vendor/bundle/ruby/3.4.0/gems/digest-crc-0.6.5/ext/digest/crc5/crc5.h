#ifndef _CRC5_H_
#define _CRC5_H_

#include <stdint.h>
#include <stddef.h>

typedef uint8_t crc5_t;

crc5_t crc5_update(crc5_t crc, const void *data, size_t data_len);

#endif
