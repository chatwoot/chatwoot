/**
 * @file pm_strncasecmp.h
 *
 * A custom strncasecmp implementation.
 */
#ifndef PRISM_STRNCASECMP_H
#define PRISM_STRNCASECMP_H

#include "prism/defines.h"

#include <ctype.h>
#include <stddef.h>
#include <stdint.h>

/**
 * Compare two strings, ignoring case, up to the given length. Returns 0 if the
 * strings are equal, a negative number if string1 is less than string2, or a
 * positive number if string1 is greater than string2.
 *
 * Note that this is effectively our own implementation of strncasecmp, but it's
 * not available on all of the platforms we want to support so we're rolling it
 * here.
 *
 * @param string1 The first string to compare.
 * @param string2 The second string to compare
 * @param length The maximum number of characters to compare.
 * @return 0 if the strings are equal, a negative number if string1 is less than
 *     string2, or a positive number if string1 is greater than string2.
 */
int pm_strncasecmp(const uint8_t *string1, const uint8_t *string2, size_t length);

#endif
