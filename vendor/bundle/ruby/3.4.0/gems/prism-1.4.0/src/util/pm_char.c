#include "prism/util/pm_char.h"

#define PRISM_CHAR_BIT_WHITESPACE (1 << 0)
#define PRISM_CHAR_BIT_INLINE_WHITESPACE (1 << 1)
#define PRISM_CHAR_BIT_REGEXP_OPTION (1 << 2)

#define PRISM_NUMBER_BIT_BINARY_DIGIT (1 << 0)
#define PRISM_NUMBER_BIT_BINARY_NUMBER (1 << 1)
#define PRISM_NUMBER_BIT_OCTAL_DIGIT (1 << 2)
#define PRISM_NUMBER_BIT_OCTAL_NUMBER (1 << 3)
#define PRISM_NUMBER_BIT_DECIMAL_DIGIT (1 << 4)
#define PRISM_NUMBER_BIT_DECIMAL_NUMBER (1 << 5)
#define PRISM_NUMBER_BIT_HEXADECIMAL_DIGIT (1 << 6)
#define PRISM_NUMBER_BIT_HEXADECIMAL_NUMBER (1 << 7)

static const uint8_t pm_byte_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 1, 3, 3, 3, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 3x
    0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, // 4x
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 0, // 5x
    0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, // 6x
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

static const uint8_t pm_number_table[256] = {
    // 0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 0x
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 1x
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 2x
    0xff, 0xff, 0xfc, 0xfc, 0xfc, 0xfc, 0xfc, 0xfc, 0xf0, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 3x
    0x00, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 4x
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xaa, // 5x
    0x00, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 6x
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 7x
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 8x
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 9x
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // Ax
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // Bx
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // Cx
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // Dx
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // Ex
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // Fx
};

/**
 * Returns the number of characters at the start of the string that match the
 * given kind. Disallows searching past the given maximum number of characters.
 */
static inline size_t
pm_strspn_char_kind(const uint8_t *string, ptrdiff_t length, uint8_t kind) {
    if (length <= 0) return 0;

    size_t size = 0;
    size_t maximum = (size_t) length;

    while (size < maximum && (pm_byte_table[string[size]] & kind)) size++;
    return size;
}

/**
 * Returns the number of characters at the start of the string that are
 * whitespace. Disallows searching past the given maximum number of characters.
 */
size_t
pm_strspn_whitespace(const uint8_t *string, ptrdiff_t length) {
    return pm_strspn_char_kind(string, length, PRISM_CHAR_BIT_WHITESPACE);
}

/**
 * Returns the number of characters at the start of the string that are
 * whitespace while also tracking the location of each newline. Disallows
 * searching past the given maximum number of characters.
 */
size_t
pm_strspn_whitespace_newlines(const uint8_t *string, ptrdiff_t length, pm_newline_list_t *newline_list) {
    if (length <= 0) return 0;

    size_t size = 0;
    size_t maximum = (size_t) length;

    while (size < maximum && (pm_byte_table[string[size]] & PRISM_CHAR_BIT_WHITESPACE)) {
        if (string[size] == '\n') {
            pm_newline_list_append(newline_list, string + size);
        }

        size++;
    }

    return size;
}

/**
 * Returns the number of characters at the start of the string that are inline
 * whitespace. Disallows searching past the given maximum number of characters.
 */
size_t
pm_strspn_inline_whitespace(const uint8_t *string, ptrdiff_t length) {
    return pm_strspn_char_kind(string, length, PRISM_CHAR_BIT_INLINE_WHITESPACE);
}

/**
 * Returns the number of characters at the start of the string that are regexp
 * options. Disallows searching past the given maximum number of characters.
 */
size_t
pm_strspn_regexp_option(const uint8_t *string, ptrdiff_t length) {
    return pm_strspn_char_kind(string, length, PRISM_CHAR_BIT_REGEXP_OPTION);
}

/**
 * Returns true if the given character matches the given kind.
 */
static inline bool
pm_char_is_char_kind(const uint8_t b, uint8_t kind) {
    return (pm_byte_table[b] & kind) != 0;
}

/**
 * Returns true if the given character is a whitespace character.
 */
bool
pm_char_is_whitespace(const uint8_t b) {
    return pm_char_is_char_kind(b, PRISM_CHAR_BIT_WHITESPACE);
}

/**
 * Returns true if the given character is an inline whitespace character.
 */
bool
pm_char_is_inline_whitespace(const uint8_t b) {
    return pm_char_is_char_kind(b, PRISM_CHAR_BIT_INLINE_WHITESPACE);
}

/**
 * Scan through the string and return the number of characters at the start of
 * the string that match the given kind. Disallows searching past the given
 * maximum number of characters.
 */
static inline size_t
pm_strspn_number_kind(const uint8_t *string, ptrdiff_t length, uint8_t kind) {
    if (length <= 0) return 0;

    size_t size = 0;
    size_t maximum = (size_t) length;

    while (size < maximum && (pm_number_table[string[size]] & kind)) size++;
    return size;
}

/**
 * Scan through the string and return the number of characters at the start of
 * the string that match the given kind. Disallows searching past the given
 * maximum number of characters.
 *
 * Additionally, report the location of the last invalid underscore character
 * found in the string through the out invalid parameter.
 */
