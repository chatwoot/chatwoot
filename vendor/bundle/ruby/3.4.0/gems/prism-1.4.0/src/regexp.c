#include "prism/regexp.h"

#define PM_REGEXP_PARSE_DEPTH_MAX 4096

/**
 * This is the parser that is going to handle parsing regular expressions.
 */
typedef struct {
    /** The parser that is currently being used. */
    pm_parser_t *parser;

    /** A pointer to the start of the source that we are parsing. */
    const uint8_t *start;

    /** A pointer to the current position in the source. */
    const uint8_t *cursor;

    /** A pointer to the end of the source that we are parsing. */
    const uint8_t *end;

    /**
     * Whether or not the regular expression currently being parsed is in
     * extended mode, wherein whitespace is ignored and comments are allowed.
     */
    bool extended_mode;

    /** Whether the encoding has changed from the default. */
    bool encoding_changed;

    /** The encoding of the source. */
    const pm_encoding_t *encoding;

    /** The callback to call when a named capture group is found. */
    pm_regexp_name_callback_t name_callback;

    /** The data to pass to the name callback. */
    void *name_data;

    /** The callback to call when a parse error is found. */
    pm_regexp_error_callback_t error_callback;

    /** The data to pass to the error callback. */
    void *error_data;
} pm_regexp_parser_t;

/**
 * Append an error to the parser.
 */
static inline void
pm_regexp_parse_error(pm_regexp_parser_t *parser, const uint8_t *start, const uint8_t *end, const char *message) {
    parser->error_callback(start, end, message, parser->error_data);
}

/**
 * This appends a new string to the list of named captures. This function
 * assumes the caller has already checked the validity of the name callback.
 */
static void
pm_regexp_parser_named_capture(pm_regexp_parser_t *parser, const uint8_t *start, const uint8_t *end) {
    pm_string_t string;
    pm_string_shared_init(&string, start, end);
    parser->name_callback(&string, parser->name_data);
    pm_string_free(&string);
}

/**
 * Returns true if the next character is the end of the source.
 */
static inline bool
pm_regexp_char_is_eof(pm_regexp_parser_t *parser) {
    return parser->cursor >= parser->end;
}

/**
 * Optionally accept a char and consume it if it exists.
 */
static inline bool
pm_regexp_char_accept(pm_regexp_parser_t *parser, uint8_t value) {
    if (!pm_regexp_char_is_eof(parser) && *parser->cursor == value) {
        parser->cursor++;
        return true;
    }
    return false;
}

/**
 * Expect a character to be present and consume it.
 */
static inline bool
pm_regexp_char_expect(pm_regexp_parser_t *parser, uint8_t value) {
    if (!pm_regexp_char_is_eof(parser) && *parser->cursor == value) {
        parser->cursor++;
        return true;
    }
    return false;
}

/**
 * This advances the current token to the next instance of the given character.
 */
static bool
pm_regexp_char_find(pm_regexp_parser_t *parser, uint8_t value) {
    if (pm_regexp_char_is_eof(parser)) {
        return false;
    }

    const uint8_t *end = (const uint8_t *) pm_memchr(parser->cursor, value, (size_t) (parser->end - parser->cursor), parser->encoding_changed, parser->encoding);
    if (end == NULL) {
        return false;
    }

    parser->cursor = end + 1;
    return true;
}

