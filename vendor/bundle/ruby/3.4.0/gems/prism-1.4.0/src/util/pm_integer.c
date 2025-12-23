#include "prism/util/pm_integer.h"

/**
 * Pull out the length and values from the integer, regardless of the form in
 * which the length/values are stored.
 */
#define INTEGER_EXTRACT(integer, length_variable, values_variable) \
    if ((integer)->values == NULL) { \
        length_variable = 1; \
        values_variable = &(integer)->value; \
    } else { \
        length_variable = (integer)->length; \
        values_variable = (integer)->values; \
    }

/**
 * Adds two positive pm_integer_t with the given base.
 * Return pm_integer_t with values allocated. Not normalized.
 */
static void
big_add(pm_integer_t *destination, pm_integer_t *left, pm_integer_t *right, uint64_t base) {
    size_t left_length;
    uint32_t *left_values;
    INTEGER_EXTRACT(left, left_length, left_values)

    size_t right_length;
    uint32_t *right_values;
    INTEGER_EXTRACT(right, right_length, right_values)

    size_t length = left_length < right_length ? right_length : left_length;
    uint32_t *values = (uint32_t *) xmalloc(sizeof(uint32_t) * (length + 1));
    if (values == NULL) return;

    uint64_t carry = 0;
    for (size_t index = 0; index < length; index++) {
        uint64_t sum = carry + (index < left_length ? left_values[index] : 0) + (index < right_length ? right_values[index] : 0);
        values[index] = (uint32_t) (sum % base);
        carry = sum / base;
    }

    if (carry > 0) {
        values[length] = (uint32_t) carry;
        length++;
    }

    *destination = (pm_integer_t) { length, values, 0, false };
}

/**
 * Internal use for karatsuba_multiply. Calculates `a - b - c` with the given
 * base. Assume a, b, c, a - b - c all to be positive.
 * Return pm_integer_t with values allocated. Not normalized.
 */
static void
big_sub2(pm_integer_t *destination, pm_integer_t *a, pm_integer_t *b, pm_integer_t *c, uint64_t base) {
    size_t a_length;
    uint32_t *a_values;
    INTEGER_EXTRACT(a, a_length, a_values)

    size_t b_length;
    uint32_t *b_values;
    INTEGER_EXTRACT(b, b_length, b_values)

    size_t c_length;
    uint32_t *c_values;
    INTEGER_EXTRACT(c, c_length, c_values)

    uint32_t *values = (uint32_t*) xmalloc(sizeof(uint32_t) * a_length);
    int64_t carry = 0;

    for (size_t index = 0; index < a_length; index++) {
        int64_t sub = (
            carry +
            a_values[index] -
            (index < b_length ? b_values[index] : 0) -
            (index < c_length ? c_values[index] : 0)
        );

        if (sub >= 0) {
            values[index] = (uint32_t) sub;
            carry = 0;
        } else {
            sub += 2 * (int64_t) base;
            values[index] = (uint32_t) ((uint64_t) sub % base);
            carry = sub / (int64_t) base - 2;
        }
    }

    while (a_length > 1 && values[a_length - 1] == 0) a_length--;
    *destination = (pm_integer_t) { a_length, values, 0, false };
}

/**
 * Multiply two positive integers with the given base using karatsuba algorithm.
 * Return pm_integer_t with values allocated. Not normalized.
 */
