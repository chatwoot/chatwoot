/**
 * @file pm_memchr.h
 *
 * A custom memchr implementation.
 */
#ifndef PRISM_MEMCHR_H
#define PRISM_MEMCHR_H

#include "prism/defines.h"
#include "prism/encoding.h"

#include <stddef.h>

/**
 * We need to roll our own memchr to handle cases where the encoding changes and
 * we need to search for a character in a buffer that could be the trailing byte
 * of a multibyte character.
 *
 * @param source The source string.
 * @param character The character to search for.
 * @param number The maximum number of bytes to search.
 * @param encoding_changed Whether the encoding changed.
 * @param encoding A pointer to the encoding.
 * @return A pointer to the first occurrence of the character in the source
 *     string, or NULL if no such character exists.
 */
void * pm_memchr(const void *source, int character, size_t number, bool encoding_changed, const pm_encoding_t *encoding);

#endif
