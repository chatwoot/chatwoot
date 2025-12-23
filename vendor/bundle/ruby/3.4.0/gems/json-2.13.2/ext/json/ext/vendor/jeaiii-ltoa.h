/*

This file is released under the terms of the MIT License. It is based on the
work of James Edward Anhalt III, with the original license listed below.

MIT License

Copyright (c) 2024,2025 Enrico Thierbach - https://github.com/radiospiel
Copyright (c) 2022 James Edward Anhalt III - https://github.com/jeaiii/itoa

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#ifndef JEAIII_TO_TEXT_H_
#define JEAIII_TO_TEXT_H_

#include <stdint.h>

typedef uint_fast32_t u32_t;
typedef uint_fast64_t u64_t;

#define u32(x) ((u32_t)(x))
#define u64(x) ((u64_t)(x))

struct digit_pair
{
    char dd[2];
};

static const struct digit_pair *digits_dd = (struct digit_pair *)(
    "00" "01" "02" "03" "04" "05" "06" "07" "08" "09"
    "10" "11" "12" "13" "14" "15" "16" "17" "18" "19"
    "20" "21" "22" "23" "24" "25" "26" "27" "28" "29"
    "30" "31" "32" "33" "34" "35" "36" "37" "38" "39"
    "40" "41" "42" "43" "44" "45" "46" "47" "48" "49"
    "50" "51" "52" "53" "54" "55" "56" "57" "58" "59"
    "60" "61" "62" "63" "64" "65" "66" "67" "68" "69"
    "70" "71" "72" "73" "74" "75" "76" "77" "78" "79"
    "80" "81" "82" "83" "84" "85" "86" "87" "88" "89"
    "90" "91" "92" "93" "94" "95" "96" "97" "98" "99"
);

static const struct digit_pair *digits_fd = (struct digit_pair *)(
    "0_" "1_" "2_" "3_" "4_" "5_" "6_" "7_" "8_" "9_"
    "10" "11" "12" "13" "14" "15" "16" "17" "18" "19"
    "20" "21" "22" "23" "24" "25" "26" "27" "28" "29"
    "30" "31" "32" "33" "34" "35" "36" "37" "38" "39"
    "40" "41" "42" "43" "44" "45" "46" "47" "48" "49"
    "50" "51" "52" "53" "54" "55" "56" "57" "58" "59"
    "60" "61" "62" "63" "64" "65" "66" "67" "68" "69"
    "70" "71" "72" "73" "74" "75" "76" "77" "78" "79"
    "80" "81" "82" "83" "84" "85" "86" "87" "88" "89"
    "90" "91" "92" "93" "94" "95" "96" "97" "98" "99"
);

static const u64_t mask24 = (u64(1) << 24) - 1;
static const u64_t mask32 = (u64(1) << 32) - 1;
static const u64_t mask57 = (u64(1) << 57) - 1;

#define COPY(buffer, digits) memcpy(buffer, &(digits), sizeof(struct digit_pair))

static char *
jeaiii_ultoa(char *b, u64_t n)
{
    if (n < u32(1e2)) {
        COPY(b, digits_fd[n]);
        return n < 10 ? b + 1 : b + 2;
    }

    if (n < u32(1e6)) {
        if (n < u32(1e4)) {
            u32_t f0 = u32((10 * (1 << 24) / 1e3 + 1) * n);
            COPY(b, digits_fd[f0 >> 24]);

            b -= n < u32(1e3);
            u32_t f2 = (f0 & mask24) * 100;
            COPY(b + 2, digits_dd[f2 >> 24]);

            return b + 4;
        }

        u64_t f0 = u64(10 * (1ull << 32ull)/ 1e5 + 1) * n;
        COPY(b, digits_fd[f0 >> 32]);

        b -= n < u32(1e5);
        u64_t f2 = (f0 & mask32) * 100;
        COPY(b + 2, digits_dd[f2 >> 32]);

        u64_t f4 = (f2 & mask32) * 100;
        COPY(b + 4, digits_dd[f4 >> 32]);
        return b + 6;
    }

    if (n < u64(1ull << 32ull)) {
        if (n < u32(1e8)) {
            u64_t f0 = u64(10 * (1ull << 48ull) / 1e7 + 1) * n >> 16;
            COPY(b, digits_fd[f0 >> 32]);

            b -= n < u32(1e7);
            u64_t f2 = (f0 & mask32) * 100;
            COPY(b + 2, digits_dd[f2 >> 32]);

            u64_t f4 = (f2 & mask32) * 100;
            COPY(b + 4, digits_dd[f4 >> 32]);

            u64_t f6 = (f4 & mask32) * 100;
            COPY(b + 6, digits_dd[f6 >> 32]);

            return b + 8;
        }

        u64_t f0 = u64(10 * (1ull << 57ull) / 1e9 + 1) * n;
        COPY(b, digits_fd[f0 >> 57]);

        b -= n < u32(1e9);
        u64_t f2 = (f0 & mask57) * 100;
        COPY(b + 2, digits_dd[f2 >> 57]);

        u64_t f4 = (f2 & mask57) * 100;
        COPY(b + 4, digits_dd[f4 >> 57]);

        u64_t f6 = (f4 & mask57) * 100;
        COPY(b + 6, digits_dd[f6 >> 57]);

        u64_t f8 = (f6 & mask57) * 100;
        COPY(b + 8, digits_dd[f8 >> 57]);

        return b + 10;
    }

    // if we get here U must be u64 but some compilers don't know that, so reassign n to a u64 to avoid warnings
    u32_t z = n % u32(1e8);
    u64_t u = n / u32(1e8);

    if (u < u32(1e2)) {
        // u can't be 1 digit (if u < 10 it would have been handled above as a 9 digit 32bit number)
        COPY(b, digits_dd[u]);
        b += 2;
    }
    else if (u < u32(1e6)) {
        if (u < u32(1e4)) {
            u32_t f0 = u32((10 * (1 << 24) / 1e3 + 1) * u);
            COPY(b, digits_fd[f0 >> 24]);

            b -= u < u32(1e3);
            u32_t f2 = (f0 & mask24) * 100;
            COPY(b + 2, digits_dd[f2 >> 24]);
            b += 4;
        }
        else {
            u64_t f0 = u64(10 * (1ull << 32ull) / 1e5 + 1) * u;
            COPY(b, digits_fd[f0 >> 32]);

            b -= u < u32(1e5);
            u64_t f2 = (f0 & mask32) * 100;
            COPY(b + 2, digits_dd[f2 >> 32]);

            u64_t f4 = (f2 & mask32) * 100;
            COPY(b + 4, digits_dd[f4 >> 32]);
            b += 6;
        }
    }
    else if (u < u32(1e8)) {
        u64_t f0 = u64(10 * (1ull << 48ull) / 1e7 + 1) * u >> 16;
        COPY(b, digits_fd[f0 >> 32]);

        b -= u < u32(1e7);
        u64_t f2 = (f0 & mask32) * 100;
        COPY(b + 2, digits_dd[f2 >> 32]);

        u64_t f4 = (f2 & mask32) * 100;
        COPY(b + 4, digits_dd[f4 >> 32]);

        u64_t f6 = (f4 & mask32) * 100;
        COPY(b + 6, digits_dd[f6 >> 32]);

        b += 8;
    }
    else if (u < u64(1ull << 32ull)) {
        u64_t f0 = u64(10 * (1ull << 57ull) / 1e9 + 1) * u;
        COPY(b, digits_fd[f0 >> 57]);

        b -= u < u32(1e9);
        u64_t f2 = (f0 & mask57) * 100;
        COPY(b + 2, digits_dd[f2 >> 57]);

        u64_t f4 = (f2 & mask57) * 100;
        COPY(b + 4, digits_dd[f4 >> 57]);

        u64_t f6 = (f4 & mask57) * 100;
        COPY(b + 6, digits_dd[f6 >> 57]);

        u64_t f8 = (f6 & mask57) * 100;
        COPY(b + 8, digits_dd[f8 >> 57]);
        b += 10;
    }
    else {
        u32_t y = u % u32(1e8);
        u /= u32(1e8);

        // u is 2, 3, or 4 digits (if u < 10 it would have been handled above)
        if (u < u32(1e2)) {
            COPY(b, digits_dd[u]);
            b += 2;
        }
        else {
            u32_t f0 = u32((10 * (1 << 24) / 1e3 + 1) * u);
            COPY(b, digits_fd[f0 >> 24]);

            b -= u < u32(1e3);
            u32_t f2 = (f0 & mask24) * 100;
            COPY(b + 2, digits_dd[f2 >> 24]);

            b += 4;
        }
        // do 8 digits
        u64_t f0 = (u64((1ull << 48ull) / 1e6 + 1) * y >> 16) + 1;
        COPY(b, digits_dd[f0 >> 32]);

        u64_t f2 = (f0 & mask32) * 100;
        COPY(b + 2, digits_dd[f2 >> 32]);

        u64_t f4 = (f2 & mask32) * 100;
        COPY(b + 4, digits_dd[f4 >> 32]);

        u64_t f6 = (f4 & mask32) * 100;
        COPY(b + 6, digits_dd[f6 >> 32]);
        b += 8;
    }

    // do 8 digits
    u64_t f0 = (u64((1ull << 48ull) / 1e6 + 1) * z >> 16) + 1;
    COPY(b, digits_dd[f0 >> 32]);

    u64_t f2 = (f0 & mask32) * 100;
    COPY(b + 2, digits_dd[f2 >> 32]);

    u64_t f4 = (f2 & mask32) * 100;
    COPY(b + 4, digits_dd[f4 >> 32]);

    u64_t f6 = (f4 & mask32) * 100;
    COPY(b + 6, digits_dd[f6 >> 32]);

    return b + 8;
}

#undef u32
#undef u64
#undef COPY

#endif // JEAIII_TO_TEXT_H_
