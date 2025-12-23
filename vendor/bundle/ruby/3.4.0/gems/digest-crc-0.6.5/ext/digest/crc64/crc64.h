#ifndef _CRC64_H_
#define _CRC64_H_

#include <stdint.h>
#include <stddef.h>

typedef uint64_t crc64_t;

crc64_t crc64_update(crc64_t crc, const void *data, size_t data_len);

#endif