static void
karatsuba_multiply(pm_integer_t *destination, pm_integer_t *left, pm_integer_t *right, uint64_t base) {
    size_t left_length;
    uint32_t *left_values;
    INTEGER_EXTRACT(left, left_length, left_values)

    size_t right_length;
    uint32_t *right_values;
    INTEGER_EXTRACT(right, right_length, right_values)

    if (left_length > right_length) {
        size_t temporary_length = left_length;
        left_length = right_length;
        right_length = temporary_length;

        uint32_t *temporary_values = left_values;
        left_values = right_values;
        right_values = temporary_values;
    }

    if (left_length <= 10) {
        size_t length = left_length + right_length;
        uint32_t *values = (uint32_t *) xcalloc(length, sizeof(uint32_t));
        if (values == NULL) return;

        for (size_t left_index = 0; left_index < left_length; left_index++) {
            uint32_t carry = 0;
            for (size_t right_index = 0; right_index < right_length; right_index++) {
                uint64_t product = (uint64_t) left_values[left_index] * right_values[right_index] + values[left_index + right_index] + carry;
                values[left_index + right_index] = (uint32_t) (product % base);
                carry = (uint32_t) (product / base);
            }
            values[left_index + right_length] = carry;
        }

        while (length > 1 && values[length - 1] == 0) length--;
        *destination = (pm_integer_t) { length, values, 0, false };
        return;
    }

    if (left_length * 2 <= right_length) {
        uint32_t *values = (uint32_t *) xcalloc(left_length + right_length, sizeof(uint32_t));

        for (size_t start_offset = 0; start_offset < right_length; start_offset += left_length) {
            size_t end_offset = start_offset + left_length;
            if (end_offset > right_length) end_offset = right_length;

            pm_integer_t sliced_left = {
                .length = left_length,
                .values = left_values,
                .value = 0,
                .negative = false
            };

            pm_integer_t sliced_right = {
                .length = end_offset - start_offset,
                .values = right_values + start_offset,
                .value = 0,
                .negative = false
            };

            pm_integer_t product;
            karatsuba_multiply(&product, &sliced_left, &sliced_right, base);

            uint32_t carry = 0;
            for (size_t index = 0; index < product.length; index++) {
                uint64_t sum = (uint64_t) values[start_offset + index] + product.values[index] + carry;
                values[start_offset + index] = (uint32_t) (sum % base);
                carry = (uint32_t) (sum / base);
            }

            if (carry > 0) values[start_offset + product.length] += carry;
            pm_integer_free(&product);
        }

        *destination = (pm_integer_t) { left_length + right_length, values, 0, false };
        return;
    }

    size_t half = left_length / 2;
    pm_integer_t x0 = { half, left_values, 0, false };
    pm_integer_t x1 = { left_length - half, left_values + half, 0, false };
    pm_integer_t y0 = { half, right_values, 0, false };
    pm_integer_t y1 = { right_length - half, right_values + half, 0, false };

    pm_integer_t z0 = { 0 };
    karatsuba_multiply(&z0, &x0, &y0, base);

    pm_integer_t z2 = { 0 };
    karatsuba_multiply(&z2, &x1, &y1, base);

    // For simplicity to avoid considering negative values,
    // use `z1 = (x0 + x1) * (y0 + y1) - z0 - z2` instead of original karatsuba algorithm.
    pm_integer_t x01 = { 0 };
    big_add(&x01, &x0, &x1, base);

    pm_integer_t y01 = { 0 };
    big_add(&y01, &y0, &y1, base);

    pm_integer_t xy = { 0 };
    karatsuba_multiply(&xy, &x01, &y01, base);

    pm_integer_t z1;
    big_sub2(&z1, &xy, &z0, &z2, base);

    size_t length = left_length + right_length;
    uint32_t *values = (uint32_t*) xcalloc(length, sizeof(uint32_t));

    assert(z0.values != NULL);
    memcpy(values, z0.values, sizeof(uint32_t) * z0.length);

    assert(z2.values != NULL);
    memcpy(values + 2 * half, z2.values, sizeof(uint32_t) * z2.length);

    uint32_t carry = 0;
    for(size_t index = 0; index < z1.length; index++) {
        uint64_t sum = (uint64_t) carry + values[index + half] + z1.values[index];
        values[index + half] = (uint32_t) (sum % base);
        carry = (uint32_t) (sum / base);
    }

    for(size_t index = half + z1.length; carry > 0; index++) {
        uint64_t sum = (uint64_t) carry + values[index];
        values[index] = (uint32_t) (sum % base);
        carry = (uint32_t) (sum / base);
    }

    while (length > 1 && values[length - 1] == 0) length--;
    pm_integer_free(&z0);
    pm_integer_free(&z1);
    pm_integer_free(&z2);
    pm_integer_free(&x01);
    pm_integer_free(&y01);
    pm_integer_free(&xy);

    *destination = (pm_integer_t) { length, values, 0, false };
}

