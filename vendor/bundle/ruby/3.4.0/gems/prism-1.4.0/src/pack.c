#include "prism/pack.h"

// We optionally support parsing String#pack templates. For systems that don't
// want or need this functionality, it can be turned off with the
// PRISM_EXCLUDE_PACK define.
#ifdef PRISM_EXCLUDE_PACK

void pm_pack_parse(void) {}

#else

#include <stdbool.h>
#include <errno.h>

static uintmax_t
strtoumaxc(const char **format) {
    uintmax_t value = 0;
    while (**format >= '0' && **format <= '9') {
        if (value > UINTMAX_MAX / 10) {
            errno = ERANGE;
        }
        value = value * 10 + ((uintmax_t) (**format - '0'));
        (*format)++;
    }
    return value;
}

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
) {
    if (*encoding == PM_PACK_ENCODING_START) {
        *encoding = PM_PACK_ENCODING_US_ASCII;
    }

    if (*format == format_end) {
            *type = PM_PACK_END;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_ENDIAN_NA;
            *size = PM_PACK_SIZE_NA;
            *length_type = PM_PACK_LENGTH_NA;
            return PM_PACK_OK;
    }

    *length_type = PM_PACK_LENGTH_FIXED;
    *length = 1;
    bool length_changed_allowed = true;

    char directive = **format;
    (*format)++;
    switch (directive) {
        case ' ':
        case '\t':
        case '\n':
        case '\v':
        case '\f':
        case '\r':
            *type = PM_PACK_SPACE;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_ENDIAN_NA;
            *size = PM_PACK_SIZE_NA;
            *length_type = PM_PACK_LENGTH_NA;
            *length = 0;
            return PM_PACK_OK;
        case '#':
            while ((*format < format_end) && (**format != '\n')) {
                (*format)++;
            }
            *type = PM_PACK_COMMENT;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_ENDIAN_NA;
            *size = PM_PACK_SIZE_NA;
            *length_type = PM_PACK_LENGTH_NA;
            *length = 0;
            return PM_PACK_OK;
        case 'C':
            *type = PM_PACK_INTEGER;
            *signed_type = PM_PACK_UNSIGNED;
            *endian = PM_PACK_AGNOSTIC_ENDIAN;
            *size = PM_PACK_SIZE_8;
            break;
        case 'S':
            *type = PM_PACK_INTEGER;
            *signed_type = PM_PACK_UNSIGNED;
            *endian = PM_PACK_NATIVE_ENDIAN;
            *size = PM_PACK_SIZE_16;
            break;
        case 'L':
            *type = PM_PACK_INTEGER;
            *signed_type = PM_PACK_UNSIGNED;
            *endian = PM_PACK_NATIVE_ENDIAN;
            *size = PM_PACK_SIZE_32;
            break;
        case 'Q':
            *type = PM_PACK_INTEGER;
            *signed_type = PM_PACK_UNSIGNED;
            *endian = PM_PACK_NATIVE_ENDIAN;
            *size = PM_PACK_SIZE_64;
            break;
        case 'J':
            *type = PM_PACK_INTEGER;
            *signed_type = PM_PACK_UNSIGNED;
            *endian = PM_PACK_NATIVE_ENDIAN;
            *size = PM_PACK_SIZE_P;
            break;
        case 'c':
            *type = PM_PACK_INTEGER;
            *signed_type = PM_PACK_SIGNED;
            *endian = PM_PACK_AGNOSTIC_ENDIAN;
            *size = PM_PACK_SIZE_8;
            break;
        case 's':
            *type = PM_PACK_INTEGER;
            *signed_type = PM_PACK_SIGNED;
            *endian = PM_PACK_NATIVE_ENDIAN;
            *size = PM_PACK_SIZE_16;
            break;
        case 'l':
            *type = PM_PACK_INTEGER;
            *signed_type = PM_PACK_SIGNED;
            *endian = PM_PACK_NATIVE_ENDIAN;
            *size = PM_PACK_SIZE_32;
            break;
        case 'q':
            *type = PM_PACK_INTEGER;
            *signed_type = PM_PACK_SIGNED;
            *endian = PM_PACK_NATIVE_ENDIAN;
            *size = PM_PACK_SIZE_64;
            break;
        case 'j':
            *type = PM_PACK_INTEGER;
            *signed_type = PM_PACK_SIGNED;
            *endian = PM_PACK_NATIVE_ENDIAN;
            *size = PM_PACK_SIZE_P;
            break;
        case 'I':
            *type = PM_PACK_INTEGER;
            *signed_type = PM_PACK_UNSIGNED;
            *endian = PM_PACK_NATIVE_ENDIAN;
            *size = PM_PACK_SIZE_INT;
            break;
        case 'i':
            *type = PM_PACK_INTEGER;
            *signed_type = PM_PACK_SIGNED;
            *endian = PM_PACK_NATIVE_ENDIAN;
            *size = PM_PACK_SIZE_INT;
            break;
        case 'n':
            *type = PM_PACK_INTEGER;
            *signed_type = PM_PACK_UNSIGNED;
            *endian = PM_PACK_BIG_ENDIAN;
            *size = PM_PACK_SIZE_16;
            length_changed_allowed = false;
            break;
        case 'N':
            *type = PM_PACK_INTEGER;
            *signed_type = PM_PACK_UNSIGNED;
            *endian = PM_PACK_BIG_ENDIAN;
            *size = PM_PACK_SIZE_32;
            length_changed_allowed = false;
            break;
        case 'v':
            *type = PM_PACK_INTEGER;
            *signed_type = PM_PACK_UNSIGNED;
            *endian = PM_PACK_LITTLE_ENDIAN;
            *size = PM_PACK_SIZE_16;
            length_changed_allowed = false;
            break;
        case 'V':
            *type = PM_PACK_INTEGER;
            *signed_type = PM_PACK_UNSIGNED;
            *endian = PM_PACK_LITTLE_ENDIAN;
            *size = PM_PACK_SIZE_32;
            length_changed_allowed = false;
            break;
        case 'U':
            *type = PM_PACK_UTF8;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_ENDIAN_NA;
            *size = PM_PACK_SIZE_NA;
            break;
        case 'w':
            *type = PM_PACK_BER;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_ENDIAN_NA;
            *size = PM_PACK_SIZE_NA;
            break;
        case 'D':
        case 'd':
            *type = PM_PACK_FLOAT;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_NATIVE_ENDIAN;
            *size = PM_PACK_SIZE_64;
            break;
        case 'F':
        case 'f':
            *type = PM_PACK_FLOAT;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_NATIVE_ENDIAN;
            *size = PM_PACK_SIZE_32;
            break;
        case 'E':
            *type = PM_PACK_FLOAT;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_LITTLE_ENDIAN;
            *size = PM_PACK_SIZE_64;
            break;
        case 'e':
            *type = PM_PACK_FLOAT;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_LITTLE_ENDIAN;
            *size = PM_PACK_SIZE_32;
            break;
        case 'G':
            *type = PM_PACK_FLOAT;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_BIG_ENDIAN;
            *size = PM_PACK_SIZE_64;
            break;
        case 'g':
            *type = PM_PACK_FLOAT;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_BIG_ENDIAN;
            *size = PM_PACK_SIZE_32;
            break;
        case 'A':
            *type = PM_PACK_STRING_SPACE_PADDED;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_ENDIAN_NA;
            *size = PM_PACK_SIZE_NA;
            break;
        case 'a':
            *type = PM_PACK_STRING_NULL_PADDED;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_ENDIAN_NA;
            *size = PM_PACK_SIZE_NA;
            break;
        case 'Z':
            *type = PM_PACK_STRING_NULL_TERMINATED;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_ENDIAN_NA;
            *size = PM_PACK_SIZE_NA;
            break;
        case 'B':
            *type = PM_PACK_STRING_MSB;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_ENDIAN_NA;
            *size = PM_PACK_SIZE_NA;
            break;
        case 'b':
            *type = PM_PACK_STRING_LSB;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_ENDIAN_NA;
            *size = PM_PACK_SIZE_NA;
            break;
        case 'H':
            *type = PM_PACK_STRING_HEX_HIGH;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_ENDIAN_NA;
            *size = PM_PACK_SIZE_NA;
            break;
        case 'h':
            *type = PM_PACK_STRING_HEX_LOW;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_ENDIAN_NA;
            *size = PM_PACK_SIZE_NA;
            break;
        case 'u':
            *type = PM_PACK_STRING_UU;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_ENDIAN_NA;
            *size = PM_PACK_SIZE_NA;
            break;
        case 'M':
            *type = PM_PACK_STRING_MIME;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_ENDIAN_NA;
            *size = PM_PACK_SIZE_NA;
            break;
        case 'm':
            *type = PM_PACK_STRING_BASE64;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_ENDIAN_NA;
            *size = PM_PACK_SIZE_NA;
            break;
        case 'P':
            *type = PM_PACK_STRING_FIXED;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_ENDIAN_NA;
            *size = PM_PACK_SIZE_NA;
            break;
        case 'p':
            *type = PM_PACK_STRING_POINTER;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_ENDIAN_NA;
            *size = PM_PACK_SIZE_NA;
            break;
        case '@':
            *type = PM_PACK_MOVE;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_ENDIAN_NA;
            *size = PM_PACK_SIZE_NA;
            break;
        case 'X':
            *type = PM_PACK_BACK;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_ENDIAN_NA;
            *size = PM_PACK_SIZE_NA;
            break;
        case 'x':
            *type = PM_PACK_NULL;
            *signed_type = PM_PACK_SIGNED_NA;
            *endian = PM_PACK_ENDIAN_NA;
            *size = PM_PACK_SIZE_NA;
            break;
        case '%':
            return PM_PACK_ERROR_UNSUPPORTED_DIRECTIVE;
        default:
            return PM_PACK_ERROR_UNKNOWN_DIRECTIVE;
    }

    bool explicit_endian = false;

    while (*format < format_end) {
        switch (**format) {
            case '_':
            case '!':
                (*format)++;
                if (*type != PM_PACK_INTEGER || !length_changed_allowed) {
                    return PM_PACK_ERROR_BANG_NOT_ALLOWED;
                }
                switch (*size) {
                    case PM_PACK_SIZE_SHORT:
                    case PM_PACK_SIZE_INT:
                    case PM_PACK_SIZE_LONG:
                    case PM_PACK_SIZE_LONG_LONG:
                        break;
                    case PM_PACK_SIZE_16:
                        *size = PM_PACK_SIZE_SHORT;
                        break;
                    case PM_PACK_SIZE_32:
                        *size = PM_PACK_SIZE_LONG;
                        break;
                    case PM_PACK_SIZE_64:
                        *size = PM_PACK_SIZE_LONG_LONG;
                        break;
                    case PM_PACK_SIZE_P:
                        break;
                    default:
                        return PM_PACK_ERROR_BANG_NOT_ALLOWED;
                }
                break;
            case '<':
                (*format)++;
                if (explicit_endian) {
                    return PM_PACK_ERROR_DOUBLE_ENDIAN;
                }
                *endian = PM_PACK_LITTLE_ENDIAN;
                explicit_endian = true;
                break;
            case '>':
                (*format)++;
                if (explicit_endian) {
                    return PM_PACK_ERROR_DOUBLE_ENDIAN;
                }
                *endian = PM_PACK_BIG_ENDIAN;
                explicit_endian = true;
                break;
            default:
                goto exit_modifier_loop;
        }
    }

exit_modifier_loop:

    if (variant == PM_PACK_VARIANT_UNPACK && *type == PM_PACK_MOVE) {
        *length = 0;
    }

    if (*format < format_end) {
        if (**format == '*') {
            switch (*type) {
                case PM_PACK_NULL:
                case PM_PACK_BACK:
                    switch (variant) {
                        case PM_PACK_VARIANT_PACK:
                            *length_type = PM_PACK_LENGTH_FIXED;
                            break;
                        case PM_PACK_VARIANT_UNPACK:
                            *length_type = PM_PACK_LENGTH_MAX;
                            break;
                    }
                    *length = 0;
                    break;

                case PM_PACK_MOVE:
                    switch (variant) {
                        case PM_PACK_VARIANT_PACK:
                            *length_type = PM_PACK_LENGTH_FIXED;
                            break;
                        case PM_PACK_VARIANT_UNPACK:
                            *length_type = PM_PACK_LENGTH_RELATIVE;
                            break;
                    }
                    *length = 0;
                    break;

                case PM_PACK_STRING_UU:
                    *length_type = PM_PACK_LENGTH_FIXED;
                    *length = 0;
                    break;

                case PM_PACK_STRING_FIXED:
                    switch (variant) {
                        case PM_PACK_VARIANT_PACK:
                            *length_type = PM_PACK_LENGTH_FIXED;
                            *length = 1;
                            break;
                        case PM_PACK_VARIANT_UNPACK:
                            *length_type = PM_PACK_LENGTH_MAX;
                            *length = 0;
                            break;
                    }
                    break;

                case PM_PACK_STRING_MIME:
                case PM_PACK_STRING_BASE64:
                    *length_type = PM_PACK_LENGTH_FIXED;
                    *length = 1;
                    break;

                default:
                    *length_type = PM_PACK_LENGTH_MAX;
                    *length = 0;
                    break;
            }

            (*format)++;
        } else if (**format >= '0' && **format <= '9') {
            errno = 0;
            *length_type = PM_PACK_LENGTH_FIXED;
            #if UINTMAX_MAX < UINT64_MAX
                #error "prism's design assumes uintmax_t is at least as large as uint64_t"
            #endif
            uintmax_t length_max = strtoumaxc(format);
            if (errno || length_max > UINT64_MAX) {
                return PM_PACK_ERROR_LENGTH_TOO_BIG;
            }
            *length = (uint64_t) length_max;
        }
    }

    switch (*type) {
        case PM_PACK_UTF8:
            /* if encoding is US-ASCII, upgrade to UTF-8 */
            if (*encoding == PM_PACK_ENCODING_US_ASCII) {
                *encoding = PM_PACK_ENCODING_UTF_8;
            }
            break;
        case PM_PACK_STRING_MIME:
        case PM_PACK_STRING_BASE64:
        case PM_PACK_STRING_UU:
            /* keep US-ASCII (do nothing) */
            break;
        default:
            /* fall back to BINARY */
            *encoding = PM_PACK_ENCODING_ASCII_8BIT;
            break;
    }

    return PM_PACK_OK;
}

PRISM_EXPORTED_FUNCTION size_t
pm_size_to_native(pm_pack_size size) {
    switch (size) {
        case PM_PACK_SIZE_SHORT:
            return sizeof(short);
        case PM_PACK_SIZE_INT:
            return sizeof(int);
        case PM_PACK_SIZE_LONG:
            return sizeof(long);
        case PM_PACK_SIZE_LONG_LONG:
            return sizeof(long long);
        case PM_PACK_SIZE_8:
            return 1;
        case PM_PACK_SIZE_16:
            return 2;
        case PM_PACK_SIZE_32:
            return 4;
        case PM_PACK_SIZE_64:
            return 8;
        case PM_PACK_SIZE_P:
            return sizeof(void *);
        default:
            return 0;
    }
}

#endif
