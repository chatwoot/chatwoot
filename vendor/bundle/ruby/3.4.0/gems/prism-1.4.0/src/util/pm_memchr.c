#include "prism/util/pm_memchr.h"

#define PRISM_MEMCHR_TRAILING_BYTE_MINIMUM 0x40

/**
 * We need to roll our own memchr to handle cases where the encoding changes and
 * we need to search for a character in a buffer that could be the trailing byte
 * of a multibyte character.
 */
void *
pm_memchr(const void *memory, int character, size_t number, bool encoding_changed, const pm_encoding_t *encoding) {
    if (encoding_changed && encoding->multibyte && character >= PRISM_MEMCHR_TRAILING_BYTE_MINIMUM) {
        const uint8_t *source = (const uint8_t *) memory;
        size_t index = 0;

        while (index < number) {
            if (source[index] == character) {
                return (void *) (source + index);
            }

            size_t width = encoding->char_width(source + index, (ptrdiff_t) (number - index));
            if (width == 0) {
                return NULL;
            }

            index += width;
        }

        return NULL;
    } else {
        return memchr(memory, character, number);
    }
}

#undef PRISM_MEMCHR_TRAILING_BYTE_MINIMUM