/**
 * The values of a hexadecimal digit, where the index is the ASCII character.
 * Note that there's an odd exception here where _ is mapped to 0. This is
 * because it's possible for us to end up trying to parse a number that has
 * already had an error attached to it, and we want to provide _something_ to
 * the user.
 */
static const int8_t pm_integer_parse_digit_values[256] = {
//   0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // 0x
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // 1x
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // 2x
     0,  1,  2,  3,  4,  5,  6,  7,  8,  9, -1, -1, -1, -1, -1, -1, // 3x
    -1, 10, 11, 12, 13, 14, 15, -1, -1, -1, -1, -1, -1, -1, -1, -1, // 4x
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,  0, // 5x
    -1, 10, 11, 12, 13, 14, 15, -1, -1, -1, -1, -1, -1, -1, -1, -1, // 6x
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // 7x
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // 8x
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // 9x
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // Ax
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // Bx
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // Cx
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // Dx
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // Ex
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // Fx
};

/**
 * Return the value of a hexadecimal digit in a uint8_t.
 */
static uint8_t
pm_integer_parse_digit(const uint8_t character) {
    int8_t value = pm_integer_parse_digit_values[character];
    assert(value != -1 && "invalid digit");

    return (uint8_t) value;
}

/**
 * Create a pm_integer_t from uint64_t with the given base. It is assumed that
 * the memory for the pm_integer_t pointer has been zeroed.
 */
static void
pm_integer_from_uint64(pm_integer_t *integer, uint64_t value, uint64_t base) {
    if (value < base) {
        integer->value = (uint32_t) value;
        return;
    }

    size_t length = 0;
    uint64_t length_value = value;
    while (length_value > 0) {
        length++;
        length_value /= base;
    }

    uint32_t *values = (uint32_t *) xmalloc(sizeof(uint32_t) * length);
    if (values == NULL) return;

    for (size_t value_index = 0; value_index < length; value_index++) {
        values[value_index] = (uint32_t) (value % base);
        value /= base;
    }

    integer->length = length;
    integer->values = values;
}

/**
 * Normalize pm_integer_t.
 * Heading zero values will be removed. If the integer fits into uint32_t,
 * values is set to NULL, length is set to 0, and value field will be used.
 */
static void
pm_integer_normalize(pm_integer_t *integer) {
    if (integer->values == NULL) {
        return;
    }

    while (integer->length > 1 && integer->values[integer->length - 1] == 0) {
        integer->length--;
    }

    if (integer->length > 1) {
        return;
    }

    uint32_t value = integer->values[0];
    bool negative = integer->negative && value != 0;

    pm_integer_free(integer);
    *integer = (pm_integer_t) { .values = NULL, .value = value, .length = 0, .negative = negative };
}

/**
 * Convert base of the integer.
 * In practice, it converts 10**9 to 1<<32 or 1<<32 to 10**9.
 */