/**
 * Range quantifiers are a special class of quantifiers that look like
 *
 * * {digit}
 * * {digit,}
 * * {digit,digit}
 * * {,digit}
 *
 * Unfortunately, if there are any spaces in between, then this just becomes a
 * regular character match expression and we have to backtrack. So when this
 * function first starts running, we'll create a "save" point and then attempt
 * to parse the quantifier. If it fails, we'll restore the save point and
 * return.
 *
 * The properly track everything, we're going to build a little state machine.
 * It looks something like the following:
 *
 *                  +-------+                 +---------+ ------------+
 * ---- lbrace ---> | start | ---- digit ---> | minimum |             |
 *                  +-------+                 +---------+ <--- digit -+
 *                      |                       |    |
 *   +-------+          |                       |  rbrace
 *   | comma | <----- comma  +---- comma -------+    |
 *   +-------+               V                       V
 *      |             +---------+               +---------+
 *      +-- digit --> | maximum | -- rbrace --> || final ||
 *                    +---------+               +---------+
 *                    |         ^
 *                    +- digit -+
 *
 * Note that by the time we've hit this function, the lbrace has already been
 * consumed so we're in the start state.
 */
static bool
pm_regexp_parse_range_quantifier(pm_regexp_parser_t *parser) {
    const uint8_t *savepoint = parser->cursor;

    enum {
        PM_REGEXP_RANGE_QUANTIFIER_STATE_START,
        PM_REGEXP_RANGE_QUANTIFIER_STATE_MINIMUM,
        PM_REGEXP_RANGE_QUANTIFIER_STATE_MAXIMUM,
        PM_REGEXP_RANGE_QUANTIFIER_STATE_COMMA
    } state = PM_REGEXP_RANGE_QUANTIFIER_STATE_START;

    while (1) {
        if (parser->cursor >= parser->end) {
            parser->cursor = savepoint;
            return true;
        }

        switch (state) {
            case PM_REGEXP_RANGE_QUANTIFIER_STATE_START:
                switch (*parser->cursor) {
                    case '0': case '1': case '2': case '3': case '4': case '5': case '6': case '7': case '8': case '9':
                        parser->cursor++;
                        state = PM_REGEXP_RANGE_QUANTIFIER_STATE_MINIMUM;
                        break;
                    case ',':
                        parser->cursor++;
                        state = PM_REGEXP_RANGE_QUANTIFIER_STATE_COMMA;
                        break;
                    default:
                        parser->cursor = savepoint;
                        return true;
                }
                break;
            case PM_REGEXP_RANGE_QUANTIFIER_STATE_MINIMUM:
                switch (*parser->cursor) {
                    case '0': case '1': case '2': case '3': case '4': case '5': case '6': case '7': case '8': case '9':
                        parser->cursor++;
                        break;
                    case ',':
                        parser->cursor++;
                        state = PM_REGEXP_RANGE_QUANTIFIER_STATE_MAXIMUM;
                        break;
                    case '}':
                        parser->cursor++;
                        return true;
                    default:
                        parser->cursor = savepoint;
                        return true;
                }
                break;
            case PM_REGEXP_RANGE_QUANTIFIER_STATE_COMMA:
                switch (*parser->cursor) {
                    case '0': case '1': case '2': case '3': case '4': case '5': case '6': case '7': case '8': case '9':
                        parser->cursor++;
                        state = PM_REGEXP_RANGE_QUANTIFIER_STATE_MAXIMUM;
                        break;
                    default:
                        parser->cursor = savepoint;
                        return true;
                }
                break;
            case PM_REGEXP_RANGE_QUANTIFIER_STATE_MAXIMUM:
                switch (*parser->cursor) {
                    case '0': case '1': case '2': case '3': case '4': case '5': case '6': case '7': case '8': case '9':
                        parser->cursor++;
                        break;
                    case '}':
                        parser->cursor++;
                        return true;
                    default:
                        parser->cursor = savepoint;
                        return true;
                }
                break;
        }
    }

    return true;
}

/**
 * quantifier : star-quantifier
 *            | plus-quantifier
 *            | optional-quantifier
 *            | range-quantifier
 *            | <empty>
 *            ;
 */
static bool
pm_regexp_parse_quantifier(pm_regexp_parser_t *parser) {
    while (!pm_regexp_char_is_eof(parser)) {
        switch (*parser->cursor) {
            case '*':
            case '+':
            case '?':
                parser->cursor++;
                break;
            case '{':
                parser->cursor++;
                if (!pm_regexp_parse_range_quantifier(parser)) return false;
                break;
            default:
                // In this case there is no quantifier.
                return true;
        }
    }

    return true;
}

