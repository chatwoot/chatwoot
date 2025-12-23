#ifndef _CRC16_X_25_H_
#define _CRC16_X_25_H_

#include "../crc16/crc16.h"

crc16_t crc16_x_25_update(crc16_t crc, const void *data, size_t data_len);

#endif