static void
pm_integer_convert_base(pm_integer_t *destination, const pm_integer_t *source, uint64_t base_from, uint64_t base_to) {
    size_t source_length;
    const uint32_t *source_values;
    INTEGER_EXTRACT(source, source_length, source_values)

    size_t bigints_length = (source_length + 1) / 2;
    assert(bigints_length > 0);

    pm_integer_t *bigints = (pm_integer_t *) xcalloc(bigints_length, sizeof(pm_integer_t));
    if (bigints == NULL) return;

    for (size_t index = 0; index < source_length; index += 2) {
        uint64_t value = source_values[index] + base_from * (index + 1 < source_length ? source_values[index + 1] : 0);
        pm_integer_from_uint64(&bigints[index / 2], value, base_to);
    }

    pm_integer_t base = { 0 };
    pm_integer_from_uint64(&base, base_from, base_to);

    while (bigints_length > 1) {
        pm_integer_t next_base;
        karatsuba_multiply(&next_base, &base, &base, base_to);

        pm_integer_free(&base);
        base = next_base;

        size_t next_length = (bigints_length + 1) / 2;
        pm_integer_t *next_bigints = (pm_integer_t *) xcalloc(next_length, sizeof(pm_integer_t));

        for (size_t bigints_index = 0; bigints_index < bigints_length; bigints_index += 2) {
            if (bigints_index + 1 == bigints_length) {
                next_bigints[bigints_index / 2] = bigints[bigints_index];
            } else {
                pm_integer_t multiplied = { 0 };
                karatsuba_multiply(&multiplied, &base, &bigints[bigints_index + 1], base_to);

                big_add(&next_bigints[bigints_index / 2], &bigints[bigints_index], &multiplied, base_to);
                pm_integer_free(&bigints[bigints_index]);
                pm_integer_free(&bigints[bigints_index + 1]);
                pm_integer_free(&multiplied);
            }
        }

        xfree(bigints);
        bigints = next_bigints;
        bigints_length = next_length;
    }

    *destination = bigints[0];
    destination->negative = source->negative;
    pm_integer_normalize(destination);

    xfree(bigints);
    pm_integer_free(&base);
}

#undef INTEGER_EXTRACT

/**
 * Convert digits to integer with the given power-of-two base.
 */
static void
pm_integer_parse_powof2(pm_integer_t *integer, uint32_t base, const uint8_t *digits, size_t digits_length) {
    size_t bit = 1;
    while (base > (uint32_t) (1 << bit)) bit++;

    size_t length = (digits_length * bit + 31) / 32;
    uint32_t *values = (uint32_t *) xcalloc(length, sizeof(uint32_t));

    for (size_t digit_index = 0; digit_index < digits_length; digit_index++) {
        size_t bit_position = bit * (digits_length - digit_index - 1);
        uint32_t value = digits[digit_index];

        size_t index = bit_position / 32;
        size_t shift = bit_position % 32;

        values[index] |= value << shift;
        if (32 - shift < bit) values[index + 1] |= value >> (32 - shift);
    }

    while (length > 1 && values[length - 1] == 0) length--;
    *integer = (pm_integer_t) { .length = length, .values = values, .value = 0, .negative = false };
    pm_integer_normalize(integer);
}

/**
 * Convert decimal digits to pm_integer_t.
 */
static void
pm_integer_parse_decimal(pm_integer_t *integer, const uint8_t *digits, size_t digits_length) {
    const size_t batch = 9;
    size_t length = (digits_length + batch - 1) / batch;

    uint32_t *values = (uint32_t *) xcalloc(length, sizeof(uint32_t));
    uint32_t value = 0;

    for (size_t digits_index = 0; digits_index < digits_length; digits_index++) {
        value = value * 10 + digits[digits_index];

        size_t reverse_index = digits_length - digits_index - 1;
        if (reverse_index % batch == 0) {
            values[reverse_index / batch] = value;
            value = 0;
        }
    }

    // Convert base from 10**9 to 1<<32.
    pm_integer_convert_base(integer, &((pm_integer_t) { .length = length, .values = values,  .value = 0, .negative = false }), 1000000000, ((uint64_t) 1 << 32));
    xfree(values);
}

/**
 * Parse a large integer from a string that does not fit into uint32_t.
 */