static inline size_t
pm_strspn_number_kind_underscores(const uint8_t *string, ptrdiff_t length, const uint8_t **invalid, uint8_t kind) {
    if (length <= 0) return 0;

    size_t size = 0;
    size_t maximum = (size_t) length;

    bool underscore = false;
    while (size < maximum && (pm_number_table[string[size]] & kind)) {
        if (string[size] == '_') {
            if (underscore) *invalid = string + size;
            underscore = true;
        } else {
            underscore = false;
        }

        size++;
    }

    if (size > 0 && string[size - 1] == '_') *invalid = string + size - 1;
    return size;
}

/**
 * Returns the number of characters at the start of the string that are binary
 * digits or underscores. Disallows searching past the given maximum number of
 * characters.
 *
 * If multiple underscores are found in a row or if an underscore is
 * found at the end of the number, then the invalid pointer is set to the index
 * of the first invalid underscore.
 */
size_t
pm_strspn_binary_number(const uint8_t *string, ptrdiff_t length, const uint8_t **invalid) {
    return pm_strspn_number_kind_underscores(string, length, invalid, PRISM_NUMBER_BIT_BINARY_NUMBER);
}

/**
 * Returns the number of characters at the start of the string that are octal
 * digits or underscores. Disallows searching past the given maximum number of
 * characters.
 *
 * If multiple underscores are found in a row or if an underscore is
 * found at the end of the number, then the invalid pointer is set to the index
 * of the first invalid underscore.
 */
size_t
pm_strspn_octal_number(const uint8_t *string, ptrdiff_t length, const uint8_t **invalid) {
    return pm_strspn_number_kind_underscores(string, length, invalid, PRISM_NUMBER_BIT_OCTAL_NUMBER);
}

/**
 * Returns the number of characters at the start of the string that are decimal
 * digits. Disallows searching past the given maximum number of characters.
 */
size_t
pm_strspn_decimal_digit(const uint8_t *string, ptrdiff_t length) {
    return pm_strspn_number_kind(string, length, PRISM_NUMBER_BIT_DECIMAL_DIGIT);
}

/**
 * Returns the number of characters at the start of the string that are decimal
 * digits or underscores. Disallows searching past the given maximum number of
 * characters.
 *
 * If multiple underscores are found in a row or if an underscore is
 * found at the end of the number, then the invalid pointer is set to the index
 * of the first invalid underscore
 */
size_t
pm_strspn_decimal_number(const uint8_t *string, ptrdiff_t length, const uint8_t **invalid) {
    return pm_strspn_number_kind_underscores(string, length, invalid, PRISM_NUMBER_BIT_DECIMAL_NUMBER);
}

/**
 * Returns the number of characters at the start of the string that are
 * hexadecimal digits. Disallows searching past the given maximum number of
 * characters.
 */
size_t
pm_strspn_hexadecimal_digit(const uint8_t *string, ptrdiff_t length) {
    return pm_strspn_number_kind(string, length, PRISM_NUMBER_BIT_HEXADECIMAL_DIGIT);
}

/**
 * Returns the number of characters at the start of the string that are
 * hexadecimal digits or underscores. Disallows searching past the given maximum
 * number of characters.
 *
 * If multiple underscores are found in a row or if an underscore is
 * found at the end of the number, then the invalid pointer is set to the index
 * of the first invalid underscore.
 */
size_t
pm_strspn_hexadecimal_number(const uint8_t *string, ptrdiff_t length, const uint8_t **invalid) {
    return pm_strspn_number_kind_underscores(string, length, invalid, PRISM_NUMBER_BIT_HEXADECIMAL_NUMBER);
}

/**
 * Returns true if the given character matches the given kind.
 */
static inline bool
pm_char_is_number_kind(const uint8_t b, uint8_t kind) {
    return (pm_number_table[b] & kind) != 0;
}

/**
 * Returns true if the given character is a binary digit.
 */
bool
pm_char_is_binary_digit(const uint8_t b) {
    return pm_char_is_number_kind(b, PRISM_NUMBER_BIT_BINARY_DIGIT);
}

/**
 * Returns true if the given character is an octal digit.
 */
bool
pm_char_is_octal_digit(const uint8_t b) {
    return pm_char_is_number_kind(b, PRISM_NUMBER_BIT_OCTAL_DIGIT);
}

/**
 * Returns true if the given character is a decimal digit.
 */
bool
pm_char_is_decimal_digit(const uint8_t b) {
    return pm_char_is_number_kind(b, PRISM_NUMBER_BIT_DECIMAL_DIGIT);
}

/**
 * Returns true if the given character is a hexadecimal digit.
 */
bool
pm_char_is_hexadecimal_digit(const uint8_t b) {
    return pm_char_is_number_kind(b, PRISM_NUMBER_BIT_HEXADECIMAL_DIGIT);
}

#undef PRISM_CHAR_BIT_WHITESPACE
#undef PRISM_CHAR_BIT_INLINE_WHITESPACE
#undef PRISM_CHAR_BIT_REGEXP_OPTION

#undef PRISM_NUMBER_BIT_BINARY_DIGIT
#undef PRISM_NUMBER_BIT_BINARY_NUMBER
#undef PRISM_NUMBER_BIT_OCTAL_DIGIT
#undef PRISM_NUMBER_BIT_OCTAL_NUMBER
#undef PRISM_NUMBER_BIT_DECIMAL_DIGIT
#undef PRISM_NUMBER_BIT_DECIMAL_NUMBER
#undef PRISM_NUMBER_BIT_HEXADECIMAL_NUMBER
#undef PRISM_NUMBER_BIT_HEXADECIMAL_DIGIT