/**
 * match-posix-class : '[' '[' ':' '^'? CHAR+ ':' ']' ']'
 *                   ;
 */
static bool
pm_regexp_parse_posix_class(pm_regexp_parser_t *parser) {
    if (!pm_regexp_char_expect(parser, ':')) {
        return false;
    }

    pm_regexp_char_accept(parser, '^');

    return (
        pm_regexp_char_find(parser, ':') &&
        pm_regexp_char_expect(parser, ']') &&
        pm_regexp_char_expect(parser, ']')
    );
}

// Forward declaration because character sets can be nested.
static bool
pm_regexp_parse_lbracket(pm_regexp_parser_t *parser, uint16_t depth);

/**
 * match-char-set : '[' '^'? (match-range | match-char)* ']'
 *                ;
 */
static bool
pm_regexp_parse_character_set(pm_regexp_parser_t *parser, uint16_t depth) {
    pm_regexp_char_accept(parser, '^');

    while (!pm_regexp_char_is_eof(parser) && *parser->cursor != ']') {
        switch (*parser->cursor++) {
            case '[':
                pm_regexp_parse_lbracket(parser, (uint16_t) (depth + 1));
                break;
            case '\\':
                if (!pm_regexp_char_is_eof(parser)) {
                    parser->cursor++;
                }
                break;
            default:
                // do nothing, we've already advanced the cursor
                break;
        }
    }

    return pm_regexp_char_expect(parser, ']');
}

/**
 * A left bracket can either mean a POSIX class or a character set.
 */
static bool
pm_regexp_parse_lbracket(pm_regexp_parser_t *parser, uint16_t depth) {
    if (depth >= PM_REGEXP_PARSE_DEPTH_MAX) {
        pm_regexp_parse_error(parser, parser->start, parser->end, "parse depth limit over");
        return false;
    }

    if ((parser->cursor < parser->end) && parser->cursor[0] == ']') {
        parser->cursor++;
        pm_regexp_parse_error(parser, parser->cursor - 1, parser->cursor, "empty char-class");
        return true;
    }

    const uint8_t *reset = parser->cursor;

    if ((parser->cursor + 2 < parser->end) && parser->cursor[0] == '[' && parser->cursor[1] == ':') {
        parser->cursor++;
        if (pm_regexp_parse_posix_class(parser)) return true;

        parser->cursor = reset;
    }

    return pm_regexp_parse_character_set(parser, depth);
}

// Forward declaration here since parsing groups needs to go back up the grammar
// to parse expressions within them.
static bool
pm_regexp_parse_expression(pm_regexp_parser_t *parser, uint16_t depth);

/**
 * These are the states of the options that are configurable on the regular
 * expression (or from within a group).
 */
typedef enum {
    PM_REGEXP_OPTION_STATE_INVALID,
    PM_REGEXP_OPTION_STATE_TOGGLEABLE,
    PM_REGEXP_OPTION_STATE_ADDABLE,
    PM_REGEXP_OPTION_STATE_ADDED,
    PM_REGEXP_OPTION_STATE_REMOVED
} pm_regexp_option_state_t;

// These are the options that are configurable on the regular expression (or
// from within a group).

#define PRISM_REGEXP_OPTION_STATE_SLOT_MINIMUM 'a'
#define PRISM_REGEXP_OPTION_STATE_SLOT_MAXIMUM 'x'
#define PRISM_REGEXP_OPTION_STATE_SLOTS (PRISM_REGEXP_OPTION_STATE_SLOT_MAXIMUM - PRISM_REGEXP_OPTION_STATE_SLOT_MINIMUM + 1)

/**
 * This is the set of options that are configurable on the regular expression.
 */