static void
pm_integer_parse_big(pm_integer_t *integer, uint32_t multiplier, const uint8_t *start, const uint8_t *end) {
    // Allocate an array to store digits.
    uint8_t *digits = xmalloc(sizeof(uint8_t) * (size_t) (end - start));
    size_t digits_length = 0;

    for (; start < end; start++) {
        if (*start == '_') continue;
        digits[digits_length++] = pm_integer_parse_digit(*start);
    }

    // Construct pm_integer_t from the digits.
    if (multiplier == 10) {
        pm_integer_parse_decimal(integer, digits, digits_length);
    } else {
        pm_integer_parse_powof2(integer, multiplier, digits, digits_length);
    }

    xfree(digits);
}

/**
 * Parse an integer from a string. This assumes that the format of the integer
 * has already been validated, as internal validation checks are not performed
 * here.
 */
void
pm_integer_parse(pm_integer_t *integer, pm_integer_base_t base, const uint8_t *start, const uint8_t *end) {
    // Ignore unary +. Unary - is parsed differently and will not end up here.
    // Instead, it will modify the parsed integer later.
    if (*start == '+') start++;

    // Determine the multiplier from the base, and skip past any prefixes.
    uint32_t multiplier = 10;
    switch (base) {
        case PM_INTEGER_BASE_DEFAULT:
            while (*start == '0') start++; // 01 -> 1
            break;
        case PM_INTEGER_BASE_BINARY:
            start += 2; // 0b
            multiplier = 2;
            break;
        case PM_INTEGER_BASE_OCTAL:
            start++; // 0
            if (*start == '_' || *start == 'o' || *start == 'O') start++; // o
            multiplier = 8;
            break;
        case PM_INTEGER_BASE_DECIMAL:
            if (*start == '0' && (end - start) > 1) start += 2; // 0d
            break;
        case PM_INTEGER_BASE_HEXADECIMAL:
            start += 2; // 0x
            multiplier = 16;
            break;
        case PM_INTEGER_BASE_UNKNOWN:
            if (*start == '0' && (end - start) > 1) {
                switch (start[1]) {
                    case '_': start += 2; multiplier = 8; break;
                    case '0': case '1': case '2': case '3': case '4': case '5': case '6': case '7': start++; multiplier = 8; break;
                    case 'b': case 'B': start += 2; multiplier = 2; break;
                    case 'o': case 'O': start += 2; multiplier = 8; break;
                    case 'd': case 'D': start += 2; break;
                    case 'x': case 'X': start += 2; multiplier = 16; break;
                    default: assert(false && "unreachable"); break;
                }
            }
            break;
    }

    // It's possible that we've consumed everything at this point if there is an
    // invalid integer. If this is the case, we'll just return 0.
    if (start >= end) return;

    const uint8_t *cursor = start;
    uint64_t value = (uint64_t) pm_integer_parse_digit(*cursor++);

    for (; cursor < end; cursor++) {
        if (*cursor == '_') continue;
        value = value * multiplier + (uint64_t) pm_integer_parse_digit(*cursor);

        if (value > UINT32_MAX) {
            // If the integer is too large to fit into a single uint32_t, then
            // we'll parse it as a big integer.
            pm_integer_parse_big(integer, multiplier, start, end);
            return;
        }
    }

    integer->value = (uint32_t) value;
}

/**
 * Compare two integers. This function returns -1 if the left integer is less
 * than the right integer, 0 if they are equal, and 1 if the left integer is
 * greater than the right integer.
 */
int
pm_integer_compare(const pm_integer_t *left, const pm_integer_t *right) {
    if (left->negative != right->negative) return left->negative ? -1 : 1;
    int negative = left->negative ? -1 : 1;

    if (left->values == NULL && right->values == NULL) {
        if (left->value < right->value) return -1 * negative;
        if (left->value > right->value) return 1 * negative;
        return 0;
    }

    if (left->values == NULL || left->length < right->length) return -1 * negative;
    if (right->values == NULL || left->length > right->length) return 1 * negative;

    for (size_t index = 0; index < left->length; index++) {
        size_t value_index = left->length - index - 1;
        uint32_t left_value = left->values[value_index];
        uint32_t right_value = right->values[value_index];

        if (left_value < right_value) return -1 * negative;
        if (left_value > right_value) return 1 * negative;
    }

    return 0;
}

