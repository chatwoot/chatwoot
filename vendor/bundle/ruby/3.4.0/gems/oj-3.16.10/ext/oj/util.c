// Copyright (c) 2019 Peter Ohler. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for license details.

#include "util.h"

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

#define SECS_PER_DAY 86400LL
#define SECS_PER_YEAR 31536000LL
#define SECS_PER_LEAP 31622400LL
#define SECS_PER_QUAD_YEAR (SECS_PER_YEAR * 3 + SECS_PER_LEAP)
#define SECS_PER_CENT (SECS_PER_QUAD_YEAR * 24 + SECS_PER_YEAR * 4)
#define SECS_PER_LEAP_CENT (SECS_PER_CENT + SECS_PER_DAY)
#define SECS_PER_QUAD_CENT (SECS_PER_CENT * 4 + SECS_PER_DAY)

static int64_t eom_secs[] = {
    2678400,   // January (31)
    5097600,   // February (28)	2419200	 2505600
    7776000,   // March (31)
    10368000,  // April (30  2592000
    13046400,  // May (31)
    15638400,  // June (30)
    18316800,  // July (31)
    20995200,  // August (31)
    23587200,  // September (30)
    26265600,  // October (31)
    28857600,  // November (30)
    31536000,  // December (31)
};

static int64_t eom_leap_secs[] = {
    2678400,   // January (31)
    5184000,   // February (28)	2419200	 2505600
    7862400,   // March (31)
    10454400,  // April (30  2592000
    13132800,  // May (31)
    15724800,  // June (30)
    18403200,  // July (31)
    21081600,  // August (31)
    23673600,  // September (30)
    26352000,  // October (31)
    28944000,  // November (30)
    31622400,  // December (31)
};

void sec_as_time(int64_t secs, TimeInfo ti) {
    int64_t  qc   = 0;
    int64_t  c    = 0;
    int64_t  qy   = 0;
    int64_t  y    = 0;
    bool     leap = false;
    int64_t *ms;
    int      m;
    int      shift = 0;

    secs += 62167219200LL;  // normalize to first day of the year 0
    if (secs < 0) {
        shift = -secs / SECS_PER_QUAD_CENT;
        shift++;
        secs += shift * SECS_PER_QUAD_CENT;
    }
    qc   = secs / SECS_PER_QUAD_CENT;
    secs = secs - qc * SECS_PER_QUAD_CENT;
    if (secs < SECS_PER_LEAP) {
        leap = true;
    } else if (secs < SECS_PER_QUAD_YEAR) {
        if (SECS_PER_LEAP <= secs) {
            secs -= SECS_PER_LEAP;
            y    = secs / SECS_PER_YEAR;
            secs = secs - y * SECS_PER_YEAR;
            y++;
            leap = false;
        }
    } else if (secs < SECS_PER_LEAP_CENT) {  // first century in 400 years is a leap century (one
                                             // extra day)
        qy   = secs / SECS_PER_QUAD_YEAR;
        secs = secs - qy * SECS_PER_QUAD_YEAR;
        if (secs < SECS_PER_LEAP) {
            leap = true;
        } else {
            secs -= SECS_PER_LEAP;
            y    = secs / SECS_PER_YEAR;
            secs = secs - y * SECS_PER_YEAR;
            y++;
        }
    } else {
        secs -= SECS_PER_LEAP_CENT;
        c    = secs / SECS_PER_CENT;
        secs = secs - c * SECS_PER_CENT;
        c++;
        if (secs < SECS_PER_YEAR * 4) {
            y    = secs / SECS_PER_YEAR;
            secs = secs - y * SECS_PER_YEAR;
        } else {
            secs -= SECS_PER_YEAR * 4;
            qy   = secs / SECS_PER_QUAD_YEAR;
            secs = secs - qy * SECS_PER_QUAD_YEAR;
            qy++;
            if (secs < SECS_PER_LEAP) {
                leap = true;
            } else {
                secs -= SECS_PER_LEAP;
                y    = secs / SECS_PER_YEAR;
                secs = secs - y * SECS_PER_YEAR;
                y++;
            }
        }
    }
    ti->year = (int)((qc - (int64_t)shift) * 400 + c * 100 + qy * 4 + y);
    if (leap) {
        ms = eom_leap_secs;
    } else {
        ms = eom_secs;
    }
    for (m = 1; m <= 12; m++, ms++) {
        if (secs < *ms) {
            if (1 < m) {
                secs -= *(ms - 1);
            }
            ti->mon = m;
            break;
        }
    }
    ti->day = (int)(secs / 86400LL);
    secs    = secs - (int64_t)ti->day * 86400LL;
    ti->day++;
    ti->hour = (int)(secs / 3600LL);
    secs     = secs - (int64_t)ti->hour * 3600LL;
    ti->min  = (int)(secs / 60LL);
    secs     = secs - (int64_t)ti->min * 60LL;
    ti->sec  = (int)secs;
}