typedef struct {
    /** The current state of each option. */
    uint8_t values[PRISM_REGEXP_OPTION_STATE_SLOTS];
} pm_regexp_options_t;

/**
 * Initialize a new set of options to their default values.
 */
static void
pm_regexp_options_init(pm_regexp_options_t *options) {
    memset(options, PM_REGEXP_OPTION_STATE_INVALID, sizeof(uint8_t) * PRISM_REGEXP_OPTION_STATE_SLOTS);
    options->values['i' - PRISM_REGEXP_OPTION_STATE_SLOT_MINIMUM] = PM_REGEXP_OPTION_STATE_TOGGLEABLE;
    options->values['m' - PRISM_REGEXP_OPTION_STATE_SLOT_MINIMUM] = PM_REGEXP_OPTION_STATE_TOGGLEABLE;
    options->values['x' - PRISM_REGEXP_OPTION_STATE_SLOT_MINIMUM] = PM_REGEXP_OPTION_STATE_TOGGLEABLE;
    options->values['d' - PRISM_REGEXP_OPTION_STATE_SLOT_MINIMUM] = PM_REGEXP_OPTION_STATE_ADDABLE;
    options->values['a' - PRISM_REGEXP_OPTION_STATE_SLOT_MINIMUM] = PM_REGEXP_OPTION_STATE_ADDABLE;
    options->values['u' - PRISM_REGEXP_OPTION_STATE_SLOT_MINIMUM] = PM_REGEXP_OPTION_STATE_ADDABLE;
}

/**
 * Attempt to add the given option to the set of options. Returns true if it was
 * added, false if it was already present.
 */
static bool
pm_regexp_options_add(pm_regexp_options_t *options, uint8_t key) {
    if (key >= PRISM_REGEXP_OPTION_STATE_SLOT_MINIMUM && key <= PRISM_REGEXP_OPTION_STATE_SLOT_MAXIMUM) {
        key = (uint8_t) (key - PRISM_REGEXP_OPTION_STATE_SLOT_MINIMUM);

        switch (options->values[key]) {
            case PM_REGEXP_OPTION_STATE_INVALID:
            case PM_REGEXP_OPTION_STATE_REMOVED:
                return false;
            case PM_REGEXP_OPTION_STATE_TOGGLEABLE:
            case PM_REGEXP_OPTION_STATE_ADDABLE:
                options->values[key] = PM_REGEXP_OPTION_STATE_ADDED;
                return true;
            case PM_REGEXP_OPTION_STATE_ADDED:
                return true;
        }
    }

    return false;
}

/**
 * Attempt to remove the given option from the set of options. Returns true if
 * it was removed, false if it was already absent.
 */
static bool
pm_regexp_options_remove(pm_regexp_options_t *options, uint8_t key) {
    if (key >= PRISM_REGEXP_OPTION_STATE_SLOT_MINIMUM && key <= PRISM_REGEXP_OPTION_STATE_SLOT_MAXIMUM) {
        key = (uint8_t) (key - PRISM_REGEXP_OPTION_STATE_SLOT_MINIMUM);

        switch (options->values[key]) {
            case PM_REGEXP_OPTION_STATE_INVALID:
            case PM_REGEXP_OPTION_STATE_ADDABLE:
                return false;
            case PM_REGEXP_OPTION_STATE_TOGGLEABLE:
            case PM_REGEXP_OPTION_STATE_ADDED:
            case PM_REGEXP_OPTION_STATE_REMOVED:
                options->values[key] = PM_REGEXP_OPTION_STATE_REMOVED;
                return true;
        }
    }

    return false;
}

/**
 * True if the given key is set in the options.
 */
