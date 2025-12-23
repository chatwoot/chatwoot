#ifndef _CRC16_GENIBUS_H_
#define _CRC16_GENIBUS_H_

#include "../crc16/crc16.h"

crc16_t crc16_genibus_update(crc16_t crc, const void *data, size_t data_len);

#endif
