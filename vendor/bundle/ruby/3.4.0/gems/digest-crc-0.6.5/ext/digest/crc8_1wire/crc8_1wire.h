#ifndef _CRC8_1WIRE_H_
#define _CRC8_1WIRE_H_

#include "../crc8/crc8.h"

crc8_t crc8_1wire_update(crc8_t crc, const void *data, size_t data_len);

#endif
