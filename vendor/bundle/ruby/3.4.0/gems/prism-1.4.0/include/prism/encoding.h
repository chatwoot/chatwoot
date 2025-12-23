/**
 * @file encoding.h
 *
 * The encoding interface and implementations used by the parser.
 */
#ifndef PRISM_ENCODING_H
#define PRISM_ENCODING_H

#include "prism/defines.h"
#include "prism/util/pm_strncasecmp.h"

#include <assert.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/**
 * This struct defines the functions necessary to implement the encoding
 * interface so we can determine how many bytes the subsequent character takes.
 * Each callback should return the number of bytes, or 0 if the next bytes are
 * invalid for the encoding and type.
 */
typedef struct {
    /**
     * Return the number of bytes that the next character takes if it is valid
     * in the encoding. Does not read more than n bytes. It is assumed that n is
     * at least 1.
     */
    size_t (*char_width)(const uint8_t *b, ptrdiff_t n);

    /**
     * Return the number of bytes that the next character takes if it is valid
     * in the encoding and is alphabetical. Does not read more than n bytes. It
     * is assumed that n is at least 1.
     */
    size_t (*alpha_char)(const uint8_t *b, ptrdiff_t n);

    /**
     * Return the number of bytes that the next character takes if it is valid
     * in the encoding and is alphanumeric. Does not read more than n bytes. It
     * is assumed that n is at least 1.
     */
    size_t (*alnum_char)(const uint8_t *b, ptrdiff_t n);

    /**
     * Return true if the next character is valid in the encoding and is an
     * uppercase character. Does not read more than n bytes. It is assumed that
     * n is at least 1.
     */
    bool (*isupper_char)(const uint8_t *b, ptrdiff_t n);

    /**
     * The name of the encoding. This should correspond to a value that can be
     * passed to Encoding.find in Ruby.
     */
    const char *name;

    /**
     * Return true if the encoding is a multibyte encoding.
     */
    bool multibyte;
} pm_encoding_t;

/**
 * All of the lookup tables use the first bit of each embedded byte to indicate
 * whether the codepoint is alphabetical.
 */
#define PRISM_ENCODING_ALPHABETIC_BIT 1 << 0

/**
 * All of the lookup tables use the second bit of each embedded byte to indicate
 * whether the codepoint is alphanumeric.
 */
#define PRISM_ENCODING_ALPHANUMERIC_BIT 1 << 1

/**
 * All of the lookup tables use the third bit of each embedded byte to indicate
 * whether the codepoint is uppercase.
 */
#define PRISM_ENCODING_UPPERCASE_BIT 1 << 2

/**
 * Return the size of the next character in the UTF-8 encoding.
 *
 * @param b The bytes to read.
 * @param n The number of bytes that can be read.
 * @returns The number of bytes that the next character takes if it is valid in
 *     the encoding, or 0 if it is not.
 */
size_t pm_encoding_utf_8_char_width(const uint8_t *b, ptrdiff_t n);

/**
 * Return the size of the next character in the UTF-8 encoding if it is an
 * alphabetical character.
 *
 * @param b The bytes to read.
 * @param n The number of bytes that can be read.
 * @returns The number of bytes that the next character takes if it is valid in
 *     the encoding, or 0 if it is not.
 */
size_t pm_encoding_utf_8_alpha_char(const uint8_t *b, ptrdiff_t n);

/**
 * Return the size of the next character in the UTF-8 encoding if it is an
 * alphanumeric character.
 *
 * @param b The bytes to read.
 * @param n The number of bytes that can be read.
 * @returns The number of bytes that the next character takes if it is valid in
 *     the encoding, or 0 if it is not.
 */
size_t pm_encoding_utf_8_alnum_char(const uint8_t *b, ptrdiff_t n);

/**
 * Return true if the next character in the UTF-8 encoding if it is an uppercase
 * character.
 *
 * @param b The bytes to read.
 * @param n The number of bytes that can be read.
 * @returns True if the next character is valid in the encoding and is an
 *     uppercase character, or false if it is not.
 */
bool pm_encoding_utf_8_isupper_char(const uint8_t *b, ptrdiff_t n);

/**
 * This lookup table is referenced in both the UTF-8 encoding file and the
 * parser directly in order to speed up the default encoding processing. It is
 * used to indicate whether a character is alphabetical, alphanumeric, or
 * uppercase in unicode mappings.
 */
extern const uint8_t pm_encoding_unicode_table[256];

/**
 * These are all of the encodings that prism supports.
 */
