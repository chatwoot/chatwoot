#ifndef _CRC32_H_
#define _CRC32_H_

#include <stdint.h>
#include <stddef.h>

typedef uint32_t crc32_t;

crc32_t crc32_update(crc32_t crc, const void *data, size_t data_len);

#endif