static uint8_t
pm_regexp_options_state(pm_regexp_options_t *options, uint8_t key) {
    if (key >= PRISM_REGEXP_OPTION_STATE_SLOT_MINIMUM && key <= PRISM_REGEXP_OPTION_STATE_SLOT_MAXIMUM) {
        key = (uint8_t) (key - PRISM_REGEXP_OPTION_STATE_SLOT_MINIMUM);
        return options->values[key];
    }

    return false;
}

/**
 * Groups can have quite a few different patterns for syntax. They basically
 * just wrap a set of expressions, but they can potentially have options after a
 * question mark. If there _isn't_ a question mark, then it's just a set of
 * expressions. If there _is_, then here are the options:
 *
 * * (?#...)                       - inline comments
 * * (?:subexp)                    - non-capturing group
 * * (?=subexp)                    - positive lookahead
 * * (?!subexp)                    - negative lookahead
 * * (?>subexp)                    - atomic group
 * * (?~subexp)                    - absence operator
 * * (?<=subexp)                   - positive lookbehind
 * * (?<!subexp)                   - negative lookbehind
 * * (?<name>subexp)               - named capturing group
 * * (?'name'subexp)               - named capturing group
 * * (?(cond)yes-subexp)           - conditional expression
 * * (?(cond)yes-subexp|no-subexp) - conditional expression
 * * (?imxdau-imx)                 - turn on and off configuration
 * * (?imxdau-imx:subexp)          - turn on and off configuration for an expression
 */
