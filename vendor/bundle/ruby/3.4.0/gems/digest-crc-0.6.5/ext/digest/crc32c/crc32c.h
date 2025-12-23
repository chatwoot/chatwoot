#ifndef _CRC32C_H_
#define _CRC32C_H_

#include "../crc32/crc32.h"

crc32_t crc32c_update(crc32_t crc, const void *data, size_t data_len);

#endif
