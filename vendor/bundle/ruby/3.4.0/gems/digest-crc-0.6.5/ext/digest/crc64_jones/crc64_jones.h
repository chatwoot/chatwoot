#ifndef _CRC64_JONES_H_
#define _CRC64_JONES_H_

#include "../crc64/crc64.h"

crc64_t crc64_jones_update(crc64_t crc, const void *data, size_t data_len);

#endif
