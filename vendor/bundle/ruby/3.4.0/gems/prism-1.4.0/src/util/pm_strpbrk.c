#include "prism/util/pm_strpbrk.h"

/**
 * Add an invalid multibyte character error to the parser.
 */
static inline void
pm_strpbrk_invalid_multibyte_character(pm_parser_t *parser, const uint8_t *start, const uint8_t *end) {
    pm_diagnostic_list_append_format(&parser->error_list, start, end, PM_ERR_INVALID_MULTIBYTE_CHARACTER, *start);
}

/**
 * Set the explicit encoding for the parser to the current encoding.
 */
static inline void
pm_strpbrk_explicit_encoding_set(pm_parser_t *parser, const uint8_t *source, size_t width) {
    if (parser->explicit_encoding != NULL) {
        if (parser->explicit_encoding == parser->encoding) {
            // Okay, we already locked to this encoding.
        } else if (parser->explicit_encoding == PM_ENCODING_UTF_8_ENTRY) {
            // Not okay, we already found a Unicode escape sequence and this
            // conflicts.
            pm_diagnostic_list_append_format(&parser->error_list, source, source + width, PM_ERR_MIXED_ENCODING, parser->encoding->name);
        } else {
            // Should not be anything else.
            assert(false && "unreachable");
        }
    }

    parser->explicit_encoding = parser->encoding;
}

/**
 * This is the default path.
 */
static inline const uint8_t *
pm_strpbrk_utf8(pm_parser_t *parser, const uint8_t *source, const uint8_t *charset, size_t maximum, bool validate) {
    size_t index = 0;

    while (index < maximum) {
        if (strchr((const char *) charset, source[index]) != NULL) {
            return source + index;
        }

        if (source[index] < 0x80) {
            index++;
        } else {
            size_t width = pm_encoding_utf_8_char_width(source + index, (ptrdiff_t) (maximum - index));

            if (width > 0) {
                index += width;
            } else if (!validate) {
                index++;
            } else {
                // At this point we know we have an invalid multibyte character.
                // We'll walk forward as far as we can until we find the next
                // valid character so that we don't spam the user with a ton of
                // the same kind of error.
                const size_t start = index;

                do {
                    index++;
                } while (index < maximum && pm_encoding_utf_8_char_width(source + index, (ptrdiff_t) (maximum - index)) == 0);

                pm_strpbrk_invalid_multibyte_character(parser, source + start, source + index);
            }
        }
    }

    return NULL;
}

/**
 * This is the path when the encoding is ASCII-8BIT.
 */
static inline const uint8_t *
pm_strpbrk_ascii_8bit(pm_parser_t *parser, const uint8_t *source, const uint8_t *charset, size_t maximum, bool validate) {
    size_t index = 0;

    while (index < maximum) {
        if (strchr((const char *) charset, source[index]) != NULL) {
            return source + index;
        }

        if (validate && source[index] >= 0x80) pm_strpbrk_explicit_encoding_set(parser, source, 1);
        index++;
    }

    return NULL;
}

/**
 * This is the slow path that does care about the encoding.
 */
static inline const uint8_t *
pm_strpbrk_multi_byte(pm_parser_t *parser, const uint8_t *source, const uint8_t *charset, size_t maximum, bool validate) {
    size_t index = 0;
    const pm_encoding_t *encoding = parser->encoding;

    while (index < maximum) {
        if (strchr((const char *) charset, source[index]) != NULL) {
            return source + index;
        }

        if (source[index] < 0x80) {
            index++;
        } else {
            size_t width = encoding->char_width(source + index, (ptrdiff_t) (maximum - index));
            if (validate) pm_strpbrk_explicit_encoding_set(parser, source, width);

            if (width > 0) {
                index += width;
            } else if (!validate) {
                index++;
            } else {
                // At this point we know we have an invalid multibyte character.
                // We'll walk forward as far as we can until we find the next
                // valid character so that we don't spam the user with a ton of
                // the same kind of error.
                const size_t start = index;

                do {
                    index++;
                } while (index < maximum && encoding->char_width(source + index, (ptrdiff_t) (maximum - index)) == 0);

                pm_strpbrk_invalid_multibyte_character(parser, source + start, source + index);
            }
        }
    }

    return NULL;
}

/**
 * This is the fast path that does not care about the encoding because we know
 * the encoding only supports single-byte characters.
 */
static inline const uint8_t *
pm_strpbrk_single_byte(pm_parser_t *parser, const uint8_t *source, const uint8_t *charset, size_t maximum, bool validate) {
    size_t index = 0;
    const pm_encoding_t *encoding = parser->encoding;

    while (index < maximum) {
        if (strchr((const char *) charset, source[index]) != NULL) {
            return source + index;
        }

        if (source[index] < 0x80 || !validate) {
            index++;
        } else {
            size_t width = encoding->char_width(source + index, (ptrdiff_t) (maximum - index));
            pm_strpbrk_explicit_encoding_set(parser, source, width);

            if (width > 0) {
                index += width;
            } else {
                // At this point we know we have an invalid multibyte character.
                // We'll walk forward as far as we can until we find the next
                // valid character so that we don't spam the user with a ton of
                // the same kind of error.
                const size_t start = index;

                do {
                    index++;
                } while (index < maximum && encoding->char_width(source + index, (ptrdiff_t) (maximum - index)) == 0);

                pm_strpbrk_invalid_multibyte_character(parser, source + start, source + index);
            }
        }
    }

    return NULL;
}

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
 * Shift_JIS, the backslash character can be a trailing byte. In that case we
 * need to take a slower path and iterate one multi-byte character at a time.
 */
const uint8_t *
pm_strpbrk(pm_parser_t *parser, const uint8_t *source, const uint8_t *charset, ptrdiff_t length, bool validate) {
    if (length <= 0) {
        return NULL;
    } else if (!parser->encoding_changed) {
        return pm_strpbrk_utf8(parser, source, charset, (size_t) length, validate);
    } else if (parser->encoding == PM_ENCODING_ASCII_8BIT_ENTRY) {
        return pm_strpbrk_ascii_8bit(parser, source, charset, (size_t) length, validate);
    } else if (parser->encoding->multibyte) {
        return pm_strpbrk_multi_byte(parser, source, charset, (size_t) length, validate);
    } else {
        return pm_strpbrk_single_byte(parser, source, charset, (size_t) length, validate);
    }
}
