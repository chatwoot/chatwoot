/**
 * @file pack.h
 *
 * A pack template string parser.
 */
#ifndef PRISM_PACK_H
#define PRISM_PACK_H

#include "prism/defines.h"

#include <stdint.h>
#include <stdlib.h>

/** The version of the pack template language that we are parsing. */
typedef enum pm_pack_version {
    PM_PACK_VERSION_3_2_0
} pm_pack_version;

/** The type of pack template we are parsing. */
typedef enum pm_pack_variant {
    PM_PACK_VARIANT_PACK,
    PM_PACK_VARIANT_UNPACK
} pm_pack_variant;

/** A directive within the pack template. */
typedef enum pm_pack_type {
    PM_PACK_SPACE,
    PM_PACK_COMMENT,
    PM_PACK_INTEGER,
    PM_PACK_UTF8,
    PM_PACK_BER,
    PM_PACK_FLOAT,
    PM_PACK_STRING_SPACE_PADDED,
    PM_PACK_STRING_NULL_PADDED,
    PM_PACK_STRING_NULL_TERMINATED,
    PM_PACK_STRING_MSB,
    PM_PACK_STRING_LSB,
    PM_PACK_STRING_HEX_HIGH,
    PM_PACK_STRING_HEX_LOW,
    PM_PACK_STRING_UU,
    PM_PACK_STRING_MIME,
    PM_PACK_STRING_BASE64,
    PM_PACK_STRING_FIXED,
    PM_PACK_STRING_POINTER,
    PM_PACK_MOVE,
    PM_PACK_BACK,
    PM_PACK_NULL,
    PM_PACK_END
} pm_pack_type;

/** The signness of a pack directive. */
typedef enum pm_pack_signed {
    PM_PACK_UNSIGNED,
    PM_PACK_SIGNED,
    PM_PACK_SIGNED_NA
} pm_pack_signed;

/** The endianness of a pack directive. */
typedef enum pm_pack_endian {
    PM_PACK_AGNOSTIC_ENDIAN,
    PM_PACK_LITTLE_ENDIAN,      // aka 'VAX', or 'V'
    PM_PACK_BIG_ENDIAN,         // aka 'network', or 'N'
    PM_PACK_NATIVE_ENDIAN,
    PM_PACK_ENDIAN_NA
} pm_pack_endian;

/** The size of an integer pack directive. */
typedef enum pm_pack_size {
    PM_PACK_SIZE_SHORT,
    PM_PACK_SIZE_INT,
    PM_PACK_SIZE_LONG,
    PM_PACK_SIZE_LONG_LONG,
    PM_PACK_SIZE_8,
    PM_PACK_SIZE_16,
    PM_PACK_SIZE_32,
    PM_PACK_SIZE_64,
    PM_PACK_SIZE_P,
    PM_PACK_SIZE_NA
} pm_pack_size;

/** The type of length of a pack directive. */
typedef enum pm_pack_length_type {
    PM_PACK_LENGTH_FIXED,
    PM_PACK_LENGTH_MAX,
    PM_PACK_LENGTH_RELATIVE,  // special case for unpack @*
    PM_PACK_LENGTH_NA
} pm_pack_length_type;

/** The type of encoding for a pack template string. */
typedef enum pm_pack_encoding {
    PM_PACK_ENCODING_START,
    PM_PACK_ENCODING_ASCII_8BIT,
    PM_PACK_ENCODING_US_ASCII,
    PM_PACK_ENCODING_UTF_8
} pm_pack_encoding;

/** The result of parsing a pack template. */
typedef enum pm_pack_result {
    PM_PACK_OK,
    PM_PACK_ERROR_UNSUPPORTED_DIRECTIVE,
    PM_PACK_ERROR_UNKNOWN_DIRECTIVE,
    PM_PACK_ERROR_LENGTH_TOO_BIG,
    PM_PACK_ERROR_BANG_NOT_ALLOWED,
    PM_PACK_ERROR_DOUBLE_ENDIAN
} pm_pack_result;

/**
 * Parse a single directive from a pack or unpack format string.
 *
 * @param variant (in) pack or unpack
 * @param format (in, out) the start of the next directive to parse on calling,
 *     and advanced beyond the parsed directive on return, or as much of it as
 *     was consumed until an error was encountered
 * @param format_end (in) the end of the format string
 * @param type (out) the type of the directive
 * @param signed_type (out) whether the value is signed
 * @param endian (out) the endianness of the value
 * @param size (out) the size of the value
 * @param length_type (out) what kind of length is specified
 * @param length (out) the length of the directive
 * @param encoding (in, out) takes the current encoding of the string which
 *     would result from parsing the whole format string, and returns a possibly
 *     changed directive - the encoding should be `PM_PACK_ENCODING_START` when
 *     pm_pack_parse is called for the first directive in a format string
 *
 * @return `PM_PACK_OK` on success or `PM_PACK_ERROR_*` on error
 * @note Consult Ruby documentation for the meaning of directives.
 */
PRISM_EXPORTED_FUNCTION pm_pack_result
pm_pack_parse(
    pm_pack_variant variant,
    const char **format,
    const char *format_end,
    pm_pack_type *type,
    pm_pack_signed *signed_type,
    pm_pack_endian *endian,
    pm_pack_size *size,
    pm_pack_length_type *length_type,
    uint64_t *length,
    pm_pack_encoding *encoding
);

/**
 * Prism abstracts sizes away from the native system - this converts an abstract
 * size to a native size.
 *
 * @param size The abstract size to convert.
 * @return The native size.
 */
PRISM_EXPORTED_FUNCTION size_t pm_size_to_native(pm_pack_size size);

#endif