/**
 * Reduce a ratio of integers to its simplest form.
 */
void pm_integers_reduce(pm_integer_t *numerator, pm_integer_t *denominator) {
    // If either the numerator or denominator do not fit into a 32-bit integer,
    // then this function is a no-op. In the future, we may consider reducing
    // even the larger numbers, but for now we're going to keep it simple.
    if (
        // If the numerator doesn't fit into a 32-bit integer, return early.
        numerator->length != 0 ||
        // If the denominator doesn't fit into a 32-bit integer, return early.
        denominator->length != 0 ||
        // If the numerator is 0, then return early.
        numerator->value == 0 ||
        // If the denominator is 1, then return early.
        denominator->value == 1
    ) return;

    // Find the greatest common divisor of the numerator and denominator.
    uint32_t divisor = numerator->value;
    uint32_t remainder = denominator->value;

    while (remainder != 0) {
        uint32_t temporary = remainder;
        remainder = divisor % remainder;
        divisor = temporary;
    }

    // Divide the numerator and denominator by the greatest common divisor.
    numerator->value /= divisor;
    denominator->value /= divisor;
}

/**
 * Convert an integer to a decimal string.
 */
PRISM_EXPORTED_FUNCTION void
pm_integer_string(pm_buffer_t *buffer, const pm_integer_t *integer) {
    if (integer->negative) {
        pm_buffer_append_byte(buffer, '-');
    }

    // If the integer fits into a single uint32_t, then we can just append the
    // value directly to the buffer.
    if (integer->values == NULL) {
        pm_buffer_append_format(buffer, "%" PRIu32, integer->value);
        return;
    }

    // If the integer is two uint32_t values, then we can | them together and
    // append the result to the buffer.
    if (integer->length == 2) {
        const uint64_t value = ((uint64_t) integer->values[0]) | ((uint64_t) integer->values[1] << 32);
        pm_buffer_append_format(buffer, "%" PRIu64, value);
        return;
    }

    // Otherwise, first we'll convert the base from 1<<32 to 10**9.
    pm_integer_t converted = { 0 };
    pm_integer_convert_base(&converted, integer, (uint64_t) 1 << 32, 1000000000);

    if (converted.values == NULL) {
        pm_buffer_append_format(buffer, "%" PRIu32, converted.value);
        pm_integer_free(&converted);
        return;
    }

    // Allocate a buffer that we'll copy the decimal digits into.
    size_t digits_length = converted.length * 9;
    char *digits = xcalloc(digits_length, sizeof(char));
    if (digits == NULL) return;

    // Pack bigdecimal to digits.
    for (size_t value_index = 0; value_index < converted.length; value_index++) {
        uint32_t value = converted.values[value_index];

        for (size_t digit_index = 0; digit_index < 9; digit_index++) {
            digits[digits_length - 9 * value_index - digit_index - 1] = (char) ('0' + value % 10);
            value /= 10;
        }
    }

    size_t start_offset = 0;
    while (start_offset < digits_length - 1 && digits[start_offset] == '0') start_offset++;

    // Finally, append the string to the buffer and free the digits.
    pm_buffer_append_string(buffer, digits + start_offset, digits_length - start_offset);
    xfree(digits);
    pm_integer_free(&converted);
}

/**
 * Free the internal memory of an integer. This memory will only be allocated if
 * the integer exceeds the size of a single uint32_t.
 */
PRISM_EXPORTED_FUNCTION void
pm_integer_free(pm_integer_t *integer) {
    if (integer->values) {
        xfree(integer->values);
    }
}
