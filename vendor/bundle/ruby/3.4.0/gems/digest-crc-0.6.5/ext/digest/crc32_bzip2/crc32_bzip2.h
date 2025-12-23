#ifndef _CRC32_BZIP2_H_
#define _CRC32_BZIP2_H_

#include "../crc32/crc32.h"

crc32_t crc32_bzip2_update(crc32_t crc, const void *data, size_t data_len);

#endif
