#include "prism/util/pm_strncasecmp.h"

/**
 * A locale-insensitive version of `tolower(3)`
 */
static inline int
pm_tolower(int c)
{
    if ('A' <= c && c <= 'Z') {
        return c | 0x20;
    }
    return c;
}

/**
 * Compare two strings, ignoring case, up to the given length. Returns 0 if the
 * strings are equal, a negative number if string1 is less than string2, or a
 * positive number if string1 is greater than string2.
 *
 * Note that this is effectively our own implementation of strncasecmp, but it's
 * not available on all of the platforms we want to support so we're rolling it
 * here.
 */
int
pm_strncasecmp(const uint8_t *string1, const uint8_t *string2, size_t length) {
    size_t offset = 0;
    int difference = 0;

    while (offset < length && string1[offset] != '\0') {
        if (string2[offset] == '\0') return string1[offset];
        if ((difference = pm_tolower(string1[offset]) - pm_tolower(string2[offset])) != 0) return difference;
        offset++;
    }

    return difference;
}