typedef enum {
    PM_ENCODING_UTF_8 = 0,
    PM_ENCODING_US_ASCII,
    PM_ENCODING_ASCII_8BIT,
    PM_ENCODING_EUC_JP,
    PM_ENCODING_WINDOWS_31J,

// We optionally support excluding the full set of encodings to only support the
// minimum necessary to process Ruby code without encoding comments.
#ifndef PRISM_ENCODING_EXCLUDE_FULL
    PM_ENCODING_BIG5,
    PM_ENCODING_BIG5_HKSCS,
    PM_ENCODING_BIG5_UAO,
    PM_ENCODING_CESU_8,
    PM_ENCODING_CP51932,
    PM_ENCODING_CP850,
    PM_ENCODING_CP852,
    PM_ENCODING_CP855,
    PM_ENCODING_CP949,
    PM_ENCODING_CP950,
    PM_ENCODING_CP951,
    PM_ENCODING_EMACS_MULE,
    PM_ENCODING_EUC_JP_MS,
    PM_ENCODING_EUC_JIS_2004,
    PM_ENCODING_EUC_KR,
    PM_ENCODING_EUC_TW,
    PM_ENCODING_GB12345,
    PM_ENCODING_GB18030,
    PM_ENCODING_GB1988,
    PM_ENCODING_GB2312,
    PM_ENCODING_GBK,
    PM_ENCODING_IBM437,
    PM_ENCODING_IBM720,
    PM_ENCODING_IBM737,
    PM_ENCODING_IBM775,
    PM_ENCODING_IBM852,
    PM_ENCODING_IBM855,
    PM_ENCODING_IBM857,
    PM_ENCODING_IBM860,
    PM_ENCODING_IBM861,
    PM_ENCODING_IBM862,
    PM_ENCODING_IBM863,
    PM_ENCODING_IBM864,
    PM_ENCODING_IBM865,
    PM_ENCODING_IBM866,
    PM_ENCODING_IBM869,
    PM_ENCODING_ISO_8859_1,
    PM_ENCODING_ISO_8859_2,
    PM_ENCODING_ISO_8859_3,
    PM_ENCODING_ISO_8859_4,
    PM_ENCODING_ISO_8859_5,
    PM_ENCODING_ISO_8859_6,
    PM_ENCODING_ISO_8859_7,
    PM_ENCODING_ISO_8859_8,
    PM_ENCODING_ISO_8859_9,
    PM_ENCODING_ISO_8859_10,
    PM_ENCODING_ISO_8859_11,
    PM_ENCODING_ISO_8859_13,
    PM_ENCODING_ISO_8859_14,
    PM_ENCODING_ISO_8859_15,
    PM_ENCODING_ISO_8859_16,
    PM_ENCODING_KOI8_R,
    PM_ENCODING_KOI8_U,
    PM_ENCODING_MAC_CENT_EURO,
    PM_ENCODING_MAC_CROATIAN,
    PM_ENCODING_MAC_CYRILLIC,
    PM_ENCODING_MAC_GREEK,
    PM_ENCODING_MAC_ICELAND,
    PM_ENCODING_MAC_JAPANESE,
    PM_ENCODING_MAC_ROMAN,
    PM_ENCODING_MAC_ROMANIA,
    PM_ENCODING_MAC_THAI,
    PM_ENCODING_MAC_TURKISH,
    PM_ENCODING_MAC_UKRAINE,
    PM_ENCODING_SHIFT_JIS,
    PM_ENCODING_SJIS_DOCOMO,
    PM_ENCODING_SJIS_KDDI,
    PM_ENCODING_SJIS_SOFTBANK,
    PM_ENCODING_STATELESS_ISO_2022_JP,
    PM_ENCODING_STATELESS_ISO_2022_JP_KDDI,
    PM_ENCODING_TIS_620,
    PM_ENCODING_UTF8_MAC,
    PM_ENCODING_UTF8_DOCOMO,
    PM_ENCODING_UTF8_KDDI,
    PM_ENCODING_UTF8_SOFTBANK,
    PM_ENCODING_WINDOWS_1250,
    PM_ENCODING_WINDOWS_1251,
    PM_ENCODING_WINDOWS_1252,
    PM_ENCODING_WINDOWS_1253,
    PM_ENCODING_WINDOWS_1254,
    PM_ENCODING_WINDOWS_1255,
    PM_ENCODING_WINDOWS_1256,
    PM_ENCODING_WINDOWS_1257,
    PM_ENCODING_WINDOWS_1258,
    PM_ENCODING_WINDOWS_874,
#endif

    PM_ENCODING_MAXIMUM
} pm_encoding_type_t;

/**
 * This is the table of all of the encodings that prism supports.
 */
extern const pm_encoding_t pm_encodings[PM_ENCODING_MAXIMUM];

/**
 * This is the default UTF-8 encoding. We need a reference to it to quickly
 * create parsers.
 */
#define PM_ENCODING_UTF_8_ENTRY (&pm_encodings[PM_ENCODING_UTF_8])

/**
 * This is the US-ASCII encoding. We need a reference to it to be able to
 * compare against it when a string is being created because it could possibly
 * need to fall back to ASCII-8BIT.
 */
#define PM_ENCODING_US_ASCII_ENTRY (&pm_encodings[PM_ENCODING_US_ASCII])

/**
 * This is the ASCII-8BIT encoding. We need a reference to it so that pm_strpbrk
 * can compare against it because invalid multibyte characters are not a thing
 * in this encoding. It is also needed for handling Regexp encoding flags.
 */
#define PM_ENCODING_ASCII_8BIT_ENTRY (&pm_encodings[PM_ENCODING_ASCII_8BIT])

/**
 * This is the EUC-JP encoding. We need a reference to it to quickly process
 * regular expression modifiers.
 */
#define PM_ENCODING_EUC_JP_ENTRY (&pm_encodings[PM_ENCODING_EUC_JP])

/**
 * This is the Windows-31J encoding. We need a reference to it to quickly
 * process regular expression modifiers.
 */
#define PM_ENCODING_WINDOWS_31J_ENTRY (&pm_encodings[PM_ENCODING_WINDOWS_31J])

/**
 * Parse the given name of an encoding and return a pointer to the corresponding
 * encoding struct if one can be found, otherwise return NULL.
 *
 * @param start A pointer to the first byte of the name.
 * @param end A pointer to the last byte of the name.
 * @returns A pointer to the encoding struct if one is found, otherwise NULL.
 */
const pm_encoding_t * pm_encoding_find(const uint8_t *start, const uint8_t *end);

#endif