static bool
pm_regexp_parse_group(pm_regexp_parser_t *parser, uint16_t depth) {
    const uint8_t *group_start = parser->cursor;

    pm_regexp_options_t options;
    pm_regexp_options_init(&options);

    // First, parse any options for the group.
    if (pm_regexp_char_accept(parser, '?')) {
        if (pm_regexp_char_is_eof(parser)) {
            pm_regexp_parse_error(parser, group_start, parser->cursor, "end pattern in group");
            return false;
        }

        switch (*parser->cursor) {
            case '#': { // inline comments
                parser->cursor++;
                if (pm_regexp_char_is_eof(parser)) {
                    pm_regexp_parse_error(parser, group_start, parser->cursor, "end pattern in group");
                    return false;
                }

                if (parser->encoding_changed && parser->encoding->multibyte) {
                    bool escaped = false;

                    // Here we're going to take a slow path and iterate through
                    // each multibyte character to find the close paren. We do
                    // this because \ can be a trailing byte in some encodings.
                    while (parser->cursor < parser->end) {
                        if (!escaped && *parser->cursor == ')') {
                            parser->cursor++;
                            return true;
                        }

                        size_t width = parser->encoding->char_width(parser->cursor, (ptrdiff_t) (parser->end - parser->cursor));
                        if (width == 0) return false;

                        escaped = (width == 1) && (*parser->cursor == '\\');
                        parser->cursor += width;
                    }

                    return false;
                } else {
                    // Here we can take the fast path and use memchr to find the
                    // next ) because we are safe checking backward for \ since
                    // it cannot be a trailing character.
                    bool found = pm_regexp_char_find(parser, ')');

                    while (found && (parser->start <= parser->cursor - 2) && (*(parser->cursor - 2) == '\\')) {
                        found = pm_regexp_char_find(parser, ')');
                    }

                    return found;
                }
            }
            case ':': // non-capturing group
            case '=': // positive lookahead
            case '!': // negative lookahead
            case '>': // atomic group
            case '~': // absence operator
                parser->cursor++;
                break;
            case '<':
                parser->cursor++;
                if (pm_regexp_char_is_eof(parser)) {
                    pm_regexp_parse_error(parser, group_start, parser->cursor, "end pattern with unmatched parenthesis");
                    return false;
                }

                switch (*parser->cursor) {
                    case '=': // positive lookbehind
                    case '!': // negative lookbehind
                        parser->cursor++;
                        break;
                    default: { // named capture group
                        const uint8_t *start = parser->cursor;
                        if (!pm_regexp_char_find(parser, '>')) {
                            return false;
                        }

                        if (parser->cursor - start == 1) {
                            pm_regexp_parse_error(parser, start, parser->cursor, "group name is empty");
                        }

                        if (parser->name_callback != NULL) {
                            pm_regexp_parser_named_capture(parser, start, parser->cursor - 1);
                        }

                        break;
                    }
                }
                break;
            case '\'': { // named capture group
                const uint8_t *start = ++parser->cursor;
                if (!pm_regexp_char_find(parser, '\'')) {
                    return false;
                }

                if (parser->name_callback != NULL) {
                    pm_regexp_parser_named_capture(parser, start, parser->cursor - 1);
                }

                break;
            }
            case '(': // conditional expression
                if (!pm_regexp_char_find(parser, ')')) {
                    return false;
                }
                break;
            case 'i': case 'm': case 'x': case 'd': case 'a': case 'u': // options
                while (!pm_regexp_char_is_eof(parser) && *parser->cursor != '-' && *parser->cursor != ':' && *parser->cursor != ')') {
                    if (!pm_regexp_options_add(&options, *parser->cursor)) {
                        return false;
                    }
                    parser->cursor++;
                }

                if (pm_regexp_char_is_eof(parser)) {
                    return false;
                }

                // If we are at the end of the group of options and there is no
                // subexpression, then we are going to be setting the options
                // for the parent group. In this case we are safe to return now.
                if (*parser->cursor == ')') {
                    if (pm_regexp_options_state(&options, 'x') == PM_REGEXP_OPTION_STATE_ADDED) {
                        parser->extended_mode = true;
                    }

                    parser->cursor++;
                    return true;
                }

                // If we hit a -, then we're done parsing options.
                if (*parser->cursor != '-') break;

                PRISM_FALLTHROUGH
            case '-':
                parser->cursor++;
                while (!pm_regexp_char_is_eof(parser) && *parser->cursor != ':' && *parser->cursor != ')') {
                    if (!pm_regexp_options_remove(&options, *parser->cursor)) {
                        return false;
                    }
                    parser->cursor++;
                }

                if (pm_regexp_char_is_eof(parser)) {
                    return false;
                }

                // If we are at the end of the group of options and there is no
                // subexpression, then we are going to be setting the options
                // for the parent group. In this case we are safe to return now.
                if (*parser->cursor == ')') {
                    switch (pm_regexp_options_state(&options, 'x')) {
                        case PM_REGEXP_OPTION_STATE_ADDED:
                            parser->extended_mode = true;
                            break;
                        case PM_REGEXP_OPTION_STATE_REMOVED:
                            parser->extended_mode = false;
                            break;
                    }

                    parser->cursor++;
                    return true;
                }

                break;
            default:
                parser->cursor++;
                pm_regexp_parse_error(parser, parser->cursor - 1, parser->cursor, "undefined group option");
                break;
        }
    }

    bool extended_mode = parser->extended_mode;
    switch (pm_regexp_options_state(&options, 'x')) {
        case PM_REGEXP_OPTION_STATE_ADDED:
            parser->extended_mode = true;
            break;
        case PM_REGEXP_OPTION_STATE_REMOVED:
            parser->extended_mode = false;
            break;
    }

    // Now, parse the expressions within this group.
    while (!pm_regexp_char_is_eof(parser) && *parser->cursor != ')') {
        if (!pm_regexp_parse_expression(parser, (uint16_t) (depth + 1))) {
            parser->extended_mode = extended_mode;
            return false;
        }
        pm_regexp_char_accept(parser, '|');
    }

    // Finally, make sure we have a closing parenthesis.
    parser->extended_mode = extended_mode;
    if (pm_regexp_char_expect(parser, ')')) return true;

    pm_regexp_parse_error(parser, group_start, parser->cursor, "end pattern with unmatched parenthesis");
    return false;
}

