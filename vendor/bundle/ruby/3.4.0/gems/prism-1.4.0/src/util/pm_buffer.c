#include "prism/util/pm_buffer.h"

/**
 * Return the size of the pm_buffer_t struct.
 */
size_t
pm_buffer_sizeof(void) {
    return sizeof(pm_buffer_t);
}

/**
 * Initialize a pm_buffer_t with the given capacity.
 */
bool
pm_buffer_init_capacity(pm_buffer_t *buffer, size_t capacity) {
    buffer->length = 0;
    buffer->capacity = capacity;

    buffer->value = (char *) xmalloc(capacity);
    return buffer->value != NULL;
}

/**
 * Initialize a pm_buffer_t with its default values.
 */
bool
pm_buffer_init(pm_buffer_t *buffer) {
    return pm_buffer_init_capacity(buffer, 1024);
}

/**
 * Return the value of the buffer.
 */
char *
pm_buffer_value(const pm_buffer_t *buffer) {
    return buffer->value;
}

/**
 * Return the length of the buffer.
 */
size_t
pm_buffer_length(const pm_buffer_t *buffer) {
    return buffer->length;
}

/**
 * Append the given amount of space to the buffer.
 */
static inline bool
pm_buffer_append_length(pm_buffer_t *buffer, size_t length) {
    size_t next_length = buffer->length + length;

    if (next_length > buffer->capacity) {
        if (buffer->capacity == 0) {
            buffer->capacity = 1;
        }

        while (next_length > buffer->capacity) {
            buffer->capacity *= 2;
        }

        buffer->value = xrealloc(buffer->value, buffer->capacity);
        if (buffer->value == NULL) return false;
    }

    buffer->length = next_length;
    return true;
}

/**
 * Append a generic pointer to memory to the buffer.
 */
static inline void
pm_buffer_append(pm_buffer_t *buffer, const void *source, size_t length) {
    size_t cursor = buffer->length;
    if (pm_buffer_append_length(buffer, length)) {
        memcpy(buffer->value + cursor, source, length);
    }
}

/**
 * Append the given amount of space as zeroes to the buffer.
 */
void
pm_buffer_append_zeroes(pm_buffer_t *buffer, size_t length) {
    size_t cursor = buffer->length;
    if (pm_buffer_append_length(buffer, length)) {
        memset(buffer->value + cursor, 0, length);
    }
}

/**
 * Append a formatted string to the buffer.
 */
void
pm_buffer_append_format(pm_buffer_t *buffer, const char *format, ...) {
    va_list arguments;
    va_start(arguments, format);
    int result = vsnprintf(NULL, 0, format, arguments);
    va_end(arguments);

    if (result < 0) return;
    size_t length = (size_t) (result + 1);

    size_t cursor = buffer->length;
    if (pm_buffer_append_length(buffer, length)) {
        va_start(arguments, format);
        vsnprintf(buffer->value + cursor, length, format, arguments);
        va_end(arguments);
        buffer->length--;
    }
}

/**
 * Append a string to the buffer.
 */
void
pm_buffer_append_string(pm_buffer_t *buffer, const char *value, size_t length) {
    pm_buffer_append(buffer, value, length);
}

/**
 * Append a list of bytes to the buffer.
 */
void
pm_buffer_append_bytes(pm_buffer_t *buffer, const uint8_t *value, size_t length) {
    pm_buffer_append(buffer, (const char *) value, length);
}

/**
 * Append a single byte to the buffer.
 */
void
pm_buffer_append_byte(pm_buffer_t *buffer, uint8_t value) {
    const void *source = &value;
    pm_buffer_append(buffer, source, sizeof(uint8_t));
}

/**
 * Append a 32-bit unsigned integer to the buffer as a variable-length integer.
 */
void
pm_buffer_append_varuint(pm_buffer_t *buffer, uint32_t value) {
    if (value < 128) {
        pm_buffer_append_byte(buffer, (uint8_t) value);
    } else {
        uint32_t n = value;
        while (n >= 128) {
            pm_buffer_append_byte(buffer, (uint8_t) (n | 128));
            n >>= 7;
        }
        pm_buffer_append_byte(buffer, (uint8_t) n);
    }
}

/**
 * Append a 32-bit signed integer to the buffer as a variable-length integer.
 */
void
pm_buffer_append_varsint(pm_buffer_t *buffer, int32_t value) {
    uint32_t unsigned_int = ((uint32_t)(value) << 1) ^ ((uint32_t)(value >> 31));
    pm_buffer_append_varuint(buffer, unsigned_int);
}

/**
 * Append a double to the buffer.
 */
void
pm_buffer_append_double(pm_buffer_t *buffer, double value) {
    const void *source = &value;
    pm_buffer_append(buffer, source, sizeof(double));
}

/**
 * Append a unicode codepoint to the buffer.
 */
