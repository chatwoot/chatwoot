#ifndef _CRC12_3GPP_H_
#define _CRC12_3GPP_H_

#include <stdint.h>
#include <stddef.h>

typedef uint16_t crc12_t;

crc12_t crc12_3gpp_update(crc12_t crc, const void *data, size_t data_len);

#endif