/**
 * item : anchor
 *      | match-posix-class
 *      | match-char-set
 *      | match-char-class
 *      | match-char-prop
 *      | match-char
 *      | match-any
 *      | group
 *      | quantified
 *      ;
 */
static bool
pm_regexp_parse_item(pm_regexp_parser_t *parser, uint16_t depth) {
    switch (*parser->cursor) {
        case '^':
        case '$':
            parser->cursor++;
            return pm_regexp_parse_quantifier(parser);
        case '\\':
            parser->cursor++;
            if (!pm_regexp_char_is_eof(parser)) {
                parser->cursor++;
            }
            return pm_regexp_parse_quantifier(parser);
        case '(':
            parser->cursor++;
            return pm_regexp_parse_group(parser, depth) && pm_regexp_parse_quantifier(parser);
        case '[':
            parser->cursor++;
            return pm_regexp_parse_lbracket(parser, depth) && pm_regexp_parse_quantifier(parser);
        case '*':
        case '?':
        case '+':
            parser->cursor++;
            pm_regexp_parse_error(parser, parser->cursor - 1, parser->cursor, "target of repeat operator is not specified");
            return true;
        case ')':
            parser->cursor++;
            pm_regexp_parse_error(parser, parser->cursor - 1, parser->cursor, "unmatched close parenthesis");
            return true;
        case '#':
            if (parser->extended_mode) {
                if (!pm_regexp_char_find(parser, '\n')) parser->cursor = parser->end;
                return true;
            }
        PRISM_FALLTHROUGH
        default: {
            size_t width;
            if (!parser->encoding_changed) {
                width = pm_encoding_utf_8_char_width(parser->cursor, (ptrdiff_t) (parser->end - parser->cursor));
            } else {
                width = parser->encoding->char_width(parser->cursor, (ptrdiff_t) (parser->end - parser->cursor));
            }

            if (width == 0) return false; // TODO: add appropriate error
            parser->cursor += width;

            return pm_regexp_parse_quantifier(parser);
        }
    }
}

/**
 * expression : item+
 *            ;
 */
static bool
pm_regexp_parse_expression(pm_regexp_parser_t *parser, uint16_t depth) {
    if (depth >= PM_REGEXP_PARSE_DEPTH_MAX) {
        pm_regexp_parse_error(parser, parser->start, parser->end, "parse depth limit over");
        return false;
    }

    if (!pm_regexp_parse_item(parser, depth)) {
        return false;
    }

    while (!pm_regexp_char_is_eof(parser) && *parser->cursor != ')' && *parser->cursor != '|') {
        if (!pm_regexp_parse_item(parser, depth)) {
            return false;
        }
    }

    return true;
}

/**
 * pattern : EOF
 *         | expression EOF
 *         | expression '|' pattern
 *         ;
 */
static bool
pm_regexp_parse_pattern(pm_regexp_parser_t *parser) {
    do {
        if (pm_regexp_char_is_eof(parser)) return true;
        if (!pm_regexp_parse_expression(parser, 0)) return false;
    } while (pm_regexp_char_accept(parser, '|'));

    return pm_regexp_char_is_eof(parser);
}

/**
 * Parse a regular expression and extract the names of all of the named capture
 * groups.
 */
PRISM_EXPORTED_FUNCTION void
pm_regexp_parse(pm_parser_t *parser, const uint8_t *source, size_t size, bool extended_mode, pm_regexp_name_callback_t name_callback, void *name_data, pm_regexp_error_callback_t error_callback, void *error_data) {
    pm_regexp_parse_pattern(&(pm_regexp_parser_t) {
        .parser = parser,
        .start = source,
        .cursor = source,
        .end = source + size,
        .extended_mode = extended_mode,
        .encoding_changed = parser->encoding_changed,
        .encoding = parser->encoding,
        .name_callback = name_callback,
        .name_data = name_data,
        .error_callback = error_callback,
        .error_data = error_data
    });
}
