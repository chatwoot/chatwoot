// Copyright (c) 2019 Peter Ohler. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for license details.

#ifndef OJ_UTIL_H
#define OJ_UTIL_H

#include <stdint.h>

typedef struct _timeInfo {
    int sec;
    int min;
    int hour;
    int day;
    int mon;
    int year;
}* TimeInfo;

extern void sec_as_time(int64_t secs, TimeInfo ti);

#endif /* OJ_UTIL_H */
