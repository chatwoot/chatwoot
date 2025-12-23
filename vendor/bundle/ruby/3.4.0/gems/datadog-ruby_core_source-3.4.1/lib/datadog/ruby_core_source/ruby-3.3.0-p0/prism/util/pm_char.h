/**
 * @file pm_char.h
 *
 * Functions for working with characters and strings.
 */
#ifndef PRISM_CHAR_H
#define PRISM_CHAR_H

#include "prism/defines.h"
#include "prism/util/pm_newline_list.h"

#include <stdbool.h>
#include <stddef.h>

/**
 * Returns the number of characters at the start of the string that are
 * whitespace. Disallows searching past the given maximum number of characters.
 *
 * @param string The string to search.
 * @param length The maximum number of characters to search.
 * @return The number of characters at the start of the string that are
 *     whitespace.
 */
size_t pm_strspn_whitespace(const uint8_t *string, ptrdiff_t length);

/**
 * Returns the number of characters at the start of the string that are
 * whitespace while also tracking the location of each newline. Disallows
 * searching past the given maximum number of characters.
 *
 * @param string The string to search.
 * @param length The maximum number of characters to search.
 * @param newline_list The list of newlines to populate.
 * @return The number of characters at the start of the string that are
 *     whitespace.
 */
size_t
pm_strspn_whitespace_newlines(const uint8_t *string, ptrdiff_t length, pm_newline_list_t *newline_list);

/**
 * Returns the number of characters at the start of the string that are inline
 * whitespace. Disallows searching past the given maximum number of characters.
 *
 * @param string The string to search.
 * @param length The maximum number of characters to search.
 * @return The number of characters at the start of the string that are inline
 *     whitespace.
 */
size_t pm_strspn_inline_whitespace(const uint8_t *string, ptrdiff_t length);

/**
 * Returns the number of characters at the start of the string that are decimal
 * digits. Disallows searching past the given maximum number of characters.
 *
 * @param string The string to search.
 * @param length The maximum number of characters to search.
 * @return The number of characters at the start of the string that are decimal
 *     digits.
 */
size_t pm_strspn_decimal_digit(const uint8_t *string, ptrdiff_t length);

/**
 * Returns the number of characters at the start of the string that are
 * hexadecimal digits. Disallows searching past the given maximum number of
 * characters.
 *
 * @param string The string to search.
 * @param length The maximum number of characters to search.
 * @return The number of characters at the start of the string that are
 *     hexadecimal digits.
 */
size_t pm_strspn_hexadecimal_digit(const uint8_t *string, ptrdiff_t length);

/**
 * Returns the number of characters at the start of the string that are octal
 * digits or underscores. Disallows searching past the given maximum number of
 * characters.
 *
 * If multiple underscores are found in a row or if an underscore is
 * found at the end of the number, then the invalid pointer is set to the index
 * of the first invalid underscore.
 *
 * @param string The string to search.
 * @param length The maximum number of characters to search.
 * @param invalid The pointer to set to the index of the first invalid
 *     underscore.
 * @return The number of characters at the start of the string that are octal
 *     digits or underscores.
 */
size_t pm_strspn_octal_number(const uint8_t *string, ptrdiff_t length, const uint8_t **invalid);

/**
 * Returns the number of characters at the start of the string that are decimal
 * digits or underscores. Disallows searching past the given maximum number of
 * characters.
 *
 * If multiple underscores are found in a row or if an underscore is
 * found at the end of the number, then the invalid pointer is set to the index
 * of the first invalid underscore.
 *
 * @param string The string to search.
 * @param length The maximum number of characters to search.
 * @param invalid The pointer to set to the index of the first invalid
 *     underscore.
 * @return The number of characters at the start of the string that are decimal
 *     digits or underscores.
 */
size_t pm_strspn_decimal_number(const uint8_t *string, ptrdiff_t length, const uint8_t **invalid);

/**
 * Returns the number of characters at the start of the string that are
 * hexadecimal digits or underscores. Disallows searching past the given maximum
 * number of characters.
 *
 * If multiple underscores are found in a row or if an underscore is
 * found at the end of the number, then the invalid pointer is set to the index
 * of the first invalid underscore.
 *
 * @param string The string to search.
 * @param length The maximum number of characters to search.
 * @param invalid The pointer to set to the index of the first invalid
 *     underscore.
 * @return The number of characters at the start of the string that are
 *     hexadecimal digits or underscores.
 */
size_t pm_strspn_hexadecimal_number(const uint8_t *string, ptrdiff_t length, const uint8_t **invalid);

/**
 * Returns the number of characters at the start of the string that are regexp
 * options. Disallows searching past the given maximum number of characters.
 *
 * @param string The string to search.
 * @param length The maximum number of characters to search.
 * @return The number of characters at the start of the string that are regexp
 *     options.
 */
size_t pm_strspn_regexp_option(const uint8_t *string, ptrdiff_t length);

/**
 * Returns the number of characters at the start of the string that are binary
 * digits or underscores. Disallows searching past the given maximum number of
 * characters.
 *
 * If multiple underscores are found in a row or if an underscore is
 * found at the end of the number, then the invalid pointer is set to the index
 * of the first invalid underscore.
 *
 * @param string The string to search.
 * @param length The maximum number of characters to search.
 * @param invalid The pointer to set to the index of the first invalid
 *     underscore.
 * @return The number of characters at the start of the string that are binary
 *     digits or underscores.
 */
size_t pm_strspn_binary_number(const uint8_t *string, ptrdiff_t length, const uint8_t **invalid);

/**
 * Returns true if the given character is a whitespace character.
 *
 * @param b The character to check.
 * @return True if the given character is a whitespace character.
 */
bool pm_char_is_whitespace(const uint8_t b);

/**
 * Returns true if the given character is an inline whitespace character.
 *
 * @param b The character to check.
 * @return True if the given character is an inline whitespace character.
 */
bool pm_char_is_inline_whitespace(const uint8_t b);

/**
 * Returns true if the given character is a binary digit.
 *
 * @param b The character to check.
 * @return True if the given character is a binary digit.
 */
bool pm_char_is_binary_digit(const uint8_t b);

/**
 * Returns true if the given character is an octal digit.
 *
 * @param b The character to check.
 * @return True if the given character is an octal digit.
 */
bool pm_char_is_octal_digit(const uint8_t b);

/**
 * Returns true if the given character is a decimal digit.
 *
 * @param b The character to check.
 * @return True if the given character is a decimal digit.
 */
bool pm_char_is_decimal_digit(const uint8_t b);

/**
 * Returns true if the given character is a hexadecimal digit.
 *
 * @param b The character to check.
 * @return True if the given character is a hexadecimal digit.
 */
bool pm_char_is_hexadecimal_digit(const uint8_t b);

#endif
