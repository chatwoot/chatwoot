#ifndef _CRC16_CCITT_H_
#define _CRC16_CCITT_H_

#include "../crc16/crc16.h"

crc16_t crc16_ccitt_update(crc16_t crc, const void *data, size_t data_len);

#endif
