/**
 * @file pm_strpbrk.h
 *
 * A custom strpbrk implementation.
 */
#ifndef PRISM_STRPBRK_H
#define PRISM_STRPBRK_H

#include "prism/defines.h"
#include "prism/parser.h"

#include <stddef.h>
#include <string.h>

/**
 * Here we have rolled our own version of strpbrk. The standard library strpbrk
 * has undefined behavior when the source string is not null-terminated. We want
 * to support strings that are not null-terminated because pm_parse does not
 * have the contract that the string is null-terminated. (This is desirable
 * because it means the extension can call pm_parse with the result of a call to
 * mmap).
 *
 * The standard library strpbrk also does not support passing a maximum length
 * to search. We want to support this for the reason mentioned above, but we
 * also don't want it to stop on null bytes. Ruby actually allows null bytes
 * within strings, comments, regular expressions, etc. So we need to be able to
 * skip past them.
 *
 * Finally, we want to support encodings wherein the charset could contain
 * characters that are trailing bytes of multi-byte characters. For example, in
 * Shift-JIS, the backslash character can be a trailing byte. In that case we
 * need to take a slower path and iterate one multi-byte character at a time.
 *
 * @param parser The parser.
 * @param source The source to search.
 * @param charset The charset to search for.
 * @param length The maximum number of bytes to search.
 * @return A pointer to the first character in the source string that is in the
 *     charset, or NULL if no such character exists.
 */
const uint8_t * pm_strpbrk(const pm_parser_t *parser, const uint8_t *source, const uint8_t *charset, ptrdiff_t length);

#endif