bool
pm_buffer_append_unicode_codepoint(pm_buffer_t *buffer, uint32_t value) {
    if (value <= 0x7F) {
        pm_buffer_append_byte(buffer, (uint8_t) value); // 0xxxxxxx
        return true;
    } else if (value <= 0x7FF) {
        uint8_t bytes[] = {
            (uint8_t) (0xC0 | ((value >> 6) & 0x3F)), // 110xxxxx
            (uint8_t) (0x80 | (value & 0x3F))         // 10xxxxxx
        };

        pm_buffer_append_bytes(buffer, bytes, 2);
        return true;
    } else if (value <= 0xFFFF) {
        uint8_t bytes[] = {
            (uint8_t) (0xE0 | ((value >> 12) & 0x3F)), // 1110xxxx
            (uint8_t) (0x80 | ((value >> 6) & 0x3F)),  // 10xxxxxx
            (uint8_t) (0x80 | (value & 0x3F))          // 10xxxxxx
        };

        pm_buffer_append_bytes(buffer, bytes, 3);
        return true;
    } else if (value <= 0x10FFFF) {
        uint8_t bytes[] = {
            (uint8_t) (0xF0 | ((value >> 18) & 0x3F)), // 11110xxx
            (uint8_t) (0x80 | ((value >> 12) & 0x3F)), // 10xxxxxx
            (uint8_t) (0x80 | ((value >> 6) & 0x3F)),  // 10xxxxxx
            (uint8_t) (0x80 | (value & 0x3F))          // 10xxxxxx
        };

        pm_buffer_append_bytes(buffer, bytes, 4);
        return true;
    } else {
        return false;
    }
}

/**
 * Append a slice of source code to the buffer.
 */
void
pm_buffer_append_source(pm_buffer_t *buffer, const uint8_t *source, size_t length, pm_buffer_escaping_t escaping) {
    for (size_t index = 0; index < length; index++) {
        const uint8_t byte = source[index];

        if ((byte <= 0x06) || (byte >= 0x0E && byte <= 0x1F) || (byte >= 0x7F)) {
            if (escaping == PM_BUFFER_ESCAPING_RUBY) {
                pm_buffer_append_format(buffer, "\\x%02X", byte);
            } else {
                pm_buffer_append_format(buffer, "\\u%04X", byte);
            }
        } else {
            switch (byte) {
                case '\a':
                    if (escaping == PM_BUFFER_ESCAPING_RUBY) {
                        pm_buffer_append_string(buffer, "\\a", 2);
                    } else {
                        pm_buffer_append_format(buffer, "\\u%04X", byte);
                    }
                    break;
                case '\b':
                    pm_buffer_append_string(buffer, "\\b", 2);
                    break;
                case '\t':
                    pm_buffer_append_string(buffer, "\\t", 2);
                    break;
                case '\n':
                    pm_buffer_append_string(buffer, "\\n", 2);
                    break;
                case '\v':
                    if (escaping == PM_BUFFER_ESCAPING_RUBY) {
                        pm_buffer_append_string(buffer, "\\v", 2);
                    } else {
                        pm_buffer_append_format(buffer, "\\u%04X", byte);
                    }
                    break;
                case '\f':
                    pm_buffer_append_string(buffer, "\\f", 2);
                    break;
                case '\r':
                    pm_buffer_append_string(buffer, "\\r", 2);
                    break;
                case '"':
                    pm_buffer_append_string(buffer, "\\\"", 2);
                    break;
                case '#': {
                    if (escaping == PM_BUFFER_ESCAPING_RUBY && index + 1 < length) {
                        const uint8_t next_byte = source[index + 1];
                        if (next_byte == '{' || next_byte == '@' || next_byte == '$') {
                            pm_buffer_append_byte(buffer, '\\');
                        }
                    }

                    pm_buffer_append_byte(buffer, '#');
                    break;
                }
                case '\\':
                    pm_buffer_append_string(buffer, "\\\\", 2);
                    break;
                default:
                    pm_buffer_append_byte(buffer, byte);
                    break;
            }
        }
    }
}

/**
 * Prepend the given string to the buffer.
 */
void
pm_buffer_prepend_string(pm_buffer_t *buffer, const char *value, size_t length) {
    size_t cursor = buffer->length;
    if (pm_buffer_append_length(buffer, length)) {
        memmove(buffer->value + length, buffer->value, cursor);
        memcpy(buffer->value, value, length);
    }
}

/**
 * Concatenate one buffer onto another.
 */
void
pm_buffer_concat(pm_buffer_t *destination, const pm_buffer_t *source) {
    if (source->length > 0) {
        pm_buffer_append(destination, source->value, source->length);
    }
}

/**
 * Clear the buffer by reducing its size to 0. This does not free the allocated
 * memory, but it does allow the buffer to be reused.
 */
void
pm_buffer_clear(pm_buffer_t *buffer) {
    buffer->length = 0;
}

/**
 * Strip the whitespace from the end of the buffer.
 */
void
pm_buffer_rstrip(pm_buffer_t *buffer) {
    while (buffer->length > 0 && pm_char_is_whitespace((uint8_t) buffer->value[buffer->length - 1])) {
        buffer->length--;
    }
}

/**
 * Checks if the buffer includes the given value.
 */
size_t
pm_buffer_index(const pm_buffer_t *buffer, char value) {
    const char *first = memchr(buffer->value, value, buffer->length);
    return (first == NULL) ? SIZE_MAX : (size_t) (first - buffer->value);
}

/**
 * Insert the given string into the buffer at the given index.
 */
void
pm_buffer_insert(pm_buffer_t *buffer, size_t index, const char *value, size_t length) {
    assert(index <= buffer->length);

    if (index == buffer->length) {
        pm_buffer_append_string(buffer, value, length);
    } else {
        pm_buffer_append_zeroes(buffer, length);
        memmove(buffer->value + index + length, buffer->value + index, buffer->length - length - index);
        memcpy(buffer->value + index, value, length);
    }
}

/**
 * Free the memory associated with the buffer.
 */
void
pm_buffer_free(pm_buffer_t *buffer) {
    xfree(buffer->value);
}
