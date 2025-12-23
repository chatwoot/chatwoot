#include "prism.h"

/**
 * The prism version and the serialization format.
 */
const char *
pm_version(void) {
    return PRISM_VERSION;
}

/**
 * In heredocs, tabs automatically complete up to the next 8 spaces. This is
 * defined in CRuby as TAB_WIDTH.
 */
#define PM_TAB_WHITESPACE_SIZE 8

// Macros for min/max.
#define MIN(a,b) (((a)<(b))?(a):(b))
#define MAX(a,b) (((a)>(b))?(a):(b))

/******************************************************************************/
/* Lex mode manipulations                                                     */
/******************************************************************************/

/**
 * Returns the incrementor character that should be used to increment the
 * nesting count if one is possible.
 */
static inline uint8_t
lex_mode_incrementor(const uint8_t start) {
    switch (start) {
        case '(':
        case '[':
        case '{':
        case '<':
            return start;
        default:
            return '\0';
    }
}

/**
 * Returns the matching character that should be used to terminate a list
 * beginning with the given character.
 */
static inline uint8_t
lex_mode_terminator(const uint8_t start) {
    switch (start) {
        case '(':
            return ')';
        case '[':
            return ']';
        case '{':
            return '}';
        case '<':
            return '>';
        default:
            return start;
    }
}

/**
 * Push a new lex state onto the stack. If we're still within the pre-allocated
 * space of the lex state stack, then we'll just use a new slot. Otherwise we'll
 * allocate a new pointer and use that.
 */
static bool
lex_mode_push(pm_parser_t *parser, pm_lex_mode_t lex_mode) {
    lex_mode.prev = parser->lex_modes.current;
    parser->lex_modes.index++;

    if (parser->lex_modes.index > PM_LEX_STACK_SIZE - 1) {
        parser->lex_modes.current = (pm_lex_mode_t *) xmalloc(sizeof(pm_lex_mode_t));
        if (parser->lex_modes.current == NULL) return false;

        *parser->lex_modes.current = lex_mode;
    } else {
        parser->lex_modes.stack[parser->lex_modes.index] = lex_mode;
        parser->lex_modes.current = &parser->lex_modes.stack[parser->lex_modes.index];
    }

    return true;
}

/**
 * Push on a new list lex mode.
 */
static inline bool
lex_mode_push_list(pm_parser_t *parser, bool interpolation, uint8_t delimiter) {
    uint8_t incrementor = lex_mode_incrementor(delimiter);
    uint8_t terminator = lex_mode_terminator(delimiter);

    pm_lex_mode_t lex_mode = {
        .mode = PM_LEX_LIST,
        .as.list = {
            .nesting = 0,
            .interpolation = interpolation,
            .incrementor = incrementor,
            .terminator = terminator
        }
    };

    // These are the places where we need to split up the content of the list.
    // We'll use strpbrk to find the first of these characters.
    uint8_t *breakpoints = lex_mode.as.list.breakpoints;
    memcpy(breakpoints, "\\ \t\f\r\v\n\0\0\0", sizeof(lex_mode.as.list.breakpoints));
    size_t index = 7;

    // Now we'll add the terminator to the list of breakpoints. If the
    // terminator is not already a NULL byte, add it to the list.
    if (terminator != '\0') {
        breakpoints[index++] = terminator;
    }

    // If interpolation is allowed, then we're going to check for the #
    // character. Otherwise we'll only look for escapes and the terminator.
    if (interpolation) {
        breakpoints[index++] = '#';
    }

    // If there is an incrementor, then we'll check for that as well.
    if (incrementor != '\0') {
        breakpoints[index++] = incrementor;
    }

    parser->explicit_encoding = NULL;
    return lex_mode_push(parser, lex_mode);
}

/**
 * Push on a new list lex mode that is only used for compatibility. This is
 * called when we're at the end of the file. We want the parser to be able to
 * perform its normal error tolerance.
 */
static inline bool
lex_mode_push_list_eof(pm_parser_t *parser) {
    return lex_mode_push_list(parser, false, '\0');
}

/**
 * Push on a new regexp lex mode.
 */
static inline bool
lex_mode_push_regexp(pm_parser_t *parser, uint8_t incrementor, uint8_t terminator) {
    pm_lex_mode_t lex_mode = {
        .mode = PM_LEX_REGEXP,
        .as.regexp = {
            .nesting = 0,
            .incrementor = incrementor,
            .terminator = terminator
        }
    };

    // These are the places where we need to split up the content of the
    // regular expression. We'll use strpbrk to find the first of these
    // characters.
    uint8_t *breakpoints = lex_mode.as.regexp.breakpoints;
    memcpy(breakpoints, "\r\n\\#\0\0", sizeof(lex_mode.as.regexp.breakpoints));
    size_t index = 4;

    // First we'll add the terminator.
    if (terminator != '\0') {
        breakpoints[index++] = terminator;
    }

    // Next, if there is an incrementor, then we'll check for that as well.
    if (incrementor != '\0') {
        breakpoints[index++] = incrementor;
    }

    parser->explicit_encoding = NULL;
    return lex_mode_push(parser, lex_mode);
}

/**
 * Push on a new string lex mode.
 */
static inline bool
lex_mode_push_string(pm_parser_t *parser, bool interpolation, bool label_allowed, uint8_t incrementor, uint8_t terminator) {
    pm_lex_mode_t lex_mode = {
        .mode = PM_LEX_STRING,
        .as.string = {
            .nesting = 0,
            .interpolation = interpolation,
            .label_allowed = label_allowed,
            .incrementor = incrementor,
            .terminator = terminator
        }
    };

    // These are the places where we need to split up the content of the
    // string. We'll use strpbrk to find the first of these characters.
    uint8_t *breakpoints = lex_mode.as.string.breakpoints;
    memcpy(breakpoints, "\r\n\\\0\0\0", sizeof(lex_mode.as.string.breakpoints));
    size_t index = 3;

    // Now add in the terminator. If the terminator is not already a NULL byte,
    // then we'll add it.
    if (terminator != '\0') {
        breakpoints[index++] = terminator;
    }

    // If interpolation is allowed, then we're going to check for the #
    // character. Otherwise we'll only look for escapes and the terminator.
    if (interpolation) {
        breakpoints[index++] = '#';
    }

    // If we have an incrementor, then we'll add that in as a breakpoint as
    // well.
    if (incrementor != '\0') {
        breakpoints[index++] = incrementor;
    }

    parser->explicit_encoding = NULL;
    return lex_mode_push(parser, lex_mode);
}

/**
 * Push on a new string lex mode that is only used for compatibility. This is
 * called when we're at the end of the file. We want the parser to be able to
 * perform its normal error tolerance.
 */
static inline bool
lex_mode_push_string_eof(pm_parser_t *parser) {
    return lex_mode_push_string(parser, false, false, '\0', '\0');
}

/**
 * Pop the current lex state off the stack. If we're within the pre-allocated
 * space of the lex state stack, then we'll just decrement the index. Otherwise
 * we'll free the current pointer and use the previous pointer.
 */
static void
lex_mode_pop(pm_parser_t *parser) {
    if (parser->lex_modes.index == 0) {
        parser->lex_modes.current->mode = PM_LEX_DEFAULT;
    } else if (parser->lex_modes.index < PM_LEX_STACK_SIZE) {
        parser->lex_modes.index--;
        parser->lex_modes.current = &parser->lex_modes.stack[parser->lex_modes.index];
    } else {
        parser->lex_modes.index--;
        pm_lex_mode_t *prev = parser->lex_modes.current->prev;
        xfree(parser->lex_modes.current);
        parser->lex_modes.current = prev;
    }
}

/**
 * This is the equivalent of IS_lex_state is CRuby.
 */
static inline bool
lex_state_p(const pm_parser_t *parser, pm_lex_state_t state) {
    return parser->lex_state & state;
}

typedef enum {
    PM_IGNORED_NEWLINE_NONE = 0,
    PM_IGNORED_NEWLINE_ALL,
    PM_IGNORED_NEWLINE_PATTERN
} pm_ignored_newline_type_t;

static inline pm_ignored_newline_type_t
lex_state_ignored_p(pm_parser_t *parser) {
    bool ignored = lex_state_p(parser, PM_LEX_STATE_BEG | PM_LEX_STATE_CLASS | PM_LEX_STATE_FNAME | PM_LEX_STATE_DOT) && !lex_state_p(parser, PM_LEX_STATE_LABELED);

    if (ignored) {
        return PM_IGNORED_NEWLINE_ALL;
    } else if ((parser->lex_state & ~((unsigned int) PM_LEX_STATE_LABEL)) == (PM_LEX_STATE_ARG | PM_LEX_STATE_LABELED)) {
        return PM_IGNORED_NEWLINE_PATTERN;
    } else {
        return PM_IGNORED_NEWLINE_NONE;
    }
}

static inline bool
lex_state_beg_p(pm_parser_t *parser) {
    return lex_state_p(parser, PM_LEX_STATE_BEG_ANY) || ((parser->lex_state & (PM_LEX_STATE_ARG | PM_LEX_STATE_LABELED)) == (PM_LEX_STATE_ARG | PM_LEX_STATE_LABELED));
}

static inline bool
lex_state_arg_p(pm_parser_t *parser) {
    return lex_state_p(parser, PM_LEX_STATE_ARG_ANY);
}

static inline bool
lex_state_spcarg_p(pm_parser_t *parser, bool space_seen) {
    if (parser->current.end >= parser->end) {
        return false;
    }
    return lex_state_arg_p(parser) && space_seen && !pm_char_is_whitespace(*parser->current.end);
}

static inline bool
lex_state_end_p(pm_parser_t *parser) {
    return lex_state_p(parser, PM_LEX_STATE_END_ANY);
}

/**
 * This is the equivalent of IS_AFTER_OPERATOR in CRuby.
 */
static inline bool
lex_state_operator_p(pm_parser_t *parser) {
    return lex_state_p(parser, PM_LEX_STATE_FNAME | PM_LEX_STATE_DOT);
}

/**
 * Set the state of the lexer. This is defined as a function to be able to put a
 * breakpoint in it.
 */
static inline void
lex_state_set(pm_parser_t *parser, pm_lex_state_t state) {
    parser->lex_state = state;
}

#ifndef PM_DEBUG_LOGGING
/**
 * Debugging logging will print additional information to stdout whenever the
 * lexer state changes.
 */
#define PM_DEBUG_LOGGING 0
#endif

#if PM_DEBUG_LOGGING
PRISM_ATTRIBUTE_UNUSED static void
debug_state(pm_parser_t *parser) {
    fprintf(stderr, "STATE: ");
    bool first = true;

    if (parser->lex_state == PM_LEX_STATE_NONE) {
        fprintf(stderr, "NONE\n");
        return;
    }

#define CHECK_STATE(state) \
    if (parser->lex_state & state) { \
        if (!first) fprintf(stderr, "|"); \
        fprintf(stderr, "%s", #state); \
        first = false; \
    }

    CHECK_STATE(PM_LEX_STATE_BEG)
    CHECK_STATE(PM_LEX_STATE_END)
    CHECK_STATE(PM_LEX_STATE_ENDARG)
    CHECK_STATE(PM_LEX_STATE_ENDFN)
    CHECK_STATE(PM_LEX_STATE_ARG)
    CHECK_STATE(PM_LEX_STATE_CMDARG)
    CHECK_STATE(PM_LEX_STATE_MID)
    CHECK_STATE(PM_LEX_STATE_FNAME)
    CHECK_STATE(PM_LEX_STATE_DOT)
    CHECK_STATE(PM_LEX_STATE_CLASS)
    CHECK_STATE(PM_LEX_STATE_LABEL)
    CHECK_STATE(PM_LEX_STATE_LABELED)
    CHECK_STATE(PM_LEX_STATE_FITEM)

#undef CHECK_STATE

    fprintf(stderr, "\n");
}

static void
debug_lex_state_set(pm_parser_t *parser, pm_lex_state_t state, char const * caller_name, int line_number) {
    fprintf(stderr, "Caller: %s:%d\nPrevious: ", caller_name, line_number);
    debug_state(parser);
    lex_state_set(parser, state);
    fprintf(stderr, "Now: ");
    debug_state(parser);
    fprintf(stderr, "\n");
}

#define lex_state_set(parser, state) debug_lex_state_set(parser, state, __func__, __LINE__)
#endif

/******************************************************************************/
/* Command-line macro helpers                                                 */
/******************************************************************************/

/** True if the parser has the given command-line option. */
#define PM_PARSER_COMMAND_LINE_OPTION(parser, option) ((parser)->command_line & (option))

/** True if the -a command line option was given. */
#define PM_PARSER_COMMAND_LINE_OPTION_A(parser) PM_PARSER_COMMAND_LINE_OPTION(parser, PM_OPTIONS_COMMAND_LINE_A)

/** True if the -e command line option was given. */
#define PM_PARSER_COMMAND_LINE_OPTION_E(parser) PM_PARSER_COMMAND_LINE_OPTION(parser, PM_OPTIONS_COMMAND_LINE_E)

/** True if the -l command line option was given. */
#define PM_PARSER_COMMAND_LINE_OPTION_L(parser) PM_PARSER_COMMAND_LINE_OPTION(parser, PM_OPTIONS_COMMAND_LINE_L)

/** True if the -n command line option was given. */
#define PM_PARSER_COMMAND_LINE_OPTION_N(parser) PM_PARSER_COMMAND_LINE_OPTION(parser, PM_OPTIONS_COMMAND_LINE_N)

/** True if the -p command line option was given. */
#define PM_PARSER_COMMAND_LINE_OPTION_P(parser) PM_PARSER_COMMAND_LINE_OPTION(parser, PM_OPTIONS_COMMAND_LINE_P)

/** True if the -x command line option was given. */
#define PM_PARSER_COMMAND_LINE_OPTION_X(parser) PM_PARSER_COMMAND_LINE_OPTION(parser, PM_OPTIONS_COMMAND_LINE_X)

/******************************************************************************/
/* Diagnostic-related functions                                               */
/******************************************************************************/

/**
 * Append an error to the list of errors on the parser.
 */
static inline void
pm_parser_err(pm_parser_t *parser, const uint8_t *start, const uint8_t *end, pm_diagnostic_id_t diag_id) {
    pm_diagnostic_list_append(&parser->error_list, start, end, diag_id);
}

/**
 * Append an error to the list of errors on the parser using a format string.
 */
#define PM_PARSER_ERR_FORMAT(parser, start, end, diag_id, ...) \
    pm_diagnostic_list_append_format(&parser->error_list, start, end, diag_id, __VA_ARGS__)

/**
 * Append an error to the list of errors on the parser using the location of the
 * current token.
 */
static inline void
pm_parser_err_current(pm_parser_t *parser, pm_diagnostic_id_t diag_id) {
    pm_parser_err(parser, parser->current.start, parser->current.end, diag_id);
}

/**
 * Append an error to the list of errors on the parser using the given location
 * using a format string.
 */
#define PM_PARSER_ERR_LOCATION_FORMAT(parser, location, diag_id, ...) \
    PM_PARSER_ERR_FORMAT(parser, (location)->start, (location)->end, diag_id, __VA_ARGS__)

/**
 * Append an error to the list of errors on the parser using the location of the
 * given node.
 */
static inline void
pm_parser_err_node(pm_parser_t *parser, const pm_node_t *node, pm_diagnostic_id_t diag_id) {
    pm_parser_err(parser, node->location.start, node->location.end, diag_id);
}

/**
 * Append an error to the list of errors on the parser using the location of the
 * given node and a format string.
 */
#define PM_PARSER_ERR_NODE_FORMAT(parser, node, diag_id, ...) \
    PM_PARSER_ERR_FORMAT(parser, (node)->location.start, (node)->location.end, diag_id, __VA_ARGS__)

/**
 * Append an error to the list of errors on the parser using the location of the
 * given node and a format string, and add on the content of the node.
 */
#define PM_PARSER_ERR_NODE_FORMAT_CONTENT(parser, node, diag_id) \
    PM_PARSER_ERR_NODE_FORMAT(parser, node, diag_id, (int) ((node)->location.end - (node)->location.start), (const char *) (node)->location.start)

/**
 * Append an error to the list of errors on the parser using the location of the
 * previous token.
 */
static inline void
pm_parser_err_previous(pm_parser_t *parser, pm_diagnostic_id_t diag_id) {
    pm_parser_err(parser, parser->previous.start, parser->previous.end, diag_id);
}

/**
 * Append an error to the list of errors on the parser using the location of the
 * given token.
 */
static inline void
pm_parser_err_token(pm_parser_t *parser, const pm_token_t *token, pm_diagnostic_id_t diag_id) {
    pm_parser_err(parser, token->start, token->end, diag_id);
}

/**
 * Append an error to the list of errors on the parser using the location of the
 * given token and a format string.
 */
#define PM_PARSER_ERR_TOKEN_FORMAT(parser, token, diag_id, ...) \
    PM_PARSER_ERR_FORMAT(parser, (token).start, (token).end, diag_id, __VA_ARGS__)

/**
 * Append an error to the list of errors on the parser using the location of the
 * given token and a format string, and add on the content of the token.
 */
#define PM_PARSER_ERR_TOKEN_FORMAT_CONTENT(parser, token, diag_id) \
    PM_PARSER_ERR_TOKEN_FORMAT(parser, token, diag_id, (int) ((token).end - (token).start), (const char *) (token).start)

/**
 * Append a warning to the list of warnings on the parser.
 */
static inline void
pm_parser_warn(pm_parser_t *parser, const uint8_t *start, const uint8_t *end, pm_diagnostic_id_t diag_id) {
    pm_diagnostic_list_append(&parser->warning_list, start, end, diag_id);
}

/**
 * Append a warning to the list of warnings on the parser using the location of
 * the given token.
 */
static inline void
pm_parser_warn_token(pm_parser_t *parser, const pm_token_t *token, pm_diagnostic_id_t diag_id) {
    pm_parser_warn(parser, token->start, token->end, diag_id);
}

/**
 * Append a warning to the list of warnings on the parser using the location of
 * the given node.
 */
static inline void
pm_parser_warn_node(pm_parser_t *parser, const pm_node_t *node, pm_diagnostic_id_t diag_id) {
    pm_parser_warn(parser, node->location.start, node->location.end, diag_id);
}

/**
 * Append a warning to the list of warnings on the parser using a format string.
 */
#define PM_PARSER_WARN_FORMAT(parser, start, end, diag_id, ...) \
    pm_diagnostic_list_append_format(&parser->warning_list, start, end, diag_id, __VA_ARGS__)

/**
 * Append a warning to the list of warnings on the parser using the location of
 * the given token and a format string.
 */
#define PM_PARSER_WARN_TOKEN_FORMAT(parser, token, diag_id, ...) \
    PM_PARSER_WARN_FORMAT(parser, (token).start, (token).end, diag_id, __VA_ARGS__)

/**
 * Append a warning to the list of warnings on the parser using the location of
 * the given token and a format string, and add on the content of the token.
 */
#define PM_PARSER_WARN_TOKEN_FORMAT_CONTENT(parser, token, diag_id) \
    PM_PARSER_WARN_TOKEN_FORMAT(parser, token, diag_id, (int) ((token).end - (token).start), (const char *) (token).start)

/**
 * Append a warning to the list of warnings on the parser using the location of
 * the given node and a format string.
 */
#define PM_PARSER_WARN_NODE_FORMAT(parser, node, diag_id, ...) \
    PM_PARSER_WARN_FORMAT(parser, (node)->location.start, (node)->location.end, diag_id, __VA_ARGS__)

/**
 * Add an error for an expected heredoc terminator. This is a special function
 * only because it grabs its location off of a lex mode instead of a node or a
 * token.
 */
static void
pm_parser_err_heredoc_term(pm_parser_t *parser, const uint8_t *ident_start, size_t ident_length) {
    PM_PARSER_ERR_FORMAT(
        parser,
        ident_start,
        ident_start + ident_length,
        PM_ERR_HEREDOC_TERM,
        (int) ident_length,
        (const char *) ident_start
    );
}

/******************************************************************************/
/* Scope-related functions                                                    */
/******************************************************************************/

/**
 * Allocate and initialize a new scope. Push it onto the scope stack.
 */
static bool
pm_parser_scope_push(pm_parser_t *parser, bool closed) {
    pm_scope_t *scope = (pm_scope_t *) xmalloc(sizeof(pm_scope_t));
    if (scope == NULL) return false;

    *scope = (pm_scope_t) {
        .previous = parser->current_scope,
        .locals = { 0 },
        .parameters = PM_SCOPE_PARAMETERS_NONE,
        .implicit_parameters = { 0 },
        .shareable_constant = parser->current_scope == NULL ? PM_SCOPE_SHAREABLE_CONSTANT_NONE : parser->current_scope->shareable_constant,
        .closed = closed
    };

    parser->current_scope = scope;
    return true;
}

/**
 * Determine if the current scope is at the top level. This means it is either
 * the top-level scope or it is open to the top-level.
 */
static bool
pm_parser_scope_toplevel_p(pm_parser_t *parser) {
    pm_scope_t *scope = parser->current_scope;

    do {
        if (scope->previous == NULL) return true;
        if (scope->closed) return false;
    } while ((scope = scope->previous) != NULL);

    assert(false && "unreachable");
    return true;
}

/**
 * Retrieve the scope at the given depth.
 */
static pm_scope_t *
pm_parser_scope_find(pm_parser_t *parser, uint32_t depth) {
    pm_scope_t *scope = parser->current_scope;

    while (depth-- > 0) {
        assert(scope != NULL);
        scope = scope->previous;
    }

    return scope;
}

typedef enum {
    PM_SCOPE_FORWARDING_PARAM_CHECK_RESULT_PASS,
    PM_SCOPE_FORWARDING_PARAM_CHECK_RESULT_CONFLICT,
    PM_SCOPE_FORWARDING_PARAM_CHECK_RESULT_FAIL
} pm_scope_forwarding_param_check_result_t;

static pm_scope_forwarding_param_check_result_t
pm_parser_scope_forwarding_param_check(pm_parser_t *parser, const uint8_t mask) {
    pm_scope_t *scope = parser->current_scope;
    bool conflict = false;

    while (scope != NULL) {
        if (scope->parameters & mask) {
            if (scope->closed) {
                if (conflict) {
                    return PM_SCOPE_FORWARDING_PARAM_CHECK_RESULT_CONFLICT;
                } else {
                    return PM_SCOPE_FORWARDING_PARAM_CHECK_RESULT_PASS;
                }
            }

            conflict = true;
        }

        if (scope->closed) break;
        scope = scope->previous;
    }

    return PM_SCOPE_FORWARDING_PARAM_CHECK_RESULT_FAIL;
}

static void
pm_parser_scope_forwarding_block_check(pm_parser_t *parser, const pm_token_t * token) {
    switch (pm_parser_scope_forwarding_param_check(parser, PM_SCOPE_PARAMETERS_FORWARDING_BLOCK)) {
        case PM_SCOPE_FORWARDING_PARAM_CHECK_RESULT_PASS:
            // Pass.
            break;
        case PM_SCOPE_FORWARDING_PARAM_CHECK_RESULT_CONFLICT:
            pm_parser_err_token(parser, token, PM_ERR_ARGUMENT_CONFLICT_AMPERSAND);
            break;
        case PM_SCOPE_FORWARDING_PARAM_CHECK_RESULT_FAIL:
            pm_parser_err_token(parser, token, PM_ERR_ARGUMENT_NO_FORWARDING_AMPERSAND);
            break;
    }
}

static void
pm_parser_scope_forwarding_positionals_check(pm_parser_t *parser, const pm_token_t * token) {
    switch (pm_parser_scope_forwarding_param_check(parser, PM_SCOPE_PARAMETERS_FORWARDING_POSITIONALS)) {
        case PM_SCOPE_FORWARDING_PARAM_CHECK_RESULT_PASS:
            // Pass.
            break;
        case PM_SCOPE_FORWARDING_PARAM_CHECK_RESULT_CONFLICT:
            pm_parser_err_token(parser, token, PM_ERR_ARGUMENT_CONFLICT_STAR);
            break;
        case PM_SCOPE_FORWARDING_PARAM_CHECK_RESULT_FAIL:
            pm_parser_err_token(parser, token, PM_ERR_ARGUMENT_NO_FORWARDING_STAR);
            break;
    }
}

static void
pm_parser_scope_forwarding_all_check(pm_parser_t *parser, const pm_token_t *token) {
    switch (pm_parser_scope_forwarding_param_check(parser, PM_SCOPE_PARAMETERS_FORWARDING_ALL)) {
        case PM_SCOPE_FORWARDING_PARAM_CHECK_RESULT_PASS:
            // Pass.
            break;
        case PM_SCOPE_FORWARDING_PARAM_CHECK_RESULT_CONFLICT:
            // This shouldn't happen, because ... is not allowed in the
            // declaration of blocks. If we get here, we assume we already have
            // an error for this.
            break;
        case PM_SCOPE_FORWARDING_PARAM_CHECK_RESULT_FAIL:
            pm_parser_err_token(parser, token, PM_ERR_ARGUMENT_NO_FORWARDING_ELLIPSES);
            break;
    }
}

static void
pm_parser_scope_forwarding_keywords_check(pm_parser_t *parser, const pm_token_t * token) {
    switch (pm_parser_scope_forwarding_param_check(parser, PM_SCOPE_PARAMETERS_FORWARDING_KEYWORDS)) {
        case PM_SCOPE_FORWARDING_PARAM_CHECK_RESULT_PASS:
            // Pass.
            break;
        case PM_SCOPE_FORWARDING_PARAM_CHECK_RESULT_CONFLICT:
            pm_parser_err_token(parser, token, PM_ERR_ARGUMENT_CONFLICT_STAR_STAR);
            break;
        case PM_SCOPE_FORWARDING_PARAM_CHECK_RESULT_FAIL:
            pm_parser_err_token(parser, token, PM_ERR_ARGUMENT_NO_FORWARDING_STAR_STAR);
            break;
    }
}

/**
 * Get the current state of constant shareability.
 */
static inline pm_shareable_constant_value_t
pm_parser_scope_shareable_constant_get(pm_parser_t *parser) {
    return parser->current_scope->shareable_constant;
}

/**
 * Set the current state of constant shareability. We'll set it on all of the
 * open scopes so that reads are quick.
 */
static void
pm_parser_scope_shareable_constant_set(pm_parser_t *parser, pm_shareable_constant_value_t shareable_constant) {
    pm_scope_t *scope = parser->current_scope;

    do {
        scope->shareable_constant = shareable_constant;
    } while (!scope->closed && (scope = scope->previous) != NULL);
}

/******************************************************************************/
/* Local variable-related functions                                           */
/******************************************************************************/

/**
 * The point at which the set of locals switches from being a list to a hash.
 */
#define PM_LOCALS_HASH_THRESHOLD 9

static void
pm_locals_free(pm_locals_t *locals) {
    if (locals->capacity > 0) {
        xfree(locals->locals);
    }
}

/**
 * Use as simple and fast a hash function as we can that still properly mixes
 * the bits.
 */
static uint32_t
pm_locals_hash(pm_constant_id_t name) {
    name = ((name >> 16) ^ name) * 0x45d9f3b;
    name = ((name >> 16) ^ name) * 0x45d9f3b;
    name = (name >> 16) ^ name;
    return name;
}

/**
 * Resize the locals list to be twice its current size. If the next capacity is
 * above the threshold for switching to a hash, then we'll switch to a hash.
 */
static void
pm_locals_resize(pm_locals_t *locals) {
    uint32_t next_capacity = locals->capacity == 0 ? 4 : (locals->capacity * 2);
    assert(next_capacity > locals->capacity);

    pm_local_t *next_locals = xcalloc(next_capacity, sizeof(pm_local_t));
    if (next_locals == NULL) abort();

    if (next_capacity < PM_LOCALS_HASH_THRESHOLD) {
        if (locals->size > 0) {
            memcpy(next_locals, locals->locals, locals->size * sizeof(pm_local_t));
        }
    } else {
        // If we just switched from a list to a hash, then we need to fill in
        // the hash values of all of the locals.
        bool hash_needed = (locals->capacity <= PM_LOCALS_HASH_THRESHOLD);
        uint32_t mask = next_capacity - 1;

        for (uint32_t index = 0; index < locals->capacity; index++) {
            pm_local_t *local = &locals->locals[index];

            if (local->name != PM_CONSTANT_ID_UNSET) {
                if (hash_needed) local->hash = pm_locals_hash(local->name);

                uint32_t hash = local->hash;
                while (next_locals[hash & mask].name != PM_CONSTANT_ID_UNSET) hash++;
                next_locals[hash & mask] = *local;
            }
        }
    }

    pm_locals_free(locals);
    locals->locals = next_locals;
    locals->capacity = next_capacity;
}

/**
 * Add a new local to the set of locals. This will automatically rehash the
 * locals if the size is greater than 3/4 of the capacity.
 *
 * @param locals The set of locals to add to.
 * @param name The name of the local.
 * @param start The source location that represents the start of the local. This
 *   is used for the location of the warning in case this local is not read.
 * @param end The source location that represents the end of the local. This is
 *   used for the location of the warning in case this local is not read.
 * @param reads The initial number of reads for this local. Usually this is set
 *   to 0, but for some locals (like parameters) we want to initialize it with
 *   1 so that we never warn on unused parameters.
 * @return True if the local was added, and false if the local already exists.
 */
static bool
pm_locals_write(pm_locals_t *locals, pm_constant_id_t name, const uint8_t *start, const uint8_t *end, uint32_t reads) {
    if (locals->size >= (locals->capacity / 4 * 3)) {
        pm_locals_resize(locals);
    }

    if (locals->capacity < PM_LOCALS_HASH_THRESHOLD) {
        for (uint32_t index = 0; index < locals->capacity; index++) {
            pm_local_t *local = &locals->locals[index];

            if (local->name == PM_CONSTANT_ID_UNSET) {
                *local = (pm_local_t) {
                    .name = name,
                    .location = { .start = start, .end = end },
                    .index = locals->size++,
                    .reads = reads,
                    .hash = 0
                };
                return true;
            } else if (local->name == name) {
                return false;
            }
        }
    } else {
        uint32_t mask = locals->capacity - 1;
        uint32_t hash = pm_locals_hash(name);
        uint32_t initial_hash = hash;

        do {
            pm_local_t *local = &locals->locals[hash & mask];

            if (local->name == PM_CONSTANT_ID_UNSET) {
                *local = (pm_local_t) {
                    .name = name,
                    .location = { .start = start, .end = end },
                    .index = locals->size++,
                    .reads = reads,
                    .hash = initial_hash
                };
                return true;
            } else if (local->name == name) {
                return false;
            } else {
                hash++;
            }
        } while ((hash & mask) != initial_hash);
    }

    assert(false && "unreachable");
    return true;
}

/**
 * Finds the index of a local variable in the locals set. If it is not found,
 * this returns UINT32_MAX.
 */
static uint32_t
pm_locals_find(pm_locals_t *locals, pm_constant_id_t name) {
    if (locals->capacity < PM_LOCALS_HASH_THRESHOLD) {
        for (uint32_t index = 0; index < locals->size; index++) {
            pm_local_t *local = &locals->locals[index];
            if (local->name == name) return index;
        }
    } else {
        uint32_t mask = locals->capacity - 1;
        uint32_t hash = pm_locals_hash(name);
        uint32_t initial_hash = hash & mask;

        do {
            pm_local_t *local = &locals->locals[hash & mask];

            if (local->name == PM_CONSTANT_ID_UNSET) {
                return UINT32_MAX;
            } else if (local->name == name) {
                return hash & mask;
            } else {
                hash++;
            }
        } while ((hash & mask) != initial_hash);
    }

    return UINT32_MAX;
}

/**
 * Called when a variable is read in a certain lexical context. Tracks the read
 * by adding to the reads count.
 */
static void
pm_locals_read(pm_locals_t *locals, pm_constant_id_t name) {
    uint32_t index = pm_locals_find(locals, name);
    assert(index != UINT32_MAX);

    pm_local_t *local = &locals->locals[index];
    assert(local->reads < UINT32_MAX);

    local->reads++;
}

/**
 * Called when a variable read is transformed into a variable write, because a
 * write operator is found after the variable name.
 */
static void
pm_locals_unread(pm_locals_t *locals, pm_constant_id_t name) {
    uint32_t index = pm_locals_find(locals, name);
    assert(index != UINT32_MAX);

    pm_local_t *local = &locals->locals[index];
    assert(local->reads > 0);

    local->reads--;
}

/**
 * Returns the current number of reads for a local variable.
 */
static uint32_t
pm_locals_reads(pm_locals_t *locals, pm_constant_id_t name) {
    uint32_t index = pm_locals_find(locals, name);
    assert(index != UINT32_MAX);

    return locals->locals[index].reads;
}

/**
 * Write out the locals into the given list of constant ids in the correct
 * order. This is used to set the list of locals on the nodes in the tree once
 * we're sure no additional locals will be added to the set.
 *
 * This function is also responsible for warning when a local variable has been
 * written but not read in certain contexts.
 */
static void
pm_locals_order(PRISM_ATTRIBUTE_UNUSED pm_parser_t *parser, pm_locals_t *locals, pm_constant_id_list_t *list, bool toplevel) {
    pm_constant_id_list_init_capacity(list, locals->size);

    // If we're still below the threshold for switching to a hash, then we only
    // need to loop over the locals until we hit the size because the locals are
    // stored in a list.
    uint32_t capacity = locals->capacity < PM_LOCALS_HASH_THRESHOLD ? locals->size : locals->capacity;

    // We will only warn for unused variables if we're not at the top level, or
    // if we're parsing a file outside of eval or -e.
    bool warn_unused = !toplevel || (!parser->parsing_eval && !PM_PARSER_COMMAND_LINE_OPTION_E(parser));

    for (uint32_t index = 0; index < capacity; index++) {
        pm_local_t *local = &locals->locals[index];

        if (local->name != PM_CONSTANT_ID_UNSET) {
            pm_constant_id_list_insert(list, (size_t) local->index, local->name);

            if (warn_unused && local->reads == 0 && ((parser->start_line >= 0) || (pm_newline_list_line(&parser->newline_list, local->location.start, parser->start_line) >= 0))) {
                pm_constant_t *constant = pm_constant_pool_id_to_constant(&parser->constant_pool, local->name);

                if (constant->length >= 1 && *constant->start != '_') {
                    PM_PARSER_WARN_FORMAT(
                        parser,
                        local->location.start,
                        local->location.end,
                        PM_WARN_UNUSED_LOCAL_VARIABLE,
                        (int) constant->length,
                        (const char *) constant->start
                    );
                }
            }
        }
    }
}

/******************************************************************************/
/* Node-related functions                                                     */
/******************************************************************************/

/**
 * Retrieve the constant pool id for the given location.
 */
static inline pm_constant_id_t
pm_parser_constant_id_location(pm_parser_t *parser, const uint8_t *start, const uint8_t *end) {
    return pm_constant_pool_insert_shared(&parser->constant_pool, start, (size_t) (end - start));
}

/**
 * Retrieve the constant pool id for the given string.
 */
static inline pm_constant_id_t
pm_parser_constant_id_owned(pm_parser_t *parser, uint8_t *start, size_t length) {
    return pm_constant_pool_insert_owned(&parser->constant_pool, start, length);
}

/**
 * Retrieve the constant pool id for the given static literal C string.
 */
static inline pm_constant_id_t
pm_parser_constant_id_constant(pm_parser_t *parser, const char *start, size_t length) {
    return pm_constant_pool_insert_constant(&parser->constant_pool, (const uint8_t *) start, length);
}

/**
 * Retrieve the constant pool id for the given token.
 */
static inline pm_constant_id_t
pm_parser_constant_id_token(pm_parser_t *parser, const pm_token_t *token) {
    return pm_parser_constant_id_location(parser, token->start, token->end);
}

/**
 * Retrieve the constant pool id for the given token. If the token is not
 * provided, then return 0.
 */
static inline pm_constant_id_t
pm_parser_optional_constant_id_token(pm_parser_t *parser, const pm_token_t *token) {
    return token->type == PM_TOKEN_NOT_PROVIDED ? 0 : pm_parser_constant_id_token(parser, token);
}

/**
 * Check whether or not the given node is value expression.
 * If the node is value node, it returns NULL.
 * If not, it returns the pointer to the node to be inspected as "void expression".
 */
static pm_node_t *
pm_check_value_expression(pm_parser_t *parser, pm_node_t *node) {
    pm_node_t *void_node = NULL;

    while (node != NULL) {
        switch (PM_NODE_TYPE(node)) {
            case PM_RETURN_NODE:
            case PM_BREAK_NODE:
            case PM_NEXT_NODE:
            case PM_REDO_NODE:
            case PM_RETRY_NODE:
            case PM_MATCH_REQUIRED_NODE:
                return void_node != NULL ? void_node : node;
            case PM_MATCH_PREDICATE_NODE:
                return NULL;
            case PM_BEGIN_NODE: {
                pm_begin_node_t *cast = (pm_begin_node_t *) node;

                if (cast->ensure_clause != NULL) {
                    if (cast->rescue_clause != NULL) {
                        pm_node_t *vn = pm_check_value_expression(parser, (pm_node_t *) cast->rescue_clause);
                        if (vn != NULL) return vn;
                    }

                    if (cast->statements != NULL) {
                        pm_node_t *vn = pm_check_value_expression(parser, (pm_node_t *) cast->statements);
                        if (vn != NULL) return vn;
                    }

                    node = (pm_node_t *) cast->ensure_clause;
                } else if (cast->rescue_clause != NULL) {
                    if (cast->statements == NULL) return NULL;

                    pm_node_t *vn = pm_check_value_expression(parser, (pm_node_t *) cast->statements);
                    if (vn == NULL) return NULL;
                    if (void_node == NULL) void_node = vn;

                    for (pm_rescue_node_t *rescue_clause = cast->rescue_clause; rescue_clause != NULL; rescue_clause = rescue_clause->subsequent) {
                        pm_node_t *vn = pm_check_value_expression(parser, (pm_node_t *) rescue_clause->statements);
                        if (vn == NULL) {
                            void_node = NULL;
                            break;
                        }
                        if (void_node == NULL) {
                            void_node = vn;
                        }
                    }

                    if (cast->else_clause != NULL) {
                        node = (pm_node_t *) cast->else_clause;
                    } else {
                        return void_node;
                    }
                } else {
                    node = (pm_node_t *) cast->statements;
                }

                break;
            }
            case PM_ENSURE_NODE: {
                pm_ensure_node_t *cast = (pm_ensure_node_t *) node;
                node = (pm_node_t *) cast->statements;
                break;
            }
            case PM_PARENTHESES_NODE: {
                pm_parentheses_node_t *cast = (pm_parentheses_node_t *) node;
                node = (pm_node_t *) cast->body;
                break;
            }
            case PM_STATEMENTS_NODE: {
                pm_statements_node_t *cast = (pm_statements_node_t *) node;
                node = cast->body.nodes[cast->body.size - 1];
                break;
            }
            case PM_IF_NODE: {
                pm_if_node_t *cast = (pm_if_node_t *) node;
                if (cast->statements == NULL || cast->subsequent == NULL) {
                    return NULL;
                }
                pm_node_t *vn = pm_check_value_expression(parser, (pm_node_t *) cast->statements);
                if (vn == NULL) {
                    return NULL;
                }
                if (void_node == NULL) {
                    void_node = vn;
                }
                node = cast->subsequent;
                break;
            }
            case PM_UNLESS_NODE: {
                pm_unless_node_t *cast = (pm_unless_node_t *) node;
                if (cast->statements == NULL || cast->else_clause == NULL) {
                    return NULL;
                }
                pm_node_t *vn = pm_check_value_expression(parser, (pm_node_t *) cast->statements);
                if (vn == NULL) {
                    return NULL;
                }
                if (void_node == NULL) {
                    void_node = vn;
                }
                node = (pm_node_t *) cast->else_clause;
                break;
            }
            case PM_ELSE_NODE: {
                pm_else_node_t *cast = (pm_else_node_t *) node;
                node = (pm_node_t *) cast->statements;
                break;
            }
            case PM_AND_NODE: {
                pm_and_node_t *cast = (pm_and_node_t *) node;
                node = cast->left;
                break;
            }
            case PM_OR_NODE: {
                pm_or_node_t *cast = (pm_or_node_t *) node;
                node = cast->left;
                break;
            }
            case PM_LOCAL_VARIABLE_WRITE_NODE: {
                pm_local_variable_write_node_t *cast = (pm_local_variable_write_node_t *) node;

                pm_scope_t *scope = parser->current_scope;
                for (uint32_t depth = 0; depth < cast->depth; depth++) scope = scope->previous;

                pm_locals_read(&scope->locals, cast->name);
                return NULL;
            }
            default:
                return NULL;
        }
    }

    return NULL;
}

static inline void
pm_assert_value_expression(pm_parser_t *parser, pm_node_t *node) {
    pm_node_t *void_node = pm_check_value_expression(parser, node);
    if (void_node != NULL) {
        pm_parser_err_node(parser, void_node, PM_ERR_VOID_EXPRESSION);
    }
}

/**
 * Warn if the given node is a "void" statement.
 */
static void
pm_void_statement_check(pm_parser_t *parser, const pm_node_t *node) {
    const char *type = NULL;
    int length = 0;

    switch (PM_NODE_TYPE(node)) {
        case PM_BACK_REFERENCE_READ_NODE:
        case PM_CLASS_VARIABLE_READ_NODE:
        case PM_GLOBAL_VARIABLE_READ_NODE:
        case PM_INSTANCE_VARIABLE_READ_NODE:
        case PM_LOCAL_VARIABLE_READ_NODE:
        case PM_NUMBERED_REFERENCE_READ_NODE:
            type = "a variable";
            length = 10;
            break;
        case PM_CALL_NODE: {
            const pm_call_node_t *cast = (const pm_call_node_t *) node;
            if (cast->call_operator_loc.start != NULL || cast->message_loc.start == NULL) break;

            const pm_constant_t *message = pm_constant_pool_id_to_constant(&parser->constant_pool, cast->name);
            switch (message->length) {
                case 1:
                    switch (message->start[0]) {
                        case '+':
                        case '-':
                        case '*':
                        case '/':
                        case '%':
                        case '|':
                        case '^':
                        case '&':
                        case '>':
                        case '<':
                            type = (const char *) message->start;
                            length = 1;
                            break;
                    }
                    break;
                case 2:
                    switch (message->start[1]) {
                        case '=':
                            if (message->start[0] == '<' || message->start[0] == '>' || message->start[0] == '!' || message->start[0] == '=') {
                                type = (const char *) message->start;
                                length = 2;
                            }
                            break;
                        case '@':
                            if (message->start[0] == '+' || message->start[0] == '-') {
                                type = (const char *) message->start;
                                length = 2;
                            }
                            break;
                        case '*':
                            if (message->start[0] == '*') {
                                type = (const char *) message->start;
                                length = 2;
                            }
                            break;
                    }
                    break;
                case 3:
                    if (memcmp(message->start, "<=>", 3) == 0) {
                        type = "<=>";
                        length = 3;
                    }
                    break;
            }

            break;
        }
        case PM_CONSTANT_PATH_NODE:
            type = "::";
            length = 2;
            break;
        case PM_CONSTANT_READ_NODE:
            type = "a constant";
            length = 10;
            break;
        case PM_DEFINED_NODE:
            type = "defined?";
            length = 8;
            break;
        case PM_FALSE_NODE:
            type = "false";
            length = 5;
            break;
        case PM_FLOAT_NODE:
        case PM_IMAGINARY_NODE:
        case PM_INTEGER_NODE:
        case PM_INTERPOLATED_REGULAR_EXPRESSION_NODE:
        case PM_INTERPOLATED_STRING_NODE:
        case PM_RATIONAL_NODE:
        case PM_REGULAR_EXPRESSION_NODE:
        case PM_SOURCE_ENCODING_NODE:
        case PM_SOURCE_FILE_NODE:
        case PM_SOURCE_LINE_NODE:
        case PM_STRING_NODE:
        case PM_SYMBOL_NODE:
            type = "a literal";
            length = 9;
            break;
        case PM_NIL_NODE:
            type = "nil";
            length = 3;
            break;
        case PM_RANGE_NODE: {
            const pm_range_node_t *cast = (const pm_range_node_t *) node;

            if (PM_NODE_FLAG_P(cast, PM_RANGE_FLAGS_EXCLUDE_END)) {
                type = "...";
                length = 3;
            } else {
                type = "..";
                length = 2;
            }

            break;
        }
        case PM_SELF_NODE:
            type = "self";
            length = 4;
            break;
        case PM_TRUE_NODE:
            type = "true";
            length = 4;
            break;
        default:
            break;
    }

    if (type != NULL) {
        PM_PARSER_WARN_NODE_FORMAT(parser, node, PM_WARN_VOID_STATEMENT, length, type);
    }
}

/**
 * Warn if any of the statements that are not the last statement in the list are
 * a "void" statement.
 */
static void
pm_void_statements_check(pm_parser_t *parser, const pm_statements_node_t *node, bool last_value) {
    assert(node->body.size > 0);
    const size_t size = node->body.size - (last_value ? 1 : 0);
    for (size_t index = 0; index < size; index++) {
        pm_void_statement_check(parser, node->body.nodes[index]);
    }
}

/**
 * When we're handling the predicate of a conditional, we need to know our
 * context in order to determine the kind of warning we should deliver to the
 * user.
 */
typedef enum {
    PM_CONDITIONAL_PREDICATE_TYPE_CONDITIONAL,
    PM_CONDITIONAL_PREDICATE_TYPE_FLIP_FLOP,
    PM_CONDITIONAL_PREDICATE_TYPE_NOT
} pm_conditional_predicate_type_t;

/**
 * Add a warning to the parser if the predicate of a conditional is a literal.
 */
static void
pm_parser_warn_conditional_predicate_literal(pm_parser_t *parser, pm_node_t *node, pm_conditional_predicate_type_t type, pm_diagnostic_id_t diag_id, const char *prefix) {
    switch (type) {
        case PM_CONDITIONAL_PREDICATE_TYPE_CONDITIONAL:
            PM_PARSER_WARN_NODE_FORMAT(parser, node, diag_id, prefix, "condition");
            break;
        case PM_CONDITIONAL_PREDICATE_TYPE_FLIP_FLOP:
            PM_PARSER_WARN_NODE_FORMAT(parser, node, diag_id, prefix, "flip-flop");
            break;
        case PM_CONDITIONAL_PREDICATE_TYPE_NOT:
            break;
    }
}

/**
 * Return true if the value being written within the predicate of a conditional
 * is a literal value.
 */
static bool
pm_conditional_predicate_warn_write_literal_p(const pm_node_t *node) {
    switch (PM_NODE_TYPE(node)) {
        case PM_ARRAY_NODE: {
            if (PM_NODE_FLAG_P(node, PM_NODE_FLAG_STATIC_LITERAL)) return true;

            const pm_array_node_t *cast = (const pm_array_node_t *) node;
            for (size_t index = 0; index < cast->elements.size; index++) {
                if (!pm_conditional_predicate_warn_write_literal_p(cast->elements.nodes[index])) return false;
            }

            return true;
        }
        case PM_HASH_NODE: {
            if (PM_NODE_FLAG_P(node, PM_NODE_FLAG_STATIC_LITERAL)) return true;

            const pm_hash_node_t *cast = (const pm_hash_node_t *) node;
            for (size_t index = 0; index < cast->elements.size; index++) {
                const pm_node_t *element = cast->elements.nodes[index];
                if (!PM_NODE_TYPE_P(element, PM_ASSOC_NODE)) return false;

                const pm_assoc_node_t *assoc = (const pm_assoc_node_t *) element;
                if (!pm_conditional_predicate_warn_write_literal_p(assoc->key) || !pm_conditional_predicate_warn_write_literal_p(assoc->value)) return false;
            }

            return true;
        }
        case PM_FALSE_NODE:
        case PM_FLOAT_NODE:
        case PM_IMAGINARY_NODE:
        case PM_INTEGER_NODE:
        case PM_NIL_NODE:
        case PM_RATIONAL_NODE:
        case PM_REGULAR_EXPRESSION_NODE:
        case PM_SOURCE_ENCODING_NODE:
        case PM_SOURCE_FILE_NODE:
        case PM_SOURCE_LINE_NODE:
        case PM_STRING_NODE:
        case PM_SYMBOL_NODE:
        case PM_TRUE_NODE:
            return true;
        default:
            return false;
    }
}

/**
 * Add a warning to the parser if the value that is being written inside of a
 * predicate to a conditional is a literal.
 */
static inline void
pm_conditional_predicate_warn_write_literal(pm_parser_t *parser, const pm_node_t *node) {
    if (pm_conditional_predicate_warn_write_literal_p(node)) {
        pm_parser_warn_node(parser, node, parser->version == PM_OPTIONS_VERSION_CRUBY_3_3 ? PM_WARN_EQUAL_IN_CONDITIONAL_3_3 : PM_WARN_EQUAL_IN_CONDITIONAL);
    }
}

/**
 * The predicate of conditional nodes can change what would otherwise be regular
 * nodes into specialized nodes. For example:
 *
 * if foo .. bar         => RangeNode becomes FlipFlopNode
 * if foo and bar .. baz => RangeNode becomes FlipFlopNode
 * if /foo/              => RegularExpressionNode becomes MatchLastLineNode
 * if /foo #{bar}/       => InterpolatedRegularExpressionNode becomes InterpolatedMatchLastLineNode
 *
 * We also want to warn the user if they're using a static literal as a
 * predicate or writing a static literal as the predicate.
 */
static void
pm_conditional_predicate(pm_parser_t *parser, pm_node_t *node, pm_conditional_predicate_type_t type) {
    switch (PM_NODE_TYPE(node)) {
        case PM_AND_NODE: {
            pm_and_node_t *cast = (pm_and_node_t *) node;
            pm_conditional_predicate(parser, cast->left, PM_CONDITIONAL_PREDICATE_TYPE_CONDITIONAL);
            pm_conditional_predicate(parser, cast->right, PM_CONDITIONAL_PREDICATE_TYPE_CONDITIONAL);
            break;
        }
        case PM_OR_NODE: {
            pm_or_node_t *cast = (pm_or_node_t *) node;
            pm_conditional_predicate(parser, cast->left, PM_CONDITIONAL_PREDICATE_TYPE_CONDITIONAL);
            pm_conditional_predicate(parser, cast->right, PM_CONDITIONAL_PREDICATE_TYPE_CONDITIONAL);
            break;
        }
        case PM_PARENTHESES_NODE: {
            pm_parentheses_node_t *cast = (pm_parentheses_node_t *) node;

            if ((cast->body != NULL) && PM_NODE_TYPE_P(cast->body, PM_STATEMENTS_NODE)) {
                pm_statements_node_t *statements = (pm_statements_node_t *) cast->body;
                if (statements->body.size == 1) pm_conditional_predicate(parser, statements->body.nodes[0], type);
            }

            break;
        }
        case PM_BEGIN_NODE: {
            pm_begin_node_t *cast = (pm_begin_node_t *) node;
            if (cast->statements != NULL) {
                pm_statements_node_t *statements = cast->statements;
                if (statements->body.size == 1) pm_conditional_predicate(parser, statements->body.nodes[0], type);
            }
            break;
        }
        case PM_RANGE_NODE: {
            pm_range_node_t *cast = (pm_range_node_t *) node;

            if (cast->left != NULL) pm_conditional_predicate(parser, cast->left, PM_CONDITIONAL_PREDICATE_TYPE_FLIP_FLOP);
            if (cast->right != NULL) pm_conditional_predicate(parser, cast->right, PM_CONDITIONAL_PREDICATE_TYPE_FLIP_FLOP);

            // Here we change the range node into a flip flop node. We can do
            // this since the nodes are exactly the same except for the type.
            // We're only asserting against the size when we should probably
            // assert against the entire layout, but we'll assume tests will
            // catch this.
            assert(sizeof(pm_range_node_t) == sizeof(pm_flip_flop_node_t));
            node->type = PM_FLIP_FLOP_NODE;

            break;
        }
        case PM_REGULAR_EXPRESSION_NODE:
            // Here we change the regular expression node into a match last line
            // node. We can do this since the nodes are exactly the same except
            // for the type.
            assert(sizeof(pm_regular_expression_node_t) == sizeof(pm_match_last_line_node_t));
            node->type = PM_MATCH_LAST_LINE_NODE;

            if (!PM_PARSER_COMMAND_LINE_OPTION_E(parser)) {
                pm_parser_warn_conditional_predicate_literal(parser, node, type, PM_WARN_LITERAL_IN_CONDITION_DEFAULT, "regex ");
            }

            break;
        case PM_INTERPOLATED_REGULAR_EXPRESSION_NODE:
            // Here we change the interpolated regular expression node into an
            // interpolated match last line node. We can do this since the nodes
            // are exactly the same except for the type.
            assert(sizeof(pm_interpolated_regular_expression_node_t) == sizeof(pm_interpolated_match_last_line_node_t));
            node->type = PM_INTERPOLATED_MATCH_LAST_LINE_NODE;

            if (!PM_PARSER_COMMAND_LINE_OPTION_E(parser)) {
                pm_parser_warn_conditional_predicate_literal(parser, node, type, PM_WARN_LITERAL_IN_CONDITION_VERBOSE, "regex ");
            }

            break;
        case PM_INTEGER_NODE:
            if (type == PM_CONDITIONAL_PREDICATE_TYPE_FLIP_FLOP) {
                if (!PM_PARSER_COMMAND_LINE_OPTION_E(parser)) {
                    pm_parser_warn_node(parser, node, PM_WARN_INTEGER_IN_FLIP_FLOP);
                }
            } else {
                pm_parser_warn_conditional_predicate_literal(parser, node, type, PM_WARN_LITERAL_IN_CONDITION_VERBOSE, "");
            }
            break;
        case PM_STRING_NODE:
        case PM_SOURCE_FILE_NODE:
        case PM_INTERPOLATED_STRING_NODE:
            pm_parser_warn_conditional_predicate_literal(parser, node, type, PM_WARN_LITERAL_IN_CONDITION_DEFAULT, "string ");
            break;
        case PM_SYMBOL_NODE:
        case PM_INTERPOLATED_SYMBOL_NODE:
            pm_parser_warn_conditional_predicate_literal(parser, node, type, PM_WARN_LITERAL_IN_CONDITION_VERBOSE, "symbol ");
            break;
        case PM_SOURCE_LINE_NODE:
        case PM_SOURCE_ENCODING_NODE:
        case PM_FLOAT_NODE:
        case PM_RATIONAL_NODE:
        case PM_IMAGINARY_NODE:
            pm_parser_warn_conditional_predicate_literal(parser, node, type, PM_WARN_LITERAL_IN_CONDITION_VERBOSE, "");
            break;
        case PM_CLASS_VARIABLE_WRITE_NODE:
            pm_conditional_predicate_warn_write_literal(parser, ((pm_class_variable_write_node_t *) node)->value);
            break;
        case PM_CONSTANT_WRITE_NODE:
            pm_conditional_predicate_warn_write_literal(parser, ((pm_constant_write_node_t *) node)->value);
            break;
        case PM_GLOBAL_VARIABLE_WRITE_NODE:
            pm_conditional_predicate_warn_write_literal(parser, ((pm_global_variable_write_node_t *) node)->value);
            break;
        case PM_INSTANCE_VARIABLE_WRITE_NODE:
            pm_conditional_predicate_warn_write_literal(parser, ((pm_instance_variable_write_node_t *) node)->value);
            break;
        case PM_LOCAL_VARIABLE_WRITE_NODE:
            pm_conditional_predicate_warn_write_literal(parser, ((pm_local_variable_write_node_t *) node)->value);
            break;
        case PM_MULTI_WRITE_NODE:
            pm_conditional_predicate_warn_write_literal(parser, ((pm_multi_write_node_t *) node)->value);
            break;
        default:
            break;
    }
}

/**
 * In a lot of places in the tree you can have tokens that are not provided but
 * that do not cause an error. For example, this happens in a method call
 * without parentheses. In these cases we set the token to the "not provided" type.
 * For example:
 *
 *     pm_token_t token = not_provided(parser);
 */
static inline pm_token_t
not_provided(pm_parser_t *parser) {
    return (pm_token_t) { .type = PM_TOKEN_NOT_PROVIDED, .start = parser->start, .end = parser->start };
}

#define PM_LOCATION_NULL_VALUE(parser) ((pm_location_t) { .start = (parser)->start, .end = (parser)->start })
#define PM_LOCATION_TOKEN_VALUE(token) ((pm_location_t) { .start = (token)->start, .end = (token)->end })
#define PM_LOCATION_NODE_VALUE(node) ((pm_location_t) { .start = (node)->location.start, .end = (node)->location.end })
#define PM_LOCATION_NODE_BASE_VALUE(node) ((pm_location_t) { .start = (node)->base.location.start, .end = (node)->base.location.end })
#define PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE ((pm_location_t) { .start = NULL, .end = NULL })
#define PM_OPTIONAL_LOCATION_TOKEN_VALUE(token) ((token)->type == PM_TOKEN_NOT_PROVIDED ? PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE : PM_LOCATION_TOKEN_VALUE(token))

/**
 * This is a special out parameter to the parse_arguments_list function that
 * includes opening and closing parentheses in addition to the arguments since
 * it's so common. It is handy to use when passing argument information to one
 * of the call node creation functions.
 */
typedef struct {
    /** The optional location of the opening parenthesis or bracket. */
    pm_location_t opening_loc;

    /** The lazily-allocated optional arguments node. */
    pm_arguments_node_t *arguments;

    /** The optional location of the closing parenthesis or bracket. */
    pm_location_t closing_loc;

    /** The optional block attached to the call. */
    pm_node_t *block;

    /** The flag indicating whether this arguments list has forwarding argument. */
    bool has_forwarding;
} pm_arguments_t;

/**
 * Retrieve the end location of a `pm_arguments_t` object.
 */
static inline const uint8_t *
pm_arguments_end(pm_arguments_t *arguments) {
    if (arguments->block != NULL) {
        const uint8_t *end = arguments->block->location.end;
        if (arguments->closing_loc.start != NULL && arguments->closing_loc.end > end) {
            end = arguments->closing_loc.end;
        }
        return end;
    }
    if (arguments->closing_loc.start != NULL) {
        return arguments->closing_loc.end;
    }
    if (arguments->arguments != NULL) {
        return arguments->arguments->base.location.end;
    }
    return arguments->closing_loc.end;
}

/**
 * Check that we're not about to attempt to attach a brace block to a call that
 * has arguments without parentheses.
 */
static void
pm_arguments_validate_block(pm_parser_t *parser, pm_arguments_t *arguments, pm_block_node_t *block) {
    // First, check that we have arguments and that we don't have a closing
    // location for them.
    if (arguments->arguments == NULL || arguments->closing_loc.start != NULL) {
        return;
    }

    // Next, check that we don't have a single parentheses argument. This would
    // look like:
    //
    //     foo (1) {}
    //
    // In this case, it's actually okay for the block to be attached to the
    // call, even though it looks like it's attached to the argument.
    if (arguments->arguments->arguments.size == 1 && PM_NODE_TYPE_P(arguments->arguments->arguments.nodes[0], PM_PARENTHESES_NODE)) {
        return;
    }

    // If we didn't hit a case before this check, then at this point we need to
    // add a syntax error.
    pm_parser_err_node(parser, (pm_node_t *) block, PM_ERR_ARGUMENT_UNEXPECTED_BLOCK);
}

/******************************************************************************/
/* Basic character checks                                                     */
/******************************************************************************/

/**
 * This function is used extremely frequently to lex all of the identifiers in a
 * source file, so it's important that it be as fast as possible. For this
 * reason we have the encoding_changed boolean to check if we need to go through
 * the function pointer or can just directly use the UTF-8 functions.
 */
static inline size_t
char_is_identifier_start(const pm_parser_t *parser, const uint8_t *b, ptrdiff_t n) {
    if (n <= 0) return 0;

    if (parser->encoding_changed) {
        size_t width;

        if ((width = parser->encoding->alpha_char(b, n)) != 0) {
            return width;
        } else if (*b == '_') {
            return 1;
        } else if (*b >= 0x80) {
            return parser->encoding->char_width(b, n);
        } else {
            return 0;
        }
    } else if (*b < 0x80) {
        return (pm_encoding_unicode_table[*b] & PRISM_ENCODING_ALPHABETIC_BIT ? 1 : 0) || (*b == '_');
    } else {
        return pm_encoding_utf_8_char_width(b, n);
    }
}

/**
 * Similar to char_is_identifier but this function assumes that the encoding
 * has not been changed.
 */
static inline size_t
char_is_identifier_utf8(const uint8_t *b, ptrdiff_t n) {
    if (n <= 0) {
        return 0;
    } else if (*b < 0x80) {
        return (*b == '_') || (pm_encoding_unicode_table[*b] & PRISM_ENCODING_ALPHANUMERIC_BIT ? 1 : 0);
    } else {
        return pm_encoding_utf_8_char_width(b, n);
    }
}

/**
 * Like the above, this function is also used extremely frequently to lex all of
 * the identifiers in a source file once the first character has been found. So
 * it's important that it be as fast as possible.
 */
static inline size_t
char_is_identifier(const pm_parser_t *parser, const uint8_t *b, ptrdiff_t n) {
    if (n <= 0) {
        return 0;
    } else if (parser->encoding_changed) {
        size_t width;

        if ((width = parser->encoding->alnum_char(b, n)) != 0) {
            return width;
        } else if (*b == '_') {
            return 1;
        } else if (*b >= 0x80) {
            return parser->encoding->char_width(b, n);
        } else {
            return 0;
        }
    } else {
        return char_is_identifier_utf8(b, n);
    }
}

// Here we're defining a perfect hash for the characters that are allowed in
// global names. This is used to quickly check the next character after a $ to
// see if it's a valid character for a global name.
#define BIT(c, idx) (((c) / 32 - 1 == idx) ? (1U << ((c) % 32)) : 0)
#define PUNCT(idx) ( \
                BIT('~', idx) | BIT('*', idx) | BIT('$', idx) | BIT('?', idx) | \
                BIT('!', idx) | BIT('@', idx) | BIT('/', idx) | BIT('\\', idx) | \
                BIT(';', idx) | BIT(',', idx) | BIT('.', idx) | BIT('=', idx) | \
                BIT(':', idx) | BIT('<', idx) | BIT('>', idx) | BIT('\"', idx) | \
                BIT('&', idx) | BIT('`', idx) | BIT('\'', idx) | BIT('+', idx) | \
                BIT('0', idx))

const unsigned int pm_global_name_punctuation_hash[(0x7e - 0x20 + 31) / 32] = { PUNCT(0), PUNCT(1), PUNCT(2) };

#undef BIT
#undef PUNCT

static inline bool
char_is_global_name_punctuation(const uint8_t b) {
    const unsigned int i = (const unsigned int) b;
    if (i <= 0x20 || 0x7e < i) return false;

    return (pm_global_name_punctuation_hash[(i - 0x20) / 32] >> (i % 32)) & 1;
}

static inline bool
token_is_setter_name(pm_token_t *token) {
    return (
        (token->type == PM_TOKEN_BRACKET_LEFT_RIGHT_EQUAL) ||
        ((token->type == PM_TOKEN_IDENTIFIER) &&
        (token->end - token->start >= 2) &&
        (token->end[-1] == '='))
    );
}

/**
 * Returns true if the given local variable is a keyword.
 */
static bool
pm_local_is_keyword(const char *source, size_t length) {
#define KEYWORD(name) if (memcmp(source, name, length) == 0) return true

    switch (length) {
        case 2:
            switch (source[0]) {
                case 'd': KEYWORD("do"); return false;
                case 'i': KEYWORD("if"); KEYWORD("in"); return false;
                case 'o': KEYWORD("or"); return false;
                default: return false;
            }
        case 3:
            switch (source[0]) {
                case 'a': KEYWORD("and"); return false;
                case 'd': KEYWORD("def"); return false;
                case 'e': KEYWORD("end"); return false;
                case 'f': KEYWORD("for"); return false;
                case 'n': KEYWORD("nil"); KEYWORD("not"); return false;
                default: return false;
            }
        case 4:
            switch (source[0]) {
                case 'c': KEYWORD("case"); return false;
                case 'e': KEYWORD("else"); return false;
                case 'n': KEYWORD("next"); return false;
                case 'r': KEYWORD("redo"); return false;
                case 's': KEYWORD("self"); return false;
                case 't': KEYWORD("then");  KEYWORD("true"); return false;
                case 'w': KEYWORD("when"); return false;
                default: return false;
            }
        case 5:
            switch (source[0]) {
                case 'a': KEYWORD("alias"); return false;
                case 'b': KEYWORD("begin"); KEYWORD("break"); return false;
                case 'c': KEYWORD("class"); return false;
                case 'e': KEYWORD("elsif"); return false;
                case 'f': KEYWORD("false"); return false;
                case 'r': KEYWORD("retry"); return false;
                case 's': KEYWORD("super"); return false;
                case 'u': KEYWORD("undef"); KEYWORD("until"); return false;
                case 'w': KEYWORD("while"); return false;
                case 'y': KEYWORD("yield"); return false;
                default: return false;
            }
        case 6:
            switch (source[0]) {
                case 'e': KEYWORD("ensure"); return false;
                case 'm': KEYWORD("module"); return false;
                case 'r': KEYWORD("rescue"); KEYWORD("return"); return false;
                case 'u': KEYWORD("unless"); return false;
                default: return false;
            }
        case 8:
            KEYWORD("__LINE__");
            KEYWORD("__FILE__");
            return false;
        case 12:
            KEYWORD("__ENCODING__");
            return false;
        default:
            return false;
    }

#undef KEYWORD
}

/******************************************************************************/
/* Node flag handling functions                                               */
/******************************************************************************/

/**
 * Set the given flag on the given node.
 */
static inline void
pm_node_flag_set(pm_node_t *node, pm_node_flags_t flag) {
    node->flags |= flag;
}

/**
 * Remove the given flag from the given node.
 */
static inline void
pm_node_flag_unset(pm_node_t *node, pm_node_flags_t flag) {
    node->flags &= (pm_node_flags_t) ~flag;
}

/**
 * Set the repeated parameter flag on the given node.
 */
static inline void
pm_node_flag_set_repeated_parameter(pm_node_t *node) {
    assert(PM_NODE_TYPE(node) == PM_BLOCK_LOCAL_VARIABLE_NODE ||
            PM_NODE_TYPE(node) == PM_BLOCK_PARAMETER_NODE ||
            PM_NODE_TYPE(node) == PM_KEYWORD_REST_PARAMETER_NODE ||
            PM_NODE_TYPE(node) == PM_OPTIONAL_KEYWORD_PARAMETER_NODE ||
            PM_NODE_TYPE(node) == PM_OPTIONAL_PARAMETER_NODE ||
            PM_NODE_TYPE(node) == PM_REQUIRED_KEYWORD_PARAMETER_NODE ||
            PM_NODE_TYPE(node) == PM_REQUIRED_PARAMETER_NODE ||
            PM_NODE_TYPE(node) == PM_REST_PARAMETER_NODE);

    pm_node_flag_set(node, PM_PARAMETER_FLAGS_REPEATED_PARAMETER);
}

/******************************************************************************/
/* Node creation functions                                                    */
/******************************************************************************/

/**
 * When you have an encoding flag on a regular expression, it takes precedence
 * over all of the previously set encoding flags. So we need to mask off any
 * previously set encoding flags before setting the new one.
 */
#define PM_REGULAR_EXPRESSION_ENCODING_MASK ~(PM_REGULAR_EXPRESSION_FLAGS_EUC_JP | PM_REGULAR_EXPRESSION_FLAGS_ASCII_8BIT | PM_REGULAR_EXPRESSION_FLAGS_WINDOWS_31J | PM_REGULAR_EXPRESSION_FLAGS_UTF_8)

/**
 * Parse out the options for a regular expression.
 */
static inline pm_node_flags_t
pm_regular_expression_flags_create(pm_parser_t *parser, const pm_token_t *closing) {
    pm_node_flags_t flags = 0;

    if (closing->type == PM_TOKEN_REGEXP_END) {
        pm_buffer_t unknown_flags = { 0 };

        for (const uint8_t *flag = closing->start + 1; flag < closing->end; flag++) {
            switch (*flag) {
                case 'i': flags |= PM_REGULAR_EXPRESSION_FLAGS_IGNORE_CASE; break;
                case 'm': flags |= PM_REGULAR_EXPRESSION_FLAGS_MULTI_LINE; break;
                case 'x': flags |= PM_REGULAR_EXPRESSION_FLAGS_EXTENDED; break;
                case 'o': flags |= PM_REGULAR_EXPRESSION_FLAGS_ONCE; break;

                case 'e': flags = (pm_node_flags_t) (((pm_node_flags_t) (flags & PM_REGULAR_EXPRESSION_ENCODING_MASK)) | PM_REGULAR_EXPRESSION_FLAGS_EUC_JP); break;
                case 'n': flags = (pm_node_flags_t) (((pm_node_flags_t) (flags & PM_REGULAR_EXPRESSION_ENCODING_MASK)) | PM_REGULAR_EXPRESSION_FLAGS_ASCII_8BIT); break;
                case 's': flags = (pm_node_flags_t) (((pm_node_flags_t) (flags & PM_REGULAR_EXPRESSION_ENCODING_MASK)) | PM_REGULAR_EXPRESSION_FLAGS_WINDOWS_31J); break;
                case 'u': flags = (pm_node_flags_t) (((pm_node_flags_t) (flags & PM_REGULAR_EXPRESSION_ENCODING_MASK)) | PM_REGULAR_EXPRESSION_FLAGS_UTF_8); break;

                default: pm_buffer_append_byte(&unknown_flags, *flag);
            }
        }

        size_t unknown_flags_length = pm_buffer_length(&unknown_flags);
        if (unknown_flags_length != 0) {
            const char *word = unknown_flags_length >= 2 ? "options" : "option";
            PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->previous, PM_ERR_REGEXP_UNKNOWN_OPTIONS, word, unknown_flags_length, pm_buffer_value(&unknown_flags));
        }
        pm_buffer_free(&unknown_flags);
    }

    return flags;
}

#undef PM_REGULAR_EXPRESSION_ENCODING_MASK

static pm_statements_node_t *
pm_statements_node_create(pm_parser_t *parser);

static void
pm_statements_node_body_append(pm_parser_t *parser, pm_statements_node_t *node, pm_node_t *statement, bool newline);

static size_t
pm_statements_node_body_length(pm_statements_node_t *node);

/**
 * This function is here to allow us a place to extend in the future when we
 * implement our own arena allocation.
 */
static inline void *
pm_node_alloc(PRISM_ATTRIBUTE_UNUSED pm_parser_t *parser, size_t size) {
    void *memory = xcalloc(1, size);
    if (memory == NULL) {
        fprintf(stderr, "Failed to allocate %d bytes\n", (int) size);
        abort();
    }
    return memory;
}

#define PM_NODE_ALLOC(parser, type) (type *) pm_node_alloc(parser, sizeof(type))
#define PM_NODE_IDENTIFY(parser) (++parser->node_id)

/**
 * Allocate a new MissingNode node.
 */
static pm_missing_node_t *
pm_missing_node_create(pm_parser_t *parser, const uint8_t *start, const uint8_t *end) {
    pm_missing_node_t *node = PM_NODE_ALLOC(parser, pm_missing_node_t);

    *node = (pm_missing_node_t) {{
        .type = PM_MISSING_NODE,
        .node_id = PM_NODE_IDENTIFY(parser),
        .location = { .start = start, .end = end }
    }};

    return node;
}

/**
 * Allocate and initialize a new AliasGlobalVariableNode node.
 */
static pm_alias_global_variable_node_t *
pm_alias_global_variable_node_create(pm_parser_t *parser, const pm_token_t *keyword, pm_node_t *new_name, pm_node_t *old_name) {
    assert(keyword->type == PM_TOKEN_KEYWORD_ALIAS);
    pm_alias_global_variable_node_t *node = PM_NODE_ALLOC(parser, pm_alias_global_variable_node_t);

    *node = (pm_alias_global_variable_node_t) {
        {
            .type = PM_ALIAS_GLOBAL_VARIABLE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = keyword->start,
                .end = old_name->location.end
            },
        },
        .new_name = new_name,
        .old_name = old_name,
        .keyword_loc = PM_LOCATION_TOKEN_VALUE(keyword)
    };

    return node;
}

/**
 * Allocate and initialize a new AliasMethodNode node.
 */
static pm_alias_method_node_t *
pm_alias_method_node_create(pm_parser_t *parser, const pm_token_t *keyword, pm_node_t *new_name, pm_node_t *old_name) {
    assert(keyword->type == PM_TOKEN_KEYWORD_ALIAS);
    pm_alias_method_node_t *node = PM_NODE_ALLOC(parser, pm_alias_method_node_t);

    *node = (pm_alias_method_node_t) {
        {
            .type = PM_ALIAS_METHOD_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = keyword->start,
                .end = old_name->location.end
            },
        },
        .new_name = new_name,
        .old_name = old_name,
        .keyword_loc = PM_LOCATION_TOKEN_VALUE(keyword)
    };

    return node;
}

/**
 * Allocate a new AlternationPatternNode node.
 */
static pm_alternation_pattern_node_t *
pm_alternation_pattern_node_create(pm_parser_t *parser, pm_node_t *left, pm_node_t *right, const pm_token_t *operator) {
    pm_alternation_pattern_node_t *node = PM_NODE_ALLOC(parser, pm_alternation_pattern_node_t);

    *node = (pm_alternation_pattern_node_t) {
        {
            .type = PM_ALTERNATION_PATTERN_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = left->location.start,
                .end = right->location.end
            },
        },
        .left = left,
        .right = right,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator)
    };

    return node;
}

/**
 * Allocate and initialize a new and node.
 */
static pm_and_node_t *
pm_and_node_create(pm_parser_t *parser, pm_node_t *left, const pm_token_t *operator, pm_node_t *right) {
    pm_assert_value_expression(parser, left);

    pm_and_node_t *node = PM_NODE_ALLOC(parser, pm_and_node_t);

    *node = (pm_and_node_t) {
        {
            .type = PM_AND_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = left->location.start,
                .end = right->location.end
            },
        },
        .left = left,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .right = right
    };

    return node;
}

/**
 * Allocate an initialize a new arguments node.
 */
static pm_arguments_node_t *
pm_arguments_node_create(pm_parser_t *parser) {
    pm_arguments_node_t *node = PM_NODE_ALLOC(parser, pm_arguments_node_t);

    *node = (pm_arguments_node_t) {
        {
            .type = PM_ARGUMENTS_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_NULL_VALUE(parser)
        },
        .arguments = { 0 }
    };

    return node;
}

/**
 * Return the size of the given arguments node.
 */
static size_t
pm_arguments_node_size(pm_arguments_node_t *node) {
    return node->arguments.size;
}

/**
 * Append an argument to an arguments node.
 */
static void
pm_arguments_node_arguments_append(pm_arguments_node_t *node, pm_node_t *argument) {
    if (pm_arguments_node_size(node) == 0) {
        node->base.location.start = argument->location.start;
    }

    node->base.location.end = argument->location.end;
    pm_node_list_append(&node->arguments, argument);

    if (PM_NODE_TYPE_P(argument, PM_SPLAT_NODE)) {
        if (PM_NODE_FLAG_P(node, PM_ARGUMENTS_NODE_FLAGS_CONTAINS_SPLAT)) {
            pm_node_flag_set((pm_node_t *) node, PM_ARGUMENTS_NODE_FLAGS_CONTAINS_MULTIPLE_SPLATS);
        } else {
            pm_node_flag_set((pm_node_t *) node, PM_ARGUMENTS_NODE_FLAGS_CONTAINS_SPLAT);
        }
    }
}

/**
 * Allocate and initialize a new ArrayNode node.
 */
static pm_array_node_t *
pm_array_node_create(pm_parser_t *parser, const pm_token_t *opening) {
    pm_array_node_t *node = PM_NODE_ALLOC(parser, pm_array_node_t);

    *node = (pm_array_node_t) {
        {
            .type = PM_ARRAY_NODE,
            .flags = PM_NODE_FLAG_STATIC_LITERAL,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_TOKEN_VALUE(opening)
        },
        .opening_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(opening),
        .closing_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(opening),
        .elements = { 0 }
    };

    return node;
}

/**
 * Append an argument to an array node.
 */
static inline void
pm_array_node_elements_append(pm_array_node_t *node, pm_node_t *element) {
    if (!node->elements.size && !node->opening_loc.start) {
        node->base.location.start = element->location.start;
    }

    pm_node_list_append(&node->elements, element);
    node->base.location.end = element->location.end;

    // If the element is not a static literal, then the array is not a static
    // literal. Turn that flag off.
    if (PM_NODE_TYPE_P(element, PM_ARRAY_NODE) || PM_NODE_TYPE_P(element, PM_HASH_NODE) || PM_NODE_TYPE_P(element, PM_RANGE_NODE) || !PM_NODE_FLAG_P(element, PM_NODE_FLAG_STATIC_LITERAL)) {
        pm_node_flag_unset((pm_node_t *)node, PM_NODE_FLAG_STATIC_LITERAL);
    }

    if (PM_NODE_TYPE_P(element, PM_SPLAT_NODE)) {
        pm_node_flag_set((pm_node_t *)node, PM_ARRAY_NODE_FLAGS_CONTAINS_SPLAT);
    }
}

/**
 * Set the closing token and end location of an array node.
 */
static void
pm_array_node_close_set(pm_array_node_t *node, const pm_token_t *closing) {
    assert(closing->type == PM_TOKEN_BRACKET_RIGHT || closing->type == PM_TOKEN_STRING_END || closing->type == PM_TOKEN_MISSING || closing->type == PM_TOKEN_NOT_PROVIDED);
    node->base.location.end = closing->end;
    node->closing_loc = PM_LOCATION_TOKEN_VALUE(closing);
}

/**
 * Allocate and initialize a new array pattern node. The node list given in the
 * nodes parameter is guaranteed to have at least two nodes.
 */
static pm_array_pattern_node_t *
pm_array_pattern_node_node_list_create(pm_parser_t *parser, pm_node_list_t *nodes) {
    pm_array_pattern_node_t *node = PM_NODE_ALLOC(parser, pm_array_pattern_node_t);

    *node = (pm_array_pattern_node_t) {
        {
            .type = PM_ARRAY_PATTERN_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = nodes->nodes[0]->location.start,
                .end = nodes->nodes[nodes->size - 1]->location.end
            },
        },
        .constant = NULL,
        .rest = NULL,
        .requireds = { 0 },
        .posts = { 0 },
        .opening_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE,
        .closing_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE
    };

    // For now we're going to just copy over each pointer manually. This could be
    // much more efficient, as we could instead resize the node list.
    bool found_rest = false;
    pm_node_t *child;

    PM_NODE_LIST_FOREACH(nodes, index, child) {
        if (!found_rest && (PM_NODE_TYPE_P(child, PM_SPLAT_NODE) || PM_NODE_TYPE_P(child, PM_IMPLICIT_REST_NODE))) {
            node->rest = child;
            found_rest = true;
        } else if (found_rest) {
            pm_node_list_append(&node->posts, child);
        } else {
            pm_node_list_append(&node->requireds, child);
        }
    }

    return node;
}

/**
 * Allocate and initialize a new array pattern node from a single rest node.
 */
static pm_array_pattern_node_t *
pm_array_pattern_node_rest_create(pm_parser_t *parser, pm_node_t *rest) {
    pm_array_pattern_node_t *node = PM_NODE_ALLOC(parser, pm_array_pattern_node_t);

    *node = (pm_array_pattern_node_t) {
        {
            .type = PM_ARRAY_PATTERN_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = rest->location,
        },
        .constant = NULL,
        .rest = rest,
        .requireds = { 0 },
        .posts = { 0 },
        .opening_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE,
        .closing_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE
    };

    return node;
}

/**
 * Allocate and initialize a new array pattern node from a constant and opening
 * and closing tokens.
 */
static pm_array_pattern_node_t *
pm_array_pattern_node_constant_create(pm_parser_t *parser, pm_node_t *constant, const pm_token_t *opening, const pm_token_t *closing) {
    pm_array_pattern_node_t *node = PM_NODE_ALLOC(parser, pm_array_pattern_node_t);

    *node = (pm_array_pattern_node_t) {
        {
            .type = PM_ARRAY_PATTERN_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = constant->location.start,
                .end = closing->end
            },
        },
        .constant = constant,
        .rest = NULL,
        .opening_loc = PM_LOCATION_TOKEN_VALUE(opening),
        .closing_loc = PM_LOCATION_TOKEN_VALUE(closing),
        .requireds = { 0 },
        .posts = { 0 }
    };

    return node;
}

/**
 * Allocate and initialize a new array pattern node from an opening and closing
 * token.
 */
static pm_array_pattern_node_t *
pm_array_pattern_node_empty_create(pm_parser_t *parser, const pm_token_t *opening, const pm_token_t *closing) {
    pm_array_pattern_node_t *node = PM_NODE_ALLOC(parser, pm_array_pattern_node_t);

    *node = (pm_array_pattern_node_t) {
        {
            .type = PM_ARRAY_PATTERN_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = opening->start,
                .end = closing->end
            },
        },
        .constant = NULL,
        .rest = NULL,
        .opening_loc = PM_LOCATION_TOKEN_VALUE(opening),
        .closing_loc = PM_LOCATION_TOKEN_VALUE(closing),
        .requireds = { 0 },
        .posts = { 0 }
    };

    return node;
}

static inline void
pm_array_pattern_node_requireds_append(pm_array_pattern_node_t *node, pm_node_t *inner) {
    pm_node_list_append(&node->requireds, inner);
}

/**
 * Allocate and initialize a new assoc node.
 */
static pm_assoc_node_t *
pm_assoc_node_create(pm_parser_t *parser, pm_node_t *key, const pm_token_t *operator, pm_node_t *value) {
    pm_assoc_node_t *node = PM_NODE_ALLOC(parser, pm_assoc_node_t);
    const uint8_t *end;

    if (value != NULL && value->location.end > key->location.end) {
        end = value->location.end;
    } else if (operator->type != PM_TOKEN_NOT_PROVIDED) {
        end = operator->end;
    } else {
        end = key->location.end;
    }

    // Hash string keys will be frozen, so we can mark them as frozen here so
    // that the compiler picks them up and also when we check for static literal
    // on the keys it gets factored in.
    if (PM_NODE_TYPE_P(key, PM_STRING_NODE)) {
        key->flags |= PM_STRING_FLAGS_FROZEN | PM_NODE_FLAG_STATIC_LITERAL;
    }

    // If the key and value of this assoc node are both static literals, then
    // we can mark this node as a static literal.
    pm_node_flags_t flags = 0;
    if (
        !PM_NODE_TYPE_P(key, PM_ARRAY_NODE) && !PM_NODE_TYPE_P(key, PM_HASH_NODE) && !PM_NODE_TYPE_P(key, PM_RANGE_NODE) &&
        value && !PM_NODE_TYPE_P(value, PM_ARRAY_NODE) && !PM_NODE_TYPE_P(value, PM_HASH_NODE) && !PM_NODE_TYPE_P(value, PM_RANGE_NODE)
    ) {
        flags = key->flags & value->flags & PM_NODE_FLAG_STATIC_LITERAL;
    }

    *node = (pm_assoc_node_t) {
        {
            .type = PM_ASSOC_NODE,
            .flags = flags,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = key->location.start,
                .end = end
            },
        },
        .key = key,
        .operator_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(operator),
        .value = value
    };

    return node;
}

/**
 * Allocate and initialize a new assoc splat node.
 */
static pm_assoc_splat_node_t *
pm_assoc_splat_node_create(pm_parser_t *parser, pm_node_t *value, const pm_token_t *operator) {
    assert(operator->type == PM_TOKEN_USTAR_STAR);
    pm_assoc_splat_node_t *node = PM_NODE_ALLOC(parser, pm_assoc_splat_node_t);

    *node = (pm_assoc_splat_node_t) {
        {
            .type = PM_ASSOC_SPLAT_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = operator->start,
                .end = value == NULL ? operator->end : value->location.end
            },
        },
        .value = value,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator)
    };

    return node;
}

/**
 * Allocate a new BackReferenceReadNode node.
 */
static pm_back_reference_read_node_t *
pm_back_reference_read_node_create(pm_parser_t *parser, const pm_token_t *name) {
    assert(name->type == PM_TOKEN_BACK_REFERENCE);
    pm_back_reference_read_node_t *node = PM_NODE_ALLOC(parser, pm_back_reference_read_node_t);

    *node = (pm_back_reference_read_node_t) {
        {
            .type = PM_BACK_REFERENCE_READ_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_TOKEN_VALUE(name),
        },
        .name = pm_parser_constant_id_token(parser, name)
    };

    return node;
}

/**
 * Allocate and initialize new a begin node.
 */
static pm_begin_node_t *
pm_begin_node_create(pm_parser_t *parser, const pm_token_t *begin_keyword, pm_statements_node_t *statements) {
    pm_begin_node_t *node = PM_NODE_ALLOC(parser, pm_begin_node_t);

    *node = (pm_begin_node_t) {
        {
            .type = PM_BEGIN_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = begin_keyword->start,
                .end = statements == NULL ? begin_keyword->end : statements->base.location.end
            },
        },
        .begin_keyword_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(begin_keyword),
        .statements = statements,
        .end_keyword_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE
    };

    return node;
}

/**
 * Set the rescue clause, optionally start, and end location of a begin node.
 */
static void
pm_begin_node_rescue_clause_set(pm_begin_node_t *node, pm_rescue_node_t *rescue_clause) {
    // If the begin keyword doesn't exist, we set the start on the begin_node
    if (!node->begin_keyword_loc.start) {
        node->base.location.start = rescue_clause->base.location.start;
    }
    node->base.location.end = rescue_clause->base.location.end;
    node->rescue_clause = rescue_clause;
}

/**
 * Set the else clause and end location of a begin node.
 */
static void
pm_begin_node_else_clause_set(pm_begin_node_t *node, pm_else_node_t *else_clause) {
    node->base.location.end = else_clause->base.location.end;
    node->else_clause = else_clause;
}

/**
 * Set the ensure clause and end location of a begin node.
 */
static void
pm_begin_node_ensure_clause_set(pm_begin_node_t *node, pm_ensure_node_t *ensure_clause) {
    node->base.location.end = ensure_clause->base.location.end;
    node->ensure_clause = ensure_clause;
}

/**
 * Set the end keyword and end location of a begin node.
 */
static void
pm_begin_node_end_keyword_set(pm_begin_node_t *node, const pm_token_t *end_keyword) {
    assert(end_keyword->type == PM_TOKEN_KEYWORD_END || end_keyword->type == PM_TOKEN_MISSING);

    node->base.location.end = end_keyword->end;
    node->end_keyword_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(end_keyword);
}

/**
 * Allocate and initialize a new BlockArgumentNode node.
 */
static pm_block_argument_node_t *
pm_block_argument_node_create(pm_parser_t *parser, const pm_token_t *operator, pm_node_t *expression) {
    pm_block_argument_node_t *node = PM_NODE_ALLOC(parser, pm_block_argument_node_t);

    *node = (pm_block_argument_node_t) {
        {
            .type = PM_BLOCK_ARGUMENT_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = operator->start,
                .end = expression == NULL ? operator->end : expression->location.end
            },
        },
        .expression = expression,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator)
    };

    return node;
}

/**
 * Allocate and initialize a new BlockNode node.
 */
static pm_block_node_t *
pm_block_node_create(pm_parser_t *parser, pm_constant_id_list_t *locals, const pm_token_t *opening, pm_node_t *parameters, pm_node_t *body, const pm_token_t *closing) {
    pm_block_node_t *node = PM_NODE_ALLOC(parser, pm_block_node_t);

    *node = (pm_block_node_t) {
        {
            .type = PM_BLOCK_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = { .start = opening->start, .end = closing->end },
        },
        .locals = *locals,
        .parameters = parameters,
        .body = body,
        .opening_loc = PM_LOCATION_TOKEN_VALUE(opening),
        .closing_loc = PM_LOCATION_TOKEN_VALUE(closing)
    };

    return node;
}

/**
 * Allocate and initialize a new BlockParameterNode node.
 */
static pm_block_parameter_node_t *
pm_block_parameter_node_create(pm_parser_t *parser, const pm_token_t *name, const pm_token_t *operator) {
    assert(operator->type == PM_TOKEN_NOT_PROVIDED || operator->type == PM_TOKEN_UAMPERSAND || operator->type == PM_TOKEN_AMPERSAND);
    pm_block_parameter_node_t *node = PM_NODE_ALLOC(parser, pm_block_parameter_node_t);

    *node = (pm_block_parameter_node_t) {
        {
            .type = PM_BLOCK_PARAMETER_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = operator->start,
                .end = (name->type == PM_TOKEN_NOT_PROVIDED ? operator->end : name->end)
            },
        },
        .name = pm_parser_optional_constant_id_token(parser, name),
        .name_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(name),
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator)
    };

    return node;
}

/**
 * Allocate and initialize a new BlockParametersNode node.
 */
static pm_block_parameters_node_t *
pm_block_parameters_node_create(pm_parser_t *parser, pm_parameters_node_t *parameters, const pm_token_t *opening) {
    pm_block_parameters_node_t *node = PM_NODE_ALLOC(parser, pm_block_parameters_node_t);

    const uint8_t *start;
    if (opening->type != PM_TOKEN_NOT_PROVIDED) {
        start = opening->start;
    } else if (parameters != NULL) {
        start = parameters->base.location.start;
    } else {
        start = NULL;
    }

    const uint8_t *end;
    if (parameters != NULL) {
        end = parameters->base.location.end;
    } else if (opening->type != PM_TOKEN_NOT_PROVIDED) {
        end = opening->end;
    } else {
        end = NULL;
    }

    *node = (pm_block_parameters_node_t) {
        {
            .type = PM_BLOCK_PARAMETERS_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = start,
                .end = end
            }
        },
        .parameters = parameters,
        .opening_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(opening),
        .closing_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE,
        .locals = { 0 }
    };

    return node;
}

/**
 * Set the closing location of a BlockParametersNode node.
 */
static void
pm_block_parameters_node_closing_set(pm_block_parameters_node_t *node, const pm_token_t *closing) {
    assert(closing->type == PM_TOKEN_PIPE || closing->type == PM_TOKEN_PARENTHESIS_RIGHT || closing->type == PM_TOKEN_MISSING);

    node->base.location.end = closing->end;
    node->closing_loc = PM_LOCATION_TOKEN_VALUE(closing);
}

/**
 * Allocate and initialize a new BlockLocalVariableNode node.
 */
static pm_block_local_variable_node_t *
pm_block_local_variable_node_create(pm_parser_t *parser, const pm_token_t *name) {
    pm_block_local_variable_node_t *node = PM_NODE_ALLOC(parser, pm_block_local_variable_node_t);

    *node = (pm_block_local_variable_node_t) {
        {
            .type = PM_BLOCK_LOCAL_VARIABLE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_TOKEN_VALUE(name),
        },
        .name = pm_parser_constant_id_token(parser, name)
    };

    return node;
}

/**
 * Append a new block-local variable to a BlockParametersNode node.
 */
static void
pm_block_parameters_node_append_local(pm_block_parameters_node_t *node, const pm_block_local_variable_node_t *local) {
    pm_node_list_append(&node->locals, (pm_node_t *) local);

    if (node->base.location.start == NULL) node->base.location.start = local->base.location.start;
    node->base.location.end = local->base.location.end;
}

/**
 * Allocate and initialize a new BreakNode node.
 */
static pm_break_node_t *
pm_break_node_create(pm_parser_t *parser, const pm_token_t *keyword, pm_arguments_node_t *arguments) {
    assert(keyword->type == PM_TOKEN_KEYWORD_BREAK);
    pm_break_node_t *node = PM_NODE_ALLOC(parser, pm_break_node_t);

    *node = (pm_break_node_t) {
        {
            .type = PM_BREAK_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = keyword->start,
                .end = (arguments == NULL ? keyword->end : arguments->base.location.end)
            },
        },
        .arguments = arguments,
        .keyword_loc = PM_LOCATION_TOKEN_VALUE(keyword)
    };

    return node;
}

// There are certain flags that we want to use internally but don't want to
// expose because they are not relevant beyond parsing. Therefore we'll define
// them here and not define them in config.yml/a header file.
static const pm_node_flags_t PM_WRITE_NODE_FLAGS_IMPLICIT_ARRAY = 0x4;
static const pm_node_flags_t PM_CALL_NODE_FLAGS_IMPLICIT_ARRAY = 0x40;
static const pm_node_flags_t PM_CALL_NODE_FLAGS_COMPARISON = 0x80;
static const pm_node_flags_t PM_CALL_NODE_FLAGS_INDEX = 0x100;

/**
 * Allocate and initialize a new CallNode node. This sets everything to NULL or
 * PM_TOKEN_NOT_PROVIDED as appropriate such that its values can be overridden
 * in the various specializations of this function.
 */
static pm_call_node_t *
pm_call_node_create(pm_parser_t *parser, pm_node_flags_t flags) {
    pm_call_node_t *node = PM_NODE_ALLOC(parser, pm_call_node_t);

    *node = (pm_call_node_t) {
        {
            .type = PM_CALL_NODE,
            .flags = flags,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_NULL_VALUE(parser),
        },
        .receiver = NULL,
        .call_operator_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE,
        .message_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE,
        .opening_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE,
        .arguments = NULL,
        .closing_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE,
        .block = NULL,
        .name = 0
    };

    return node;
}

/**
 * Returns the value that the ignore visibility flag should be set to for the
 * given receiver.
 */
static inline pm_node_flags_t
pm_call_node_ignore_visibility_flag(const pm_node_t *receiver) {
    return PM_NODE_TYPE_P(receiver, PM_SELF_NODE) ? PM_CALL_NODE_FLAGS_IGNORE_VISIBILITY : 0;
}

/**
 * Allocate and initialize a new CallNode node from an aref or an aset
 * expression.
 */
static pm_call_node_t *
pm_call_node_aref_create(pm_parser_t *parser, pm_node_t *receiver, pm_arguments_t *arguments) {
    pm_assert_value_expression(parser, receiver);

    pm_node_flags_t flags = pm_call_node_ignore_visibility_flag(receiver);
    if (arguments->block == NULL || PM_NODE_TYPE_P(arguments->block, PM_BLOCK_ARGUMENT_NODE)) {
        flags |= PM_CALL_NODE_FLAGS_INDEX;
    }

    pm_call_node_t *node = pm_call_node_create(parser, flags);

    node->base.location.start = receiver->location.start;
    node->base.location.end = pm_arguments_end(arguments);

    node->receiver = receiver;
    node->message_loc.start = arguments->opening_loc.start;
    node->message_loc.end = arguments->closing_loc.end;

    node->opening_loc = arguments->opening_loc;
    node->arguments = arguments->arguments;
    node->closing_loc = arguments->closing_loc;
    node->block = arguments->block;

    node->name = pm_parser_constant_id_constant(parser, "[]", 2);
    return node;
}

/**
 * Allocate and initialize a new CallNode node from a binary expression.
 */
static pm_call_node_t *
pm_call_node_binary_create(pm_parser_t *parser, pm_node_t *receiver, pm_token_t *operator, pm_node_t *argument, pm_node_flags_t flags) {
    pm_assert_value_expression(parser, receiver);
    pm_assert_value_expression(parser, argument);

    pm_call_node_t *node = pm_call_node_create(parser, pm_call_node_ignore_visibility_flag(receiver) | flags);

    node->base.location.start = MIN(receiver->location.start, argument->location.start);
    node->base.location.end = MAX(receiver->location.end, argument->location.end);

    node->receiver = receiver;
    node->message_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(operator);

    pm_arguments_node_t *arguments = pm_arguments_node_create(parser);
    pm_arguments_node_arguments_append(arguments, argument);
    node->arguments = arguments;

    node->name = pm_parser_constant_id_token(parser, operator);
    return node;
}

/**
 * Allocate and initialize a new CallNode node from a call expression.
 */
static pm_call_node_t *
pm_call_node_call_create(pm_parser_t *parser, pm_node_t *receiver, pm_token_t *operator, pm_token_t *message, pm_arguments_t *arguments) {
    pm_assert_value_expression(parser, receiver);

    pm_call_node_t *node = pm_call_node_create(parser, pm_call_node_ignore_visibility_flag(receiver));

    node->base.location.start = receiver->location.start;
    const uint8_t *end = pm_arguments_end(arguments);
    if (end == NULL) {
        end = message->end;
    }
    node->base.location.end = end;

    node->receiver = receiver;
    node->call_operator_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(operator);
    node->message_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(message);
    node->opening_loc = arguments->opening_loc;
    node->arguments = arguments->arguments;
    node->closing_loc = arguments->closing_loc;
    node->block = arguments->block;

    if (operator->type == PM_TOKEN_AMPERSAND_DOT) {
        pm_node_flag_set((pm_node_t *)node, PM_CALL_NODE_FLAGS_SAFE_NAVIGATION);
    }

    node->name = pm_parser_constant_id_token(parser, message);
    return node;
}

/**
 * Allocate and initialize a new synthesized CallNode node from a call expression.
 */
static pm_call_node_t *
pm_call_node_call_synthesized_create(pm_parser_t *parser, pm_node_t *receiver, const char *message, pm_arguments_node_t *arguments) {
    pm_call_node_t *node = pm_call_node_create(parser, 0);
    node->base.location.start = parser->start;
    node->base.location.end = parser->end;

    node->receiver = receiver;
    node->call_operator_loc = (pm_location_t) { .start = NULL, .end = NULL };
    node->message_loc = (pm_location_t) { .start = NULL, .end = NULL };
    node->arguments = arguments;

    node->name = pm_parser_constant_id_constant(parser, message, strlen(message));
    return node;
}

/**
 * Allocate and initialize a new CallNode node from a call to a method name
 * without a receiver that could not have been a local variable read.
 */
static pm_call_node_t *
pm_call_node_fcall_create(pm_parser_t *parser, pm_token_t *message, pm_arguments_t *arguments) {
    pm_call_node_t *node = pm_call_node_create(parser, PM_CALL_NODE_FLAGS_IGNORE_VISIBILITY);

    node->base.location.start = message->start;
    node->base.location.end = pm_arguments_end(arguments);

    node->message_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(message);
    node->opening_loc = arguments->opening_loc;
    node->arguments = arguments->arguments;
    node->closing_loc = arguments->closing_loc;
    node->block = arguments->block;

    node->name = pm_parser_constant_id_token(parser, message);
    return node;
}

/**
 * Allocate and initialize a new CallNode node from a synthesized call to a
 * method name with the given arguments.
 */
static pm_call_node_t *
pm_call_node_fcall_synthesized_create(pm_parser_t *parser, pm_arguments_node_t *arguments, pm_constant_id_t name) {
    pm_call_node_t *node = pm_call_node_create(parser, PM_CALL_NODE_FLAGS_IGNORE_VISIBILITY);

    node->base.location = PM_LOCATION_NULL_VALUE(parser);
    node->arguments = arguments;

    node->name = name;
    return node;
}

/**
 * Allocate and initialize a new CallNode node from a not expression.
 */
static pm_call_node_t *
pm_call_node_not_create(pm_parser_t *parser, pm_node_t *receiver, pm_token_t *message, pm_arguments_t *arguments) {
    pm_assert_value_expression(parser, receiver);
    if (receiver != NULL) pm_conditional_predicate(parser, receiver, PM_CONDITIONAL_PREDICATE_TYPE_NOT);

    pm_call_node_t *node = pm_call_node_create(parser, receiver == NULL ? 0 : pm_call_node_ignore_visibility_flag(receiver));

    node->base.location.start = message->start;
    if (arguments->closing_loc.start != NULL) {
        node->base.location.end = arguments->closing_loc.end;
    } else {
        assert(receiver != NULL);
        node->base.location.end = receiver->location.end;
    }

    node->receiver = receiver;
    node->message_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(message);
    node->opening_loc = arguments->opening_loc;
    node->arguments = arguments->arguments;
    node->closing_loc = arguments->closing_loc;

    node->name = pm_parser_constant_id_constant(parser, "!", 1);
    return node;
}

/**
 * Allocate and initialize a new CallNode node from a call shorthand expression.
 */
static pm_call_node_t *
pm_call_node_shorthand_create(pm_parser_t *parser, pm_node_t *receiver, pm_token_t *operator, pm_arguments_t *arguments) {
    pm_assert_value_expression(parser, receiver);

    pm_call_node_t *node = pm_call_node_create(parser, pm_call_node_ignore_visibility_flag(receiver));

    node->base.location.start = receiver->location.start;
    node->base.location.end = pm_arguments_end(arguments);

    node->receiver = receiver;
    node->call_operator_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(operator);
    node->opening_loc = arguments->opening_loc;
    node->arguments = arguments->arguments;
    node->closing_loc = arguments->closing_loc;
    node->block = arguments->block;

    if (operator->type == PM_TOKEN_AMPERSAND_DOT) {
        pm_node_flag_set((pm_node_t *)node, PM_CALL_NODE_FLAGS_SAFE_NAVIGATION);
    }

    node->name = pm_parser_constant_id_constant(parser, "call", 4);
    return node;
}

/**
 * Allocate and initialize a new CallNode node from a unary operator expression.
 */
static pm_call_node_t *
pm_call_node_unary_create(pm_parser_t *parser, pm_token_t *operator, pm_node_t *receiver, const char *name) {
    pm_assert_value_expression(parser, receiver);

    pm_call_node_t *node = pm_call_node_create(parser, pm_call_node_ignore_visibility_flag(receiver));

    node->base.location.start = operator->start;
    node->base.location.end = receiver->location.end;

    node->receiver = receiver;
    node->message_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(operator);

    node->name = pm_parser_constant_id_constant(parser, name, strlen(name));
    return node;
}

/**
 * Allocate and initialize a new CallNode node from a call to a method name
 * without a receiver that could also have been a local variable read.
 */
static pm_call_node_t *
pm_call_node_variable_call_create(pm_parser_t *parser, pm_token_t *message) {
    pm_call_node_t *node = pm_call_node_create(parser, PM_CALL_NODE_FLAGS_IGNORE_VISIBILITY);

    node->base.location = PM_LOCATION_TOKEN_VALUE(message);
    node->message_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(message);

    node->name = pm_parser_constant_id_token(parser, message);
    return node;
}

/**
 * Returns whether or not this call can be used on the left-hand side of an
 * operator assignment.
 */
static inline bool
pm_call_node_writable_p(const pm_parser_t *parser, const pm_call_node_t *node) {
    return (
        (node->message_loc.start != NULL) &&
        (node->message_loc.end[-1] != '!') &&
        (node->message_loc.end[-1] != '?') &&
        char_is_identifier_start(parser, node->message_loc.start, parser->end - node->message_loc.start) &&
        (node->opening_loc.start == NULL) &&
        (node->arguments == NULL) &&
        (node->block == NULL)
    );
}

/**
 * Initialize the read name by reading the write name and chopping off the '='.
 */
static void
pm_call_write_read_name_init(pm_parser_t *parser, pm_constant_id_t *read_name, pm_constant_id_t *write_name) {
    pm_constant_t *write_constant = pm_constant_pool_id_to_constant(&parser->constant_pool, *write_name);

    if (write_constant->length > 0) {
        size_t length = write_constant->length - 1;

        void *memory = xmalloc(length);
        memcpy(memory, write_constant->start, length);

        *read_name = pm_constant_pool_insert_owned(&parser->constant_pool, (uint8_t *) memory, length);
    } else {
        // We can get here if the message was missing because of a syntax error.
        *read_name = pm_parser_constant_id_constant(parser, "", 0);
    }
}

/**
 * Allocate and initialize a new CallAndWriteNode node.
 */
static pm_call_and_write_node_t *
pm_call_and_write_node_create(pm_parser_t *parser, pm_call_node_t *target, const pm_token_t *operator, pm_node_t *value) {
    assert(target->block == NULL);
    assert(operator->type == PM_TOKEN_AMPERSAND_AMPERSAND_EQUAL);
    pm_call_and_write_node_t *node = PM_NODE_ALLOC(parser, pm_call_and_write_node_t);

    *node = (pm_call_and_write_node_t) {
        {
            .type = PM_CALL_AND_WRITE_NODE,
            .flags = target->base.flags,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->base.location.start,
                .end = value->location.end
            }
        },
        .receiver = target->receiver,
        .call_operator_loc = target->call_operator_loc,
        .message_loc = target->message_loc,
        .read_name = 0,
        .write_name = target->name,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value
    };

    pm_call_write_read_name_init(parser, &node->read_name, &node->write_name);

    // Here we're going to free the target, since it is no longer necessary.
    // However, we don't want to call `pm_node_destroy` because we want to keep
    // around all of its children since we just reused them.
    xfree(target);

    return node;
}

/**
 * Validate that index expressions do not have keywords or blocks if we are
 * parsing as Ruby 3.4+.
 */
static void
pm_index_arguments_check(pm_parser_t *parser, const pm_arguments_node_t *arguments, const pm_node_t *block) {
    if (parser->version != PM_OPTIONS_VERSION_CRUBY_3_3) {
        if (arguments != NULL && PM_NODE_FLAG_P(arguments, PM_ARGUMENTS_NODE_FLAGS_CONTAINS_KEYWORDS)) {
            pm_node_t *node;
            PM_NODE_LIST_FOREACH(&arguments->arguments, index, node) {
                if (PM_NODE_TYPE_P(node, PM_KEYWORD_HASH_NODE)) {
                    pm_parser_err_node(parser, node, PM_ERR_UNEXPECTED_INDEX_KEYWORDS);
                    break;
                }
            }
        }

        if (block != NULL) {
            pm_parser_err_node(parser, block, PM_ERR_UNEXPECTED_INDEX_BLOCK);
        }
    }
}

/**
 * Allocate and initialize a new IndexAndWriteNode node.
 */
static pm_index_and_write_node_t *
pm_index_and_write_node_create(pm_parser_t *parser, pm_call_node_t *target, const pm_token_t *operator, pm_node_t *value) {
    assert(operator->type == PM_TOKEN_AMPERSAND_AMPERSAND_EQUAL);
    pm_index_and_write_node_t *node = PM_NODE_ALLOC(parser, pm_index_and_write_node_t);

    pm_index_arguments_check(parser, target->arguments, target->block);

    assert(!target->block || PM_NODE_TYPE_P(target->block, PM_BLOCK_ARGUMENT_NODE));
    *node = (pm_index_and_write_node_t) {
        {
            .type = PM_INDEX_AND_WRITE_NODE,
            .flags = target->base.flags,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->base.location.start,
                .end = value->location.end
            }
        },
        .receiver = target->receiver,
        .call_operator_loc = target->call_operator_loc,
        .opening_loc = target->opening_loc,
        .arguments = target->arguments,
        .closing_loc = target->closing_loc,
        .block = (pm_block_argument_node_t *) target->block,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value
    };

    // Here we're going to free the target, since it is no longer necessary.
    // However, we don't want to call `pm_node_destroy` because we want to keep
    // around all of its children since we just reused them.
    xfree(target);

    return node;
}

/**
 * Allocate a new CallOperatorWriteNode node.
 */
static pm_call_operator_write_node_t *
pm_call_operator_write_node_create(pm_parser_t *parser, pm_call_node_t *target, const pm_token_t *operator, pm_node_t *value) {
    assert(target->block == NULL);
    pm_call_operator_write_node_t *node = PM_NODE_ALLOC(parser, pm_call_operator_write_node_t);

    *node = (pm_call_operator_write_node_t) {
        {
            .type = PM_CALL_OPERATOR_WRITE_NODE,
            .flags = target->base.flags,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->base.location.start,
                .end = value->location.end
            }
        },
        .receiver = target->receiver,
        .call_operator_loc = target->call_operator_loc,
        .message_loc = target->message_loc,
        .read_name = 0,
        .write_name = target->name,
        .binary_operator = pm_parser_constant_id_location(parser, operator->start, operator->end - 1),
        .binary_operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value
    };

    pm_call_write_read_name_init(parser, &node->read_name, &node->write_name);

    // Here we're going to free the target, since it is no longer necessary.
    // However, we don't want to call `pm_node_destroy` because we want to keep
    // around all of its children since we just reused them.
    xfree(target);

    return node;
}

/**
 * Allocate a new IndexOperatorWriteNode node.
 */
static pm_index_operator_write_node_t *
pm_index_operator_write_node_create(pm_parser_t *parser, pm_call_node_t *target, const pm_token_t *operator, pm_node_t *value) {
    pm_index_operator_write_node_t *node = PM_NODE_ALLOC(parser, pm_index_operator_write_node_t);

    pm_index_arguments_check(parser, target->arguments, target->block);

    assert(!target->block || PM_NODE_TYPE_P(target->block, PM_BLOCK_ARGUMENT_NODE));
    *node = (pm_index_operator_write_node_t) {
        {
            .type = PM_INDEX_OPERATOR_WRITE_NODE,
            .flags = target->base.flags,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->base.location.start,
                .end = value->location.end
            }
        },
        .receiver = target->receiver,
        .call_operator_loc = target->call_operator_loc,
        .opening_loc = target->opening_loc,
        .arguments = target->arguments,
        .closing_loc = target->closing_loc,
        .block = (pm_block_argument_node_t *) target->block,
        .binary_operator = pm_parser_constant_id_location(parser, operator->start, operator->end - 1),
        .binary_operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value
    };

    // Here we're going to free the target, since it is no longer necessary.
    // However, we don't want to call `pm_node_destroy` because we want to keep
    // around all of its children since we just reused them.
    xfree(target);

    return node;
}

/**
 * Allocate and initialize a new CallOrWriteNode node.
 */
static pm_call_or_write_node_t *
pm_call_or_write_node_create(pm_parser_t *parser, pm_call_node_t *target, const pm_token_t *operator, pm_node_t *value) {
    assert(target->block == NULL);
    assert(operator->type == PM_TOKEN_PIPE_PIPE_EQUAL);
    pm_call_or_write_node_t *node = PM_NODE_ALLOC(parser, pm_call_or_write_node_t);

    *node = (pm_call_or_write_node_t) {
        {
            .type = PM_CALL_OR_WRITE_NODE,
            .flags = target->base.flags,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->base.location.start,
                .end = value->location.end
            }
        },
        .receiver = target->receiver,
        .call_operator_loc = target->call_operator_loc,
        .message_loc = target->message_loc,
        .read_name = 0,
        .write_name = target->name,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value
    };

    pm_call_write_read_name_init(parser, &node->read_name, &node->write_name);

    // Here we're going to free the target, since it is no longer necessary.
    // However, we don't want to call `pm_node_destroy` because we want to keep
    // around all of its children since we just reused them.
    xfree(target);

    return node;
}

/**
 * Allocate and initialize a new IndexOrWriteNode node.
 */
static pm_index_or_write_node_t *
pm_index_or_write_node_create(pm_parser_t *parser, pm_call_node_t *target, const pm_token_t *operator, pm_node_t *value) {
    assert(operator->type == PM_TOKEN_PIPE_PIPE_EQUAL);
    pm_index_or_write_node_t *node = PM_NODE_ALLOC(parser, pm_index_or_write_node_t);

    pm_index_arguments_check(parser, target->arguments, target->block);

    assert(!target->block || PM_NODE_TYPE_P(target->block, PM_BLOCK_ARGUMENT_NODE));
    *node = (pm_index_or_write_node_t) {
        {
            .type = PM_INDEX_OR_WRITE_NODE,
            .flags = target->base.flags,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->base.location.start,
                .end = value->location.end
            }
        },
        .receiver = target->receiver,
        .call_operator_loc = target->call_operator_loc,
        .opening_loc = target->opening_loc,
        .arguments = target->arguments,
        .closing_loc = target->closing_loc,
        .block = (pm_block_argument_node_t *) target->block,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value
    };

    // Here we're going to free the target, since it is no longer necessary.
    // However, we don't want to call `pm_node_destroy` because we want to keep
    // around all of its children since we just reused them.
    xfree(target);

    return node;
}

/**
 * Allocate and initialize a new CallTargetNode node from an existing call
 * node.
 */
static pm_call_target_node_t *
pm_call_target_node_create(pm_parser_t *parser, pm_call_node_t *target) {
    pm_call_target_node_t *node = PM_NODE_ALLOC(parser, pm_call_target_node_t);

    *node = (pm_call_target_node_t) {
        {
            .type = PM_CALL_TARGET_NODE,
            .flags = target->base.flags,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = target->base.location
        },
        .receiver = target->receiver,
        .call_operator_loc = target->call_operator_loc,
        .name = target->name,
        .message_loc = target->message_loc
    };

    // Here we're going to free the target, since it is no longer necessary.
    // However, we don't want to call `pm_node_destroy` because we want to keep
    // around all of its children since we just reused them.
    xfree(target);

    return node;
}

/**
 * Allocate and initialize a new IndexTargetNode node from an existing call
 * node.
 */
static pm_index_target_node_t *
pm_index_target_node_create(pm_parser_t *parser, pm_call_node_t *target) {
    pm_index_target_node_t *node = PM_NODE_ALLOC(parser, pm_index_target_node_t);
    pm_node_flags_t flags = target->base.flags;

    pm_index_arguments_check(parser, target->arguments, target->block);

    assert(!target->block || PM_NODE_TYPE_P(target->block, PM_BLOCK_ARGUMENT_NODE));
    *node = (pm_index_target_node_t) {
        {
            .type = PM_INDEX_TARGET_NODE,
            .flags = flags | PM_CALL_NODE_FLAGS_ATTRIBUTE_WRITE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = target->base.location
        },
        .receiver = target->receiver,
        .opening_loc = target->opening_loc,
        .arguments = target->arguments,
        .closing_loc = target->closing_loc,
        .block = (pm_block_argument_node_t *) target->block,
    };

    // Here we're going to free the target, since it is no longer necessary.
    // However, we don't want to call `pm_node_destroy` because we want to keep
    // around all of its children since we just reused them.
    xfree(target);

    return node;
}

/**
 * Allocate and initialize a new CapturePatternNode node.
 */
static pm_capture_pattern_node_t *
pm_capture_pattern_node_create(pm_parser_t *parser, pm_node_t *value, pm_local_variable_target_node_t *target, const pm_token_t *operator) {
    pm_capture_pattern_node_t *node = PM_NODE_ALLOC(parser, pm_capture_pattern_node_t);

    *node = (pm_capture_pattern_node_t) {
        {
            .type = PM_CAPTURE_PATTERN_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = value->location.start,
                .end = target->base.location.end
            },
        },
        .value = value,
        .target = target,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator)
    };

    return node;
}

/**
 * Allocate and initialize a new CaseNode node.
 */
static pm_case_node_t *
pm_case_node_create(pm_parser_t *parser, const pm_token_t *case_keyword, pm_node_t *predicate, const pm_token_t *end_keyword) {
    pm_case_node_t *node = PM_NODE_ALLOC(parser, pm_case_node_t);

    *node = (pm_case_node_t) {
        {
            .type = PM_CASE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = case_keyword->start,
                .end = end_keyword->end
            },
        },
        .predicate = predicate,
        .else_clause = NULL,
        .case_keyword_loc = PM_LOCATION_TOKEN_VALUE(case_keyword),
        .end_keyword_loc = PM_LOCATION_TOKEN_VALUE(end_keyword),
        .conditions = { 0 }
    };

    return node;
}

/**
 * Append a new condition to a CaseNode node.
 */
static void
pm_case_node_condition_append(pm_case_node_t *node, pm_node_t *condition) {
    assert(PM_NODE_TYPE_P(condition, PM_WHEN_NODE));

    pm_node_list_append(&node->conditions, condition);
    node->base.location.end = condition->location.end;
}

/**
 * Set the else clause of a CaseNode node.
 */
static void
pm_case_node_else_clause_set(pm_case_node_t *node, pm_else_node_t *else_clause) {
    node->else_clause = else_clause;
    node->base.location.end = else_clause->base.location.end;
}

/**
 * Set the end location for a CaseNode node.
 */
static void
pm_case_node_end_keyword_loc_set(pm_case_node_t *node, const pm_token_t *end_keyword) {
    node->base.location.end = end_keyword->end;
    node->end_keyword_loc = PM_LOCATION_TOKEN_VALUE(end_keyword);
}

/**
 * Allocate and initialize a new CaseMatchNode node.
 */
static pm_case_match_node_t *
pm_case_match_node_create(pm_parser_t *parser, const pm_token_t *case_keyword, pm_node_t *predicate, const pm_token_t *end_keyword) {
    pm_case_match_node_t *node = PM_NODE_ALLOC(parser, pm_case_match_node_t);

    *node = (pm_case_match_node_t) {
        {
            .type = PM_CASE_MATCH_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = case_keyword->start,
                .end = end_keyword->end
            },
        },
        .predicate = predicate,
        .else_clause = NULL,
        .case_keyword_loc = PM_LOCATION_TOKEN_VALUE(case_keyword),
        .end_keyword_loc = PM_LOCATION_TOKEN_VALUE(end_keyword),
        .conditions = { 0 }
    };

    return node;
}

/**
 * Append a new condition to a CaseMatchNode node.
 */
static void
pm_case_match_node_condition_append(pm_case_match_node_t *node, pm_node_t *condition) {
    assert(PM_NODE_TYPE_P(condition, PM_IN_NODE));

    pm_node_list_append(&node->conditions, condition);
    node->base.location.end = condition->location.end;
}

/**
 * Set the else clause of a CaseMatchNode node.
 */
static void
pm_case_match_node_else_clause_set(pm_case_match_node_t *node, pm_else_node_t *else_clause) {
    node->else_clause = else_clause;
    node->base.location.end = else_clause->base.location.end;
}

/**
 * Set the end location for a CaseMatchNode node.
 */
static void
pm_case_match_node_end_keyword_loc_set(pm_case_match_node_t *node, const pm_token_t *end_keyword) {
    node->base.location.end = end_keyword->end;
    node->end_keyword_loc = PM_LOCATION_TOKEN_VALUE(end_keyword);
}

/**
 * Allocate a new ClassNode node.
 */
static pm_class_node_t *
pm_class_node_create(pm_parser_t *parser, pm_constant_id_list_t *locals, const pm_token_t *class_keyword, pm_node_t *constant_path, const pm_token_t *name, const pm_token_t *inheritance_operator, pm_node_t *superclass, pm_node_t *body, const pm_token_t *end_keyword) {
    pm_class_node_t *node = PM_NODE_ALLOC(parser, pm_class_node_t);

    *node = (pm_class_node_t) {
        {
            .type = PM_CLASS_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = { .start = class_keyword->start, .end = end_keyword->end },
        },
        .locals = *locals,
        .class_keyword_loc = PM_LOCATION_TOKEN_VALUE(class_keyword),
        .constant_path = constant_path,
        .inheritance_operator_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(inheritance_operator),
        .superclass = superclass,
        .body = body,
        .end_keyword_loc = PM_LOCATION_TOKEN_VALUE(end_keyword),
        .name = pm_parser_constant_id_token(parser, name)
    };

    return node;
}

/**
 * Allocate and initialize a new ClassVariableAndWriteNode node.
 */
static pm_class_variable_and_write_node_t *
pm_class_variable_and_write_node_create(pm_parser_t *parser, pm_class_variable_read_node_t *target, const pm_token_t *operator, pm_node_t *value) {
    assert(operator->type == PM_TOKEN_AMPERSAND_AMPERSAND_EQUAL);
    pm_class_variable_and_write_node_t *node = PM_NODE_ALLOC(parser, pm_class_variable_and_write_node_t);

    *node = (pm_class_variable_and_write_node_t) {
        {
            .type = PM_CLASS_VARIABLE_AND_WRITE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->base.location.start,
                .end = value->location.end
            }
        },
        .name = target->name,
        .name_loc = target->base.location,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value
    };

    return node;
}

/**
 * Allocate and initialize a new ClassVariableOperatorWriteNode node.
 */
static pm_class_variable_operator_write_node_t *
pm_class_variable_operator_write_node_create(pm_parser_t *parser, pm_class_variable_read_node_t *target, const pm_token_t *operator, pm_node_t *value) {
    pm_class_variable_operator_write_node_t *node = PM_NODE_ALLOC(parser, pm_class_variable_operator_write_node_t);

    *node = (pm_class_variable_operator_write_node_t) {
        {
            .type = PM_CLASS_VARIABLE_OPERATOR_WRITE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->base.location.start,
                .end = value->location.end
            }
        },
        .name = target->name,
        .name_loc = target->base.location,
        .binary_operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value,
        .binary_operator = pm_parser_constant_id_location(parser, operator->start, operator->end - 1)
    };

    return node;
}

/**
 * Allocate and initialize a new ClassVariableOrWriteNode node.
 */
static pm_class_variable_or_write_node_t *
pm_class_variable_or_write_node_create(pm_parser_t *parser, pm_class_variable_read_node_t *target, const pm_token_t *operator, pm_node_t *value) {
    assert(operator->type == PM_TOKEN_PIPE_PIPE_EQUAL);
    pm_class_variable_or_write_node_t *node = PM_NODE_ALLOC(parser, pm_class_variable_or_write_node_t);

    *node = (pm_class_variable_or_write_node_t) {
        {
            .type = PM_CLASS_VARIABLE_OR_WRITE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->base.location.start,
                .end = value->location.end
            }
        },
        .name = target->name,
        .name_loc = target->base.location,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value
    };

    return node;
}

/**
 * Allocate and initialize a new ClassVariableReadNode node.
 */
static pm_class_variable_read_node_t *
pm_class_variable_read_node_create(pm_parser_t *parser, const pm_token_t *token) {
    assert(token->type == PM_TOKEN_CLASS_VARIABLE);
    pm_class_variable_read_node_t *node = PM_NODE_ALLOC(parser, pm_class_variable_read_node_t);

    *node = (pm_class_variable_read_node_t) {
        {
            .type = PM_CLASS_VARIABLE_READ_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_TOKEN_VALUE(token)
        },
        .name = pm_parser_constant_id_token(parser, token)
    };

    return node;
}

/**
 * True if the given node is an implicit array node on a write, as in:
 *
 *     a = *b
 *     a = 1, 2, 3
 */
static inline pm_node_flags_t
pm_implicit_array_write_flags(const pm_node_t *node, pm_node_flags_t flags) {
    if (PM_NODE_TYPE_P(node, PM_ARRAY_NODE) && ((const pm_array_node_t *) node)->opening_loc.start == NULL) {
        return flags;
    }
    return 0;
}

/**
 * Initialize a new ClassVariableWriteNode node from a ClassVariableRead node.
 */
static pm_class_variable_write_node_t *
pm_class_variable_write_node_create(pm_parser_t *parser, pm_class_variable_read_node_t *read_node, pm_token_t *operator, pm_node_t *value) {
    pm_class_variable_write_node_t *node = PM_NODE_ALLOC(parser, pm_class_variable_write_node_t);

    *node = (pm_class_variable_write_node_t) {
        {
            .type = PM_CLASS_VARIABLE_WRITE_NODE,
            .flags = pm_implicit_array_write_flags(value, PM_WRITE_NODE_FLAGS_IMPLICIT_ARRAY),
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = read_node->base.location.start,
                .end = value->location.end
            },
        },
        .name = read_node->name,
        .name_loc = PM_LOCATION_NODE_VALUE((pm_node_t *) read_node),
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value
    };

    return node;
}

/**
 * Allocate and initialize a new ConstantPathAndWriteNode node.
 */
static pm_constant_path_and_write_node_t *
pm_constant_path_and_write_node_create(pm_parser_t *parser, pm_constant_path_node_t *target, const pm_token_t *operator, pm_node_t *value) {
    assert(operator->type == PM_TOKEN_AMPERSAND_AMPERSAND_EQUAL);
    pm_constant_path_and_write_node_t *node = PM_NODE_ALLOC(parser, pm_constant_path_and_write_node_t);

    *node = (pm_constant_path_and_write_node_t) {
        {
            .type = PM_CONSTANT_PATH_AND_WRITE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->base.location.start,
                .end = value->location.end
            }
        },
        .target = target,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value
    };

    return node;
}

/**
 * Allocate and initialize a new ConstantPathOperatorWriteNode node.
 */
static pm_constant_path_operator_write_node_t *
pm_constant_path_operator_write_node_create(pm_parser_t *parser, pm_constant_path_node_t *target, const pm_token_t *operator, pm_node_t *value) {
    pm_constant_path_operator_write_node_t *node = PM_NODE_ALLOC(parser, pm_constant_path_operator_write_node_t);

    *node = (pm_constant_path_operator_write_node_t) {
        {
            .type = PM_CONSTANT_PATH_OPERATOR_WRITE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->base.location.start,
                .end = value->location.end
            }
        },
        .target = target,
        .binary_operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value,
        .binary_operator = pm_parser_constant_id_location(parser, operator->start, operator->end - 1)
    };

    return node;
}

/**
 * Allocate and initialize a new ConstantPathOrWriteNode node.
 */
static pm_constant_path_or_write_node_t *
pm_constant_path_or_write_node_create(pm_parser_t *parser, pm_constant_path_node_t *target, const pm_token_t *operator, pm_node_t *value) {
    assert(operator->type == PM_TOKEN_PIPE_PIPE_EQUAL);
    pm_constant_path_or_write_node_t *node = PM_NODE_ALLOC(parser, pm_constant_path_or_write_node_t);

    *node = (pm_constant_path_or_write_node_t) {
        {
            .type = PM_CONSTANT_PATH_OR_WRITE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->base.location.start,
                .end = value->location.end
            }
        },
        .target = target,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value
    };

    return node;
}

/**
 * Allocate and initialize a new ConstantPathNode node.
 */
static pm_constant_path_node_t *
pm_constant_path_node_create(pm_parser_t *parser, pm_node_t *parent, const pm_token_t *delimiter, const pm_token_t *name_token) {
    pm_assert_value_expression(parser, parent);
    pm_constant_path_node_t *node = PM_NODE_ALLOC(parser, pm_constant_path_node_t);

    pm_constant_id_t name = PM_CONSTANT_ID_UNSET;
    if (name_token->type == PM_TOKEN_CONSTANT) {
        name = pm_parser_constant_id_token(parser, name_token);
    }

    *node = (pm_constant_path_node_t) {
        {
            .type = PM_CONSTANT_PATH_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = parent == NULL ? delimiter->start : parent->location.start,
                .end = name_token->end
            },
        },
        .parent = parent,
        .name = name,
        .delimiter_loc = PM_LOCATION_TOKEN_VALUE(delimiter),
        .name_loc = PM_LOCATION_TOKEN_VALUE(name_token)
    };

    return node;
}

/**
 * Allocate a new ConstantPathWriteNode node.
 */
static pm_constant_path_write_node_t *
pm_constant_path_write_node_create(pm_parser_t *parser, pm_constant_path_node_t *target, const pm_token_t *operator, pm_node_t *value) {
    pm_constant_path_write_node_t *node = PM_NODE_ALLOC(parser, pm_constant_path_write_node_t);

    *node = (pm_constant_path_write_node_t) {
        {
            .type = PM_CONSTANT_PATH_WRITE_NODE,
            .flags = pm_implicit_array_write_flags(value, PM_WRITE_NODE_FLAGS_IMPLICIT_ARRAY),
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->base.location.start,
                .end = value->location.end
            },
        },
        .target = target,
        .operator_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(operator),
        .value = value
    };

    return node;
}

/**
 * Allocate and initialize a new ConstantAndWriteNode node.
 */
static pm_constant_and_write_node_t *
pm_constant_and_write_node_create(pm_parser_t *parser, pm_constant_read_node_t *target, const pm_token_t *operator, pm_node_t *value) {
    assert(operator->type == PM_TOKEN_AMPERSAND_AMPERSAND_EQUAL);
    pm_constant_and_write_node_t *node = PM_NODE_ALLOC(parser, pm_constant_and_write_node_t);

    *node = (pm_constant_and_write_node_t) {
        {
            .type = PM_CONSTANT_AND_WRITE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->base.location.start,
                .end = value->location.end
            }
        },
        .name = target->name,
        .name_loc = target->base.location,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value
    };

    return node;
}

/**
 * Allocate and initialize a new ConstantOperatorWriteNode node.
 */
static pm_constant_operator_write_node_t *
pm_constant_operator_write_node_create(pm_parser_t *parser, pm_constant_read_node_t *target, const pm_token_t *operator, pm_node_t *value) {
    pm_constant_operator_write_node_t *node = PM_NODE_ALLOC(parser, pm_constant_operator_write_node_t);

    *node = (pm_constant_operator_write_node_t) {
        {
            .type = PM_CONSTANT_OPERATOR_WRITE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->base.location.start,
                .end = value->location.end
            }
        },
        .name = target->name,
        .name_loc = target->base.location,
        .binary_operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value,
        .binary_operator = pm_parser_constant_id_location(parser, operator->start, operator->end - 1)
    };

    return node;
}

/**
 * Allocate and initialize a new ConstantOrWriteNode node.
 */
static pm_constant_or_write_node_t *
pm_constant_or_write_node_create(pm_parser_t *parser, pm_constant_read_node_t *target, const pm_token_t *operator, pm_node_t *value) {
    assert(operator->type == PM_TOKEN_PIPE_PIPE_EQUAL);
    pm_constant_or_write_node_t *node = PM_NODE_ALLOC(parser, pm_constant_or_write_node_t);

    *node = (pm_constant_or_write_node_t) {
        {
            .type = PM_CONSTANT_OR_WRITE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->base.location.start,
                .end = value->location.end
            }
        },
        .name = target->name,
        .name_loc = target->base.location,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value
    };

    return node;
}

/**
 * Allocate and initialize a new ConstantReadNode node.
 */
static pm_constant_read_node_t *
pm_constant_read_node_create(pm_parser_t *parser, const pm_token_t *name) {
    assert(name->type == PM_TOKEN_CONSTANT || name->type == PM_TOKEN_MISSING);
    pm_constant_read_node_t *node = PM_NODE_ALLOC(parser, pm_constant_read_node_t);

    *node = (pm_constant_read_node_t) {
        {
            .type = PM_CONSTANT_READ_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_TOKEN_VALUE(name)
        },
        .name = pm_parser_constant_id_token(parser, name)
    };

    return node;
}

/**
 * Allocate a new ConstantWriteNode node.
 */
static pm_constant_write_node_t *
pm_constant_write_node_create(pm_parser_t *parser, pm_constant_read_node_t *target, const pm_token_t *operator, pm_node_t *value) {
    pm_constant_write_node_t *node = PM_NODE_ALLOC(parser, pm_constant_write_node_t);

    *node = (pm_constant_write_node_t) {
        {
            .type = PM_CONSTANT_WRITE_NODE,
            .flags = pm_implicit_array_write_flags(value, PM_WRITE_NODE_FLAGS_IMPLICIT_ARRAY),
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->base.location.start,
                .end = value->location.end
            }
        },
        .name = target->name,
        .name_loc = target->base.location,
        .operator_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(operator),
        .value = value
    };

    return node;
}

/**
 * Check if the receiver of a `def` node is allowed.
 */
static void
pm_def_node_receiver_check(pm_parser_t *parser, const pm_node_t *node) {
    switch (PM_NODE_TYPE(node)) {
        case PM_BEGIN_NODE: {
            const pm_begin_node_t *cast = (pm_begin_node_t *) node;
            if (cast->statements != NULL) pm_def_node_receiver_check(parser, (pm_node_t *) cast->statements);
            break;
        }
        case PM_PARENTHESES_NODE: {
            const pm_parentheses_node_t *cast = (const pm_parentheses_node_t *) node;
            if (cast->body != NULL) pm_def_node_receiver_check(parser, cast->body);
            break;
        }
        case PM_STATEMENTS_NODE: {
            const pm_statements_node_t *cast = (const pm_statements_node_t *) node;
            pm_def_node_receiver_check(parser, cast->body.nodes[cast->body.size - 1]);
            break;
        }
        case PM_ARRAY_NODE:
        case PM_FLOAT_NODE:
        case PM_IMAGINARY_NODE:
        case PM_INTEGER_NODE:
        case PM_INTERPOLATED_REGULAR_EXPRESSION_NODE:
        case PM_INTERPOLATED_STRING_NODE:
        case PM_INTERPOLATED_SYMBOL_NODE:
        case PM_INTERPOLATED_X_STRING_NODE:
        case PM_RATIONAL_NODE:
        case PM_REGULAR_EXPRESSION_NODE:
        case PM_SOURCE_ENCODING_NODE:
        case PM_SOURCE_FILE_NODE:
        case PM_SOURCE_LINE_NODE:
        case PM_STRING_NODE:
        case PM_SYMBOL_NODE:
        case PM_X_STRING_NODE:
            pm_parser_err_node(parser, node, PM_ERR_SINGLETON_FOR_LITERALS);
            break;
        default:
            break;
    }
}

/**
 * Allocate and initialize a new DefNode node.
 */
static pm_def_node_t *
pm_def_node_create(
    pm_parser_t *parser,
    pm_constant_id_t name,
    const pm_token_t *name_loc,
    pm_node_t *receiver,
    pm_parameters_node_t *parameters,
    pm_node_t *body,
    pm_constant_id_list_t *locals,
    const pm_token_t *def_keyword,
    const pm_token_t *operator,
    const pm_token_t *lparen,
    const pm_token_t *rparen,
    const pm_token_t *equal,
    const pm_token_t *end_keyword
) {
    pm_def_node_t *node = PM_NODE_ALLOC(parser, pm_def_node_t);
    const uint8_t *end;

    if (end_keyword->type == PM_TOKEN_NOT_PROVIDED) {
        end = body->location.end;
    } else {
        end = end_keyword->end;
    }

    if ((receiver != NULL) && PM_NODE_TYPE_P(receiver, PM_PARENTHESES_NODE)) {
        pm_def_node_receiver_check(parser, receiver);
    }

    *node = (pm_def_node_t) {
        {
            .type = PM_DEF_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = { .start = def_keyword->start, .end = end },
        },
        .name = name,
        .name_loc = PM_LOCATION_TOKEN_VALUE(name_loc),
        .receiver = receiver,
        .parameters = parameters,
        .body = body,
        .locals = *locals,
        .def_keyword_loc = PM_LOCATION_TOKEN_VALUE(def_keyword),
        .operator_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(operator),
        .lparen_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(lparen),
        .rparen_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(rparen),
        .equal_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(equal),
        .end_keyword_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(end_keyword)
    };

    return node;
}

/**
 * Allocate a new DefinedNode node.
 */
static pm_defined_node_t *
pm_defined_node_create(pm_parser_t *parser, const pm_token_t *lparen, pm_node_t *value, const pm_token_t *rparen, const pm_location_t *keyword_loc) {
    pm_defined_node_t *node = PM_NODE_ALLOC(parser, pm_defined_node_t);

    *node = (pm_defined_node_t) {
        {
            .type = PM_DEFINED_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = keyword_loc->start,
                .end = (rparen->type == PM_TOKEN_NOT_PROVIDED ? value->location.end : rparen->end)
            },
        },
        .lparen_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(lparen),
        .value = value,
        .rparen_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(rparen),
        .keyword_loc = *keyword_loc
    };

    return node;
}

/**
 * Allocate and initialize a new ElseNode node.
 */
static pm_else_node_t *
pm_else_node_create(pm_parser_t *parser, const pm_token_t *else_keyword, pm_statements_node_t *statements, const pm_token_t *end_keyword) {
    pm_else_node_t *node = PM_NODE_ALLOC(parser, pm_else_node_t);
    const uint8_t *end = NULL;
    if ((end_keyword->type == PM_TOKEN_NOT_PROVIDED) && (statements != NULL)) {
        end = statements->base.location.end;
    } else {
        end = end_keyword->end;
    }

    *node = (pm_else_node_t) {
        {
            .type = PM_ELSE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = else_keyword->start,
                .end = end,
            },
        },
        .else_keyword_loc = PM_LOCATION_TOKEN_VALUE(else_keyword),
        .statements = statements,
        .end_keyword_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(end_keyword)
    };

    return node;
}

/**
 * Allocate and initialize a new EmbeddedStatementsNode node.
 */
static pm_embedded_statements_node_t *
pm_embedded_statements_node_create(pm_parser_t *parser, const pm_token_t *opening, pm_statements_node_t *statements, const pm_token_t *closing) {
    pm_embedded_statements_node_t *node = PM_NODE_ALLOC(parser, pm_embedded_statements_node_t);

    *node = (pm_embedded_statements_node_t) {
        {
            .type = PM_EMBEDDED_STATEMENTS_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = opening->start,
                .end = closing->end
            }
        },
        .opening_loc = PM_LOCATION_TOKEN_VALUE(opening),
        .statements = statements,
        .closing_loc = PM_LOCATION_TOKEN_VALUE(closing)
    };

    return node;
}

/**
 * Allocate and initialize a new EmbeddedVariableNode node.
 */
static pm_embedded_variable_node_t *
pm_embedded_variable_node_create(pm_parser_t *parser, const pm_token_t *operator, pm_node_t *variable) {
    pm_embedded_variable_node_t *node = PM_NODE_ALLOC(parser, pm_embedded_variable_node_t);

    *node = (pm_embedded_variable_node_t) {
        {
            .type = PM_EMBEDDED_VARIABLE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = operator->start,
                .end = variable->location.end
            }
        },
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .variable = variable
    };

    return node;
}

/**
 * Allocate a new EnsureNode node.
 */
static pm_ensure_node_t *
pm_ensure_node_create(pm_parser_t *parser, const pm_token_t *ensure_keyword, pm_statements_node_t *statements, const pm_token_t *end_keyword) {
    pm_ensure_node_t *node = PM_NODE_ALLOC(parser, pm_ensure_node_t);

    *node = (pm_ensure_node_t) {
        {
            .type = PM_ENSURE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = ensure_keyword->start,
                .end = end_keyword->end
            },
        },
        .ensure_keyword_loc = PM_LOCATION_TOKEN_VALUE(ensure_keyword),
        .statements = statements,
        .end_keyword_loc = PM_LOCATION_TOKEN_VALUE(end_keyword)
    };

    return node;
}

/**
 * Allocate and initialize a new FalseNode node.
 */
static pm_false_node_t *
pm_false_node_create(pm_parser_t *parser, const pm_token_t *token) {
    assert(token->type == PM_TOKEN_KEYWORD_FALSE);
    pm_false_node_t *node = PM_NODE_ALLOC(parser, pm_false_node_t);

    *node = (pm_false_node_t) {{
        .type = PM_FALSE_NODE,
        .flags = PM_NODE_FLAG_STATIC_LITERAL,
        .node_id = PM_NODE_IDENTIFY(parser),
        .location = PM_LOCATION_TOKEN_VALUE(token)
    }};

    return node;
}

/**
 * Allocate and initialize a new find pattern node. The node list given in the
 * nodes parameter is guaranteed to have at least two nodes.
 */
static pm_find_pattern_node_t *
pm_find_pattern_node_create(pm_parser_t *parser, pm_node_list_t *nodes) {
    pm_find_pattern_node_t *node = PM_NODE_ALLOC(parser, pm_find_pattern_node_t);

    pm_node_t *left = nodes->nodes[0];
    assert(PM_NODE_TYPE_P(left, PM_SPLAT_NODE));
    pm_splat_node_t *left_splat_node = (pm_splat_node_t *) left;

    pm_node_t *right;

    if (nodes->size == 1) {
        right = (pm_node_t *) pm_missing_node_create(parser, left->location.end, left->location.end);
    } else {
        right = nodes->nodes[nodes->size - 1];
        assert(PM_NODE_TYPE_P(right, PM_SPLAT_NODE));
    }

#if PRISM_SERIALIZE_ONLY_SEMANTICS_FIELDS
    // FindPatternNode#right is typed as SplatNode in this case, so replace the potential MissingNode with a SplatNode.
    // The resulting AST will anyway be ignored, but this file still needs to compile.
    pm_splat_node_t *right_splat_node = PM_NODE_TYPE_P(right, PM_SPLAT_NODE) ? (pm_splat_node_t *) right : left_splat_node;
#else
    pm_node_t *right_splat_node = right;
#endif
    *node = (pm_find_pattern_node_t) {
        {
            .type = PM_FIND_PATTERN_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = left->location.start,
                .end = right->location.end,
            },
        },
        .constant = NULL,
        .left = left_splat_node,
        .right = right_splat_node,
        .requireds = { 0 },
        .opening_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE,
        .closing_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE
    };

    // For now we're going to just copy over each pointer manually. This could be
    // much more efficient, as we could instead resize the node list to only point
    // to 1...-1.
    for (size_t index = 1; index < nodes->size - 1; index++) {
        pm_node_list_append(&node->requireds, nodes->nodes[index]);
    }

    return node;
}

/**
 * Parse the value of a double, add appropriate errors if there is an issue, and
 * return the value that should be saved on the PM_FLOAT_NODE node.
 */
static double
pm_double_parse(pm_parser_t *parser, const pm_token_t *token) {
    ptrdiff_t diff = token->end - token->start;
    if (diff <= 0) return 0.0;

    // First, get a buffer of the content.
    size_t length = (size_t) diff;
    char *buffer = xmalloc(sizeof(char) * (length + 1));
    memcpy((void *) buffer, token->start, length);

    // Next, determine if we need to replace the decimal point because of
    // locale-specific options, and then normalize them if we have to.
    char decimal_point = *localeconv()->decimal_point;
    if (decimal_point != '.') {
        for (size_t index = 0; index < length; index++) {
            if (buffer[index] == '.') buffer[index] = decimal_point;
        }
    }

    // Next, handle underscores by removing them from the buffer.
    for (size_t index = 0; index < length; index++) {
        if (buffer[index] == '_') {
            memmove((void *) (buffer + index), (void *) (buffer + index + 1), length - index);
            length--;
        }
    }

    // Null-terminate the buffer so that strtod cannot read off the end.
    buffer[length] = '\0';

    // Now, call strtod to parse the value. Note that CRuby has their own
    // version of strtod which avoids locales. We're okay using the locale-aware
    // version because we've already validated through the parser that the token
    // is in a valid format.
    errno = 0;
    char *eptr;
    double value = strtod(buffer, &eptr);

    // This should never happen, because we've already checked that the token
    // is in a valid format. However it's good to be safe.
    if ((eptr != buffer + length) || (errno != 0 && errno != ERANGE)) {
        PM_PARSER_ERR_TOKEN_FORMAT_CONTENT(parser, (*token), PM_ERR_FLOAT_PARSE);
        xfree((void *) buffer);
        return 0.0;
    }

    // If errno is set, then it should only be ERANGE. At this point we need to
    // check if it's infinity (it should be).
    if (errno == ERANGE && PRISM_ISINF(value)) {
        int warn_width;
        const char *ellipsis;

        if (length > 20) {
            warn_width = 20;
            ellipsis = "...";
        } else {
            warn_width = (int) length;
            ellipsis = "";
        }

        pm_diagnostic_list_append_format(&parser->warning_list, token->start, token->end, PM_WARN_FLOAT_OUT_OF_RANGE, warn_width, (const char *) token->start, ellipsis);
        value = (value < 0.0) ? -HUGE_VAL : HUGE_VAL;
    }

    // Finally we can free the buffer and return the value.
    xfree((void *) buffer);
    return value;
}

/**
 * Allocate and initialize a new FloatNode node.
 */
static pm_float_node_t *
pm_float_node_create(pm_parser_t *parser, const pm_token_t *token) {
    assert(token->type == PM_TOKEN_FLOAT);
    pm_float_node_t *node = PM_NODE_ALLOC(parser, pm_float_node_t);

    *node = (pm_float_node_t) {
        {
            .type = PM_FLOAT_NODE,
            .flags = PM_NODE_FLAG_STATIC_LITERAL,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_TOKEN_VALUE(token)
        },
        .value = pm_double_parse(parser, token)
    };

    return node;
}

/**
 * Allocate and initialize a new FloatNode node from a FLOAT_IMAGINARY token.
 */
static pm_imaginary_node_t *
pm_float_node_imaginary_create(pm_parser_t *parser, const pm_token_t *token) {
    assert(token->type == PM_TOKEN_FLOAT_IMAGINARY);

    pm_imaginary_node_t *node = PM_NODE_ALLOC(parser, pm_imaginary_node_t);
    *node = (pm_imaginary_node_t) {
        {
            .type = PM_IMAGINARY_NODE,
            .flags = PM_NODE_FLAG_STATIC_LITERAL,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_TOKEN_VALUE(token)
        },
        .numeric = (pm_node_t *) pm_float_node_create(parser, &((pm_token_t) {
            .type = PM_TOKEN_FLOAT,
            .start = token->start,
            .end = token->end - 1
        }))
    };

    return node;
}

/**
 * Allocate and initialize a new RationalNode node from a FLOAT_RATIONAL token.
 */
static pm_rational_node_t *
pm_float_node_rational_create(pm_parser_t *parser, const pm_token_t *token) {
    assert(token->type == PM_TOKEN_FLOAT_RATIONAL);

    pm_rational_node_t *node = PM_NODE_ALLOC(parser, pm_rational_node_t);
    *node = (pm_rational_node_t) {
        {
            .type = PM_RATIONAL_NODE,
            .flags = PM_INTEGER_BASE_FLAGS_DECIMAL | PM_NODE_FLAG_STATIC_LITERAL,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_TOKEN_VALUE(token)
        },
        .numerator = { 0 },
        .denominator = { 0 }
    };

    const uint8_t *start = token->start;
    const uint8_t *end = token->end - 1; // r

    while (start < end && *start == '0') start++; // 0.1 -> .1
    while (end > start && end[-1] == '0') end--; // 1.0 -> 1.

    size_t length = (size_t) (end - start);
    if (length == 1) {
        node->denominator.value = 1;
        return node;
    }

    const uint8_t *point = memchr(start, '.', length);
    assert(point && "should have a decimal point");

    uint8_t *digits = malloc(length);
    if (digits == NULL) {
        fputs("[pm_float_node_rational_create] Failed to allocate memory", stderr);
        abort();
    }

    memcpy(digits, start, (unsigned long) (point - start));
    memcpy(digits + (point - start), point + 1, (unsigned long) (end - point - 1));
    pm_integer_parse(&node->numerator, PM_INTEGER_BASE_DEFAULT, digits, digits + length - 1);

    digits[0] = '1';
    if (end - point > 1) memset(digits + 1, '0', (size_t) (end - point - 1));
    pm_integer_parse(&node->denominator, PM_INTEGER_BASE_DEFAULT, digits, digits + (end - point));
    free(digits);

    pm_integers_reduce(&node->numerator, &node->denominator);
    return node;
}

/**
 * Allocate and initialize a new FloatNode node from a FLOAT_RATIONAL_IMAGINARY
 * token.
 */
static pm_imaginary_node_t *
pm_float_node_rational_imaginary_create(pm_parser_t *parser, const pm_token_t *token) {
    assert(token->type == PM_TOKEN_FLOAT_RATIONAL_IMAGINARY);

    pm_imaginary_node_t *node = PM_NODE_ALLOC(parser, pm_imaginary_node_t);
    *node = (pm_imaginary_node_t) {
        {
            .type = PM_IMAGINARY_NODE,
            .flags = PM_NODE_FLAG_STATIC_LITERAL,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_TOKEN_VALUE(token)
        },
        .numeric = (pm_node_t *) pm_float_node_rational_create(parser, &((pm_token_t) {
            .type = PM_TOKEN_FLOAT_RATIONAL,
            .start = token->start,
            .end = token->end - 1
        }))
    };

    return node;
}

/**
 * Allocate and initialize a new ForNode node.
 */
static pm_for_node_t *
pm_for_node_create(
    pm_parser_t *parser,
    pm_node_t *index,
    pm_node_t *collection,
    pm_statements_node_t *statements,
    const pm_token_t *for_keyword,
    const pm_token_t *in_keyword,
    const pm_token_t *do_keyword,
    const pm_token_t *end_keyword
) {
    pm_for_node_t *node = PM_NODE_ALLOC(parser, pm_for_node_t);

    *node = (pm_for_node_t) {
        {
            .type = PM_FOR_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = for_keyword->start,
                .end = end_keyword->end
            },
        },
        .index = index,
        .collection = collection,
        .statements = statements,
        .for_keyword_loc = PM_LOCATION_TOKEN_VALUE(for_keyword),
        .in_keyword_loc = PM_LOCATION_TOKEN_VALUE(in_keyword),
        .do_keyword_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(do_keyword),
        .end_keyword_loc = PM_LOCATION_TOKEN_VALUE(end_keyword)
    };

    return node;
}

/**
 * Allocate and initialize a new ForwardingArgumentsNode node.
 */
static pm_forwarding_arguments_node_t *
pm_forwarding_arguments_node_create(pm_parser_t *parser, const pm_token_t *token) {
    assert(token->type == PM_TOKEN_UDOT_DOT_DOT);
    pm_forwarding_arguments_node_t *node = PM_NODE_ALLOC(parser, pm_forwarding_arguments_node_t);

    *node = (pm_forwarding_arguments_node_t) {{
        .type = PM_FORWARDING_ARGUMENTS_NODE,
        .node_id = PM_NODE_IDENTIFY(parser),
        .location = PM_LOCATION_TOKEN_VALUE(token)
    }};

    return node;
}

/**
 * Allocate and initialize a new ForwardingParameterNode node.
 */
static pm_forwarding_parameter_node_t *
pm_forwarding_parameter_node_create(pm_parser_t *parser, const pm_token_t *token) {
    assert(token->type == PM_TOKEN_UDOT_DOT_DOT);
    pm_forwarding_parameter_node_t *node = PM_NODE_ALLOC(parser, pm_forwarding_parameter_node_t);

    *node = (pm_forwarding_parameter_node_t) {{
        .type = PM_FORWARDING_PARAMETER_NODE,
        .node_id = PM_NODE_IDENTIFY(parser),
        .location = PM_LOCATION_TOKEN_VALUE(token)
    }};

    return node;
}

/**
 * Allocate and initialize a new ForwardingSuper node.
 */
static pm_forwarding_super_node_t *
pm_forwarding_super_node_create(pm_parser_t *parser, const pm_token_t *token, pm_arguments_t *arguments) {
    assert(arguments->block == NULL || PM_NODE_TYPE_P(arguments->block, PM_BLOCK_NODE));
    assert(token->type == PM_TOKEN_KEYWORD_SUPER);
    pm_forwarding_super_node_t *node = PM_NODE_ALLOC(parser, pm_forwarding_super_node_t);

    pm_block_node_t *block = NULL;
    if (arguments->block != NULL) {
        block = (pm_block_node_t *) arguments->block;
    }

    *node = (pm_forwarding_super_node_t) {
        {
            .type = PM_FORWARDING_SUPER_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = token->start,
                .end = block != NULL ? block->base.location.end : token->end
            },
        },
        .block = block
    };

    return node;
}

/**
 * Allocate and initialize a new hash pattern node from an opening and closing
 * token.
 */
static pm_hash_pattern_node_t *
pm_hash_pattern_node_empty_create(pm_parser_t *parser, const pm_token_t *opening, const pm_token_t *closing) {
    pm_hash_pattern_node_t *node = PM_NODE_ALLOC(parser, pm_hash_pattern_node_t);

    *node = (pm_hash_pattern_node_t) {
        {
            .type = PM_HASH_PATTERN_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = opening->start,
                .end = closing->end
            },
        },
        .constant = NULL,
        .opening_loc = PM_LOCATION_TOKEN_VALUE(opening),
        .closing_loc = PM_LOCATION_TOKEN_VALUE(closing),
        .elements = { 0 },
        .rest = NULL
    };

    return node;
}

/**
 * Allocate and initialize a new hash pattern node.
 */
static pm_hash_pattern_node_t *
pm_hash_pattern_node_node_list_create(pm_parser_t *parser, pm_node_list_t *elements, pm_node_t *rest) {
    pm_hash_pattern_node_t *node = PM_NODE_ALLOC(parser, pm_hash_pattern_node_t);

    const uint8_t *start;
    const uint8_t *end;

    if (elements->size > 0) {
        if (rest) {
            start = elements->nodes[0]->location.start;
            end = rest->location.end;
        } else {
            start = elements->nodes[0]->location.start;
            end = elements->nodes[elements->size - 1]->location.end;
        }
    } else {
        assert(rest != NULL);
        start = rest->location.start;
        end = rest->location.end;
    }

    *node = (pm_hash_pattern_node_t) {
        {
            .type = PM_HASH_PATTERN_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = start,
                .end = end
            },
        },
        .constant = NULL,
        .elements = { 0 },
        .rest = rest,
        .opening_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE,
        .closing_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE
    };

    pm_node_t *element;
    PM_NODE_LIST_FOREACH(elements, index, element) {
        pm_node_list_append(&node->elements, element);
    }

    return node;
}

/**
 * Retrieve the name from a node that will become a global variable write node.
 */
static pm_constant_id_t
pm_global_variable_write_name(pm_parser_t *parser, const pm_node_t *target) {
    switch (PM_NODE_TYPE(target)) {
        case PM_GLOBAL_VARIABLE_READ_NODE:
            return ((pm_global_variable_read_node_t *) target)->name;
        case PM_BACK_REFERENCE_READ_NODE:
            return ((pm_back_reference_read_node_t *) target)->name;
        case PM_NUMBERED_REFERENCE_READ_NODE:
            // This will only ever happen in the event of a syntax error, but we
            // still need to provide something for the node.
            return pm_parser_constant_id_location(parser, target->location.start, target->location.end);
        default:
            assert(false && "unreachable");
            return (pm_constant_id_t) -1;
    }
}

/**
 * Allocate and initialize a new GlobalVariableAndWriteNode node.
 */
static pm_global_variable_and_write_node_t *
pm_global_variable_and_write_node_create(pm_parser_t *parser, pm_node_t *target, const pm_token_t *operator, pm_node_t *value) {
    assert(operator->type == PM_TOKEN_AMPERSAND_AMPERSAND_EQUAL);
    pm_global_variable_and_write_node_t *node = PM_NODE_ALLOC(parser, pm_global_variable_and_write_node_t);

    *node = (pm_global_variable_and_write_node_t) {
        {
            .type = PM_GLOBAL_VARIABLE_AND_WRITE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->location.start,
                .end = value->location.end
            }
        },
        .name = pm_global_variable_write_name(parser, target),
        .name_loc = target->location,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value
    };

    return node;
}

/**
 * Allocate and initialize a new GlobalVariableOperatorWriteNode node.
 */
static pm_global_variable_operator_write_node_t *
pm_global_variable_operator_write_node_create(pm_parser_t *parser, pm_node_t *target, const pm_token_t *operator, pm_node_t *value) {
    pm_global_variable_operator_write_node_t *node = PM_NODE_ALLOC(parser, pm_global_variable_operator_write_node_t);

    *node = (pm_global_variable_operator_write_node_t) {
        {
            .type = PM_GLOBAL_VARIABLE_OPERATOR_WRITE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->location.start,
                .end = value->location.end
            }
        },
        .name = pm_global_variable_write_name(parser, target),
        .name_loc = target->location,
        .binary_operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value,
        .binary_operator = pm_parser_constant_id_location(parser, operator->start, operator->end - 1)
    };

    return node;
}

/**
 * Allocate and initialize a new GlobalVariableOrWriteNode node.
 */
static pm_global_variable_or_write_node_t *
pm_global_variable_or_write_node_create(pm_parser_t *parser, pm_node_t *target, const pm_token_t *operator, pm_node_t *value) {
    assert(operator->type == PM_TOKEN_PIPE_PIPE_EQUAL);
    pm_global_variable_or_write_node_t *node = PM_NODE_ALLOC(parser, pm_global_variable_or_write_node_t);

    *node = (pm_global_variable_or_write_node_t) {
        {
            .type = PM_GLOBAL_VARIABLE_OR_WRITE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->location.start,
                .end = value->location.end
            }
        },
        .name = pm_global_variable_write_name(parser, target),
        .name_loc = target->location,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value
    };

    return node;
}

/**
 * Allocate a new GlobalVariableReadNode node.
 */
static pm_global_variable_read_node_t *
pm_global_variable_read_node_create(pm_parser_t *parser, const pm_token_t *name) {
    pm_global_variable_read_node_t *node = PM_NODE_ALLOC(parser, pm_global_variable_read_node_t);

    *node = (pm_global_variable_read_node_t) {
        {
            .type = PM_GLOBAL_VARIABLE_READ_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_TOKEN_VALUE(name),
        },
        .name = pm_parser_constant_id_token(parser, name)
    };

    return node;
}

/**
 * Allocate and initialize a new synthesized GlobalVariableReadNode node.
 */
static pm_global_variable_read_node_t *
pm_global_variable_read_node_synthesized_create(pm_parser_t *parser, pm_constant_id_t name) {
    pm_global_variable_read_node_t *node = PM_NODE_ALLOC(parser, pm_global_variable_read_node_t);

    *node = (pm_global_variable_read_node_t) {
        {
            .type = PM_GLOBAL_VARIABLE_READ_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_NULL_VALUE(parser)
        },
        .name = name
    };

    return node;
}

/**
 * Allocate and initialize a new GlobalVariableWriteNode node.
 */
static pm_global_variable_write_node_t *
pm_global_variable_write_node_create(pm_parser_t *parser, pm_node_t *target, const pm_token_t *operator, pm_node_t *value) {
    pm_global_variable_write_node_t *node = PM_NODE_ALLOC(parser, pm_global_variable_write_node_t);

    *node = (pm_global_variable_write_node_t) {
        {
            .type = PM_GLOBAL_VARIABLE_WRITE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .flags = pm_implicit_array_write_flags(value, PM_WRITE_NODE_FLAGS_IMPLICIT_ARRAY),
            .location = {
                .start = target->location.start,
                .end = value->location.end
            },
        },
        .name = pm_global_variable_write_name(parser, target),
        .name_loc = PM_LOCATION_NODE_VALUE(target),
        .operator_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(operator),
        .value = value
    };

    return node;
}

/**
 * Allocate and initialize a new synthesized GlobalVariableWriteNode node.
 */
static pm_global_variable_write_node_t *
pm_global_variable_write_node_synthesized_create(pm_parser_t *parser, pm_constant_id_t name, pm_node_t *value) {
    pm_global_variable_write_node_t *node = PM_NODE_ALLOC(parser, pm_global_variable_write_node_t);

    *node = (pm_global_variable_write_node_t) {
        {
            .type = PM_GLOBAL_VARIABLE_WRITE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_NULL_VALUE(parser)
        },
        .name = name,
        .name_loc = PM_LOCATION_NULL_VALUE(parser),
        .operator_loc = PM_LOCATION_NULL_VALUE(parser),
        .value = value
    };

    return node;
}

/**
 * Allocate a new HashNode node.
 */
static pm_hash_node_t *
pm_hash_node_create(pm_parser_t *parser, const pm_token_t *opening) {
    assert(opening != NULL);
    pm_hash_node_t *node = PM_NODE_ALLOC(parser, pm_hash_node_t);

    *node = (pm_hash_node_t) {
        {
            .type = PM_HASH_NODE,
            .flags = PM_NODE_FLAG_STATIC_LITERAL,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_TOKEN_VALUE(opening)
        },
        .opening_loc = PM_LOCATION_TOKEN_VALUE(opening),
        .closing_loc = PM_LOCATION_NULL_VALUE(parser),
        .elements = { 0 }
    };

    return node;
}

/**
 * Append a new element to a hash node.
 */
static inline void
pm_hash_node_elements_append(pm_hash_node_t *hash, pm_node_t *element) {
    pm_node_list_append(&hash->elements, element);

    bool static_literal = PM_NODE_TYPE_P(element, PM_ASSOC_NODE);
    if (static_literal) {
        pm_assoc_node_t *assoc = (pm_assoc_node_t *) element;
        static_literal = !PM_NODE_TYPE_P(assoc->key, PM_ARRAY_NODE) && !PM_NODE_TYPE_P(assoc->key, PM_HASH_NODE) && !PM_NODE_TYPE_P(assoc->key, PM_RANGE_NODE);
        static_literal = static_literal && PM_NODE_FLAG_P(assoc->key, PM_NODE_FLAG_STATIC_LITERAL);
        static_literal = static_literal && PM_NODE_FLAG_P(assoc, PM_NODE_FLAG_STATIC_LITERAL);
    }

    if (!static_literal) {
        pm_node_flag_unset((pm_node_t *)hash, PM_NODE_FLAG_STATIC_LITERAL);
    }
}

static inline void
pm_hash_node_closing_loc_set(pm_hash_node_t *hash, pm_token_t *token) {
    hash->base.location.end = token->end;
    hash->closing_loc = PM_LOCATION_TOKEN_VALUE(token);
}

/**
 * Allocate a new IfNode node.
 */
static pm_if_node_t *
pm_if_node_create(pm_parser_t *parser,
    const pm_token_t *if_keyword,
    pm_node_t *predicate,
    const pm_token_t *then_keyword,
    pm_statements_node_t *statements,
    pm_node_t *subsequent,
    const pm_token_t *end_keyword
) {
    pm_conditional_predicate(parser, predicate, PM_CONDITIONAL_PREDICATE_TYPE_CONDITIONAL);
    pm_if_node_t *node = PM_NODE_ALLOC(parser, pm_if_node_t);

    const uint8_t *end;
    if (end_keyword->type != PM_TOKEN_NOT_PROVIDED) {
        end = end_keyword->end;
    } else if (subsequent != NULL) {
        end = subsequent->location.end;
    } else if (pm_statements_node_body_length(statements) != 0) {
        end = statements->base.location.end;
    } else {
        end = predicate->location.end;
    }

    *node = (pm_if_node_t) {
        {
            .type = PM_IF_NODE,
            .flags = PM_NODE_FLAG_NEWLINE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = if_keyword->start,
                .end = end
            },
        },
        .if_keyword_loc = PM_LOCATION_TOKEN_VALUE(if_keyword),
        .predicate = predicate,
        .then_keyword_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(then_keyword),
        .statements = statements,
        .subsequent = subsequent,
        .end_keyword_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(end_keyword)
    };

    return node;
}

/**
 * Allocate and initialize new IfNode node in the modifier form.
 */
static pm_if_node_t *
pm_if_node_modifier_create(pm_parser_t *parser, pm_node_t *statement, const pm_token_t *if_keyword, pm_node_t *predicate) {
    pm_conditional_predicate(parser, predicate, PM_CONDITIONAL_PREDICATE_TYPE_CONDITIONAL);
    pm_if_node_t *node = PM_NODE_ALLOC(parser, pm_if_node_t);

    pm_statements_node_t *statements = pm_statements_node_create(parser);
    pm_statements_node_body_append(parser, statements, statement, true);

    *node = (pm_if_node_t) {
        {
            .type = PM_IF_NODE,
            .flags = PM_NODE_FLAG_NEWLINE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = statement->location.start,
                .end = predicate->location.end
            },
        },
        .if_keyword_loc = PM_LOCATION_TOKEN_VALUE(if_keyword),
        .predicate = predicate,
        .then_keyword_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE,
        .statements = statements,
        .subsequent = NULL,
        .end_keyword_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE
    };

    return node;
}

/**
 * Allocate and initialize an if node from a ternary expression.
 */
static pm_if_node_t *
pm_if_node_ternary_create(pm_parser_t *parser, pm_node_t *predicate, const pm_token_t *qmark, pm_node_t *true_expression, const pm_token_t *colon, pm_node_t *false_expression) {
    pm_assert_value_expression(parser, predicate);
    pm_conditional_predicate(parser, predicate, PM_CONDITIONAL_PREDICATE_TYPE_CONDITIONAL);

    pm_statements_node_t *if_statements = pm_statements_node_create(parser);
    pm_statements_node_body_append(parser, if_statements, true_expression, true);

    pm_statements_node_t *else_statements = pm_statements_node_create(parser);
    pm_statements_node_body_append(parser, else_statements, false_expression, true);

    pm_token_t end_keyword = not_provided(parser);
    pm_else_node_t *else_node = pm_else_node_create(parser, colon, else_statements, &end_keyword);

    pm_if_node_t *node = PM_NODE_ALLOC(parser, pm_if_node_t);

    *node = (pm_if_node_t) {
        {
            .type = PM_IF_NODE,
            .flags = PM_NODE_FLAG_NEWLINE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = predicate->location.start,
                .end = false_expression->location.end,
            },
        },
        .if_keyword_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE,
        .predicate = predicate,
        .then_keyword_loc = PM_LOCATION_TOKEN_VALUE(qmark),
        .statements = if_statements,
        .subsequent = (pm_node_t *) else_node,
        .end_keyword_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE
    };

    return node;

}

static inline void
pm_if_node_end_keyword_loc_set(pm_if_node_t *node, const pm_token_t *keyword) {
    node->base.location.end = keyword->end;
    node->end_keyword_loc = PM_LOCATION_TOKEN_VALUE(keyword);
}

static inline void
pm_else_node_end_keyword_loc_set(pm_else_node_t *node, const pm_token_t *keyword) {
    node->base.location.end = keyword->end;
    node->end_keyword_loc = PM_LOCATION_TOKEN_VALUE(keyword);
}

/**
 * Allocate and initialize a new ImplicitNode node.
 */
static pm_implicit_node_t *
pm_implicit_node_create(pm_parser_t *parser, pm_node_t *value) {
    pm_implicit_node_t *node = PM_NODE_ALLOC(parser, pm_implicit_node_t);

    *node = (pm_implicit_node_t) {
        {
            .type = PM_IMPLICIT_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = value->location
        },
        .value = value
    };

    return node;
}

/**
 * Allocate and initialize a new ImplicitRestNode node.
 */
static pm_implicit_rest_node_t *
pm_implicit_rest_node_create(pm_parser_t *parser, const pm_token_t *token) {
    assert(token->type == PM_TOKEN_COMMA);

    pm_implicit_rest_node_t *node = PM_NODE_ALLOC(parser, pm_implicit_rest_node_t);

    *node = (pm_implicit_rest_node_t) {
        {
            .type = PM_IMPLICIT_REST_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_TOKEN_VALUE(token)
        }
    };

    return node;
}

/**
 * Allocate and initialize a new IntegerNode node.
 */
static pm_integer_node_t *
pm_integer_node_create(pm_parser_t *parser, pm_node_flags_t base, const pm_token_t *token) {
    assert(token->type == PM_TOKEN_INTEGER);
    pm_integer_node_t *node = PM_NODE_ALLOC(parser, pm_integer_node_t);

    *node = (pm_integer_node_t) {
        {
            .type = PM_INTEGER_NODE,
            .flags = base | PM_NODE_FLAG_STATIC_LITERAL,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_TOKEN_VALUE(token)
        },
        .value = { 0 }
    };

    pm_integer_base_t integer_base = PM_INTEGER_BASE_DECIMAL;
    switch (base) {
        case PM_INTEGER_BASE_FLAGS_BINARY: integer_base = PM_INTEGER_BASE_BINARY; break;
        case PM_INTEGER_BASE_FLAGS_OCTAL: integer_base = PM_INTEGER_BASE_OCTAL; break;
        case PM_INTEGER_BASE_FLAGS_DECIMAL: break;
        case PM_INTEGER_BASE_FLAGS_HEXADECIMAL: integer_base = PM_INTEGER_BASE_HEXADECIMAL; break;
        default: assert(false && "unreachable"); break;
    }

    pm_integer_parse(&node->value, integer_base, token->start, token->end);
    return node;
}

/**
 * Allocate and initialize a new IntegerNode node from an INTEGER_IMAGINARY
 * token.
 */
static pm_imaginary_node_t *
pm_integer_node_imaginary_create(pm_parser_t *parser, pm_node_flags_t base, const pm_token_t *token) {
    assert(token->type == PM_TOKEN_INTEGER_IMAGINARY);

    pm_imaginary_node_t *node = PM_NODE_ALLOC(parser, pm_imaginary_node_t);
    *node = (pm_imaginary_node_t) {
        {
            .type = PM_IMAGINARY_NODE,
            .flags = PM_NODE_FLAG_STATIC_LITERAL,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_TOKEN_VALUE(token)
        },
        .numeric = (pm_node_t *) pm_integer_node_create(parser, base, &((pm_token_t) {
            .type = PM_TOKEN_INTEGER,
            .start = token->start,
            .end = token->end - 1
        }))
    };

    return node;
}

/**
 * Allocate and initialize a new RationalNode node from an INTEGER_RATIONAL
 * token.
 */
static pm_rational_node_t *
pm_integer_node_rational_create(pm_parser_t *parser, pm_node_flags_t base, const pm_token_t *token) {
    assert(token->type == PM_TOKEN_INTEGER_RATIONAL);

    pm_rational_node_t *node = PM_NODE_ALLOC(parser, pm_rational_node_t);
    *node = (pm_rational_node_t) {
        {
            .type = PM_RATIONAL_NODE,
            .flags = base | PM_NODE_FLAG_STATIC_LITERAL,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_TOKEN_VALUE(token)
        },
        .numerator = { 0 },
        .denominator = { .value = 1, 0 }
    };

    pm_integer_base_t integer_base = PM_INTEGER_BASE_DECIMAL;
    switch (base) {
        case PM_INTEGER_BASE_FLAGS_BINARY: integer_base = PM_INTEGER_BASE_BINARY; break;
        case PM_INTEGER_BASE_FLAGS_OCTAL: integer_base = PM_INTEGER_BASE_OCTAL; break;
        case PM_INTEGER_BASE_FLAGS_DECIMAL: break;
        case PM_INTEGER_BASE_FLAGS_HEXADECIMAL: integer_base = PM_INTEGER_BASE_HEXADECIMAL; break;
        default: assert(false && "unreachable"); break;
    }

    pm_integer_parse(&node->numerator, integer_base, token->start, token->end - 1);

    return node;
}

/**
 * Allocate and initialize a new IntegerNode node from an
 * INTEGER_RATIONAL_IMAGINARY token.
 */
static pm_imaginary_node_t *
pm_integer_node_rational_imaginary_create(pm_parser_t *parser, pm_node_flags_t base, const pm_token_t *token) {
    assert(token->type == PM_TOKEN_INTEGER_RATIONAL_IMAGINARY);

    pm_imaginary_node_t *node = PM_NODE_ALLOC(parser, pm_imaginary_node_t);
    *node = (pm_imaginary_node_t) {
        {
            .type = PM_IMAGINARY_NODE,
            .flags = PM_NODE_FLAG_STATIC_LITERAL,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_TOKEN_VALUE(token)
        },
        .numeric = (pm_node_t *) pm_integer_node_rational_create(parser, base, &((pm_token_t) {
            .type = PM_TOKEN_INTEGER_RATIONAL,
            .start = token->start,
            .end = token->end - 1
        }))
    };

    return node;
}

/**
 * Allocate and initialize a new InNode node.
 */
static pm_in_node_t *
pm_in_node_create(pm_parser_t *parser, pm_node_t *pattern, pm_statements_node_t *statements, const pm_token_t *in_keyword, const pm_token_t *then_keyword) {
    pm_in_node_t *node = PM_NODE_ALLOC(parser, pm_in_node_t);

    const uint8_t *end;
    if (statements != NULL) {
        end = statements->base.location.end;
    } else if (then_keyword->type != PM_TOKEN_NOT_PROVIDED) {
        end = then_keyword->end;
    } else {
        end = pattern->location.end;
    }

    *node = (pm_in_node_t) {
        {
            .type = PM_IN_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = in_keyword->start,
                .end = end
            },
        },
        .pattern = pattern,
        .statements = statements,
        .in_loc = PM_LOCATION_TOKEN_VALUE(in_keyword),
        .then_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(then_keyword)
    };

    return node;
}

/**
 * Allocate and initialize a new InstanceVariableAndWriteNode node.
 */
static pm_instance_variable_and_write_node_t *
pm_instance_variable_and_write_node_create(pm_parser_t *parser, pm_instance_variable_read_node_t *target, const pm_token_t *operator, pm_node_t *value) {
    assert(operator->type == PM_TOKEN_AMPERSAND_AMPERSAND_EQUAL);
    pm_instance_variable_and_write_node_t *node = PM_NODE_ALLOC(parser, pm_instance_variable_and_write_node_t);

    *node = (pm_instance_variable_and_write_node_t) {
        {
            .type = PM_INSTANCE_VARIABLE_AND_WRITE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->base.location.start,
                .end = value->location.end
            }
        },
        .name = target->name,
        .name_loc = target->base.location,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value
    };

    return node;
}

/**
 * Allocate and initialize a new InstanceVariableOperatorWriteNode node.
 */
static pm_instance_variable_operator_write_node_t *
pm_instance_variable_operator_write_node_create(pm_parser_t *parser, pm_instance_variable_read_node_t *target, const pm_token_t *operator, pm_node_t *value) {
    pm_instance_variable_operator_write_node_t *node = PM_NODE_ALLOC(parser, pm_instance_variable_operator_write_node_t);

    *node = (pm_instance_variable_operator_write_node_t) {
        {
            .type = PM_INSTANCE_VARIABLE_OPERATOR_WRITE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->base.location.start,
                .end = value->location.end
            }
        },
        .name = target->name,
        .name_loc = target->base.location,
        .binary_operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value,
        .binary_operator = pm_parser_constant_id_location(parser, operator->start, operator->end - 1)
    };

    return node;
}

/**
 * Allocate and initialize a new InstanceVariableOrWriteNode node.
 */
static pm_instance_variable_or_write_node_t *
pm_instance_variable_or_write_node_create(pm_parser_t *parser, pm_instance_variable_read_node_t *target, const pm_token_t *operator, pm_node_t *value) {
    assert(operator->type == PM_TOKEN_PIPE_PIPE_EQUAL);
    pm_instance_variable_or_write_node_t *node = PM_NODE_ALLOC(parser, pm_instance_variable_or_write_node_t);

    *node = (pm_instance_variable_or_write_node_t) {
        {
            .type = PM_INSTANCE_VARIABLE_OR_WRITE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->base.location.start,
                .end = value->location.end
            }
        },
        .name = target->name,
        .name_loc = target->base.location,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value
    };

    return node;
}

/**
 * Allocate and initialize a new InstanceVariableReadNode node.
 */
static pm_instance_variable_read_node_t *
pm_instance_variable_read_node_create(pm_parser_t *parser, const pm_token_t *token) {
    assert(token->type == PM_TOKEN_INSTANCE_VARIABLE);
    pm_instance_variable_read_node_t *node = PM_NODE_ALLOC(parser, pm_instance_variable_read_node_t);

    *node = (pm_instance_variable_read_node_t) {
        {
            .type = PM_INSTANCE_VARIABLE_READ_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_TOKEN_VALUE(token)
        },
        .name = pm_parser_constant_id_token(parser, token)
    };

    return node;
}

/**
 * Initialize a new InstanceVariableWriteNode node from an InstanceVariableRead
 * node.
 */
static pm_instance_variable_write_node_t *
pm_instance_variable_write_node_create(pm_parser_t *parser, pm_instance_variable_read_node_t *read_node, pm_token_t *operator, pm_node_t *value) {
    pm_instance_variable_write_node_t *node = PM_NODE_ALLOC(parser, pm_instance_variable_write_node_t);
    *node = (pm_instance_variable_write_node_t) {
        {
            .type = PM_INSTANCE_VARIABLE_WRITE_NODE,
            .flags = pm_implicit_array_write_flags(value, PM_WRITE_NODE_FLAGS_IMPLICIT_ARRAY),
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = read_node->base.location.start,
                .end = value->location.end
            }
        },
        .name = read_node->name,
        .name_loc = PM_LOCATION_NODE_BASE_VALUE(read_node),
        .operator_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(operator),
        .value = value
    };

    return node;
}

/**
 * Append a part into a list of string parts. Importantly this handles nested
 * interpolated strings by not necessarily removing the marker for static
 * literals.
 */
static void
pm_interpolated_node_append(pm_node_t *node, pm_node_list_t *parts, pm_node_t *part) {
    switch (PM_NODE_TYPE(part)) {
        case PM_STRING_NODE:
            pm_node_flag_set(part, PM_NODE_FLAG_STATIC_LITERAL | PM_STRING_FLAGS_FROZEN);
            break;
        case PM_EMBEDDED_STATEMENTS_NODE: {
            pm_embedded_statements_node_t *cast = (pm_embedded_statements_node_t *) part;
            pm_node_t *embedded = (cast->statements != NULL && cast->statements->body.size == 1) ? cast->statements->body.nodes[0] : NULL;

            if (embedded == NULL) {
                // If there are no statements or more than one statement, then
                // we lose the static literal flag.
                pm_node_flag_unset(node, PM_NODE_FLAG_STATIC_LITERAL);
            } else if (PM_NODE_TYPE_P(embedded, PM_STRING_NODE)) {
                // If the embedded statement is a string, then we can keep the
                // static literal flag and mark the string as frozen.
                pm_node_flag_set(embedded, PM_NODE_FLAG_STATIC_LITERAL | PM_STRING_FLAGS_FROZEN);
            } else if (PM_NODE_TYPE_P(embedded, PM_INTERPOLATED_STRING_NODE) && PM_NODE_FLAG_P(embedded, PM_NODE_FLAG_STATIC_LITERAL)) {
                // If the embedded statement is an interpolated string and it's
                // a static literal, then we can keep the static literal flag.
            } else {
                // Otherwise we lose the static literal flag.
                pm_node_flag_unset(node, PM_NODE_FLAG_STATIC_LITERAL);
            }

            break;
        }
        case PM_EMBEDDED_VARIABLE_NODE:
            pm_node_flag_unset((pm_node_t *) node, PM_NODE_FLAG_STATIC_LITERAL);
            break;
        default:
            assert(false && "unexpected node type");
            break;
    }

    pm_node_list_append(parts, part);
}

/**
 * Allocate a new InterpolatedRegularExpressionNode node.
 */
static pm_interpolated_regular_expression_node_t *
pm_interpolated_regular_expression_node_create(pm_parser_t *parser, const pm_token_t *opening) {
    pm_interpolated_regular_expression_node_t *node = PM_NODE_ALLOC(parser, pm_interpolated_regular_expression_node_t);

    *node = (pm_interpolated_regular_expression_node_t) {
        {
            .type = PM_INTERPOLATED_REGULAR_EXPRESSION_NODE,
            .flags = PM_NODE_FLAG_STATIC_LITERAL,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = opening->start,
                .end = NULL,
            },
        },
        .opening_loc = PM_LOCATION_TOKEN_VALUE(opening),
        .closing_loc = PM_LOCATION_TOKEN_VALUE(opening),
        .parts = { 0 }
    };

    return node;
}

static inline void
pm_interpolated_regular_expression_node_append(pm_interpolated_regular_expression_node_t *node, pm_node_t *part) {
    if (node->base.location.start > part->location.start) {
        node->base.location.start = part->location.start;
    }
    if (node->base.location.end < part->location.end) {
        node->base.location.end = part->location.end;
    }

    pm_interpolated_node_append((pm_node_t *) node, &node->parts, part);
}

static inline void
pm_interpolated_regular_expression_node_closing_set(pm_parser_t *parser, pm_interpolated_regular_expression_node_t *node, const pm_token_t *closing) {
    node->closing_loc = PM_LOCATION_TOKEN_VALUE(closing);
    node->base.location.end = closing->end;
    pm_node_flag_set((pm_node_t *) node, pm_regular_expression_flags_create(parser, closing));
}

/**
 * Append a part to an InterpolatedStringNode node.
 *
 * This has some somewhat complicated semantics, because we need to update
 * multiple flags that have somewhat confusing interactions.
 *
 * PM_NODE_FLAG_STATIC_LITERAL indicates that the node should be treated as a
 * single static literal string that can be pushed onto the stack on its own.
 * Note that this doesn't necessarily mean that the string will be frozen or
 * not; the instructions in CRuby will be either putobject or putstring,
 * depending on the combination of `--enable-frozen-string-literal`,
 * `# frozen_string_literal: true`, and whether or not there is interpolation.
 *
 * PM_INTERPOLATED_STRING_NODE_FLAGS_FROZEN indicates that the string should be
 * explicitly frozen. This will only happen if the string is comprised entirely
 * of string parts that are themselves static literals and frozen.
 *
 * PM_INTERPOLATED_STRING_NODE_FLAGS_MUTABLE indicates that the string should
 * be explicitly marked as mutable. This will happen from
 * `--disable-frozen-string-literal` or `# frozen_string_literal: false`. This
 * is necessary to indicate that the string should be left up to the runtime,
 * which could potentially use a chilled string otherwise.
 */
static inline void
pm_interpolated_string_node_append(pm_interpolated_string_node_t *node, pm_node_t *part) {
#define CLEAR_FLAGS(node) \
    node->base.flags = (pm_node_flags_t) (node->base.flags & ~(PM_NODE_FLAG_STATIC_LITERAL | PM_INTERPOLATED_STRING_NODE_FLAGS_FROZEN | PM_INTERPOLATED_STRING_NODE_FLAGS_MUTABLE))

#define MUTABLE_FLAGS(node) \
    node->base.flags = (pm_node_flags_t) ((node->base.flags | PM_INTERPOLATED_STRING_NODE_FLAGS_MUTABLE) & ~PM_INTERPOLATED_STRING_NODE_FLAGS_FROZEN);

    if (node->parts.size == 0 && node->opening_loc.start == NULL) {
        node->base.location.start = part->location.start;
    }

    node->base.location.end = MAX(node->base.location.end, part->location.end);

    switch (PM_NODE_TYPE(part)) {
        case PM_STRING_NODE:
            part->flags = (pm_node_flags_t) ((part->flags | PM_NODE_FLAG_STATIC_LITERAL | PM_STRING_FLAGS_FROZEN) & ~PM_STRING_FLAGS_MUTABLE);
            break;
        case PM_INTERPOLATED_STRING_NODE:
            if (PM_NODE_FLAG_P(part, PM_NODE_FLAG_STATIC_LITERAL)) {
                // If the string that we're concatenating is a static literal,
                // then we can keep the static literal flag for this string.
            } else {
                // Otherwise, we lose the static literal flag here and we should
                // also clear the mutability flags.
                CLEAR_FLAGS(node);
            }
            break;
        case PM_EMBEDDED_STATEMENTS_NODE: {
            pm_embedded_statements_node_t *cast = (pm_embedded_statements_node_t *) part;
            pm_node_t *embedded = (cast->statements != NULL && cast->statements->body.size == 1) ? cast->statements->body.nodes[0] : NULL;

            if (embedded == NULL) {
                // If we're embedding multiple statements or no statements, then
                // the string is not longer a static literal.
                CLEAR_FLAGS(node);
            } else if (PM_NODE_TYPE_P(embedded, PM_STRING_NODE)) {
                // If the embedded statement is a string, then we can make that
                // string as frozen and static literal, and not touch the static
                // literal status of this string.
                embedded->flags = (pm_node_flags_t) ((embedded->flags | PM_NODE_FLAG_STATIC_LITERAL | PM_STRING_FLAGS_FROZEN) & ~PM_STRING_FLAGS_MUTABLE);

                if (PM_NODE_FLAG_P(node, PM_NODE_FLAG_STATIC_LITERAL)) {
                    MUTABLE_FLAGS(node);
                }
            } else if (PM_NODE_TYPE_P(embedded, PM_INTERPOLATED_STRING_NODE) && PM_NODE_FLAG_P(embedded, PM_NODE_FLAG_STATIC_LITERAL)) {
                // If the embedded statement is an interpolated string, but that
                // string is marked as static literal, then we can keep our
                // static literal status for this string.
                if (PM_NODE_FLAG_P(node, PM_NODE_FLAG_STATIC_LITERAL)) {
                    MUTABLE_FLAGS(node);
                }
            } else {
                // In all other cases, we lose the static literal flag here and
                // become mutable.
                CLEAR_FLAGS(node);
            }

            break;
        }
        case PM_EMBEDDED_VARIABLE_NODE:
            // Embedded variables clear static literal, which means we also
            // should clear the mutability flags.
            CLEAR_FLAGS(node);
            break;
        case PM_X_STRING_NODE:
        case PM_INTERPOLATED_X_STRING_NODE:
            // If this is an x string, then this is a syntax error. But we want
            // to handle it here so that we don't fail the assertion.
            CLEAR_FLAGS(node);
            break;
        default:
            assert(false && "unexpected node type");
            break;
    }

    pm_node_list_append(&node->parts, part);

#undef CLEAR_FLAGS
#undef MUTABLE_FLAGS
}

/**
 * Allocate and initialize a new InterpolatedStringNode node.
 */
static pm_interpolated_string_node_t *
pm_interpolated_string_node_create(pm_parser_t *parser, const pm_token_t *opening, const pm_node_list_t *parts, const pm_token_t *closing) {
    pm_interpolated_string_node_t *node = PM_NODE_ALLOC(parser, pm_interpolated_string_node_t);
    pm_node_flags_t flags = PM_NODE_FLAG_STATIC_LITERAL;

    switch (parser->frozen_string_literal) {
        case PM_OPTIONS_FROZEN_STRING_LITERAL_DISABLED:
            flags |= PM_INTERPOLATED_STRING_NODE_FLAGS_MUTABLE;
            break;
        case PM_OPTIONS_FROZEN_STRING_LITERAL_ENABLED:
            flags |= PM_INTERPOLATED_STRING_NODE_FLAGS_FROZEN;
            break;
    }

    *node = (pm_interpolated_string_node_t) {
        {
            .type = PM_INTERPOLATED_STRING_NODE,
            .flags = flags,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = opening->start,
                .end = closing->end,
            },
        },
        .opening_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(opening),
        .closing_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(closing),
        .parts = { 0 }
    };

    if (parts != NULL) {
        pm_node_t *part;
        PM_NODE_LIST_FOREACH(parts, index, part) {
            pm_interpolated_string_node_append(node, part);
        }
    }

    return node;
}

/**
 * Set the closing token of the given InterpolatedStringNode node.
 */
static void
pm_interpolated_string_node_closing_set(pm_interpolated_string_node_t *node, const pm_token_t *closing) {
    node->closing_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(closing);
    node->base.location.end = closing->end;
}

static void
pm_interpolated_symbol_node_append(pm_interpolated_symbol_node_t *node, pm_node_t *part) {
    if (node->parts.size == 0 && node->opening_loc.start == NULL) {
        node->base.location.start = part->location.start;
    }

    pm_interpolated_node_append((pm_node_t *) node, &node->parts, part);
    node->base.location.end = MAX(node->base.location.end, part->location.end);
}

static void
pm_interpolated_symbol_node_closing_loc_set(pm_interpolated_symbol_node_t *node, const pm_token_t *closing) {
    node->closing_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(closing);
    node->base.location.end = closing->end;
}

/**
 * Allocate and initialize a new InterpolatedSymbolNode node.
 */
static pm_interpolated_symbol_node_t *
pm_interpolated_symbol_node_create(pm_parser_t *parser, const pm_token_t *opening, const pm_node_list_t *parts, const pm_token_t *closing) {
    pm_interpolated_symbol_node_t *node = PM_NODE_ALLOC(parser, pm_interpolated_symbol_node_t);

    *node = (pm_interpolated_symbol_node_t) {
        {
            .type = PM_INTERPOLATED_SYMBOL_NODE,
            .flags = PM_NODE_FLAG_STATIC_LITERAL,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = opening->start,
                .end = closing->end,
            },
        },
        .opening_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(opening),
        .closing_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(closing),
        .parts = { 0 }
    };

    if (parts != NULL) {
        pm_node_t *part;
        PM_NODE_LIST_FOREACH(parts, index, part) {
            pm_interpolated_symbol_node_append(node, part);
        }
    }

    return node;
}

/**
 * Allocate a new InterpolatedXStringNode node.
 */
static pm_interpolated_x_string_node_t *
pm_interpolated_xstring_node_create(pm_parser_t *parser, const pm_token_t *opening, const pm_token_t *closing) {
    pm_interpolated_x_string_node_t *node = PM_NODE_ALLOC(parser, pm_interpolated_x_string_node_t);

    *node = (pm_interpolated_x_string_node_t) {
        {
            .type = PM_INTERPOLATED_X_STRING_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = opening->start,
                .end = closing->end
            },
        },
        .opening_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(opening),
        .closing_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(closing),
        .parts = { 0 }
    };

    return node;
}

static inline void
pm_interpolated_xstring_node_append(pm_interpolated_x_string_node_t *node, pm_node_t *part) {
    pm_interpolated_node_append((pm_node_t *) node, &node->parts, part);
    node->base.location.end = part->location.end;
}

static inline void
pm_interpolated_xstring_node_closing_set(pm_interpolated_x_string_node_t *node, const pm_token_t *closing) {
    node->closing_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(closing);
    node->base.location.end = closing->end;
}

/**
 * Create a local variable read that is reading the implicit 'it' variable.
 */
static pm_it_local_variable_read_node_t *
pm_it_local_variable_read_node_create(pm_parser_t *parser, const pm_token_t *name) {
    pm_it_local_variable_read_node_t *node = PM_NODE_ALLOC(parser, pm_it_local_variable_read_node_t);

    *node = (pm_it_local_variable_read_node_t) {
        {
            .type = PM_IT_LOCAL_VARIABLE_READ_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_TOKEN_VALUE(name)
        }
    };

    return node;
}

/**
 * Allocate and initialize a new ItParametersNode node.
 */
static pm_it_parameters_node_t *
pm_it_parameters_node_create(pm_parser_t *parser, const pm_token_t *opening, const pm_token_t *closing) {
    pm_it_parameters_node_t *node = PM_NODE_ALLOC(parser, pm_it_parameters_node_t);

    *node = (pm_it_parameters_node_t) {
        {
            .type = PM_IT_PARAMETERS_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = opening->start,
                .end = closing->end
            }
        }
    };

    return node;
}

/**
 * Allocate a new KeywordHashNode node.
 */
static pm_keyword_hash_node_t *
pm_keyword_hash_node_create(pm_parser_t *parser) {
    pm_keyword_hash_node_t *node = PM_NODE_ALLOC(parser, pm_keyword_hash_node_t);

    *node = (pm_keyword_hash_node_t) {
        .base = {
            .type = PM_KEYWORD_HASH_NODE,
            .flags = PM_KEYWORD_HASH_NODE_FLAGS_SYMBOL_KEYS,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE
        },
        .elements = { 0 }
    };

    return node;
}

/**
 * Append an element to a KeywordHashNode node.
 */
static void
pm_keyword_hash_node_elements_append(pm_keyword_hash_node_t *hash, pm_node_t *element) {
    // If the element being added is not an AssocNode or does not have a symbol
    // key, then we want to turn the SYMBOL_KEYS flag off.
    if (!PM_NODE_TYPE_P(element, PM_ASSOC_NODE) || !PM_NODE_TYPE_P(((pm_assoc_node_t *) element)->key, PM_SYMBOL_NODE)) {
        pm_node_flag_unset((pm_node_t *)hash, PM_KEYWORD_HASH_NODE_FLAGS_SYMBOL_KEYS);
    }

    pm_node_list_append(&hash->elements, element);
    if (hash->base.location.start == NULL) {
        hash->base.location.start = element->location.start;
    }
    hash->base.location.end = element->location.end;
}

/**
 * Allocate and initialize a new RequiredKeywordParameterNode node.
 */
static pm_required_keyword_parameter_node_t *
pm_required_keyword_parameter_node_create(pm_parser_t *parser, const pm_token_t *name) {
    pm_required_keyword_parameter_node_t *node = PM_NODE_ALLOC(parser, pm_required_keyword_parameter_node_t);

    *node = (pm_required_keyword_parameter_node_t) {
        {
            .type = PM_REQUIRED_KEYWORD_PARAMETER_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = name->start,
                .end = name->end
            },
        },
        .name = pm_parser_constant_id_location(parser, name->start, name->end - 1),
        .name_loc = PM_LOCATION_TOKEN_VALUE(name),
    };

    return node;
}

/**
 * Allocate a new OptionalKeywordParameterNode node.
 */
static pm_optional_keyword_parameter_node_t *
pm_optional_keyword_parameter_node_create(pm_parser_t *parser, const pm_token_t *name, pm_node_t *value) {
    pm_optional_keyword_parameter_node_t *node = PM_NODE_ALLOC(parser, pm_optional_keyword_parameter_node_t);

    *node = (pm_optional_keyword_parameter_node_t) {
        {
            .type = PM_OPTIONAL_KEYWORD_PARAMETER_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = name->start,
                .end = value->location.end
            },
        },
        .name = pm_parser_constant_id_location(parser, name->start, name->end - 1),
        .name_loc = PM_LOCATION_TOKEN_VALUE(name),
        .value = value
    };

    return node;
}

/**
 * Allocate a new KeywordRestParameterNode node.
 */
static pm_keyword_rest_parameter_node_t *
pm_keyword_rest_parameter_node_create(pm_parser_t *parser, const pm_token_t *operator, const pm_token_t *name) {
    pm_keyword_rest_parameter_node_t *node = PM_NODE_ALLOC(parser, pm_keyword_rest_parameter_node_t);

    *node = (pm_keyword_rest_parameter_node_t) {
        {
            .type = PM_KEYWORD_REST_PARAMETER_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = operator->start,
                .end = (name->type == PM_TOKEN_NOT_PROVIDED ? operator->end : name->end)
            },
        },
        .name = pm_parser_optional_constant_id_token(parser, name),
        .name_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(name),
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator)
    };

    return node;
}

/**
 * Allocate a new LambdaNode node.
 */
static pm_lambda_node_t *
pm_lambda_node_create(
    pm_parser_t *parser,
    pm_constant_id_list_t *locals,
    const pm_token_t *operator,
    const pm_token_t *opening,
    const pm_token_t *closing,
    pm_node_t *parameters,
    pm_node_t *body
) {
    pm_lambda_node_t *node = PM_NODE_ALLOC(parser, pm_lambda_node_t);

    *node = (pm_lambda_node_t) {
        {
            .type = PM_LAMBDA_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = operator->start,
                .end = closing->end
            },
        },
        .locals = *locals,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .opening_loc = PM_LOCATION_TOKEN_VALUE(opening),
        .closing_loc = PM_LOCATION_TOKEN_VALUE(closing),
        .parameters = parameters,
        .body = body
    };

    return node;
}

/**
 * Allocate and initialize a new LocalVariableAndWriteNode node.
 */
static pm_local_variable_and_write_node_t *
pm_local_variable_and_write_node_create(pm_parser_t *parser, pm_node_t *target, const pm_token_t *operator, pm_node_t *value, pm_constant_id_t name, uint32_t depth) {
    assert(PM_NODE_TYPE_P(target, PM_LOCAL_VARIABLE_READ_NODE) || PM_NODE_TYPE_P(target, PM_IT_LOCAL_VARIABLE_READ_NODE) || PM_NODE_TYPE_P(target, PM_CALL_NODE));
    assert(operator->type == PM_TOKEN_AMPERSAND_AMPERSAND_EQUAL);
    pm_local_variable_and_write_node_t *node = PM_NODE_ALLOC(parser, pm_local_variable_and_write_node_t);

    *node = (pm_local_variable_and_write_node_t) {
        {
            .type = PM_LOCAL_VARIABLE_AND_WRITE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->location.start,
                .end = value->location.end
            }
        },
        .name_loc = target->location,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value,
        .name = name,
        .depth = depth
    };

    return node;
}

/**
 * Allocate and initialize a new LocalVariableOperatorWriteNode node.
 */
static pm_local_variable_operator_write_node_t *
pm_local_variable_operator_write_node_create(pm_parser_t *parser, pm_node_t *target, const pm_token_t *operator, pm_node_t *value, pm_constant_id_t name, uint32_t depth) {
    pm_local_variable_operator_write_node_t *node = PM_NODE_ALLOC(parser, pm_local_variable_operator_write_node_t);

    *node = (pm_local_variable_operator_write_node_t) {
        {
            .type = PM_LOCAL_VARIABLE_OPERATOR_WRITE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->location.start,
                .end = value->location.end
            }
        },
        .name_loc = target->location,
        .binary_operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value,
        .name = name,
        .binary_operator = pm_parser_constant_id_location(parser, operator->start, operator->end - 1),
        .depth = depth
    };

    return node;
}

/**
 * Allocate and initialize a new LocalVariableOrWriteNode node.
 */
static pm_local_variable_or_write_node_t *
pm_local_variable_or_write_node_create(pm_parser_t *parser, pm_node_t *target, const pm_token_t *operator, pm_node_t *value, pm_constant_id_t name, uint32_t depth) {
    assert(PM_NODE_TYPE_P(target, PM_LOCAL_VARIABLE_READ_NODE) || PM_NODE_TYPE_P(target, PM_IT_LOCAL_VARIABLE_READ_NODE) || PM_NODE_TYPE_P(target, PM_CALL_NODE));
    assert(operator->type == PM_TOKEN_PIPE_PIPE_EQUAL);
    pm_local_variable_or_write_node_t *node = PM_NODE_ALLOC(parser, pm_local_variable_or_write_node_t);

    *node = (pm_local_variable_or_write_node_t) {
        {
            .type = PM_LOCAL_VARIABLE_OR_WRITE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->location.start,
                .end = value->location.end
            }
        },
        .name_loc = target->location,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value,
        .name = name,
        .depth = depth
    };

    return node;
}

/**
 * Allocate a new LocalVariableReadNode node with constant_id.
 */
static pm_local_variable_read_node_t *
pm_local_variable_read_node_create_constant_id(pm_parser_t *parser, const pm_token_t *name, pm_constant_id_t name_id, uint32_t depth, bool missing) {
    if (!missing) pm_locals_read(&pm_parser_scope_find(parser, depth)->locals, name_id);

    pm_local_variable_read_node_t *node = PM_NODE_ALLOC(parser, pm_local_variable_read_node_t);

    *node = (pm_local_variable_read_node_t) {
        {
            .type = PM_LOCAL_VARIABLE_READ_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_TOKEN_VALUE(name)
        },
        .name = name_id,
        .depth = depth
    };

    return node;
}

/**
 * Allocate and initialize a new LocalVariableReadNode node.
 */
static pm_local_variable_read_node_t *
pm_local_variable_read_node_create(pm_parser_t *parser, const pm_token_t *name, uint32_t depth) {
    pm_constant_id_t name_id = pm_parser_constant_id_token(parser, name);
    return pm_local_variable_read_node_create_constant_id(parser, name, name_id, depth, false);
}

/**
 * Allocate and initialize a new LocalVariableReadNode node for a missing local
 * variable. (This will only happen when there is a syntax error.)
 */
static pm_local_variable_read_node_t *
pm_local_variable_read_node_missing_create(pm_parser_t *parser, const pm_token_t *name, uint32_t depth) {
    pm_constant_id_t name_id = pm_parser_constant_id_token(parser, name);
    return pm_local_variable_read_node_create_constant_id(parser, name, name_id, depth, true);
}

/**
 * Allocate and initialize a new LocalVariableWriteNode node.
 */
static pm_local_variable_write_node_t *
pm_local_variable_write_node_create(pm_parser_t *parser, pm_constant_id_t name, uint32_t depth, pm_node_t *value, const pm_location_t *name_loc, const pm_token_t *operator) {
    pm_local_variable_write_node_t *node = PM_NODE_ALLOC(parser, pm_local_variable_write_node_t);

    *node = (pm_local_variable_write_node_t) {
        {
            .type = PM_LOCAL_VARIABLE_WRITE_NODE,
            .flags = pm_implicit_array_write_flags(value, PM_WRITE_NODE_FLAGS_IMPLICIT_ARRAY),
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = name_loc->start,
                .end = value->location.end
            }
        },
        .name = name,
        .depth = depth,
        .value = value,
        .name_loc = *name_loc,
        .operator_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(operator)
    };

    return node;
}

/**
 * Returns true if the given bounds comprise `it`.
 */
static inline bool
pm_token_is_it(const uint8_t *start, const uint8_t *end) {
    return (end - start == 2) && (start[0] == 'i') && (start[1] == 't');
}

/**
 * Returns true if the given bounds comprise a numbered parameter (i.e., they
 * are of the form /^_\d$/).
 */
static inline bool
pm_token_is_numbered_parameter(const uint8_t *start, const uint8_t *end) {
    return (end - start == 2) && (start[0] == '_') && (start[1] != '0') && (pm_char_is_decimal_digit(start[1]));
}

/**
 * Ensure the given bounds do not comprise a numbered parameter. If they do, add
 * an appropriate error message to the parser.
 */
static inline void
pm_refute_numbered_parameter(pm_parser_t *parser, const uint8_t *start, const uint8_t *end) {
    if (pm_token_is_numbered_parameter(start, end)) {
        PM_PARSER_ERR_FORMAT(parser, start, end, PM_ERR_PARAMETER_NUMBERED_RESERVED, start);
    }
}

/**
 * Allocate and initialize a new LocalVariableTargetNode node with the given
 * name and depth.
 */
static pm_local_variable_target_node_t *
pm_local_variable_target_node_create(pm_parser_t *parser, const pm_location_t *location, pm_constant_id_t name, uint32_t depth) {
    pm_refute_numbered_parameter(parser, location->start, location->end);
    pm_local_variable_target_node_t *node = PM_NODE_ALLOC(parser, pm_local_variable_target_node_t);

    *node = (pm_local_variable_target_node_t) {
        {
            .type = PM_LOCAL_VARIABLE_TARGET_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = *location
        },
        .name = name,
        .depth = depth
    };

    return node;
}

/**
 * Allocate and initialize a new MatchPredicateNode node.
 */
static pm_match_predicate_node_t *
pm_match_predicate_node_create(pm_parser_t *parser, pm_node_t *value, pm_node_t *pattern, const pm_token_t *operator) {
    pm_assert_value_expression(parser, value);

    pm_match_predicate_node_t *node = PM_NODE_ALLOC(parser, pm_match_predicate_node_t);

    *node = (pm_match_predicate_node_t) {
        {
            .type = PM_MATCH_PREDICATE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = value->location.start,
                .end = pattern->location.end
            }
        },
        .value = value,
        .pattern = pattern,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator)
    };

    return node;
}

/**
 * Allocate and initialize a new MatchRequiredNode node.
 */
static pm_match_required_node_t *
pm_match_required_node_create(pm_parser_t *parser, pm_node_t *value, pm_node_t *pattern, const pm_token_t *operator) {
    pm_assert_value_expression(parser, value);

    pm_match_required_node_t *node = PM_NODE_ALLOC(parser, pm_match_required_node_t);

    *node = (pm_match_required_node_t) {
        {
            .type = PM_MATCH_REQUIRED_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = value->location.start,
                .end = pattern->location.end
            }
        },
        .value = value,
        .pattern = pattern,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator)
    };

    return node;
}

/**
 * Allocate and initialize a new MatchWriteNode node.
 */
static pm_match_write_node_t *
pm_match_write_node_create(pm_parser_t *parser, pm_call_node_t *call) {
    pm_match_write_node_t *node = PM_NODE_ALLOC(parser, pm_match_write_node_t);

    *node = (pm_match_write_node_t) {
        {
            .type = PM_MATCH_WRITE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = call->base.location
        },
        .call = call,
        .targets = { 0 }
    };

    return node;
}

/**
 * Allocate a new ModuleNode node.
 */
static pm_module_node_t *
pm_module_node_create(pm_parser_t *parser, pm_constant_id_list_t *locals, const pm_token_t *module_keyword, pm_node_t *constant_path, const pm_token_t *name, pm_node_t *body, const pm_token_t *end_keyword) {
    pm_module_node_t *node = PM_NODE_ALLOC(parser, pm_module_node_t);

    *node = (pm_module_node_t) {
        {
            .type = PM_MODULE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = module_keyword->start,
                .end = end_keyword->end
            }
        },
        .locals = (locals == NULL ? ((pm_constant_id_list_t) { .ids = NULL, .size = 0, .capacity = 0 }) : *locals),
        .module_keyword_loc = PM_LOCATION_TOKEN_VALUE(module_keyword),
        .constant_path = constant_path,
        .body = body,
        .end_keyword_loc = PM_LOCATION_TOKEN_VALUE(end_keyword),
        .name = pm_parser_constant_id_token(parser, name)
    };

    return node;
}

/**
 * Allocate and initialize new MultiTargetNode node.
 */
static pm_multi_target_node_t *
pm_multi_target_node_create(pm_parser_t *parser) {
    pm_multi_target_node_t *node = PM_NODE_ALLOC(parser, pm_multi_target_node_t);

    *node = (pm_multi_target_node_t) {
        {
            .type = PM_MULTI_TARGET_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = { .start = NULL, .end = NULL }
        },
        .lefts = { 0 },
        .rest = NULL,
        .rights = { 0 },
        .lparen_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE,
        .rparen_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE
    };

    return node;
}

/**
 * Append a target to a MultiTargetNode node.
 */
static void
pm_multi_target_node_targets_append(pm_parser_t *parser, pm_multi_target_node_t *node, pm_node_t *target) {
    if (PM_NODE_TYPE_P(target, PM_SPLAT_NODE)) {
        if (node->rest == NULL) {
            node->rest = target;
        } else {
            pm_parser_err_node(parser, target, PM_ERR_MULTI_ASSIGN_MULTI_SPLATS);
            pm_node_list_append(&node->rights, target);
        }
    } else if (PM_NODE_TYPE_P(target, PM_IMPLICIT_REST_NODE)) {
        if (node->rest == NULL) {
            node->rest = target;
        } else {
            PM_PARSER_ERR_TOKEN_FORMAT_CONTENT(parser, parser->current, PM_ERR_MULTI_ASSIGN_UNEXPECTED_REST);
            pm_node_list_append(&node->rights, target);
        }
    } else if (node->rest == NULL) {
        pm_node_list_append(&node->lefts, target);
    } else {
        pm_node_list_append(&node->rights, target);
    }

    if (node->base.location.start == NULL || (node->base.location.start > target->location.start)) {
        node->base.location.start = target->location.start;
    }

    if (node->base.location.end == NULL || (node->base.location.end < target->location.end)) {
        node->base.location.end = target->location.end;
    }
}

/**
 * Set the opening of a MultiTargetNode node.
 */
static void
pm_multi_target_node_opening_set(pm_multi_target_node_t *node, const pm_token_t *lparen) {
    node->base.location.start = lparen->start;
    node->lparen_loc = PM_LOCATION_TOKEN_VALUE(lparen);
}

/**
 * Set the closing of a MultiTargetNode node.
 */
static void
pm_multi_target_node_closing_set(pm_multi_target_node_t *node, const pm_token_t *rparen) {
    node->base.location.end = rparen->end;
    node->rparen_loc = PM_LOCATION_TOKEN_VALUE(rparen);
}

/**
 * Allocate a new MultiWriteNode node.
 */
static pm_multi_write_node_t *
pm_multi_write_node_create(pm_parser_t *parser, pm_multi_target_node_t *target, const pm_token_t *operator, pm_node_t *value) {
    pm_multi_write_node_t *node = PM_NODE_ALLOC(parser, pm_multi_write_node_t);

    *node = (pm_multi_write_node_t) {
        {
            .type = PM_MULTI_WRITE_NODE,
            .flags = pm_implicit_array_write_flags(value, PM_WRITE_NODE_FLAGS_IMPLICIT_ARRAY),
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = target->base.location.start,
                .end = value->location.end
            }
        },
        .lefts = target->lefts,
        .rest = target->rest,
        .rights = target->rights,
        .lparen_loc = target->lparen_loc,
        .rparen_loc = target->rparen_loc,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value
    };

    // Explicitly do not call pm_node_destroy here because we want to keep
    // around all of the information within the MultiWriteNode node.
    xfree(target);

    return node;
}

/**
 * Allocate and initialize a new NextNode node.
 */
static pm_next_node_t *
pm_next_node_create(pm_parser_t *parser, const pm_token_t *keyword, pm_arguments_node_t *arguments) {
    assert(keyword->type == PM_TOKEN_KEYWORD_NEXT);
    pm_next_node_t *node = PM_NODE_ALLOC(parser, pm_next_node_t);

    *node = (pm_next_node_t) {
        {
            .type = PM_NEXT_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = keyword->start,
                .end = (arguments == NULL ? keyword->end : arguments->base.location.end)
            }
        },
        .keyword_loc = PM_LOCATION_TOKEN_VALUE(keyword),
        .arguments = arguments
    };

    return node;
}

/**
 * Allocate and initialize a new NilNode node.
 */
static pm_nil_node_t *
pm_nil_node_create(pm_parser_t *parser, const pm_token_t *token) {
    assert(token->type == PM_TOKEN_KEYWORD_NIL);
    pm_nil_node_t *node = PM_NODE_ALLOC(parser, pm_nil_node_t);

    *node = (pm_nil_node_t) {{
        .type = PM_NIL_NODE,
        .flags = PM_NODE_FLAG_STATIC_LITERAL,
        .node_id = PM_NODE_IDENTIFY(parser),
        .location = PM_LOCATION_TOKEN_VALUE(token)
    }};

    return node;
}

/**
 * Allocate and initialize a new NoKeywordsParameterNode node.
 */
static pm_no_keywords_parameter_node_t *
pm_no_keywords_parameter_node_create(pm_parser_t *parser, const pm_token_t *operator, const pm_token_t *keyword) {
    assert(operator->type == PM_TOKEN_USTAR_STAR || operator->type == PM_TOKEN_STAR_STAR);
    assert(keyword->type == PM_TOKEN_KEYWORD_NIL);
    pm_no_keywords_parameter_node_t *node = PM_NODE_ALLOC(parser, pm_no_keywords_parameter_node_t);

    *node = (pm_no_keywords_parameter_node_t) {
        {
            .type = PM_NO_KEYWORDS_PARAMETER_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = operator->start,
                .end = keyword->end
            }
        },
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .keyword_loc = PM_LOCATION_TOKEN_VALUE(keyword)
    };

    return node;
}

/**
 * Allocate and initialize a new NumberedParametersNode node.
 */
static pm_numbered_parameters_node_t *
pm_numbered_parameters_node_create(pm_parser_t *parser, const pm_location_t *location, uint8_t maximum) {
    pm_numbered_parameters_node_t *node = PM_NODE_ALLOC(parser, pm_numbered_parameters_node_t);

    *node = (pm_numbered_parameters_node_t) {
        {
            .type = PM_NUMBERED_PARAMETERS_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = *location
        },
        .maximum = maximum
    };

    return node;
}

/**
 * The maximum numbered reference value is defined as the maximum value that an
 * integer can hold minus 1 bit for CRuby instruction sequence operand tagging.
 */
#define NTH_REF_MAX ((uint32_t) (INT_MAX >> 1))

/**
 * Parse the decimal number represented by the range of bytes. Returns
 * 0 if the number fails to parse or if the number is greater than the maximum
 * value representable by a numbered reference. This function assumes that the
 * range of bytes has already been validated to contain only decimal digits.
 */
static uint32_t
pm_numbered_reference_read_node_number(pm_parser_t *parser, const pm_token_t *token) {
    const uint8_t *start = token->start + 1;
    const uint8_t *end = token->end;

    ptrdiff_t diff = end - start;
    assert(diff > 0);
#if PTRDIFF_MAX > SIZE_MAX
    assert(diff < (ptrdiff_t) SIZE_MAX);
#endif
    size_t length = (size_t) diff;

    char *digits = xcalloc(length + 1, sizeof(char));
    memcpy(digits, start, length);
    digits[length] = '\0';

    char *endptr;
    errno = 0;
    unsigned long value = strtoul(digits, &endptr, 10);

    if ((digits == endptr) || (*endptr != '\0')) {
        pm_parser_err(parser, start, end, PM_ERR_INVALID_NUMBER_DECIMAL);
        value = 0;
    }

    xfree(digits);

    if ((errno == ERANGE) || (value > NTH_REF_MAX)) {
        PM_PARSER_WARN_FORMAT(parser, start, end, PM_WARN_INVALID_NUMBERED_REFERENCE, (int) (length + 1), (const char *) token->start);
        value = 0;
    }

    return (uint32_t) value;
}

#undef NTH_REF_MAX

/**
 * Allocate and initialize a new NthReferenceReadNode node.
 */
static pm_numbered_reference_read_node_t *
pm_numbered_reference_read_node_create(pm_parser_t *parser, const pm_token_t *name) {
    assert(name->type == PM_TOKEN_NUMBERED_REFERENCE);
    pm_numbered_reference_read_node_t *node = PM_NODE_ALLOC(parser, pm_numbered_reference_read_node_t);

    *node = (pm_numbered_reference_read_node_t) {
        {
            .type = PM_NUMBERED_REFERENCE_READ_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_TOKEN_VALUE(name),
        },
        .number = pm_numbered_reference_read_node_number(parser, name)
    };

    return node;
}

/**
 * Allocate a new OptionalParameterNode node.
 */
static pm_optional_parameter_node_t *
pm_optional_parameter_node_create(pm_parser_t *parser, const pm_token_t *name, const pm_token_t *operator, pm_node_t *value) {
    pm_optional_parameter_node_t *node = PM_NODE_ALLOC(parser, pm_optional_parameter_node_t);

    *node = (pm_optional_parameter_node_t) {
        {
            .type = PM_OPTIONAL_PARAMETER_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = name->start,
                .end = value->location.end
            }
        },
        .name = pm_parser_constant_id_token(parser, name),
        .name_loc = PM_LOCATION_TOKEN_VALUE(name),
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .value = value
    };

    return node;
}

/**
 * Allocate and initialize a new OrNode node.
 */
static pm_or_node_t *
pm_or_node_create(pm_parser_t *parser, pm_node_t *left, const pm_token_t *operator, pm_node_t *right) {
    pm_assert_value_expression(parser, left);

    pm_or_node_t *node = PM_NODE_ALLOC(parser, pm_or_node_t);

    *node = (pm_or_node_t) {
        {
            .type = PM_OR_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = left->location.start,
                .end = right->location.end
            }
        },
        .left = left,
        .right = right,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator)
    };

    return node;
}

/**
 * Allocate and initialize a new ParametersNode node.
 */
static pm_parameters_node_t *
pm_parameters_node_create(pm_parser_t *parser) {
    pm_parameters_node_t *node = PM_NODE_ALLOC(parser, pm_parameters_node_t);

    *node = (pm_parameters_node_t) {
        {
            .type = PM_PARAMETERS_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_TOKEN_VALUE(&parser->current)
        },
        .rest = NULL,
        .keyword_rest = NULL,
        .block = NULL,
        .requireds = { 0 },
        .optionals = { 0 },
        .posts = { 0 },
        .keywords = { 0 }
    };

    return node;
}

/**
 * Set the location properly for the parameters node.
 */
static void
pm_parameters_node_location_set(pm_parameters_node_t *params, pm_node_t *param) {
    if (params->base.location.start == NULL) {
        params->base.location.start = param->location.start;
    } else {
        params->base.location.start = params->base.location.start < param->location.start ? params->base.location.start : param->location.start;
    }

    if (params->base.location.end == NULL) {
        params->base.location.end = param->location.end;
    } else {
        params->base.location.end = params->base.location.end > param->location.end ? params->base.location.end : param->location.end;
    }
}

/**
 * Append a required parameter to a ParametersNode node.
 */
static void
pm_parameters_node_requireds_append(pm_parameters_node_t *params, pm_node_t *param) {
    pm_parameters_node_location_set(params, param);
    pm_node_list_append(&params->requireds, param);
}

/**
 * Append an optional parameter to a ParametersNode node.
 */
static void
pm_parameters_node_optionals_append(pm_parameters_node_t *params, pm_optional_parameter_node_t *param) {
    pm_parameters_node_location_set(params, (pm_node_t *) param);
    pm_node_list_append(&params->optionals, (pm_node_t *) param);
}

/**
 * Append a post optional arguments parameter to a ParametersNode node.
 */
static void
pm_parameters_node_posts_append(pm_parameters_node_t *params, pm_node_t *param) {
    pm_parameters_node_location_set(params, param);
    pm_node_list_append(&params->posts, param);
}

/**
 * Set the rest parameter on a ParametersNode node.
 */
static void
pm_parameters_node_rest_set(pm_parameters_node_t *params, pm_node_t *param) {
    pm_parameters_node_location_set(params, param);
    params->rest = param;
}

/**
 * Append a keyword parameter to a ParametersNode node.
 */
static void
pm_parameters_node_keywords_append(pm_parameters_node_t *params, pm_node_t *param) {
    pm_parameters_node_location_set(params, param);
    pm_node_list_append(&params->keywords, param);
}

/**
 * Set the keyword rest parameter on a ParametersNode node.
 */
static void
pm_parameters_node_keyword_rest_set(pm_parameters_node_t *params, pm_node_t *param) {
    assert(params->keyword_rest == NULL);
    pm_parameters_node_location_set(params, param);
    params->keyword_rest = param;
}

/**
 * Set the block parameter on a ParametersNode node.
 */
static void
pm_parameters_node_block_set(pm_parameters_node_t *params, pm_block_parameter_node_t *param) {
    assert(params->block == NULL);
    pm_parameters_node_location_set(params, (pm_node_t *) param);
    params->block = param;
}

/**
 * Allocate a new ProgramNode node.
 */
static pm_program_node_t *
pm_program_node_create(pm_parser_t *parser, pm_constant_id_list_t *locals, pm_statements_node_t *statements) {
    pm_program_node_t *node = PM_NODE_ALLOC(parser, pm_program_node_t);

    *node = (pm_program_node_t) {
        {
            .type = PM_PROGRAM_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = statements == NULL ? parser->start : statements->base.location.start,
                .end = statements == NULL ? parser->end : statements->base.location.end
            }
        },
        .locals = *locals,
        .statements = statements
    };

    return node;
}

/**
 * Allocate and initialize new ParenthesesNode node.
 */
static pm_parentheses_node_t *
pm_parentheses_node_create(pm_parser_t *parser, const pm_token_t *opening, pm_node_t *body, const pm_token_t *closing, pm_node_flags_t flags) {
    pm_parentheses_node_t *node = PM_NODE_ALLOC(parser, pm_parentheses_node_t);

    *node = (pm_parentheses_node_t) {
        {
            .type = PM_PARENTHESES_NODE,
            .flags = flags,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = opening->start,
                .end = closing->end
            }
        },
        .body = body,
        .opening_loc = PM_LOCATION_TOKEN_VALUE(opening),
        .closing_loc = PM_LOCATION_TOKEN_VALUE(closing)
    };

    return node;
}

/**
 * Allocate and initialize a new PinnedExpressionNode node.
 */
static pm_pinned_expression_node_t *
pm_pinned_expression_node_create(pm_parser_t *parser, pm_node_t *expression, const pm_token_t *operator, const pm_token_t *lparen, const pm_token_t *rparen) {
    pm_pinned_expression_node_t *node = PM_NODE_ALLOC(parser, pm_pinned_expression_node_t);

    *node = (pm_pinned_expression_node_t) {
        {
            .type = PM_PINNED_EXPRESSION_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = operator->start,
                .end = rparen->end
            }
        },
        .expression = expression,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .lparen_loc = PM_LOCATION_TOKEN_VALUE(lparen),
        .rparen_loc = PM_LOCATION_TOKEN_VALUE(rparen)
    };

    return node;
}

/**
 * Allocate and initialize a new PinnedVariableNode node.
 */
static pm_pinned_variable_node_t *
pm_pinned_variable_node_create(pm_parser_t *parser, const pm_token_t *operator, pm_node_t *variable) {
    pm_pinned_variable_node_t *node = PM_NODE_ALLOC(parser, pm_pinned_variable_node_t);

    *node = (pm_pinned_variable_node_t) {
        {
            .type = PM_PINNED_VARIABLE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = operator->start,
                .end = variable->location.end
            }
        },
        .variable = variable,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator)
    };

    return node;
}

/**
 * Allocate and initialize a new PostExecutionNode node.
 */
static pm_post_execution_node_t *
pm_post_execution_node_create(pm_parser_t *parser, const pm_token_t *keyword, const pm_token_t *opening, pm_statements_node_t *statements, const pm_token_t *closing) {
    pm_post_execution_node_t *node = PM_NODE_ALLOC(parser, pm_post_execution_node_t);

    *node = (pm_post_execution_node_t) {
        {
            .type = PM_POST_EXECUTION_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = keyword->start,
                .end = closing->end
            }
        },
        .statements = statements,
        .keyword_loc = PM_LOCATION_TOKEN_VALUE(keyword),
        .opening_loc = PM_LOCATION_TOKEN_VALUE(opening),
        .closing_loc = PM_LOCATION_TOKEN_VALUE(closing)
    };

    return node;
}

/**
 * Allocate and initialize a new PreExecutionNode node.
 */
static pm_pre_execution_node_t *
pm_pre_execution_node_create(pm_parser_t *parser, const pm_token_t *keyword, const pm_token_t *opening, pm_statements_node_t *statements, const pm_token_t *closing) {
    pm_pre_execution_node_t *node = PM_NODE_ALLOC(parser, pm_pre_execution_node_t);

    *node = (pm_pre_execution_node_t) {
        {
            .type = PM_PRE_EXECUTION_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = keyword->start,
                .end = closing->end
            }
        },
        .statements = statements,
        .keyword_loc = PM_LOCATION_TOKEN_VALUE(keyword),
        .opening_loc = PM_LOCATION_TOKEN_VALUE(opening),
        .closing_loc = PM_LOCATION_TOKEN_VALUE(closing)
    };

    return node;
}

/**
 * Allocate and initialize new RangeNode node.
 */
static pm_range_node_t *
pm_range_node_create(pm_parser_t *parser, pm_node_t *left, const pm_token_t *operator, pm_node_t *right) {
    pm_assert_value_expression(parser, left);
    pm_assert_value_expression(parser, right);

    pm_range_node_t *node = PM_NODE_ALLOC(parser, pm_range_node_t);
    pm_node_flags_t flags = 0;

    // Indicate that this node is an exclusive range if the operator is `...`.
    if (operator->type == PM_TOKEN_DOT_DOT_DOT || operator->type == PM_TOKEN_UDOT_DOT_DOT) {
        flags |= PM_RANGE_FLAGS_EXCLUDE_END;
    }

    // Indicate that this node is a static literal (i.e., can be compiled with
    // a putobject in CRuby) if the left and right are implicit nil, explicit
    // nil, or integers.
    if (
        (left == NULL || PM_NODE_TYPE_P(left, PM_NIL_NODE) || PM_NODE_TYPE_P(left, PM_INTEGER_NODE)) &&
        (right == NULL || PM_NODE_TYPE_P(right, PM_NIL_NODE) || PM_NODE_TYPE_P(right, PM_INTEGER_NODE))
    ) {
        flags |= PM_NODE_FLAG_STATIC_LITERAL;
    }

    *node = (pm_range_node_t) {
        {
            .type = PM_RANGE_NODE,
            .flags = flags,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = (left == NULL ? operator->start : left->location.start),
                .end = (right == NULL ? operator->end : right->location.end)
            }
        },
        .left = left,
        .right = right,
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator)
    };

    return node;
}

/**
 * Allocate and initialize a new RedoNode node.
 */
static pm_redo_node_t *
pm_redo_node_create(pm_parser_t *parser, const pm_token_t *token) {
    assert(token->type == PM_TOKEN_KEYWORD_REDO);
    pm_redo_node_t *node = PM_NODE_ALLOC(parser, pm_redo_node_t);

    *node = (pm_redo_node_t) {{
        .type = PM_REDO_NODE,
        .node_id = PM_NODE_IDENTIFY(parser),
        .location = PM_LOCATION_TOKEN_VALUE(token)
    }};

    return node;
}

/**
 * Allocate a new initialize a new RegularExpressionNode node with the given
 * unescaped string.
 */
static pm_regular_expression_node_t *
pm_regular_expression_node_create_unescaped(pm_parser_t *parser, const pm_token_t *opening, const pm_token_t *content, const pm_token_t *closing, const pm_string_t *unescaped) {
    pm_regular_expression_node_t *node = PM_NODE_ALLOC(parser, pm_regular_expression_node_t);

    *node = (pm_regular_expression_node_t) {
        {
            .type = PM_REGULAR_EXPRESSION_NODE,
            .flags = pm_regular_expression_flags_create(parser, closing) | PM_NODE_FLAG_STATIC_LITERAL,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = MIN(opening->start, closing->start),
                .end = MAX(opening->end, closing->end)
            }
        },
        .opening_loc = PM_LOCATION_TOKEN_VALUE(opening),
        .content_loc = PM_LOCATION_TOKEN_VALUE(content),
        .closing_loc = PM_LOCATION_TOKEN_VALUE(closing),
        .unescaped = *unescaped
    };

    return node;
}

/**
 * Allocate a new initialize a new RegularExpressionNode node.
 */
static inline pm_regular_expression_node_t *
pm_regular_expression_node_create(pm_parser_t *parser, const pm_token_t *opening, const pm_token_t *content, const pm_token_t *closing) {
    return pm_regular_expression_node_create_unescaped(parser, opening, content, closing, &PM_STRING_EMPTY);
}

/**
 * Allocate a new RequiredParameterNode node.
 */
static pm_required_parameter_node_t *
pm_required_parameter_node_create(pm_parser_t *parser, const pm_token_t *token) {
    pm_required_parameter_node_t *node = PM_NODE_ALLOC(parser, pm_required_parameter_node_t);

    *node = (pm_required_parameter_node_t) {
        {
            .type = PM_REQUIRED_PARAMETER_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_TOKEN_VALUE(token)
        },
        .name = pm_parser_constant_id_token(parser, token)
    };

    return node;
}

/**
 * Allocate a new RescueModifierNode node.
 */
static pm_rescue_modifier_node_t *
pm_rescue_modifier_node_create(pm_parser_t *parser, pm_node_t *expression, const pm_token_t *keyword, pm_node_t *rescue_expression) {
    pm_rescue_modifier_node_t *node = PM_NODE_ALLOC(parser, pm_rescue_modifier_node_t);

    *node = (pm_rescue_modifier_node_t) {
        {
            .type = PM_RESCUE_MODIFIER_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = expression->location.start,
                .end = rescue_expression->location.end
            }
        },
        .expression = expression,
        .keyword_loc = PM_LOCATION_TOKEN_VALUE(keyword),
        .rescue_expression = rescue_expression
    };

    return node;
}

/**
 * Allocate and initialize a new RescueNode node.
 */
static pm_rescue_node_t *
pm_rescue_node_create(pm_parser_t *parser, const pm_token_t *keyword) {
    pm_rescue_node_t *node = PM_NODE_ALLOC(parser, pm_rescue_node_t);

    *node = (pm_rescue_node_t) {
        {
            .type = PM_RESCUE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_TOKEN_VALUE(keyword)
        },
        .keyword_loc = PM_LOCATION_TOKEN_VALUE(keyword),
        .operator_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE,
        .then_keyword_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE,
        .reference = NULL,
        .statements = NULL,
        .subsequent = NULL,
        .exceptions = { 0 }
    };

    return node;
}

static inline void
pm_rescue_node_operator_set(pm_rescue_node_t *node, const pm_token_t *operator) {
    node->operator_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(operator);
}

/**
 * Set the reference of a rescue node, and update the location of the node.
 */
static void
pm_rescue_node_reference_set(pm_rescue_node_t *node, pm_node_t *reference) {
    node->reference = reference;
    node->base.location.end = reference->location.end;
}

/**
 * Set the statements of a rescue node, and update the location of the node.
 */
static void
pm_rescue_node_statements_set(pm_rescue_node_t *node, pm_statements_node_t *statements) {
    node->statements = statements;
    if (pm_statements_node_body_length(statements) > 0) {
        node->base.location.end = statements->base.location.end;
    }
}

/**
 * Set the subsequent of a rescue node, and update the location.
 */
static void
pm_rescue_node_subsequent_set(pm_rescue_node_t *node, pm_rescue_node_t *subsequent) {
    node->subsequent = subsequent;
    node->base.location.end = subsequent->base.location.end;
}

/**
 * Append an exception node to a rescue node, and update the location.
 */
static void
pm_rescue_node_exceptions_append(pm_rescue_node_t *node, pm_node_t *exception) {
    pm_node_list_append(&node->exceptions, exception);
    node->base.location.end = exception->location.end;
}

/**
 * Allocate a new RestParameterNode node.
 */
static pm_rest_parameter_node_t *
pm_rest_parameter_node_create(pm_parser_t *parser, const pm_token_t *operator, const pm_token_t *name) {
    pm_rest_parameter_node_t *node = PM_NODE_ALLOC(parser, pm_rest_parameter_node_t);

    *node = (pm_rest_parameter_node_t) {
        {
            .type = PM_REST_PARAMETER_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = operator->start,
                .end = (name->type == PM_TOKEN_NOT_PROVIDED ? operator->end : name->end)
            }
        },
        .name = pm_parser_optional_constant_id_token(parser, name),
        .name_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(name),
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator)
    };

    return node;
}

/**
 * Allocate and initialize a new RetryNode node.
 */
static pm_retry_node_t *
pm_retry_node_create(pm_parser_t *parser, const pm_token_t *token) {
    assert(token->type == PM_TOKEN_KEYWORD_RETRY);
    pm_retry_node_t *node = PM_NODE_ALLOC(parser, pm_retry_node_t);

    *node = (pm_retry_node_t) {{
        .type = PM_RETRY_NODE,
        .node_id = PM_NODE_IDENTIFY(parser),
        .location = PM_LOCATION_TOKEN_VALUE(token)
    }};

    return node;
}

/**
 * Allocate a new ReturnNode node.
 */
static pm_return_node_t *
pm_return_node_create(pm_parser_t *parser, const pm_token_t *keyword, pm_arguments_node_t *arguments) {
    pm_return_node_t *node = PM_NODE_ALLOC(parser, pm_return_node_t);

    *node = (pm_return_node_t) {
        {
            .type = PM_RETURN_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = keyword->start,
                .end = (arguments == NULL ? keyword->end : arguments->base.location.end)
            }
        },
        .keyword_loc = PM_LOCATION_TOKEN_VALUE(keyword),
        .arguments = arguments
    };

    return node;
}

/**
 * Allocate and initialize a new SelfNode node.
 */
static pm_self_node_t *
pm_self_node_create(pm_parser_t *parser, const pm_token_t *token) {
    assert(token->type == PM_TOKEN_KEYWORD_SELF);
    pm_self_node_t *node = PM_NODE_ALLOC(parser, pm_self_node_t);

    *node = (pm_self_node_t) {{
        .type = PM_SELF_NODE,
        .node_id = PM_NODE_IDENTIFY(parser),
        .location = PM_LOCATION_TOKEN_VALUE(token)
    }};

    return node;
}

/**
 * Allocate and initialize a new ShareableConstantNode node.
 */
static pm_shareable_constant_node_t *
pm_shareable_constant_node_create(pm_parser_t *parser, pm_node_t *write, pm_shareable_constant_value_t value) {
    pm_shareable_constant_node_t *node = PM_NODE_ALLOC(parser, pm_shareable_constant_node_t);

    *node = (pm_shareable_constant_node_t) {
        {
            .type = PM_SHAREABLE_CONSTANT_NODE,
            .flags = (pm_node_flags_t) value,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_NODE_VALUE(write)
        },
        .write = write
    };

    return node;
}

/**
 * Allocate a new SingletonClassNode node.
 */
static pm_singleton_class_node_t *
pm_singleton_class_node_create(pm_parser_t *parser, pm_constant_id_list_t *locals, const pm_token_t *class_keyword, const pm_token_t *operator, pm_node_t *expression, pm_node_t *body, const pm_token_t *end_keyword) {
    pm_singleton_class_node_t *node = PM_NODE_ALLOC(parser, pm_singleton_class_node_t);

    *node = (pm_singleton_class_node_t) {
        {
            .type = PM_SINGLETON_CLASS_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = class_keyword->start,
                .end = end_keyword->end
            }
        },
        .locals = *locals,
        .class_keyword_loc = PM_LOCATION_TOKEN_VALUE(class_keyword),
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .expression = expression,
        .body = body,
        .end_keyword_loc = PM_LOCATION_TOKEN_VALUE(end_keyword)
    };

    return node;
}

/**
 * Allocate and initialize a new SourceEncodingNode node.
 */
static pm_source_encoding_node_t *
pm_source_encoding_node_create(pm_parser_t *parser, const pm_token_t *token) {
    assert(token->type == PM_TOKEN_KEYWORD___ENCODING__);
    pm_source_encoding_node_t *node = PM_NODE_ALLOC(parser, pm_source_encoding_node_t);

    *node = (pm_source_encoding_node_t) {{
        .type = PM_SOURCE_ENCODING_NODE,
        .flags = PM_NODE_FLAG_STATIC_LITERAL,
        .node_id = PM_NODE_IDENTIFY(parser),
        .location = PM_LOCATION_TOKEN_VALUE(token)
    }};

    return node;
}

/**
 * Allocate and initialize a new SourceFileNode node.
 */
static pm_source_file_node_t*
pm_source_file_node_create(pm_parser_t *parser, const pm_token_t *file_keyword) {
    pm_source_file_node_t *node = PM_NODE_ALLOC(parser, pm_source_file_node_t);
    assert(file_keyword->type == PM_TOKEN_KEYWORD___FILE__);

    pm_node_flags_t flags = 0;

    switch (parser->frozen_string_literal) {
        case PM_OPTIONS_FROZEN_STRING_LITERAL_DISABLED:
            flags |= PM_STRING_FLAGS_MUTABLE;
            break;
        case PM_OPTIONS_FROZEN_STRING_LITERAL_ENABLED:
            flags |= PM_NODE_FLAG_STATIC_LITERAL | PM_STRING_FLAGS_FROZEN;
            break;
    }

    *node = (pm_source_file_node_t) {
        {
            .type = PM_SOURCE_FILE_NODE,
            .flags = flags,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_TOKEN_VALUE(file_keyword),
        },
        .filepath = parser->filepath
    };

    return node;
}

/**
 * Allocate and initialize a new SourceLineNode node.
 */
static pm_source_line_node_t *
pm_source_line_node_create(pm_parser_t *parser, const pm_token_t *token) {
    assert(token->type == PM_TOKEN_KEYWORD___LINE__);
    pm_source_line_node_t *node = PM_NODE_ALLOC(parser, pm_source_line_node_t);

    *node = (pm_source_line_node_t) {{
        .type = PM_SOURCE_LINE_NODE,
        .flags = PM_NODE_FLAG_STATIC_LITERAL,
        .node_id = PM_NODE_IDENTIFY(parser),
        .location = PM_LOCATION_TOKEN_VALUE(token)
    }};

    return node;
}

/**
 * Allocate a new SplatNode node.
 */
static pm_splat_node_t *
pm_splat_node_create(pm_parser_t *parser, const pm_token_t *operator, pm_node_t *expression) {
    pm_splat_node_t *node = PM_NODE_ALLOC(parser, pm_splat_node_t);

    *node = (pm_splat_node_t) {
        {
            .type = PM_SPLAT_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = operator->start,
                .end = (expression == NULL ? operator->end : expression->location.end)
            }
        },
        .operator_loc = PM_LOCATION_TOKEN_VALUE(operator),
        .expression = expression
    };

    return node;
}

/**
 * Allocate and initialize a new StatementsNode node.
 */
static pm_statements_node_t *
pm_statements_node_create(pm_parser_t *parser) {
    pm_statements_node_t *node = PM_NODE_ALLOC(parser, pm_statements_node_t);

    *node = (pm_statements_node_t) {
        {
            .type = PM_STATEMENTS_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_NULL_VALUE(parser)
        },
        .body = { 0 }
    };

    return node;
}

/**
 * Get the length of the given StatementsNode node's body.
 */
static size_t
pm_statements_node_body_length(pm_statements_node_t *node) {
    return node && node->body.size;
}

/**
 * Set the location of the given StatementsNode.
 */
static void
pm_statements_node_location_set(pm_statements_node_t *node, const uint8_t *start, const uint8_t *end) {
    node->base.location = (pm_location_t) { .start = start, .end = end };
}

/**
 * Update the location of the statements node based on the statement that is
 * being added to the list.
 */
static inline void
pm_statements_node_body_update(pm_statements_node_t *node, pm_node_t *statement) {
    if (pm_statements_node_body_length(node) == 0 || statement->location.start < node->base.location.start) {
        node->base.location.start = statement->location.start;
    }

    if (statement->location.end > node->base.location.end) {
        node->base.location.end = statement->location.end;
    }
}

/**
 * Append a new node to the given StatementsNode node's body.
 */
static void
pm_statements_node_body_append(pm_parser_t *parser, pm_statements_node_t *node, pm_node_t *statement, bool newline) {
    pm_statements_node_body_update(node, statement);

    if (node->body.size > 0) {
        const pm_node_t *previous = node->body.nodes[node->body.size - 1];

        switch (PM_NODE_TYPE(previous)) {
            case PM_BREAK_NODE:
            case PM_NEXT_NODE:
            case PM_REDO_NODE:
            case PM_RETRY_NODE:
            case PM_RETURN_NODE:
                pm_parser_warn_node(parser, statement, PM_WARN_UNREACHABLE_STATEMENT);
                break;
            default:
                break;
        }
    }

    pm_node_list_append(&node->body, statement);
    if (newline) pm_node_flag_set(statement, PM_NODE_FLAG_NEWLINE);
}

/**
 * Prepend a new node to the given StatementsNode node's body.
 */
static void
pm_statements_node_body_prepend(pm_statements_node_t *node, pm_node_t *statement) {
    pm_statements_node_body_update(node, statement);
    pm_node_list_prepend(&node->body, statement);
    pm_node_flag_set(statement, PM_NODE_FLAG_NEWLINE);
}

/**
 * Allocate a new StringNode node with the current string on the parser.
 */
static inline pm_string_node_t *
pm_string_node_create_unescaped(pm_parser_t *parser, const pm_token_t *opening, const pm_token_t *content, const pm_token_t *closing, const pm_string_t *string) {
    pm_string_node_t *node = PM_NODE_ALLOC(parser, pm_string_node_t);
    pm_node_flags_t flags = 0;

    switch (parser->frozen_string_literal) {
        case PM_OPTIONS_FROZEN_STRING_LITERAL_DISABLED:
            flags = PM_STRING_FLAGS_MUTABLE;
            break;
        case PM_OPTIONS_FROZEN_STRING_LITERAL_ENABLED:
            flags = PM_NODE_FLAG_STATIC_LITERAL | PM_STRING_FLAGS_FROZEN;
            break;
    }

    *node = (pm_string_node_t) {
        {
            .type = PM_STRING_NODE,
            .flags = flags,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = (opening->type == PM_TOKEN_NOT_PROVIDED ? content->start : opening->start),
                .end = (closing->type == PM_TOKEN_NOT_PROVIDED ? content->end : closing->end)
            }
        },
        .opening_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(opening),
        .content_loc = PM_LOCATION_TOKEN_VALUE(content),
        .closing_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(closing),
        .unescaped = *string
    };

    return node;
}

/**
 * Allocate a new StringNode node.
 */
static pm_string_node_t *
pm_string_node_create(pm_parser_t *parser, const pm_token_t *opening, const pm_token_t *content, const pm_token_t *closing) {
    return pm_string_node_create_unescaped(parser, opening, content, closing, &PM_STRING_EMPTY);
}

/**
 * Allocate a new StringNode node and create it using the current string on the
 * parser.
 */
static pm_string_node_t *
pm_string_node_create_current_string(pm_parser_t *parser, const pm_token_t *opening, const pm_token_t *content, const pm_token_t *closing) {
    pm_string_node_t *node = pm_string_node_create_unescaped(parser, opening, content, closing, &parser->current_string);
    parser->current_string = PM_STRING_EMPTY;
    return node;
}

/**
 * Allocate and initialize a new SuperNode node.
 */
static pm_super_node_t *
pm_super_node_create(pm_parser_t *parser, const pm_token_t *keyword, pm_arguments_t *arguments) {
    assert(keyword->type == PM_TOKEN_KEYWORD_SUPER);
    pm_super_node_t *node = PM_NODE_ALLOC(parser, pm_super_node_t);

    const uint8_t *end = pm_arguments_end(arguments);
    if (end == NULL) {
        assert(false && "unreachable");
    }

    *node = (pm_super_node_t) {
        {
            .type = PM_SUPER_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = keyword->start,
                .end = end,
            }
        },
        .keyword_loc = PM_LOCATION_TOKEN_VALUE(keyword),
        .lparen_loc = arguments->opening_loc,
        .arguments = arguments->arguments,
        .rparen_loc = arguments->closing_loc,
        .block = arguments->block
    };

    return node;
}

/**
 * Read through the contents of a string and check if it consists solely of
 * US-ASCII code points.
 */
static bool
pm_ascii_only_p(const pm_string_t *contents) {
    const size_t length = pm_string_length(contents);
    const uint8_t *source = pm_string_source(contents);

    for (size_t index = 0; index < length; index++) {
        if (source[index] & 0x80) return false;
    }

    return true;
}

/**
 * Validate that the contents of the given symbol are all valid UTF-8.
 */
static void
parse_symbol_encoding_validate_utf8(pm_parser_t *parser, const pm_token_t *location, const pm_string_t *contents) {
    for (const uint8_t *cursor = pm_string_source(contents), *end = cursor + pm_string_length(contents); cursor < end;) {
        size_t width = pm_encoding_utf_8_char_width(cursor, end - cursor);

        if (width == 0) {
            pm_parser_err(parser, location->start, location->end, PM_ERR_INVALID_SYMBOL);
            break;
        }

        cursor += width;
    }
}

/**
 * Validate that the contents of the given symbol are all valid in the encoding
 * of the parser.
 */
static void
parse_symbol_encoding_validate_other(pm_parser_t *parser, const pm_token_t *location, const pm_string_t *contents) {
    const pm_encoding_t *encoding = parser->encoding;

    for (const uint8_t *cursor = pm_string_source(contents), *end = cursor + pm_string_length(contents); cursor < end;) {
        size_t width = encoding->char_width(cursor, end - cursor);

        if (width == 0) {
            pm_parser_err(parser, location->start, location->end, PM_ERR_INVALID_SYMBOL);
            break;
        }

        cursor += width;
    }
}

/**
 * Ruby "downgrades" the encoding of Symbols to US-ASCII if the associated
 * encoding is ASCII-compatible and the Symbol consists only of US-ASCII code
 * points. Otherwise, the encoding may be explicitly set with an escape
 * sequence.
 *
 * If the validate flag is set, then it will check the contents of the symbol
 * to ensure that all characters are valid in the encoding.
 */
static inline pm_node_flags_t
parse_symbol_encoding(pm_parser_t *parser, const pm_token_t *location, const pm_string_t *contents, bool validate) {
    if (parser->explicit_encoding != NULL) {
        // A Symbol may optionally have its encoding explicitly set. This will
        // happen if an escape sequence results in a non-ASCII code point.
        if (parser->explicit_encoding == PM_ENCODING_UTF_8_ENTRY) {
            if (validate) parse_symbol_encoding_validate_utf8(parser, location, contents);
            return PM_SYMBOL_FLAGS_FORCED_UTF8_ENCODING;
        } else if (parser->encoding == PM_ENCODING_US_ASCII_ENTRY) {
            return PM_SYMBOL_FLAGS_FORCED_BINARY_ENCODING;
        } else if (validate) {
            parse_symbol_encoding_validate_other(parser, location, contents);
        }
    } else if (pm_ascii_only_p(contents)) {
        // Ruby stipulates that all source files must use an ASCII-compatible
        // encoding. Thus, all symbols appearing in source are eligible for
        // "downgrading" to US-ASCII.
        return PM_SYMBOL_FLAGS_FORCED_US_ASCII_ENCODING;
    } else if (validate) {
        parse_symbol_encoding_validate_other(parser, location, contents);
    }

    return 0;
}

static pm_node_flags_t
parse_and_validate_regular_expression_encoding_modifier(pm_parser_t *parser, const pm_string_t *source, bool ascii_only, pm_node_flags_t flags, char modifier, const pm_encoding_t *modifier_encoding) {
    assert ((modifier == 'n' && modifier_encoding == PM_ENCODING_ASCII_8BIT_ENTRY) ||
            (modifier == 'u' && modifier_encoding == PM_ENCODING_UTF_8_ENTRY) ||
            (modifier == 'e' && modifier_encoding == PM_ENCODING_EUC_JP_ENTRY) ||
            (modifier == 's' && modifier_encoding == PM_ENCODING_WINDOWS_31J_ENTRY));

    // There's special validation logic used if a string does not contain any character escape sequences.
    if (parser->explicit_encoding == NULL) {
        // If an ASCII-only string without character escapes is used with an encoding modifier, then resulting Regexp
        // has the modifier encoding, unless the ASCII-8BIT modifier is used, in which case the Regexp "downgrades" to
        // the US-ASCII encoding.
        if (ascii_only) {
            return modifier == 'n' ? PM_REGULAR_EXPRESSION_FLAGS_FORCED_US_ASCII_ENCODING : flags;
        }

        if (parser->encoding == PM_ENCODING_US_ASCII_ENTRY) {
            if (!ascii_only) {
                PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_INVALID_MULTIBYTE_CHAR, parser->encoding->name);
            }
        } else if (parser->encoding != modifier_encoding) {
            PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_REGEXP_ENCODING_OPTION_MISMATCH, modifier, parser->encoding->name);

            if (modifier == 'n' && !ascii_only) {
                PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_REGEXP_NON_ESCAPED_MBC, (int) pm_string_length(source), (const char *) pm_string_source(source));
            }
        }

        return flags;
    }

    // TODO (nirvdrum 21-Feb-2024): To validate regexp sources with character escape sequences we need to know whether hex or Unicode escape sequences were used and Prism doesn't currently provide that data. We handle a subset of unambiguous cases in the meanwhile.
    bool mixed_encoding = false;

    if (mixed_encoding) {
        PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_INVALID_MULTIBYTE_ESCAPE, (int) pm_string_length(source), (const char *) pm_string_source(source));
    } else if (modifier != 'n' && parser->explicit_encoding == PM_ENCODING_ASCII_8BIT_ENTRY) {
        // TODO (nirvdrum 21-Feb-2024): Validate the content is valid in the modifier encoding. Do this on-demand so we don't pay the cost of computation unnecessarily.
        bool valid_string_in_modifier_encoding = true;

        if (!valid_string_in_modifier_encoding) {
            PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_INVALID_MULTIBYTE_ESCAPE, (int) pm_string_length(source), (const char *) pm_string_source(source));
        }
    } else if (modifier != 'u' && parser->explicit_encoding == PM_ENCODING_UTF_8_ENTRY) {
        // TODO (nirvdrum 21-Feb-2024): There's currently no way to tell if the source used hex or Unicode character escapes from `explicit_encoding` alone. If the source encoding was already UTF-8, both character escape types would set `explicit_encoding` to UTF-8, but need to be processed differently. Skip for now.
        if (parser->encoding != PM_ENCODING_UTF_8_ENTRY) {
            PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_REGEXP_INCOMPAT_CHAR_ENCODING, (int) pm_string_length(source), (const char *) pm_string_source(source));
        }
    }

    // We've determined the encoding would naturally be EUC-JP and there is no need to force the encoding to anything else.
    return flags;
}

/**
 * Ruby "downgrades" the encoding of Regexps to US-ASCII if the associated encoding is ASCII-compatible and
 * the unescaped representation of a Regexp source consists only of US-ASCII code points. This is true even
 * when the Regexp is explicitly given an ASCII-8BIT encoding via the (/n) modifier. Otherwise, the encoding
 * may be explicitly set with an escape sequence.
 */
static pm_node_flags_t
parse_and_validate_regular_expression_encoding(pm_parser_t *parser, const pm_string_t *source, bool ascii_only, pm_node_flags_t flags) {
    // TODO (nirvdrum 22-Feb-2024): CRuby reports a special Regexp-specific error for invalid Unicode ranges. We either need to scan again or modify the "invalid Unicode escape sequence" message we already report.
    bool valid_unicode_range = true;
    if (parser->explicit_encoding == PM_ENCODING_UTF_8_ENTRY && !valid_unicode_range) {
        PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_REGEXP_INVALID_UNICODE_RANGE, (int) pm_string_length(source), (const char *) pm_string_source(source));
        return flags;
    }

    // US-ASCII strings do not admit multi-byte character literals. However, character escape sequences corresponding
    // to multi-byte characters are allowed.
    if (parser->encoding == PM_ENCODING_US_ASCII_ENTRY && parser->explicit_encoding == NULL && !ascii_only) {
        // CRuby will continue processing even though a SyntaxError has already been detected. It may result in the
        // following error message appearing twice. We do the same for compatibility.
        PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_INVALID_MULTIBYTE_CHAR, parser->encoding->name);
    }

    /**
     * Start checking modifier flags. We need to process these before considering any explicit encodings that may have
     * been set by character literals. The order in which the encoding modifiers is checked does not matter. In the
     * event that both an encoding modifier and an explicit encoding would result in the same encoding we do not set
     * the corresponding "forced_<encoding>" flag. Instead, the caller should check the encoding modifier flag and
     * determine the encoding that way.
     */

    if (flags & PM_REGULAR_EXPRESSION_FLAGS_ASCII_8BIT) {
        return parse_and_validate_regular_expression_encoding_modifier(parser, source, ascii_only, flags, 'n', PM_ENCODING_ASCII_8BIT_ENTRY);
    }

    if (flags & PM_REGULAR_EXPRESSION_FLAGS_UTF_8) {
        return parse_and_validate_regular_expression_encoding_modifier(parser, source, ascii_only, flags, 'u', PM_ENCODING_UTF_8_ENTRY);
    }

    if (flags & PM_REGULAR_EXPRESSION_FLAGS_EUC_JP) {
        return parse_and_validate_regular_expression_encoding_modifier(parser, source, ascii_only, flags, 'e', PM_ENCODING_EUC_JP_ENTRY);
    }

    if (flags & PM_REGULAR_EXPRESSION_FLAGS_WINDOWS_31J) {
        return parse_and_validate_regular_expression_encoding_modifier(parser, source, ascii_only, flags, 's', PM_ENCODING_WINDOWS_31J_ENTRY);
    }

    // At this point no encoding modifiers will be present on the regular expression as they would have already
    // been processed. Ruby stipulates that all source files must use an ASCII-compatible encoding. Thus, all
    // regular expressions without an encoding modifier appearing in source are eligible for "downgrading" to US-ASCII.
    if (ascii_only) {
        return PM_REGULAR_EXPRESSION_FLAGS_FORCED_US_ASCII_ENCODING;
    }

    // A Regexp may optionally have its encoding explicitly set via a character escape sequence in the source string
    // or by specifying a modifier.
    //
    // NB: an explicitly set encoding is ignored by Ruby if the Regexp consists of only US ASCII code points.
    if (parser->explicit_encoding != NULL) {
        if (parser->explicit_encoding == PM_ENCODING_UTF_8_ENTRY) {
            return PM_REGULAR_EXPRESSION_FLAGS_FORCED_UTF8_ENCODING;
        } else if (parser->encoding == PM_ENCODING_US_ASCII_ENTRY) {
            return PM_REGULAR_EXPRESSION_FLAGS_FORCED_BINARY_ENCODING;
        }
    }

    return 0;
}

/**
 * Allocate and initialize a new SymbolNode node with the given unescaped
 * string.
 */
static pm_symbol_node_t *
pm_symbol_node_create_unescaped(pm_parser_t *parser, const pm_token_t *opening, const pm_token_t *value, const pm_token_t *closing, const pm_string_t *unescaped, pm_node_flags_t flags) {
    pm_symbol_node_t *node = PM_NODE_ALLOC(parser, pm_symbol_node_t);

    *node = (pm_symbol_node_t) {
        {
            .type = PM_SYMBOL_NODE,
            .flags = PM_NODE_FLAG_STATIC_LITERAL | flags,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = (opening->type == PM_TOKEN_NOT_PROVIDED ? value->start : opening->start),
                .end = (closing->type == PM_TOKEN_NOT_PROVIDED ? value->end : closing->end)
            }
        },
        .opening_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(opening),
        .value_loc = PM_LOCATION_TOKEN_VALUE(value),
        .closing_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(closing),
        .unescaped = *unescaped
    };

    return node;
}

/**
 * Allocate and initialize a new SymbolNode node.
 */
static inline pm_symbol_node_t *
pm_symbol_node_create(pm_parser_t *parser, const pm_token_t *opening, const pm_token_t *value, const pm_token_t *closing) {
    return pm_symbol_node_create_unescaped(parser, opening, value, closing, &PM_STRING_EMPTY, 0);
}

/**
 * Allocate and initialize a new SymbolNode node with the current string.
 */
static pm_symbol_node_t *
pm_symbol_node_create_current_string(pm_parser_t *parser, const pm_token_t *opening, const pm_token_t *value, const pm_token_t *closing) {
    pm_symbol_node_t *node = pm_symbol_node_create_unescaped(parser, opening, value, closing, &parser->current_string, parse_symbol_encoding(parser, value, &parser->current_string, false));
    parser->current_string = PM_STRING_EMPTY;
    return node;
}

/**
 * Allocate and initialize a new SymbolNode node from a label.
 */
static pm_symbol_node_t *
pm_symbol_node_label_create(pm_parser_t *parser, const pm_token_t *token) {
    pm_symbol_node_t *node;

    switch (token->type) {
        case PM_TOKEN_LABEL: {
            pm_token_t opening = not_provided(parser);
            pm_token_t closing = { .type = PM_TOKEN_LABEL_END, .start = token->end - 1, .end = token->end };

            pm_token_t label = { .type = PM_TOKEN_LABEL, .start = token->start, .end = token->end - 1 };
            node = pm_symbol_node_create(parser, &opening, &label, &closing);

            assert((label.end - label.start) >= 0);
            pm_string_shared_init(&node->unescaped, label.start, label.end);
            pm_node_flag_set((pm_node_t *) node, parse_symbol_encoding(parser, &label, &node->unescaped, false));

            break;
        }
        case PM_TOKEN_MISSING: {
            pm_token_t opening = not_provided(parser);
            pm_token_t closing = not_provided(parser);

            pm_token_t label = { .type = PM_TOKEN_LABEL, .start = token->start, .end = token->end };
            node = pm_symbol_node_create(parser, &opening, &label, &closing);
            break;
        }
        default:
            assert(false && "unreachable");
            node = NULL;
            break;
    }

    return node;
}

/**
 * Allocate and initialize a new synthesized SymbolNode node.
 */
static pm_symbol_node_t *
pm_symbol_node_synthesized_create(pm_parser_t *parser, const char *content) {
    pm_symbol_node_t *node = PM_NODE_ALLOC(parser, pm_symbol_node_t);

    *node = (pm_symbol_node_t) {
        {
            .type = PM_SYMBOL_NODE,
            .flags = PM_NODE_FLAG_STATIC_LITERAL | PM_SYMBOL_FLAGS_FORCED_US_ASCII_ENCODING,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_NULL_VALUE(parser)
        },
        .value_loc = PM_LOCATION_NULL_VALUE(parser),
        .unescaped = { 0 }
    };

    pm_string_constant_init(&node->unescaped, content, strlen(content));
    return node;
}

/**
 * Check if the given node is a label in a hash.
 */
static bool
pm_symbol_node_label_p(pm_node_t *node) {
    const uint8_t *end = NULL;

    switch (PM_NODE_TYPE(node)) {
        case PM_SYMBOL_NODE:
            end = ((pm_symbol_node_t *) node)->closing_loc.end;
            break;
        case PM_INTERPOLATED_SYMBOL_NODE:
            end = ((pm_interpolated_symbol_node_t *) node)->closing_loc.end;
            break;
        default:
            return false;
    }

    return (end != NULL) && (end[-1] == ':');
}

/**
 * Convert the given StringNode node to a SymbolNode node.
 */
static pm_symbol_node_t *
pm_string_node_to_symbol_node(pm_parser_t *parser, pm_string_node_t *node, const pm_token_t *opening, const pm_token_t *closing) {
    pm_symbol_node_t *new_node = PM_NODE_ALLOC(parser, pm_symbol_node_t);

    *new_node = (pm_symbol_node_t) {
        {
            .type = PM_SYMBOL_NODE,
            .flags = PM_NODE_FLAG_STATIC_LITERAL,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = opening->start,
                .end = closing->end
            }
        },
        .opening_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(opening),
        .value_loc = node->content_loc,
        .closing_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(closing),
        .unescaped = node->unescaped
    };

    pm_token_t content = { .type = PM_TOKEN_IDENTIFIER, .start = node->content_loc.start, .end = node->content_loc.end };
    pm_node_flag_set((pm_node_t *) new_node, parse_symbol_encoding(parser, &content, &node->unescaped, true));

    // We are explicitly _not_ using pm_node_destroy here because we don't want
    // to trash the unescaped string. We could instead copy the string if we
    // know that it is owned, but we're taking the fast path for now.
    xfree(node);

    return new_node;
}

/**
 * Convert the given SymbolNode node to a StringNode node.
 */
static pm_string_node_t *
pm_symbol_node_to_string_node(pm_parser_t *parser, pm_symbol_node_t *node) {
    pm_string_node_t *new_node = PM_NODE_ALLOC(parser, pm_string_node_t);
    pm_node_flags_t flags = 0;

    switch (parser->frozen_string_literal) {
        case PM_OPTIONS_FROZEN_STRING_LITERAL_DISABLED:
            flags = PM_STRING_FLAGS_MUTABLE;
            break;
        case PM_OPTIONS_FROZEN_STRING_LITERAL_ENABLED:
            flags = PM_NODE_FLAG_STATIC_LITERAL | PM_STRING_FLAGS_FROZEN;
            break;
    }

    *new_node = (pm_string_node_t) {
        {
            .type = PM_STRING_NODE,
            .flags = flags,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = node->base.location
        },
        .opening_loc = node->opening_loc,
        .content_loc = node->value_loc,
        .closing_loc = node->closing_loc,
        .unescaped = node->unescaped
    };

    // We are explicitly _not_ using pm_node_destroy here because we don't want
    // to trash the unescaped string. We could instead copy the string if we
    // know that it is owned, but we're taking the fast path for now.
    xfree(node);

    return new_node;
}

/**
 * Allocate and initialize a new TrueNode node.
 */
static pm_true_node_t *
pm_true_node_create(pm_parser_t *parser, const pm_token_t *token) {
    assert(token->type == PM_TOKEN_KEYWORD_TRUE);
    pm_true_node_t *node = PM_NODE_ALLOC(parser, pm_true_node_t);

    *node = (pm_true_node_t) {{
        .type = PM_TRUE_NODE,
        .flags = PM_NODE_FLAG_STATIC_LITERAL,
        .node_id = PM_NODE_IDENTIFY(parser),
        .location = PM_LOCATION_TOKEN_VALUE(token)
    }};

    return node;
}

/**
 * Allocate and initialize a new synthesized TrueNode node.
 */
static pm_true_node_t *
pm_true_node_synthesized_create(pm_parser_t *parser) {
    pm_true_node_t *node = PM_NODE_ALLOC(parser, pm_true_node_t);

    *node = (pm_true_node_t) {{
        .type = PM_TRUE_NODE,
        .flags = PM_NODE_FLAG_STATIC_LITERAL,
        .node_id = PM_NODE_IDENTIFY(parser),
        .location = { .start = parser->start, .end = parser->end }
    }};

    return node;
}

/**
 * Allocate and initialize a new UndefNode node.
 */
static pm_undef_node_t *
pm_undef_node_create(pm_parser_t *parser, const pm_token_t *token) {
    assert(token->type == PM_TOKEN_KEYWORD_UNDEF);
    pm_undef_node_t *node = PM_NODE_ALLOC(parser, pm_undef_node_t);

    *node = (pm_undef_node_t) {
        {
            .type = PM_UNDEF_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_TOKEN_VALUE(token),
        },
        .keyword_loc = PM_LOCATION_TOKEN_VALUE(token),
        .names = { 0 }
    };

    return node;
}

/**
 * Append a name to an undef node.
 */
static void
pm_undef_node_append(pm_undef_node_t *node, pm_node_t *name) {
    node->base.location.end = name->location.end;
    pm_node_list_append(&node->names, name);
}

/**
 * Allocate a new UnlessNode node.
 */
static pm_unless_node_t *
pm_unless_node_create(pm_parser_t *parser, const pm_token_t *keyword, pm_node_t *predicate, const pm_token_t *then_keyword, pm_statements_node_t *statements) {
    pm_conditional_predicate(parser, predicate, PM_CONDITIONAL_PREDICATE_TYPE_CONDITIONAL);
    pm_unless_node_t *node = PM_NODE_ALLOC(parser, pm_unless_node_t);

    const uint8_t *end;
    if (statements != NULL) {
        end = statements->base.location.end;
    } else {
        end = predicate->location.end;
    }

    *node = (pm_unless_node_t) {
        {
            .type = PM_UNLESS_NODE,
            .flags = PM_NODE_FLAG_NEWLINE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = keyword->start,
                .end = end
            },
        },
        .keyword_loc = PM_LOCATION_TOKEN_VALUE(keyword),
        .predicate = predicate,
        .then_keyword_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(then_keyword),
        .statements = statements,
        .else_clause = NULL,
        .end_keyword_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE
    };

    return node;
}

/**
 * Allocate and initialize new UnlessNode node in the modifier form.
 */
static pm_unless_node_t *
pm_unless_node_modifier_create(pm_parser_t *parser, pm_node_t *statement, const pm_token_t *unless_keyword, pm_node_t *predicate) {
    pm_conditional_predicate(parser, predicate, PM_CONDITIONAL_PREDICATE_TYPE_CONDITIONAL);
    pm_unless_node_t *node = PM_NODE_ALLOC(parser, pm_unless_node_t);

    pm_statements_node_t *statements = pm_statements_node_create(parser);
    pm_statements_node_body_append(parser, statements, statement, true);

    *node = (pm_unless_node_t) {
        {
            .type = PM_UNLESS_NODE,
            .flags = PM_NODE_FLAG_NEWLINE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = statement->location.start,
                .end = predicate->location.end
            },
        },
        .keyword_loc = PM_LOCATION_TOKEN_VALUE(unless_keyword),
        .predicate = predicate,
        .then_keyword_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE,
        .statements = statements,
        .else_clause = NULL,
        .end_keyword_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE
    };

    return node;
}

static inline void
pm_unless_node_end_keyword_loc_set(pm_unless_node_t *node, const pm_token_t *end_keyword) {
    node->end_keyword_loc = PM_LOCATION_TOKEN_VALUE(end_keyword);
    node->base.location.end = end_keyword->end;
}

/**
 * Loop modifiers could potentially modify an expression that contains block
 * exits. In this case we need to loop through them and remove them from the
 * list of block exits so that they do not later get marked as invalid.
 */
static void
pm_loop_modifier_block_exits(pm_parser_t *parser, pm_statements_node_t *statements) {
    assert(parser->current_block_exits != NULL);

    // All of the block exits that we want to remove should be within the
    // statements, and since we are modifying the statements, we shouldn't have
    // to check the end location.
    const uint8_t *start = statements->base.location.start;

    for (size_t index = parser->current_block_exits->size; index > 0; index--) {
        pm_node_t *block_exit = parser->current_block_exits->nodes[index - 1];
        if (block_exit->location.start < start) break;

        // Implicitly remove from the list by lowering the size.
        parser->current_block_exits->size--;
    }
}

/**
 * Allocate a new UntilNode node.
 */
static pm_until_node_t *
pm_until_node_create(pm_parser_t *parser, const pm_token_t *keyword, const pm_token_t *do_keyword, const pm_token_t *closing, pm_node_t *predicate, pm_statements_node_t *statements, pm_node_flags_t flags) {
    pm_until_node_t *node = PM_NODE_ALLOC(parser, pm_until_node_t);
    pm_conditional_predicate(parser, predicate, PM_CONDITIONAL_PREDICATE_TYPE_CONDITIONAL);

    *node = (pm_until_node_t) {
        {
            .type = PM_UNTIL_NODE,
            .flags = flags,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = keyword->start,
                .end = closing->end,
            },
        },
        .keyword_loc = PM_LOCATION_TOKEN_VALUE(keyword),
        .do_keyword_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(do_keyword),
        .closing_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(closing),
        .predicate = predicate,
        .statements = statements
    };

    return node;
}

/**
 * Allocate a new UntilNode node.
 */
static pm_until_node_t *
pm_until_node_modifier_create(pm_parser_t *parser, const pm_token_t *keyword, pm_node_t *predicate, pm_statements_node_t *statements, pm_node_flags_t flags) {
    pm_until_node_t *node = PM_NODE_ALLOC(parser, pm_until_node_t);
    pm_conditional_predicate(parser, predicate, PM_CONDITIONAL_PREDICATE_TYPE_CONDITIONAL);
    pm_loop_modifier_block_exits(parser, statements);

    *node = (pm_until_node_t) {
        {
            .type = PM_UNTIL_NODE,
            .flags = flags,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = statements->base.location.start,
                .end = predicate->location.end,
            },
        },
        .keyword_loc = PM_LOCATION_TOKEN_VALUE(keyword),
        .do_keyword_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE,
        .closing_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE,
        .predicate = predicate,
        .statements = statements
    };

    return node;
}

/**
 * Allocate and initialize a new WhenNode node.
 */
static pm_when_node_t *
pm_when_node_create(pm_parser_t *parser, const pm_token_t *keyword) {
    pm_when_node_t *node = PM_NODE_ALLOC(parser, pm_when_node_t);

    *node = (pm_when_node_t) {
        {
            .type = PM_WHEN_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = keyword->start,
                .end = NULL
            }
        },
        .keyword_loc = PM_LOCATION_TOKEN_VALUE(keyword),
        .statements = NULL,
        .then_keyword_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE,
        .conditions = { 0 }
    };

    return node;
}

/**
 * Append a new condition to a when node.
 */
static void
pm_when_node_conditions_append(pm_when_node_t *node, pm_node_t *condition) {
    node->base.location.end = condition->location.end;
    pm_node_list_append(&node->conditions, condition);
}

/**
 * Set the location of the then keyword of a when node.
 */
static inline void
pm_when_node_then_keyword_loc_set(pm_when_node_t *node, const pm_token_t *then_keyword) {
    node->base.location.end = then_keyword->end;
    node->then_keyword_loc = PM_LOCATION_TOKEN_VALUE(then_keyword);
}

/**
 * Set the statements list of a when node.
 */
static void
pm_when_node_statements_set(pm_when_node_t *node, pm_statements_node_t *statements) {
    if (statements->base.location.end > node->base.location.end) {
        node->base.location.end = statements->base.location.end;
    }

    node->statements = statements;
}

/**
 * Allocate a new WhileNode node.
 */
static pm_while_node_t *
pm_while_node_create(pm_parser_t *parser, const pm_token_t *keyword, const pm_token_t *do_keyword, const pm_token_t *closing, pm_node_t *predicate, pm_statements_node_t *statements, pm_node_flags_t flags) {
    pm_while_node_t *node = PM_NODE_ALLOC(parser, pm_while_node_t);
    pm_conditional_predicate(parser, predicate, PM_CONDITIONAL_PREDICATE_TYPE_CONDITIONAL);

    *node = (pm_while_node_t) {
        {
            .type = PM_WHILE_NODE,
            .flags = flags,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = keyword->start,
                .end = closing->end
            },
        },
        .keyword_loc = PM_LOCATION_TOKEN_VALUE(keyword),
        .do_keyword_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(do_keyword),
        .closing_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(closing),
        .predicate = predicate,
        .statements = statements
    };

    return node;
}

/**
 * Allocate a new WhileNode node.
 */
static pm_while_node_t *
pm_while_node_modifier_create(pm_parser_t *parser, const pm_token_t *keyword, pm_node_t *predicate, pm_statements_node_t *statements, pm_node_flags_t flags) {
    pm_while_node_t *node = PM_NODE_ALLOC(parser, pm_while_node_t);
    pm_conditional_predicate(parser, predicate, PM_CONDITIONAL_PREDICATE_TYPE_CONDITIONAL);
    pm_loop_modifier_block_exits(parser, statements);

    *node = (pm_while_node_t) {
        {
            .type = PM_WHILE_NODE,
            .flags = flags,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = statements->base.location.start,
                .end = predicate->location.end
            },
        },
        .keyword_loc = PM_LOCATION_TOKEN_VALUE(keyword),
        .do_keyword_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE,
        .closing_loc = PM_OPTIONAL_LOCATION_NOT_PROVIDED_VALUE,
        .predicate = predicate,
        .statements = statements
    };

    return node;
}

/**
 * Allocate and initialize a new synthesized while loop.
 */
static pm_while_node_t *
pm_while_node_synthesized_create(pm_parser_t *parser, pm_node_t *predicate, pm_statements_node_t *statements) {
    pm_while_node_t *node = PM_NODE_ALLOC(parser, pm_while_node_t);

    *node = (pm_while_node_t) {
        {
            .type = PM_WHILE_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = PM_LOCATION_NULL_VALUE(parser)
        },
        .keyword_loc = PM_LOCATION_NULL_VALUE(parser),
        .do_keyword_loc = PM_LOCATION_NULL_VALUE(parser),
        .closing_loc = PM_LOCATION_NULL_VALUE(parser),
        .predicate = predicate,
        .statements = statements
    };

    return node;
}

/**
 * Allocate and initialize a new XStringNode node with the given unescaped
 * string.
 */
static pm_x_string_node_t *
pm_xstring_node_create_unescaped(pm_parser_t *parser, const pm_token_t *opening, const pm_token_t *content, const pm_token_t *closing, const pm_string_t *unescaped) {
    pm_x_string_node_t *node = PM_NODE_ALLOC(parser, pm_x_string_node_t);

    *node = (pm_x_string_node_t) {
        {
            .type = PM_X_STRING_NODE,
            .flags = PM_STRING_FLAGS_FROZEN,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = opening->start,
                .end = closing->end
            },
        },
        .opening_loc = PM_LOCATION_TOKEN_VALUE(opening),
        .content_loc = PM_LOCATION_TOKEN_VALUE(content),
        .closing_loc = PM_LOCATION_TOKEN_VALUE(closing),
        .unescaped = *unescaped
    };

    return node;
}

/**
 * Allocate and initialize a new XStringNode node.
 */
static inline pm_x_string_node_t *
pm_xstring_node_create(pm_parser_t *parser, const pm_token_t *opening, const pm_token_t *content, const pm_token_t *closing) {
    return pm_xstring_node_create_unescaped(parser, opening, content, closing, &PM_STRING_EMPTY);
}

/**
 * Allocate a new YieldNode node.
 */
static pm_yield_node_t *
pm_yield_node_create(pm_parser_t *parser, const pm_token_t *keyword, const pm_location_t *lparen_loc, pm_arguments_node_t *arguments, const pm_location_t *rparen_loc) {
    pm_yield_node_t *node = PM_NODE_ALLOC(parser, pm_yield_node_t);

    const uint8_t *end;
    if (rparen_loc->start != NULL) {
        end = rparen_loc->end;
    } else if (arguments != NULL) {
        end = arguments->base.location.end;
    } else if (lparen_loc->start != NULL) {
        end = lparen_loc->end;
    } else {
        end = keyword->end;
    }

    *node = (pm_yield_node_t) {
        {
            .type = PM_YIELD_NODE,
            .node_id = PM_NODE_IDENTIFY(parser),
            .location = {
                .start = keyword->start,
                .end = end
            },
        },
        .keyword_loc = PM_LOCATION_TOKEN_VALUE(keyword),
        .lparen_loc = *lparen_loc,
        .arguments = arguments,
        .rparen_loc = *rparen_loc
    };

    return node;
}

#undef PM_NODE_ALLOC
#undef PM_NODE_IDENTIFY

/**
 * Check if any of the currently visible scopes contain a local variable
 * described by the given constant id.
 */
static int
pm_parser_local_depth_constant_id(pm_parser_t *parser, pm_constant_id_t constant_id) {
    pm_scope_t *scope = parser->current_scope;
    int depth = 0;

    while (scope != NULL) {
        if (pm_locals_find(&scope->locals, constant_id) != UINT32_MAX) return depth;
        if (scope->closed) break;

        scope = scope->previous;
        depth++;
    }

    return -1;
}

/**
 * Check if any of the currently visible scopes contain a local variable
 * described by the given token. This function implicitly inserts a constant
 * into the constant pool.
 */
static inline int
pm_parser_local_depth(pm_parser_t *parser, pm_token_t *token) {
    return pm_parser_local_depth_constant_id(parser, pm_parser_constant_id_token(parser, token));
}

/**
 * Add a constant id to the local table of the current scope.
 */
static inline void
pm_parser_local_add(pm_parser_t *parser, pm_constant_id_t constant_id, const uint8_t *start, const uint8_t *end, uint32_t reads) {
    pm_locals_write(&parser->current_scope->locals, constant_id, start, end, reads);
}

/**
 * Add a local variable from a location to the current scope.
 */
static pm_constant_id_t
pm_parser_local_add_location(pm_parser_t *parser, const uint8_t *start, const uint8_t *end, uint32_t reads) {
    pm_constant_id_t constant_id = pm_parser_constant_id_location(parser, start, end);
    if (constant_id != 0) pm_parser_local_add(parser, constant_id, start, end, reads);
    return constant_id;
}

/**
 * Add a local variable from a token to the current scope.
 */
static inline pm_constant_id_t
pm_parser_local_add_token(pm_parser_t *parser, pm_token_t *token, uint32_t reads) {
    return pm_parser_local_add_location(parser, token->start, token->end, reads);
}

/**
 * Add a local variable from an owned string to the current scope.
 */
static pm_constant_id_t
pm_parser_local_add_owned(pm_parser_t *parser, uint8_t *start, size_t length) {
    pm_constant_id_t constant_id = pm_parser_constant_id_owned(parser, start, length);
    if (constant_id != 0) pm_parser_local_add(parser, constant_id, parser->start, parser->start, 1);
    return constant_id;
}

/**
 * Add a local variable from a constant string to the current scope.
 */
static pm_constant_id_t
pm_parser_local_add_constant(pm_parser_t *parser, const char *start, size_t length) {
    pm_constant_id_t constant_id = pm_parser_constant_id_constant(parser, start, length);
    if (constant_id != 0) pm_parser_local_add(parser, constant_id, parser->start, parser->start, 1);
    return constant_id;
}

/**
 * Add a parameter name to the current scope and check whether the name of the
 * parameter is unique or not.
 *
 * Returns `true` if this is a duplicate parameter name, otherwise returns
 * false.
 */
static bool
pm_parser_parameter_name_check(pm_parser_t *parser, const pm_token_t *name) {
    // We want to check whether the parameter name is a numbered parameter or
    // not.
    pm_refute_numbered_parameter(parser, name->start, name->end);

    // Otherwise we'll fetch the constant id for the parameter name and check
    // whether it's already in the current scope.
    pm_constant_id_t constant_id = pm_parser_constant_id_token(parser, name);

    if (pm_locals_find(&parser->current_scope->locals, constant_id) != UINT32_MAX) {
        // Add an error if the parameter doesn't start with _ and has been seen before
        if ((name->start < name->end) && (*name->start != '_')) {
            pm_parser_err_token(parser, name, PM_ERR_PARAMETER_NAME_DUPLICATED);
        }
        return true;
    }
    return false;
}

/**
 * Pop the current scope off the scope stack.
 */
static void
pm_parser_scope_pop(pm_parser_t *parser) {
    pm_scope_t *scope = parser->current_scope;
    parser->current_scope = scope->previous;
    pm_locals_free(&scope->locals);
    pm_node_list_free(&scope->implicit_parameters);
    xfree(scope);
}

/******************************************************************************/
/* Stack helpers                                                              */
/******************************************************************************/

/**
 * Pushes a value onto the stack.
 */
static inline void
pm_state_stack_push(pm_state_stack_t *stack, bool value) {
    *stack = (*stack << 1) | (value & 1);
}

/**
 * Pops a value off the stack.
 */
static inline void
pm_state_stack_pop(pm_state_stack_t *stack) {
    *stack >>= 1;
}

/**
 * Returns the value at the top of the stack.
 */
static inline bool
pm_state_stack_p(const pm_state_stack_t *stack) {
    return *stack & 1;
}

static inline void
pm_accepts_block_stack_push(pm_parser_t *parser, bool value) {
    // Use the negation of the value to prevent stack overflow.
    pm_state_stack_push(&parser->accepts_block_stack, !value);
}

static inline void
pm_accepts_block_stack_pop(pm_parser_t *parser) {
    pm_state_stack_pop(&parser->accepts_block_stack);
}

static inline bool
pm_accepts_block_stack_p(pm_parser_t *parser) {
    return !pm_state_stack_p(&parser->accepts_block_stack);
}

static inline void
pm_do_loop_stack_push(pm_parser_t *parser, bool value) {
    pm_state_stack_push(&parser->do_loop_stack, value);
}

static inline void
pm_do_loop_stack_pop(pm_parser_t *parser) {
    pm_state_stack_pop(&parser->do_loop_stack);
}

static inline bool
pm_do_loop_stack_p(pm_parser_t *parser) {
    return pm_state_stack_p(&parser->do_loop_stack);
}

/******************************************************************************/
/* Lexer check helpers                                                        */
/******************************************************************************/

/**
 * Get the next character in the source starting from +cursor+. If that position
 * is beyond the end of the source then return '\0'.
 */
static inline uint8_t
peek_at(const pm_parser_t *parser, const uint8_t *cursor) {
    if (cursor < parser->end) {
        return *cursor;
    } else {
        return '\0';
    }
}

/**
 * Get the next character in the source starting from parser->current.end and
 * adding the given offset. If that position is beyond the end of the source
 * then return '\0'.
 */
static inline uint8_t
peek_offset(pm_parser_t *parser, ptrdiff_t offset) {
    return peek_at(parser, parser->current.end + offset);
}

/**
 * Get the next character in the source starting from parser->current.end. If
 * that position is beyond the end of the source then return '\0'.
 */
static inline uint8_t
peek(const pm_parser_t *parser) {
    return peek_at(parser, parser->current.end);
}

/**
 * If the character to be read matches the given value, then returns true and
 * advances the current pointer.
 */
static inline bool
match(pm_parser_t *parser, uint8_t value) {
    if (peek(parser) == value) {
        parser->current.end++;
        return true;
    }
    return false;
}

/**
 * Return the length of the line ending string starting at +cursor+, or 0 if it
 * is not a line ending. This function is intended to be CRLF/LF agnostic.
 */
static inline size_t
match_eol_at(pm_parser_t *parser, const uint8_t *cursor) {
    if (peek_at(parser, cursor) == '\n') {
        return 1;
    }
    if (peek_at(parser, cursor) == '\r' && peek_at(parser, cursor + 1) == '\n') {
        return 2;
    }
    return 0;
}

/**
 * Return the length of the line ending string starting at
 * `parser->current.end + offset`, or 0 if it is not a line ending. This
 * function is intended to be CRLF/LF agnostic.
 */
static inline size_t
match_eol_offset(pm_parser_t *parser, ptrdiff_t offset) {
    return match_eol_at(parser, parser->current.end + offset);
}

/**
 * Return the length of the line ending string starting at parser->current.end,
 * or 0 if it is not a line ending. This function is intended to be CRLF/LF
 * agnostic.
 */
static inline size_t
match_eol(pm_parser_t *parser) {
    return match_eol_at(parser, parser->current.end);
}

/**
 * Skip to the next newline character or NUL byte.
 */
static inline const uint8_t *
next_newline(const uint8_t *cursor, ptrdiff_t length) {
    assert(length >= 0);

    // Note that it's okay for us to use memchr here to look for \n because none
    // of the encodings that we support have \n as a component of a multi-byte
    // character.
    return memchr(cursor, '\n', (size_t) length);
}

/**
 * This is equivalent to the predicate of warn_balanced in CRuby.
 */
static inline bool
ambiguous_operator_p(const pm_parser_t *parser, bool space_seen) {
    return !lex_state_p(parser, PM_LEX_STATE_CLASS | PM_LEX_STATE_DOT | PM_LEX_STATE_FNAME | PM_LEX_STATE_ENDFN) && space_seen && !pm_char_is_whitespace(peek(parser));
}

/**
 * Here we're going to check if this is a "magic" comment, and perform whatever
 * actions are necessary for it here.
 */
static bool
parser_lex_magic_comment_encoding_value(pm_parser_t *parser, const uint8_t *start, const uint8_t *end) {
    const pm_encoding_t *encoding = pm_encoding_find(start, end);

    if (encoding != NULL) {
        if (parser->encoding != encoding) {
            parser->encoding = encoding;
            if (parser->encoding_changed_callback != NULL) parser->encoding_changed_callback(parser);
        }

        parser->encoding_changed = (encoding != PM_ENCODING_UTF_8_ENTRY);
        return true;
    }

    return false;
}

/**
 * Look for a specific pattern of "coding" and potentially set the encoding on
 * the parser.
 */
static void
parser_lex_magic_comment_encoding(pm_parser_t *parser) {
    const uint8_t *cursor = parser->current.start + 1;
    const uint8_t *end = parser->current.end;

    bool separator = false;
    while (true) {
        if (end - cursor <= 6) return;
        switch (cursor[6]) {
            case 'C': case 'c': cursor += 6; continue;
            case 'O': case 'o': cursor += 5; continue;
            case 'D': case 'd': cursor += 4; continue;
            case 'I': case 'i': cursor += 3; continue;
            case 'N': case 'n': cursor += 2; continue;
            case 'G': case 'g': cursor += 1; continue;
            case '=': case ':':
                separator = true;
                cursor += 6;
                break;
            default:
                cursor += 6;
                if (pm_char_is_whitespace(*cursor)) break;
                continue;
        }
        if (pm_strncasecmp(cursor - 6, (const uint8_t *) "coding", 6) == 0) break;
        separator = false;
    }

    while (true) {
        do {
            if (++cursor >= end) return;
        } while (pm_char_is_whitespace(*cursor));

        if (separator) break;
        if (*cursor != '=' && *cursor != ':') return;

        separator = true;
        cursor++;
    }

    const uint8_t *value_start = cursor;
    while ((*cursor == '-' || *cursor == '_' || parser->encoding->alnum_char(cursor, 1)) && ++cursor < end);

    if (!parser_lex_magic_comment_encoding_value(parser, value_start, cursor)) {
        // If we were unable to parse the encoding value, then we've got an
        // issue because we didn't understand the encoding that the user was
        // trying to use. In this case we'll keep using the default encoding but
        // add an error to the parser to indicate an unsuccessful parse.
        pm_parser_err(parser, value_start, cursor, PM_ERR_INVALID_ENCODING_MAGIC_COMMENT);
    }
}

typedef enum {
    PM_MAGIC_COMMENT_BOOLEAN_VALUE_TRUE,
    PM_MAGIC_COMMENT_BOOLEAN_VALUE_FALSE,
    PM_MAGIC_COMMENT_BOOLEAN_VALUE_INVALID
} pm_magic_comment_boolean_value_t;

/**
 * Check if this is a magic comment that includes the frozen_string_literal
 * pragma. If it does, set that field on the parser.
 */
static pm_magic_comment_boolean_value_t
parser_lex_magic_comment_boolean_value(const uint8_t *value_start, uint32_t value_length) {
    if (value_length == 4 && pm_strncasecmp(value_start, (const uint8_t *) "true", 4) == 0) {
        return PM_MAGIC_COMMENT_BOOLEAN_VALUE_TRUE;
    } else if (value_length == 5 && pm_strncasecmp(value_start, (const uint8_t *) "false", 5) == 0) {
        return PM_MAGIC_COMMENT_BOOLEAN_VALUE_FALSE;
    } else {
        return PM_MAGIC_COMMENT_BOOLEAN_VALUE_INVALID;
    }
}

static inline bool
pm_char_is_magic_comment_key_delimiter(const uint8_t b) {
    return b == '\'' || b == '"' || b == ':' || b == ';';
}

/**
 * Find an emacs magic comment marker (-*-) within the given bounds. If one is
 * found, it returns a pointer to the start of the marker. Otherwise it returns
 * NULL.
 */
static inline const uint8_t *
parser_lex_magic_comment_emacs_marker(pm_parser_t *parser, const uint8_t *cursor, const uint8_t *end) {
    while ((cursor + 3 <= end) && (cursor = pm_memchr(cursor, '-', (size_t) (end - cursor), parser->encoding_changed, parser->encoding)) != NULL) {
        if (cursor + 3 <= end && cursor[1] == '*' && cursor[2] == '-') {
            return cursor;
        }
        cursor++;
    }
    return NULL;
}

/**
 * Parse the current token on the parser to see if it's a magic comment and
 * potentially perform some action based on that. A regular expression that this
 * function is effectively matching is:
 *
 *     %r"([^\\s\'\":;]+)\\s*:\\s*(\"(?:\\\\.|[^\"])*\"|[^\"\\s;]+)[\\s;]*"
 *
 * It returns true if it consumes the entire comment. Otherwise it returns
 * false.
 */
static inline bool
parser_lex_magic_comment(pm_parser_t *parser, bool semantic_token_seen) {
    bool result = true;

    const uint8_t *start = parser->current.start + 1;
    const uint8_t *end = parser->current.end;
    if (end - start <= 7) return false;

    const uint8_t *cursor;
    bool indicator = false;

    if ((cursor = parser_lex_magic_comment_emacs_marker(parser, start, end)) != NULL) {
        start = cursor + 3;

        if ((cursor = parser_lex_magic_comment_emacs_marker(parser, start, end)) != NULL) {
            end = cursor;
            indicator = true;
        } else {
            // If we have a start marker but not an end marker, then we cannot
            // have a magic comment.
            return false;
        }
    }

    cursor = start;
    while (cursor < end) {
        while (cursor < end && (pm_char_is_magic_comment_key_delimiter(*cursor) || pm_char_is_whitespace(*cursor))) cursor++;

        const uint8_t *key_start = cursor;
        while (cursor < end && (!pm_char_is_magic_comment_key_delimiter(*cursor) && !pm_char_is_whitespace(*cursor))) cursor++;

        const uint8_t *key_end = cursor;
        while (cursor < end && pm_char_is_whitespace(*cursor)) cursor++;
        if (cursor == end) break;

        if (*cursor == ':') {
            cursor++;
        } else {
            if (!indicator) return false;
            continue;
        }

        while (cursor < end && pm_char_is_whitespace(*cursor)) cursor++;
        if (cursor == end) break;

        const uint8_t *value_start;
        const uint8_t *value_end;

        if (*cursor == '"') {
            value_start = ++cursor;
            for (; cursor < end && *cursor != '"'; cursor++) {
                if (*cursor == '\\' && (cursor + 1 < end)) cursor++;
            }
            value_end = cursor;
            if (*cursor == '"') cursor++;
        } else {
            value_start = cursor;
            while (cursor < end && *cursor != '"' && *cursor != ';' && !pm_char_is_whitespace(*cursor)) cursor++;
            value_end = cursor;
        }

        if (indicator) {
            while (cursor < end && (*cursor == ';' || pm_char_is_whitespace(*cursor))) cursor++;
        } else {
            while (cursor < end && pm_char_is_whitespace(*cursor)) cursor++;
            if (cursor != end) return false;
        }

        // Here, we need to do some processing on the key to swap out dashes for
        // underscores. We only need to do this if there _is_ a dash in the key.
        pm_string_t key;
        const size_t key_length = (size_t) (key_end - key_start);
        const uint8_t *dash = pm_memchr(key_start, '-', key_length, parser->encoding_changed, parser->encoding);

        if (dash == NULL) {
            pm_string_shared_init(&key, key_start, key_end);
        } else {
            uint8_t *buffer = xmalloc(key_length);
            if (buffer == NULL) break;

            memcpy(buffer, key_start, key_length);
            buffer[dash - key_start] = '_';

            while ((dash = pm_memchr(dash + 1, '-', (size_t) (key_end - dash - 1), parser->encoding_changed, parser->encoding)) != NULL) {
                buffer[dash - key_start] = '_';
            }

            pm_string_owned_init(&key, buffer, key_length);
        }

        // Finally, we can start checking the key against the list of known
        // magic comment keys, and potentially change state based on that.
        const uint8_t *key_source = pm_string_source(&key);
        uint32_t value_length = (uint32_t) (value_end - value_start);

        // We only want to attempt to compare against encoding comments if it's
        // the first line in the file (or the second in the case of a shebang).
        if (parser->current.start == parser->encoding_comment_start && !parser->encoding_locked) {
            if (
                (key_length == 8 && pm_strncasecmp(key_source, (const uint8_t *) "encoding", 8) == 0) ||
                (key_length == 6 && pm_strncasecmp(key_source, (const uint8_t *) "coding", 6) == 0)
            ) {
                result = parser_lex_magic_comment_encoding_value(parser, value_start, value_end);
            }
        }

        if (key_length == 11) {
            if (pm_strncasecmp(key_source, (const uint8_t *) "warn_indent", 11) == 0) {
                switch (parser_lex_magic_comment_boolean_value(value_start, value_length)) {
                    case PM_MAGIC_COMMENT_BOOLEAN_VALUE_INVALID:
                        PM_PARSER_WARN_TOKEN_FORMAT(
                            parser,
                            parser->current,
                            PM_WARN_INVALID_MAGIC_COMMENT_VALUE,
                            (int) key_length,
                            (const char *) key_source,
                            (int) value_length,
                            (const char *) value_start
                        );
                        break;
                    case PM_MAGIC_COMMENT_BOOLEAN_VALUE_FALSE:
                        parser->warn_mismatched_indentation = false;
                        break;
                    case PM_MAGIC_COMMENT_BOOLEAN_VALUE_TRUE:
                        parser->warn_mismatched_indentation = true;
                        break;
                }
            }
        } else if (key_length == 21) {
            if (pm_strncasecmp(key_source, (const uint8_t *) "frozen_string_literal", 21) == 0) {
                // We only want to handle frozen string literal comments if it's
                // before any semantic tokens have been seen.
                if (semantic_token_seen) {
                    pm_parser_warn_token(parser, &parser->current, PM_WARN_IGNORED_FROZEN_STRING_LITERAL);
                } else {
                    switch (parser_lex_magic_comment_boolean_value(value_start, value_length)) {
                        case PM_MAGIC_COMMENT_BOOLEAN_VALUE_INVALID:
                            PM_PARSER_WARN_TOKEN_FORMAT(
                                parser,
                                parser->current,
                                PM_WARN_INVALID_MAGIC_COMMENT_VALUE,
                                (int) key_length,
                                (const char *) key_source,
                                (int) value_length,
                                (const char *) value_start
                            );
                            break;
                        case PM_MAGIC_COMMENT_BOOLEAN_VALUE_FALSE:
                            parser->frozen_string_literal = PM_OPTIONS_FROZEN_STRING_LITERAL_DISABLED;
                            break;
                        case PM_MAGIC_COMMENT_BOOLEAN_VALUE_TRUE:
                            parser->frozen_string_literal = PM_OPTIONS_FROZEN_STRING_LITERAL_ENABLED;
                            break;
                    }
                }
            }
        } else if (key_length == 24) {
            if (pm_strncasecmp(key_source, (const uint8_t *) "shareable_constant_value", 24) == 0) {
                const uint8_t *cursor = parser->current.start;
                while ((cursor > parser->start) && ((cursor[-1] == ' ') || (cursor[-1] == '\t'))) cursor--;

                if (!((cursor == parser->start) || (cursor[-1] == '\n'))) {
                    pm_parser_warn_token(parser, &parser->current, PM_WARN_SHAREABLE_CONSTANT_VALUE_LINE);
                } else if (value_length == 4 && pm_strncasecmp(value_start, (const uint8_t *) "none", 4) == 0) {
                    pm_parser_scope_shareable_constant_set(parser, PM_SCOPE_SHAREABLE_CONSTANT_NONE);
                } else if (value_length == 7 && pm_strncasecmp(value_start, (const uint8_t *) "literal", 7) == 0) {
                    pm_parser_scope_shareable_constant_set(parser, PM_SCOPE_SHAREABLE_CONSTANT_LITERAL);
                } else if (value_length == 23 && pm_strncasecmp(value_start, (const uint8_t *) "experimental_everything", 23) == 0) {
                    pm_parser_scope_shareable_constant_set(parser, PM_SCOPE_SHAREABLE_CONSTANT_EXPERIMENTAL_EVERYTHING);
                } else if (value_length == 17 && pm_strncasecmp(value_start, (const uint8_t *) "experimental_copy", 17) == 0) {
                    pm_parser_scope_shareable_constant_set(parser, PM_SCOPE_SHAREABLE_CONSTANT_EXPERIMENTAL_COPY);
                } else {
                    PM_PARSER_WARN_TOKEN_FORMAT(
                        parser,
                        parser->current,
                        PM_WARN_INVALID_MAGIC_COMMENT_VALUE,
                        (int) key_length,
                        (const char *) key_source,
                        (int) value_length,
                        (const char *) value_start
                    );
                }
            }
        }

        // When we're done, we want to free the string in case we had to
        // allocate memory for it.
        pm_string_free(&key);

        // Allocate a new magic comment node to append to the parser's list.
        pm_magic_comment_t *magic_comment;
        if ((magic_comment = (pm_magic_comment_t *) xcalloc(1, sizeof(pm_magic_comment_t))) != NULL) {
            magic_comment->key_start = key_start;
            magic_comment->value_start = value_start;
            magic_comment->key_length = (uint32_t) key_length;
            magic_comment->value_length = value_length;
            pm_list_append(&parser->magic_comment_list, (pm_list_node_t *) magic_comment);
        }
    }

    return result;
}

/******************************************************************************/
/* Context manipulations                                                      */
/******************************************************************************/

static bool
context_terminator(pm_context_t context, pm_token_t *token) {
    switch (context) {
        case PM_CONTEXT_MAIN:
        case PM_CONTEXT_DEF_PARAMS:
        case PM_CONTEXT_DEFINED:
        case PM_CONTEXT_MULTI_TARGET:
        case PM_CONTEXT_TERNARY:
        case PM_CONTEXT_RESCUE_MODIFIER:
            return token->type == PM_TOKEN_EOF;
        case PM_CONTEXT_DEFAULT_PARAMS:
            return token->type == PM_TOKEN_COMMA || token->type == PM_TOKEN_PARENTHESIS_RIGHT;
        case PM_CONTEXT_PREEXE:
        case PM_CONTEXT_POSTEXE:
            return token->type == PM_TOKEN_BRACE_RIGHT;
        case PM_CONTEXT_MODULE:
        case PM_CONTEXT_CLASS:
        case PM_CONTEXT_SCLASS:
        case PM_CONTEXT_LAMBDA_DO_END:
        case PM_CONTEXT_DEF:
        case PM_CONTEXT_BLOCK_KEYWORDS:
            return token->type == PM_TOKEN_KEYWORD_END || token->type == PM_TOKEN_KEYWORD_RESCUE || token->type == PM_TOKEN_KEYWORD_ENSURE;
        case PM_CONTEXT_WHILE:
        case PM_CONTEXT_UNTIL:
        case PM_CONTEXT_ELSE:
        case PM_CONTEXT_FOR:
        case PM_CONTEXT_BEGIN_ENSURE:
        case PM_CONTEXT_BLOCK_ENSURE:
        case PM_CONTEXT_CLASS_ENSURE:
        case PM_CONTEXT_DEF_ENSURE:
        case PM_CONTEXT_LAMBDA_ENSURE:
        case PM_CONTEXT_MODULE_ENSURE:
        case PM_CONTEXT_SCLASS_ENSURE:
            return token->type == PM_TOKEN_KEYWORD_END;
        case PM_CONTEXT_LOOP_PREDICATE:
            return token->type == PM_TOKEN_KEYWORD_DO || token->type == PM_TOKEN_KEYWORD_THEN;
        case PM_CONTEXT_FOR_INDEX:
            return token->type == PM_TOKEN_KEYWORD_IN;
        case PM_CONTEXT_CASE_WHEN:
            return token->type == PM_TOKEN_KEYWORD_WHEN || token->type == PM_TOKEN_KEYWORD_END || token->type == PM_TOKEN_KEYWORD_ELSE;
        case PM_CONTEXT_CASE_IN:
            return token->type == PM_TOKEN_KEYWORD_IN || token->type == PM_TOKEN_KEYWORD_END || token->type == PM_TOKEN_KEYWORD_ELSE;
        case PM_CONTEXT_IF:
        case PM_CONTEXT_ELSIF:
            return token->type == PM_TOKEN_KEYWORD_ELSE || token->type == PM_TOKEN_KEYWORD_ELSIF || token->type == PM_TOKEN_KEYWORD_END;
        case PM_CONTEXT_UNLESS:
            return token->type == PM_TOKEN_KEYWORD_ELSE || token->type == PM_TOKEN_KEYWORD_END;
        case PM_CONTEXT_EMBEXPR:
            return token->type == PM_TOKEN_EMBEXPR_END;
        case PM_CONTEXT_BLOCK_BRACES:
            return token->type == PM_TOKEN_BRACE_RIGHT;
        case PM_CONTEXT_PARENS:
            return token->type == PM_TOKEN_PARENTHESIS_RIGHT;
        case PM_CONTEXT_BEGIN:
        case PM_CONTEXT_BEGIN_RESCUE:
        case PM_CONTEXT_BLOCK_RESCUE:
        case PM_CONTEXT_CLASS_RESCUE:
        case PM_CONTEXT_DEF_RESCUE:
        case PM_CONTEXT_LAMBDA_RESCUE:
        case PM_CONTEXT_MODULE_RESCUE:
        case PM_CONTEXT_SCLASS_RESCUE:
            return token->type == PM_TOKEN_KEYWORD_ENSURE || token->type == PM_TOKEN_KEYWORD_RESCUE || token->type == PM_TOKEN_KEYWORD_ELSE || token->type == PM_TOKEN_KEYWORD_END;
        case PM_CONTEXT_BEGIN_ELSE:
        case PM_CONTEXT_BLOCK_ELSE:
        case PM_CONTEXT_CLASS_ELSE:
        case PM_CONTEXT_DEF_ELSE:
        case PM_CONTEXT_LAMBDA_ELSE:
        case PM_CONTEXT_MODULE_ELSE:
        case PM_CONTEXT_SCLASS_ELSE:
            return token->type == PM_TOKEN_KEYWORD_ENSURE || token->type == PM_TOKEN_KEYWORD_END;
        case PM_CONTEXT_LAMBDA_BRACES:
            return token->type == PM_TOKEN_BRACE_RIGHT;
        case PM_CONTEXT_PREDICATE:
            return token->type == PM_TOKEN_KEYWORD_THEN || token->type == PM_TOKEN_NEWLINE || token->type == PM_TOKEN_SEMICOLON;
        case PM_CONTEXT_NONE:
            return false;
    }

    return false;
}

/**
 * Returns the context that the given token is found to be terminating, or
 * returns PM_CONTEXT_NONE.
 */
static pm_context_t
context_recoverable(const pm_parser_t *parser, pm_token_t *token) {
    pm_context_node_t *context_node = parser->current_context;

    while (context_node != NULL) {
        if (context_terminator(context_node->context, token)) return context_node->context;
        context_node = context_node->prev;
    }

    return PM_CONTEXT_NONE;
}

static bool
context_push(pm_parser_t *parser, pm_context_t context) {
    pm_context_node_t *context_node = (pm_context_node_t *) xmalloc(sizeof(pm_context_node_t));
    if (context_node == NULL) return false;

    *context_node = (pm_context_node_t) { .context = context, .prev = NULL };

    if (parser->current_context == NULL) {
        parser->current_context = context_node;
    } else {
        context_node->prev = parser->current_context;
        parser->current_context = context_node;
    }

    return true;
}

static void
context_pop(pm_parser_t *parser) {
    pm_context_node_t *prev = parser->current_context->prev;
    xfree(parser->current_context);
    parser->current_context = prev;
}

static bool
context_p(const pm_parser_t *parser, pm_context_t context) {
    pm_context_node_t *context_node = parser->current_context;

    while (context_node != NULL) {
        if (context_node->context == context) return true;
        context_node = context_node->prev;
    }

    return false;
}

static bool
context_def_p(const pm_parser_t *parser) {
    pm_context_node_t *context_node = parser->current_context;

    while (context_node != NULL) {
        switch (context_node->context) {
            case PM_CONTEXT_DEF:
            case PM_CONTEXT_DEF_PARAMS:
            case PM_CONTEXT_DEF_ENSURE:
            case PM_CONTEXT_DEF_RESCUE:
            case PM_CONTEXT_DEF_ELSE:
                return true;
            case PM_CONTEXT_CLASS:
            case PM_CONTEXT_CLASS_ENSURE:
            case PM_CONTEXT_CLASS_RESCUE:
            case PM_CONTEXT_CLASS_ELSE:
            case PM_CONTEXT_MODULE:
            case PM_CONTEXT_MODULE_ENSURE:
            case PM_CONTEXT_MODULE_RESCUE:
            case PM_CONTEXT_MODULE_ELSE:
            case PM_CONTEXT_SCLASS:
            case PM_CONTEXT_SCLASS_ENSURE:
            case PM_CONTEXT_SCLASS_RESCUE:
            case PM_CONTEXT_SCLASS_ELSE:
                return false;
            default:
                context_node = context_node->prev;
        }
    }

    return false;
}

/**
 * Returns a human readable string for the given context, used in error
 * messages.
 */
static const char *
context_human(pm_context_t context) {
    switch (context) {
        case PM_CONTEXT_NONE:
            assert(false && "unreachable");
            return "";
        case PM_CONTEXT_BEGIN: return "begin statement";
        case PM_CONTEXT_BLOCK_BRACES: return "'{'..'}' block";
        case PM_CONTEXT_BLOCK_KEYWORDS: return "'do'..'end' block";
        case PM_CONTEXT_CASE_WHEN: return "'when' clause";
        case PM_CONTEXT_CASE_IN: return "'in' clause";
        case PM_CONTEXT_CLASS: return "class definition";
        case PM_CONTEXT_DEF: return "method definition";
        case PM_CONTEXT_DEF_PARAMS: return "method parameters";
        case PM_CONTEXT_DEFAULT_PARAMS: return "parameter default value";
        case PM_CONTEXT_DEFINED: return "'defined?' expression";
        case PM_CONTEXT_ELSE:
        case PM_CONTEXT_BEGIN_ELSE:
        case PM_CONTEXT_BLOCK_ELSE:
        case PM_CONTEXT_CLASS_ELSE:
        case PM_CONTEXT_DEF_ELSE:
        case PM_CONTEXT_LAMBDA_ELSE:
        case PM_CONTEXT_MODULE_ELSE:
        case PM_CONTEXT_SCLASS_ELSE: return "'else' clause";
        case PM_CONTEXT_ELSIF: return "'elsif' clause";
        case PM_CONTEXT_EMBEXPR: return "embedded expression";
        case PM_CONTEXT_BEGIN_ENSURE:
        case PM_CONTEXT_BLOCK_ENSURE:
        case PM_CONTEXT_CLASS_ENSURE:
        case PM_CONTEXT_DEF_ENSURE:
        case PM_CONTEXT_LAMBDA_ENSURE:
        case PM_CONTEXT_MODULE_ENSURE:
        case PM_CONTEXT_SCLASS_ENSURE: return "'ensure' clause";
        case PM_CONTEXT_FOR: return "for loop";
        case PM_CONTEXT_FOR_INDEX: return "for loop index";
        case PM_CONTEXT_IF: return "if statement";
        case PM_CONTEXT_LAMBDA_BRACES: return "'{'..'}' lambda block";
        case PM_CONTEXT_LAMBDA_DO_END: return "'do'..'end' lambda block";
        case PM_CONTEXT_LOOP_PREDICATE: return "loop predicate";
        case PM_CONTEXT_MAIN: return "top level context";
        case PM_CONTEXT_MODULE: return "module definition";
        case PM_CONTEXT_MULTI_TARGET: return "multiple targets";
        case PM_CONTEXT_PARENS: return "parentheses";
        case PM_CONTEXT_POSTEXE: return "'END' block";
        case PM_CONTEXT_PREDICATE: return "predicate";
        case PM_CONTEXT_PREEXE: return "'BEGIN' block";
        case PM_CONTEXT_BEGIN_RESCUE:
        case PM_CONTEXT_BLOCK_RESCUE:
        case PM_CONTEXT_CLASS_RESCUE:
        case PM_CONTEXT_DEF_RESCUE:
        case PM_CONTEXT_LAMBDA_RESCUE:
        case PM_CONTEXT_MODULE_RESCUE:
        case PM_CONTEXT_RESCUE_MODIFIER:
        case PM_CONTEXT_SCLASS_RESCUE: return "'rescue' clause";
        case PM_CONTEXT_SCLASS: return "singleton class definition";
        case PM_CONTEXT_TERNARY: return "ternary expression";
        case PM_CONTEXT_UNLESS: return "unless statement";
        case PM_CONTEXT_UNTIL: return "until statement";
        case PM_CONTEXT_WHILE: return "while statement";
    }

    assert(false && "unreachable");
    return "";
}

/******************************************************************************/
/* Specific token lexers                                                      */
/******************************************************************************/

static inline void
pm_strspn_number_validate(pm_parser_t *parser, const uint8_t *string, size_t length, const uint8_t *invalid) {
    if (invalid != NULL) {
        pm_diagnostic_id_t diag_id = (invalid == (string + length - 1)) ? PM_ERR_INVALID_NUMBER_UNDERSCORE_TRAILING : PM_ERR_INVALID_NUMBER_UNDERSCORE_INNER;
        pm_parser_err(parser, invalid, invalid + 1, diag_id);
    }
}

static size_t
pm_strspn_binary_number_validate(pm_parser_t *parser, const uint8_t *string) {
    const uint8_t *invalid = NULL;
    size_t length = pm_strspn_binary_number(string, parser->end - string, &invalid);
    pm_strspn_number_validate(parser, string, length, invalid);
    return length;
}

static size_t
pm_strspn_octal_number_validate(pm_parser_t *parser, const uint8_t *string) {
    const uint8_t *invalid = NULL;
    size_t length = pm_strspn_octal_number(string, parser->end - string, &invalid);
    pm_strspn_number_validate(parser, string, length, invalid);
    return length;
}

static size_t
pm_strspn_decimal_number_validate(pm_parser_t *parser, const uint8_t *string) {
    const uint8_t *invalid = NULL;
    size_t length = pm_strspn_decimal_number(string, parser->end - string, &invalid);
    pm_strspn_number_validate(parser, string, length, invalid);
    return length;
}

static size_t
pm_strspn_hexadecimal_number_validate(pm_parser_t *parser, const uint8_t *string) {
    const uint8_t *invalid = NULL;
    size_t length = pm_strspn_hexadecimal_number(string, parser->end - string, &invalid);
    pm_strspn_number_validate(parser, string, length, invalid);
    return length;
}

static pm_token_type_t
lex_optional_float_suffix(pm_parser_t *parser, bool* seen_e) {
    pm_token_type_t type = PM_TOKEN_INTEGER;

    // Here we're going to attempt to parse the optional decimal portion of a
    // float. If it's not there, then it's okay and we'll just continue on.
    if (peek(parser) == '.') {
        if (pm_char_is_decimal_digit(peek_offset(parser, 1))) {
            parser->current.end += 2;
            parser->current.end += pm_strspn_decimal_number_validate(parser, parser->current.end);
            type = PM_TOKEN_FLOAT;
        } else {
            // If we had a . and then something else, then it's not a float
            // suffix on a number it's a method call or something else.
            return type;
        }
    }

    // Here we're going to attempt to parse the optional exponent portion of a
    // float. If it's not there, it's okay and we'll just continue on.
    if ((peek(parser) == 'e') || (peek(parser) == 'E')) {
        if ((peek_offset(parser, 1) == '+') || (peek_offset(parser, 1) == '-')) {
            parser->current.end += 2;

            if (pm_char_is_decimal_digit(peek(parser))) {
                parser->current.end++;
                parser->current.end += pm_strspn_decimal_number_validate(parser, parser->current.end);
            } else {
                pm_parser_err_current(parser, PM_ERR_INVALID_FLOAT_EXPONENT);
            }
        } else if (pm_char_is_decimal_digit(peek_offset(parser, 1))) {
            parser->current.end++;
            parser->current.end += pm_strspn_decimal_number_validate(parser, parser->current.end);
        } else {
            return type;
        }

        *seen_e = true;
        type = PM_TOKEN_FLOAT;
    }

    return type;
}

static pm_token_type_t
lex_numeric_prefix(pm_parser_t *parser, bool* seen_e) {
    pm_token_type_t type = PM_TOKEN_INTEGER;
    *seen_e = false;

    if (peek_offset(parser, -1) == '0') {
        switch (*parser->current.end) {
            // 0d1111 is a decimal number
            case 'd':
            case 'D':
                parser->current.end++;
                if (pm_char_is_decimal_digit(peek(parser))) {
                    parser->current.end += pm_strspn_decimal_number_validate(parser, parser->current.end);
                } else {
                    match(parser, '_');
                    pm_parser_err_current(parser, PM_ERR_INVALID_NUMBER_DECIMAL);
                }

                break;

            // 0b1111 is a binary number
            case 'b':
            case 'B':
                parser->current.end++;
                if (pm_char_is_binary_digit(peek(parser))) {
                    parser->current.end += pm_strspn_binary_number_validate(parser, parser->current.end);
                } else {
                    match(parser, '_');
                    pm_parser_err_current(parser, PM_ERR_INVALID_NUMBER_BINARY);
                }

                parser->integer_base = PM_INTEGER_BASE_FLAGS_BINARY;
                break;

            // 0o1111 is an octal number
            case 'o':
            case 'O':
                parser->current.end++;
                if (pm_char_is_octal_digit(peek(parser))) {
                    parser->current.end += pm_strspn_octal_number_validate(parser, parser->current.end);
                } else {
                    match(parser, '_');
                    pm_parser_err_current(parser, PM_ERR_INVALID_NUMBER_OCTAL);
                }

                parser->integer_base = PM_INTEGER_BASE_FLAGS_OCTAL;
                break;

            // 01111 is an octal number
            case '_':
            case '0':
            case '1':
            case '2':
            case '3':
            case '4':
            case '5':
            case '6':
            case '7':
                parser->current.end += pm_strspn_octal_number_validate(parser, parser->current.end);
                parser->integer_base = PM_INTEGER_BASE_FLAGS_OCTAL;
                break;

            // 0x1111 is a hexadecimal number
            case 'x':
            case 'X':
                parser->current.end++;
                if (pm_char_is_hexadecimal_digit(peek(parser))) {
                    parser->current.end += pm_strspn_hexadecimal_number_validate(parser, parser->current.end);
                } else {
                    match(parser, '_');
                    pm_parser_err_current(parser, PM_ERR_INVALID_NUMBER_HEXADECIMAL);
                }

                parser->integer_base = PM_INTEGER_BASE_FLAGS_HEXADECIMAL;
                break;

            // 0.xxx is a float
            case '.': {
                type = lex_optional_float_suffix(parser, seen_e);
                break;
            }

            // 0exxx is a float
            case 'e':
            case 'E': {
                type = lex_optional_float_suffix(parser, seen_e);
                break;
            }
        }
    } else {
        // If it didn't start with a 0, then we'll lex as far as we can into a
        // decimal number.
        parser->current.end += pm_strspn_decimal_number_validate(parser, parser->current.end);

        // Afterward, we'll lex as far as we can into an optional float suffix.
        type = lex_optional_float_suffix(parser, seen_e);
    }

    // At this point we have a completed number, but we want to provide the user
    // with a good experience if they put an additional .xxx fractional
    // component on the end, so we'll check for that here.
    if (peek_offset(parser, 0) == '.' && pm_char_is_decimal_digit(peek_offset(parser, 1))) {
        const uint8_t *fraction_start = parser->current.end;
        const uint8_t *fraction_end = parser->current.end + 2;
        fraction_end += pm_strspn_decimal_digit(fraction_end, parser->end - fraction_end);
        pm_parser_err(parser, fraction_start, fraction_end, PM_ERR_INVALID_NUMBER_FRACTION);
    }

    return type;
}

static pm_token_type_t
lex_numeric(pm_parser_t *parser) {
    pm_token_type_t type = PM_TOKEN_INTEGER;
    parser->integer_base = PM_INTEGER_BASE_FLAGS_DECIMAL;

    if (parser->current.end < parser->end) {
        bool seen_e = false;
        type = lex_numeric_prefix(parser, &seen_e);

        const uint8_t *end = parser->current.end;
        pm_token_type_t suffix_type = type;

        if (type == PM_TOKEN_INTEGER) {
            if (match(parser, 'r')) {
                suffix_type = PM_TOKEN_INTEGER_RATIONAL;

                if (match(parser, 'i')) {
                    suffix_type = PM_TOKEN_INTEGER_RATIONAL_IMAGINARY;
                }
            } else if (match(parser, 'i')) {
                suffix_type = PM_TOKEN_INTEGER_IMAGINARY;
            }
        } else {
            if (!seen_e && match(parser, 'r')) {
                suffix_type = PM_TOKEN_FLOAT_RATIONAL;

                if (match(parser, 'i')) {
                    suffix_type = PM_TOKEN_FLOAT_RATIONAL_IMAGINARY;
                }
            } else if (match(parser, 'i')) {
                suffix_type = PM_TOKEN_FLOAT_IMAGINARY;
            }
        }

        const uint8_t b = peek(parser);
        if (b != '\0' && (b >= 0x80 || ((b >= 'a' && b <= 'z') || (b >= 'A' && b <= 'Z')) || b == '_')) {
            parser->current.end = end;
        } else {
            type = suffix_type;
        }
    }

    return type;
}

static pm_token_type_t
lex_global_variable(pm_parser_t *parser) {
    if (parser->current.end >= parser->end) {
        pm_parser_err_token(parser, &parser->current, PM_ERR_GLOBAL_VARIABLE_BARE);
        return PM_TOKEN_GLOBAL_VARIABLE;
    }

    // True if multiple characters are allowed after the declaration of the
    // global variable. Not true when it starts with "$-".
    bool allow_multiple = true;

    switch (*parser->current.end) {
        case '~':  // $~: match-data
        case '*':  // $*: argv
        case '$':  // $$: pid
        case '?':  // $?: last status
        case '!':  // $!: error string
        case '@':  // $@: error position
        case '/':  // $/: input record separator
        case '\\': // $\: output record separator
        case ';':  // $;: field separator
        case ',':  // $,: output field separator
        case '.':  // $.: last read line number
        case '=':  // $=: ignorecase
        case ':':  // $:: load path
        case '<':  // $<: reading filename
        case '>':  // $>: default output handle
        case '\"': // $": already loaded files
            parser->current.end++;
            return PM_TOKEN_GLOBAL_VARIABLE;

        case '&':  // $&: last match
        case '`':  // $`: string before last match
        case '\'': // $': string after last match
        case '+':  // $+: string matches last paren.
            parser->current.end++;
            return lex_state_p(parser, PM_LEX_STATE_FNAME) ? PM_TOKEN_GLOBAL_VARIABLE : PM_TOKEN_BACK_REFERENCE;

        case '0': {
            parser->current.end++;
            size_t width;

            if ((width = char_is_identifier(parser, parser->current.end, parser->end - parser->current.end)) > 0) {
                do {
                    parser->current.end += width;
                } while ((width = char_is_identifier(parser, parser->current.end, parser->end - parser->current.end)) > 0);

                // $0 isn't allowed to be followed by anything.
                pm_diagnostic_id_t diag_id = parser->version == PM_OPTIONS_VERSION_CRUBY_3_3 ? PM_ERR_INVALID_VARIABLE_GLOBAL_3_3 : PM_ERR_INVALID_VARIABLE_GLOBAL;
                PM_PARSER_ERR_TOKEN_FORMAT_CONTENT(parser, parser->current, diag_id);
            }

            return PM_TOKEN_GLOBAL_VARIABLE;
        }

        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
            parser->current.end += pm_strspn_decimal_digit(parser->current.end, parser->end - parser->current.end);
            return lex_state_p(parser, PM_LEX_STATE_FNAME) ? PM_TOKEN_GLOBAL_VARIABLE : PM_TOKEN_NUMBERED_REFERENCE;

        case '-':
            parser->current.end++;
            allow_multiple = false;
            PRISM_FALLTHROUGH
        default: {
            size_t width;

            if ((width = char_is_identifier(parser, parser->current.end, parser->end - parser->current.end)) > 0) {
                do {
                    parser->current.end += width;
                } while (allow_multiple && (width = char_is_identifier(parser, parser->current.end, parser->end - parser->current.end)) > 0);
            } else if (pm_char_is_whitespace(peek(parser))) {
                // If we get here, then we have a $ followed by whitespace,
                // which is not allowed.
                pm_parser_err_token(parser, &parser->current, PM_ERR_GLOBAL_VARIABLE_BARE);
            } else {
                // If we get here, then we have a $ followed by something that
                // isn't recognized as a global variable.
                pm_diagnostic_id_t diag_id = parser->version == PM_OPTIONS_VERSION_CRUBY_3_3 ? PM_ERR_INVALID_VARIABLE_GLOBAL_3_3 : PM_ERR_INVALID_VARIABLE_GLOBAL;
                const uint8_t *end = parser->current.end + parser->encoding->char_width(parser->current.end, parser->end - parser->current.end);
                PM_PARSER_ERR_FORMAT(parser, parser->current.start, end, diag_id, (int) (end - parser->current.start), (const char *) parser->current.start);
            }

            return PM_TOKEN_GLOBAL_VARIABLE;
        }
    }
}

/**
 * This function checks if the current token matches a keyword. If it does, it
 * returns the token type. Otherwise, it returns PM_TOKEN_EOF. The arguments are as follows:
 *
 * * `parser` - the parser object
 * * `current_start` - pointer to the start of the current token
 * * `value` - the literal string that we're checking for
 * * `vlen` - the length of the token
 * * `state` - the state that we should transition to if the token matches
 * * `type` - the expected token type
 * * `modifier_type` - the expected modifier token type
 */
static inline pm_token_type_t
lex_keyword(pm_parser_t *parser, const uint8_t *current_start, const char *value, size_t vlen, pm_lex_state_t state, pm_token_type_t type, pm_token_type_t modifier_type) {
    if (memcmp(current_start, value, vlen) == 0) {
        pm_lex_state_t last_state = parser->lex_state;

        if (parser->lex_state & PM_LEX_STATE_FNAME) {
            lex_state_set(parser, PM_LEX_STATE_ENDFN);
        } else {
            lex_state_set(parser, state);
            if (state == PM_LEX_STATE_BEG) {
                parser->command_start = true;
            }

            if ((modifier_type != PM_TOKEN_EOF) && !(last_state & (PM_LEX_STATE_BEG | PM_LEX_STATE_LABELED | PM_LEX_STATE_CLASS))) {
                lex_state_set(parser, PM_LEX_STATE_BEG | PM_LEX_STATE_LABEL);
                return modifier_type;
            }
        }

        return type;
    }

    return PM_TOKEN_EOF;
}

static pm_token_type_t
lex_identifier(pm_parser_t *parser, bool previous_command_start) {
    // Lex as far as we can into the current identifier.
    size_t width;
    const uint8_t *end = parser->end;
    const uint8_t *current_start = parser->current.start;
    const uint8_t *current_end = parser->current.end;
    bool encoding_changed = parser->encoding_changed;

    if (encoding_changed) {
        while ((width = char_is_identifier(parser, current_end, end - current_end)) > 0) {
            current_end += width;
        }
    } else {
        while ((width = char_is_identifier_utf8(current_end, end - current_end)) > 0) {
            current_end += width;
        }
    }
    parser->current.end = current_end;

    // Now cache the length of the identifier so that we can quickly compare it
    // against known keywords.
    width = (size_t) (current_end - current_start);

    if (current_end < end) {
        if (((current_end + 1 >= end) || (current_end[1] != '=')) && (match(parser, '!') || match(parser, '?'))) {
            // First we'll attempt to extend the identifier by a ! or ?. Then we'll
            // check if we're returning the defined? keyword or just an identifier.
            width++;

            if (
                ((lex_state_p(parser, PM_LEX_STATE_LABEL | PM_LEX_STATE_ENDFN) && !previous_command_start) || lex_state_arg_p(parser)) &&
                (peek(parser) == ':') && (peek_offset(parser, 1) != ':')
            ) {
                // If we're in a position where we can accept a : at the end of an
                // identifier, then we'll optionally accept it.
                lex_state_set(parser, PM_LEX_STATE_ARG | PM_LEX_STATE_LABELED);
                (void) match(parser, ':');
                return PM_TOKEN_LABEL;
            }

            if (parser->lex_state != PM_LEX_STATE_DOT) {
                if (width == 8 && (lex_keyword(parser, current_start, "defined?", width, PM_LEX_STATE_ARG, PM_TOKEN_KEYWORD_DEFINED, PM_TOKEN_EOF) != PM_TOKEN_EOF)) {
                    return PM_TOKEN_KEYWORD_DEFINED;
                }
            }

            return PM_TOKEN_METHOD_NAME;
        }

        if (lex_state_p(parser, PM_LEX_STATE_FNAME) && peek_offset(parser, 1) != '~' && peek_offset(parser, 1) != '>' && (peek_offset(parser, 1) != '=' || peek_offset(parser, 2) == '>') && match(parser, '=')) {
            // If we're in a position where we can accept a = at the end of an
            // identifier, then we'll optionally accept it.
            return PM_TOKEN_IDENTIFIER;
        }

        if (
            ((lex_state_p(parser, PM_LEX_STATE_LABEL | PM_LEX_STATE_ENDFN) && !previous_command_start) || lex_state_arg_p(parser)) &&
            peek(parser) == ':' && peek_offset(parser, 1) != ':'
        ) {
            // If we're in a position where we can accept a : at the end of an
            // identifier, then we'll optionally accept it.
            lex_state_set(parser, PM_LEX_STATE_ARG | PM_LEX_STATE_LABELED);
            (void) match(parser, ':');
            return PM_TOKEN_LABEL;
        }
    }

    if (parser->lex_state != PM_LEX_STATE_DOT) {
        pm_token_type_t type;
        switch (width) {
            case 2:
                if (lex_keyword(parser, current_start, "do", width, PM_LEX_STATE_BEG, PM_TOKEN_KEYWORD_DO, PM_TOKEN_EOF) != PM_TOKEN_EOF) {
                    if (pm_do_loop_stack_p(parser)) {
                        return PM_TOKEN_KEYWORD_DO_LOOP;
                    }
                    return PM_TOKEN_KEYWORD_DO;
                }

                if ((type = lex_keyword(parser, current_start, "if", width, PM_LEX_STATE_BEG, PM_TOKEN_KEYWORD_IF, PM_TOKEN_KEYWORD_IF_MODIFIER)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "in", width, PM_LEX_STATE_BEG, PM_TOKEN_KEYWORD_IN, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "or", width, PM_LEX_STATE_BEG, PM_TOKEN_KEYWORD_OR, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                break;
            case 3:
                if ((type = lex_keyword(parser, current_start, "and", width, PM_LEX_STATE_BEG, PM_TOKEN_KEYWORD_AND, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "def", width, PM_LEX_STATE_FNAME, PM_TOKEN_KEYWORD_DEF, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "end", width, PM_LEX_STATE_END, PM_TOKEN_KEYWORD_END, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "END", width, PM_LEX_STATE_END, PM_TOKEN_KEYWORD_END_UPCASE, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "for", width, PM_LEX_STATE_BEG, PM_TOKEN_KEYWORD_FOR, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "nil", width, PM_LEX_STATE_END, PM_TOKEN_KEYWORD_NIL, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "not", width, PM_LEX_STATE_ARG, PM_TOKEN_KEYWORD_NOT, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                break;
            case 4:
                if ((type = lex_keyword(parser, current_start, "case", width, PM_LEX_STATE_BEG, PM_TOKEN_KEYWORD_CASE, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "else", width, PM_LEX_STATE_BEG, PM_TOKEN_KEYWORD_ELSE, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "next", width, PM_LEX_STATE_MID, PM_TOKEN_KEYWORD_NEXT, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "redo", width, PM_LEX_STATE_END, PM_TOKEN_KEYWORD_REDO, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "self", width, PM_LEX_STATE_END, PM_TOKEN_KEYWORD_SELF, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "then", width, PM_LEX_STATE_BEG, PM_TOKEN_KEYWORD_THEN, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "true", width, PM_LEX_STATE_END, PM_TOKEN_KEYWORD_TRUE, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "when", width, PM_LEX_STATE_BEG, PM_TOKEN_KEYWORD_WHEN, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                break;
            case 5:
                if ((type = lex_keyword(parser, current_start, "alias", width, PM_LEX_STATE_FNAME | PM_LEX_STATE_FITEM, PM_TOKEN_KEYWORD_ALIAS, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "begin", width, PM_LEX_STATE_BEG, PM_TOKEN_KEYWORD_BEGIN, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "BEGIN", width, PM_LEX_STATE_END, PM_TOKEN_KEYWORD_BEGIN_UPCASE, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "break", width, PM_LEX_STATE_MID, PM_TOKEN_KEYWORD_BREAK, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "class", width, PM_LEX_STATE_CLASS, PM_TOKEN_KEYWORD_CLASS, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "elsif", width, PM_LEX_STATE_BEG, PM_TOKEN_KEYWORD_ELSIF, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "false", width, PM_LEX_STATE_END, PM_TOKEN_KEYWORD_FALSE, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "retry", width, PM_LEX_STATE_END, PM_TOKEN_KEYWORD_RETRY, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "super", width, PM_LEX_STATE_ARG, PM_TOKEN_KEYWORD_SUPER, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "undef", width, PM_LEX_STATE_FNAME | PM_LEX_STATE_FITEM, PM_TOKEN_KEYWORD_UNDEF, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "until", width, PM_LEX_STATE_BEG, PM_TOKEN_KEYWORD_UNTIL, PM_TOKEN_KEYWORD_UNTIL_MODIFIER)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "while", width, PM_LEX_STATE_BEG, PM_TOKEN_KEYWORD_WHILE, PM_TOKEN_KEYWORD_WHILE_MODIFIER)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "yield", width, PM_LEX_STATE_ARG, PM_TOKEN_KEYWORD_YIELD, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                break;
            case 6:
                if ((type = lex_keyword(parser, current_start, "ensure", width, PM_LEX_STATE_BEG, PM_TOKEN_KEYWORD_ENSURE, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "module", width, PM_LEX_STATE_BEG, PM_TOKEN_KEYWORD_MODULE, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "rescue", width, PM_LEX_STATE_MID, PM_TOKEN_KEYWORD_RESCUE, PM_TOKEN_KEYWORD_RESCUE_MODIFIER)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "return", width, PM_LEX_STATE_MID, PM_TOKEN_KEYWORD_RETURN, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "unless", width, PM_LEX_STATE_BEG, PM_TOKEN_KEYWORD_UNLESS, PM_TOKEN_KEYWORD_UNLESS_MODIFIER)) != PM_TOKEN_EOF) return type;
                break;
            case 8:
                if ((type = lex_keyword(parser, current_start, "__LINE__", width, PM_LEX_STATE_END, PM_TOKEN_KEYWORD___LINE__, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                if ((type = lex_keyword(parser, current_start, "__FILE__", width, PM_LEX_STATE_END, PM_TOKEN_KEYWORD___FILE__, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                break;
            case 12:
                if ((type = lex_keyword(parser, current_start, "__ENCODING__", width, PM_LEX_STATE_END, PM_TOKEN_KEYWORD___ENCODING__, PM_TOKEN_EOF)) != PM_TOKEN_EOF) return type;
                break;
        }
    }

    if (encoding_changed) {
        return parser->encoding->isupper_char(current_start, end - current_start) ? PM_TOKEN_CONSTANT : PM_TOKEN_IDENTIFIER;
    }
    return pm_encoding_utf_8_isupper_char(current_start, end - current_start) ? PM_TOKEN_CONSTANT : PM_TOKEN_IDENTIFIER;
}

/**
 * Returns true if the current token that the parser is considering is at the
 * beginning of a line or the beginning of the source.
 */
static bool
current_token_starts_line(pm_parser_t *parser) {
    return (parser->current.start == parser->start) || (parser->current.start[-1] == '\n');
}

/**
 * When we hit a # while lexing something like a string, we need to potentially
 * handle interpolation. This function performs that check. It returns a token
 * type representing what it found. Those cases are:
 *
 * * PM_TOKEN_NOT_PROVIDED - No interpolation was found at this point. The
 *     caller should keep lexing.
 * * PM_TOKEN_STRING_CONTENT - No interpolation was found at this point. The
 *     caller should return this token type.
 * * PM_TOKEN_EMBEXPR_BEGIN - An embedded expression was found. The caller
 *     should return this token type.
 * * PM_TOKEN_EMBVAR - An embedded variable was found. The caller should return
 *     this token type.
 */
static pm_token_type_t
lex_interpolation(pm_parser_t *parser, const uint8_t *pound) {
    // If there is no content following this #, then we're at the end of
    // the string and we can safely return string content.
    if (pound + 1 >= parser->end) {
        parser->current.end = pound + 1;
        return PM_TOKEN_STRING_CONTENT;
    }

    // Now we'll check against the character that follows the #. If it constitutes
    // valid interplation, we'll handle that, otherwise we'll return
    // PM_TOKEN_NOT_PROVIDED.
    switch (pound[1]) {
        case '@': {
            // In this case we may have hit an embedded instance or class variable.
            if (pound + 2 >= parser->end) {
                parser->current.end = pound + 1;
                return PM_TOKEN_STRING_CONTENT;
            }

            // If we're looking at a @ and there's another @, then we'll skip past the
            // second @.
            const uint8_t *variable = pound + 2;
            if (*variable == '@' && pound + 3 < parser->end) variable++;

            if (char_is_identifier_start(parser, variable, parser->end - variable)) {
                // At this point we're sure that we've either hit an embedded instance
                // or class variable. In this case we'll first need to check if we've
                // already consumed content.
                if (pound > parser->current.start) {
                    parser->current.end = pound;
                    return PM_TOKEN_STRING_CONTENT;
                }

                // Otherwise we need to return the embedded variable token
                // and then switch to the embedded variable lex mode.
                lex_mode_push(parser, (pm_lex_mode_t) { .mode = PM_LEX_EMBVAR });
                parser->current.end = pound + 1;
                return PM_TOKEN_EMBVAR;
            }

            // If we didn't get a valid interpolation, then this is just regular
            // string content. This is like if we get "#@-". In this case the caller
            // should keep lexing.
            parser->current.end = pound + 1;
            return PM_TOKEN_NOT_PROVIDED;
        }
        case '$':
            // In this case we may have hit an embedded global variable. If there's
            // not enough room, then we'll just return string content.
            if (pound + 2 >= parser->end) {
                parser->current.end = pound + 1;
                return PM_TOKEN_STRING_CONTENT;
            }

            // This is the character that we're going to check to see if it is the
            // start of an identifier that would indicate that this is a global
            // variable.
            const uint8_t *check = pound + 2;

            if (pound[2] == '-') {
                if (pound + 3 >= parser->end) {
                    parser->current.end = pound + 2;
                    return PM_TOKEN_STRING_CONTENT;
                }

                check++;
            }

            // If the character that we're going to check is the start of an
            // identifier, or we don't have a - and the character is a decimal number
            // or a global name punctuation character, then we've hit an embedded
            // global variable.
            if (
                char_is_identifier_start(parser, check, parser->end - check) ||
                (pound[2] != '-' && (pm_char_is_decimal_digit(pound[2]) || char_is_global_name_punctuation(pound[2])))
            ) {
                // In this case we've hit an embedded global variable. First check to
                // see if we've already consumed content. If we have, then we need to
                // return that content as string content first.
                if (pound > parser->current.start) {
                    parser->current.end = pound;
                    return PM_TOKEN_STRING_CONTENT;
                }

                // Otherwise, we need to return the embedded variable token and switch
                // to the embedded variable lex mode.
                lex_mode_push(parser, (pm_lex_mode_t) { .mode = PM_LEX_EMBVAR });
                parser->current.end = pound + 1;
                return PM_TOKEN_EMBVAR;
            }

            // In this case we've hit a #$ that does not indicate a global variable.
            // In this case we'll continue lexing past it.
            parser->current.end = pound + 1;
            return PM_TOKEN_NOT_PROVIDED;
        case '{':
            // In this case it's the start of an embedded expression. If we have
            // already consumed content, then we need to return that content as string
            // content first.
            if (pound > parser->current.start) {
                parser->current.end = pound;
                return PM_TOKEN_STRING_CONTENT;
            }

            parser->enclosure_nesting++;

            // Otherwise we'll skip past the #{ and begin lexing the embedded
            // expression.
            lex_mode_push(parser, (pm_lex_mode_t) { .mode = PM_LEX_EMBEXPR });
            parser->current.end = pound + 2;
            parser->command_start = true;
            pm_do_loop_stack_push(parser, false);
            return PM_TOKEN_EMBEXPR_BEGIN;
        default:
            // In this case we've hit a # that doesn't constitute interpolation. We'll
            // mark that by returning the not provided token type. This tells the
            // consumer to keep lexing forward.
            parser->current.end = pound + 1;
            return PM_TOKEN_NOT_PROVIDED;
    }
}

static const uint8_t PM_ESCAPE_FLAG_NONE = 0x0;
static const uint8_t PM_ESCAPE_FLAG_CONTROL = 0x1;
static const uint8_t PM_ESCAPE_FLAG_META = 0x2;
static const uint8_t PM_ESCAPE_FLAG_SINGLE = 0x4;
static const uint8_t PM_ESCAPE_FLAG_REGEXP = 0x8;

/**
 * This is a lookup table for whether or not an ASCII character is printable.
 */
static const bool ascii_printable_chars[] = {
    0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0
};

static inline bool
char_is_ascii_printable(const uint8_t b) {
    return (b < 0x80) && ascii_printable_chars[b];
}

/**
 * Return the value that a hexadecimal digit character represents. For example,
 * transform 'a' into 10, 'b' into 11, etc.
 */
static inline uint8_t
escape_hexadecimal_digit(const uint8_t value) {
    return (uint8_t) ((value <= '9') ? (value - '0') : (value & 0x7) + 9);
}

/**
 * Scan the 4 digits of a Unicode escape into the value. Returns the number of
 * digits scanned. This function assumes that the characters have already been
 * validated.
 */
static inline uint32_t
escape_unicode(pm_parser_t *parser, const uint8_t *string, size_t length) {
    uint32_t value = 0;
    for (size_t index = 0; index < length; index++) {
        if (index != 0) value <<= 4;
        value |= escape_hexadecimal_digit(string[index]);
    }

    // Here we're going to verify that the value is actually a valid Unicode
    // codepoint and not a surrogate pair.
    if (value >= 0xD800 && value <= 0xDFFF) {
        pm_parser_err(parser, string, string + length, PM_ERR_ESCAPE_INVALID_UNICODE);
        return 0xFFFD;
    }

    return value;
}

/**
 * Escape a single character value based on the given flags.
 */
static inline uint8_t
escape_byte(uint8_t value, const uint8_t flags) {
    if (flags & PM_ESCAPE_FLAG_CONTROL) value &= 0x9f;
    if (flags & PM_ESCAPE_FLAG_META) value |= 0x80;
    return value;
}

/**
 * Write a unicode codepoint to the given buffer.
 */
static inline void
escape_write_unicode(pm_parser_t *parser, pm_buffer_t *buffer, const uint8_t flags, const uint8_t *start, const uint8_t *end, uint32_t value) {
    // \u escape sequences in string-like structures implicitly change the
    // encoding to UTF-8 if they are >= 0x80 or if they are used in a character
    // literal.
    if (value >= 0x80 || flags & PM_ESCAPE_FLAG_SINGLE) {
        if (parser->explicit_encoding != NULL && parser->explicit_encoding != PM_ENCODING_UTF_8_ENTRY) {
            PM_PARSER_ERR_FORMAT(parser, start, end, PM_ERR_MIXED_ENCODING, parser->explicit_encoding->name);
        }

        parser->explicit_encoding = PM_ENCODING_UTF_8_ENTRY;
    }

    if (!pm_buffer_append_unicode_codepoint(buffer, value)) {
        pm_parser_err(parser, start, end, PM_ERR_ESCAPE_INVALID_UNICODE);
        pm_buffer_append_byte(buffer, 0xEF);
        pm_buffer_append_byte(buffer, 0xBF);
        pm_buffer_append_byte(buffer, 0xBD);
    }
}

/**
 * When you're writing a byte to the unescape buffer, if the byte is non-ASCII
 * (i.e., the top bit is set) then it locks in the encoding.
 */
static inline void
escape_write_byte_encoded(pm_parser_t *parser, pm_buffer_t *buffer, uint8_t byte) {
    if (byte >= 0x80) {
        if (parser->explicit_encoding != NULL && parser->explicit_encoding == PM_ENCODING_UTF_8_ENTRY && parser->encoding != PM_ENCODING_UTF_8_ENTRY) {
            PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_MIXED_ENCODING, parser->encoding->name);
        }

        parser->explicit_encoding = parser->encoding;
    }

    pm_buffer_append_byte(buffer, byte);
}

/**
 * The regular expression engine doesn't support the same escape sequences as
 * Ruby does. So first we have to read the escape sequence, and then we have to
 * format it like the regular expression engine expects it. For example, in Ruby
 * if we have:
 *
 *     /\M-\C-?/
 *
 * then the first byte is actually 255, so we have to rewrite this as:
 *
 *     /\xFF/
 *
 * Note that in this case there is a literal \ byte in the regular expression
 * source so that the regular expression engine will perform its own unescaping.
 */
static inline void
escape_write_byte(pm_parser_t *parser, pm_buffer_t *buffer, pm_buffer_t *regular_expression_buffer, uint8_t flags, uint8_t byte) {
    if (flags & PM_ESCAPE_FLAG_REGEXP) {
        pm_buffer_append_format(regular_expression_buffer, "\\x%02X", byte);
    }

    escape_write_byte_encoded(parser, buffer, byte);
}

/**
 * Write each byte of the given escaped character into the buffer.
 */
static inline void
escape_write_escape_encoded(pm_parser_t *parser, pm_buffer_t *buffer, pm_buffer_t *regular_expression_buffer, uint8_t flags) {
    size_t width;
    if (parser->encoding_changed) {
        width = parser->encoding->char_width(parser->current.end, parser->end - parser->current.end);
    } else {
        width = pm_encoding_utf_8_char_width(parser->current.end, parser->end - parser->current.end);
    }

    if (width == 1) {
        escape_write_byte(parser, buffer, regular_expression_buffer, flags, escape_byte(*parser->current.end++, flags));
    } else if (width > 1) {
        // Valid multibyte character.  Just ignore escape.
        pm_buffer_t *b = (flags & PM_ESCAPE_FLAG_REGEXP) ? regular_expression_buffer : buffer;
        pm_buffer_append_bytes(b, parser->current.end, width);
        parser->current.end += width;
    } else {
        // Assume the next character wasn't meant to be part of this escape
        // sequence since it is invalid. Add an error and move on.
        parser->current.end++;
        pm_parser_err_current(parser, PM_ERR_ESCAPE_INVALID_CONTROL);
    }
}

/**
 * Warn about using a space or a tab character in an escape, as opposed to using
 * \\s or \\t. Note that we can quite copy the source because the warning
 * message replaces \\c with \\C.
 */
static void
escape_read_warn(pm_parser_t *parser, uint8_t flags, uint8_t flag, const char *type) {
#define FLAG(value) ((value & PM_ESCAPE_FLAG_CONTROL) ? "\\C-" : (value & PM_ESCAPE_FLAG_META) ? "\\M-" : "")

    PM_PARSER_WARN_TOKEN_FORMAT(
        parser,
        parser->current,
        PM_WARN_INVALID_CHARACTER,
        FLAG(flags),
        FLAG(flag),
        type
    );

#undef FLAG
}

/**
 * Read the value of an escape into the buffer.
 */
static void
escape_read(pm_parser_t *parser, pm_buffer_t *buffer, pm_buffer_t *regular_expression_buffer, uint8_t flags) {
    uint8_t peeked = peek(parser);
    switch (peeked) {
        case '\\': {
            parser->current.end++;
            escape_write_byte(parser, buffer, regular_expression_buffer, flags, escape_byte('\\', flags));
            return;
        }
        case '\'': {
            parser->current.end++;
            escape_write_byte(parser, buffer, regular_expression_buffer, flags, escape_byte('\'', flags));
            return;
        }
        case 'a': {
            parser->current.end++;
            escape_write_byte(parser, buffer, regular_expression_buffer, flags, escape_byte('\a', flags));
            return;
        }
        case 'b': {
            parser->current.end++;
            escape_write_byte(parser, buffer, regular_expression_buffer, flags, escape_byte('\b', flags));
            return;
        }
        case 'e': {
            parser->current.end++;
            escape_write_byte(parser, buffer, regular_expression_buffer, flags, escape_byte('\033', flags));
            return;
        }
        case 'f': {
            parser->current.end++;
            escape_write_byte(parser, buffer, regular_expression_buffer, flags, escape_byte('\f', flags));
            return;
        }
        case 'n': {
            parser->current.end++;
            escape_write_byte(parser, buffer, regular_expression_buffer, flags, escape_byte('\n', flags));
            return;
        }
        case 'r': {
            parser->current.end++;
            escape_write_byte(parser, buffer, regular_expression_buffer, flags, escape_byte('\r', flags));
            return;
        }
        case 's': {
            parser->current.end++;
            escape_write_byte(parser, buffer, regular_expression_buffer, flags, escape_byte(' ', flags));
            return;
        }
        case 't': {
            parser->current.end++;
            escape_write_byte(parser, buffer, regular_expression_buffer, flags, escape_byte('\t', flags));
            return;
        }
        case 'v': {
            parser->current.end++;
            escape_write_byte(parser, buffer, regular_expression_buffer, flags, escape_byte('\v', flags));
            return;
        }
        case '0': case '1': case '2': case '3': case '4': case '5': case '6': case '7': {
            uint8_t value = (uint8_t) (*parser->current.end - '0');
            parser->current.end++;

            if (pm_char_is_octal_digit(peek(parser))) {
                value = ((uint8_t) (value << 3)) | ((uint8_t) (*parser->current.end - '0'));
                parser->current.end++;

                if (pm_char_is_octal_digit(peek(parser))) {
                    value = ((uint8_t) (value << 3)) | ((uint8_t) (*parser->current.end - '0'));
                    parser->current.end++;
                }
            }

            value = escape_byte(value, flags);
            escape_write_byte(parser, buffer, regular_expression_buffer, flags, value);
            return;
        }
        case 'x': {
            const uint8_t *start = parser->current.end - 1;

            parser->current.end++;
            uint8_t byte = peek(parser);

            if (pm_char_is_hexadecimal_digit(byte)) {
                uint8_t value = escape_hexadecimal_digit(byte);
                parser->current.end++;

                byte = peek(parser);
                if (pm_char_is_hexadecimal_digit(byte)) {
                    value = (uint8_t) ((value << 4) | escape_hexadecimal_digit(byte));
                    parser->current.end++;
                }

                value = escape_byte(value, flags);
                if (flags & PM_ESCAPE_FLAG_REGEXP) {
                    if (flags & (PM_ESCAPE_FLAG_CONTROL | PM_ESCAPE_FLAG_META)) {
                        pm_buffer_append_format(regular_expression_buffer, "\\x%02X", value);
                    } else {
                        pm_buffer_append_bytes(regular_expression_buffer, start, (size_t) (parser->current.end - start));
                    }
                }

                escape_write_byte_encoded(parser, buffer, value);
            } else {
                pm_parser_err_current(parser, PM_ERR_ESCAPE_INVALID_HEXADECIMAL);
            }

            return;
        }
        case 'u': {
            const uint8_t *start = parser->current.end - 1;
            parser->current.end++;

            if (parser->current.end == parser->end) {
                const uint8_t *start = parser->current.end - 2;
                PM_PARSER_ERR_FORMAT(parser, start, parser->current.end, PM_ERR_ESCAPE_INVALID_UNICODE_SHORT, 2, start);
            } else if (peek(parser) == '{') {
                const uint8_t *unicode_codepoints_start = parser->current.end - 2;
                parser->current.end++;

                size_t whitespace;
                while (true) {
                    if ((whitespace = pm_strspn_inline_whitespace(parser->current.end, parser->end - parser->current.end)) > 0) {
                        parser->current.end += whitespace;
                    } else if (peek(parser) == '\\' && peek_offset(parser, 1) == 'n') {
                        // This is super hacky, but it gets us nicer error
                        // messages because we can still pass it off to the
                        // regular expression engine even if we hit an
                        // unterminated regular expression.
                        parser->current.end += 2;
                    } else {
                        break;
                    }
                }

                const uint8_t *extra_codepoints_start = NULL;
                int codepoints_count = 0;

                while ((parser->current.end < parser->end) && (*parser->current.end != '}')) {
                    const uint8_t *unicode_start = parser->current.end;
                    size_t hexadecimal_length = pm_strspn_hexadecimal_digit(parser->current.end, parser->end - parser->current.end);

                    if (hexadecimal_length > 6) {
                        // \u{nnnn} character literal allows only 1-6 hexadecimal digits
                        pm_parser_err(parser, unicode_start, unicode_start + hexadecimal_length, PM_ERR_ESCAPE_INVALID_UNICODE_LONG);
                    } else if (hexadecimal_length == 0) {
                        // there are not hexadecimal characters

                        if (flags & PM_ESCAPE_FLAG_REGEXP) {
                            // If this is a regular expression, we are going to
                            // let the regular expression engine handle this
                            // error instead of us.
                            pm_buffer_append_bytes(regular_expression_buffer, start, (size_t) (parser->current.end - start));
                        } else {
                            pm_parser_err(parser, parser->current.end, parser->current.end, PM_ERR_ESCAPE_INVALID_UNICODE);
                            pm_parser_err(parser, parser->current.end, parser->current.end, PM_ERR_ESCAPE_INVALID_UNICODE_TERM);
                        }

                        return;
                    }

                    parser->current.end += hexadecimal_length;
                    codepoints_count++;
                    if (flags & PM_ESCAPE_FLAG_SINGLE && codepoints_count == 2) {
                        extra_codepoints_start = unicode_start;
                    }

                    uint32_t value = escape_unicode(parser, unicode_start, hexadecimal_length);
                    escape_write_unicode(parser, buffer, flags, unicode_start, parser->current.end, value);

                    parser->current.end += pm_strspn_inline_whitespace(parser->current.end, parser->end - parser->current.end);
                }

                // ?\u{nnnn} character literal should contain only one codepoint
                // and cannot be like ?\u{nnnn mmmm}.
                if (flags & PM_ESCAPE_FLAG_SINGLE && codepoints_count > 1) {
                    pm_parser_err(parser, extra_codepoints_start, parser->current.end - 1, PM_ERR_ESCAPE_INVALID_UNICODE_LITERAL);
                }

                if (parser->current.end == parser->end) {
                    PM_PARSER_ERR_FORMAT(parser, start, parser->current.end, PM_ERR_ESCAPE_INVALID_UNICODE_LIST, (int) (parser->current.end - start), start);
                } else if (peek(parser) == '}') {
                    parser->current.end++;
                } else {
                    if (flags & PM_ESCAPE_FLAG_REGEXP) {
                        // If this is a regular expression, we are going to let
                        // the regular expression engine handle this error
                        // instead of us.
                        pm_buffer_append_bytes(regular_expression_buffer, start, (size_t) (parser->current.end - start));
                    } else {
                        pm_parser_err(parser, unicode_codepoints_start, parser->current.end, PM_ERR_ESCAPE_INVALID_UNICODE_TERM);
                    }
                }

                if (flags & PM_ESCAPE_FLAG_REGEXP) {
                    pm_buffer_append_bytes(regular_expression_buffer, unicode_codepoints_start, (size_t) (parser->current.end - unicode_codepoints_start));
                }
            } else {
                size_t length = pm_strspn_hexadecimal_digit(parser->current.end, MIN(parser->end - parser->current.end, 4));

                if (length == 0) {
                    if (flags & PM_ESCAPE_FLAG_REGEXP) {
                        pm_buffer_append_bytes(regular_expression_buffer, start, (size_t) (parser->current.end - start));
                    } else {
                        const uint8_t *start = parser->current.end - 2;
                        PM_PARSER_ERR_FORMAT(parser, start, parser->current.end, PM_ERR_ESCAPE_INVALID_UNICODE_SHORT, 2, start);
                    }
                } else if (length == 4) {
                    uint32_t value = escape_unicode(parser, parser->current.end, 4);

                    if (flags & PM_ESCAPE_FLAG_REGEXP) {
                        pm_buffer_append_bytes(regular_expression_buffer, start, (size_t) (parser->current.end + 4 - start));
                    }

                    escape_write_unicode(parser, buffer, flags, start, parser->current.end + 4, value);
                    parser->current.end += 4;
                } else {
                    parser->current.end += length;

                    if (flags & PM_ESCAPE_FLAG_REGEXP) {
                        // If this is a regular expression, we are going to let
                        // the regular expression engine handle this error
                        // instead of us.
                        pm_buffer_append_bytes(regular_expression_buffer, start, (size_t) (parser->current.end - start));
                    } else {
                        pm_parser_err_current(parser, PM_ERR_ESCAPE_INVALID_UNICODE);
                    }
                }
            }

            return;
        }
        case 'c': {
            parser->current.end++;
            if (flags & PM_ESCAPE_FLAG_CONTROL) {
                pm_parser_err_current(parser, PM_ERR_ESCAPE_INVALID_CONTROL_REPEAT);
            }

            if (parser->current.end == parser->end) {
                pm_parser_err_current(parser, PM_ERR_ESCAPE_INVALID_CONTROL);
                return;
            }

            uint8_t peeked = peek(parser);
            switch (peeked) {
                case '?': {
                    parser->current.end++;
                    escape_write_byte(parser, buffer, regular_expression_buffer, flags, escape_byte(0x7f, flags));
                    return;
                }
                case '\\':
                    parser->current.end++;

                    if (match(parser, 'u') || match(parser, 'U')) {
                        pm_parser_err(parser, parser->current.start, parser->current.end, PM_ERR_INVALID_ESCAPE_CHARACTER);
                        return;
                    }

                    escape_read(parser, buffer, regular_expression_buffer, flags | PM_ESCAPE_FLAG_CONTROL);
                    return;
                case ' ':
                    parser->current.end++;
                    escape_read_warn(parser, flags, PM_ESCAPE_FLAG_CONTROL, "\\s");
                    escape_write_byte(parser, buffer, regular_expression_buffer, flags, escape_byte(peeked, flags | PM_ESCAPE_FLAG_CONTROL));
                    return;
                case '\t':
                    parser->current.end++;
                    escape_read_warn(parser, flags, 0, "\\t");
                    escape_write_byte(parser, buffer, regular_expression_buffer, flags, escape_byte(peeked, flags | PM_ESCAPE_FLAG_CONTROL));
                    return;
                default: {
                    if (!char_is_ascii_printable(peeked)) {
                        pm_parser_err_current(parser, PM_ERR_ESCAPE_INVALID_CONTROL);
                        return;
                    }

                    parser->current.end++;
                    escape_write_byte(parser, buffer, regular_expression_buffer, flags, escape_byte(peeked, flags | PM_ESCAPE_FLAG_CONTROL));
                    return;
                }
            }
        }
        case 'C': {
            parser->current.end++;
            if (flags & PM_ESCAPE_FLAG_CONTROL) {
                pm_parser_err_current(parser, PM_ERR_ESCAPE_INVALID_CONTROL_REPEAT);
            }

            if (peek(parser) != '-') {
                size_t width = parser->encoding->char_width(parser->current.end, parser->end - parser->current.end);
                pm_parser_err(parser, parser->current.start, parser->current.end + width, PM_ERR_ESCAPE_INVALID_CONTROL);
                return;
            }

            parser->current.end++;
            if (parser->current.end == parser->end) {
                pm_parser_err_current(parser, PM_ERR_ESCAPE_INVALID_CONTROL);
                return;
            }

            uint8_t peeked = peek(parser);
            switch (peeked) {
                case '?': {
                    parser->current.end++;
                    escape_write_byte(parser, buffer, regular_expression_buffer, flags, escape_byte(0x7f, flags));
                    return;
                }
                case '\\':
                    parser->current.end++;

                    if (match(parser, 'u') || match(parser, 'U')) {
                        pm_parser_err(parser, parser->current.start, parser->current.end, PM_ERR_INVALID_ESCAPE_CHARACTER);
                        return;
                    }

                    escape_read(parser, buffer, regular_expression_buffer, flags | PM_ESCAPE_FLAG_CONTROL);
                    return;
                case ' ':
                    parser->current.end++;
                    escape_read_warn(parser, flags, PM_ESCAPE_FLAG_CONTROL, "\\s");
                    escape_write_byte(parser, buffer, regular_expression_buffer, flags, escape_byte(peeked, flags | PM_ESCAPE_FLAG_CONTROL));
                    return;
                case '\t':
                    parser->current.end++;
                    escape_read_warn(parser, flags, 0, "\\t");
                    escape_write_byte(parser, buffer, regular_expression_buffer, flags, escape_byte(peeked, flags | PM_ESCAPE_FLAG_CONTROL));
                    return;
                default: {
                    if (!char_is_ascii_printable(peeked)) {
                        size_t width = parser->encoding->char_width(parser->current.end, parser->end - parser->current.end);
                        pm_parser_err(parser, parser->current.start, parser->current.end + width, PM_ERR_ESCAPE_INVALID_CONTROL);
                        return;
                    }

                    parser->current.end++;
                    escape_write_byte(parser, buffer, regular_expression_buffer, flags, escape_byte(peeked, flags | PM_ESCAPE_FLAG_CONTROL));
                    return;
                }
            }
        }
        case 'M': {
            parser->current.end++;
            if (flags & PM_ESCAPE_FLAG_META) {
                pm_parser_err_current(parser, PM_ERR_ESCAPE_INVALID_META_REPEAT);
            }

            if (peek(parser) != '-') {
                size_t width = parser->encoding->char_width(parser->current.end, parser->end - parser->current.end);
                pm_parser_err(parser, parser->current.start, parser->current.end + width, PM_ERR_ESCAPE_INVALID_META);
                return;
            }

            parser->current.end++;
            if (parser->current.end == parser->end) {
                pm_parser_err_current(parser, PM_ERR_ESCAPE_INVALID_META);
                return;
            }

            uint8_t peeked = peek(parser);
            switch (peeked) {
                case '\\':
                    parser->current.end++;

                    if (match(parser, 'u') || match(parser, 'U')) {
                        pm_parser_err(parser, parser->current.start, parser->current.end, PM_ERR_INVALID_ESCAPE_CHARACTER);
                        return;
                    }

                    escape_read(parser, buffer, regular_expression_buffer, flags | PM_ESCAPE_FLAG_META);
                    return;
                case ' ':
                    parser->current.end++;
                    escape_read_warn(parser, flags, PM_ESCAPE_FLAG_META, "\\s");
                    escape_write_byte(parser, buffer, regular_expression_buffer, flags, escape_byte(peeked, flags | PM_ESCAPE_FLAG_META));
                    return;
                case '\t':
                    parser->current.end++;
                    escape_read_warn(parser, flags & ((uint8_t) ~PM_ESCAPE_FLAG_CONTROL), PM_ESCAPE_FLAG_META, "\\t");
                    escape_write_byte(parser, buffer, regular_expression_buffer, flags, escape_byte(peeked, flags | PM_ESCAPE_FLAG_META));
                    return;
                default:
                    if (!char_is_ascii_printable(peeked)) {
                        size_t width = parser->encoding->char_width(parser->current.end, parser->end - parser->current.end);
                        pm_parser_err(parser, parser->current.start, parser->current.end + width, PM_ERR_ESCAPE_INVALID_META);
                        return;
                    }

                    parser->current.end++;
                    escape_write_byte(parser, buffer, regular_expression_buffer, flags, escape_byte(peeked, flags | PM_ESCAPE_FLAG_META));
                    return;
            }
        }
        case '\r': {
            if (peek_offset(parser, 1) == '\n') {
                parser->current.end += 2;
                escape_write_byte_encoded(parser, buffer, escape_byte('\n', flags));
                return;
            }
            PRISM_FALLTHROUGH
        }
        default: {
            if ((flags & (PM_ESCAPE_FLAG_CONTROL | PM_ESCAPE_FLAG_META)) && !char_is_ascii_printable(peeked)) {
                size_t width = parser->encoding->char_width(parser->current.end, parser->end - parser->current.end);
                pm_parser_err(parser, parser->current.start, parser->current.end + width, PM_ERR_ESCAPE_INVALID_META);
                return;
            }
            if (parser->current.end < parser->end) {
                escape_write_escape_encoded(parser, buffer, regular_expression_buffer, flags);
            } else {
                pm_parser_err_current(parser, PM_ERR_INVALID_ESCAPE_CHARACTER);
            }
            return;
        }
    }
}

/**
 * This function is responsible for lexing either a character literal or the ?
 * operator. The supported character literals are described below.
 *
 * \\a            bell, ASCII 07h (BEL)
 * \\b            backspace, ASCII 08h (BS)
 * \t             horizontal tab, ASCII 09h (TAB)
 * \\n            newline (line feed), ASCII 0Ah (LF)
 * \v             vertical tab, ASCII 0Bh (VT)
 * \f             form feed, ASCII 0Ch (FF)
 * \r             carriage return, ASCII 0Dh (CR)
 * \\e            escape, ASCII 1Bh (ESC)
 * \s             space, ASCII 20h (SPC)
 * \\             backslash
 * \nnn           octal bit pattern, where nnn is 1-3 octal digits ([0-7])
 * \xnn           hexadecimal bit pattern, where nn is 1-2 hexadecimal digits ([0-9a-fA-F])
 * \unnnn         Unicode character, where nnnn is exactly 4 hexadecimal digits ([0-9a-fA-F])
 * \u{nnnn ...}   Unicode character(s), where each nnnn is 1-6 hexadecimal digits ([0-9a-fA-F])
 * \cx or \C-x    control character, where x is an ASCII printable character
 * \M-x           meta character, where x is an ASCII printable character
 * \M-\C-x        meta control character, where x is an ASCII printable character
 * \M-\cx         same as above
 * \\c\M-x        same as above
 * \\c? or \C-?   delete, ASCII 7Fh (DEL)
 */
static pm_token_type_t
lex_question_mark(pm_parser_t *parser) {
    if (lex_state_end_p(parser)) {
        lex_state_set(parser, PM_LEX_STATE_BEG);
        return PM_TOKEN_QUESTION_MARK;
    }

    if (parser->current.end >= parser->end) {
        pm_parser_err_current(parser, PM_ERR_INCOMPLETE_QUESTION_MARK);
        pm_string_shared_init(&parser->current_string, parser->current.start + 1, parser->current.end);
        return PM_TOKEN_CHARACTER_LITERAL;
    }

    if (pm_char_is_whitespace(*parser->current.end)) {
        lex_state_set(parser, PM_LEX_STATE_BEG);
        return PM_TOKEN_QUESTION_MARK;
    }

    lex_state_set(parser, PM_LEX_STATE_BEG);

    if (match(parser, '\\')) {
        lex_state_set(parser, PM_LEX_STATE_END);

        pm_buffer_t buffer;
        pm_buffer_init_capacity(&buffer, 3);

        escape_read(parser, &buffer, NULL, PM_ESCAPE_FLAG_SINGLE);
        pm_string_owned_init(&parser->current_string, (uint8_t *) buffer.value, buffer.length);

        return PM_TOKEN_CHARACTER_LITERAL;
    } else {
        size_t encoding_width = parser->encoding->char_width(parser->current.end, parser->end - parser->current.end);

        // Ternary operators can have a ? immediately followed by an identifier
        // which starts with an underscore. We check for this case here.
        if (
            !(parser->encoding->alnum_char(parser->current.end, parser->end - parser->current.end) || peek(parser) == '_') ||
            (
                (parser->current.end + encoding_width >= parser->end) ||
                !char_is_identifier(parser, parser->current.end + encoding_width, parser->end - (parser->current.end + encoding_width))
            )
        ) {
            lex_state_set(parser, PM_LEX_STATE_END);
            parser->current.end += encoding_width;
            pm_string_shared_init(&parser->current_string, parser->current.start + 1, parser->current.end);
            return PM_TOKEN_CHARACTER_LITERAL;
        }
    }

    return PM_TOKEN_QUESTION_MARK;
}

/**
 * Lex a variable that starts with an @ sign (either an instance or class
 * variable).
 */
static pm_token_type_t
lex_at_variable(pm_parser_t *parser) {
    pm_token_type_t type = match(parser, '@') ? PM_TOKEN_CLASS_VARIABLE : PM_TOKEN_INSTANCE_VARIABLE;
    const uint8_t *end = parser->end;

    size_t width;
    if ((width = char_is_identifier_start(parser, parser->current.end, end - parser->current.end)) > 0) {
        parser->current.end += width;

        while ((width = char_is_identifier(parser, parser->current.end, end - parser->current.end)) > 0) {
            parser->current.end += width;
        }
    } else if (parser->current.end < end && pm_char_is_decimal_digit(*parser->current.end)) {
        pm_diagnostic_id_t diag_id = (type == PM_TOKEN_CLASS_VARIABLE) ? PM_ERR_INCOMPLETE_VARIABLE_CLASS : PM_ERR_INCOMPLETE_VARIABLE_INSTANCE;
        if (parser->version == PM_OPTIONS_VERSION_CRUBY_3_3) {
            diag_id = (type == PM_TOKEN_CLASS_VARIABLE) ? PM_ERR_INCOMPLETE_VARIABLE_CLASS_3_3 : PM_ERR_INCOMPLETE_VARIABLE_INSTANCE_3_3;
        }

        size_t width = parser->encoding->char_width(parser->current.end, end - parser->current.end);
        PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, diag_id, (int) ((parser->current.end + width) - parser->current.start), (const char *) parser->current.start);
    } else {
        pm_diagnostic_id_t diag_id = (type == PM_TOKEN_CLASS_VARIABLE) ? PM_ERR_CLASS_VARIABLE_BARE : PM_ERR_INSTANCE_VARIABLE_BARE;
        pm_parser_err_token(parser, &parser->current, diag_id);
    }

    // If we're lexing an embedded variable, then we need to pop back into the
    // parent lex context.
    if (parser->lex_modes.current->mode == PM_LEX_EMBVAR) {
        lex_mode_pop(parser);
    }

    return type;
}

/**
 * Optionally call out to the lex callback if one is provided.
 */
static inline void
parser_lex_callback(pm_parser_t *parser) {
    if (parser->lex_callback) {
        parser->lex_callback->callback(parser->lex_callback->data, parser, &parser->current);
    }
}

/**
 * Return a new comment node of the specified type.
 */
static inline pm_comment_t *
parser_comment(pm_parser_t *parser, pm_comment_type_t type) {
    pm_comment_t *comment = (pm_comment_t *) xcalloc(1, sizeof(pm_comment_t));
    if (comment == NULL) return NULL;

    *comment = (pm_comment_t) {
        .type = type,
        .location = { parser->current.start, parser->current.end }
    };

    return comment;
}

/**
 * Lex out embedded documentation, and return when we have either hit the end of
 * the file or the end of the embedded documentation. This calls the callback
 * manually because only the lexer should see these tokens, not the parser.
 */
static pm_token_type_t
lex_embdoc(pm_parser_t *parser) {
    // First, lex out the EMBDOC_BEGIN token.
    const uint8_t *newline = next_newline(parser->current.end, parser->end - parser->current.end);

    if (newline == NULL) {
        parser->current.end = parser->end;
    } else {
        pm_newline_list_append(&parser->newline_list, newline);
        parser->current.end = newline + 1;
    }

    parser->current.type = PM_TOKEN_EMBDOC_BEGIN;
    parser_lex_callback(parser);

    // Now, create a comment that is going to be attached to the parser.
    pm_comment_t *comment = parser_comment(parser, PM_COMMENT_EMBDOC);
    if (comment == NULL) return PM_TOKEN_EOF;

    // Now, loop until we find the end of the embedded documentation or the end
    // of the file.
    while (parser->current.end + 4 <= parser->end) {
        parser->current.start = parser->current.end;

        // If we've hit the end of the embedded documentation then we'll return
        // that token here.
        if (
            (memcmp(parser->current.end, "=end", 4) == 0) &&
            (
                (parser->current.end + 4 == parser->end) || // end of file
                pm_char_is_whitespace(parser->current.end[4]) || // whitespace
                (parser->current.end[4] == '\0') || // NUL or end of script
                (parser->current.end[4] == '\004') || // ^D
                (parser->current.end[4] == '\032') // ^Z
            )
        ) {
            const uint8_t *newline = next_newline(parser->current.end, parser->end - parser->current.end);

            if (newline == NULL) {
                parser->current.end = parser->end;
            } else {
                pm_newline_list_append(&parser->newline_list, newline);
                parser->current.end = newline + 1;
            }

            parser->current.type = PM_TOKEN_EMBDOC_END;
            parser_lex_callback(parser);

            comment->location.end = parser->current.end;
            pm_list_append(&parser->comment_list, (pm_list_node_t *) comment);

            return PM_TOKEN_EMBDOC_END;
        }

        // Otherwise, we'll parse until the end of the line and return a line of
        // embedded documentation.
        const uint8_t *newline = next_newline(parser->current.end, parser->end - parser->current.end);

        if (newline == NULL) {
            parser->current.end = parser->end;
        } else {
            pm_newline_list_append(&parser->newline_list, newline);
            parser->current.end = newline + 1;
        }

        parser->current.type = PM_TOKEN_EMBDOC_LINE;
        parser_lex_callback(parser);
    }

    pm_parser_err_current(parser, PM_ERR_EMBDOC_TERM);

    comment->location.end = parser->current.end;
    pm_list_append(&parser->comment_list, (pm_list_node_t *) comment);

    return PM_TOKEN_EOF;
}

/**
 * Set the current type to an ignored newline and then call the lex callback.
 * This happens in a couple places depending on whether or not we have already
 * lexed a comment.
 */
static inline void
parser_lex_ignored_newline(pm_parser_t *parser) {
    parser->current.type = PM_TOKEN_IGNORED_NEWLINE;
    parser_lex_callback(parser);
}

/**
 * This function will be called when a newline is encountered. In some newlines,
 * we need to check if there is a heredoc or heredocs that we have already lexed
 * the body of that we need to now skip past. That will be indicated by the
 * heredoc_end field on the parser.
 *
 * If it is set, then we need to skip past the heredoc body and then clear the
 * heredoc_end field.
 */
static inline void
parser_flush_heredoc_end(pm_parser_t *parser) {
    assert(parser->heredoc_end <= parser->end);
    parser->next_start = parser->heredoc_end;
    parser->heredoc_end = NULL;
}

/**
 * Returns true if the parser has lexed the last token on the current line.
*/
static bool
parser_end_of_line_p(const pm_parser_t *parser) {
    const uint8_t *cursor = parser->current.end;

    while (cursor < parser->end && *cursor != '\n' && *cursor != '#') {
        if (!pm_char_is_inline_whitespace(*cursor++)) return false;
    }

    return true;
}

/**
 * When we're lexing certain types (strings, symbols, lists, etc.) we have
 * string content associated with the tokens. For example:
 *
 *     "foo"
 *
 * In this case, the string content is foo. Since there is no escaping, there's
 * no need to track additional information and the token can be returned as
 * normal. However, if we have escape sequences:
 *
 *     "foo\n"
 *
 * then the bytes in the string are "f", "o", "o", "\", "n", but we want to
 * provide our consumers with the string content "f", "o", "o", "\n". In these
 * cases, when we find the first escape sequence, we initialize a pm_buffer_t
 * to keep track of the string content. Then in the parser, it will
 * automatically attach the string content to the node that it belongs to.
 */
typedef struct {
    /**
     * The buffer that we're using to keep track of the string content. It will
     * only be initialized if we receive an escape sequence.
     */
    pm_buffer_t buffer;

    /**
     * The cursor into the source string that points to how far we have
     * currently copied into the buffer.
     */
    const uint8_t *cursor;
} pm_token_buffer_t;

/**
 * In order to properly set a regular expression's encoding and to validate
 * the byte sequence for the underlying encoding we must process any escape
 * sequences. The unescaped byte sequence will be stored in `buffer` just like
 * for other string-like types. However, we also need to store the regular
 * expression's source string. That string may be different from what we see
 * during lexing because some escape sequences rewrite the source.
 *
 * This value will only be initialized for regular expressions and only if we
 * receive an escape sequence. It will contain the regular expression's source
 * string's byte sequence.
 */
typedef struct {
    /** The embedded base buffer. */
    pm_token_buffer_t base;

    /** The buffer holding the regexp source. */
    pm_buffer_t regexp_buffer;
} pm_regexp_token_buffer_t;

/**
 * Push the given byte into the token buffer.
 */
static inline void
pm_token_buffer_push_byte(pm_token_buffer_t *token_buffer, uint8_t byte) {
    pm_buffer_append_byte(&token_buffer->buffer, byte);
}

static inline void
pm_regexp_token_buffer_push_byte(pm_regexp_token_buffer_t *token_buffer, uint8_t byte) {
    pm_buffer_append_byte(&token_buffer->regexp_buffer, byte);
}

/**
 * Return the width of the character at the end of the current token.
 */
static inline size_t
parser_char_width(const pm_parser_t *parser) {
    size_t width;
    if (parser->encoding_changed) {
        width = parser->encoding->char_width(parser->current.end, parser->end - parser->current.end);
    } else {
        width = pm_encoding_utf_8_char_width(parser->current.end, parser->end - parser->current.end);
    }

    // TODO: If the character is invalid in the given encoding, then we'll just
    // push one byte into the buffer. This should actually be an error.
    return (width == 0 ? 1 : width);
}

/**
 * Push an escaped character into the token buffer.
 */
static void
pm_token_buffer_push_escaped(pm_token_buffer_t *token_buffer, pm_parser_t *parser) {
    size_t width = parser_char_width(parser);
    pm_buffer_append_bytes(&token_buffer->buffer, parser->current.end, width);
    parser->current.end += width;
}

static void
pm_regexp_token_buffer_push_escaped(pm_regexp_token_buffer_t *token_buffer, pm_parser_t *parser) {
    size_t width = parser_char_width(parser);
    pm_buffer_append_bytes(&token_buffer->base.buffer, parser->current.end, width);
    pm_buffer_append_bytes(&token_buffer->regexp_buffer, parser->current.end, width);
    parser->current.end += width;
}

static bool
pm_slice_ascii_only_p(const uint8_t *value, size_t length) {
    for (size_t index = 0; index < length; index++) {
        if (value[index] & 0x80) return false;
    }

    return true;
}

/**
 * When we're about to return from lexing the current token and we know for sure
 * that we have found an escape sequence, this function is called to copy the
 * contents of the token buffer into the current string on the parser so that it
 * can be attached to the correct node.
 */
static inline void
pm_token_buffer_copy(pm_parser_t *parser, pm_token_buffer_t *token_buffer) {
    pm_string_owned_init(&parser->current_string, (uint8_t *) pm_buffer_value(&token_buffer->buffer), pm_buffer_length(&token_buffer->buffer));
}

static inline void
pm_regexp_token_buffer_copy(pm_parser_t *parser, pm_regexp_token_buffer_t *token_buffer) {
    pm_string_owned_init(&parser->current_string, (uint8_t *) pm_buffer_value(&token_buffer->base.buffer), pm_buffer_length(&token_buffer->base.buffer));
    parser->current_regular_expression_ascii_only = pm_slice_ascii_only_p((const uint8_t *) pm_buffer_value(&token_buffer->regexp_buffer), pm_buffer_length(&token_buffer->regexp_buffer));
    pm_buffer_free(&token_buffer->regexp_buffer);
}

/**
 * When we're about to return from lexing the current token, we need to flush
 * all of the content that we have pushed into the buffer into the current
 * string. If we haven't pushed anything into the buffer, this means that we
 * never found an escape sequence, so we can directly reference the bounds of
 * the current string. Either way, at the return of this function it is expected
 * that parser->current_string is established in such a way that it can be
 * attached to a node.
 */
static void
pm_token_buffer_flush(pm_parser_t *parser, pm_token_buffer_t *token_buffer) {
    if (token_buffer->cursor == NULL) {
        pm_string_shared_init(&parser->current_string, parser->current.start, parser->current.end);
    } else {
        pm_buffer_append_bytes(&token_buffer->buffer, token_buffer->cursor, (size_t) (parser->current.end - token_buffer->cursor));
        pm_token_buffer_copy(parser, token_buffer);
    }
}

static void
pm_regexp_token_buffer_flush(pm_parser_t *parser, pm_regexp_token_buffer_t *token_buffer) {
    if (token_buffer->base.cursor == NULL) {
        pm_string_shared_init(&parser->current_string, parser->current.start, parser->current.end);
        parser->current_regular_expression_ascii_only = pm_slice_ascii_only_p(parser->current.start, (size_t) (parser->current.end - parser->current.start));
    } else {
        pm_buffer_append_bytes(&token_buffer->base.buffer, token_buffer->base.cursor, (size_t) (parser->current.end - token_buffer->base.cursor));
        pm_buffer_append_bytes(&token_buffer->regexp_buffer, token_buffer->base.cursor, (size_t) (parser->current.end - token_buffer->base.cursor));
        pm_regexp_token_buffer_copy(parser, token_buffer);
    }
}

#define PM_TOKEN_BUFFER_DEFAULT_SIZE 16

/**
 * When we've found an escape sequence, we need to copy everything up to this
 * point into the buffer because we're about to provide a string that has
 * different content than a direct slice of the source.
 *
 * It is expected that the parser's current token end will be pointing at one
 * byte past the backslash that starts the escape sequence.
 */
static void
pm_token_buffer_escape(pm_parser_t *parser, pm_token_buffer_t *token_buffer) {
    const uint8_t *start;
    if (token_buffer->cursor == NULL) {
        pm_buffer_init_capacity(&token_buffer->buffer, PM_TOKEN_BUFFER_DEFAULT_SIZE);
        start = parser->current.start;
    } else {
        start = token_buffer->cursor;
    }

    const uint8_t *end = parser->current.end - 1;
    assert(end >= start);
    pm_buffer_append_bytes(&token_buffer->buffer, start, (size_t) (end - start));

    token_buffer->cursor = end;
}

static void
pm_regexp_token_buffer_escape(pm_parser_t *parser, pm_regexp_token_buffer_t *token_buffer) {
    const uint8_t *start;
    if (token_buffer->base.cursor == NULL) {
        pm_buffer_init_capacity(&token_buffer->base.buffer, PM_TOKEN_BUFFER_DEFAULT_SIZE);
        pm_buffer_init_capacity(&token_buffer->regexp_buffer, PM_TOKEN_BUFFER_DEFAULT_SIZE);
        start = parser->current.start;
    } else {
        start = token_buffer->base.cursor;
    }

    const uint8_t *end = parser->current.end - 1;
    pm_buffer_append_bytes(&token_buffer->base.buffer, start, (size_t) (end - start));
    pm_buffer_append_bytes(&token_buffer->regexp_buffer, start, (size_t) (end - start));

    token_buffer->base.cursor = end;
}

#undef PM_TOKEN_BUFFER_DEFAULT_SIZE

/**
 * Effectively the same thing as pm_strspn_inline_whitespace, but in the case of
 * a tilde heredoc expands out tab characters to the nearest tab boundaries.
 */
static inline size_t
pm_heredoc_strspn_inline_whitespace(pm_parser_t *parser, const uint8_t **cursor, pm_heredoc_indent_t indent) {
    size_t whitespace = 0;

    switch (indent) {
        case PM_HEREDOC_INDENT_NONE:
            // Do nothing, we can't match a terminator with
            // indentation and there's no need to calculate common
            // whitespace.
            break;
        case PM_HEREDOC_INDENT_DASH:
            // Skip past inline whitespace.
            *cursor += pm_strspn_inline_whitespace(*cursor, parser->end - *cursor);
            break;
        case PM_HEREDOC_INDENT_TILDE:
            // Skip past inline whitespace and calculate common
            // whitespace.
            while (*cursor < parser->end && pm_char_is_inline_whitespace(**cursor)) {
                if (**cursor == '\t') {
                    whitespace = (whitespace / PM_TAB_WHITESPACE_SIZE + 1) * PM_TAB_WHITESPACE_SIZE;
                } else {
                    whitespace++;
                }
                (*cursor)++;
            }

            break;
    }

    return whitespace;
}

/**
 * Lex past the delimiter of a percent literal. Handle newlines and heredocs
 * appropriately.
 */
static uint8_t
pm_lex_percent_delimiter(pm_parser_t *parser) {
    size_t eol_length = match_eol(parser);

    if (eol_length) {
        if (parser->heredoc_end) {
            // If we have already lexed a heredoc, then the newline has already
            // been added to the list. In this case we want to just flush the
            // heredoc end.
            parser_flush_heredoc_end(parser);
        } else {
            // Otherwise, we'll add the newline to the list of newlines.
            pm_newline_list_append(&parser->newline_list, parser->current.end + eol_length - 1);
        }

        uint8_t delimiter = *parser->current.end;

        // If our delimiter is \r\n, we want to treat it as if it's \n.
        // For example, %\r\nfoo\r\n should be "foo"
        if (eol_length == 2) {
            delimiter = *(parser->current.end + 1);
        }

        parser->current.end += eol_length;
        return delimiter;
    }

    return *parser->current.end++;
}

/**
 * This is a convenience macro that will set the current token type, call the
 * lex callback, and then return from the parser_lex function.
 */
#define LEX(token_type) parser->current.type = token_type; parser_lex_callback(parser); return

/**
 * Called when the parser requires a new token. The parser maintains a moving
 * window of two tokens at a time: parser.previous and parser.current. This
 * function will move the current token into the previous token and then
 * lex a new token into the current token.
 */
static void
parser_lex(pm_parser_t *parser) {
    assert(parser->current.end <= parser->end);
    parser->previous = parser->current;

    // This value mirrors cmd_state from CRuby.
    bool previous_command_start = parser->command_start;
    parser->command_start = false;

    // This is used to communicate to the newline lexing function that we've
    // already seen a comment.
    bool lexed_comment = false;

    // Here we cache the current value of the semantic token seen flag. This is
    // used to reset it in case we find a token that shouldn't flip this flag.
    unsigned int semantic_token_seen = parser->semantic_token_seen;
    parser->semantic_token_seen = true;

    switch (parser->lex_modes.current->mode) {
        case PM_LEX_DEFAULT:
        case PM_LEX_EMBEXPR:
        case PM_LEX_EMBVAR:

        // We have a specific named label here because we are going to jump back to
        // this location in the event that we have lexed a token that should not be
        // returned to the parser. This includes comments, ignored newlines, and
        // invalid tokens of some form.
        lex_next_token: {
            // If we have the special next_start pointer set, then we're going to jump
            // to that location and start lexing from there.
            if (parser->next_start != NULL) {
                parser->current.end = parser->next_start;
                parser->next_start = NULL;
            }

            // This value mirrors space_seen from CRuby. It tracks whether or not
            // space has been eaten before the start of the next token.
            bool space_seen = false;

            // First, we're going to skip past any whitespace at the front of the next
            // token.
            bool chomping = true;
            while (parser->current.end < parser->end && chomping) {
                switch (*parser->current.end) {
                    case ' ':
                    case '\t':
                    case '\f':
                    case '\v':
                        parser->current.end++;
                        space_seen = true;
                        break;
                    case '\r':
                        if (match_eol_offset(parser, 1)) {
                            chomping = false;
                        } else {
                            pm_parser_warn(parser, parser->current.end, parser->current.end + 1, PM_WARN_UNEXPECTED_CARRIAGE_RETURN);
                            parser->current.end++;
                            space_seen = true;
                        }
                        break;
                    case '\\': {
                        size_t eol_length = match_eol_offset(parser, 1);
                        if (eol_length) {
                            if (parser->heredoc_end) {
                                parser->current.end = parser->heredoc_end;
                                parser->heredoc_end = NULL;
                            } else {
                                parser->current.end += eol_length + 1;
                                pm_newline_list_append(&parser->newline_list, parser->current.end - 1);
                                space_seen = true;
                            }
                        } else if (pm_char_is_inline_whitespace(*parser->current.end)) {
                            parser->current.end += 2;
                        } else {
                            chomping = false;
                        }

                        break;
                    }
                    default:
                        chomping = false;
                        break;
                }
            }

            // Next, we'll set to start of this token to be the current end.
            parser->current.start = parser->current.end;

            // We'll check if we're at the end of the file. If we are, then we
            // need to return the EOF token.
            if (parser->current.end >= parser->end) {
                // If we hit EOF, but the EOF came immediately after a newline,
                // set the start of the token to the newline.  This way any EOF
                // errors will be reported as happening on that line rather than
                // a line after.  For example "foo(\n" should report an error
                // on line 1 even though EOF technically occurs on line 2.
                if (parser->current.start > parser->start && (*(parser->current.start - 1) == '\n')) {
                    parser->current.start -= 1;
                }
                LEX(PM_TOKEN_EOF);
            }

            // Finally, we'll check the current character to determine the next
            // token.
            switch (*parser->current.end++) {
                case '\0':   // NUL or end of script
                case '\004': // ^D
                case '\032': // ^Z
                    parser->current.end--;
                    LEX(PM_TOKEN_EOF);

                case '#': { // comments
                    const uint8_t *ending = next_newline(parser->current.end, parser->end - parser->current.end);
                    parser->current.end = ending == NULL ? parser->end : ending;

                    // If we found a comment while lexing, then we're going to
                    // add it to the list of comments in the file and keep
                    // lexing.
                    pm_comment_t *comment = parser_comment(parser, PM_COMMENT_INLINE);
                    pm_list_append(&parser->comment_list, (pm_list_node_t *) comment);

                    if (ending) parser->current.end++;
                    parser->current.type = PM_TOKEN_COMMENT;
                    parser_lex_callback(parser);

                    // Here, parse the comment to see if it's a magic comment
                    // and potentially change state on the parser.
                    if (!parser_lex_magic_comment(parser, semantic_token_seen) && (parser->current.start == parser->encoding_comment_start)) {
                        ptrdiff_t length = parser->current.end - parser->current.start;

                        // If we didn't find a magic comment within the first
                        // pass and we're at the start of the file, then we need
                        // to do another pass to potentially find other patterns
                        // for encoding comments.
                        if (length >= 10 && !parser->encoding_locked) {
                            parser_lex_magic_comment_encoding(parser);
                        }
                    }

                    lexed_comment = true;
                }
                PRISM_FALLTHROUGH
                case '\r':
                case '\n': {
                    parser->semantic_token_seen = semantic_token_seen & 0x1;
                    size_t eol_length = match_eol_at(parser, parser->current.end - 1);

                    if (eol_length) {
                        // The only way you can have carriage returns in this
                        // particular loop is if you have a carriage return
                        // followed by a newline. In that case we'll just skip
                        // over the carriage return and continue lexing, in
                        // order to make it so that the newline token
                        // encapsulates both the carriage return and the
                        // newline. Note that we need to check that we haven't
                        // already lexed a comment here because that falls
                        // through into here as well.
                        if (!lexed_comment) {
                            parser->current.end += eol_length - 1; // skip CR
                        }

                        if (parser->heredoc_end == NULL) {
                            pm_newline_list_append(&parser->newline_list, parser->current.end - 1);
                        }
                    }

                    if (parser->heredoc_end) {
                        parser_flush_heredoc_end(parser);
                    }

                    // If this is an ignored newline, then we can continue lexing after
                    // calling the callback with the ignored newline token.
                    switch (lex_state_ignored_p(parser)) {
                        case PM_IGNORED_NEWLINE_NONE:
                            break;
                        case PM_IGNORED_NEWLINE_PATTERN:
                            if (parser->pattern_matching_newlines || parser->in_keyword_arg) {
                                if (!lexed_comment) parser_lex_ignored_newline(parser);
                                lex_state_set(parser, PM_LEX_STATE_BEG);
                                parser->command_start = true;
                                parser->current.type = PM_TOKEN_NEWLINE;
                                return;
                            }
                            PRISM_FALLTHROUGH
                        case PM_IGNORED_NEWLINE_ALL:
                            if (!lexed_comment) parser_lex_ignored_newline(parser);
                            lexed_comment = false;
                            goto lex_next_token;
                    }

                    // Here we need to look ahead and see if there is a call operator
                    // (either . or &.) that starts the next line. If there is, then this
                    // is going to become an ignored newline and we're going to instead
                    // return the call operator.
                    const uint8_t *next_content = parser->next_start == NULL ? parser->current.end : parser->next_start;
                    next_content += pm_strspn_inline_whitespace(next_content, parser->end - next_content);

                    if (next_content < parser->end) {
                        // If we hit a comment after a newline, then we're going to check
                        // if it's ignored or if it's followed by a method call ('.').
                        // If it is, then we're going to call the
                        // callback with an ignored newline and then continue lexing.
                        // Otherwise we'll return a regular newline.
                        if (next_content[0] == '#') {
                            // Here we look for a "." or "&." following a "\n".
                            const uint8_t *following = next_newline(next_content, parser->end - next_content);

                            while (following && (following + 1 < parser->end)) {
                                following++;
                                following += pm_strspn_inline_whitespace(following, parser->end - following);

                                // If this is not followed by a comment, then we can break out
                                // of this loop.
                                if (peek_at(parser, following) != '#') break;

                                // If there is a comment, then we need to find the end of the
                                // comment and continue searching from there.
                                following = next_newline(following, parser->end - following);
                            }

                            // If the lex state was ignored, or we hit a '.' or a '&.',
                            // we will lex the ignored newline
                            if (
                                lex_state_ignored_p(parser) ||
                                (following && (
                                    (peek_at(parser, following) == '.') ||
                                    (peek_at(parser, following) == '&' && peek_at(parser, following + 1) == '.')
                                ))
                            ) {
                                if (!lexed_comment) parser_lex_ignored_newline(parser);
                                lexed_comment = false;
                                goto lex_next_token;
                            }
                        }

                        // If we hit a . after a newline, then we're in a call chain and
                        // we need to return the call operator.
                        if (next_content[0] == '.') {
                            // To match ripper, we need to emit an ignored newline even though
                            // it's a real newline in the case that we have a beginless range
                            // on a subsequent line.
                            if (peek_at(parser, next_content + 1) == '.') {
                                if (!lexed_comment) parser_lex_ignored_newline(parser);
                                lex_state_set(parser, PM_LEX_STATE_BEG);
                                parser->command_start = true;
                                parser->current.type = PM_TOKEN_NEWLINE;
                                return;
                            }

                            if (!lexed_comment) parser_lex_ignored_newline(parser);
                            lex_state_set(parser, PM_LEX_STATE_DOT);
                            parser->current.start = next_content;
                            parser->current.end = next_content + 1;
                            parser->next_start = NULL;
                            LEX(PM_TOKEN_DOT);
                        }

                        // If we hit a &. after a newline, then we're in a call chain and
                        // we need to return the call operator.
                        if (peek_at(parser, next_content) == '&' && peek_at(parser, next_content + 1) == '.') {
                            if (!lexed_comment) parser_lex_ignored_newline(parser);
                            lex_state_set(parser, PM_LEX_STATE_DOT);
                            parser->current.start = next_content;
                            parser->current.end = next_content + 2;
                            parser->next_start = NULL;
                            LEX(PM_TOKEN_AMPERSAND_DOT);
                        }
                    }

                    // At this point we know this is a regular newline, and we can set the
                    // necessary state and return the token.
                    lex_state_set(parser, PM_LEX_STATE_BEG);
                    parser->command_start = true;
                    parser->current.type = PM_TOKEN_NEWLINE;
                    if (!lexed_comment) parser_lex_callback(parser);
                    return;
                }

                // ,
                case ',':
                    if ((parser->previous.type == PM_TOKEN_COMMA) && (parser->enclosure_nesting > 0)) {
                        PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_ARRAY_TERM, pm_token_type_human(parser->current.type));
                    }

                    lex_state_set(parser, PM_LEX_STATE_BEG | PM_LEX_STATE_LABEL);
                    LEX(PM_TOKEN_COMMA);

                // (
                case '(': {
                    pm_token_type_t type = PM_TOKEN_PARENTHESIS_LEFT;

                    if (space_seen && (lex_state_arg_p(parser) || parser->lex_state == (PM_LEX_STATE_END | PM_LEX_STATE_LABEL))) {
                        type = PM_TOKEN_PARENTHESIS_LEFT_PARENTHESES;
                    }

                    parser->enclosure_nesting++;
                    lex_state_set(parser, PM_LEX_STATE_BEG | PM_LEX_STATE_LABEL);
                    pm_do_loop_stack_push(parser, false);
                    LEX(type);
                }

                // )
                case ')':
                    parser->enclosure_nesting--;
                    lex_state_set(parser, PM_LEX_STATE_ENDFN);
                    pm_do_loop_stack_pop(parser);
                    LEX(PM_TOKEN_PARENTHESIS_RIGHT);

                // ;
                case ';':
                    lex_state_set(parser, PM_LEX_STATE_BEG);
                    parser->command_start = true;
                    LEX(PM_TOKEN_SEMICOLON);

                // [ [] []=
                case '[':
                    parser->enclosure_nesting++;
                    pm_token_type_t type = PM_TOKEN_BRACKET_LEFT;

                    if (lex_state_operator_p(parser)) {
                        if (match(parser, ']')) {
                            parser->enclosure_nesting--;
                            lex_state_set(parser, PM_LEX_STATE_ARG);
                            LEX(match(parser, '=') ? PM_TOKEN_BRACKET_LEFT_RIGHT_EQUAL : PM_TOKEN_BRACKET_LEFT_RIGHT);
                        }

                        lex_state_set(parser, PM_LEX_STATE_ARG | PM_LEX_STATE_LABEL);
                        LEX(type);
                    }

                    if (lex_state_beg_p(parser) || (lex_state_arg_p(parser) && (space_seen || lex_state_p(parser, PM_LEX_STATE_LABELED)))) {
                        type = PM_TOKEN_BRACKET_LEFT_ARRAY;
                    }

                    lex_state_set(parser, PM_LEX_STATE_BEG | PM_LEX_STATE_LABEL);
                    pm_do_loop_stack_push(parser, false);
                    LEX(type);

                // ]
                case ']':
                    parser->enclosure_nesting--;
                    lex_state_set(parser, PM_LEX_STATE_END);
                    pm_do_loop_stack_pop(parser);
                    LEX(PM_TOKEN_BRACKET_RIGHT);

                // {
                case '{': {
                    pm_token_type_t type = PM_TOKEN_BRACE_LEFT;

                    if (parser->enclosure_nesting == parser->lambda_enclosure_nesting) {
                        // This { begins a lambda
                        parser->command_start = true;
                        lex_state_set(parser, PM_LEX_STATE_BEG);
                        type = PM_TOKEN_LAMBDA_BEGIN;
                    } else if (lex_state_p(parser, PM_LEX_STATE_LABELED)) {
                        // This { begins a hash literal
                        lex_state_set(parser, PM_LEX_STATE_BEG | PM_LEX_STATE_LABEL);
                    } else if (lex_state_p(parser, PM_LEX_STATE_ARG_ANY | PM_LEX_STATE_END | PM_LEX_STATE_ENDFN)) {
                        // This { begins a block
                        parser->command_start = true;
                        lex_state_set(parser, PM_LEX_STATE_BEG);
                    } else if (lex_state_p(parser, PM_LEX_STATE_ENDARG)) {
                        // This { begins a block on a command
                        parser->command_start = true;
                        lex_state_set(parser, PM_LEX_STATE_BEG);
                    } else {
                        // This { begins a hash literal
                        lex_state_set(parser, PM_LEX_STATE_BEG | PM_LEX_STATE_LABEL);
                    }

                    parser->enclosure_nesting++;
                    parser->brace_nesting++;
                    pm_do_loop_stack_push(parser, false);

                    LEX(type);
                }

                // }
                case '}':
                    parser->enclosure_nesting--;
                    pm_do_loop_stack_pop(parser);

                    if ((parser->lex_modes.current->mode == PM_LEX_EMBEXPR) && (parser->brace_nesting == 0)) {
                        lex_mode_pop(parser);
                        LEX(PM_TOKEN_EMBEXPR_END);
                    }

                    parser->brace_nesting--;
                    lex_state_set(parser, PM_LEX_STATE_END);
                    LEX(PM_TOKEN_BRACE_RIGHT);

                // * ** **= *=
                case '*': {
                    if (match(parser, '*')) {
                        if (match(parser, '=')) {
                            lex_state_set(parser, PM_LEX_STATE_BEG);
                            LEX(PM_TOKEN_STAR_STAR_EQUAL);
                        }

                        pm_token_type_t type = PM_TOKEN_STAR_STAR;

                        if (lex_state_spcarg_p(parser, space_seen)) {
                            pm_parser_warn_token(parser, &parser->current, PM_WARN_AMBIGUOUS_PREFIX_STAR_STAR);
                            type = PM_TOKEN_USTAR_STAR;
                        } else if (lex_state_beg_p(parser)) {
                            type = PM_TOKEN_USTAR_STAR;
                        } else if (ambiguous_operator_p(parser, space_seen)) {
                            PM_PARSER_WARN_TOKEN_FORMAT(parser, parser->current, PM_WARN_AMBIGUOUS_BINARY_OPERATOR, "**", "argument prefix");
                        }

                        if (lex_state_operator_p(parser)) {
                            lex_state_set(parser, PM_LEX_STATE_ARG);
                        } else {
                            lex_state_set(parser, PM_LEX_STATE_BEG);
                        }

                        LEX(type);
                    }

                    if (match(parser, '=')) {
                        lex_state_set(parser, PM_LEX_STATE_BEG);
                        LEX(PM_TOKEN_STAR_EQUAL);
                    }

                    pm_token_type_t type = PM_TOKEN_STAR;

                    if (lex_state_spcarg_p(parser, space_seen)) {
                        pm_parser_warn_token(parser, &parser->current, PM_WARN_AMBIGUOUS_PREFIX_STAR);
                        type = PM_TOKEN_USTAR;
                    } else if (lex_state_beg_p(parser)) {
                        type = PM_TOKEN_USTAR;
                    } else if (ambiguous_operator_p(parser, space_seen)) {
                        PM_PARSER_WARN_TOKEN_FORMAT(parser, parser->current, PM_WARN_AMBIGUOUS_BINARY_OPERATOR, "*", "argument prefix");
                    }

                    if (lex_state_operator_p(parser)) {
                        lex_state_set(parser, PM_LEX_STATE_ARG);
                    } else {
                        lex_state_set(parser, PM_LEX_STATE_BEG);
                    }

                    LEX(type);
                }

                // ! != !~ !@
                case '!':
                    if (lex_state_operator_p(parser)) {
                        lex_state_set(parser, PM_LEX_STATE_ARG);
                        if (match(parser, '@')) {
                            LEX(PM_TOKEN_BANG);
                        }
                    } else {
                        lex_state_set(parser, PM_LEX_STATE_BEG);
                    }

                    if (match(parser, '=')) {
                        LEX(PM_TOKEN_BANG_EQUAL);
                    }

                    if (match(parser, '~')) {
                        LEX(PM_TOKEN_BANG_TILDE);
                    }

                    LEX(PM_TOKEN_BANG);

                // = => =~ == === =begin
                case '=':
                    if (
                        current_token_starts_line(parser) &&
                        (parser->current.end + 5 <= parser->end) &&
                        memcmp(parser->current.end, "begin", 5) == 0 &&
                        (pm_char_is_whitespace(peek_offset(parser, 5)) || (peek_offset(parser, 5) == '\0'))
                    ) {
                        pm_token_type_t type = lex_embdoc(parser);
                        if (type == PM_TOKEN_EOF) {
                            LEX(type);
                        }

                        goto lex_next_token;
                    }

                    if (lex_state_operator_p(parser)) {
                        lex_state_set(parser, PM_LEX_STATE_ARG);
                    } else {
                        lex_state_set(parser, PM_LEX_STATE_BEG);
                    }

                    if (match(parser, '>')) {
                        LEX(PM_TOKEN_EQUAL_GREATER);
                    }

                    if (match(parser, '~')) {
                        LEX(PM_TOKEN_EQUAL_TILDE);
                    }

                    if (match(parser, '=')) {
                        LEX(match(parser, '=') ? PM_TOKEN_EQUAL_EQUAL_EQUAL : PM_TOKEN_EQUAL_EQUAL);
                    }

                    LEX(PM_TOKEN_EQUAL);

                // < << <<= <= <=>
                case '<':
                    if (match(parser, '<')) {
                        if (
                            !lex_state_p(parser, PM_LEX_STATE_DOT | PM_LEX_STATE_CLASS) &&
                            !lex_state_end_p(parser) &&
                            (!lex_state_p(parser, PM_LEX_STATE_ARG_ANY) || lex_state_p(parser, PM_LEX_STATE_LABELED) || space_seen)
                        ) {
                            const uint8_t *end = parser->current.end;

                            pm_heredoc_quote_t quote = PM_HEREDOC_QUOTE_NONE;
                            pm_heredoc_indent_t indent = PM_HEREDOC_INDENT_NONE;

                            if (match(parser, '-')) {
                                indent = PM_HEREDOC_INDENT_DASH;
                            }
                            else if (match(parser, '~')) {
                                indent = PM_HEREDOC_INDENT_TILDE;
                            }

                            if (match(parser, '`')) {
                                quote = PM_HEREDOC_QUOTE_BACKTICK;
                            }
                            else if (match(parser, '"')) {
                                quote = PM_HEREDOC_QUOTE_DOUBLE;
                            }
                            else if (match(parser, '\'')) {
                                quote = PM_HEREDOC_QUOTE_SINGLE;
                            }

                            const uint8_t *ident_start = parser->current.end;
                            size_t width = 0;

                            if (parser->current.end >= parser->end) {
                                parser->current.end = end;
                            } else if (quote == PM_HEREDOC_QUOTE_NONE && (width = char_is_identifier(parser, parser->current.end, parser->end - parser->current.end)) == 0) {
                                parser->current.end = end;
                            } else {
                                if (quote == PM_HEREDOC_QUOTE_NONE) {
                                    parser->current.end += width;

                                    while ((width = char_is_identifier(parser, parser->current.end, parser->end - parser->current.end))) {
                                        parser->current.end += width;
                                    }
                                } else {
                                    // If we have quotes, then we're going to go until we find the
                                    // end quote.
                                    while ((parser->current.end < parser->end) && quote != (pm_heredoc_quote_t) (*parser->current.end)) {
                                        if (*parser->current.end == '\r' || *parser->current.end == '\n') break;
                                        parser->current.end++;
                                    }
                                }

                                size_t ident_length = (size_t) (parser->current.end - ident_start);
                                bool ident_error = false;

                                if (quote != PM_HEREDOC_QUOTE_NONE && !match(parser, (uint8_t) quote)) {
                                    pm_parser_err(parser, ident_start, ident_start + ident_length, PM_ERR_HEREDOC_IDENTIFIER);
                                    ident_error = true;
                                }

                                parser->explicit_encoding = NULL;
                                lex_mode_push(parser, (pm_lex_mode_t) {
                                    .mode = PM_LEX_HEREDOC,
                                    .as.heredoc = {
                                        .base = {
                                            .ident_start = ident_start,
                                            .ident_length = ident_length,
                                            .quote = quote,
                                            .indent = indent
                                        },
                                        .next_start = parser->current.end,
                                        .common_whitespace = NULL,
                                        .line_continuation = false
                                    }
                                });

                                if (parser->heredoc_end == NULL) {
                                    const uint8_t *body_start = next_newline(parser->current.end, parser->end - parser->current.end);

                                    if (body_start == NULL) {
                                        // If there is no newline after the heredoc identifier, then
                                        // this is not a valid heredoc declaration. In this case we
                                        // will add an error, but we will still return a heredoc
                                        // start.
                                        if (!ident_error) pm_parser_err_heredoc_term(parser, ident_start, ident_length);
                                        body_start = parser->end;
                                    } else {
                                        // Otherwise, we want to indicate that the body of the
                                        // heredoc starts on the character after the next newline.
                                        pm_newline_list_append(&parser->newline_list, body_start);
                                        body_start++;
                                    }

                                    parser->next_start = body_start;
                                } else {
                                    parser->next_start = parser->heredoc_end;
                                }

                                LEX(PM_TOKEN_HEREDOC_START);
                            }
                        }

                        if (match(parser, '=')) {
                            lex_state_set(parser, PM_LEX_STATE_BEG);
                            LEX(PM_TOKEN_LESS_LESS_EQUAL);
                        }

                        if (ambiguous_operator_p(parser, space_seen)) {
                            PM_PARSER_WARN_TOKEN_FORMAT(parser, parser->current, PM_WARN_AMBIGUOUS_BINARY_OPERATOR, "<<", "here document");
                        }

                        if (lex_state_operator_p(parser)) {
                            lex_state_set(parser, PM_LEX_STATE_ARG);
                        } else {
                            if (lex_state_p(parser, PM_LEX_STATE_CLASS)) parser->command_start = true;
                            lex_state_set(parser, PM_LEX_STATE_BEG);
                        }

                        LEX(PM_TOKEN_LESS_LESS);
                    }

                    if (lex_state_operator_p(parser)) {
                        lex_state_set(parser, PM_LEX_STATE_ARG);
                    } else {
                        if (lex_state_p(parser, PM_LEX_STATE_CLASS)) parser->command_start = true;
                        lex_state_set(parser, PM_LEX_STATE_BEG);
                    }

                    if (match(parser, '=')) {
                        if (match(parser, '>')) {
                            LEX(PM_TOKEN_LESS_EQUAL_GREATER);
                        }

                        LEX(PM_TOKEN_LESS_EQUAL);
                    }

                    LEX(PM_TOKEN_LESS);

                // > >> >>= >=
                case '>':
                    if (match(parser, '>')) {
                        if (lex_state_operator_p(parser)) {
                            lex_state_set(parser, PM_LEX_STATE_ARG);
                        } else {
                            lex_state_set(parser, PM_LEX_STATE_BEG);
                        }
                        LEX(match(parser, '=') ? PM_TOKEN_GREATER_GREATER_EQUAL : PM_TOKEN_GREATER_GREATER);
                    }

                    if (lex_state_operator_p(parser)) {
                        lex_state_set(parser, PM_LEX_STATE_ARG);
                    } else {
                        lex_state_set(parser, PM_LEX_STATE_BEG);
                    }

                    LEX(match(parser, '=') ? PM_TOKEN_GREATER_EQUAL : PM_TOKEN_GREATER);

                // double-quoted string literal
                case '"': {
                    bool label_allowed = (lex_state_p(parser, PM_LEX_STATE_LABEL | PM_LEX_STATE_ENDFN) && !previous_command_start) || lex_state_arg_p(parser);
                    lex_mode_push_string(parser, true, label_allowed, '\0', '"');
                    LEX(PM_TOKEN_STRING_BEGIN);
                }

                // xstring literal
                case '`': {
                    if (lex_state_p(parser, PM_LEX_STATE_FNAME)) {
                        lex_state_set(parser, PM_LEX_STATE_ENDFN);
                        LEX(PM_TOKEN_BACKTICK);
                    }

                    if (lex_state_p(parser, PM_LEX_STATE_DOT)) {
                        if (previous_command_start) {
                            lex_state_set(parser, PM_LEX_STATE_CMDARG);
                        } else {
                            lex_state_set(parser, PM_LEX_STATE_ARG);
                        }

                        LEX(PM_TOKEN_BACKTICK);
                    }

                    lex_mode_push_string(parser, true, false, '\0', '`');
                    LEX(PM_TOKEN_BACKTICK);
                }

                // single-quoted string literal
                case '\'': {
                    bool label_allowed = (lex_state_p(parser, PM_LEX_STATE_LABEL | PM_LEX_STATE_ENDFN) && !previous_command_start) || lex_state_arg_p(parser);
                    lex_mode_push_string(parser, false, label_allowed, '\0', '\'');
                    LEX(PM_TOKEN_STRING_BEGIN);
                }

                // ? character literal
                case '?':
                    LEX(lex_question_mark(parser));

                // & && &&= &=
                case '&': {
                    if (match(parser, '&')) {
                        lex_state_set(parser, PM_LEX_STATE_BEG);

                        if (match(parser, '=')) {
                            LEX(PM_TOKEN_AMPERSAND_AMPERSAND_EQUAL);
                        }

                        LEX(PM_TOKEN_AMPERSAND_AMPERSAND);
                    }

                    if (match(parser, '=')) {
                        lex_state_set(parser, PM_LEX_STATE_BEG);
                        LEX(PM_TOKEN_AMPERSAND_EQUAL);
                    }

                    if (match(parser, '.')) {
                        lex_state_set(parser, PM_LEX_STATE_DOT);
                        LEX(PM_TOKEN_AMPERSAND_DOT);
                    }

                    pm_token_type_t type = PM_TOKEN_AMPERSAND;
                    if (lex_state_spcarg_p(parser, space_seen)) {
                        if ((peek(parser) != ':') || (peek_offset(parser, 1) == '\0')) {
                            pm_parser_warn_token(parser, &parser->current, PM_WARN_AMBIGUOUS_PREFIX_AMPERSAND);
                        } else {
                            const uint8_t delim = peek_offset(parser, 1);

                            if ((delim != '\'') && (delim != '"') && !char_is_identifier(parser, parser->current.end + 1, parser->end - (parser->current.end + 1))) {
                                pm_parser_warn_token(parser, &parser->current, PM_WARN_AMBIGUOUS_PREFIX_AMPERSAND);
                            }
                        }

                        type = PM_TOKEN_UAMPERSAND;
                    } else if (lex_state_beg_p(parser)) {
                        type = PM_TOKEN_UAMPERSAND;
                    } else if (ambiguous_operator_p(parser, space_seen)) {
                        PM_PARSER_WARN_TOKEN_FORMAT(parser, parser->current, PM_WARN_AMBIGUOUS_BINARY_OPERATOR, "&", "argument prefix");
                    }

                    if (lex_state_operator_p(parser)) {
                        lex_state_set(parser, PM_LEX_STATE_ARG);
                    } else {
                        lex_state_set(parser, PM_LEX_STATE_BEG);
                    }

                    LEX(type);
                }

                // | || ||= |=
                case '|':
                    if (match(parser, '|')) {
                        if (match(parser, '=')) {
                            lex_state_set(parser, PM_LEX_STATE_BEG);
                            LEX(PM_TOKEN_PIPE_PIPE_EQUAL);
                        }

                        if (lex_state_p(parser, PM_LEX_STATE_BEG)) {
                            parser->current.end--;
                            LEX(PM_TOKEN_PIPE);
                        }

                        lex_state_set(parser, PM_LEX_STATE_BEG);
                        LEX(PM_TOKEN_PIPE_PIPE);
                    }

                    if (match(parser, '=')) {
                        lex_state_set(parser, PM_LEX_STATE_BEG);
                        LEX(PM_TOKEN_PIPE_EQUAL);
                    }

                    if (lex_state_operator_p(parser)) {
                        lex_state_set(parser, PM_LEX_STATE_ARG);
                    } else {
                        lex_state_set(parser, PM_LEX_STATE_BEG | PM_LEX_STATE_LABEL);
                    }

                    LEX(PM_TOKEN_PIPE);

                // + += +@
                case '+': {
                    if (lex_state_operator_p(parser)) {
                        lex_state_set(parser, PM_LEX_STATE_ARG);

                        if (match(parser, '@')) {
                            LEX(PM_TOKEN_UPLUS);
                        }

                        LEX(PM_TOKEN_PLUS);
                    }

                    if (match(parser, '=')) {
                        lex_state_set(parser, PM_LEX_STATE_BEG);
                        LEX(PM_TOKEN_PLUS_EQUAL);
                    }

                    if (
                        lex_state_beg_p(parser) ||
                        (lex_state_spcarg_p(parser, space_seen) ? (pm_parser_warn_token(parser, &parser->current, PM_WARN_AMBIGUOUS_FIRST_ARGUMENT_PLUS), true) : false)
                    ) {
                        lex_state_set(parser, PM_LEX_STATE_BEG);

                        if (pm_char_is_decimal_digit(peek(parser))) {
                            parser->current.end++;
                            pm_token_type_t type = lex_numeric(parser);
                            lex_state_set(parser, PM_LEX_STATE_END);
                            LEX(type);
                        }

                        LEX(PM_TOKEN_UPLUS);
                    }

                    if (ambiguous_operator_p(parser, space_seen)) {
                        PM_PARSER_WARN_TOKEN_FORMAT(parser, parser->current, PM_WARN_AMBIGUOUS_BINARY_OPERATOR, "+", "unary operator");
                    }

                    lex_state_set(parser, PM_LEX_STATE_BEG);
                    LEX(PM_TOKEN_PLUS);
                }

                // - -= -@
                case '-': {
                    if (lex_state_operator_p(parser)) {
                        lex_state_set(parser, PM_LEX_STATE_ARG);

                        if (match(parser, '@')) {
                            LEX(PM_TOKEN_UMINUS);
                        }

                        LEX(PM_TOKEN_MINUS);
                    }

                    if (match(parser, '=')) {
                        lex_state_set(parser, PM_LEX_STATE_BEG);
                        LEX(PM_TOKEN_MINUS_EQUAL);
                    }

                    if (match(parser, '>')) {
                        lex_state_set(parser, PM_LEX_STATE_ENDFN);
                        LEX(PM_TOKEN_MINUS_GREATER);
                    }

                    bool spcarg = lex_state_spcarg_p(parser, space_seen);
                    bool is_beg = lex_state_beg_p(parser);
                    if (!is_beg && spcarg) {
                        pm_parser_warn_token(parser, &parser->current, PM_WARN_AMBIGUOUS_FIRST_ARGUMENT_MINUS);
                    }

                    if (is_beg || spcarg) {
                        lex_state_set(parser, PM_LEX_STATE_BEG);
                        LEX(pm_char_is_decimal_digit(peek(parser)) ? PM_TOKEN_UMINUS_NUM : PM_TOKEN_UMINUS);
                    }

                    if (ambiguous_operator_p(parser, space_seen)) {
                        PM_PARSER_WARN_TOKEN_FORMAT(parser, parser->current, PM_WARN_AMBIGUOUS_BINARY_OPERATOR, "-", "unary operator");
                    }

                    lex_state_set(parser, PM_LEX_STATE_BEG);
                    LEX(PM_TOKEN_MINUS);
                }

                // . .. ...
                case '.': {
                    bool beg_p = lex_state_beg_p(parser);

                    if (match(parser, '.')) {
                        if (match(parser, '.')) {
                            // If we're _not_ inside a range within default parameters
                            if (!context_p(parser, PM_CONTEXT_DEFAULT_PARAMS) && context_p(parser, PM_CONTEXT_DEF_PARAMS)) {
                                if (lex_state_p(parser, PM_LEX_STATE_END)) {
                                    lex_state_set(parser, PM_LEX_STATE_BEG);
                                } else {
                                    lex_state_set(parser, PM_LEX_STATE_ENDARG);
                                }
                                LEX(PM_TOKEN_UDOT_DOT_DOT);
                            }

                            if (parser->enclosure_nesting == 0 && parser_end_of_line_p(parser)) {
                                pm_parser_warn_token(parser, &parser->current, PM_WARN_DOT_DOT_DOT_EOL);
                            }

                            lex_state_set(parser, PM_LEX_STATE_BEG);
                            LEX(beg_p ? PM_TOKEN_UDOT_DOT_DOT : PM_TOKEN_DOT_DOT_DOT);
                        }

                        lex_state_set(parser, PM_LEX_STATE_BEG);
                        LEX(beg_p ? PM_TOKEN_UDOT_DOT : PM_TOKEN_DOT_DOT);
                    }

                    lex_state_set(parser, PM_LEX_STATE_DOT);
                    LEX(PM_TOKEN_DOT);
                }

                // integer
                case '0':
                case '1':
                case '2':
                case '3':
                case '4':
                case '5':
                case '6':
                case '7':
                case '8':
                case '9': {
                    pm_token_type_t type = lex_numeric(parser);
                    lex_state_set(parser, PM_LEX_STATE_END);
                    LEX(type);
                }

                // :: symbol
                case ':':
                    if (match(parser, ':')) {
                        if (lex_state_beg_p(parser) || lex_state_p(parser, PM_LEX_STATE_CLASS) || (lex_state_p(parser, PM_LEX_STATE_ARG_ANY) && space_seen)) {
                            lex_state_set(parser, PM_LEX_STATE_BEG);
                            LEX(PM_TOKEN_UCOLON_COLON);
                        }

                        lex_state_set(parser, PM_LEX_STATE_DOT);
                        LEX(PM_TOKEN_COLON_COLON);
                    }

                    if (lex_state_end_p(parser) || pm_char_is_whitespace(peek(parser)) || peek(parser) == '#') {
                        lex_state_set(parser, PM_LEX_STATE_BEG);
                        LEX(PM_TOKEN_COLON);
                    }

                    if (peek(parser) == '"' || peek(parser) == '\'') {
                        lex_mode_push_string(parser, peek(parser) == '"', false, '\0', *parser->current.end);
                        parser->current.end++;
                    }

                    lex_state_set(parser, PM_LEX_STATE_FNAME);
                    LEX(PM_TOKEN_SYMBOL_BEGIN);

                // / /=
                case '/':
                    if (lex_state_beg_p(parser)) {
                        lex_mode_push_regexp(parser, '\0', '/');
                        LEX(PM_TOKEN_REGEXP_BEGIN);
                    }

                    if (match(parser, '=')) {
                        lex_state_set(parser, PM_LEX_STATE_BEG);
                        LEX(PM_TOKEN_SLASH_EQUAL);
                    }

                    if (lex_state_spcarg_p(parser, space_seen)) {
                        pm_parser_warn_token(parser, &parser->current, PM_WARN_AMBIGUOUS_SLASH);
                        lex_mode_push_regexp(parser, '\0', '/');
                        LEX(PM_TOKEN_REGEXP_BEGIN);
                    }

                    if (ambiguous_operator_p(parser, space_seen)) {
                        PM_PARSER_WARN_TOKEN_FORMAT(parser, parser->current, PM_WARN_AMBIGUOUS_BINARY_OPERATOR, "/", "regexp literal");
                    }

                    if (lex_state_operator_p(parser)) {
                        lex_state_set(parser, PM_LEX_STATE_ARG);
                    } else {
                        lex_state_set(parser, PM_LEX_STATE_BEG);
                    }

                    LEX(PM_TOKEN_SLASH);

                // ^ ^=
                case '^':
                    if (lex_state_operator_p(parser)) {
                        lex_state_set(parser, PM_LEX_STATE_ARG);
                    } else {
                        lex_state_set(parser, PM_LEX_STATE_BEG);
                    }
                    LEX(match(parser, '=') ? PM_TOKEN_CARET_EQUAL : PM_TOKEN_CARET);

                // ~ ~@
                case '~':
                    if (lex_state_operator_p(parser)) {
                        (void) match(parser, '@');
                        lex_state_set(parser, PM_LEX_STATE_ARG);
                    } else {
                        lex_state_set(parser, PM_LEX_STATE_BEG);
                    }

                    LEX(PM_TOKEN_TILDE);

                // % %= %i %I %q %Q %w %W
                case '%': {
                    // If there is no subsequent character then we have an
                    // invalid token. We're going to say it's the percent
                    // operator because we don't want to move into the string
                    // lex mode unnecessarily.
                    if ((lex_state_beg_p(parser) || lex_state_arg_p(parser)) && (parser->current.end >= parser->end)) {
                        pm_parser_err_current(parser, PM_ERR_INVALID_PERCENT_EOF);
                        LEX(PM_TOKEN_PERCENT);
                    }

                    if (!lex_state_beg_p(parser) && match(parser, '=')) {
                        lex_state_set(parser, PM_LEX_STATE_BEG);
                        LEX(PM_TOKEN_PERCENT_EQUAL);
                    } else if (
                        lex_state_beg_p(parser) ||
                        (lex_state_p(parser, PM_LEX_STATE_FITEM) && (peek(parser) == 's')) ||
                        lex_state_spcarg_p(parser, space_seen)
                    ) {
                        if (!parser->encoding->alnum_char(parser->current.end, parser->end - parser->current.end)) {
                            if (*parser->current.end >= 0x80) {
                                pm_parser_err_current(parser, PM_ERR_INVALID_PERCENT);
                            }

                            const uint8_t delimiter = pm_lex_percent_delimiter(parser);
                            lex_mode_push_string(parser, true, false, lex_mode_incrementor(delimiter), lex_mode_terminator(delimiter));
                            LEX(PM_TOKEN_STRING_BEGIN);
                        }

                        // Delimiters for %-literals cannot be alphanumeric. We
                        // validate that here.
                        uint8_t delimiter = peek_offset(parser, 1);
                        if (delimiter >= 0x80 || parser->encoding->alnum_char(&delimiter, 1)) {
                            pm_parser_err_current(parser, PM_ERR_INVALID_PERCENT);
                            goto lex_next_token;
                        }

                        switch (peek(parser)) {
                            case 'i': {
                                parser->current.end++;

                                if (parser->current.end < parser->end) {
                                    lex_mode_push_list(parser, false, pm_lex_percent_delimiter(parser));
                                } else {
                                    lex_mode_push_list_eof(parser);
                                }

                                LEX(PM_TOKEN_PERCENT_LOWER_I);
                            }
                            case 'I': {
                                parser->current.end++;

                                if (parser->current.end < parser->end) {
                                    lex_mode_push_list(parser, true, pm_lex_percent_delimiter(parser));
                                } else {
                                    lex_mode_push_list_eof(parser);
                                }

                                LEX(PM_TOKEN_PERCENT_UPPER_I);
                            }
                            case 'r': {
                                parser->current.end++;

                                if (parser->current.end < parser->end) {
                                    const uint8_t delimiter = pm_lex_percent_delimiter(parser);
                                    lex_mode_push_regexp(parser, lex_mode_incrementor(delimiter), lex_mode_terminator(delimiter));
                                } else {
                                    lex_mode_push_regexp(parser, '\0', '\0');
                                }

                                LEX(PM_TOKEN_REGEXP_BEGIN);
                            }
                            case 'q': {
                                parser->current.end++;

                                if (parser->current.end < parser->end) {
                                    const uint8_t delimiter = pm_lex_percent_delimiter(parser);
                                    lex_mode_push_string(parser, false, false, lex_mode_incrementor(delimiter), lex_mode_terminator(delimiter));
                                } else {
                                    lex_mode_push_string_eof(parser);
                                }

                                LEX(PM_TOKEN_STRING_BEGIN);
                            }
                            case 'Q': {
                                parser->current.end++;

                                if (parser->current.end < parser->end) {
                                    const uint8_t delimiter = pm_lex_percent_delimiter(parser);
                                    lex_mode_push_string(parser, true, false, lex_mode_incrementor(delimiter), lex_mode_terminator(delimiter));
                                } else {
                                    lex_mode_push_string_eof(parser);
                                }

                                LEX(PM_TOKEN_STRING_BEGIN);
                            }
                            case 's': {
                                parser->current.end++;

                                if (parser->current.end < parser->end) {
                                    const uint8_t delimiter = pm_lex_percent_delimiter(parser);
                                    lex_mode_push_string(parser, false, false, lex_mode_incrementor(delimiter), lex_mode_terminator(delimiter));
                                    lex_state_set(parser, PM_LEX_STATE_FNAME | PM_LEX_STATE_FITEM);
                                } else {
                                    lex_mode_push_string_eof(parser);
                                }

                                LEX(PM_TOKEN_SYMBOL_BEGIN);
                            }
                            case 'w': {
                                parser->current.end++;

                                if (parser->current.end < parser->end) {
                                    lex_mode_push_list(parser, false, pm_lex_percent_delimiter(parser));
                                } else {
                                    lex_mode_push_list_eof(parser);
                                }

                                LEX(PM_TOKEN_PERCENT_LOWER_W);
                            }
                            case 'W': {
                                parser->current.end++;

                                if (parser->current.end < parser->end) {
                                    lex_mode_push_list(parser, true, pm_lex_percent_delimiter(parser));
                                } else {
                                    lex_mode_push_list_eof(parser);
                                }

                                LEX(PM_TOKEN_PERCENT_UPPER_W);
                            }
                            case 'x': {
                                parser->current.end++;

                                if (parser->current.end < parser->end) {
                                    const uint8_t delimiter = pm_lex_percent_delimiter(parser);
                                    lex_mode_push_string(parser, true, false, lex_mode_incrementor(delimiter), lex_mode_terminator(delimiter));
                                } else {
                                    lex_mode_push_string_eof(parser);
                                }

                                LEX(PM_TOKEN_PERCENT_LOWER_X);
                            }
                            default:
                                // If we get to this point, then we have a % that is completely
                                // unparsable. In this case we'll just drop it from the parser
                                // and skip past it and hope that the next token is something
                                // that we can parse.
                                pm_parser_err_current(parser, PM_ERR_INVALID_PERCENT);
                                goto lex_next_token;
                        }
                    }

                    if (ambiguous_operator_p(parser, space_seen)) {
                        PM_PARSER_WARN_TOKEN_FORMAT(parser, parser->current, PM_WARN_AMBIGUOUS_BINARY_OPERATOR, "%", "string literal");
                    }

                    lex_state_set(parser, lex_state_operator_p(parser) ? PM_LEX_STATE_ARG : PM_LEX_STATE_BEG);
                    LEX(PM_TOKEN_PERCENT);
                }

                // global variable
                case '$': {
                    pm_token_type_t type = lex_global_variable(parser);

                    // If we're lexing an embedded variable, then we need to pop back into
                    // the parent lex context.
                    if (parser->lex_modes.current->mode == PM_LEX_EMBVAR) {
                        lex_mode_pop(parser);
                    }

                    lex_state_set(parser, PM_LEX_STATE_END);
                    LEX(type);
                }

                // instance variable, class variable
                case '@':
                    lex_state_set(parser, parser->lex_state & PM_LEX_STATE_FNAME ? PM_LEX_STATE_ENDFN : PM_LEX_STATE_END);
                    LEX(lex_at_variable(parser));

                default: {
                    if (*parser->current.start != '_') {
                        size_t width = char_is_identifier_start(parser, parser->current.start, parser->end - parser->current.start);

                        // If this isn't the beginning of an identifier, then
                        // it's an invalid token as we've exhausted all of the
                        // other options. We'll skip past it and return the next
                        // token after adding an appropriate error message.
                        if (!width) {
                            if (*parser->current.start >= 0x80) {
                                PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_INVALID_MULTIBYTE_CHARACTER, *parser->current.start);
                            } else if (*parser->current.start == '\\') {
                                switch (peek_at(parser, parser->current.start + 1)) {
                                    case ' ':
                                        parser->current.end++;
                                        PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_UNEXPECTED_TOKEN_IGNORE, "escaped space");
                                        break;
                                    case '\f':
                                        parser->current.end++;
                                        PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_UNEXPECTED_TOKEN_IGNORE, "escaped form feed");
                                        break;
                                    case '\t':
                                        parser->current.end++;
                                        PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_UNEXPECTED_TOKEN_IGNORE, "escaped horizontal tab");
                                        break;
                                    case '\v':
                                        parser->current.end++;
                                        PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_UNEXPECTED_TOKEN_IGNORE, "escaped vertical tab");
                                        break;
                                    case '\r':
                                        if (peek_at(parser, parser->current.start + 2) != '\n') {
                                            parser->current.end++;
                                            PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_UNEXPECTED_TOKEN_IGNORE, "escaped carriage return");
                                            break;
                                        }
                                        PRISM_FALLTHROUGH
                                    default:
                                        PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_UNEXPECTED_TOKEN_IGNORE, "backslash");
                                        break;
                                }
                            } else if (char_is_ascii_printable(*parser->current.start)) {
                                PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_INVALID_PRINTABLE_CHARACTER, *parser->current.start);
                            } else {
                                PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_INVALID_CHARACTER, *parser->current.start);
                            }

                            goto lex_next_token;
                        }

                        parser->current.end = parser->current.start + width;
                    }

                    pm_token_type_t type = lex_identifier(parser, previous_command_start);

                    // If we've hit a __END__ and it was at the start of the
                    // line or the start of the file and it is followed by
                    // either a \n or a \r\n, then this is the last token of the
                    // file.
                    if (
                        ((parser->current.end - parser->current.start) == 7) &&
                        current_token_starts_line(parser) &&
                        (memcmp(parser->current.start, "__END__", 7) == 0) &&
                        (parser->current.end == parser->end || match_eol(parser))
                    ) {
                        // Since we know we're about to add an __END__ comment,
                        // we know we need to add all of the newlines to get the
                        // correct column information for it.
                        const uint8_t *cursor = parser->current.end;
                        while ((cursor = next_newline(cursor, parser->end - cursor)) != NULL) {
                            pm_newline_list_append(&parser->newline_list, cursor++);
                        }

                        parser->current.end = parser->end;
                        parser->current.type = PM_TOKEN___END__;
                        parser_lex_callback(parser);

                        parser->data_loc.start = parser->current.start;
                        parser->data_loc.end = parser->current.end;

                        LEX(PM_TOKEN_EOF);
                    }

                    pm_lex_state_t last_state = parser->lex_state;

                    if (type == PM_TOKEN_IDENTIFIER || type == PM_TOKEN_CONSTANT || type == PM_TOKEN_METHOD_NAME) {
                        if (lex_state_p(parser, PM_LEX_STATE_BEG_ANY | PM_LEX_STATE_ARG_ANY | PM_LEX_STATE_DOT)) {
                            if (previous_command_start) {
                                lex_state_set(parser, PM_LEX_STATE_CMDARG);
                            } else {
                                lex_state_set(parser, PM_LEX_STATE_ARG);
                            }
                        } else if (parser->lex_state == PM_LEX_STATE_FNAME) {
                            lex_state_set(parser, PM_LEX_STATE_ENDFN);
                        } else {
                            lex_state_set(parser, PM_LEX_STATE_END);
                        }
                    }

                    if (
                        !(last_state & (PM_LEX_STATE_DOT | PM_LEX_STATE_FNAME)) &&
                        (type == PM_TOKEN_IDENTIFIER) &&
                        ((pm_parser_local_depth(parser, &parser->current) != -1) ||
                         pm_token_is_numbered_parameter(parser->current.start, parser->current.end))
                    ) {
                        lex_state_set(parser, PM_LEX_STATE_END | PM_LEX_STATE_LABEL);
                    }

                    LEX(type);
                }
            }
        }
        case PM_LEX_LIST: {
            if (parser->next_start != NULL) {
                parser->current.end = parser->next_start;
                parser->next_start = NULL;
            }

            // First we'll set the beginning of the token.
            parser->current.start = parser->current.end;

            // If there's any whitespace at the start of the list, then we're
            // going to trim it off the beginning and create a new token.
            size_t whitespace;

            if (parser->heredoc_end) {
                whitespace = pm_strspn_inline_whitespace(parser->current.end, parser->end - parser->current.end);
                if (peek_offset(parser, (ptrdiff_t)whitespace) == '\n') {
                    whitespace += 1;
                }
            } else {
                whitespace = pm_strspn_whitespace_newlines(parser->current.end, parser->end - parser->current.end, &parser->newline_list);
            }

            if (whitespace > 0) {
                parser->current.end += whitespace;
                if (peek_offset(parser, -1) == '\n') {
                    // mutates next_start
                    parser_flush_heredoc_end(parser);
                }
                LEX(PM_TOKEN_WORDS_SEP);
            }

            // We'll check if we're at the end of the file. If we are, then we
            // need to return the EOF token.
            if (parser->current.end >= parser->end) {
                LEX(PM_TOKEN_EOF);
            }

            // Here we'll get a list of the places where strpbrk should break,
            // and then find the first one.
            pm_lex_mode_t *lex_mode = parser->lex_modes.current;
            const uint8_t *breakpoints = lex_mode->as.list.breakpoints;
            const uint8_t *breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, true);

            // If we haven't found an escape yet, then this buffer will be
            // unallocated since we can refer directly to the source string.
            pm_token_buffer_t token_buffer = { 0 };

            while (breakpoint != NULL) {
                // If we hit whitespace, then we must have received content by
                // now, so we can return an element of the list.
                if (pm_char_is_whitespace(*breakpoint)) {
                    parser->current.end = breakpoint;
                    pm_token_buffer_flush(parser, &token_buffer);
                    LEX(PM_TOKEN_STRING_CONTENT);
                }

                // If we hit the terminator, we need to check which token to
                // return.
                if (*breakpoint == lex_mode->as.list.terminator) {
                    // If this terminator doesn't actually close the list, then
                    // we need to continue on past it.
                    if (lex_mode->as.list.nesting > 0) {
                        parser->current.end = breakpoint + 1;
                        breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, true);
                        lex_mode->as.list.nesting--;
                        continue;
                    }

                    // If we've hit the terminator and we've already skipped
                    // past content, then we can return a list node.
                    if (breakpoint > parser->current.start) {
                        parser->current.end = breakpoint;
                        pm_token_buffer_flush(parser, &token_buffer);
                        LEX(PM_TOKEN_STRING_CONTENT);
                    }

                    // Otherwise, switch back to the default state and return
                    // the end of the list.
                    parser->current.end = breakpoint + 1;
                    lex_mode_pop(parser);
                    lex_state_set(parser, PM_LEX_STATE_END);
                    LEX(PM_TOKEN_STRING_END);
                }

                // If we hit a null byte, skip directly past it.
                if (*breakpoint == '\0') {
                    breakpoint = pm_strpbrk(parser, breakpoint + 1, breakpoints, parser->end - (breakpoint + 1), true);
                    continue;
                }

                // If we hit escapes, then we need to treat the next token
                // literally. In this case we'll skip past the next character
                // and find the next breakpoint.
                if (*breakpoint == '\\') {
                    parser->current.end = breakpoint + 1;

                    // If we've hit the end of the file, then break out of the
                    // loop by setting the breakpoint to NULL.
                    if (parser->current.end == parser->end) {
                        breakpoint = NULL;
                        continue;
                    }

                    pm_token_buffer_escape(parser, &token_buffer);
                    uint8_t peeked = peek(parser);

                    switch (peeked) {
                        case ' ':
                        case '\f':
                        case '\t':
                        case '\v':
                        case '\\':
                            pm_token_buffer_push_byte(&token_buffer, peeked);
                            parser->current.end++;
                            break;
                        case '\r':
                            parser->current.end++;
                            if (peek(parser) != '\n') {
                                pm_token_buffer_push_byte(&token_buffer, '\r');
                                break;
                            }
                        PRISM_FALLTHROUGH
                        case '\n':
                            pm_token_buffer_push_byte(&token_buffer, '\n');

                            if (parser->heredoc_end) {
                                // ... if we are on the same line as a heredoc,
                                // flush the heredoc and continue parsing after
                                // heredoc_end.
                                parser_flush_heredoc_end(parser);
                                pm_token_buffer_copy(parser, &token_buffer);
                                LEX(PM_TOKEN_STRING_CONTENT);
                            } else {
                                // ... else track the newline.
                                pm_newline_list_append(&parser->newline_list, parser->current.end);
                            }

                            parser->current.end++;
                            break;
                        default:
                            if (peeked == lex_mode->as.list.incrementor || peeked == lex_mode->as.list.terminator) {
                                pm_token_buffer_push_byte(&token_buffer, peeked);
                                parser->current.end++;
                            } else if (lex_mode->as.list.interpolation) {
                                escape_read(parser, &token_buffer.buffer, NULL, PM_ESCAPE_FLAG_NONE);
                            } else {
                                pm_token_buffer_push_byte(&token_buffer, '\\');
                                pm_token_buffer_push_escaped(&token_buffer, parser);
                            }

                            break;
                    }

                    token_buffer.cursor = parser->current.end;
                    breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, true);
                    continue;
                }

                // If we hit a #, then we will attempt to lex interpolation.
                if (*breakpoint == '#') {
                    pm_token_type_t type = lex_interpolation(parser, breakpoint);

                    if (type == PM_TOKEN_NOT_PROVIDED) {
                        // If we haven't returned at this point then we had something
                        // that looked like an interpolated class or instance variable
                        // like "#@" but wasn't actually. In this case we'll just skip
                        // to the next breakpoint.
                        breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, true);
                        continue;
                    }

                    if (type == PM_TOKEN_STRING_CONTENT) {
                        pm_token_buffer_flush(parser, &token_buffer);
                    }

                    LEX(type);
                }

                // If we've hit the incrementor, then we need to skip past it
                // and find the next breakpoint.
                assert(*breakpoint == lex_mode->as.list.incrementor);
                parser->current.end = breakpoint + 1;
                breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, true);
                lex_mode->as.list.nesting++;
                continue;
            }

            if (parser->current.end > parser->current.start) {
                pm_token_buffer_flush(parser, &token_buffer);
                LEX(PM_TOKEN_STRING_CONTENT);
            }

            // If we were unable to find a breakpoint, then this token hits the
            // end of the file.
            parser->current.end = parser->end;
            pm_token_buffer_flush(parser, &token_buffer);
            LEX(PM_TOKEN_STRING_CONTENT);
        }
        case PM_LEX_REGEXP: {
            // First, we'll set to start of this token to be the current end.
            if (parser->next_start == NULL) {
                parser->current.start = parser->current.end;
            } else {
                parser->current.start = parser->next_start;
                parser->current.end = parser->next_start;
                parser->next_start = NULL;
            }

            // We'll check if we're at the end of the file. If we are, then we
            // need to return the EOF token.
            if (parser->current.end >= parser->end) {
                LEX(PM_TOKEN_EOF);
            }

            // Get a reference to the current mode.
            pm_lex_mode_t *lex_mode = parser->lex_modes.current;

            // These are the places where we need to split up the content of the
            // regular expression. We'll use strpbrk to find the first of these
            // characters.
            const uint8_t *breakpoints = lex_mode->as.regexp.breakpoints;
            const uint8_t *breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, false);
            pm_regexp_token_buffer_t token_buffer = { 0 };

            while (breakpoint != NULL) {
                uint8_t term = lex_mode->as.regexp.terminator;
                bool is_terminator = (*breakpoint == term);

                // If the terminator is newline, we need to consider \r\n _also_ a newline
                // For example: `%\nfoo\r\n`
                // The string should be "foo", not "foo\r"
                if (*breakpoint == '\r' && peek_at(parser, breakpoint + 1) == '\n') {
                    if (term == '\n') {
                        is_terminator = true;
                    }

                    // If the terminator is a CR, but we see a CRLF, we need to
                    // treat the CRLF as a newline, meaning this is _not_ the
                    // terminator
                    if (term == '\r') {
                        is_terminator = false;
                    }
                }

                // If we hit the terminator, we need to determine what kind of
                // token to return.
                if (is_terminator) {
                    if (lex_mode->as.regexp.nesting > 0) {
                        parser->current.end = breakpoint + 1;
                        breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, false);
                        lex_mode->as.regexp.nesting--;
                        continue;
                    }

                    // Here we've hit the terminator. If we have already consumed
                    // content then we need to return that content as string content
                    // first.
                    if (breakpoint > parser->current.start) {
                        parser->current.end = breakpoint;
                        pm_regexp_token_buffer_flush(parser, &token_buffer);
                        LEX(PM_TOKEN_STRING_CONTENT);
                    }

                    // Check here if we need to track the newline.
                    size_t eol_length = match_eol_at(parser, breakpoint);
                    if (eol_length) {
                        parser->current.end = breakpoint + eol_length;
                        pm_newline_list_append(&parser->newline_list, parser->current.end - 1);
                    } else {
                        parser->current.end = breakpoint + 1;
                    }

                    // Since we've hit the terminator of the regular expression,
                    // we now need to parse the options.
                    parser->current.end += pm_strspn_regexp_option(parser->current.end, parser->end - parser->current.end);

                    lex_mode_pop(parser);
                    lex_state_set(parser, PM_LEX_STATE_END);
                    LEX(PM_TOKEN_REGEXP_END);
                }

                // If we've hit the incrementor, then we need to skip past it
                // and find the next breakpoint.
                if (*breakpoint && *breakpoint == lex_mode->as.regexp.incrementor) {
                    parser->current.end = breakpoint + 1;
                    breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, false);
                    lex_mode->as.regexp.nesting++;
                    continue;
                }

                switch (*breakpoint) {
                    case '\0':
                        // If we hit a null byte, skip directly past it.
                        parser->current.end = breakpoint + 1;
                        breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, false);
                        break;
                    case '\r':
                        if (peek_at(parser, breakpoint + 1) != '\n') {
                            parser->current.end = breakpoint + 1;
                            breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, false);
                            break;
                        }

                        breakpoint++;
                        parser->current.end = breakpoint;
                        pm_regexp_token_buffer_escape(parser, &token_buffer);
                        token_buffer.base.cursor = breakpoint;

                        PRISM_FALLTHROUGH
                    case '\n':
                        // If we've hit a newline, then we need to track that in
                        // the list of newlines.
                        if (parser->heredoc_end == NULL) {
                            pm_newline_list_append(&parser->newline_list, breakpoint);
                            parser->current.end = breakpoint + 1;
                            breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, false);
                            break;
                        }

                        parser->current.end = breakpoint + 1;
                        parser_flush_heredoc_end(parser);
                        pm_regexp_token_buffer_flush(parser, &token_buffer);
                        LEX(PM_TOKEN_STRING_CONTENT);
                    case '\\': {
                        // If we hit escapes, then we need to treat the next
                        // token literally. In this case we'll skip past the
                        // next character and find the next breakpoint.
                        parser->current.end = breakpoint + 1;

                        // If we've hit the end of the file, then break out of
                        // the loop by setting the breakpoint to NULL.
                        if (parser->current.end == parser->end) {
                            breakpoint = NULL;
                            break;
                        }

                        pm_regexp_token_buffer_escape(parser, &token_buffer);
                        uint8_t peeked = peek(parser);

                        switch (peeked) {
                            case '\r':
                                parser->current.end++;
                                if (peek(parser) != '\n') {
                                    if (lex_mode->as.regexp.terminator != '\r') {
                                        pm_token_buffer_push_byte(&token_buffer.base, '\\');
                                    }
                                    pm_regexp_token_buffer_push_byte(&token_buffer, '\r');
                                    pm_token_buffer_push_byte(&token_buffer.base, '\r');
                                    break;
                                }
                            PRISM_FALLTHROUGH
                            case '\n':
                                if (parser->heredoc_end) {
                                    // ... if we are on the same line as a heredoc,
                                    // flush the heredoc and continue parsing after
                                    // heredoc_end.
                                    parser_flush_heredoc_end(parser);
                                    pm_regexp_token_buffer_copy(parser, &token_buffer);
                                    LEX(PM_TOKEN_STRING_CONTENT);
                                } else {
                                    // ... else track the newline.
                                    pm_newline_list_append(&parser->newline_list, parser->current.end);
                                }

                                parser->current.end++;
                                break;
                            case 'c':
                            case 'C':
                            case 'M':
                            case 'u':
                            case 'x':
                                escape_read(parser, &token_buffer.regexp_buffer, &token_buffer.base.buffer, PM_ESCAPE_FLAG_REGEXP);
                                break;
                            default:
                                if (lex_mode->as.regexp.terminator == peeked) {
                                    // Some characters when they are used as the
                                    // terminator also receive an escape. They are
                                    // enumerated here.
                                    switch (peeked) {
                                        case '$': case ')': case '*': case '+':
                                        case '.': case '>': case '?': case ']':
                                        case '^': case '|': case '}':
                                            pm_token_buffer_push_byte(&token_buffer.base, '\\');
                                            break;
                                        default:
                                            break;
                                    }

                                    pm_regexp_token_buffer_push_byte(&token_buffer, peeked);
                                    pm_token_buffer_push_byte(&token_buffer.base, peeked);
                                    parser->current.end++;
                                    break;
                                }

                                if (peeked < 0x80) pm_token_buffer_push_byte(&token_buffer.base, '\\');
                                pm_regexp_token_buffer_push_escaped(&token_buffer, parser);
                                break;
                        }

                        token_buffer.base.cursor = parser->current.end;
                        breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, false);
                        break;
                    }
                    case '#': {
                        // If we hit a #, then we will attempt to lex
                        // interpolation.
                        pm_token_type_t type = lex_interpolation(parser, breakpoint);

                        if (type == PM_TOKEN_NOT_PROVIDED) {
                            // If we haven't returned at this point then we had
                            // something that looked like an interpolated class or
                            // instance variable like "#@" but wasn't actually. In
                            // this case we'll just skip to the next breakpoint.
                            breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, false);
                            break;
                        }

                        if (type == PM_TOKEN_STRING_CONTENT) {
                            pm_regexp_token_buffer_flush(parser, &token_buffer);
                        }

                        LEX(type);
                    }
                    default:
                        assert(false && "unreachable");
                        break;
                }
            }

            if (parser->current.end > parser->current.start) {
                pm_regexp_token_buffer_flush(parser, &token_buffer);
                LEX(PM_TOKEN_STRING_CONTENT);
            }

            // If we were unable to find a breakpoint, then this token hits the
            // end of the file.
            parser->current.end = parser->end;
            pm_regexp_token_buffer_flush(parser, &token_buffer);
            LEX(PM_TOKEN_STRING_CONTENT);
        }
        case PM_LEX_STRING: {
            // First, we'll set to start of this token to be the current end.
            if (parser->next_start == NULL) {
                parser->current.start = parser->current.end;
            } else {
                parser->current.start = parser->next_start;
                parser->current.end = parser->next_start;
                parser->next_start = NULL;
            }

            // We'll check if we're at the end of the file. If we are, then we need to
            // return the EOF token.
            if (parser->current.end >= parser->end) {
                LEX(PM_TOKEN_EOF);
            }

            // These are the places where we need to split up the content of the
            // string. We'll use strpbrk to find the first of these characters.
            pm_lex_mode_t *lex_mode = parser->lex_modes.current;
            const uint8_t *breakpoints = lex_mode->as.string.breakpoints;
            const uint8_t *breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, true);

            // If we haven't found an escape yet, then this buffer will be
            // unallocated since we can refer directly to the source string.
            pm_token_buffer_t token_buffer = { 0 };

            while (breakpoint != NULL) {
                // If we hit the incrementor, then we'll increment then nesting and
                // continue lexing.
                if (lex_mode->as.string.incrementor != '\0' && *breakpoint == lex_mode->as.string.incrementor) {
                    lex_mode->as.string.nesting++;
                    parser->current.end = breakpoint + 1;
                    breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, true);
                    continue;
                }

                uint8_t term = lex_mode->as.string.terminator;
                bool is_terminator = (*breakpoint == term);

                // If the terminator is newline, we need to consider \r\n _also_ a newline
                // For example: `%r\nfoo\r\n`
                // The string should be /foo/, not /foo\r/
                if (*breakpoint == '\r' && peek_at(parser, breakpoint + 1) == '\n') {
                    if (term == '\n') {
                        is_terminator = true;
                    }

                    // If the terminator is a CR, but we see a CRLF, we need to
                    // treat the CRLF as a newline, meaning this is _not_ the
                    // terminator
                    if (term == '\r') {
                        is_terminator = false;
                    }
                }

                // Note that we have to check the terminator here first because we could
                // potentially be parsing a % string that has a # character as the
                // terminator.
                if (is_terminator) {
                    // If this terminator doesn't actually close the string, then we need
                    // to continue on past it.
                    if (lex_mode->as.string.nesting > 0) {
                        parser->current.end = breakpoint + 1;
                        breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, true);
                        lex_mode->as.string.nesting--;
                        continue;
                    }

                    // Here we've hit the terminator. If we have already consumed content
                    // then we need to return that content as string content first.
                    if (breakpoint > parser->current.start) {
                        parser->current.end = breakpoint;
                        pm_token_buffer_flush(parser, &token_buffer);
                        LEX(PM_TOKEN_STRING_CONTENT);
                    }

                    // Otherwise we need to switch back to the parent lex mode and
                    // return the end of the string.
                    size_t eol_length = match_eol_at(parser, breakpoint);
                    if (eol_length) {
                        parser->current.end = breakpoint + eol_length;
                        pm_newline_list_append(&parser->newline_list, parser->current.end - 1);
                    } else {
                        parser->current.end = breakpoint + 1;
                    }

                    if (lex_mode->as.string.label_allowed && (peek(parser) == ':') && (peek_offset(parser, 1) != ':')) {
                        parser->current.end++;
                        lex_state_set(parser, PM_LEX_STATE_ARG | PM_LEX_STATE_LABELED);
                        lex_mode_pop(parser);
                        LEX(PM_TOKEN_LABEL_END);
                    }

                    lex_state_set(parser, PM_LEX_STATE_END);
                    lex_mode_pop(parser);
                    LEX(PM_TOKEN_STRING_END);
                }

                switch (*breakpoint) {
                    case '\0':
                        // Skip directly past the null character.
                        parser->current.end = breakpoint + 1;
                        breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, true);
                        break;
                    case '\r':
                        if (peek_at(parser, breakpoint + 1) != '\n') {
                            parser->current.end = breakpoint + 1;
                            breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, true);
                            break;
                        }

                        // If we hit a \r\n sequence, then we need to treat it
                        // as a newline.
                        breakpoint++;
                        parser->current.end = breakpoint;
                        pm_token_buffer_escape(parser, &token_buffer);
                        token_buffer.cursor = breakpoint;

                        PRISM_FALLTHROUGH
                    case '\n':
                        // When we hit a newline, we need to flush any potential
                        // heredocs. Note that this has to happen after we check
                        // for the terminator in case the terminator is a
                        // newline character.
                        if (parser->heredoc_end == NULL) {
                            pm_newline_list_append(&parser->newline_list, breakpoint);
                            parser->current.end = breakpoint + 1;
                            breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, true);
                            break;
                        }

                        parser->current.end = breakpoint + 1;
                        parser_flush_heredoc_end(parser);
                        pm_token_buffer_flush(parser, &token_buffer);
                        LEX(PM_TOKEN_STRING_CONTENT);
                    case '\\': {
                        // Here we hit escapes.
                        parser->current.end = breakpoint + 1;

                        // If we've hit the end of the file, then break out of
                        // the loop by setting the breakpoint to NULL.
                        if (parser->current.end == parser->end) {
                            breakpoint = NULL;
                            continue;
                        }

                        pm_token_buffer_escape(parser, &token_buffer);
                        uint8_t peeked = peek(parser);

                        switch (peeked) {
                            case '\\':
                                pm_token_buffer_push_byte(&token_buffer, '\\');
                                parser->current.end++;
                                break;
                            case '\r':
                                parser->current.end++;
                                if (peek(parser) != '\n') {
                                    if (!lex_mode->as.string.interpolation) {
                                        pm_token_buffer_push_byte(&token_buffer, '\\');
                                    }
                                    pm_token_buffer_push_byte(&token_buffer, '\r');
                                    break;
                                }
                            PRISM_FALLTHROUGH
                            case '\n':
                                if (!lex_mode->as.string.interpolation) {
                                    pm_token_buffer_push_byte(&token_buffer, '\\');
                                    pm_token_buffer_push_byte(&token_buffer, '\n');
                                }

                                if (parser->heredoc_end) {
                                    // ... if we are on the same line as a heredoc,
                                    // flush the heredoc and continue parsing after
                                    // heredoc_end.
                                    parser_flush_heredoc_end(parser);
                                    pm_token_buffer_copy(parser, &token_buffer);
                                    LEX(PM_TOKEN_STRING_CONTENT);
                                } else {
                                    // ... else track the newline.
                                    pm_newline_list_append(&parser->newline_list, parser->current.end);
                                }

                                parser->current.end++;
                                break;
                            default:
                                if (lex_mode->as.string.incrementor != '\0' && peeked == lex_mode->as.string.incrementor) {
                                    pm_token_buffer_push_byte(&token_buffer, peeked);
                                    parser->current.end++;
                                } else if (lex_mode->as.string.terminator != '\0' && peeked == lex_mode->as.string.terminator) {
                                    pm_token_buffer_push_byte(&token_buffer, peeked);
                                    parser->current.end++;
                                } else if (lex_mode->as.string.interpolation) {
                                    escape_read(parser, &token_buffer.buffer, NULL, PM_ESCAPE_FLAG_NONE);
                                } else {
                                    pm_token_buffer_push_byte(&token_buffer, '\\');
                                    pm_token_buffer_push_escaped(&token_buffer, parser);
                                }

                                break;
                        }

                        token_buffer.cursor = parser->current.end;
                        breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, true);
                        break;
                    }
                    case '#': {
                        pm_token_type_t type = lex_interpolation(parser, breakpoint);

                        if (type == PM_TOKEN_NOT_PROVIDED) {
                            // If we haven't returned at this point then we had something that
                            // looked like an interpolated class or instance variable like "#@"
                            // but wasn't actually. In this case we'll just skip to the next
                            // breakpoint.
                            breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, true);
                            break;
                        }

                        if (type == PM_TOKEN_STRING_CONTENT) {
                            pm_token_buffer_flush(parser, &token_buffer);
                        }

                        LEX(type);
                    }
                    default:
                        assert(false && "unreachable");
                }
            }

            if (parser->current.end > parser->current.start) {
                pm_token_buffer_flush(parser, &token_buffer);
                LEX(PM_TOKEN_STRING_CONTENT);
            }

            // If we've hit the end of the string, then this is an unterminated
            // string. In that case we'll return a string content token.
            parser->current.end = parser->end;
            pm_token_buffer_flush(parser, &token_buffer);
            LEX(PM_TOKEN_STRING_CONTENT);
        }
        case PM_LEX_HEREDOC: {
            // First, we'll set to start of this token.
            if (parser->next_start == NULL) {
                parser->current.start = parser->current.end;
            } else {
                parser->current.start = parser->next_start;
                parser->current.end = parser->next_start;
                parser->heredoc_end = NULL;
                parser->next_start = NULL;
            }

            // Now let's grab the information about the identifier off of the
            // current lex mode.
            pm_lex_mode_t *lex_mode = parser->lex_modes.current;
            pm_heredoc_lex_mode_t *heredoc_lex_mode = &lex_mode->as.heredoc.base;

            bool line_continuation = lex_mode->as.heredoc.line_continuation;
            lex_mode->as.heredoc.line_continuation = false;

            // We'll check if we're at the end of the file. If we are, then we
            // will add an error (because we weren't able to find the
            // terminator) but still continue parsing so that content after the
            // declaration of the heredoc can be parsed.
            if (parser->current.end >= parser->end) {
                pm_parser_err_heredoc_term(parser, heredoc_lex_mode->ident_start, heredoc_lex_mode->ident_length);
                parser->next_start = lex_mode->as.heredoc.next_start;
                parser->heredoc_end = parser->current.end;
                lex_state_set(parser, PM_LEX_STATE_END);
                lex_mode_pop(parser);
                LEX(PM_TOKEN_HEREDOC_END);
            }

            const uint8_t *ident_start = heredoc_lex_mode->ident_start;
            size_t ident_length = heredoc_lex_mode->ident_length;

            // If we are immediately following a newline and we have hit the
            // terminator, then we need to return the ending of the heredoc.
            if (current_token_starts_line(parser)) {
                const uint8_t *start = parser->current.start;

                if (!line_continuation && (start + ident_length <= parser->end)) {
                    const uint8_t *newline = next_newline(start, parser->end - start);
                    const uint8_t *ident_end = newline;
                    const uint8_t *terminator_end = newline;

                    if (newline == NULL) {
                        terminator_end = parser->end;
                        ident_end = parser->end;
                    } else {
                        terminator_end++;
                        if (newline[-1] == '\r') {
                            ident_end--; // Remove \r
                        }
                    }

                    const uint8_t *terminator_start = ident_end - ident_length;
                    const uint8_t *cursor = start;

                    if (heredoc_lex_mode->indent == PM_HEREDOC_INDENT_DASH || heredoc_lex_mode->indent == PM_HEREDOC_INDENT_TILDE) {
                        while (cursor < terminator_start && pm_char_is_inline_whitespace(*cursor)) {
                            cursor++;
                        }
                    }

                    if (
                        (cursor == terminator_start) &&
                        (memcmp(terminator_start, ident_start, ident_length) == 0)
                    ) {
                        if (newline != NULL) {
                            pm_newline_list_append(&parser->newline_list, newline);
                        }

                        parser->current.end = terminator_end;
                        if (*lex_mode->as.heredoc.next_start == '\\') {
                            parser->next_start = NULL;
                        } else {
                            parser->next_start = lex_mode->as.heredoc.next_start;
                            parser->heredoc_end = parser->current.end;
                        }

                        lex_state_set(parser, PM_LEX_STATE_END);
                        lex_mode_pop(parser);
                        LEX(PM_TOKEN_HEREDOC_END);
                    }
                }

                size_t whitespace = pm_heredoc_strspn_inline_whitespace(parser, &start, heredoc_lex_mode->indent);
                if (
                    heredoc_lex_mode->indent == PM_HEREDOC_INDENT_TILDE &&
                    lex_mode->as.heredoc.common_whitespace != NULL &&
                    (*lex_mode->as.heredoc.common_whitespace > whitespace) &&
                    peek_at(parser, start) != '\n'
                ) {
                    *lex_mode->as.heredoc.common_whitespace = whitespace;
                }
            }

            // Otherwise we'll be parsing string content. These are the places
            // where we need to split up the content of the heredoc. We'll use
            // strpbrk to find the first of these characters.
            uint8_t breakpoints[] = "\r\n\\#";

            pm_heredoc_quote_t quote = heredoc_lex_mode->quote;
            if (quote == PM_HEREDOC_QUOTE_SINGLE) {
                breakpoints[3] = '\0';
            }

            const uint8_t *breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, true);
            pm_token_buffer_t token_buffer = { 0 };
            bool was_line_continuation = false;

            while (breakpoint != NULL) {
                switch (*breakpoint) {
                    case '\0':
                        // Skip directly past the null character.
                        parser->current.end = breakpoint + 1;
                        breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, true);
                        break;
                    case '\r':
                        parser->current.end = breakpoint + 1;

                        if (peek_at(parser, breakpoint + 1) != '\n') {
                            breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, true);
                            break;
                        }

                        // If we hit a \r\n sequence, then we want to replace it
                        // with a single \n character in the final string.
                        breakpoint++;
                        pm_token_buffer_escape(parser, &token_buffer);
                        token_buffer.cursor = breakpoint;

                        PRISM_FALLTHROUGH
                    case '\n': {
                        if (parser->heredoc_end != NULL && (parser->heredoc_end > breakpoint)) {
                            parser_flush_heredoc_end(parser);
                            parser->current.end = breakpoint + 1;
                            pm_token_buffer_flush(parser, &token_buffer);
                            LEX(PM_TOKEN_STRING_CONTENT);
                        }

                        pm_newline_list_append(&parser->newline_list, breakpoint);

                        // If we have a - or ~ heredoc, then we can match after
                        // some leading whitespace.
                        const uint8_t *start = breakpoint + 1;

                        if (!was_line_continuation && (start + ident_length <= parser->end)) {
                            // We want to match the terminator starting from the end of the line in case
                            // there is whitespace in the ident such as <<-'   DOC' or <<~'   DOC'.
                            const uint8_t *newline = next_newline(start, parser->end - start);

                            if (newline == NULL) {
                                newline = parser->end;
                            } else if (newline[-1] == '\r') {
                                newline--; // Remove \r
                            }

                            // Start of a possible terminator.
                            const uint8_t *terminator_start = newline - ident_length;

                            // Cursor to check for the leading whitespace. We skip the
                            // leading whitespace if we have a - or ~ heredoc.
                            const uint8_t *cursor = start;

                            if (heredoc_lex_mode->indent == PM_HEREDOC_INDENT_DASH || heredoc_lex_mode->indent == PM_HEREDOC_INDENT_TILDE) {
                                while (cursor < terminator_start && pm_char_is_inline_whitespace(*cursor)) {
                                    cursor++;
                                }
                            }

                            if (
                                cursor == terminator_start &&
                                (memcmp(terminator_start, ident_start, ident_length) == 0)
                            ) {
                                parser->current.end = breakpoint + 1;
                                pm_token_buffer_flush(parser, &token_buffer);
                                LEX(PM_TOKEN_STRING_CONTENT);
                            }
                        }

                        size_t whitespace = pm_heredoc_strspn_inline_whitespace(parser, &start, lex_mode->as.heredoc.base.indent);

                        // If we have hit a newline that is followed by a valid
                        // terminator, then we need to return the content of the
                        // heredoc here as string content. Then, the next time a
                        // token is lexed, it will match again and return the
                        // end of the heredoc.
                        if (lex_mode->as.heredoc.base.indent == PM_HEREDOC_INDENT_TILDE) {
                            if ((lex_mode->as.heredoc.common_whitespace != NULL) && (*lex_mode->as.heredoc.common_whitespace > whitespace) && peek_at(parser, start) != '\n') {
                                *lex_mode->as.heredoc.common_whitespace = whitespace;
                            }

                            parser->current.end = breakpoint + 1;
                            pm_token_buffer_flush(parser, &token_buffer);
                            LEX(PM_TOKEN_STRING_CONTENT);
                        }

                        // Otherwise we hit a newline and it wasn't followed by
                        // a terminator, so we can continue parsing.
                        parser->current.end = breakpoint + 1;
                        breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, true);
                        break;
                    }
                    case '\\': {
                        // If we hit an escape, then we need to skip past
                        // however many characters the escape takes up. However
                        // it's important that if \n or \r\n are escaped, we
                        // stop looping before the newline and not after the
                        // newline so that we can still potentially find the
                        // terminator of the heredoc.
                        parser->current.end = breakpoint + 1;

                        // If we've hit the end of the file, then break out of
                        // the loop by setting the breakpoint to NULL.
                        if (parser->current.end == parser->end) {
                            breakpoint = NULL;
                            continue;
                        }

                        pm_token_buffer_escape(parser, &token_buffer);
                        uint8_t peeked = peek(parser);

                        if (quote == PM_HEREDOC_QUOTE_SINGLE) {
                            switch (peeked) {
                                case '\r':
                                    parser->current.end++;
                                    if (peek(parser) != '\n') {
                                        pm_token_buffer_push_byte(&token_buffer, '\\');
                                        pm_token_buffer_push_byte(&token_buffer, '\r');
                                        break;
                                    }
                                PRISM_FALLTHROUGH
                                case '\n':
                                    pm_token_buffer_push_byte(&token_buffer, '\\');
                                    pm_token_buffer_push_byte(&token_buffer, '\n');
                                    token_buffer.cursor = parser->current.end + 1;
                                    breakpoint = parser->current.end;
                                    continue;
                                default:
                                    pm_token_buffer_push_byte(&token_buffer, '\\');
                                    pm_token_buffer_push_escaped(&token_buffer, parser);
                                    break;
                            }
                        } else {
                            switch (peeked) {
                                case '\r':
                                    parser->current.end++;
                                    if (peek(parser) != '\n') {
                                        pm_token_buffer_push_byte(&token_buffer, '\r');
                                        break;
                                    }
                                PRISM_FALLTHROUGH
                                case '\n':
                                    // If we are in a tilde here, we should
                                    // break out of the loop and return the
                                    // string content.
                                    if (heredoc_lex_mode->indent == PM_HEREDOC_INDENT_TILDE) {
                                        const uint8_t *end = parser->current.end;
                                        pm_newline_list_append(&parser->newline_list, end);

                                        // Here we want the buffer to only
                                        // include up to the backslash.
                                        parser->current.end = breakpoint;
                                        pm_token_buffer_flush(parser, &token_buffer);

                                        // Now we can advance the end of the
                                        // token past the newline.
                                        parser->current.end = end + 1;
                                        lex_mode->as.heredoc.line_continuation = true;
                                        LEX(PM_TOKEN_STRING_CONTENT);
                                    }

                                    was_line_continuation = true;
                                    token_buffer.cursor = parser->current.end + 1;
                                    breakpoint = parser->current.end;
                                    continue;
                                default:
                                    escape_read(parser, &token_buffer.buffer, NULL, PM_ESCAPE_FLAG_NONE);
                                    break;
                            }
                        }

                        token_buffer.cursor = parser->current.end;
                        breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, true);
                        break;
                    }
                    case '#': {
                        pm_token_type_t type = lex_interpolation(parser, breakpoint);

                        if (type == PM_TOKEN_NOT_PROVIDED) {
                            // If we haven't returned at this point then we had
                            // something that looked like an interpolated class
                            // or instance variable like "#@" but wasn't
                            // actually. In this case we'll just skip to the
                            // next breakpoint.
                            breakpoint = pm_strpbrk(parser, parser->current.end, breakpoints, parser->end - parser->current.end, true);
                            break;
                        }

                        if (type == PM_TOKEN_STRING_CONTENT) {
                            pm_token_buffer_flush(parser, &token_buffer);
                        }

                        LEX(type);
                    }
                    default:
                        assert(false && "unreachable");
                }

                was_line_continuation = false;
            }

            if (parser->current.end > parser->current.start) {
                parser->current.end = parser->end;
                pm_token_buffer_flush(parser, &token_buffer);
                LEX(PM_TOKEN_STRING_CONTENT);
            }

            // If we've hit the end of the string, then this is an unterminated
            // heredoc. In that case we'll return a string content token.
            parser->current.end = parser->end;
            pm_token_buffer_flush(parser, &token_buffer);
            LEX(PM_TOKEN_STRING_CONTENT);
        }
    }

    assert(false && "unreachable");
}

#undef LEX

/******************************************************************************/
/* Parse functions                                                            */
/******************************************************************************/

/**
 * These are the various precedence rules. Because we are using a Pratt parser,
 * they are named binding power to represent the manner in which nodes are bound
 * together in the stack.
 *
 * We increment by 2 because we want to leave room for the infix operators to
 * specify their associativity by adding or subtracting one.
 */
typedef enum {
    PM_BINDING_POWER_UNSET =             0, // used to indicate this token cannot be used as an infix operator
    PM_BINDING_POWER_STATEMENT =         2,
    PM_BINDING_POWER_MODIFIER_RESCUE =   4, // rescue
    PM_BINDING_POWER_MODIFIER =          6, // if unless until while
    PM_BINDING_POWER_COMPOSITION =       8, // and or
    PM_BINDING_POWER_NOT =              10, // not
    PM_BINDING_POWER_MATCH =            12, // => in
    PM_BINDING_POWER_DEFINED =          14, // defined?
    PM_BINDING_POWER_MULTI_ASSIGNMENT = 16, // =
    PM_BINDING_POWER_ASSIGNMENT =       18, // = += -= *= /= %= &= |= ^= &&= ||= <<= >>= **=
    PM_BINDING_POWER_TERNARY =          20, // ?:
    PM_BINDING_POWER_RANGE =            22, // .. ...
    PM_BINDING_POWER_LOGICAL_OR =       24, // ||
    PM_BINDING_POWER_LOGICAL_AND =      26, // &&
    PM_BINDING_POWER_EQUALITY =         28, // <=> == === != =~ !~
    PM_BINDING_POWER_COMPARISON =       30, // > >= < <=
    PM_BINDING_POWER_BITWISE_OR =       32, // | ^
    PM_BINDING_POWER_BITWISE_AND =      34, // &
    PM_BINDING_POWER_SHIFT =            36, // << >>
    PM_BINDING_POWER_TERM =             38, // + -
    PM_BINDING_POWER_FACTOR =           40, // * / %
    PM_BINDING_POWER_UMINUS =           42, // -@
    PM_BINDING_POWER_EXPONENT =         44, // **
    PM_BINDING_POWER_UNARY =            46, // ! ~ +@
    PM_BINDING_POWER_INDEX =            48, // [] []=
    PM_BINDING_POWER_CALL =             50, // :: .
    PM_BINDING_POWER_MAX =              52
} pm_binding_power_t;

/**
 * This struct represents a set of binding powers used for a given token. They
 * are combined in this way to make it easier to represent associativity.
 */
typedef struct {
    /** The left binding power. */
    pm_binding_power_t left;

    /** The right binding power. */
    pm_binding_power_t right;

    /** Whether or not this token can be used as a binary operator. */
    bool binary;

    /**
     * Whether or not this token can be used as non-associative binary operator.
     * Non-associative operators (e.g. in and =>) need special treatment in parse_expression.
     */
    bool nonassoc;
} pm_binding_powers_t;

#define BINDING_POWER_ASSIGNMENT { PM_BINDING_POWER_UNARY, PM_BINDING_POWER_ASSIGNMENT, true, false }
#define LEFT_ASSOCIATIVE(precedence) { precedence, precedence + 1, true, false }
#define RIGHT_ASSOCIATIVE(precedence) { precedence, precedence, true, false }
#define NON_ASSOCIATIVE(precedence) { precedence, precedence + 1, true, true }
#define RIGHT_ASSOCIATIVE_UNARY(precedence) { precedence, precedence, false, false }

pm_binding_powers_t pm_binding_powers[PM_TOKEN_MAXIMUM] = {
    // rescue
    [PM_TOKEN_KEYWORD_RESCUE_MODIFIER] = { PM_BINDING_POWER_MODIFIER_RESCUE, PM_BINDING_POWER_COMPOSITION, true, false },

    // if unless until while
    [PM_TOKEN_KEYWORD_IF_MODIFIER] = LEFT_ASSOCIATIVE(PM_BINDING_POWER_MODIFIER),
    [PM_TOKEN_KEYWORD_UNLESS_MODIFIER] = LEFT_ASSOCIATIVE(PM_BINDING_POWER_MODIFIER),
    [PM_TOKEN_KEYWORD_UNTIL_MODIFIER] = LEFT_ASSOCIATIVE(PM_BINDING_POWER_MODIFIER),
    [PM_TOKEN_KEYWORD_WHILE_MODIFIER] = LEFT_ASSOCIATIVE(PM_BINDING_POWER_MODIFIER),

    // and or
    [PM_TOKEN_KEYWORD_AND] = LEFT_ASSOCIATIVE(PM_BINDING_POWER_COMPOSITION),
    [PM_TOKEN_KEYWORD_OR] = LEFT_ASSOCIATIVE(PM_BINDING_POWER_COMPOSITION),

    // => in
    [PM_TOKEN_EQUAL_GREATER] = NON_ASSOCIATIVE(PM_BINDING_POWER_MATCH),
    [PM_TOKEN_KEYWORD_IN] = NON_ASSOCIATIVE(PM_BINDING_POWER_MATCH),

    // &&= &= ^= = >>= <<= -= %= |= ||= += /= *= **=
    [PM_TOKEN_AMPERSAND_AMPERSAND_EQUAL] = BINDING_POWER_ASSIGNMENT,
    [PM_TOKEN_AMPERSAND_EQUAL] = BINDING_POWER_ASSIGNMENT,
    [PM_TOKEN_CARET_EQUAL] = BINDING_POWER_ASSIGNMENT,
    [PM_TOKEN_EQUAL] = BINDING_POWER_ASSIGNMENT,
    [PM_TOKEN_GREATER_GREATER_EQUAL] = BINDING_POWER_ASSIGNMENT,
    [PM_TOKEN_LESS_LESS_EQUAL] = BINDING_POWER_ASSIGNMENT,
    [PM_TOKEN_MINUS_EQUAL] = BINDING_POWER_ASSIGNMENT,
    [PM_TOKEN_PERCENT_EQUAL] = BINDING_POWER_ASSIGNMENT,
    [PM_TOKEN_PIPE_EQUAL] = BINDING_POWER_ASSIGNMENT,
    [PM_TOKEN_PIPE_PIPE_EQUAL] = BINDING_POWER_ASSIGNMENT,
    [PM_TOKEN_PLUS_EQUAL] = BINDING_POWER_ASSIGNMENT,
    [PM_TOKEN_SLASH_EQUAL] = BINDING_POWER_ASSIGNMENT,
    [PM_TOKEN_STAR_EQUAL] = BINDING_POWER_ASSIGNMENT,
    [PM_TOKEN_STAR_STAR_EQUAL] = BINDING_POWER_ASSIGNMENT,

    // ?:
    [PM_TOKEN_QUESTION_MARK] = RIGHT_ASSOCIATIVE(PM_BINDING_POWER_TERNARY),

    // .. ...
    [PM_TOKEN_DOT_DOT] = NON_ASSOCIATIVE(PM_BINDING_POWER_RANGE),
    [PM_TOKEN_DOT_DOT_DOT] = NON_ASSOCIATIVE(PM_BINDING_POWER_RANGE),
    [PM_TOKEN_UDOT_DOT] = RIGHT_ASSOCIATIVE_UNARY(PM_BINDING_POWER_LOGICAL_OR),
    [PM_TOKEN_UDOT_DOT_DOT] = RIGHT_ASSOCIATIVE_UNARY(PM_BINDING_POWER_LOGICAL_OR),

    // ||
    [PM_TOKEN_PIPE_PIPE] = LEFT_ASSOCIATIVE(PM_BINDING_POWER_LOGICAL_OR),

    // &&
    [PM_TOKEN_AMPERSAND_AMPERSAND] = LEFT_ASSOCIATIVE(PM_BINDING_POWER_LOGICAL_AND),

    // != !~ == === =~ <=>
    [PM_TOKEN_BANG_EQUAL] = NON_ASSOCIATIVE(PM_BINDING_POWER_EQUALITY),
    [PM_TOKEN_BANG_TILDE] = NON_ASSOCIATIVE(PM_BINDING_POWER_EQUALITY),
    [PM_TOKEN_EQUAL_EQUAL] = NON_ASSOCIATIVE(PM_BINDING_POWER_EQUALITY),
    [PM_TOKEN_EQUAL_EQUAL_EQUAL] = NON_ASSOCIATIVE(PM_BINDING_POWER_EQUALITY),
    [PM_TOKEN_EQUAL_TILDE] = NON_ASSOCIATIVE(PM_BINDING_POWER_EQUALITY),
    [PM_TOKEN_LESS_EQUAL_GREATER] = NON_ASSOCIATIVE(PM_BINDING_POWER_EQUALITY),

    // > >= < <=
    [PM_TOKEN_GREATER] = LEFT_ASSOCIATIVE(PM_BINDING_POWER_COMPARISON),
    [PM_TOKEN_GREATER_EQUAL] = LEFT_ASSOCIATIVE(PM_BINDING_POWER_COMPARISON),
    [PM_TOKEN_LESS] = LEFT_ASSOCIATIVE(PM_BINDING_POWER_COMPARISON),
    [PM_TOKEN_LESS_EQUAL] = LEFT_ASSOCIATIVE(PM_BINDING_POWER_COMPARISON),

    // ^ |
    [PM_TOKEN_CARET] = LEFT_ASSOCIATIVE(PM_BINDING_POWER_BITWISE_OR),
    [PM_TOKEN_PIPE] = LEFT_ASSOCIATIVE(PM_BINDING_POWER_BITWISE_OR),

    // &
    [PM_TOKEN_AMPERSAND] = LEFT_ASSOCIATIVE(PM_BINDING_POWER_BITWISE_AND),

    // >> <<
    [PM_TOKEN_GREATER_GREATER] = LEFT_ASSOCIATIVE(PM_BINDING_POWER_SHIFT),
    [PM_TOKEN_LESS_LESS] = LEFT_ASSOCIATIVE(PM_BINDING_POWER_SHIFT),

    // - +
    [PM_TOKEN_MINUS] = LEFT_ASSOCIATIVE(PM_BINDING_POWER_TERM),
    [PM_TOKEN_PLUS] = LEFT_ASSOCIATIVE(PM_BINDING_POWER_TERM),

    // % / *
    [PM_TOKEN_PERCENT] = LEFT_ASSOCIATIVE(PM_BINDING_POWER_FACTOR),
    [PM_TOKEN_SLASH] = LEFT_ASSOCIATIVE(PM_BINDING_POWER_FACTOR),
    [PM_TOKEN_STAR] = LEFT_ASSOCIATIVE(PM_BINDING_POWER_FACTOR),
    [PM_TOKEN_USTAR] = RIGHT_ASSOCIATIVE_UNARY(PM_BINDING_POWER_FACTOR),

    // -@
    [PM_TOKEN_UMINUS] = RIGHT_ASSOCIATIVE_UNARY(PM_BINDING_POWER_UMINUS),
    [PM_TOKEN_UMINUS_NUM] = { PM_BINDING_POWER_UMINUS, PM_BINDING_POWER_MAX, false, false },

    // **
    [PM_TOKEN_STAR_STAR] = RIGHT_ASSOCIATIVE(PM_BINDING_POWER_EXPONENT),
    [PM_TOKEN_USTAR_STAR] = RIGHT_ASSOCIATIVE_UNARY(PM_BINDING_POWER_UNARY),

    // ! ~ +@
    [PM_TOKEN_BANG] = RIGHT_ASSOCIATIVE_UNARY(PM_BINDING_POWER_UNARY),
    [PM_TOKEN_TILDE] = RIGHT_ASSOCIATIVE_UNARY(PM_BINDING_POWER_UNARY),
    [PM_TOKEN_UPLUS] = RIGHT_ASSOCIATIVE_UNARY(PM_BINDING_POWER_UNARY),

    // [
    [PM_TOKEN_BRACKET_LEFT] = LEFT_ASSOCIATIVE(PM_BINDING_POWER_INDEX),

    // :: . &.
    [PM_TOKEN_COLON_COLON] = RIGHT_ASSOCIATIVE(PM_BINDING_POWER_CALL),
    [PM_TOKEN_DOT] = RIGHT_ASSOCIATIVE(PM_BINDING_POWER_CALL),
    [PM_TOKEN_AMPERSAND_DOT] = RIGHT_ASSOCIATIVE(PM_BINDING_POWER_CALL)
};

#undef BINDING_POWER_ASSIGNMENT
#undef LEFT_ASSOCIATIVE
#undef RIGHT_ASSOCIATIVE
#undef RIGHT_ASSOCIATIVE_UNARY

/**
 * Returns true if the current token is of the given type.
 */
static inline bool
match1(const pm_parser_t *parser, pm_token_type_t type) {
    return parser->current.type == type;
}

/**
 * Returns true if the current token is of either of the given types.
 */
static inline bool
match2(const pm_parser_t *parser, pm_token_type_t type1, pm_token_type_t type2) {
    return match1(parser, type1) || match1(parser, type2);
}

/**
 * Returns true if the current token is any of the three given types.
 */
static inline bool
match3(const pm_parser_t *parser, pm_token_type_t type1, pm_token_type_t type2, pm_token_type_t type3) {
    return match1(parser, type1) || match1(parser, type2) || match1(parser, type3);
}

/**
 * Returns true if the current token is any of the four given types.
 */
static inline bool
match4(const pm_parser_t *parser, pm_token_type_t type1, pm_token_type_t type2, pm_token_type_t type3, pm_token_type_t type4) {
    return match1(parser, type1) || match1(parser, type2) || match1(parser, type3) || match1(parser, type4);
}

/**
 * Returns true if the current token is any of the seven given types.
 */
static inline bool
match7(const pm_parser_t *parser, pm_token_type_t type1, pm_token_type_t type2, pm_token_type_t type3, pm_token_type_t type4, pm_token_type_t type5, pm_token_type_t type6, pm_token_type_t type7) {
    return match1(parser, type1) || match1(parser, type2) || match1(parser, type3) || match1(parser, type4) || match1(parser, type5) || match1(parser, type6) || match1(parser, type7);
}

/**
 * Returns true if the current token is any of the eight given types.
 */
static inline bool
match8(const pm_parser_t *parser, pm_token_type_t type1, pm_token_type_t type2, pm_token_type_t type3, pm_token_type_t type4, pm_token_type_t type5, pm_token_type_t type6, pm_token_type_t type7, pm_token_type_t type8) {
    return match1(parser, type1) || match1(parser, type2) || match1(parser, type3) || match1(parser, type4) || match1(parser, type5) || match1(parser, type6) || match1(parser, type7) || match1(parser, type8);
}

/**
 * Returns true if the current token is any of the nine given types.
 */
static inline bool
match9(const pm_parser_t *parser, pm_token_type_t type1, pm_token_type_t type2, pm_token_type_t type3, pm_token_type_t type4, pm_token_type_t type5, pm_token_type_t type6, pm_token_type_t type7, pm_token_type_t type8, pm_token_type_t type9) {
    return match1(parser, type1) || match1(parser, type2) || match1(parser, type3) || match1(parser, type4) || match1(parser, type5) || match1(parser, type6) || match1(parser, type7) || match1(parser, type8) || match1(parser, type9);
}

/**
 * If the current token is of the specified type, lex forward by one token and
 * return true. Otherwise, return false. For example:
 *
 *     if (accept1(parser, PM_TOKEN_COLON)) { ... }
 */
static bool
accept1(pm_parser_t *parser, pm_token_type_t type) {
    if (match1(parser, type)) {
        parser_lex(parser);
        return true;
    }
    return false;
}

/**
 * If the current token is either of the two given types, lex forward by one
 * token and return true. Otherwise return false.
 */
static inline bool
accept2(pm_parser_t *parser, pm_token_type_t type1, pm_token_type_t type2) {
    if (match2(parser, type1, type2)) {
        parser_lex(parser);
        return true;
    }
    return false;
}

/**
 * This function indicates that the parser expects a token in a specific
 * position. For example, if you're parsing a BEGIN block, you know that a { is
 * expected immediately after the keyword. In that case you would call this
 * function to indicate that that token should be found.
 *
 * If we didn't find the token that we were expecting, then we're going to add
 * an error to the parser's list of errors (to indicate that the tree is not
 * valid) and create an artificial token instead. This allows us to recover from
 * the fact that the token isn't present and continue parsing.
 */
static void
expect1(pm_parser_t *parser, pm_token_type_t type, pm_diagnostic_id_t diag_id) {
    if (accept1(parser, type)) return;

    const uint8_t *location = parser->previous.end;
    pm_parser_err(parser, location, location, diag_id);

    parser->previous.start = location;
    parser->previous.type = PM_TOKEN_MISSING;
}

/**
 * This function is the same as expect1, but it expects either of two token
 * types.
 */
static void
expect2(pm_parser_t *parser, pm_token_type_t type1, pm_token_type_t type2, pm_diagnostic_id_t diag_id) {
    if (accept2(parser, type1, type2)) return;

    const uint8_t *location = parser->previous.end;
    pm_parser_err(parser, location, location, diag_id);

    parser->previous.start = location;
    parser->previous.type = PM_TOKEN_MISSING;
}

/**
 * A special expect1 that expects a heredoc terminator and handles popping the
 * lex mode accordingly.
 */
static void
expect1_heredoc_term(pm_parser_t *parser, const uint8_t *ident_start, size_t ident_length) {
    if (match1(parser, PM_TOKEN_HEREDOC_END)) {
        parser_lex(parser);
    } else {
        pm_parser_err_heredoc_term(parser, ident_start, ident_length);
        parser->previous.start = parser->previous.end;
        parser->previous.type = PM_TOKEN_MISSING;
    }
}

static pm_node_t *
parse_expression(pm_parser_t *parser, pm_binding_power_t binding_power, bool accepts_command_call, bool accepts_label, pm_diagnostic_id_t diag_id, uint16_t depth);

/**
 * This is a wrapper of parse_expression, which also checks whether the
 * resulting node is a value expression.
 */
static pm_node_t *
parse_value_expression(pm_parser_t *parser, pm_binding_power_t binding_power, bool accepts_command_call, bool accepts_label, pm_diagnostic_id_t diag_id, uint16_t depth) {
    pm_node_t *node = parse_expression(parser, binding_power, accepts_command_call, accepts_label, diag_id, depth);
    pm_assert_value_expression(parser, node);
    return node;
}

/**
 * This function controls whether or not we will attempt to parse an expression
 * beginning at the subsequent token. It is used when we are in a context where
 * an expression is optional.
 *
 * For example, looking at a range object when we've already lexed the operator,
 * we need to know if we should attempt to parse an expression on the right.
 *
 * For another example, if we've parsed an identifier or a method call and we do
 * not have parentheses, then the next token may be the start of an argument or
 * it may not.
 *
 * CRuby parsers that are generated would resolve this by using a lookahead and
 * potentially backtracking. We attempt to do this by just looking at the next
 * token and making a decision based on that. I am not sure if this is going to
 * work in all cases, it may need to be refactored later. But it appears to work
 * for now.
 */
static inline bool
token_begins_expression_p(pm_token_type_t type) {
    switch (type) {
        case PM_TOKEN_EQUAL_GREATER:
        case PM_TOKEN_KEYWORD_IN:
            // We need to special case this because it is a binary operator that
            // should not be marked as beginning an expression.
            return false;
        case PM_TOKEN_BRACE_RIGHT:
        case PM_TOKEN_BRACKET_RIGHT:
        case PM_TOKEN_COLON:
        case PM_TOKEN_COMMA:
        case PM_TOKEN_EMBEXPR_END:
        case PM_TOKEN_EOF:
        case PM_TOKEN_LAMBDA_BEGIN:
        case PM_TOKEN_KEYWORD_DO:
        case PM_TOKEN_KEYWORD_DO_LOOP:
        case PM_TOKEN_KEYWORD_END:
        case PM_TOKEN_KEYWORD_ELSE:
        case PM_TOKEN_KEYWORD_ELSIF:
        case PM_TOKEN_KEYWORD_ENSURE:
        case PM_TOKEN_KEYWORD_THEN:
        case PM_TOKEN_KEYWORD_RESCUE:
        case PM_TOKEN_KEYWORD_WHEN:
        case PM_TOKEN_NEWLINE:
        case PM_TOKEN_PARENTHESIS_RIGHT:
        case PM_TOKEN_SEMICOLON:
            // The reason we need this short-circuit is because we're using the
            // binding powers table to tell us if the subsequent token could
            // potentially be the start of an expression. If there _is_ a binding
            // power for one of these tokens, then we should remove it from this list
            // and let it be handled by the default case below.
            assert(pm_binding_powers[type].left == PM_BINDING_POWER_UNSET);
            return false;
        case PM_TOKEN_UAMPERSAND:
            // This is a special case because this unary operator cannot appear
            // as a general operator, it only appears in certain circumstances.
            return false;
        case PM_TOKEN_UCOLON_COLON:
        case PM_TOKEN_UMINUS:
        case PM_TOKEN_UMINUS_NUM:
        case PM_TOKEN_UPLUS:
        case PM_TOKEN_BANG:
        case PM_TOKEN_TILDE:
        case PM_TOKEN_UDOT_DOT:
        case PM_TOKEN_UDOT_DOT_DOT:
            // These unary tokens actually do have binding power associated with them
            // so that we can correctly place them into the precedence order. But we
            // want them to be marked as beginning an expression, so we need to
            // special case them here.
            return true;
        default:
            return pm_binding_powers[type].left == PM_BINDING_POWER_UNSET;
    }
}

/**
 * Parse an expression with the given binding power that may be optionally
 * prefixed by the * operator.
 */
static pm_node_t *
parse_starred_expression(pm_parser_t *parser, pm_binding_power_t binding_power, bool accepts_command_call, pm_diagnostic_id_t diag_id, uint16_t depth) {
    if (accept1(parser, PM_TOKEN_USTAR)) {
        pm_token_t operator = parser->previous;
        pm_node_t *expression = parse_value_expression(parser, binding_power, false, false, PM_ERR_EXPECT_EXPRESSION_AFTER_STAR, (uint16_t) (depth + 1));
        return (pm_node_t *) pm_splat_node_create(parser, &operator, expression);
    }

    return parse_value_expression(parser, binding_power, accepts_command_call, false, diag_id, depth);
}

/**
 * Convert the name of a method into the corresponding write method name. For
 * example, foo would be turned into foo=.
 */
static void
parse_write_name(pm_parser_t *parser, pm_constant_id_t *name_field) {
    // The method name needs to change. If we previously had
    // foo, we now need foo=. In this case we'll allocate a new
    // owned string, copy the previous method name in, and
    // append an =.
    pm_constant_t *constant = pm_constant_pool_id_to_constant(&parser->constant_pool, *name_field);
    size_t length = constant->length;
    uint8_t *name = xcalloc(length + 1, sizeof(uint8_t));
    if (name == NULL) return;

    memcpy(name, constant->start, length);
    name[length] = '=';

    // Now switch the name to the new string.
    // This silences clang analyzer warning about leak of memory pointed by `name`.
    // NOLINTNEXTLINE(clang-analyzer-*)
    *name_field = pm_constant_pool_insert_owned(&parser->constant_pool, name, length + 1);
}

/**
 * Certain expressions are not targetable, but in order to provide a better
 * experience we give a specific error message. In order to maintain as much
 * information in the tree as possible, we replace them with local variable
 * writes.
 */
static pm_node_t *
parse_unwriteable_target(pm_parser_t *parser, pm_node_t *target) {
    switch (PM_NODE_TYPE(target)) {
        case PM_SOURCE_ENCODING_NODE: pm_parser_err_node(parser, target, PM_ERR_EXPRESSION_NOT_WRITABLE_ENCODING); break;
        case PM_FALSE_NODE: pm_parser_err_node(parser, target, PM_ERR_EXPRESSION_NOT_WRITABLE_FALSE); break;
        case PM_SOURCE_FILE_NODE: pm_parser_err_node(parser, target, PM_ERR_EXPRESSION_NOT_WRITABLE_FILE); break;
        case PM_SOURCE_LINE_NODE: pm_parser_err_node(parser, target, PM_ERR_EXPRESSION_NOT_WRITABLE_LINE); break;
        case PM_NIL_NODE: pm_parser_err_node(parser, target, PM_ERR_EXPRESSION_NOT_WRITABLE_NIL); break;
        case PM_SELF_NODE: pm_parser_err_node(parser, target, PM_ERR_EXPRESSION_NOT_WRITABLE_SELF); break;
        case PM_TRUE_NODE: pm_parser_err_node(parser, target, PM_ERR_EXPRESSION_NOT_WRITABLE_TRUE); break;
        default: break;
    }

    pm_constant_id_t name = pm_parser_constant_id_location(parser, target->location.start, target->location.end);
    pm_local_variable_target_node_t *result = pm_local_variable_target_node_create(parser, &target->location, name, 0);

    pm_node_destroy(parser, target);
    return (pm_node_t *) result;
}

/**
 * When an implicit local variable is written to or targeted, it becomes a
 * regular, named local variable. This function removes it from the list of
 * implicit parameters when that happens.
 */
static void
parse_target_implicit_parameter(pm_parser_t *parser, pm_node_t *node) {
    pm_node_list_t *implicit_parameters = &parser->current_scope->implicit_parameters;

    for (size_t index = 0; index < implicit_parameters->size; index++) {
        if (implicit_parameters->nodes[index] == node) {
            // If the node is not the last one in the list, we need to shift the
            // remaining nodes down to fill the gap. This is extremely unlikely
            // to happen.
            if (index != implicit_parameters->size - 1) {
                memcpy(&implicit_parameters->nodes[index], &implicit_parameters->nodes[index + 1], (implicit_parameters->size - index - 1) * sizeof(pm_node_t *));
            }

            implicit_parameters->size--;
            break;
        }
    }
}

/**
 * Convert the given node into a valid target node.
 *
 * @param multiple Whether or not this target is part of a larger set of
 *   targets. If it is, then the &. operator is not allowed.
 * @param splat Whether or not this target is a child of a splat target. If it
 *   is, then fewer patterns are allowed.
 */
static pm_node_t *
parse_target(pm_parser_t *parser, pm_node_t *target, bool multiple, bool splat_parent) {
    switch (PM_NODE_TYPE(target)) {
        case PM_MISSING_NODE:
            return target;
        case PM_SOURCE_ENCODING_NODE:
        case PM_FALSE_NODE:
        case PM_SOURCE_FILE_NODE:
        case PM_SOURCE_LINE_NODE:
        case PM_NIL_NODE:
        case PM_SELF_NODE:
        case PM_TRUE_NODE: {
            // In these special cases, we have specific error messages and we
            // will replace them with local variable writes.
            return parse_unwriteable_target(parser, target);
        }
        case PM_CLASS_VARIABLE_READ_NODE:
            assert(sizeof(pm_class_variable_target_node_t) == sizeof(pm_class_variable_read_node_t));
            target->type = PM_CLASS_VARIABLE_TARGET_NODE;
            return target;
        case PM_CONSTANT_PATH_NODE:
            if (context_def_p(parser)) {
                pm_parser_err_node(parser, target, PM_ERR_WRITE_TARGET_IN_METHOD);
            }

            assert(sizeof(pm_constant_path_target_node_t) == sizeof(pm_constant_path_node_t));
            target->type = PM_CONSTANT_PATH_TARGET_NODE;

            return target;
        case PM_CONSTANT_READ_NODE:
            if (context_def_p(parser)) {
                pm_parser_err_node(parser, target, PM_ERR_WRITE_TARGET_IN_METHOD);
            }

            assert(sizeof(pm_constant_target_node_t) == sizeof(pm_constant_read_node_t));
            target->type = PM_CONSTANT_TARGET_NODE;

            return target;
        case PM_BACK_REFERENCE_READ_NODE:
        case PM_NUMBERED_REFERENCE_READ_NODE:
            PM_PARSER_ERR_NODE_FORMAT_CONTENT(parser, target, PM_ERR_WRITE_TARGET_READONLY);
            return target;
        case PM_GLOBAL_VARIABLE_READ_NODE:
            assert(sizeof(pm_global_variable_target_node_t) == sizeof(pm_global_variable_read_node_t));
            target->type = PM_GLOBAL_VARIABLE_TARGET_NODE;
            return target;
        case PM_LOCAL_VARIABLE_READ_NODE: {
            if (pm_token_is_numbered_parameter(target->location.start, target->location.end)) {
                PM_PARSER_ERR_FORMAT(parser, target->location.start, target->location.end, PM_ERR_PARAMETER_NUMBERED_RESERVED, target->location.start);
                parse_target_implicit_parameter(parser, target);
            }

            const pm_local_variable_read_node_t *cast = (const pm_local_variable_read_node_t *) target;
            uint32_t name = cast->name;
            uint32_t depth = cast->depth;
            pm_locals_unread(&pm_parser_scope_find(parser, depth)->locals, name);

            assert(sizeof(pm_local_variable_target_node_t) == sizeof(pm_local_variable_read_node_t));
            target->type = PM_LOCAL_VARIABLE_TARGET_NODE;

            return target;
        }
        case PM_IT_LOCAL_VARIABLE_READ_NODE: {
            pm_constant_id_t name = pm_parser_local_add_constant(parser, "it", 2);
            pm_node_t *node = (pm_node_t *) pm_local_variable_target_node_create(parser, &target->location, name, 0);

            parse_target_implicit_parameter(parser, target);
            pm_node_destroy(parser, target);

            return node;
        }
        case PM_INSTANCE_VARIABLE_READ_NODE:
            assert(sizeof(pm_instance_variable_target_node_t) == sizeof(pm_instance_variable_read_node_t));
            target->type = PM_INSTANCE_VARIABLE_TARGET_NODE;
            return target;
        case PM_MULTI_TARGET_NODE:
            if (splat_parent) {
                // Multi target is not accepted in all positions. If this is one
                // of them, then we need to add an error.
                pm_parser_err_node(parser, target, PM_ERR_WRITE_TARGET_UNEXPECTED);
            }

            return target;
        case PM_SPLAT_NODE: {
            pm_splat_node_t *splat = (pm_splat_node_t *) target;

            if (splat->expression != NULL) {
                splat->expression = parse_target(parser, splat->expression, multiple, true);
            }

            return (pm_node_t *) splat;
        }
        case PM_CALL_NODE: {
            pm_call_node_t *call = (pm_call_node_t *) target;

            // If we have no arguments to the call node and we need this to be a
            // target then this is either a method call or a local variable
            // write.
            if (
                (call->message_loc.start != NULL) &&
                (call->message_loc.end[-1] != '!') &&
                (call->message_loc.end[-1] != '?') &&
                (call->opening_loc.start == NULL) &&
                (call->arguments == NULL) &&
                (call->block == NULL)
            ) {
                if (call->receiver == NULL) {
                    // When we get here, we have a local variable write, because it
                    // was previously marked as a method call but now we have an =.
                    // This looks like:
                    //
                    //     foo = 1
                    //
                    // When it was parsed in the prefix position, foo was seen as a
                    // method call with no receiver and no arguments. Now we have an
                    // =, so we know it's a local variable write.
                    const pm_location_t message_loc = call->message_loc;

                    pm_constant_id_t name = pm_parser_local_add_location(parser, message_loc.start, message_loc.end, 0);
                    pm_node_destroy(parser, target);

                    return (pm_node_t *) pm_local_variable_target_node_create(parser, &message_loc, name, 0);
                }

                if (*call->message_loc.start == '_' || parser->encoding->alnum_char(call->message_loc.start, call->message_loc.end - call->message_loc.start)) {
                    if (multiple && PM_NODE_FLAG_P(call, PM_CALL_NODE_FLAGS_SAFE_NAVIGATION)) {
                        pm_parser_err_node(parser, (const pm_node_t *) call, PM_ERR_UNEXPECTED_SAFE_NAVIGATION);
                    }

                    parse_write_name(parser, &call->name);
                    return (pm_node_t *) pm_call_target_node_create(parser, call);
                }
            }

            // If there is no call operator and the message is "[]" then this is
            // an aref expression, and we can transform it into an aset
            // expression.
            if (PM_NODE_FLAG_P(call, PM_CALL_NODE_FLAGS_INDEX)) {
                return (pm_node_t *) pm_index_target_node_create(parser, call);
            }
        }
        PRISM_FALLTHROUGH
        default:
            // In this case we have a node that we don't know how to convert
            // into a target. We need to treat it as an error. For now, we'll
            // mark it as an error and just skip right past it.
            pm_parser_err_node(parser, target, PM_ERR_WRITE_TARGET_UNEXPECTED);
            return target;
    }
}

/**
 * Parse a write target and validate that it is in a valid position for
 * assignment.
 */
static pm_node_t *
parse_target_validate(pm_parser_t *parser, pm_node_t *target, bool multiple) {
    pm_node_t *result = parse_target(parser, target, multiple, false);

    // Ensure that we have one of an =, an 'in' in for indexes, and a ')' in
    // parens after the targets.
    if (
        !match1(parser, PM_TOKEN_EQUAL) &&
        !(context_p(parser, PM_CONTEXT_FOR_INDEX) && match1(parser, PM_TOKEN_KEYWORD_IN)) &&
        !(context_p(parser, PM_CONTEXT_PARENS) && match1(parser, PM_TOKEN_PARENTHESIS_RIGHT))
    ) {
        pm_parser_err_node(parser, result, PM_ERR_WRITE_TARGET_UNEXPECTED);
    }

    return result;
}

/**
 * Potentially wrap a constant write node in a shareable constant node depending
 * on the current state.
 */
static pm_node_t *
parse_shareable_constant_write(pm_parser_t *parser, pm_node_t *write) {
    pm_shareable_constant_value_t shareable_constant = pm_parser_scope_shareable_constant_get(parser);

    if (shareable_constant != PM_SCOPE_SHAREABLE_CONSTANT_NONE) {
        return (pm_node_t *) pm_shareable_constant_node_create(parser, write, shareable_constant);
    }

    return write;
}

/**
 * Convert the given node into a valid write node.
 */
static pm_node_t *
parse_write(pm_parser_t *parser, pm_node_t *target, pm_token_t *operator, pm_node_t *value) {
    switch (PM_NODE_TYPE(target)) {
        case PM_MISSING_NODE:
            pm_node_destroy(parser, value);
            return target;
        case PM_CLASS_VARIABLE_READ_NODE: {
            pm_class_variable_write_node_t *node = pm_class_variable_write_node_create(parser, (pm_class_variable_read_node_t *) target, operator, value);
            pm_node_destroy(parser, target);
            return (pm_node_t *) node;
        }
        case PM_CONSTANT_PATH_NODE: {
            pm_node_t *node = (pm_node_t *) pm_constant_path_write_node_create(parser, (pm_constant_path_node_t *) target, operator, value);

            if (context_def_p(parser)) {
                pm_parser_err_node(parser, node, PM_ERR_WRITE_TARGET_IN_METHOD);
            }

            return parse_shareable_constant_write(parser, node);
        }
        case PM_CONSTANT_READ_NODE: {
            pm_node_t *node = (pm_node_t *) pm_constant_write_node_create(parser, (pm_constant_read_node_t *) target, operator, value);

            if (context_def_p(parser)) {
                pm_parser_err_node(parser, node, PM_ERR_WRITE_TARGET_IN_METHOD);
            }

            pm_node_destroy(parser, target);
            return parse_shareable_constant_write(parser, node);
        }
        case PM_BACK_REFERENCE_READ_NODE:
        case PM_NUMBERED_REFERENCE_READ_NODE:
            PM_PARSER_ERR_NODE_FORMAT_CONTENT(parser, target, PM_ERR_WRITE_TARGET_READONLY);
            PRISM_FALLTHROUGH
        case PM_GLOBAL_VARIABLE_READ_NODE: {
            pm_global_variable_write_node_t *node = pm_global_variable_write_node_create(parser, target, operator, value);
            pm_node_destroy(parser, target);
            return (pm_node_t *) node;
        }
        case PM_LOCAL_VARIABLE_READ_NODE: {
            pm_local_variable_read_node_t *local_read = (pm_local_variable_read_node_t *) target;

            pm_constant_id_t name = local_read->name;
            pm_location_t name_loc = target->location;

            uint32_t depth = local_read->depth;
            pm_scope_t *scope = pm_parser_scope_find(parser, depth);

            if (pm_token_is_numbered_parameter(target->location.start, target->location.end)) {
                pm_diagnostic_id_t diag_id = (scope->parameters & PM_SCOPE_PARAMETERS_NUMBERED_FOUND) ? PM_ERR_EXPRESSION_NOT_WRITABLE_NUMBERED : PM_ERR_PARAMETER_NUMBERED_RESERVED;
                PM_PARSER_ERR_FORMAT(parser, target->location.start, target->location.end, diag_id, target->location.start);
                parse_target_implicit_parameter(parser, target);
            }

            pm_locals_unread(&scope->locals, name);
            pm_node_destroy(parser, target);

            return (pm_node_t *) pm_local_variable_write_node_create(parser, name, depth, value, &name_loc, operator);
        }
        case PM_IT_LOCAL_VARIABLE_READ_NODE: {
            pm_constant_id_t name = pm_parser_local_add_constant(parser, "it", 2);
            pm_node_t *node = (pm_node_t *) pm_local_variable_write_node_create(parser, name, 0, value, &target->location, operator);

            parse_target_implicit_parameter(parser, target);
            pm_node_destroy(parser, target);

            return node;
        }
        case PM_INSTANCE_VARIABLE_READ_NODE: {
            pm_node_t *write_node = (pm_node_t *) pm_instance_variable_write_node_create(parser, (pm_instance_variable_read_node_t *) target, operator, value);
            pm_node_destroy(parser, target);
            return write_node;
        }
        case PM_MULTI_TARGET_NODE:
            return (pm_node_t *) pm_multi_write_node_create(parser, (pm_multi_target_node_t *) target, operator, value);
        case PM_SPLAT_NODE: {
            pm_splat_node_t *splat = (pm_splat_node_t *) target;

            if (splat->expression != NULL) {
                splat->expression = parse_write(parser, splat->expression, operator, value);
            }

            pm_multi_target_node_t *multi_target = pm_multi_target_node_create(parser);
            pm_multi_target_node_targets_append(parser, multi_target, (pm_node_t *) splat);

            return (pm_node_t *) pm_multi_write_node_create(parser, multi_target, operator, value);
        }
        case PM_CALL_NODE: {
            pm_call_node_t *call = (pm_call_node_t *) target;

            // If we have no arguments to the call node and we need this to be a
            // target then this is either a method call or a local variable
            // write.
            if (
                (call->message_loc.start != NULL) &&
                (call->message_loc.end[-1] != '!') &&
                (call->message_loc.end[-1] != '?') &&
                (call->opening_loc.start == NULL) &&
                (call->arguments == NULL) &&
                (call->block == NULL)
            ) {
                if (call->receiver == NULL) {
                    // When we get here, we have a local variable write, because it
                    // was previously marked as a method call but now we have an =.
                    // This looks like:
                    //
                    //     foo = 1
                    //
                    // When it was parsed in the prefix position, foo was seen as a
                    // method call with no receiver and no arguments. Now we have an
                    // =, so we know it's a local variable write.
                    const pm_location_t message = call->message_loc;

                    pm_parser_local_add_location(parser, message.start, message.end, 0);
                    pm_node_destroy(parser, target);

                    pm_constant_id_t constant_id = pm_parser_constant_id_location(parser, message.start, message.end);
                    target = (pm_node_t *) pm_local_variable_write_node_create(parser, constant_id, 0, value, &message, operator);

                    pm_refute_numbered_parameter(parser, message.start, message.end);
                    return target;
                }

                if (char_is_identifier_start(parser, call->message_loc.start, parser->end - call->message_loc.start)) {
                    // When we get here, we have a method call, because it was
                    // previously marked as a method call but now we have an =. This
                    // looks like:
                    //
                    //     foo.bar = 1
                    //
                    // When it was parsed in the prefix position, foo.bar was seen as a
                    // method call with no arguments. Now we have an =, so we know it's
                    // a method call with an argument. In this case we will create the
                    // arguments node, parse the argument, and add it to the list.
                    pm_arguments_node_t *arguments = pm_arguments_node_create(parser);
                    call->arguments = arguments;

                    pm_arguments_node_arguments_append(arguments, value);
                    call->base.location.end = arguments->base.location.end;

                    parse_write_name(parser, &call->name);
                    pm_node_flag_set((pm_node_t *) call, PM_CALL_NODE_FLAGS_ATTRIBUTE_WRITE | pm_implicit_array_write_flags(value, PM_CALL_NODE_FLAGS_IMPLICIT_ARRAY));

                    return (pm_node_t *) call;
                }
            }

            // If there is no call operator and the message is "[]" then this is
            // an aref expression, and we can transform it into an aset
            // expression.
            if (PM_NODE_FLAG_P(call, PM_CALL_NODE_FLAGS_INDEX)) {
                if (call->arguments == NULL) {
                    call->arguments = pm_arguments_node_create(parser);
                }

                pm_arguments_node_arguments_append(call->arguments, value);
                target->location.end = value->location.end;

                // Replace the name with "[]=".
                call->name = pm_parser_constant_id_constant(parser, "[]=", 3);

                // Ensure that the arguments for []= don't contain keywords
                pm_index_arguments_check(parser, call->arguments, call->block);
                pm_node_flag_set((pm_node_t *) call, PM_CALL_NODE_FLAGS_ATTRIBUTE_WRITE | pm_implicit_array_write_flags(value, PM_CALL_NODE_FLAGS_IMPLICIT_ARRAY));

                return target;
            }

            // If there are arguments on the call node, then it can't be a method
            // call ending with = or a local variable write, so it must be a
            // syntax error. In this case we'll fall through to our default
            // handling. We need to free the value that we parsed because there
            // is no way for us to attach it to the tree at this point.
            pm_node_destroy(parser, value);
        }
        PRISM_FALLTHROUGH
        default:
            // In this case we have a node that we don't know how to convert into a
            // target. We need to treat it as an error. For now, we'll mark it as an
            // error and just skip right past it.
            pm_parser_err_token(parser, operator, PM_ERR_WRITE_TARGET_UNEXPECTED);
            return target;
    }
}

/**
 * Certain expressions are not writable, but in order to provide a better
 * experience we give a specific error message. In order to maintain as much
 * information in the tree as possible, we replace them with local variable
 * writes.
 */
static pm_node_t *
parse_unwriteable_write(pm_parser_t *parser, pm_node_t *target, const pm_token_t *equals, pm_node_t *value) {
    switch (PM_NODE_TYPE(target)) {
        case PM_SOURCE_ENCODING_NODE: pm_parser_err_token(parser, equals, PM_ERR_EXPRESSION_NOT_WRITABLE_ENCODING); break;
        case PM_FALSE_NODE: pm_parser_err_token(parser, equals, PM_ERR_EXPRESSION_NOT_WRITABLE_FALSE); break;
        case PM_SOURCE_FILE_NODE: pm_parser_err_token(parser, equals, PM_ERR_EXPRESSION_NOT_WRITABLE_FILE); break;
        case PM_SOURCE_LINE_NODE: pm_parser_err_token(parser, equals, PM_ERR_EXPRESSION_NOT_WRITABLE_LINE); break;
        case PM_NIL_NODE: pm_parser_err_token(parser, equals, PM_ERR_EXPRESSION_NOT_WRITABLE_NIL); break;
        case PM_SELF_NODE: pm_parser_err_token(parser, equals, PM_ERR_EXPRESSION_NOT_WRITABLE_SELF); break;
        case PM_TRUE_NODE: pm_parser_err_token(parser, equals, PM_ERR_EXPRESSION_NOT_WRITABLE_TRUE); break;
        default: break;
    }

    pm_constant_id_t name = pm_parser_local_add_location(parser, target->location.start, target->location.end, 1);
    pm_local_variable_write_node_t *result = pm_local_variable_write_node_create(parser, name, 0, value, &target->location, equals);

    pm_node_destroy(parser, target);
    return (pm_node_t *) result;
}

/**
 * Parse a list of targets for assignment. This is used in the case of a for
 * loop or a multi-assignment. For example, in the following code:
 *
 *     for foo, bar in baz
 *         ^^^^^^^^
 *
 * The targets are `foo` and `bar`. This function will either return a single
 * target node or a multi-target node.
 */
static pm_node_t *
parse_targets(pm_parser_t *parser, pm_node_t *first_target, pm_binding_power_t binding_power, uint16_t depth) {
    bool has_rest = PM_NODE_TYPE_P(first_target, PM_SPLAT_NODE);

    pm_multi_target_node_t *result = pm_multi_target_node_create(parser);
    pm_multi_target_node_targets_append(parser, result, parse_target(parser, first_target, true, false));

    while (accept1(parser, PM_TOKEN_COMMA)) {
        if (accept1(parser, PM_TOKEN_USTAR)) {
            // Here we have a splat operator. It can have a name or be
            // anonymous. It can be the final target or be in the middle if
            // there haven't been any others yet.
            if (has_rest) {
                pm_parser_err_previous(parser, PM_ERR_MULTI_ASSIGN_MULTI_SPLATS);
            }

            pm_token_t star_operator = parser->previous;
            pm_node_t *name = NULL;

            if (token_begins_expression_p(parser->current.type)) {
                name = parse_expression(parser, binding_power, false, false, PM_ERR_EXPECT_EXPRESSION_AFTER_STAR, (uint16_t) (depth + 1));
                name = parse_target(parser, name, true, true);
            }

            pm_node_t *splat = (pm_node_t *) pm_splat_node_create(parser, &star_operator, name);
            pm_multi_target_node_targets_append(parser, result, splat);
            has_rest = true;
        } else if (match1(parser, PM_TOKEN_PARENTHESIS_LEFT)) {
            context_push(parser, PM_CONTEXT_MULTI_TARGET);
            pm_node_t *target = parse_expression(parser, binding_power, false, false, PM_ERR_EXPECT_EXPRESSION_AFTER_COMMA, (uint16_t) (depth + 1));
            target = parse_target(parser, target, true, false);

            pm_multi_target_node_targets_append(parser, result, target);
            context_pop(parser);
        } else if (token_begins_expression_p(parser->current.type)) {
            pm_node_t *target = parse_expression(parser, binding_power, false, false, PM_ERR_EXPECT_EXPRESSION_AFTER_COMMA, (uint16_t) (depth + 1));
            target = parse_target(parser, target, true, false);

            pm_multi_target_node_targets_append(parser, result, target);
        } else if (!match1(parser, PM_TOKEN_EOF)) {
            // If we get here, then we have a trailing , in a multi target node.
            // We'll add an implicit rest node to represent this.
            pm_node_t *rest = (pm_node_t *) pm_implicit_rest_node_create(parser, &parser->previous);
            pm_multi_target_node_targets_append(parser, result, rest);
            break;
        }
    }

    return (pm_node_t *) result;
}

/**
 * Parse a list of targets and validate that it is in a valid position for
 * assignment.
 */
static pm_node_t *
parse_targets_validate(pm_parser_t *parser, pm_node_t *first_target, pm_binding_power_t binding_power, uint16_t depth) {
    pm_node_t *result = parse_targets(parser, first_target, binding_power, depth);
    accept1(parser, PM_TOKEN_NEWLINE);

    // Ensure that we have either an = or a ) after the targets.
    if (!match2(parser, PM_TOKEN_EQUAL, PM_TOKEN_PARENTHESIS_RIGHT)) {
        pm_parser_err_node(parser, result, PM_ERR_WRITE_TARGET_UNEXPECTED);
    }

    return result;
}

/**
 * Parse a list of statements separated by newlines or semicolons.
 */
static pm_statements_node_t *
parse_statements(pm_parser_t *parser, pm_context_t context, uint16_t depth) {
    // First, skip past any optional terminators that might be at the beginning
    // of the statements.
    while (accept2(parser, PM_TOKEN_SEMICOLON, PM_TOKEN_NEWLINE));

    // If we have a terminator, then we can just return NULL.
    if (context_terminator(context, &parser->current)) return NULL;

    pm_statements_node_t *statements = pm_statements_node_create(parser);

    // At this point we know we have at least one statement, and that it
    // immediately follows the current token.
    context_push(parser, context);

    while (true) {
        pm_node_t *node = parse_expression(parser, PM_BINDING_POWER_STATEMENT, true, false, PM_ERR_CANNOT_PARSE_EXPRESSION, (uint16_t) (depth + 1));
        pm_statements_node_body_append(parser, statements, node, true);

        // If we're recovering from a syntax error, then we need to stop parsing
        // the statements now.
        if (parser->recovering) {
            // If this is the level of context where the recovery has happened,
            // then we can mark the parser as done recovering.
            if (context_terminator(context, &parser->current)) parser->recovering = false;
            break;
        }

        // If we have a terminator, then we will parse all consecutive
        // terminators and then continue parsing the statements list.
        if (accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON)) {
            // If we have a terminator, then we will continue parsing the
            // statements list.
            while (accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON));
            if (context_terminator(context, &parser->current)) break;

            // Now we can continue parsing the list of statements.
            continue;
        }

        // At this point we have a list of statements that are not terminated by
        // a newline or semicolon. At this point we need to check if we're at
        // the end of the statements list. If we are, then we should break out
        // of the loop.
        if (context_terminator(context, &parser->current)) break;

        // At this point, we have a syntax error, because the statement was not
        // terminated by a newline or semicolon, and we're not at the end of the
        // statements list. Ideally we should scan forward to determine if we
        // should insert a missing terminator or break out of parsing the
        // statements list at this point.
        //
        // We don't have that yet, so instead we'll do a more naive approach. If
        // we were unable to parse an expression, then we will skip past this
        // token and continue parsing the statements list. Otherwise we'll add
        // an error and continue parsing the statements list.
        if (PM_NODE_TYPE_P(node, PM_MISSING_NODE)) {
            parser_lex(parser);

            // If we are at the end of the file, then we need to stop parsing
            // the statements entirely at this point. Mark the parser as
            // recovering, as we know that EOF closes the top-level context, and
            // then break out of the loop.
            if (match1(parser, PM_TOKEN_EOF)) {
                parser->recovering = true;
                break;
            }

            while (accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON));
            if (context_terminator(context, &parser->current)) break;
        } else if (!accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_EOF)) {
            // This is an inlined version of accept1 because the error that we
            // want to add has varargs. If this happens again, we should
            // probably extract a helper function.
            PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_EXPECT_EOL_AFTER_STATEMENT, pm_token_type_human(parser->current.type));
            parser->previous.start = parser->previous.end;
            parser->previous.type = PM_TOKEN_MISSING;
        }
    }

    context_pop(parser);
    bool last_value = true;
    switch (context) {
        case PM_CONTEXT_BEGIN_ENSURE:
        case PM_CONTEXT_DEF_ENSURE:
            last_value = false;
            break;
        default:
            break;
    }
    pm_void_statements_check(parser, statements, last_value);

    return statements;
}

/**
 * Add a node to a set of static literals that holds a set of hash keys. If the
 * node is a duplicate, then add an appropriate warning.
 */
static void
pm_hash_key_static_literals_add(pm_parser_t *parser, pm_static_literals_t *literals, pm_node_t *node) {
    const pm_node_t *duplicated = pm_static_literals_add(&parser->newline_list, parser->start_line, literals, node, true);

    if (duplicated != NULL) {
        pm_buffer_t buffer = { 0 };
        pm_static_literal_inspect(&buffer, &parser->newline_list, parser->start_line, parser->encoding->name, duplicated);

        pm_diagnostic_list_append_format(
            &parser->warning_list,
            duplicated->location.start,
            duplicated->location.end,
            PM_WARN_DUPLICATED_HASH_KEY,
            (int) pm_buffer_length(&buffer),
            pm_buffer_value(&buffer),
            pm_newline_list_line_column(&parser->newline_list, node->location.start, parser->start_line).line
        );

        pm_buffer_free(&buffer);
    }
}

/**
 * Add a node to a set of static literals that holds a set of hash keys. If the
 * node is a duplicate, then add an appropriate warning.
 */
static void
pm_when_clause_static_literals_add(pm_parser_t *parser, pm_static_literals_t *literals, pm_node_t *node) {
    pm_node_t *previous;

    if ((previous = pm_static_literals_add(&parser->newline_list, parser->start_line, literals, node, false)) != NULL) {
        pm_diagnostic_list_append_format(
            &parser->warning_list,
            node->location.start,
            node->location.end,
            PM_WARN_DUPLICATED_WHEN_CLAUSE,
            pm_newline_list_line_column(&parser->newline_list, node->location.start, parser->start_line).line,
            pm_newline_list_line_column(&parser->newline_list, previous->location.start, parser->start_line).line
        );
    }
}

/**
 * Parse all of the elements of a hash. Return true if a double splat was found.
 */
static bool
parse_assocs(pm_parser_t *parser, pm_static_literals_t *literals, pm_node_t *node, uint16_t depth) {
    assert(PM_NODE_TYPE_P(node, PM_HASH_NODE) || PM_NODE_TYPE_P(node, PM_KEYWORD_HASH_NODE));
    bool contains_keyword_splat = false;

    while (true) {
        pm_node_t *element;

        switch (parser->current.type) {
            case PM_TOKEN_USTAR_STAR: {
                parser_lex(parser);
                pm_token_t operator = parser->previous;
                pm_node_t *value = NULL;

                if (match1(parser, PM_TOKEN_BRACE_LEFT)) {
                    // If we're about to parse a nested hash that is being
                    // pushed into this hash directly with **, then we want the
                    // inner hash to share the static literals with the outer
                    // hash.
                    parser->current_hash_keys = literals;
                    value = parse_value_expression(parser, PM_BINDING_POWER_DEFINED, false, false, PM_ERR_EXPECT_EXPRESSION_AFTER_SPLAT_HASH, (uint16_t) (depth + 1));
                } else if (token_begins_expression_p(parser->current.type)) {
                    value = parse_value_expression(parser, PM_BINDING_POWER_DEFINED, false, false, PM_ERR_EXPECT_EXPRESSION_AFTER_SPLAT_HASH, (uint16_t) (depth + 1));
                } else {
                    pm_parser_scope_forwarding_keywords_check(parser, &operator);
                }

                element = (pm_node_t *) pm_assoc_splat_node_create(parser, value, &operator);
                contains_keyword_splat = true;
                break;
            }
            case PM_TOKEN_LABEL: {
                pm_token_t label = parser->current;
                parser_lex(parser);

                pm_node_t *key = (pm_node_t *) pm_symbol_node_label_create(parser, &label);
                pm_hash_key_static_literals_add(parser, literals, key);

                pm_token_t operator = not_provided(parser);
                pm_node_t *value = NULL;

                if (token_begins_expression_p(parser->current.type)) {
                    value = parse_value_expression(parser, PM_BINDING_POWER_DEFINED, false, false, PM_ERR_HASH_EXPRESSION_AFTER_LABEL, (uint16_t) (depth + 1));
                } else {
                    if (parser->encoding->isupper_char(label.start, (label.end - 1) - label.start)) {
                        pm_token_t constant = { .type = PM_TOKEN_CONSTANT, .start = label.start, .end = label.end - 1 };
                        value = (pm_node_t *) pm_constant_read_node_create(parser, &constant);
                    } else {
                        int depth = -1;
                        pm_token_t identifier = { .type = PM_TOKEN_IDENTIFIER, .start = label.start, .end = label.end - 1 };

                        if (identifier.end[-1] == '!' || identifier.end[-1] == '?') {
                            PM_PARSER_ERR_TOKEN_FORMAT_CONTENT(parser, identifier, PM_ERR_INVALID_LOCAL_VARIABLE_READ);
                        } else {
                            depth = pm_parser_local_depth(parser, &identifier);
                        }

                        if (depth == -1) {
                            value = (pm_node_t *) pm_call_node_variable_call_create(parser, &identifier);
                        } else {
                            value = (pm_node_t *) pm_local_variable_read_node_create(parser, &identifier, (uint32_t) depth);
                        }
                    }

                    value->location.end++;
                    value = (pm_node_t *) pm_implicit_node_create(parser, value);
                }

                element = (pm_node_t *) pm_assoc_node_create(parser, key, &operator, value);
                break;
            }
            default: {
                pm_node_t *key = parse_value_expression(parser, PM_BINDING_POWER_DEFINED, false, true, PM_ERR_HASH_KEY, (uint16_t) (depth + 1));

                // Hash keys that are strings are automatically frozen. We will
                // mark that here.
                if (PM_NODE_TYPE_P(key, PM_STRING_NODE)) {
                    pm_node_flag_set(key, PM_STRING_FLAGS_FROZEN | PM_NODE_FLAG_STATIC_LITERAL);
                }

                pm_hash_key_static_literals_add(parser, literals, key);

                pm_token_t operator;
                if (pm_symbol_node_label_p(key)) {
                    operator = not_provided(parser);
                } else {
                    expect1(parser, PM_TOKEN_EQUAL_GREATER, PM_ERR_HASH_ROCKET);
                    operator = parser->previous;
                }

                pm_node_t *value = parse_value_expression(parser, PM_BINDING_POWER_DEFINED, false, false, PM_ERR_HASH_VALUE, (uint16_t) (depth + 1));
                element = (pm_node_t *) pm_assoc_node_create(parser, key, &operator, value);
                break;
            }
        }

        if (PM_NODE_TYPE_P(node, PM_HASH_NODE)) {
            pm_hash_node_elements_append((pm_hash_node_t *) node, element);
        } else {
            pm_keyword_hash_node_elements_append((pm_keyword_hash_node_t *) node, element);
        }

        // If there's no comma after the element, then we're done.
        if (!accept1(parser, PM_TOKEN_COMMA)) break;

        // If the next element starts with a label or a **, then we know we have
        // another element in the hash, so we'll continue parsing.
        if (match2(parser, PM_TOKEN_USTAR_STAR, PM_TOKEN_LABEL)) continue;

        // Otherwise we need to check if the subsequent token begins an expression.
        // If it does, then we'll continue parsing.
        if (token_begins_expression_p(parser->current.type)) continue;

        // Otherwise by default we will exit out of this loop.
        break;
    }

    return contains_keyword_splat;
}

/**
 * Append an argument to a list of arguments.
 */
static inline void
parse_arguments_append(pm_parser_t *parser, pm_arguments_t *arguments, pm_node_t *argument) {
    if (arguments->arguments == NULL) {
        arguments->arguments = pm_arguments_node_create(parser);
    }

    pm_arguments_node_arguments_append(arguments->arguments, argument);
}

/**
 * Parse a list of arguments.
 */
static void
parse_arguments(pm_parser_t *parser, pm_arguments_t *arguments, bool accepts_forwarding, pm_token_type_t terminator, uint16_t depth) {
    pm_binding_power_t binding_power = pm_binding_powers[parser->current.type].left;

    // First we need to check if the next token is one that could be the start
    // of an argument. If it's not, then we can just return.
    if (
        match2(parser, terminator, PM_TOKEN_EOF) ||
        (binding_power != PM_BINDING_POWER_UNSET && binding_power < PM_BINDING_POWER_RANGE) ||
        context_terminator(parser->current_context->context, &parser->current)
    ) {
        return;
    }

    bool parsed_first_argument = false;
    bool parsed_bare_hash = false;
    bool parsed_block_argument = false;
    bool parsed_forwarding_arguments = false;

    while (!match1(parser, PM_TOKEN_EOF)) {
        if (parsed_forwarding_arguments) {
            pm_parser_err_current(parser, PM_ERR_ARGUMENT_AFTER_FORWARDING_ELLIPSES);
        }

        pm_node_t *argument = NULL;

        switch (parser->current.type) {
            case PM_TOKEN_USTAR_STAR:
            case PM_TOKEN_LABEL: {
                if (parsed_bare_hash) {
                    pm_parser_err_current(parser, PM_ERR_ARGUMENT_BARE_HASH);
                }

                pm_keyword_hash_node_t *hash = pm_keyword_hash_node_create(parser);
                argument = (pm_node_t *) hash;

                pm_static_literals_t hash_keys = { 0 };
                bool contains_keyword_splat = parse_assocs(parser, &hash_keys, (pm_node_t *) hash, (uint16_t) (depth + 1));

                parse_arguments_append(parser, arguments, argument);

                pm_node_flags_t flags = PM_ARGUMENTS_NODE_FLAGS_CONTAINS_KEYWORDS;
                if (contains_keyword_splat) flags |= PM_ARGUMENTS_NODE_FLAGS_CONTAINS_KEYWORD_SPLAT;
                pm_node_flag_set((pm_node_t *) arguments->arguments, flags);

                pm_static_literals_free(&hash_keys);
                parsed_bare_hash = true;

                break;
            }
            case PM_TOKEN_UAMPERSAND: {
                parser_lex(parser);
                pm_token_t operator = parser->previous;
                pm_node_t *expression = NULL;

                if (token_begins_expression_p(parser->current.type)) {
                    expression = parse_value_expression(parser, PM_BINDING_POWER_DEFINED, false, false, PM_ERR_EXPECT_ARGUMENT, (uint16_t) (depth + 1));
                } else {
                    pm_parser_scope_forwarding_block_check(parser, &operator);
                }

                argument = (pm_node_t *) pm_block_argument_node_create(parser, &operator, expression);
                if (parsed_block_argument) {
                    parse_arguments_append(parser, arguments, argument);
                } else {
                    arguments->block = argument;
                }

                if (match1(parser, PM_TOKEN_COMMA)) {
                    pm_parser_err_current(parser, PM_ERR_ARGUMENT_AFTER_BLOCK);
                }

                parsed_block_argument = true;
                break;
            }
            case PM_TOKEN_USTAR: {
                parser_lex(parser);
                pm_token_t operator = parser->previous;

                if (match4(parser, PM_TOKEN_PARENTHESIS_RIGHT, PM_TOKEN_COMMA, PM_TOKEN_SEMICOLON, PM_TOKEN_BRACKET_RIGHT)) {
                    pm_parser_scope_forwarding_positionals_check(parser, &operator);
                    argument = (pm_node_t *) pm_splat_node_create(parser, &operator, NULL);
                    if (parsed_bare_hash) {
                        pm_parser_err_previous(parser, PM_ERR_ARGUMENT_SPLAT_AFTER_ASSOC_SPLAT);
                    }
                } else {
                    pm_node_t *expression = parse_value_expression(parser, PM_BINDING_POWER_DEFINED, false, false, PM_ERR_EXPECT_EXPRESSION_AFTER_SPLAT, (uint16_t) (depth + 1));

                    if (parsed_bare_hash) {
                        pm_parser_err(parser, operator.start, expression->location.end, PM_ERR_ARGUMENT_SPLAT_AFTER_ASSOC_SPLAT);
                    }

                    argument = (pm_node_t *) pm_splat_node_create(parser, &operator, expression);
                }

                parse_arguments_append(parser, arguments, argument);
                break;
            }
            case PM_TOKEN_UDOT_DOT_DOT: {
                if (accepts_forwarding) {
                    parser_lex(parser);

                    if (token_begins_expression_p(parser->current.type)) {
                        // If the token begins an expression then this ... was
                        // not actually argument forwarding but was instead a
                        // range.
                        pm_token_t operator = parser->previous;
                        pm_node_t *right = parse_expression(parser, PM_BINDING_POWER_RANGE, false, false, PM_ERR_EXPECT_EXPRESSION_AFTER_OPERATOR, (uint16_t) (depth + 1));

                        // If we parse a range, we need to validate that we
                        // didn't accidentally violate the nonassoc rules of the
                        // ... operator.
                        if (PM_NODE_TYPE_P(right, PM_RANGE_NODE)) {
                            pm_range_node_t *range = (pm_range_node_t *) right;
                            pm_parser_err(parser, range->operator_loc.start, range->operator_loc.end, PM_ERR_UNEXPECTED_RANGE_OPERATOR);
                        }

                        argument = (pm_node_t *) pm_range_node_create(parser, NULL, &operator, right);
                    } else {
                        pm_parser_scope_forwarding_all_check(parser, &parser->previous);
                        if (parsed_first_argument && terminator == PM_TOKEN_EOF) {
                            pm_parser_err_previous(parser, PM_ERR_ARGUMENT_FORWARDING_UNBOUND);
                        }

                        argument = (pm_node_t *) pm_forwarding_arguments_node_create(parser, &parser->previous);
                        parse_arguments_append(parser, arguments, argument);
                        pm_node_flag_set((pm_node_t *) arguments->arguments, PM_ARGUMENTS_NODE_FLAGS_CONTAINS_FORWARDING);
                        arguments->has_forwarding = true;
                        parsed_forwarding_arguments = true;
                        break;
                    }
                }
            }
            PRISM_FALLTHROUGH
            default: {
                if (argument == NULL) {
                    argument = parse_value_expression(parser, PM_BINDING_POWER_DEFINED, !parsed_first_argument, true, PM_ERR_EXPECT_ARGUMENT, (uint16_t) (depth + 1));
                }

                bool contains_keywords = false;
                bool contains_keyword_splat = false;

                if (pm_symbol_node_label_p(argument) || accept1(parser, PM_TOKEN_EQUAL_GREATER)) {
                    if (parsed_bare_hash) {
                        pm_parser_err_previous(parser, PM_ERR_ARGUMENT_BARE_HASH);
                    }

                    pm_token_t operator;
                    if (parser->previous.type == PM_TOKEN_EQUAL_GREATER) {
                        operator = parser->previous;
                    } else {
                        operator = not_provided(parser);
                    }

                    pm_keyword_hash_node_t *bare_hash = pm_keyword_hash_node_create(parser);
                    contains_keywords = true;

                    // Create the set of static literals for this hash.
                    pm_static_literals_t hash_keys = { 0 };
                    pm_hash_key_static_literals_add(parser, &hash_keys, argument);

                    // Finish parsing the one we are part way through.
                    pm_node_t *value = parse_value_expression(parser, PM_BINDING_POWER_DEFINED, false, false, PM_ERR_HASH_VALUE, (uint16_t) (depth + 1));
                    argument = (pm_node_t *) pm_assoc_node_create(parser, argument, &operator, value);

                    pm_keyword_hash_node_elements_append(bare_hash, argument);
                    argument = (pm_node_t *) bare_hash;

                    // Then parse more if we have a comma
                    if (accept1(parser, PM_TOKEN_COMMA) && (
                        token_begins_expression_p(parser->current.type) ||
                        match2(parser, PM_TOKEN_USTAR_STAR, PM_TOKEN_LABEL)
                    )) {
                        contains_keyword_splat = parse_assocs(parser, &hash_keys, (pm_node_t *) bare_hash, (uint16_t) (depth + 1));
                    }

                    pm_static_literals_free(&hash_keys);
                    parsed_bare_hash = true;
                }

                parse_arguments_append(parser, arguments, argument);

                pm_node_flags_t flags = 0;
                if (contains_keywords) flags |= PM_ARGUMENTS_NODE_FLAGS_CONTAINS_KEYWORDS;
                if (contains_keyword_splat) flags |= PM_ARGUMENTS_NODE_FLAGS_CONTAINS_KEYWORD_SPLAT;
                pm_node_flag_set((pm_node_t *) arguments->arguments, flags);

                break;
            }
        }

        parsed_first_argument = true;

        // If parsing the argument failed, we need to stop parsing arguments.
        if (PM_NODE_TYPE_P(argument, PM_MISSING_NODE) || parser->recovering) break;

        // If the terminator of these arguments is not EOF, then we have a
        // specific token we're looking for. In that case we can accept a
        // newline here because it is not functioning as a statement terminator.
        bool accepted_newline = false;
        if (terminator != PM_TOKEN_EOF) {
            accepted_newline = accept1(parser, PM_TOKEN_NEWLINE);
        }

        if (parser->previous.type == PM_TOKEN_COMMA && parsed_bare_hash) {
            // If we previously were on a comma and we just parsed a bare hash,
            // then we want to continue parsing arguments. This is because the
            // comma was grabbed up by the hash parser.
        } else if (accept1(parser, PM_TOKEN_COMMA)) {
            // If there was a comma, then we need to check if we also accepted a
            // newline. If we did, then this is a syntax error.
            if (accepted_newline) {
                pm_parser_err_previous(parser, PM_ERR_INVALID_COMMA);
            }
        } else {
            // If there is no comma at the end of the argument list then we're
            // done parsing arguments and can break out of this loop.
            break;
        }

        // If we hit the terminator, then that means we have a trailing comma so
        // we can accept that output as well.
        if (match1(parser, terminator)) break;
    }
}

/**
 * Required parameters on method, block, and lambda declarations can be
 * destructured using parentheses. This looks like:
 *
 *     def foo((bar, baz))
 *     end
 *
 *
 * It can recurse infinitely down, and splats are allowed to group arguments.
 */
static pm_multi_target_node_t *
parse_required_destructured_parameter(pm_parser_t *parser) {
    expect1(parser, PM_TOKEN_PARENTHESIS_LEFT, PM_ERR_EXPECT_LPAREN_REQ_PARAMETER);

    pm_multi_target_node_t *node = pm_multi_target_node_create(parser);
    pm_multi_target_node_opening_set(node, &parser->previous);

    do {
        pm_node_t *param;

        // If we get here then we have a trailing comma, which isn't allowed in
        // the grammar. In other places, multi targets _do_ allow trailing
        // commas, so here we'll assume this is a mistake of the user not
        // knowing it's not allowed here.
        if (node->lefts.size > 0 && match1(parser, PM_TOKEN_PARENTHESIS_RIGHT)) {
            param = (pm_node_t *) pm_implicit_rest_node_create(parser, &parser->previous);
            pm_multi_target_node_targets_append(parser, node, param);
            pm_parser_err_current(parser, PM_ERR_PARAMETER_WILD_LOOSE_COMMA);
            break;
        }

        if (match1(parser, PM_TOKEN_PARENTHESIS_LEFT)) {
            param = (pm_node_t *) parse_required_destructured_parameter(parser);
        } else if (accept1(parser, PM_TOKEN_USTAR)) {
            pm_token_t star = parser->previous;
            pm_node_t *value = NULL;

            if (accept1(parser, PM_TOKEN_IDENTIFIER)) {
                pm_token_t name = parser->previous;
                value = (pm_node_t *) pm_required_parameter_node_create(parser, &name);
                if (pm_parser_parameter_name_check(parser, &name)) {
                    pm_node_flag_set_repeated_parameter(value);
                }
                pm_parser_local_add_token(parser, &name, 1);
            }

            param = (pm_node_t *) pm_splat_node_create(parser, &star, value);
        } else {
            expect1(parser, PM_TOKEN_IDENTIFIER, PM_ERR_EXPECT_IDENT_REQ_PARAMETER);
            pm_token_t name = parser->previous;

            param = (pm_node_t *) pm_required_parameter_node_create(parser, &name);
            if (pm_parser_parameter_name_check(parser, &name)) {
                pm_node_flag_set_repeated_parameter(param);
            }
            pm_parser_local_add_token(parser, &name, 1);
        }

        pm_multi_target_node_targets_append(parser, node, param);
    } while (accept1(parser, PM_TOKEN_COMMA));

    accept1(parser, PM_TOKEN_NEWLINE);
    expect1(parser, PM_TOKEN_PARENTHESIS_RIGHT, PM_ERR_EXPECT_RPAREN_REQ_PARAMETER);
    pm_multi_target_node_closing_set(node, &parser->previous);

    return node;
}

/**
 * This represents the different order states we can be in when parsing
 * method parameters.
 */
typedef enum {
    PM_PARAMETERS_NO_CHANGE = 0, // Extra state for tokens that should not change the state
    PM_PARAMETERS_ORDER_NOTHING_AFTER = 1,
    PM_PARAMETERS_ORDER_KEYWORDS_REST,
    PM_PARAMETERS_ORDER_KEYWORDS,
    PM_PARAMETERS_ORDER_REST,
    PM_PARAMETERS_ORDER_AFTER_OPTIONAL,
    PM_PARAMETERS_ORDER_OPTIONAL,
    PM_PARAMETERS_ORDER_NAMED,
    PM_PARAMETERS_ORDER_NONE,
} pm_parameters_order_t;

/**
 * This matches parameters tokens with parameters state.
 */
static pm_parameters_order_t parameters_ordering[PM_TOKEN_MAXIMUM] = {
    [0] = PM_PARAMETERS_NO_CHANGE,
    [PM_TOKEN_UAMPERSAND] = PM_PARAMETERS_ORDER_NOTHING_AFTER,
    [PM_TOKEN_AMPERSAND] = PM_PARAMETERS_ORDER_NOTHING_AFTER,
    [PM_TOKEN_UDOT_DOT_DOT] = PM_PARAMETERS_ORDER_NOTHING_AFTER,
    [PM_TOKEN_IDENTIFIER] = PM_PARAMETERS_ORDER_NAMED,
    [PM_TOKEN_PARENTHESIS_LEFT] = PM_PARAMETERS_ORDER_NAMED,
    [PM_TOKEN_EQUAL] = PM_PARAMETERS_ORDER_OPTIONAL,
    [PM_TOKEN_LABEL] = PM_PARAMETERS_ORDER_KEYWORDS,
    [PM_TOKEN_USTAR] = PM_PARAMETERS_ORDER_AFTER_OPTIONAL,
    [PM_TOKEN_STAR] = PM_PARAMETERS_ORDER_AFTER_OPTIONAL,
    [PM_TOKEN_USTAR_STAR] = PM_PARAMETERS_ORDER_KEYWORDS_REST,
    [PM_TOKEN_STAR_STAR] = PM_PARAMETERS_ORDER_KEYWORDS_REST
};

/**
 * Check if current parameter follows valid parameters ordering. If not it adds
 * an error to the list without stopping the parsing, otherwise sets the
 * parameters state to the one corresponding to the current parameter.
 *
 * It returns true if it was successful, and false otherwise.
 */
static bool
update_parameter_state(pm_parser_t *parser, pm_token_t *token, pm_parameters_order_t *current) {
    pm_parameters_order_t state = parameters_ordering[token->type];
    if (state == PM_PARAMETERS_NO_CHANGE) return true;

    // If we see another ordered argument after a optional argument
    // we only continue parsing ordered arguments until we stop seeing ordered arguments.
    if (*current == PM_PARAMETERS_ORDER_OPTIONAL && state == PM_PARAMETERS_ORDER_NAMED) {
        *current = PM_PARAMETERS_ORDER_AFTER_OPTIONAL;
        return true;
    } else if (*current == PM_PARAMETERS_ORDER_AFTER_OPTIONAL && state == PM_PARAMETERS_ORDER_NAMED) {
        return true;
    }

    if (token->type == PM_TOKEN_USTAR && *current == PM_PARAMETERS_ORDER_AFTER_OPTIONAL) {
        pm_parser_err_token(parser, token, PM_ERR_PARAMETER_STAR);
        return false;
    } else if (token->type == PM_TOKEN_UDOT_DOT_DOT && (*current >= PM_PARAMETERS_ORDER_KEYWORDS_REST && *current <= PM_PARAMETERS_ORDER_AFTER_OPTIONAL)) {
        pm_parser_err_token(parser, token, *current == PM_PARAMETERS_ORDER_AFTER_OPTIONAL ? PM_ERR_PARAMETER_FORWARDING_AFTER_REST : PM_ERR_PARAMETER_ORDER);
        return false;
    } else if (*current == PM_PARAMETERS_ORDER_NOTHING_AFTER || state > *current) {
        // We know what transition we failed on, so we can provide a better error here.
        pm_parser_err_token(parser, token, PM_ERR_PARAMETER_ORDER);
        return false;
    }

    if (state < *current) *current = state;
    return true;
}

/**
 * Parse a list of parameters on a method definition.
 */
static pm_parameters_node_t *
parse_parameters(
    pm_parser_t *parser,
    pm_binding_power_t binding_power,
    bool uses_parentheses,
    bool allows_trailing_comma,
    bool allows_forwarding_parameters,
    bool accepts_blocks_in_defaults,
    bool in_block,
    uint16_t depth
) {
    pm_do_loop_stack_push(parser, false);

    pm_parameters_node_t *params = pm_parameters_node_create(parser);
    pm_parameters_order_t order = PM_PARAMETERS_ORDER_NONE;

    while (true) {
        bool parsing = true;

        switch (parser->current.type) {
            case PM_TOKEN_PARENTHESIS_LEFT: {
                update_parameter_state(parser, &parser->current, &order);
                pm_node_t *param = (pm_node_t *) parse_required_destructured_parameter(parser);

                if (order > PM_PARAMETERS_ORDER_AFTER_OPTIONAL) {
                    pm_parameters_node_requireds_append(params, param);
                } else {
                    pm_parameters_node_posts_append(params, param);
                }
                break;
            }
            case PM_TOKEN_UAMPERSAND:
            case PM_TOKEN_AMPERSAND: {
                update_parameter_state(parser, &parser->current, &order);
                parser_lex(parser);

                pm_token_t operator = parser->previous;
                pm_token_t name;

                bool repeated = false;
                if (accept1(parser, PM_TOKEN_IDENTIFIER)) {
                    name = parser->previous;
                    repeated = pm_parser_parameter_name_check(parser, &name);
                    pm_parser_local_add_token(parser, &name, 1);
                } else {
                    name = not_provided(parser);
                    parser->current_scope->parameters |= PM_SCOPE_PARAMETERS_FORWARDING_BLOCK;
                }

                pm_block_parameter_node_t *param = pm_block_parameter_node_create(parser, &name, &operator);
                if (repeated) {
                    pm_node_flag_set_repeated_parameter((pm_node_t *)param);
                }
                if (params->block == NULL) {
                    pm_parameters_node_block_set(params, param);
                } else {
                    pm_parser_err_node(parser, (pm_node_t *) param, PM_ERR_PARAMETER_BLOCK_MULTI);
                    pm_parameters_node_posts_append(params, (pm_node_t *) param);
                }

                break;
            }
            case PM_TOKEN_UDOT_DOT_DOT: {
                if (!allows_forwarding_parameters) {
                    pm_parser_err_current(parser, PM_ERR_ARGUMENT_NO_FORWARDING_ELLIPSES);
                }

                bool succeeded = update_parameter_state(parser, &parser->current, &order);
                parser_lex(parser);

                parser->current_scope->parameters |= PM_SCOPE_PARAMETERS_FORWARDING_ALL;
                pm_forwarding_parameter_node_t *param = pm_forwarding_parameter_node_create(parser, &parser->previous);

                if (params->keyword_rest != NULL) {
                    // If we already have a keyword rest parameter, then we replace it with the
                    // forwarding parameter and move the keyword rest parameter to the posts list.
                    pm_node_t *keyword_rest = params->keyword_rest;
                    pm_parameters_node_posts_append(params, keyword_rest);
                    if (succeeded) pm_parser_err_previous(parser, PM_ERR_PARAMETER_UNEXPECTED_FWD);
                    params->keyword_rest = NULL;
                }

                pm_parameters_node_keyword_rest_set(params, (pm_node_t *) param);
                break;
            }
            case PM_TOKEN_CLASS_VARIABLE:
            case PM_TOKEN_IDENTIFIER:
            case PM_TOKEN_CONSTANT:
            case PM_TOKEN_INSTANCE_VARIABLE:
            case PM_TOKEN_GLOBAL_VARIABLE:
            case PM_TOKEN_METHOD_NAME: {
                parser_lex(parser);
                switch (parser->previous.type) {
                    case PM_TOKEN_CONSTANT:
                        pm_parser_err_previous(parser, PM_ERR_ARGUMENT_FORMAL_CONSTANT);
                        break;
                    case PM_TOKEN_INSTANCE_VARIABLE:
                        pm_parser_err_previous(parser, PM_ERR_ARGUMENT_FORMAL_IVAR);
                        break;
                    case PM_TOKEN_GLOBAL_VARIABLE:
                        pm_parser_err_previous(parser, PM_ERR_ARGUMENT_FORMAL_GLOBAL);
                        break;
                    case PM_TOKEN_CLASS_VARIABLE:
                        pm_parser_err_previous(parser, PM_ERR_ARGUMENT_FORMAL_CLASS);
                        break;
                    case PM_TOKEN_METHOD_NAME:
                        pm_parser_err_previous(parser, PM_ERR_PARAMETER_METHOD_NAME);
                        break;
                    default: break;
                }

                if (parser->current.type == PM_TOKEN_EQUAL) {
                    update_parameter_state(parser, &parser->current, &order);
                } else {
                    update_parameter_state(parser, &parser->previous, &order);
                }

                pm_token_t name = parser->previous;
                bool repeated = pm_parser_parameter_name_check(parser, &name);
                pm_parser_local_add_token(parser, &name, 1);

                if (match1(parser, PM_TOKEN_EQUAL)) {
                    pm_token_t operator = parser->current;
                    context_push(parser, PM_CONTEXT_DEFAULT_PARAMS);
                    parser_lex(parser);

                    pm_constant_id_t name_id = pm_parser_constant_id_token(parser, &name);
                    uint32_t reads = parser->version == PM_OPTIONS_VERSION_CRUBY_3_3 ? pm_locals_reads(&parser->current_scope->locals, name_id) : 0;

                    if (accepts_blocks_in_defaults) pm_accepts_block_stack_push(parser, true);
                    pm_node_t *value = parse_value_expression(parser, binding_power, false, false, PM_ERR_PARAMETER_NO_DEFAULT, (uint16_t) (depth + 1));
                    if (accepts_blocks_in_defaults) pm_accepts_block_stack_pop(parser);

                    pm_optional_parameter_node_t *param = pm_optional_parameter_node_create(parser, &name, &operator, value);

                    if (repeated) {
                        pm_node_flag_set_repeated_parameter((pm_node_t *) param);
                    }
                    pm_parameters_node_optionals_append(params, param);

                    // If the value of the parameter increased the number of
                    // reads of that parameter, then we need to warn that we
                    // have a circular definition.
                    if ((parser->version == PM_OPTIONS_VERSION_CRUBY_3_3) && (pm_locals_reads(&parser->current_scope->locals, name_id) != reads)) {
                        PM_PARSER_ERR_TOKEN_FORMAT_CONTENT(parser, name, PM_ERR_PARAMETER_CIRCULAR);
                    }

                    context_pop(parser);

                    // If parsing the value of the parameter resulted in error recovery,
                    // then we can put a missing node in its place and stop parsing the
                    // parameters entirely now.
                    if (parser->recovering) {
                        parsing = false;
                        break;
                    }
                } else if (order > PM_PARAMETERS_ORDER_AFTER_OPTIONAL) {
                    pm_required_parameter_node_t *param = pm_required_parameter_node_create(parser, &name);
                    if (repeated) {
                        pm_node_flag_set_repeated_parameter((pm_node_t *)param);
                    }
                    pm_parameters_node_requireds_append(params, (pm_node_t *) param);
                } else {
                    pm_required_parameter_node_t *param = pm_required_parameter_node_create(parser, &name);
                    if (repeated) {
                        pm_node_flag_set_repeated_parameter((pm_node_t *)param);
                    }
                    pm_parameters_node_posts_append(params, (pm_node_t *) param);
                }

                break;
            }
            case PM_TOKEN_LABEL: {
                if (!uses_parentheses && !in_block) parser->in_keyword_arg = true;
                update_parameter_state(parser, &parser->current, &order);

                context_push(parser, PM_CONTEXT_DEFAULT_PARAMS);
                parser_lex(parser);

                pm_token_t name = parser->previous;
                pm_token_t local = name;
                local.end -= 1;

                if (parser->encoding_changed ? parser->encoding->isupper_char(local.start, local.end - local.start) : pm_encoding_utf_8_isupper_char(local.start, local.end - local.start)) {
                    pm_parser_err(parser, local.start, local.end, PM_ERR_ARGUMENT_FORMAL_CONSTANT);
                } else if (local.end[-1] == '!' || local.end[-1] == '?') {
                    PM_PARSER_ERR_TOKEN_FORMAT_CONTENT(parser, local, PM_ERR_INVALID_LOCAL_VARIABLE_WRITE);
                }

                bool repeated = pm_parser_parameter_name_check(parser, &local);
                pm_parser_local_add_token(parser, &local, 1);

                switch (parser->current.type) {
                    case PM_TOKEN_COMMA:
                    case PM_TOKEN_PARENTHESIS_RIGHT:
                    case PM_TOKEN_PIPE: {
                        context_pop(parser);

                        pm_node_t *param = (pm_node_t *) pm_required_keyword_parameter_node_create(parser, &name);
                        if (repeated) {
                            pm_node_flag_set_repeated_parameter(param);
                        }

                        pm_parameters_node_keywords_append(params, param);
                        break;
                    }
                    case PM_TOKEN_SEMICOLON:
                    case PM_TOKEN_NEWLINE: {
                        context_pop(parser);

                        if (uses_parentheses) {
                            parsing = false;
                            break;
                        }

                        pm_node_t *param = (pm_node_t *) pm_required_keyword_parameter_node_create(parser, &name);
                        if (repeated) {
                            pm_node_flag_set_repeated_parameter(param);
                        }

                        pm_parameters_node_keywords_append(params, param);
                        break;
                    }
                    default: {
                        pm_node_t *param;

                        if (token_begins_expression_p(parser->current.type)) {
                            pm_constant_id_t name_id = pm_parser_constant_id_token(parser, &local);
                            uint32_t reads = parser->version == PM_OPTIONS_VERSION_CRUBY_3_3 ? pm_locals_reads(&parser->current_scope->locals, name_id) : 0;

                            if (accepts_blocks_in_defaults) pm_accepts_block_stack_push(parser, true);
                            pm_node_t *value = parse_value_expression(parser, binding_power, false, false, PM_ERR_PARAMETER_NO_DEFAULT_KW, (uint16_t) (depth + 1));
                            if (accepts_blocks_in_defaults) pm_accepts_block_stack_pop(parser);

                            if (parser->version == PM_OPTIONS_VERSION_CRUBY_3_3 && (pm_locals_reads(&parser->current_scope->locals, name_id) != reads)) {
                                PM_PARSER_ERR_TOKEN_FORMAT_CONTENT(parser, local, PM_ERR_PARAMETER_CIRCULAR);
                            }

                            param = (pm_node_t *) pm_optional_keyword_parameter_node_create(parser, &name, value);
                        }
                        else {
                            param = (pm_node_t *) pm_required_keyword_parameter_node_create(parser, &name);
                        }

                        if (repeated) {
                            pm_node_flag_set_repeated_parameter(param);
                        }

                        context_pop(parser);
                        pm_parameters_node_keywords_append(params, param);

                        // If parsing the value of the parameter resulted in error recovery,
                        // then we can put a missing node in its place and stop parsing the
                        // parameters entirely now.
                        if (parser->recovering) {
                            parsing = false;
                            break;
                        }
                    }
                }

                parser->in_keyword_arg = false;
                break;
            }
            case PM_TOKEN_USTAR:
            case PM_TOKEN_STAR: {
                update_parameter_state(parser, &parser->current, &order);
                parser_lex(parser);

                pm_token_t operator = parser->previous;
                pm_token_t name;
                bool repeated = false;

                if (accept1(parser, PM_TOKEN_IDENTIFIER)) {
                    name = parser->previous;
                    repeated = pm_parser_parameter_name_check(parser, &name);
                    pm_parser_local_add_token(parser, &name, 1);
                } else {
                    name = not_provided(parser);
                    parser->current_scope->parameters |= PM_SCOPE_PARAMETERS_FORWARDING_POSITIONALS;
                }

                pm_node_t *param = (pm_node_t *) pm_rest_parameter_node_create(parser, &operator, &name);
                if (repeated) {
                    pm_node_flag_set_repeated_parameter(param);
                }

                if (params->rest == NULL) {
                    pm_parameters_node_rest_set(params, param);
                } else {
                    pm_parser_err_node(parser, param, PM_ERR_PARAMETER_SPLAT_MULTI);
                    pm_parameters_node_posts_append(params, param);
                }

                break;
            }
            case PM_TOKEN_STAR_STAR:
            case PM_TOKEN_USTAR_STAR: {
                pm_parameters_order_t previous_order = order;
                update_parameter_state(parser, &parser->current, &order);
                parser_lex(parser);

                pm_token_t operator = parser->previous;
                pm_node_t *param;

                if (accept1(parser, PM_TOKEN_KEYWORD_NIL)) {
                    if (previous_order <= PM_PARAMETERS_ORDER_KEYWORDS) {
                        pm_parser_err_previous(parser, PM_ERR_PARAMETER_UNEXPECTED_NO_KW);
                    }

                    param = (pm_node_t *) pm_no_keywords_parameter_node_create(parser, &operator, &parser->previous);
                } else {
                    pm_token_t name;

                    bool repeated = false;
                    if (accept1(parser, PM_TOKEN_IDENTIFIER)) {
                        name = parser->previous;
                        repeated = pm_parser_parameter_name_check(parser, &name);
                        pm_parser_local_add_token(parser, &name, 1);
                    } else {
                        name = not_provided(parser);
                        parser->current_scope->parameters |= PM_SCOPE_PARAMETERS_FORWARDING_KEYWORDS;
                    }

                    param = (pm_node_t *) pm_keyword_rest_parameter_node_create(parser, &operator, &name);
                    if (repeated) {
                        pm_node_flag_set_repeated_parameter(param);
                    }
                }

                if (params->keyword_rest == NULL) {
                    pm_parameters_node_keyword_rest_set(params, param);
                } else {
                    pm_parser_err_node(parser, param, PM_ERR_PARAMETER_ASSOC_SPLAT_MULTI);
                    pm_parameters_node_posts_append(params, param);
                }

                break;
            }
            default:
                if (parser->previous.type == PM_TOKEN_COMMA) {
                    if (allows_trailing_comma && order >= PM_PARAMETERS_ORDER_NAMED) {
                        // If we get here, then we have a trailing comma in a
                        // block parameter list.
                        pm_node_t *param = (pm_node_t *) pm_implicit_rest_node_create(parser, &parser->previous);

                        if (params->rest == NULL) {
                            pm_parameters_node_rest_set(params, param);
                        } else {
                            pm_parser_err_node(parser, (pm_node_t *) param, PM_ERR_PARAMETER_SPLAT_MULTI);
                            pm_parameters_node_posts_append(params, (pm_node_t *) param);
                        }
                    } else {
                        pm_parser_err_previous(parser, PM_ERR_PARAMETER_WILD_LOOSE_COMMA);
                    }
                }

                parsing = false;
                break;
        }

        // If we hit some kind of issue while parsing the parameter, this would
        // have been set to false. In that case, we need to break out of the
        // loop.
        if (!parsing) break;

        bool accepted_newline = false;
        if (uses_parentheses) {
            accepted_newline = accept1(parser, PM_TOKEN_NEWLINE);
        }

        if (accept1(parser, PM_TOKEN_COMMA)) {
            // If there was a comma, but we also accepted a newline, then this
            // is a syntax error.
            if (accepted_newline) {
                pm_parser_err_previous(parser, PM_ERR_INVALID_COMMA);
            }
        } else {
            // If there was no comma, then we're done parsing parameters.
            break;
        }
    }

    pm_do_loop_stack_pop(parser);

    // If we don't have any parameters, return `NULL` instead of an empty `ParametersNode`.
    if (params->base.location.start == params->base.location.end) {
        pm_node_destroy(parser, (pm_node_t *) params);
        return NULL;
    }

    return params;
}

/**
 * Accepts a parser returns the index of the last newline in the file that was
 * ecorded before the current token within the newline list.
 */
static size_t
token_newline_index(const pm_parser_t *parser) {
    if (parser->heredoc_end == NULL) {
        // This is the common case. In this case we can look at the previously
        // recorded newline in the newline list and subtract from the current
        // offset.
        return parser->newline_list.size - 1;
    } else {
        // This is unlikely. This is the case that we have already parsed the
        // start of a heredoc, so we cannot rely on looking at the previous
        // offset of the newline list, and instead must go through the whole
        // process of a binary search for the line number.
        return (size_t) pm_newline_list_line(&parser->newline_list, parser->current.start, 0);
    }
}

/**
 * Accepts a parser, a newline index, and a token and returns the column. The
 * important piece of this is that it expands tabs out to the next tab stop.
 */
static int64_t
token_column(const pm_parser_t *parser, size_t newline_index, const pm_token_t *token, bool break_on_non_space) {
    const uint8_t *cursor = parser->start + parser->newline_list.offsets[newline_index];
    const uint8_t *end = token->start;

    // Skip over the BOM if it is present.
    if (
        newline_index == 0 &&
        parser->start[0] == 0xef &&
        parser->start[1] == 0xbb &&
        parser->start[2] == 0xbf
    ) cursor += 3;

    int64_t column = 0;
    for (; cursor < end; cursor++) {
        switch (*cursor) {
            case '\t':
                column = ((column / PM_TAB_WHITESPACE_SIZE) + 1) * PM_TAB_WHITESPACE_SIZE;
                break;
            case ' ':
                column++;
                break;
            default:
                column++;
                if (break_on_non_space) return -1;
                break;
        }
    }

    return column;
}

/**
 * Accepts a parser, two newline indices, and pointers to two tokens. This
 * function warns if the indentation of the two tokens does not match.
 */
static void
parser_warn_indentation_mismatch(pm_parser_t *parser, size_t opening_newline_index, const pm_token_t *opening_token, bool if_after_else, bool allow_indent) {
    // If these warnings are disabled (unlikely), then we can just return.
    if (!parser->warn_mismatched_indentation) return;

    // If the tokens are on the same line, we do not warn.
    size_t closing_newline_index = token_newline_index(parser);
    if (opening_newline_index == closing_newline_index) return;

    // If the opening token has anything other than spaces or tabs before it,
    // then we do not warn. This is unless we are matching up an `if`/`end` pair
    // and the `if` immediately follows an `else` keyword.
    int64_t opening_column = token_column(parser, opening_newline_index, opening_token, !if_after_else);
    if (!if_after_else && (opening_column == -1)) return;

    // Get a reference to the closing token off the current parser. This assumes
    // that the caller has placed this in the correct position.
    pm_token_t *closing_token = &parser->current;

    // If the tokens are at the same indentation, we do not warn.
    int64_t closing_column = token_column(parser, closing_newline_index, closing_token, true);
    if ((closing_column == -1) || (opening_column == closing_column)) return;

    // If the closing column is greater than the opening column and we are
    // allowing indentation, then we do not warn.
    if (allow_indent && (closing_column > opening_column)) return;

    // Otherwise, add a warning.
    PM_PARSER_WARN_FORMAT(
        parser,
        closing_token->start,
        closing_token->end,
        PM_WARN_INDENTATION_MISMATCH,
        (int) (closing_token->end - closing_token->start),
        (const char *) closing_token->start,
        (int) (opening_token->end - opening_token->start),
        (const char *) opening_token->start,
        ((int32_t) opening_newline_index) + parser->start_line
    );
}

typedef enum {
    PM_RESCUES_BEGIN = 1,
    PM_RESCUES_BLOCK,
    PM_RESCUES_CLASS,
    PM_RESCUES_DEF,
    PM_RESCUES_LAMBDA,
    PM_RESCUES_MODULE,
    PM_RESCUES_SCLASS
} pm_rescues_type_t;

/**
 * Parse any number of rescue clauses. This will form a linked list of if
 * nodes pointing to each other from the top.
 */
static inline void
parse_rescues(pm_parser_t *parser, size_t opening_newline_index, const pm_token_t *opening, pm_begin_node_t *parent_node, pm_rescues_type_t type, uint16_t depth) {
    pm_rescue_node_t *current = NULL;

    while (match1(parser, PM_TOKEN_KEYWORD_RESCUE)) {
        if (opening != NULL) parser_warn_indentation_mismatch(parser, opening_newline_index, opening, false, false);
        parser_lex(parser);

        pm_rescue_node_t *rescue = pm_rescue_node_create(parser, &parser->previous);

        switch (parser->current.type) {
            case PM_TOKEN_EQUAL_GREATER: {
                // Here we have an immediate => after the rescue keyword, in which case
                // we're going to have an empty list of exceptions to rescue (which
                // implies StandardError).
                parser_lex(parser);
                pm_rescue_node_operator_set(rescue, &parser->previous);

                pm_node_t *reference = parse_expression(parser, PM_BINDING_POWER_INDEX, false, false, PM_ERR_RESCUE_VARIABLE, (uint16_t) (depth + 1));
                reference = parse_target(parser, reference, false, false);

                pm_rescue_node_reference_set(rescue, reference);
                break;
            }
            case PM_TOKEN_NEWLINE:
            case PM_TOKEN_SEMICOLON:
            case PM_TOKEN_KEYWORD_THEN:
                // Here we have a terminator for the rescue keyword, in which
                // case we're going to just continue on.
                break;
            default: {
                if (token_begins_expression_p(parser->current.type) || match1(parser, PM_TOKEN_USTAR)) {
                    // Here we have something that could be an exception expression, so
                    // we'll attempt to parse it here and any others delimited by commas.

                    do {
                        pm_node_t *expression = parse_starred_expression(parser, PM_BINDING_POWER_DEFINED, false, PM_ERR_RESCUE_EXPRESSION, (uint16_t) (depth + 1));
                        pm_rescue_node_exceptions_append(rescue, expression);

                        // If we hit a newline, then this is the end of the rescue expression. We
                        // can continue on to parse the statements.
                        if (match3(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON, PM_TOKEN_KEYWORD_THEN)) break;

                        // If we hit a `=>` then we're going to parse the exception variable. Once
                        // we've done that, we'll break out of the loop and parse the statements.
                        if (accept1(parser, PM_TOKEN_EQUAL_GREATER)) {
                            pm_rescue_node_operator_set(rescue, &parser->previous);

                            pm_node_t *reference = parse_expression(parser, PM_BINDING_POWER_INDEX, false, false, PM_ERR_RESCUE_VARIABLE, (uint16_t) (depth + 1));
                            reference = parse_target(parser, reference, false, false);

                            pm_rescue_node_reference_set(rescue, reference);
                            break;
                        }
                    } while (accept1(parser, PM_TOKEN_COMMA));
                }
            }
        }

        if (accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON)) {
            if (accept1(parser, PM_TOKEN_KEYWORD_THEN)) {
                rescue->then_keyword_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(&parser->previous);
            }
        } else {
            expect1(parser, PM_TOKEN_KEYWORD_THEN, PM_ERR_RESCUE_TERM);
            rescue->then_keyword_loc = PM_OPTIONAL_LOCATION_TOKEN_VALUE(&parser->previous);
        }

        if (!match3(parser, PM_TOKEN_KEYWORD_ELSE, PM_TOKEN_KEYWORD_ENSURE, PM_TOKEN_KEYWORD_END)) {
            pm_accepts_block_stack_push(parser, true);
            pm_context_t context;

            switch (type) {
                case PM_RESCUES_BEGIN: context = PM_CONTEXT_BEGIN_RESCUE; break;
                case PM_RESCUES_BLOCK: context = PM_CONTEXT_BLOCK_RESCUE; break;
                case PM_RESCUES_CLASS: context = PM_CONTEXT_CLASS_RESCUE; break;
                case PM_RESCUES_DEF: context = PM_CONTEXT_DEF_RESCUE; break;
                case PM_RESCUES_LAMBDA: context = PM_CONTEXT_LAMBDA_RESCUE; break;
                case PM_RESCUES_MODULE: context = PM_CONTEXT_MODULE_RESCUE; break;
                case PM_RESCUES_SCLASS: context = PM_CONTEXT_SCLASS_RESCUE; break;
                default: assert(false && "unreachable"); context = PM_CONTEXT_BEGIN_RESCUE; break;
            }

            pm_statements_node_t *statements = parse_statements(parser, context, (uint16_t) (depth + 1));
            if (statements != NULL) pm_rescue_node_statements_set(rescue, statements);

            pm_accepts_block_stack_pop(parser);
            accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON);
        }

        if (current == NULL) {
            pm_begin_node_rescue_clause_set(parent_node, rescue);
        } else {
            pm_rescue_node_subsequent_set(current, rescue);
        }

        current = rescue;
    }

    // The end node locations on rescue nodes will not be set correctly
    // since we won't know the end until we've found all subsequent
    // clauses. This sets the end location on all rescues once we know it.
    if (current != NULL) {
        const uint8_t *end_to_set = current->base.location.end;
        pm_rescue_node_t *clause = parent_node->rescue_clause;

        while (clause != NULL) {
            clause->base.location.end = end_to_set;
            clause = clause->subsequent;
        }
    }

    pm_token_t else_keyword;
    if (match1(parser, PM_TOKEN_KEYWORD_ELSE)) {
        if (opening != NULL) parser_warn_indentation_mismatch(parser, opening_newline_index, opening, false, false);
        opening_newline_index = token_newline_index(parser);

        else_keyword = parser->current;
        opening = &else_keyword;

        parser_lex(parser);
        accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON);

        pm_statements_node_t *else_statements = NULL;
        if (!match2(parser, PM_TOKEN_KEYWORD_END, PM_TOKEN_KEYWORD_ENSURE)) {
            pm_accepts_block_stack_push(parser, true);
            pm_context_t context;

            switch (type) {
                case PM_RESCUES_BEGIN: context = PM_CONTEXT_BEGIN_ELSE; break;
                case PM_RESCUES_BLOCK: context = PM_CONTEXT_BLOCK_ELSE; break;
                case PM_RESCUES_CLASS: context = PM_CONTEXT_CLASS_ELSE; break;
                case PM_RESCUES_DEF: context = PM_CONTEXT_DEF_ELSE; break;
                case PM_RESCUES_LAMBDA: context = PM_CONTEXT_LAMBDA_ELSE; break;
                case PM_RESCUES_MODULE: context = PM_CONTEXT_MODULE_ELSE; break;
                case PM_RESCUES_SCLASS: context = PM_CONTEXT_SCLASS_ELSE; break;
                default: assert(false && "unreachable"); context = PM_CONTEXT_BEGIN_ELSE; break;
            }

            else_statements = parse_statements(parser, context, (uint16_t) (depth + 1));
            pm_accepts_block_stack_pop(parser);

            accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON);
        }

        pm_else_node_t *else_clause = pm_else_node_create(parser, &else_keyword, else_statements, &parser->current);
        pm_begin_node_else_clause_set(parent_node, else_clause);

        // If we don't have a `current` rescue node, then this is a dangling
        // else, and it's an error.
        if (current == NULL) pm_parser_err_node(parser, (pm_node_t *) else_clause, PM_ERR_BEGIN_LONELY_ELSE);
    }

    if (match1(parser, PM_TOKEN_KEYWORD_ENSURE)) {
        if (opening != NULL) parser_warn_indentation_mismatch(parser, opening_newline_index, opening, false, false);
        pm_token_t ensure_keyword = parser->current;

        parser_lex(parser);
        accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON);

        pm_statements_node_t *ensure_statements = NULL;
        if (!match1(parser, PM_TOKEN_KEYWORD_END)) {
            pm_accepts_block_stack_push(parser, true);
            pm_context_t context;

            switch (type) {
                case PM_RESCUES_BEGIN: context = PM_CONTEXT_BEGIN_ENSURE; break;
                case PM_RESCUES_BLOCK: context = PM_CONTEXT_BLOCK_ENSURE; break;
                case PM_RESCUES_CLASS: context = PM_CONTEXT_CLASS_ENSURE; break;
                case PM_RESCUES_DEF: context = PM_CONTEXT_DEF_ENSURE; break;
                case PM_RESCUES_LAMBDA: context = PM_CONTEXT_LAMBDA_ENSURE; break;
                case PM_RESCUES_MODULE: context = PM_CONTEXT_MODULE_ENSURE; break;
                case PM_RESCUES_SCLASS: context = PM_CONTEXT_SCLASS_ENSURE; break;
                default: assert(false && "unreachable"); context = PM_CONTEXT_BEGIN_RESCUE; break;
            }

            ensure_statements = parse_statements(parser, context, (uint16_t) (depth + 1));
            pm_accepts_block_stack_pop(parser);

            accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON);
        }

        pm_ensure_node_t *ensure_clause = pm_ensure_node_create(parser, &ensure_keyword, ensure_statements, &parser->current);
        pm_begin_node_ensure_clause_set(parent_node, ensure_clause);
    }

    if (match1(parser, PM_TOKEN_KEYWORD_END)) {
        if (opening != NULL) parser_warn_indentation_mismatch(parser, opening_newline_index, opening, false, false);
        pm_begin_node_end_keyword_set(parent_node, &parser->current);
    } else {
        pm_token_t end_keyword = (pm_token_t) { .type = PM_TOKEN_MISSING, .start = parser->previous.end, .end = parser->previous.end };
        pm_begin_node_end_keyword_set(parent_node, &end_keyword);
    }
}

/**
 * Parse a set of rescue clauses with an implicit begin (for example when on a
 * class, module, def, etc.).
 */
static pm_begin_node_t *
parse_rescues_implicit_begin(pm_parser_t *parser, size_t opening_newline_index, const pm_token_t *opening, const uint8_t *start, pm_statements_node_t *statements, pm_rescues_type_t type, uint16_t depth) {
    pm_token_t begin_keyword = not_provided(parser);
    pm_begin_node_t *node = pm_begin_node_create(parser, &begin_keyword, statements);

    parse_rescues(parser, opening_newline_index, opening, node, type, (uint16_t) (depth + 1));
    node->base.location.start = start;

    return node;
}

/**
 * Parse a list of parameters and local on a block definition.
 */
static pm_block_parameters_node_t *
parse_block_parameters(
    pm_parser_t *parser,
    bool allows_trailing_comma,
    const pm_token_t *opening,
    bool is_lambda_literal,
    bool accepts_blocks_in_defaults,
    uint16_t depth
) {
    pm_parameters_node_t *parameters = NULL;
    if (!match1(parser, PM_TOKEN_SEMICOLON)) {
        parameters = parse_parameters(
            parser,
            is_lambda_literal ? PM_BINDING_POWER_DEFINED : PM_BINDING_POWER_INDEX,
            false,
            allows_trailing_comma,
            false,
            accepts_blocks_in_defaults,
            true,
            (uint16_t) (depth + 1)
        );
    }

    pm_block_parameters_node_t *block_parameters = pm_block_parameters_node_create(parser, parameters, opening);
    if ((opening->type != PM_TOKEN_NOT_PROVIDED)) {
        accept1(parser, PM_TOKEN_NEWLINE);

        if (accept1(parser, PM_TOKEN_SEMICOLON)) {
            do {
                switch (parser->current.type) {
                    case PM_TOKEN_CONSTANT:
                        pm_parser_err_current(parser, PM_ERR_ARGUMENT_FORMAL_CONSTANT);
                        parser_lex(parser);
                        break;
                    case PM_TOKEN_INSTANCE_VARIABLE:
                        pm_parser_err_current(parser, PM_ERR_ARGUMENT_FORMAL_IVAR);
                        parser_lex(parser);
                        break;
                    case PM_TOKEN_GLOBAL_VARIABLE:
                        pm_parser_err_current(parser, PM_ERR_ARGUMENT_FORMAL_GLOBAL);
                        parser_lex(parser);
                        break;
                    case PM_TOKEN_CLASS_VARIABLE:
                        pm_parser_err_current(parser, PM_ERR_ARGUMENT_FORMAL_CLASS);
                        parser_lex(parser);
                        break;
                    default:
                        expect1(parser, PM_TOKEN_IDENTIFIER, PM_ERR_BLOCK_PARAM_LOCAL_VARIABLE);
                        break;
                }

                bool repeated = pm_parser_parameter_name_check(parser, &parser->previous);
                pm_parser_local_add_token(parser, &parser->previous, 1);

                pm_block_local_variable_node_t *local = pm_block_local_variable_node_create(parser, &parser->previous);
                if (repeated) pm_node_flag_set_repeated_parameter((pm_node_t *) local);

                pm_block_parameters_node_append_local(block_parameters, local);
            } while (accept1(parser, PM_TOKEN_COMMA));
        }
    }

    return block_parameters;
}

/**
 * Return true if any of the visible scopes to the current context are using
 * numbered parameters.
 */
static bool
outer_scope_using_numbered_parameters_p(pm_parser_t *parser) {
    for (pm_scope_t *scope = parser->current_scope->previous; scope != NULL && !scope->closed; scope = scope->previous) {
        if (scope->parameters & PM_SCOPE_PARAMETERS_NUMBERED_FOUND) return true;
    }

    return false;
}

/**
 * These are the names of the various numbered parameters. We have them here so
 * that when we insert them into the constant pool we can use a constant string
 * and not have to allocate.
 */
static const char * const pm_numbered_parameter_names[] = {
    "_1", "_2", "_3", "_4", "_5", "_6", "_7", "_8", "_9"
};

/**
 * Return the node that should be used in the parameters field of a block-like
 * (block or lambda) node, depending on the kind of parameters that were
 * declared in the current scope.
 */
static pm_node_t *
parse_blocklike_parameters(pm_parser_t *parser, pm_node_t *parameters, const pm_token_t *opening, const pm_token_t *closing) {
    pm_node_list_t *implicit_parameters = &parser->current_scope->implicit_parameters;

    // If we have ordinary parameters, then we will return them as the set of
    // parameters.
    if (parameters != NULL) {
        // If we also have implicit parameters, then this is an error.
        if (implicit_parameters->size > 0) {
            pm_node_t *node = implicit_parameters->nodes[0];

            if (PM_NODE_TYPE_P(node, PM_LOCAL_VARIABLE_READ_NODE)) {
                pm_parser_err_node(parser, node, PM_ERR_NUMBERED_PARAMETER_ORDINARY);
            } else if (PM_NODE_TYPE_P(node, PM_IT_LOCAL_VARIABLE_READ_NODE)) {
                pm_parser_err_node(parser, node, PM_ERR_IT_NOT_ALLOWED_ORDINARY);
            } else {
                assert(false && "unreachable");
            }
        }

        return parameters;
    }

    // If we don't have any implicit parameters, then the set of parameters is
    // NULL.
    if (implicit_parameters->size == 0) {
        return NULL;
    }

    // If we don't have ordinary parameters, then we now must validate our set
    // of implicit parameters. We can only have numbered parameters or it, but
    // they cannot be mixed.
    uint8_t numbered_parameter = 0;
    bool it_parameter = false;

    for (size_t index = 0; index < implicit_parameters->size; index++) {
        pm_node_t *node = implicit_parameters->nodes[index];

        if (PM_NODE_TYPE_P(node, PM_LOCAL_VARIABLE_READ_NODE)) {
            if (it_parameter) {
                pm_parser_err_node(parser, node, PM_ERR_NUMBERED_PARAMETER_IT);
            } else if (outer_scope_using_numbered_parameters_p(parser)) {
                pm_parser_err_node(parser, node, PM_ERR_NUMBERED_PARAMETER_OUTER_BLOCK);
            } else if (parser->current_scope->parameters & PM_SCOPE_PARAMETERS_NUMBERED_INNER) {
                pm_parser_err_node(parser, node, PM_ERR_NUMBERED_PARAMETER_INNER_BLOCK);
            } else if (pm_token_is_numbered_parameter(node->location.start, node->location.end)) {
                numbered_parameter = MAX(numbered_parameter, (uint8_t) (node->location.start[1] - '0'));
            } else {
                assert(false && "unreachable");
            }
        } else if (PM_NODE_TYPE_P(node, PM_IT_LOCAL_VARIABLE_READ_NODE)) {
            if (numbered_parameter > 0) {
                pm_parser_err_node(parser, node, PM_ERR_IT_NOT_ALLOWED_NUMBERED);
            } else {
                it_parameter = true;
            }
        }
    }

    if (numbered_parameter > 0) {
        // Go through the parent scopes and mark them as being disallowed from
        // using numbered parameters because this inner scope is using them.
        for (pm_scope_t *scope = parser->current_scope->previous; scope != NULL && !scope->closed; scope = scope->previous) {
            scope->parameters |= PM_SCOPE_PARAMETERS_NUMBERED_INNER;
        }

        const pm_location_t location = { .start = opening->start, .end = closing->end };
        return (pm_node_t *) pm_numbered_parameters_node_create(parser, &location, numbered_parameter);
    }

    if (it_parameter) {
        return (pm_node_t *) pm_it_parameters_node_create(parser, opening, closing);
    }

    return NULL;
}

/**
 * Parse a block.
 */
static pm_block_node_t *
parse_block(pm_parser_t *parser, uint16_t depth) {
    pm_token_t opening = parser->previous;
    accept1(parser, PM_TOKEN_NEWLINE);

    pm_accepts_block_stack_push(parser, true);
    pm_parser_scope_push(parser, false);

    pm_block_parameters_node_t *block_parameters = NULL;

    if (accept1(parser, PM_TOKEN_PIPE)) {
        pm_token_t block_parameters_opening = parser->previous;
        if (match1(parser, PM_TOKEN_PIPE)) {
            block_parameters = pm_block_parameters_node_create(parser, NULL, &block_parameters_opening);
            parser->command_start = true;
            parser_lex(parser);
        } else {
            block_parameters = parse_block_parameters(parser, true, &block_parameters_opening, false, true, (uint16_t) (depth + 1));
            accept1(parser, PM_TOKEN_NEWLINE);
            parser->command_start = true;
            expect1(parser, PM_TOKEN_PIPE, PM_ERR_BLOCK_PARAM_PIPE_TERM);
        }

        pm_block_parameters_node_closing_set(block_parameters, &parser->previous);
    }

    accept1(parser, PM_TOKEN_NEWLINE);
    pm_node_t *statements = NULL;

    if (opening.type == PM_TOKEN_BRACE_LEFT) {
        if (!match1(parser, PM_TOKEN_BRACE_RIGHT)) {
            statements = (pm_node_t *) parse_statements(parser, PM_CONTEXT_BLOCK_BRACES, (uint16_t) (depth + 1));
        }

        expect1(parser, PM_TOKEN_BRACE_RIGHT, PM_ERR_BLOCK_TERM_BRACE);
    } else {
        if (!match1(parser, PM_TOKEN_KEYWORD_END)) {
            if (!match3(parser, PM_TOKEN_KEYWORD_RESCUE, PM_TOKEN_KEYWORD_ELSE, PM_TOKEN_KEYWORD_ENSURE)) {
                pm_accepts_block_stack_push(parser, true);
                statements = (pm_node_t *) parse_statements(parser, PM_CONTEXT_BLOCK_KEYWORDS, (uint16_t) (depth + 1));
                pm_accepts_block_stack_pop(parser);
            }

            if (match2(parser, PM_TOKEN_KEYWORD_RESCUE, PM_TOKEN_KEYWORD_ENSURE)) {
                assert(statements == NULL || PM_NODE_TYPE_P(statements, PM_STATEMENTS_NODE));
                statements = (pm_node_t *) parse_rescues_implicit_begin(parser, 0, NULL, opening.start, (pm_statements_node_t *) statements, PM_RESCUES_BLOCK, (uint16_t) (depth + 1));
            }
        }

        expect1(parser, PM_TOKEN_KEYWORD_END, PM_ERR_BLOCK_TERM_END);
    }

    pm_constant_id_list_t locals;
    pm_locals_order(parser, &parser->current_scope->locals, &locals, pm_parser_scope_toplevel_p(parser));
    pm_node_t *parameters = parse_blocklike_parameters(parser, (pm_node_t *) block_parameters, &opening, &parser->previous);

    pm_parser_scope_pop(parser);
    pm_accepts_block_stack_pop(parser);

    return pm_block_node_create(parser, &locals, &opening, parameters, statements, &parser->previous);
}

/**
 * Parse a list of arguments and their surrounding parentheses if they are
 * present. It returns true if it found any pieces of arguments (parentheses,
 * arguments, or blocks).
 */
static bool
parse_arguments_list(pm_parser_t *parser, pm_arguments_t *arguments, bool accepts_block, bool accepts_command_call, uint16_t depth) {
    bool found = false;

    if (accept1(parser, PM_TOKEN_PARENTHESIS_LEFT)) {
        found |= true;
        arguments->opening_loc = PM_LOCATION_TOKEN_VALUE(&parser->previous);

        if (accept1(parser, PM_TOKEN_PARENTHESIS_RIGHT)) {
            arguments->closing_loc = PM_LOCATION_TOKEN_VALUE(&parser->previous);
        } else {
            pm_accepts_block_stack_push(parser, true);
            parse_arguments(parser, arguments, accepts_block, PM_TOKEN_PARENTHESIS_RIGHT, (uint16_t) (depth + 1));

            if (!accept1(parser, PM_TOKEN_PARENTHESIS_RIGHT)) {
                PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_ARGUMENT_TERM_PAREN, pm_token_type_human(parser->current.type));
                parser->previous.start = parser->previous.end;
                parser->previous.type = PM_TOKEN_MISSING;
            }

            pm_accepts_block_stack_pop(parser);
            arguments->closing_loc = PM_LOCATION_TOKEN_VALUE(&parser->previous);
        }
    } else if (accepts_command_call && (token_begins_expression_p(parser->current.type) || match3(parser, PM_TOKEN_USTAR, PM_TOKEN_USTAR_STAR, PM_TOKEN_UAMPERSAND)) && !match1(parser, PM_TOKEN_BRACE_LEFT)) {
        found |= true;
        pm_accepts_block_stack_push(parser, false);

        // If we get here, then the subsequent token cannot be used as an infix
        // operator. In this case we assume the subsequent token is part of an
        // argument to this method call.
        parse_arguments(parser, arguments, accepts_block, PM_TOKEN_EOF, (uint16_t) (depth + 1));

        // If we have done with the arguments and still not consumed the comma,
        // then we have a trailing comma where we need to check whether it is
        // allowed or not.
        if (parser->previous.type == PM_TOKEN_COMMA && !match1(parser, PM_TOKEN_SEMICOLON)) {
            PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->previous, PM_ERR_EXPECT_ARGUMENT, pm_token_type_human(parser->current.type));
        }

        pm_accepts_block_stack_pop(parser);
    }

    // If we're at the end of the arguments, we can now check if there is a block
    // node that starts with a {. If there is, then we can parse it and add it to
    // the arguments.
    if (accepts_block) {
        pm_block_node_t *block = NULL;

        if (accept1(parser, PM_TOKEN_BRACE_LEFT)) {
            found |= true;
            block = parse_block(parser, (uint16_t) (depth + 1));
            pm_arguments_validate_block(parser, arguments, block);
        } else if (pm_accepts_block_stack_p(parser) && accept1(parser, PM_TOKEN_KEYWORD_DO)) {
            found |= true;
            block = parse_block(parser, (uint16_t) (depth + 1));
        }

        if (block != NULL) {
            if (arguments->block == NULL && !arguments->has_forwarding) {
                arguments->block = (pm_node_t *) block;
            } else {
                pm_parser_err_node(parser, (pm_node_t *) block, PM_ERR_ARGUMENT_BLOCK_MULTI);

                if (arguments->block != NULL) {
                    if (arguments->arguments == NULL) {
                        arguments->arguments = pm_arguments_node_create(parser);
                    }
                    pm_arguments_node_arguments_append(arguments->arguments, arguments->block);
                }
                arguments->block = (pm_node_t *) block;
            }
        }
    }

    return found;
}

/**
 * Check that the return is allowed in the current context. If it isn't, add an
 * error to the parser.
 */
static void
parse_return(pm_parser_t *parser, pm_node_t *node) {
    bool in_sclass = false;
    for (pm_context_node_t *context_node = parser->current_context; context_node != NULL; context_node = context_node->prev) {
        switch (context_node->context) {
            case PM_CONTEXT_BEGIN_ELSE:
            case PM_CONTEXT_BEGIN_ENSURE:
            case PM_CONTEXT_BEGIN_RESCUE:
            case PM_CONTEXT_BEGIN:
            case PM_CONTEXT_CASE_IN:
            case PM_CONTEXT_CASE_WHEN:
            case PM_CONTEXT_DEFAULT_PARAMS:
            case PM_CONTEXT_DEFINED:
            case PM_CONTEXT_ELSE:
            case PM_CONTEXT_ELSIF:
            case PM_CONTEXT_EMBEXPR:
            case PM_CONTEXT_FOR_INDEX:
            case PM_CONTEXT_FOR:
            case PM_CONTEXT_IF:
            case PM_CONTEXT_LOOP_PREDICATE:
            case PM_CONTEXT_MAIN:
            case PM_CONTEXT_MULTI_TARGET:
            case PM_CONTEXT_PARENS:
            case PM_CONTEXT_POSTEXE:
            case PM_CONTEXT_PREDICATE:
            case PM_CONTEXT_PREEXE:
            case PM_CONTEXT_RESCUE_MODIFIER:
            case PM_CONTEXT_TERNARY:
            case PM_CONTEXT_UNLESS:
            case PM_CONTEXT_UNTIL:
            case PM_CONTEXT_WHILE:
                // Keep iterating up the lists of contexts, because returns can
                // see through these.
                continue;
            case PM_CONTEXT_SCLASS_ELSE:
            case PM_CONTEXT_SCLASS_ENSURE:
            case PM_CONTEXT_SCLASS_RESCUE:
            case PM_CONTEXT_SCLASS:
                in_sclass = true;
                continue;
            case PM_CONTEXT_CLASS_ELSE:
            case PM_CONTEXT_CLASS_ENSURE:
            case PM_CONTEXT_CLASS_RESCUE:
            case PM_CONTEXT_CLASS:
            case PM_CONTEXT_MODULE_ELSE:
            case PM_CONTEXT_MODULE_ENSURE:
            case PM_CONTEXT_MODULE_RESCUE:
            case PM_CONTEXT_MODULE:
                // These contexts are invalid for a return.
                pm_parser_err_node(parser, node, PM_ERR_RETURN_INVALID);
                return;
            case PM_CONTEXT_BLOCK_BRACES:
            case PM_CONTEXT_BLOCK_ELSE:
            case PM_CONTEXT_BLOCK_ENSURE:
            case PM_CONTEXT_BLOCK_KEYWORDS:
            case PM_CONTEXT_BLOCK_RESCUE:
            case PM_CONTEXT_DEF_ELSE:
            case PM_CONTEXT_DEF_ENSURE:
            case PM_CONTEXT_DEF_PARAMS:
            case PM_CONTEXT_DEF_RESCUE:
            case PM_CONTEXT_DEF:
            case PM_CONTEXT_LAMBDA_BRACES:
            case PM_CONTEXT_LAMBDA_DO_END:
            case PM_CONTEXT_LAMBDA_ELSE:
            case PM_CONTEXT_LAMBDA_ENSURE:
            case PM_CONTEXT_LAMBDA_RESCUE:
                // These contexts are valid for a return, and we should not
                // continue to loop.
                return;
            case PM_CONTEXT_NONE:
                // This case should never happen.
                assert(false && "unreachable");
                break;
        }
    }
    if (in_sclass) {
        pm_parser_err_node(parser, node, PM_ERR_RETURN_INVALID);
    }
}

/**
 * Check that the block exit (next, break, redo) is allowed in the current
 * context. If it isn't, add an error to the parser.
 */
static void
parse_block_exit(pm_parser_t *parser, pm_node_t *node) {
    for (pm_context_node_t *context_node = parser->current_context; context_node != NULL; context_node = context_node->prev) {
        switch (context_node->context) {
            case PM_CONTEXT_BLOCK_BRACES:
            case PM_CONTEXT_BLOCK_KEYWORDS:
            case PM_CONTEXT_BLOCK_ELSE:
            case PM_CONTEXT_BLOCK_ENSURE:
            case PM_CONTEXT_BLOCK_RESCUE:
            case PM_CONTEXT_DEFINED:
            case PM_CONTEXT_FOR:
            case PM_CONTEXT_LAMBDA_BRACES:
            case PM_CONTEXT_LAMBDA_DO_END:
            case PM_CONTEXT_LAMBDA_ELSE:
            case PM_CONTEXT_LAMBDA_ENSURE:
            case PM_CONTEXT_LAMBDA_RESCUE:
            case PM_CONTEXT_LOOP_PREDICATE:
            case PM_CONTEXT_POSTEXE:
            case PM_CONTEXT_UNTIL:
            case PM_CONTEXT_WHILE:
                // These are the good cases. We're allowed to have a block exit
                // in these contexts.
                return;
            case PM_CONTEXT_DEF:
            case PM_CONTEXT_DEF_PARAMS:
            case PM_CONTEXT_DEF_ELSE:
            case PM_CONTEXT_DEF_ENSURE:
            case PM_CONTEXT_DEF_RESCUE:
            case PM_CONTEXT_MAIN:
            case PM_CONTEXT_PREEXE:
            case PM_CONTEXT_SCLASS:
            case PM_CONTEXT_SCLASS_ELSE:
            case PM_CONTEXT_SCLASS_ENSURE:
            case PM_CONTEXT_SCLASS_RESCUE:
                // These are the bad cases. We're not allowed to have a block
                // exit in these contexts.
                //
                // If we get here, then we're about to mark this block exit
                // as invalid. However, it could later _become_ valid if we
                // find a trailing while/until on the expression. In this
                // case instead of adding the error here, we'll add the
                // block exit to the list of exits for the expression, and
                // the node parsing will handle validating it instead.
                assert(parser->current_block_exits != NULL);
                pm_node_list_append(parser->current_block_exits, node);
                return;
            case PM_CONTEXT_BEGIN_ELSE:
            case PM_CONTEXT_BEGIN_ENSURE:
            case PM_CONTEXT_BEGIN_RESCUE:
            case PM_CONTEXT_BEGIN:
            case PM_CONTEXT_CASE_IN:
            case PM_CONTEXT_CASE_WHEN:
            case PM_CONTEXT_CLASS_ELSE:
            case PM_CONTEXT_CLASS_ENSURE:
            case PM_CONTEXT_CLASS_RESCUE:
            case PM_CONTEXT_CLASS:
            case PM_CONTEXT_DEFAULT_PARAMS:
            case PM_CONTEXT_ELSE:
            case PM_CONTEXT_ELSIF:
            case PM_CONTEXT_EMBEXPR:
            case PM_CONTEXT_FOR_INDEX:
            case PM_CONTEXT_IF:
            case PM_CONTEXT_MODULE_ELSE:
            case PM_CONTEXT_MODULE_ENSURE:
            case PM_CONTEXT_MODULE_RESCUE:
            case PM_CONTEXT_MODULE:
            case PM_CONTEXT_MULTI_TARGET:
            case PM_CONTEXT_PARENS:
            case PM_CONTEXT_PREDICATE:
            case PM_CONTEXT_RESCUE_MODIFIER:
            case PM_CONTEXT_TERNARY:
            case PM_CONTEXT_UNLESS:
                // In these contexts we should continue walking up the list of
                // contexts.
                break;
            case PM_CONTEXT_NONE:
                // This case should never happen.
                assert(false && "unreachable");
                break;
        }
    }
}

/**
 * When we hit an expression that could contain block exits, we need to stash
 * the previous set and create a new one.
 */
static pm_node_list_t *
push_block_exits(pm_parser_t *parser, pm_node_list_t *current_block_exits) {
    pm_node_list_t *previous_block_exits = parser->current_block_exits;
    parser->current_block_exits = current_block_exits;
    return previous_block_exits;
}

/**
 * If we did not match a trailing while/until and this was the last chance to do
 * so, then all of the block exits in the list are invalid and we need to add an
 * error for each of them.
 */
static void
flush_block_exits(pm_parser_t *parser, pm_node_list_t *previous_block_exits) {
    pm_node_t *block_exit;
    PM_NODE_LIST_FOREACH(parser->current_block_exits, index, block_exit) {
        const char *type;

        switch (PM_NODE_TYPE(block_exit)) {
            case PM_BREAK_NODE: type = "break"; break;
            case PM_NEXT_NODE: type = "next"; break;
            case PM_REDO_NODE: type = "redo"; break;
            default: assert(false && "unreachable"); type = ""; break;
        }

        PM_PARSER_ERR_NODE_FORMAT(parser, block_exit, PM_ERR_INVALID_BLOCK_EXIT, type);
    }

    parser->current_block_exits = previous_block_exits;
}

/**
 * Pop the current level of block exits from the parser, and add errors to the
 * parser if any of them are deemed to be invalid.
 */
static void
pop_block_exits(pm_parser_t *parser, pm_node_list_t *previous_block_exits) {
    if (match2(parser, PM_TOKEN_KEYWORD_WHILE_MODIFIER, PM_TOKEN_KEYWORD_UNTIL_MODIFIER)) {
        // If we matched a trailing while/until, then all of the block exits in
        // the contained list are valid. In this case we do not need to do
        // anything.
        parser->current_block_exits = previous_block_exits;
    } else if (previous_block_exits != NULL) {
        // If we did not matching a trailing while/until, then all of the block
        // exits contained in the list are invalid for this specific context.
        // However, they could still become valid in a higher level context if
        // there is another list above this one. In this case we'll push all of
        // the block exits up to the previous list.
        pm_node_list_concat(previous_block_exits, parser->current_block_exits);
        parser->current_block_exits = previous_block_exits;
    } else {
        // If we did not match a trailing while/until and this was the last
        // chance to do so, then all of the block exits in the list are invalid
        // and we need to add an error for each of them.
        flush_block_exits(parser, previous_block_exits);
    }
}

static inline pm_node_t *
parse_predicate(pm_parser_t *parser, pm_binding_power_t binding_power, pm_context_t context, pm_token_t *then_keyword, uint16_t depth) {
    context_push(parser, PM_CONTEXT_PREDICATE);
    pm_diagnostic_id_t error_id = context == PM_CONTEXT_IF ? PM_ERR_CONDITIONAL_IF_PREDICATE : PM_ERR_CONDITIONAL_UNLESS_PREDICATE;
    pm_node_t *predicate = parse_value_expression(parser, binding_power, true, false, error_id, (uint16_t) (depth + 1));

    // Predicates are closed by a term, a "then", or a term and then a "then".
    bool predicate_closed = accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON);

    if (accept1(parser, PM_TOKEN_KEYWORD_THEN)) {
        predicate_closed = true;
        *then_keyword = parser->previous;
    }

    if (!predicate_closed) {
        pm_parser_err_current(parser, PM_ERR_CONDITIONAL_PREDICATE_TERM);
    }

    context_pop(parser);
    return predicate;
}

static inline pm_node_t *
parse_conditional(pm_parser_t *parser, pm_context_t context, size_t opening_newline_index, bool if_after_else, uint16_t depth) {
    pm_node_list_t current_block_exits = { 0 };
    pm_node_list_t *previous_block_exits = push_block_exits(parser, &current_block_exits);

    pm_token_t keyword = parser->previous;
    pm_token_t then_keyword = not_provided(parser);

    pm_node_t *predicate = parse_predicate(parser, PM_BINDING_POWER_MODIFIER, context, &then_keyword, (uint16_t) (depth + 1));
    pm_statements_node_t *statements = NULL;

    if (!match3(parser, PM_TOKEN_KEYWORD_ELSIF, PM_TOKEN_KEYWORD_ELSE, PM_TOKEN_KEYWORD_END)) {
        pm_accepts_block_stack_push(parser, true);
        statements = parse_statements(parser, context, (uint16_t) (depth + 1));
        pm_accepts_block_stack_pop(parser);
        accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON);
    }

    pm_token_t end_keyword = not_provided(parser);
    pm_node_t *parent = NULL;

    switch (context) {
        case PM_CONTEXT_IF:
            parent = (pm_node_t *) pm_if_node_create(parser, &keyword, predicate, &then_keyword, statements, NULL, &end_keyword);
            break;
        case PM_CONTEXT_UNLESS:
            parent = (pm_node_t *) pm_unless_node_create(parser, &keyword, predicate, &then_keyword, statements);
            break;
        default:
            assert(false && "unreachable");
            break;
    }

    pm_node_t *current = parent;

    // Parse any number of elsif clauses. This will form a linked list of if
    // nodes pointing to each other from the top.
    if (context == PM_CONTEXT_IF) {
        while (match1(parser, PM_TOKEN_KEYWORD_ELSIF)) {
            if (parser_end_of_line_p(parser)) {
                PM_PARSER_WARN_TOKEN_FORMAT_CONTENT(parser, parser->current, PM_WARN_KEYWORD_EOL);
            }

            parser_warn_indentation_mismatch(parser, opening_newline_index, &keyword, false, false);
            pm_token_t elsif_keyword = parser->current;
            parser_lex(parser);

            pm_node_t *predicate = parse_predicate(parser, PM_BINDING_POWER_MODIFIER, PM_CONTEXT_ELSIF, &then_keyword, (uint16_t) (depth + 1));
            pm_accepts_block_stack_push(parser, true);

            pm_statements_node_t *statements = parse_statements(parser, PM_CONTEXT_ELSIF, (uint16_t) (depth + 1));
            pm_accepts_block_stack_pop(parser);
            accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON);

            pm_node_t *elsif = (pm_node_t *) pm_if_node_create(parser, &elsif_keyword, predicate, &then_keyword, statements, NULL, &end_keyword);
            ((pm_if_node_t *) current)->subsequent = elsif;
            current = elsif;
        }
    }

    if (match1(parser, PM_TOKEN_KEYWORD_ELSE)) {
        parser_warn_indentation_mismatch(parser, opening_newline_index, &keyword, false, false);
        opening_newline_index = token_newline_index(parser);

        parser_lex(parser);
        pm_token_t else_keyword = parser->previous;

        pm_accepts_block_stack_push(parser, true);
        pm_statements_node_t *else_statements = parse_statements(parser, PM_CONTEXT_ELSE, (uint16_t) (depth + 1));
        pm_accepts_block_stack_pop(parser);

        accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON);
        parser_warn_indentation_mismatch(parser, opening_newline_index, &else_keyword, false, false);
        expect1(parser, PM_TOKEN_KEYWORD_END, PM_ERR_CONDITIONAL_TERM_ELSE);

        pm_else_node_t *else_node = pm_else_node_create(parser, &else_keyword, else_statements, &parser->previous);

        switch (context) {
            case PM_CONTEXT_IF:
                ((pm_if_node_t *) current)->subsequent = (pm_node_t *) else_node;
                break;
            case PM_CONTEXT_UNLESS:
                ((pm_unless_node_t *) parent)->else_clause = else_node;
                break;
            default:
                assert(false && "unreachable");
                break;
        }
    } else {
        parser_warn_indentation_mismatch(parser, opening_newline_index, &keyword, if_after_else, false);
        expect1(parser, PM_TOKEN_KEYWORD_END, PM_ERR_CONDITIONAL_TERM);
    }

    // Set the appropriate end location for all of the nodes in the subtree.
    switch (context) {
        case PM_CONTEXT_IF: {
            pm_node_t *current = parent;
            bool recursing = true;

            while (recursing) {
                switch (PM_NODE_TYPE(current)) {
                    case PM_IF_NODE:
                        pm_if_node_end_keyword_loc_set((pm_if_node_t *) current, &parser->previous);
                        current = ((pm_if_node_t *) current)->subsequent;
                        recursing = current != NULL;
                        break;
                    case PM_ELSE_NODE:
                        pm_else_node_end_keyword_loc_set((pm_else_node_t *) current, &parser->previous);
                        recursing = false;
                        break;
                    default: {
                        recursing = false;
                        break;
                    }
                }
            }
            break;
        }
        case PM_CONTEXT_UNLESS:
            pm_unless_node_end_keyword_loc_set((pm_unless_node_t *) parent, &parser->previous);
            break;
        default:
            assert(false && "unreachable");
            break;
    }

    pop_block_exits(parser, previous_block_exits);
    pm_node_list_free(&current_block_exits);

    return parent;
}

/**
 * This macro allows you to define a case statement for all of the keywords.
 * It's meant to be used in a switch statement.
 */
#define PM_CASE_KEYWORD PM_TOKEN_KEYWORD___ENCODING__: case PM_TOKEN_KEYWORD___FILE__: case PM_TOKEN_KEYWORD___LINE__: \
    case PM_TOKEN_KEYWORD_ALIAS: case PM_TOKEN_KEYWORD_AND: case PM_TOKEN_KEYWORD_BEGIN: case PM_TOKEN_KEYWORD_BEGIN_UPCASE: \
    case PM_TOKEN_KEYWORD_BREAK: case PM_TOKEN_KEYWORD_CASE: case PM_TOKEN_KEYWORD_CLASS: case PM_TOKEN_KEYWORD_DEF: \
    case PM_TOKEN_KEYWORD_DEFINED: case PM_TOKEN_KEYWORD_DO: case PM_TOKEN_KEYWORD_DO_LOOP: case PM_TOKEN_KEYWORD_ELSE: \
    case PM_TOKEN_KEYWORD_ELSIF: case PM_TOKEN_KEYWORD_END: case PM_TOKEN_KEYWORD_END_UPCASE: case PM_TOKEN_KEYWORD_ENSURE: \
    case PM_TOKEN_KEYWORD_FALSE: case PM_TOKEN_KEYWORD_FOR: case PM_TOKEN_KEYWORD_IF: case PM_TOKEN_KEYWORD_IN: \
    case PM_TOKEN_KEYWORD_MODULE: case PM_TOKEN_KEYWORD_NEXT: case PM_TOKEN_KEYWORD_NIL: case PM_TOKEN_KEYWORD_NOT: \
    case PM_TOKEN_KEYWORD_OR: case PM_TOKEN_KEYWORD_REDO: case PM_TOKEN_KEYWORD_RESCUE: case PM_TOKEN_KEYWORD_RETRY: \
    case PM_TOKEN_KEYWORD_RETURN: case PM_TOKEN_KEYWORD_SELF: case PM_TOKEN_KEYWORD_SUPER: case PM_TOKEN_KEYWORD_THEN: \
    case PM_TOKEN_KEYWORD_TRUE: case PM_TOKEN_KEYWORD_UNDEF: case PM_TOKEN_KEYWORD_UNLESS: case PM_TOKEN_KEYWORD_UNTIL: \
    case PM_TOKEN_KEYWORD_WHEN: case PM_TOKEN_KEYWORD_WHILE: case PM_TOKEN_KEYWORD_YIELD

/**
 * This macro allows you to define a case statement for all of the operators.
 * It's meant to be used in a switch statement.
 */
#define PM_CASE_OPERATOR PM_TOKEN_AMPERSAND: case PM_TOKEN_BACKTICK: case PM_TOKEN_BANG_EQUAL: \
    case PM_TOKEN_BANG_TILDE: case PM_TOKEN_BANG: case PM_TOKEN_BRACKET_LEFT_RIGHT_EQUAL: \
    case PM_TOKEN_BRACKET_LEFT_RIGHT: case PM_TOKEN_CARET: case PM_TOKEN_EQUAL_EQUAL_EQUAL: case PM_TOKEN_EQUAL_EQUAL: \
    case PM_TOKEN_EQUAL_TILDE: case PM_TOKEN_GREATER_EQUAL: case PM_TOKEN_GREATER_GREATER: case PM_TOKEN_GREATER: \
    case PM_TOKEN_LESS_EQUAL_GREATER: case PM_TOKEN_LESS_EQUAL: case PM_TOKEN_LESS_LESS: case PM_TOKEN_LESS: \
    case PM_TOKEN_MINUS: case PM_TOKEN_PERCENT: case PM_TOKEN_PIPE: case PM_TOKEN_PLUS: case PM_TOKEN_SLASH: \
    case PM_TOKEN_STAR_STAR: case PM_TOKEN_STAR: case PM_TOKEN_TILDE: case PM_TOKEN_UAMPERSAND: case PM_TOKEN_UMINUS: \
    case PM_TOKEN_UMINUS_NUM: case PM_TOKEN_UPLUS: case PM_TOKEN_USTAR: case PM_TOKEN_USTAR_STAR

/**
 * This macro allows you to define a case statement for all of the token types
 * that represent the beginning of nodes that are "primitives" in a pattern
 * matching expression.
 */
#define PM_CASE_PRIMITIVE PM_TOKEN_INTEGER: case PM_TOKEN_INTEGER_IMAGINARY: case PM_TOKEN_INTEGER_RATIONAL: \
    case PM_TOKEN_INTEGER_RATIONAL_IMAGINARY: case PM_TOKEN_FLOAT: case PM_TOKEN_FLOAT_IMAGINARY: \
    case PM_TOKEN_FLOAT_RATIONAL: case PM_TOKEN_FLOAT_RATIONAL_IMAGINARY: case PM_TOKEN_SYMBOL_BEGIN: \
    case PM_TOKEN_REGEXP_BEGIN: case PM_TOKEN_BACKTICK: case PM_TOKEN_PERCENT_LOWER_X: case PM_TOKEN_PERCENT_LOWER_I: \
    case PM_TOKEN_PERCENT_LOWER_W: case PM_TOKEN_PERCENT_UPPER_I: case PM_TOKEN_PERCENT_UPPER_W: \
    case PM_TOKEN_STRING_BEGIN: case PM_TOKEN_KEYWORD_NIL: case PM_TOKEN_KEYWORD_SELF: case PM_TOKEN_KEYWORD_TRUE: \
    case PM_TOKEN_KEYWORD_FALSE: case PM_TOKEN_KEYWORD___FILE__: case PM_TOKEN_KEYWORD___LINE__: \
    case PM_TOKEN_KEYWORD___ENCODING__: case PM_TOKEN_MINUS_GREATER: case PM_TOKEN_HEREDOC_START: \
    case PM_TOKEN_UMINUS_NUM: case PM_TOKEN_CHARACTER_LITERAL

/**
 * This macro allows you to define a case statement for all of the token types
 * that could begin a parameter.
 */
#define PM_CASE_PARAMETER PM_TOKEN_UAMPERSAND: case PM_TOKEN_AMPERSAND: case PM_TOKEN_UDOT_DOT_DOT: \
    case PM_TOKEN_IDENTIFIER: case PM_TOKEN_LABEL: case PM_TOKEN_USTAR: case PM_TOKEN_STAR: case PM_TOKEN_STAR_STAR: \
    case PM_TOKEN_USTAR_STAR: case PM_TOKEN_CONSTANT: case PM_TOKEN_INSTANCE_VARIABLE: case PM_TOKEN_GLOBAL_VARIABLE: \
    case PM_TOKEN_CLASS_VARIABLE

/**
 * This macro allows you to define a case statement for all of the nodes that
 * can be transformed into write targets.
 */
#define PM_CASE_WRITABLE PM_CLASS_VARIABLE_READ_NODE: case PM_CONSTANT_PATH_NODE: \
    case PM_CONSTANT_READ_NODE: case PM_GLOBAL_VARIABLE_READ_NODE: case PM_LOCAL_VARIABLE_READ_NODE: \
    case PM_INSTANCE_VARIABLE_READ_NODE: case PM_MULTI_TARGET_NODE: case PM_BACK_REFERENCE_READ_NODE: \
    case PM_NUMBERED_REFERENCE_READ_NODE: case PM_IT_LOCAL_VARIABLE_READ_NODE

// Assert here that the flags are the same so that we can safely switch the type
// of the node without having to move the flags.
PM_STATIC_ASSERT(__LINE__, ((int) PM_STRING_FLAGS_FORCED_UTF8_ENCODING) == ((int) PM_ENCODING_FLAGS_FORCED_UTF8_ENCODING), "Expected the flags to match.");

/**
 * If the encoding was explicitly set through the lexing process, then we need
 * to potentially mark the string's flags to indicate how to encode it.
 */
static inline pm_node_flags_t
parse_unescaped_encoding(const pm_parser_t *parser) {
    if (parser->explicit_encoding != NULL) {
        if (parser->explicit_encoding == PM_ENCODING_UTF_8_ENTRY) {
            // If the there's an explicit encoding and it's using a UTF-8 escape
            // sequence, then mark the string as UTF-8.
            return PM_STRING_FLAGS_FORCED_UTF8_ENCODING;
        } else if (parser->encoding == PM_ENCODING_US_ASCII_ENTRY) {
            // If there's a non-UTF-8 escape sequence being used, then the
            // string uses the source encoding, unless the source is marked as
            // US-ASCII. In that case the string is forced as ASCII-8BIT in
            // order to keep the string valid.
            return PM_STRING_FLAGS_FORCED_BINARY_ENCODING;
        }
    }
    return 0;
}

/**
 * Parse a node that is part of a string. If the subsequent tokens cannot be
 * parsed as a string part, then NULL is returned.
 */
static pm_node_t *
parse_string_part(pm_parser_t *parser, uint16_t depth) {
    switch (parser->current.type) {
        // Here the lexer has returned to us plain string content. In this case
        // we'll create a string node that has no opening or closing and return that
        // as the part. These kinds of parts look like:
        //
        //     "aaa #{bbb} #@ccc ddd"
        //      ^^^^      ^     ^^^^
        case PM_TOKEN_STRING_CONTENT: {
            pm_token_t opening = not_provided(parser);
            pm_token_t closing = not_provided(parser);

            pm_node_t *node = (pm_node_t *) pm_string_node_create_current_string(parser, &opening, &parser->current, &closing);
            pm_node_flag_set(node, parse_unescaped_encoding(parser));

            parser_lex(parser);
            return node;
        }
        // Here the lexer has returned the beginning of an embedded expression. In
        // that case we'll parse the inner statements and return that as the part.
        // These kinds of parts look like:
        //
        //     "aaa #{bbb} #@ccc ddd"
        //          ^^^^^^
        case PM_TOKEN_EMBEXPR_BEGIN: {
            // Ruby disallows seeing encoding around interpolation in strings,
            // even though it is known at parse time.
            parser->explicit_encoding = NULL;

            pm_lex_state_t state = parser->lex_state;
            int brace_nesting = parser->brace_nesting;

            parser->brace_nesting = 0;
            lex_state_set(parser, PM_LEX_STATE_BEG);
            parser_lex(parser);

            pm_token_t opening = parser->previous;
            pm_statements_node_t *statements = NULL;

            if (!match1(parser, PM_TOKEN_EMBEXPR_END)) {
                pm_accepts_block_stack_push(parser, true);
                statements = parse_statements(parser, PM_CONTEXT_EMBEXPR, (uint16_t) (depth + 1));
                pm_accepts_block_stack_pop(parser);
            }

            parser->brace_nesting = brace_nesting;
            lex_state_set(parser, state);

            expect1(parser, PM_TOKEN_EMBEXPR_END, PM_ERR_EMBEXPR_END);
            pm_token_t closing = parser->previous;

            // If this set of embedded statements only contains a single
            // statement, then Ruby does not consider it as a possible statement
            // that could emit a line event.
            if (statements != NULL && statements->body.size == 1) {
                pm_node_flag_unset(statements->body.nodes[0], PM_NODE_FLAG_NEWLINE);
            }

            return (pm_node_t *) pm_embedded_statements_node_create(parser, &opening, statements, &closing);
        }

        // Here the lexer has returned the beginning of an embedded variable.
        // In that case we'll parse the variable and create an appropriate node
        // for it and then return that node. These kinds of parts look like:
        //
        //     "aaa #{bbb} #@ccc ddd"
        //                 ^^^^^
        case PM_TOKEN_EMBVAR: {
            // Ruby disallows seeing encoding around interpolation in strings,
            // even though it is known at parse time.
            parser->explicit_encoding = NULL;

            lex_state_set(parser, PM_LEX_STATE_BEG);
            parser_lex(parser);

            pm_token_t operator = parser->previous;
            pm_node_t *variable;

            switch (parser->current.type) {
                // In this case a back reference is being interpolated. We'll
                // create a global variable read node.
                case PM_TOKEN_BACK_REFERENCE:
                    parser_lex(parser);
                    variable = (pm_node_t *) pm_back_reference_read_node_create(parser, &parser->previous);
                    break;
                // In this case an nth reference is being interpolated. We'll
                // create a global variable read node.
                case PM_TOKEN_NUMBERED_REFERENCE:
                    parser_lex(parser);
                    variable = (pm_node_t *) pm_numbered_reference_read_node_create(parser, &parser->previous);
                    break;
                // In this case a global variable is being interpolated. We'll
                // create a global variable read node.
                case PM_TOKEN_GLOBAL_VARIABLE:
                    parser_lex(parser);
                    variable = (pm_node_t *) pm_global_variable_read_node_create(parser, &parser->previous);
                    break;
                // In this case an instance variable is being interpolated.
                // We'll create an instance variable read node.
                case PM_TOKEN_INSTANCE_VARIABLE:
                    parser_lex(parser);
                    variable = (pm_node_t *) pm_instance_variable_read_node_create(parser, &parser->previous);
                    break;
                // In this case a class variable is being interpolated. We'll
                // create a class variable read node.
                case PM_TOKEN_CLASS_VARIABLE:
                    parser_lex(parser);
                    variable = (pm_node_t *) pm_class_variable_read_node_create(parser, &parser->previous);
                    break;
                // We can hit here if we got an invalid token. In that case
                // we'll not attempt to lex this token and instead just return a
                // missing node.
                default:
                    expect1(parser, PM_TOKEN_IDENTIFIER, PM_ERR_EMBVAR_INVALID);
                    variable = (pm_node_t *) pm_missing_node_create(parser, parser->current.start, parser->current.end);
                    break;
            }

            return (pm_node_t *) pm_embedded_variable_node_create(parser, &operator, variable);
        }
        default:
            parser_lex(parser);
            pm_parser_err_previous(parser, PM_ERR_CANNOT_PARSE_STRING_PART);
            return NULL;
    }
}

/**
 * When creating a symbol, unary operators that cannot be binary operators
 * automatically drop trailing `@` characters. This happens at the parser level,
 * such that `~@` is parsed as `~` and `!@` is parsed as `!`. We do that here.
 */
static const uint8_t *
parse_operator_symbol_name(const pm_token_t *name) {
    switch (name->type) {
        case PM_TOKEN_TILDE:
        case PM_TOKEN_BANG:
            if (name->end[-1] == '@') return name->end - 1;
        PRISM_FALLTHROUGH
        default:
            return name->end;
    }
}

static pm_node_t *
parse_operator_symbol(pm_parser_t *parser, const pm_token_t *opening, pm_lex_state_t next_state) {
    pm_token_t closing = not_provided(parser);
    pm_symbol_node_t *symbol = pm_symbol_node_create(parser, opening, &parser->current, &closing);

    const uint8_t *end = parse_operator_symbol_name(&parser->current);

    if (next_state != PM_LEX_STATE_NONE) lex_state_set(parser, next_state);
    parser_lex(parser);

    pm_string_shared_init(&symbol->unescaped, parser->previous.start, end);
    pm_node_flag_set((pm_node_t *) symbol, PM_SYMBOL_FLAGS_FORCED_US_ASCII_ENCODING);

    return (pm_node_t *) symbol;
}

/**
 * Parse a symbol node. This function will get called immediately after finding
 * a symbol opening token. This handles parsing bare symbols and interpolated
 * symbols.
 */
static pm_node_t *
parse_symbol(pm_parser_t *parser, pm_lex_mode_t *lex_mode, pm_lex_state_t next_state, uint16_t depth) {
    const pm_token_t opening = parser->previous;

    if (lex_mode->mode != PM_LEX_STRING) {
        if (next_state != PM_LEX_STATE_NONE) lex_state_set(parser, next_state);

        switch (parser->current.type) {
            case PM_CASE_OPERATOR:
                return parse_operator_symbol(parser, &opening, next_state == PM_LEX_STATE_NONE ? PM_LEX_STATE_ENDFN : next_state);
            case PM_TOKEN_IDENTIFIER:
            case PM_TOKEN_CONSTANT:
            case PM_TOKEN_INSTANCE_VARIABLE:
            case PM_TOKEN_METHOD_NAME:
            case PM_TOKEN_CLASS_VARIABLE:
            case PM_TOKEN_GLOBAL_VARIABLE:
            case PM_TOKEN_NUMBERED_REFERENCE:
            case PM_TOKEN_BACK_REFERENCE:
            case PM_CASE_KEYWORD:
                parser_lex(parser);
                break;
            default:
                expect2(parser, PM_TOKEN_IDENTIFIER, PM_TOKEN_METHOD_NAME, PM_ERR_SYMBOL_INVALID);
                break;
        }

        pm_token_t closing = not_provided(parser);
        pm_symbol_node_t *symbol = pm_symbol_node_create(parser, &opening, &parser->previous, &closing);

        pm_string_shared_init(&symbol->unescaped, parser->previous.start, parser->previous.end);
        pm_node_flag_set((pm_node_t *) symbol, parse_symbol_encoding(parser, &parser->previous, &symbol->unescaped, false));

        return (pm_node_t *) symbol;
    }

    if (lex_mode->as.string.interpolation) {
        // If we have the end of the symbol, then we can return an empty symbol.
        if (match1(parser, PM_TOKEN_STRING_END)) {
            if (next_state != PM_LEX_STATE_NONE) lex_state_set(parser, next_state);
            parser_lex(parser);

            pm_token_t content = not_provided(parser);
            pm_token_t closing = parser->previous;
            return (pm_node_t *) pm_symbol_node_create(parser, &opening, &content, &closing);
        }

        // Now we can parse the first part of the symbol.
        pm_node_t *part = parse_string_part(parser, (uint16_t) (depth + 1));

        // If we got a string part, then it's possible that we could transform
        // what looks like an interpolated symbol into a regular symbol.
        if (part && PM_NODE_TYPE_P(part, PM_STRING_NODE) && match2(parser, PM_TOKEN_STRING_END, PM_TOKEN_EOF)) {
            if (next_state != PM_LEX_STATE_NONE) lex_state_set(parser, next_state);
            expect1(parser, PM_TOKEN_STRING_END, PM_ERR_SYMBOL_TERM_INTERPOLATED);

            return (pm_node_t *) pm_string_node_to_symbol_node(parser, (pm_string_node_t *) part, &opening, &parser->previous);
        }

        pm_interpolated_symbol_node_t *symbol = pm_interpolated_symbol_node_create(parser, &opening, NULL, &opening);
        if (part) pm_interpolated_symbol_node_append(symbol, part);

        while (!match2(parser, PM_TOKEN_STRING_END, PM_TOKEN_EOF)) {
            if ((part = parse_string_part(parser, (uint16_t) (depth + 1))) != NULL) {
                pm_interpolated_symbol_node_append(symbol, part);
            }
        }

        if (next_state != PM_LEX_STATE_NONE) lex_state_set(parser, next_state);
        if (match1(parser, PM_TOKEN_EOF)) {
            pm_parser_err_token(parser, &opening, PM_ERR_SYMBOL_TERM_INTERPOLATED);
        } else {
            expect1(parser, PM_TOKEN_STRING_END, PM_ERR_SYMBOL_TERM_INTERPOLATED);
        }

        pm_interpolated_symbol_node_closing_loc_set(symbol, &parser->previous);
        return (pm_node_t *) symbol;
    }

    pm_token_t content;
    pm_string_t unescaped;

    if (match1(parser, PM_TOKEN_STRING_CONTENT)) {
        content = parser->current;
        unescaped = parser->current_string;
        parser_lex(parser);

        // If we have two string contents in a row, then the content of this
        // symbol is split because of heredoc contents. This looks like:
        //
        // <<A; :'a
        // A
        // b'
        //
        // In this case, the best way we have to represent this is as an
        // interpolated string node, so that's what we'll do here.
        if (match1(parser, PM_TOKEN_STRING_CONTENT)) {
            pm_interpolated_symbol_node_t *symbol = pm_interpolated_symbol_node_create(parser, &opening, NULL, &opening);
            pm_token_t bounds = not_provided(parser);

            pm_node_t *part = (pm_node_t *) pm_string_node_create_unescaped(parser, &bounds, &content, &bounds, &unescaped);
            pm_interpolated_symbol_node_append(symbol, part);

            part = (pm_node_t *) pm_string_node_create_unescaped(parser, &bounds, &parser->current, &bounds, &parser->current_string);
            pm_interpolated_symbol_node_append(symbol, part);

            if (next_state != PM_LEX_STATE_NONE) {
                lex_state_set(parser, next_state);
            }

            parser_lex(parser);
            expect1(parser, PM_TOKEN_STRING_END, PM_ERR_SYMBOL_TERM_DYNAMIC);

            pm_interpolated_symbol_node_closing_loc_set(symbol, &parser->previous);
            return (pm_node_t *) symbol;
        }
    } else {
        content = (pm_token_t) { .type = PM_TOKEN_STRING_CONTENT, .start = parser->previous.end, .end = parser->previous.end };
        pm_string_shared_init(&unescaped, content.start, content.end);
    }

    if (next_state != PM_LEX_STATE_NONE) {
        lex_state_set(parser, next_state);
    }

    if (match1(parser, PM_TOKEN_EOF)) {
        pm_parser_err_token(parser, &opening, PM_ERR_SYMBOL_TERM_DYNAMIC);
    } else {
        expect1(parser, PM_TOKEN_STRING_END, PM_ERR_SYMBOL_TERM_DYNAMIC);
    }

    return (pm_node_t *) pm_symbol_node_create_unescaped(parser, &opening, &content, &parser->previous, &unescaped, parse_symbol_encoding(parser, &content, &unescaped, false));
}

/**
 * Parse an argument to undef which can either be a bare word, a symbol, a
 * constant, or an interpolated symbol.
 */
static inline pm_node_t *
parse_undef_argument(pm_parser_t *parser, uint16_t depth) {
    switch (parser->current.type) {
        case PM_CASE_OPERATOR: {
            const pm_token_t opening = not_provided(parser);
            return parse_operator_symbol(parser, &opening, PM_LEX_STATE_NONE);
        }
        case PM_CASE_KEYWORD:
        case PM_TOKEN_CONSTANT:
        case PM_TOKEN_IDENTIFIER:
        case PM_TOKEN_METHOD_NAME: {
            parser_lex(parser);

            pm_token_t opening = not_provided(parser);
            pm_token_t closing = not_provided(parser);
            pm_symbol_node_t *symbol = pm_symbol_node_create(parser, &opening, &parser->previous, &closing);

            pm_string_shared_init(&symbol->unescaped, parser->previous.start, parser->previous.end);
            pm_node_flag_set((pm_node_t *) symbol, parse_symbol_encoding(parser, &parser->previous, &symbol->unescaped, false));

            return (pm_node_t *) symbol;
        }
        case PM_TOKEN_SYMBOL_BEGIN: {
            pm_lex_mode_t lex_mode = *parser->lex_modes.current;
            parser_lex(parser);

            return parse_symbol(parser, &lex_mode, PM_LEX_STATE_NONE, (uint16_t) (depth + 1));
        }
        default:
            pm_parser_err_current(parser, PM_ERR_UNDEF_ARGUMENT);
            return (pm_node_t *) pm_missing_node_create(parser, parser->current.start, parser->current.end);
    }
}

/**
 * Parse an argument to alias which can either be a bare word, a symbol, an
 * interpolated symbol or a global variable. If this is the first argument, then
 * we need to set the lex state to PM_LEX_STATE_FNAME | PM_LEX_STATE_FITEM
 * between the first and second arguments.
 */
static inline pm_node_t *
parse_alias_argument(pm_parser_t *parser, bool first, uint16_t depth) {
    switch (parser->current.type) {
        case PM_CASE_OPERATOR: {
            const pm_token_t opening = not_provided(parser);
            return parse_operator_symbol(parser, &opening, first ? PM_LEX_STATE_FNAME | PM_LEX_STATE_FITEM : PM_LEX_STATE_NONE);
        }
        case PM_CASE_KEYWORD:
        case PM_TOKEN_CONSTANT:
        case PM_TOKEN_IDENTIFIER:
        case PM_TOKEN_METHOD_NAME: {
            if (first) lex_state_set(parser, PM_LEX_STATE_FNAME | PM_LEX_STATE_FITEM);
            parser_lex(parser);

            pm_token_t opening = not_provided(parser);
            pm_token_t closing = not_provided(parser);
            pm_symbol_node_t *symbol = pm_symbol_node_create(parser, &opening, &parser->previous, &closing);

            pm_string_shared_init(&symbol->unescaped, parser->previous.start, parser->previous.end);
            pm_node_flag_set((pm_node_t *) symbol, parse_symbol_encoding(parser, &parser->previous, &symbol->unescaped, false));

            return (pm_node_t *) symbol;
        }
        case PM_TOKEN_SYMBOL_BEGIN: {
            pm_lex_mode_t lex_mode = *parser->lex_modes.current;
            parser_lex(parser);

            return parse_symbol(parser, &lex_mode, first ? PM_LEX_STATE_FNAME | PM_LEX_STATE_FITEM : PM_LEX_STATE_NONE, (uint16_t) (depth + 1));
        }
        case PM_TOKEN_BACK_REFERENCE:
            parser_lex(parser);
            return (pm_node_t *) pm_back_reference_read_node_create(parser, &parser->previous);
        case PM_TOKEN_NUMBERED_REFERENCE:
            parser_lex(parser);
            return (pm_node_t *) pm_numbered_reference_read_node_create(parser, &parser->previous);
        case PM_TOKEN_GLOBAL_VARIABLE:
            parser_lex(parser);
            return (pm_node_t *) pm_global_variable_read_node_create(parser, &parser->previous);
        default:
            pm_parser_err_current(parser, PM_ERR_ALIAS_ARGUMENT);
            return (pm_node_t *) pm_missing_node_create(parser, parser->current.start, parser->current.end);
    }
}

/**
 * Parse an identifier into either a local variable read. If the local variable
 * is not found, it returns NULL instead.
 */
static pm_node_t *
parse_variable(pm_parser_t *parser) {
    pm_constant_id_t name_id = pm_parser_constant_id_token(parser, &parser->previous);
    int depth;
    bool is_numbered_param = pm_token_is_numbered_parameter(parser->previous.start, parser->previous.end);

    if (!is_numbered_param && ((depth = pm_parser_local_depth_constant_id(parser, name_id)) != -1)) {
        return (pm_node_t *) pm_local_variable_read_node_create_constant_id(parser, &parser->previous, name_id, (uint32_t) depth, false);
    }

    pm_scope_t *current_scope = parser->current_scope;
    if (!current_scope->closed && !(current_scope->parameters & PM_SCOPE_PARAMETERS_IMPLICIT_DISALLOWED)) {
        if (is_numbered_param) {
            // When you use a numbered parameter, it implies the existence of
            // all of the locals that exist before it. For example, referencing
            // _2 means that _1 must exist. Therefore here we loop through all
            // of the possibilities and add them into the constant pool.
            uint8_t maximum = (uint8_t) (parser->previous.start[1] - '0');
            for (uint8_t number = 1; number <= maximum; number++) {
                pm_parser_local_add_constant(parser, pm_numbered_parameter_names[number - 1], 2);
            }

            if (!match1(parser, PM_TOKEN_EQUAL)) {
                parser->current_scope->parameters |= PM_SCOPE_PARAMETERS_NUMBERED_FOUND;
            }

            pm_node_t *node = (pm_node_t *) pm_local_variable_read_node_create_constant_id(parser, &parser->previous, name_id, 0, false);
            pm_node_list_append(&current_scope->implicit_parameters, node);

            return node;
        } else if ((parser->version != PM_OPTIONS_VERSION_CRUBY_3_3) && pm_token_is_it(parser->previous.start, parser->previous.end)) {
            pm_node_t *node = (pm_node_t *) pm_it_local_variable_read_node_create(parser, &parser->previous);
            pm_node_list_append(&current_scope->implicit_parameters, node);

            return node;
        }
    }

    return NULL;
}

/**
 * Parse an identifier into either a local variable read or a call.
 */
static pm_node_t *
parse_variable_call(pm_parser_t *parser) {
    pm_node_flags_t flags = 0;

    if (!match1(parser, PM_TOKEN_PARENTHESIS_LEFT) && (parser->previous.end[-1] != '!') && (parser->previous.end[-1] != '?')) {
        pm_node_t *node = parse_variable(parser);
        if (node != NULL) return node;
        flags |= PM_CALL_NODE_FLAGS_VARIABLE_CALL;
    }

    pm_call_node_t *node = pm_call_node_variable_call_create(parser, &parser->previous);
    pm_node_flag_set((pm_node_t *)node, flags);

    return (pm_node_t *) node;
}

/**
 * Parse the method definition name based on the current token available on the
 * parser. If it does not match a valid method definition name, then a missing
 * token is returned.
 */
static inline pm_token_t
parse_method_definition_name(pm_parser_t *parser) {
    switch (parser->current.type) {
        case PM_CASE_KEYWORD:
        case PM_TOKEN_CONSTANT:
        case PM_TOKEN_METHOD_NAME:
            parser_lex(parser);
            return parser->previous;
        case PM_TOKEN_IDENTIFIER:
            pm_refute_numbered_parameter(parser, parser->current.start, parser->current.end);
            parser_lex(parser);
            return parser->previous;
        case PM_CASE_OPERATOR:
            lex_state_set(parser, PM_LEX_STATE_ENDFN);
            parser_lex(parser);
            return parser->previous;
        default:
            PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_DEF_NAME, pm_token_type_human(parser->current.type));
            return (pm_token_t) { .type = PM_TOKEN_MISSING, .start = parser->current.start, .end = parser->current.end };
    }
}

static void
parse_heredoc_dedent_string(pm_string_t *string, size_t common_whitespace) {
    // Get a reference to the string struct that is being held by the string
    // node. This is the value we're going to actually manipulate.
    pm_string_ensure_owned(string);

    // Now get the bounds of the existing string. We'll use this as a
    // destination to move bytes into. We'll also use it for bounds checking
    // since we don't require that these strings be null terminated.
    size_t dest_length = pm_string_length(string);
    const uint8_t *source_cursor = (uint8_t *) string->source;
    const uint8_t *source_end = source_cursor + dest_length;

    // We're going to move bytes backward in the string when we get leading
    // whitespace, so we'll maintain a pointer to the current position in the
    // string that we're writing to.
    size_t trimmed_whitespace = 0;

    // While we haven't reached the amount of common whitespace that we need to
    // trim and we haven't reached the end of the string, we'll keep trimming
    // whitespace. Trimming in this context means skipping over these bytes such
    // that they aren't copied into the new string.
    while ((source_cursor < source_end) && pm_char_is_inline_whitespace(*source_cursor) && trimmed_whitespace < common_whitespace) {
        if (*source_cursor == '\t') {
            trimmed_whitespace = (trimmed_whitespace / PM_TAB_WHITESPACE_SIZE + 1) * PM_TAB_WHITESPACE_SIZE;
            if (trimmed_whitespace > common_whitespace) break;
        } else {
            trimmed_whitespace++;
        }

        source_cursor++;
        dest_length--;
    }

    memmove((uint8_t *) string->source, source_cursor, (size_t) (source_end - source_cursor));
    string->length = dest_length;
}

/**
 * Take a heredoc node that is indented by a ~ and trim the leading whitespace.
 */
static void
parse_heredoc_dedent(pm_parser_t *parser, pm_node_list_t *nodes, size_t common_whitespace) {
    // The next node should be dedented if it's the first node in the list or if
    // it follows a string node.
    bool dedent_next = true;

    // Iterate over all nodes, and trim whitespace accordingly. We're going to
    // keep around two indices: a read and a write. If we end up trimming all of
    // the whitespace from a node, then we'll drop it from the list entirely.
    size_t write_index = 0;

    pm_node_t *node;
    PM_NODE_LIST_FOREACH(nodes, read_index, node) {
        // We're not manipulating child nodes that aren't strings. In this case
        // we'll skip past it and indicate that the subsequent node should not
        // be dedented.
        if (!PM_NODE_TYPE_P(node, PM_STRING_NODE)) {
            nodes->nodes[write_index++] = node;
            dedent_next = false;
            continue;
        }

        pm_string_node_t *string_node = ((pm_string_node_t *) node);
        if (dedent_next) {
            parse_heredoc_dedent_string(&string_node->unescaped, common_whitespace);
        }

        if (string_node->unescaped.length == 0) {
            pm_node_destroy(parser, node);
        } else {
            nodes->nodes[write_index++] = node;
        }

        // We always dedent the next node if it follows a string node.
        dedent_next = true;
    }

    nodes->size = write_index;
}

/**
 * Return a string content token at a particular location that is empty.
 */
static pm_token_t
parse_strings_empty_content(const uint8_t *location) {
    return (pm_token_t) { .type = PM_TOKEN_STRING_CONTENT, .start = location, .end = location };
}

/**
 * Parse a set of strings that could be concatenated together.
 */
static inline pm_node_t *
parse_strings(pm_parser_t *parser, pm_node_t *current, bool accepts_label, uint16_t depth) {
    assert(parser->current.type == PM_TOKEN_STRING_BEGIN);
    bool concating = false;

    while (match1(parser, PM_TOKEN_STRING_BEGIN)) {
        pm_node_t *node = NULL;

        // Here we have found a string literal. We'll parse it and add it to
        // the list of strings.
        const pm_lex_mode_t *lex_mode = parser->lex_modes.current;
        assert(lex_mode->mode == PM_LEX_STRING);
        bool lex_interpolation = lex_mode->as.string.interpolation;
        bool label_allowed = lex_mode->as.string.label_allowed && accepts_label;

        pm_token_t opening = parser->current;
        parser_lex(parser);

        if (match2(parser, PM_TOKEN_STRING_END, PM_TOKEN_EOF)) {
            expect1(parser, PM_TOKEN_STRING_END, PM_ERR_STRING_LITERAL_EOF);
            // If we get here, then we have an end immediately after a
            // start. In that case we'll create an empty content token and
            // return an uninterpolated string.
            pm_token_t content = parse_strings_empty_content(parser->previous.start);
            pm_string_node_t *string = pm_string_node_create(parser, &opening, &content, &parser->previous);

            pm_string_shared_init(&string->unescaped, content.start, content.end);
            node = (pm_node_t *) string;
        } else if (accept1(parser, PM_TOKEN_LABEL_END)) {
            // If we get here, then we have an end of a label immediately
            // after a start. In that case we'll create an empty symbol
            // node.
            pm_token_t content = parse_strings_empty_content(parser->previous.start);
            pm_symbol_node_t *symbol = pm_symbol_node_create(parser, &opening, &content, &parser->previous);

            pm_string_shared_init(&symbol->unescaped, content.start, content.end);
            node = (pm_node_t *) symbol;

            if (!label_allowed) pm_parser_err_node(parser, node, PM_ERR_UNEXPECTED_LABEL);
        } else if (!lex_interpolation) {
            // If we don't accept interpolation then we expect the string to
            // start with a single string content node.
            pm_string_t unescaped;
            pm_token_t content;

            if (match1(parser, PM_TOKEN_EOF)) {
                unescaped = PM_STRING_EMPTY;
                content = not_provided(parser);
            } else {
                unescaped = parser->current_string;
                expect1(parser, PM_TOKEN_STRING_CONTENT, PM_ERR_EXPECT_STRING_CONTENT);
                content = parser->previous;
            }

            // It is unfortunately possible to have multiple string content
            // nodes in a row in the case that there's heredoc content in
            // the middle of the string, like this cursed example:
            //
            // <<-END+'b
            //  a
            // END
            //  c'+'d'
            //
            // In that case we need to switch to an interpolated string to
            // be able to contain all of the parts.
            if (match1(parser, PM_TOKEN_STRING_CONTENT)) {
                pm_node_list_t parts = { 0 };

                pm_token_t delimiters = not_provided(parser);
                pm_node_t *part = (pm_node_t *) pm_string_node_create_unescaped(parser, &delimiters, &content, &delimiters, &unescaped);
                pm_node_list_append(&parts, part);

                do {
                    part = (pm_node_t *) pm_string_node_create_current_string(parser, &delimiters, &parser->current, &delimiters);
                    pm_node_list_append(&parts, part);
                    parser_lex(parser);
                } while (match1(parser, PM_TOKEN_STRING_CONTENT));

                expect1(parser, PM_TOKEN_STRING_END, PM_ERR_STRING_LITERAL_EOF);
                node = (pm_node_t *) pm_interpolated_string_node_create(parser, &opening, &parts, &parser->previous);

                pm_node_list_free(&parts);
            } else if (accept1(parser, PM_TOKEN_LABEL_END)) {
                node = (pm_node_t *) pm_symbol_node_create_unescaped(parser, &opening, &content, &parser->previous, &unescaped, parse_symbol_encoding(parser, &content, &unescaped, true));
                if (!label_allowed) pm_parser_err_node(parser, node, PM_ERR_UNEXPECTED_LABEL);
            } else if (match1(parser, PM_TOKEN_EOF)) {
                pm_parser_err_token(parser, &opening, PM_ERR_STRING_LITERAL_EOF);
                node = (pm_node_t *) pm_string_node_create_unescaped(parser, &opening, &content, &parser->current, &unescaped);
            } else if (accept1(parser, PM_TOKEN_STRING_END)) {
                node = (pm_node_t *) pm_string_node_create_unescaped(parser, &opening, &content, &parser->previous, &unescaped);
            } else {
                PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->previous, PM_ERR_STRING_LITERAL_TERM, pm_token_type_human(parser->previous.type));
                parser->previous.start = parser->previous.end;
                parser->previous.type = PM_TOKEN_MISSING;
                node = (pm_node_t *) pm_string_node_create_unescaped(parser, &opening, &content, &parser->previous, &unescaped);
            }
        } else if (match1(parser, PM_TOKEN_STRING_CONTENT)) {
            // In this case we've hit string content so we know the string
            // at least has something in it. We'll need to check if the
            // following token is the end (in which case we can return a
            // plain string) or if it's not then it has interpolation.
            pm_token_t content = parser->current;
            pm_string_t unescaped = parser->current_string;
            parser_lex(parser);

            if (match2(parser, PM_TOKEN_STRING_END, PM_TOKEN_EOF)) {
                node = (pm_node_t *) pm_string_node_create_unescaped(parser, &opening, &content, &parser->current, &unescaped);
                pm_node_flag_set(node, parse_unescaped_encoding(parser));

                // Kind of odd behavior, but basically if we have an
                // unterminated string and it ends in a newline, we back up one
                // character so that the error message is on the last line of
                // content in the string.
                if (!accept1(parser, PM_TOKEN_STRING_END)) {
                    const uint8_t *location = parser->previous.end;
                    if (location > parser->start && location[-1] == '\n') location--;
                    pm_parser_err(parser, location, location, PM_ERR_STRING_LITERAL_EOF);

                    parser->previous.start = parser->previous.end;
                    parser->previous.type = PM_TOKEN_MISSING;
                }
            } else if (accept1(parser, PM_TOKEN_LABEL_END)) {
                node = (pm_node_t *) pm_symbol_node_create_unescaped(parser, &opening, &content, &parser->previous, &unescaped, parse_symbol_encoding(parser, &content, &unescaped, true));
                if (!label_allowed) pm_parser_err_node(parser, node, PM_ERR_UNEXPECTED_LABEL);
            } else {
                // If we get here, then we have interpolation so we'll need
                // to create a string or symbol node with interpolation.
                pm_node_list_t parts = { 0 };
                pm_token_t string_opening = not_provided(parser);
                pm_token_t string_closing = not_provided(parser);

                pm_node_t *part = (pm_node_t *) pm_string_node_create_unescaped(parser, &string_opening, &parser->previous, &string_closing, &unescaped);
                pm_node_flag_set(part, parse_unescaped_encoding(parser));
                pm_node_list_append(&parts, part);

                while (!match3(parser, PM_TOKEN_STRING_END, PM_TOKEN_LABEL_END, PM_TOKEN_EOF)) {
                    if ((part = parse_string_part(parser, (uint16_t) (depth + 1))) != NULL) {
                        pm_node_list_append(&parts, part);
                    }
                }

                if (accept1(parser, PM_TOKEN_LABEL_END)) {
                    node = (pm_node_t *) pm_interpolated_symbol_node_create(parser, &opening, &parts, &parser->previous);
                    if (!label_allowed) pm_parser_err_node(parser, node, PM_ERR_UNEXPECTED_LABEL);
                } else if (match1(parser, PM_TOKEN_EOF)) {
                    pm_parser_err_token(parser, &opening, PM_ERR_STRING_INTERPOLATED_TERM);
                    node = (pm_node_t *) pm_interpolated_string_node_create(parser, &opening, &parts, &parser->current);
                } else {
                    expect1(parser, PM_TOKEN_STRING_END, PM_ERR_STRING_INTERPOLATED_TERM);
                    node = (pm_node_t *) pm_interpolated_string_node_create(parser, &opening, &parts, &parser->previous);
                }

                pm_node_list_free(&parts);
            }
        } else {
            // If we get here, then the first part of the string is not plain
            // string content, in which case we need to parse the string as an
            // interpolated string.
            pm_node_list_t parts = { 0 };
            pm_node_t *part;

            while (!match3(parser, PM_TOKEN_STRING_END, PM_TOKEN_LABEL_END, PM_TOKEN_EOF)) {
                if ((part = parse_string_part(parser, (uint16_t) (depth + 1))) != NULL) {
                    pm_node_list_append(&parts, part);
                }
            }

            if (accept1(parser, PM_TOKEN_LABEL_END)) {
                node = (pm_node_t *) pm_interpolated_symbol_node_create(parser, &opening, &parts, &parser->previous);
                if (!label_allowed) pm_parser_err_node(parser, node, PM_ERR_UNEXPECTED_LABEL);
            } else if (match1(parser, PM_TOKEN_EOF)) {
                pm_parser_err_token(parser, &opening, PM_ERR_STRING_INTERPOLATED_TERM);
                node = (pm_node_t *) pm_interpolated_string_node_create(parser, &opening, &parts, &parser->current);
            } else {
                expect1(parser, PM_TOKEN_STRING_END, PM_ERR_STRING_INTERPOLATED_TERM);
                node = (pm_node_t *) pm_interpolated_string_node_create(parser, &opening, &parts, &parser->previous);
            }

            pm_node_list_free(&parts);
        }

        if (current == NULL) {
            // If the node we just parsed is a symbol node, then we can't
            // concatenate it with anything else, so we can now return that
            // node.
            if (PM_NODE_TYPE_P(node, PM_SYMBOL_NODE) || PM_NODE_TYPE_P(node, PM_INTERPOLATED_SYMBOL_NODE)) {
                return node;
            }

            // If we don't already have a node, then it's fine and we can just
            // set the result to be the node we just parsed.
            current = node;
        } else {
            // Otherwise we need to check the type of the node we just parsed.
            // If it cannot be concatenated with the previous node, then we'll
            // need to add a syntax error.
            if (!PM_NODE_TYPE_P(node, PM_STRING_NODE) && !PM_NODE_TYPE_P(node, PM_INTERPOLATED_STRING_NODE)) {
                pm_parser_err_node(parser, node, PM_ERR_STRING_CONCATENATION);
            }

            // If we haven't already created our container for concatenation,
            // we'll do that now.
            if (!concating) {
                if (!PM_NODE_TYPE_P(current, PM_STRING_NODE) && !PM_NODE_TYPE_P(current, PM_INTERPOLATED_STRING_NODE)) {
                    pm_parser_err_node(parser, current, PM_ERR_STRING_CONCATENATION);
                }

                concating = true;
                pm_token_t bounds = not_provided(parser);

                pm_interpolated_string_node_t *container = pm_interpolated_string_node_create(parser, &bounds, NULL, &bounds);
                pm_interpolated_string_node_append(container, current);
                current = (pm_node_t *) container;
            }

            pm_interpolated_string_node_append((pm_interpolated_string_node_t *) current, node);
        }
    }

    return current;
}

#define PM_PARSE_PATTERN_SINGLE 0
#define PM_PARSE_PATTERN_TOP 1
#define PM_PARSE_PATTERN_MULTI 2

static pm_node_t *
parse_pattern(pm_parser_t *parser, pm_constant_id_list_t *captures, uint8_t flags, pm_diagnostic_id_t diag_id, uint16_t depth);

/**
 * Add the newly created local to the list of captures for this pattern matching
 * expression. If it is duplicated from a previous local, then we'll need to add
 * an error to the parser.
 */
static void
parse_pattern_capture(pm_parser_t *parser, pm_constant_id_list_t *captures, pm_constant_id_t capture, const pm_location_t *location) {
    // Skip this capture if it starts with an underscore.
    if (*location->start == '_') return;

    if (pm_constant_id_list_includes(captures, capture)) {
        pm_parser_err(parser, location->start, location->end, PM_ERR_PATTERN_CAPTURE_DUPLICATE);
    } else {
        pm_constant_id_list_append(captures, capture);
    }
}

/**
 * Accept any number of constants joined by :: delimiters.
 */
static pm_node_t *
parse_pattern_constant_path(pm_parser_t *parser, pm_constant_id_list_t *captures, pm_node_t *node, uint16_t depth) {
    // Now, if there are any :: operators that follow, parse them as constant
    // path nodes.
    while (accept1(parser, PM_TOKEN_COLON_COLON)) {
        pm_token_t delimiter = parser->previous;
        expect1(parser, PM_TOKEN_CONSTANT, PM_ERR_CONSTANT_PATH_COLON_COLON_CONSTANT);
        node = (pm_node_t *) pm_constant_path_node_create(parser, node, &delimiter, &parser->previous);
    }

    // If there is a [ or ( that follows, then this is part of a larger pattern
    // expression. We'll parse the inner pattern here, then modify the returned
    // inner pattern with our constant path attached.
    if (!match2(parser, PM_TOKEN_BRACKET_LEFT, PM_TOKEN_PARENTHESIS_LEFT)) {
        return node;
    }

    pm_token_t opening;
    pm_token_t closing;
    pm_node_t *inner = NULL;

    if (accept1(parser, PM_TOKEN_BRACKET_LEFT)) {
        opening = parser->previous;
        accept1(parser, PM_TOKEN_NEWLINE);

        if (!accept1(parser, PM_TOKEN_BRACKET_RIGHT)) {
            inner = parse_pattern(parser, captures, PM_PARSE_PATTERN_TOP | PM_PARSE_PATTERN_MULTI, PM_ERR_PATTERN_EXPRESSION_AFTER_BRACKET, (uint16_t) (depth + 1));
            accept1(parser, PM_TOKEN_NEWLINE);
            expect1(parser, PM_TOKEN_BRACKET_RIGHT, PM_ERR_PATTERN_TERM_BRACKET);
        }

        closing = parser->previous;
    } else {
        parser_lex(parser);
        opening = parser->previous;
        accept1(parser, PM_TOKEN_NEWLINE);

        if (!accept1(parser, PM_TOKEN_PARENTHESIS_RIGHT)) {
            inner = parse_pattern(parser, captures, PM_PARSE_PATTERN_TOP | PM_PARSE_PATTERN_MULTI, PM_ERR_PATTERN_EXPRESSION_AFTER_PAREN, (uint16_t) (depth + 1));
            accept1(parser, PM_TOKEN_NEWLINE);
            expect1(parser, PM_TOKEN_PARENTHESIS_RIGHT, PM_ERR_PATTERN_TERM_PAREN);
        }

        closing = parser->previous;
    }

    if (!inner) {
        // If there was no inner pattern, then we have something like Foo() or
        // Foo[]. In that case we'll create an array pattern with no requireds.
        return (pm_node_t *) pm_array_pattern_node_constant_create(parser, node, &opening, &closing);
    }

    // Now that we have the inner pattern, check to see if it's an array, find,
    // or hash pattern. If it is, then we'll attach our constant path to it if
    // it doesn't already have a constant. If it's not one of those node types
    // or it does have a constant, then we'll create an array pattern.
    switch (PM_NODE_TYPE(inner)) {
        case PM_ARRAY_PATTERN_NODE: {
            pm_array_pattern_node_t *pattern_node = (pm_array_pattern_node_t *) inner;

            if (pattern_node->constant == NULL && pattern_node->opening_loc.start == NULL) {
                pattern_node->base.location.start = node->location.start;
                pattern_node->base.location.end = closing.end;

                pattern_node->constant = node;
                pattern_node->opening_loc = PM_LOCATION_TOKEN_VALUE(&opening);
                pattern_node->closing_loc = PM_LOCATION_TOKEN_VALUE(&closing);

                return (pm_node_t *) pattern_node;
            }

            break;
        }
        case PM_FIND_PATTERN_NODE: {
            pm_find_pattern_node_t *pattern_node = (pm_find_pattern_node_t *) inner;

            if (pattern_node->constant == NULL && pattern_node->opening_loc.start == NULL) {
                pattern_node->base.location.start = node->location.start;
                pattern_node->base.location.end = closing.end;

                pattern_node->constant = node;
                pattern_node->opening_loc = PM_LOCATION_TOKEN_VALUE(&opening);
                pattern_node->closing_loc = PM_LOCATION_TOKEN_VALUE(&closing);

                return (pm_node_t *) pattern_node;
            }

            break;
        }
        case PM_HASH_PATTERN_NODE: {
            pm_hash_pattern_node_t *pattern_node = (pm_hash_pattern_node_t *) inner;

            if (pattern_node->constant == NULL && pattern_node->opening_loc.start == NULL) {
                pattern_node->base.location.start = node->location.start;
                pattern_node->base.location.end = closing.end;

                pattern_node->constant = node;
                pattern_node->opening_loc = PM_LOCATION_TOKEN_VALUE(&opening);
                pattern_node->closing_loc = PM_LOCATION_TOKEN_VALUE(&closing);

                return (pm_node_t *) pattern_node;
            }

            break;
        }
        default:
            break;
    }

    // If we got here, then we didn't return one of the inner patterns by
    // attaching its constant. In this case we'll create an array pattern and
    // attach our constant to it.
    pm_array_pattern_node_t *pattern_node = pm_array_pattern_node_constant_create(parser, node, &opening, &closing);
    pm_array_pattern_node_requireds_append(pattern_node, inner);
    return (pm_node_t *) pattern_node;
}

/**
 * Parse a rest pattern.
 */
static pm_splat_node_t *
parse_pattern_rest(pm_parser_t *parser, pm_constant_id_list_t *captures) {
    assert(parser->previous.type == PM_TOKEN_USTAR);
    pm_token_t operator = parser->previous;
    pm_node_t *name = NULL;

    // Rest patterns don't necessarily have a name associated with them. So we
    // will check for that here. If they do, then we'll add it to the local
    // table since this pattern will cause it to become a local variable.
    if (accept1(parser, PM_TOKEN_IDENTIFIER)) {
        pm_token_t identifier = parser->previous;
        pm_constant_id_t constant_id = pm_parser_constant_id_token(parser, &identifier);

        int depth;
        if ((depth = pm_parser_local_depth_constant_id(parser, constant_id)) == -1) {
            pm_parser_local_add(parser, constant_id, identifier.start, identifier.end, 0);
        }

        parse_pattern_capture(parser, captures, constant_id, &PM_LOCATION_TOKEN_VALUE(&identifier));
        name = (pm_node_t *) pm_local_variable_target_node_create(
            parser,
            &PM_LOCATION_TOKEN_VALUE(&identifier),
            constant_id,
            (uint32_t) (depth == -1 ? 0 : depth)
        );
    }

    // Finally we can return the created node.
    return pm_splat_node_create(parser, &operator, name);
}

/**
 * Parse a keyword rest node.
 */
static pm_node_t *
parse_pattern_keyword_rest(pm_parser_t *parser, pm_constant_id_list_t *captures) {
    assert(parser->current.type == PM_TOKEN_USTAR_STAR);
    parser_lex(parser);

    pm_token_t operator = parser->previous;
    pm_node_t *value = NULL;

    if (accept1(parser, PM_TOKEN_KEYWORD_NIL)) {
        return (pm_node_t *) pm_no_keywords_parameter_node_create(parser, &operator, &parser->previous);
    }

    if (accept1(parser, PM_TOKEN_IDENTIFIER)) {
        pm_constant_id_t constant_id = pm_parser_constant_id_token(parser, &parser->previous);

        int depth;
        if ((depth = pm_parser_local_depth_constant_id(parser, constant_id)) == -1) {
            pm_parser_local_add(parser, constant_id, parser->previous.start, parser->previous.end, 0);
        }

        parse_pattern_capture(parser, captures, constant_id, &PM_LOCATION_TOKEN_VALUE(&parser->previous));
        value = (pm_node_t *) pm_local_variable_target_node_create(
            parser,
            &PM_LOCATION_TOKEN_VALUE(&parser->previous),
            constant_id,
            (uint32_t) (depth == -1 ? 0 : depth)
        );
    }

    return (pm_node_t *) pm_assoc_splat_node_create(parser, value, &operator);
}

/**
 * Check that the slice of the source given by the bounds parameters constitutes
 * a valid local variable name.
 */
static bool
pm_slice_is_valid_local(const pm_parser_t *parser, const uint8_t *start, const uint8_t *end) {
    ptrdiff_t length = end - start;
    if (length == 0) return false;

    // First ensure that it starts with a valid identifier starting character.
    size_t width = char_is_identifier_start(parser, start, end - start);
    if (width == 0) return false;

    // Next, ensure that it's not an uppercase character.
    if (parser->encoding_changed) {
        if (parser->encoding->isupper_char(start, length)) return false;
    } else {
        if (pm_encoding_utf_8_isupper_char(start, length)) return false;
    }

    // Next, iterate through all of the bytes of the string to ensure that they
    // are all valid identifier characters.
    const uint8_t *cursor = start + width;
    while ((width = char_is_identifier(parser, cursor, end - cursor))) cursor += width;
    return cursor == end;
}

/**
 * Create an implicit node for the value of a hash pattern that has omitted the
 * value. This will use an implicit local variable target.
 */
static pm_node_t *
parse_pattern_hash_implicit_value(pm_parser_t *parser, pm_constant_id_list_t *captures, pm_symbol_node_t *key) {
    const pm_location_t *value_loc = &((pm_symbol_node_t *) key)->value_loc;

    pm_constant_id_t constant_id = pm_parser_constant_id_location(parser, value_loc->start, value_loc->end);
    int depth = -1;

    if (pm_slice_is_valid_local(parser, value_loc->start, value_loc->end)) {
        depth = pm_parser_local_depth_constant_id(parser, constant_id);
    } else {
        pm_parser_err(parser, key->base.location.start, key->base.location.end, PM_ERR_PATTERN_HASH_KEY_LOCALS);

        if ((value_loc->end > value_loc->start) && ((value_loc->end[-1] == '!') || (value_loc->end[-1] == '?'))) {
            PM_PARSER_ERR_LOCATION_FORMAT(parser, value_loc, PM_ERR_INVALID_LOCAL_VARIABLE_WRITE, (int) (value_loc->end - value_loc->start), (const char *) value_loc->start);
        }
    }

    if (depth == -1) {
        pm_parser_local_add(parser, constant_id, value_loc->start, value_loc->end, 0);
    }

    parse_pattern_capture(parser, captures, constant_id, value_loc);
    pm_local_variable_target_node_t *target = pm_local_variable_target_node_create(
        parser,
        value_loc,
        constant_id,
        (uint32_t) (depth == -1 ? 0 : depth)
    );

    return (pm_node_t *) pm_implicit_node_create(parser, (pm_node_t *) target);
}

/**
 * Add a node to the list of keys for a hash pattern, and if it is a duplicate
 * then add an error to the parser.
 */
static void
parse_pattern_hash_key(pm_parser_t *parser, pm_static_literals_t *keys, pm_node_t *node) {
    if (pm_static_literals_add(&parser->newline_list, parser->start_line, keys, node, true) != NULL) {
        pm_parser_err_node(parser, node, PM_ERR_PATTERN_HASH_KEY_DUPLICATE);
    }
}

/**
 * Parse a hash pattern.
 */
static pm_hash_pattern_node_t *
parse_pattern_hash(pm_parser_t *parser, pm_constant_id_list_t *captures, pm_node_t *first_node, uint16_t depth) {
    pm_node_list_t assocs = { 0 };
    pm_static_literals_t keys = { 0 };
    pm_node_t *rest = NULL;

    switch (PM_NODE_TYPE(first_node)) {
        case PM_ASSOC_SPLAT_NODE:
        case PM_NO_KEYWORDS_PARAMETER_NODE:
            rest = first_node;
            break;
        case PM_SYMBOL_NODE: {
            if (pm_symbol_node_label_p(first_node)) {
                parse_pattern_hash_key(parser, &keys, first_node);
                pm_node_t *value;

                if (match8(parser, PM_TOKEN_COMMA, PM_TOKEN_KEYWORD_THEN, PM_TOKEN_BRACE_RIGHT, PM_TOKEN_BRACKET_RIGHT, PM_TOKEN_PARENTHESIS_RIGHT, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON, PM_TOKEN_EOF)) {
                    // Otherwise, we will create an implicit local variable
                    // target for the value.
                    value = parse_pattern_hash_implicit_value(parser, captures, (pm_symbol_node_t *) first_node);
                } else {
                    // Here we have a value for the first assoc in the list, so
                    // we will parse it now.
                    value = parse_pattern(parser, captures, PM_PARSE_PATTERN_SINGLE, PM_ERR_PATTERN_EXPRESSION_AFTER_KEY, (uint16_t) (depth + 1));
                }

                pm_token_t operator = not_provided(parser);
                pm_node_t *assoc = (pm_node_t *) pm_assoc_node_create(parser, first_node, &operator, value);

                pm_node_list_append(&assocs, assoc);
                break;
            }
        }
        PRISM_FALLTHROUGH
        default: {
            // If we get anything else, then this is an error. For this we'll
            // create a missing node for the value and create an assoc node for
            // the first node in the list.
            pm_diagnostic_id_t diag_id = PM_NODE_TYPE_P(first_node, PM_INTERPOLATED_SYMBOL_NODE) ? PM_ERR_PATTERN_HASH_KEY_INTERPOLATED : PM_ERR_PATTERN_HASH_KEY_LABEL;
            pm_parser_err_node(parser, first_node, diag_id);

            pm_token_t operator = not_provided(parser);
            pm_node_t *value = (pm_node_t *) pm_missing_node_create(parser, first_node->location.start, first_node->location.end);
            pm_node_t *assoc = (pm_node_t *) pm_assoc_node_create(parser, first_node, &operator, value);

            pm_node_list_append(&assocs, assoc);
            break;
        }
    }

    // If there are any other assocs, then we'll parse them now.
    while (accept1(parser, PM_TOKEN_COMMA)) {
        // Here we need to break to support trailing commas.
        if (match7(parser, PM_TOKEN_KEYWORD_THEN, PM_TOKEN_BRACE_RIGHT, PM_TOKEN_BRACKET_RIGHT, PM_TOKEN_PARENTHESIS_RIGHT, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON, PM_TOKEN_EOF)) {
            // Trailing commas are not allowed to follow a rest pattern.
            if (rest != NULL) {
                pm_parser_err_token(parser, &parser->current, PM_ERR_PATTERN_EXPRESSION_AFTER_REST);
            }

            break;
        }

        if (match1(parser, PM_TOKEN_USTAR_STAR)) {
            pm_node_t *assoc = parse_pattern_keyword_rest(parser, captures);

            if (rest == NULL) {
                rest = assoc;
            } else {
                pm_parser_err_node(parser, assoc, PM_ERR_PATTERN_EXPRESSION_AFTER_REST);
                pm_node_list_append(&assocs, assoc);
            }
        } else {
            pm_node_t *key;

            if (match1(parser, PM_TOKEN_STRING_BEGIN)) {
                key = parse_strings(parser, NULL, true, (uint16_t) (depth + 1));

                if (PM_NODE_TYPE_P(key, PM_INTERPOLATED_SYMBOL_NODE)) {
                    pm_parser_err_node(parser, key, PM_ERR_PATTERN_HASH_KEY_INTERPOLATED);
                } else if (!pm_symbol_node_label_p(key)) {
                    pm_parser_err_node(parser, key, PM_ERR_PATTERN_LABEL_AFTER_COMMA);
                }
            } else {
                expect1(parser, PM_TOKEN_LABEL, PM_ERR_PATTERN_LABEL_AFTER_COMMA);
                key = (pm_node_t *) pm_symbol_node_label_create(parser, &parser->previous);
            }

            parse_pattern_hash_key(parser, &keys, key);
            pm_node_t *value = NULL;

            if (match7(parser, PM_TOKEN_COMMA, PM_TOKEN_KEYWORD_THEN, PM_TOKEN_BRACE_RIGHT, PM_TOKEN_BRACKET_RIGHT, PM_TOKEN_PARENTHESIS_RIGHT, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON)) {
                value = parse_pattern_hash_implicit_value(parser, captures, (pm_symbol_node_t *) key);
            } else {
                value = parse_pattern(parser, captures, PM_PARSE_PATTERN_SINGLE, PM_ERR_PATTERN_EXPRESSION_AFTER_KEY, (uint16_t) (depth + 1));
            }

            pm_token_t operator = not_provided(parser);
            pm_node_t *assoc = (pm_node_t *) pm_assoc_node_create(parser, key, &operator, value);

            if (rest != NULL) {
                pm_parser_err_node(parser, assoc, PM_ERR_PATTERN_EXPRESSION_AFTER_REST);
            }

            pm_node_list_append(&assocs, assoc);
        }
    }

    pm_hash_pattern_node_t *node = pm_hash_pattern_node_node_list_create(parser, &assocs, rest);
    xfree(assocs.nodes);

    pm_static_literals_free(&keys);
    return node;
}

/**
 * Parse a pattern expression primitive.
 */
static pm_node_t *
parse_pattern_primitive(pm_parser_t *parser, pm_constant_id_list_t *captures, pm_diagnostic_id_t diag_id, uint16_t depth) {
    switch (parser->current.type) {
        case PM_TOKEN_IDENTIFIER:
        case PM_TOKEN_METHOD_NAME: {
            parser_lex(parser);
            pm_constant_id_t constant_id = pm_parser_constant_id_token(parser, &parser->previous);

            int depth;
            if ((depth = pm_parser_local_depth_constant_id(parser, constant_id)) == -1) {
                pm_parser_local_add(parser, constant_id, parser->previous.start, parser->previous.end, 0);
            }

            parse_pattern_capture(parser, captures, constant_id, &PM_LOCATION_TOKEN_VALUE(&parser->previous));
            return (pm_node_t *) pm_local_variable_target_node_create(
                parser,
                &PM_LOCATION_TOKEN_VALUE(&parser->previous),
                constant_id,
                (uint32_t) (depth == -1 ? 0 : depth)
            );
        }
        case PM_TOKEN_BRACKET_LEFT_ARRAY: {
            pm_token_t opening = parser->current;
            parser_lex(parser);

            if (accept1(parser, PM_TOKEN_BRACKET_RIGHT)) {
                // If we have an empty array pattern, then we'll just return a new
                // array pattern node.
                return (pm_node_t *) pm_array_pattern_node_empty_create(parser, &opening, &parser->previous);
            }

            // Otherwise, we'll parse the inner pattern, then deal with it depending
            // on the type it returns.
            pm_node_t *inner = parse_pattern(parser, captures, PM_PARSE_PATTERN_MULTI, PM_ERR_PATTERN_EXPRESSION_AFTER_BRACKET, (uint16_t) (depth + 1));

            accept1(parser, PM_TOKEN_NEWLINE);
            expect1(parser, PM_TOKEN_BRACKET_RIGHT, PM_ERR_PATTERN_TERM_BRACKET);
            pm_token_t closing = parser->previous;

            switch (PM_NODE_TYPE(inner)) {
                case PM_ARRAY_PATTERN_NODE: {
                    pm_array_pattern_node_t *pattern_node = (pm_array_pattern_node_t *) inner;
                    if (pattern_node->opening_loc.start == NULL) {
                        pattern_node->base.location.start = opening.start;
                        pattern_node->base.location.end = closing.end;

                        pattern_node->opening_loc = PM_LOCATION_TOKEN_VALUE(&opening);
                        pattern_node->closing_loc = PM_LOCATION_TOKEN_VALUE(&closing);

                        return (pm_node_t *) pattern_node;
                    }

                    break;
                }
                case PM_FIND_PATTERN_NODE: {
                    pm_find_pattern_node_t *pattern_node = (pm_find_pattern_node_t *) inner;
                    if (pattern_node->opening_loc.start == NULL) {
                        pattern_node->base.location.start = opening.start;
                        pattern_node->base.location.end = closing.end;

                        pattern_node->opening_loc = PM_LOCATION_TOKEN_VALUE(&opening);
                        pattern_node->closing_loc = PM_LOCATION_TOKEN_VALUE(&closing);

                        return (pm_node_t *) pattern_node;
                    }

                    break;
                }
                default:
                    break;
            }

            pm_array_pattern_node_t *node = pm_array_pattern_node_empty_create(parser, &opening, &closing);
            pm_array_pattern_node_requireds_append(node, inner);
            return (pm_node_t *) node;
        }
        case PM_TOKEN_BRACE_LEFT: {
            bool previous_pattern_matching_newlines = parser->pattern_matching_newlines;
            parser->pattern_matching_newlines = false;

            pm_hash_pattern_node_t *node;
            pm_token_t opening = parser->current;
            parser_lex(parser);

            if (accept1(parser, PM_TOKEN_BRACE_RIGHT)) {
                // If we have an empty hash pattern, then we'll just return a new hash
                // pattern node.
                node = pm_hash_pattern_node_empty_create(parser, &opening, &parser->previous);
            } else {
                pm_node_t *first_node;

                switch (parser->current.type) {
                    case PM_TOKEN_LABEL:
                        parser_lex(parser);
                        first_node = (pm_node_t *) pm_symbol_node_label_create(parser, &parser->previous);
                        break;
                    case PM_TOKEN_USTAR_STAR:
                        first_node = parse_pattern_keyword_rest(parser, captures);
                        break;
                    case PM_TOKEN_STRING_BEGIN:
                        first_node = parse_expression(parser, PM_BINDING_POWER_MAX, false, true, PM_ERR_PATTERN_HASH_KEY_LABEL, (uint16_t) (depth + 1));
                        break;
                    default: {
                        PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_PATTERN_HASH_KEY, pm_token_type_human(parser->current.type));
                        parser_lex(parser);

                        first_node = (pm_node_t *) pm_missing_node_create(parser, parser->previous.start, parser->previous.end);
                        break;
                    }
                }

                node = parse_pattern_hash(parser, captures, first_node, (uint16_t) (depth + 1));

                accept1(parser, PM_TOKEN_NEWLINE);
                expect1(parser, PM_TOKEN_BRACE_RIGHT, PM_ERR_PATTERN_TERM_BRACE);
                pm_token_t closing = parser->previous;

                node->base.location.start = opening.start;
                node->base.location.end = closing.end;

                node->opening_loc = PM_LOCATION_TOKEN_VALUE(&opening);
                node->closing_loc = PM_LOCATION_TOKEN_VALUE(&closing);
            }

            parser->pattern_matching_newlines = previous_pattern_matching_newlines;
            return (pm_node_t *) node;
        }
        case PM_TOKEN_UDOT_DOT:
        case PM_TOKEN_UDOT_DOT_DOT: {
            pm_token_t operator = parser->current;
            parser_lex(parser);

            // Since we have a unary range operator, we need to parse the subsequent
            // expression as the right side of the range.
            switch (parser->current.type) {
                case PM_CASE_PRIMITIVE: {
                    pm_node_t *right = parse_expression(parser, PM_BINDING_POWER_MAX, false, false, PM_ERR_PATTERN_EXPRESSION_AFTER_RANGE, (uint16_t) (depth + 1));
                    return (pm_node_t *) pm_range_node_create(parser, NULL, &operator, right);
                }
                default: {
                    pm_parser_err_token(parser, &operator, PM_ERR_PATTERN_EXPRESSION_AFTER_RANGE);
                    pm_node_t *right = (pm_node_t *) pm_missing_node_create(parser, operator.start, operator.end);
                    return (pm_node_t *) pm_range_node_create(parser, NULL, &operator, right);
                }
            }
        }
        case PM_CASE_PRIMITIVE: {
            pm_node_t *node = parse_expression(parser, PM_BINDING_POWER_MAX, false, true, diag_id, (uint16_t) (depth + 1));

            // If we found a label, we need to immediately return to the caller.
            if (pm_symbol_node_label_p(node)) return node;

            // Now that we have a primitive, we need to check if it's part of a range.
            if (accept2(parser, PM_TOKEN_DOT_DOT, PM_TOKEN_DOT_DOT_DOT)) {
                pm_token_t operator = parser->previous;

                // Now that we have the operator, we need to check if this is followed
                // by another expression. If it is, then we will create a full range
                // node. Otherwise, we'll create an endless range.
                switch (parser->current.type) {
                    case PM_CASE_PRIMITIVE: {
                        pm_node_t *right = parse_expression(parser, PM_BINDING_POWER_MAX, false, false, PM_ERR_PATTERN_EXPRESSION_AFTER_RANGE, (uint16_t) (depth + 1));
                        return (pm_node_t *) pm_range_node_create(parser, node, &operator, right);
                    }
                    default:
                        return (pm_node_t *) pm_range_node_create(parser, node, &operator, NULL);
                }
            }

            return node;
        }
        case PM_TOKEN_CARET: {
            parser_lex(parser);
            pm_token_t operator = parser->previous;

            // At this point we have a pin operator. We need to check the subsequent
            // expression to determine if it's a variable or an expression.
            switch (parser->current.type) {
                case PM_TOKEN_IDENTIFIER: {
                    parser_lex(parser);
                    pm_node_t *variable = (pm_node_t *) parse_variable(parser);

                    if (variable == NULL) {
                        PM_PARSER_ERR_TOKEN_FORMAT_CONTENT(parser, parser->previous, PM_ERR_NO_LOCAL_VARIABLE);
                        variable = (pm_node_t *) pm_local_variable_read_node_missing_create(parser, &parser->previous, 0);
                    }

                    return (pm_node_t *) pm_pinned_variable_node_create(parser, &operator, variable);
                }
                case PM_TOKEN_INSTANCE_VARIABLE: {
                    parser_lex(parser);
                    pm_node_t *variable = (pm_node_t *) pm_instance_variable_read_node_create(parser, &parser->previous);

                    return (pm_node_t *) pm_pinned_variable_node_create(parser, &operator, variable);
                }
                case PM_TOKEN_CLASS_VARIABLE: {
                    parser_lex(parser);
                    pm_node_t *variable = (pm_node_t *) pm_class_variable_read_node_create(parser, &parser->previous);

                    return (pm_node_t *) pm_pinned_variable_node_create(parser, &operator, variable);
                }
                case PM_TOKEN_GLOBAL_VARIABLE: {
                    parser_lex(parser);
                    pm_node_t *variable = (pm_node_t *) pm_global_variable_read_node_create(parser, &parser->previous);

                    return (pm_node_t *) pm_pinned_variable_node_create(parser, &operator, variable);
                }
                case PM_TOKEN_NUMBERED_REFERENCE: {
                    parser_lex(parser);
                    pm_node_t *variable = (pm_node_t *) pm_numbered_reference_read_node_create(parser, &parser->previous);

                    return (pm_node_t *) pm_pinned_variable_node_create(parser, &operator, variable);
                }
                case PM_TOKEN_BACK_REFERENCE: {
                    parser_lex(parser);
                    pm_node_t *variable = (pm_node_t *) pm_back_reference_read_node_create(parser, &parser->previous);

                    return (pm_node_t *) pm_pinned_variable_node_create(parser, &operator, variable);
                }
                case PM_TOKEN_PARENTHESIS_LEFT: {
                    bool previous_pattern_matching_newlines = parser->pattern_matching_newlines;
                    parser->pattern_matching_newlines = false;

                    pm_token_t lparen = parser->current;
                    parser_lex(parser);

                    pm_node_t *expression = parse_value_expression(parser, PM_BINDING_POWER_STATEMENT, true, false, PM_ERR_PATTERN_EXPRESSION_AFTER_PIN, (uint16_t) (depth + 1));
                    parser->pattern_matching_newlines = previous_pattern_matching_newlines;

                    accept1(parser, PM_TOKEN_NEWLINE);
                    expect1(parser, PM_TOKEN_PARENTHESIS_RIGHT, PM_ERR_PATTERN_TERM_PAREN);
                    return (pm_node_t *) pm_pinned_expression_node_create(parser, expression, &operator, &lparen, &parser->previous);
                }
                default: {
                    // If we get here, then we have a pin operator followed by something
                    // not understood. We'll create a missing node and return that.
                    pm_parser_err_token(parser, &operator, PM_ERR_PATTERN_EXPRESSION_AFTER_PIN);
                    pm_node_t *variable = (pm_node_t *) pm_missing_node_create(parser, operator.start, operator.end);
                    return (pm_node_t *) pm_pinned_variable_node_create(parser, &operator, variable);
                }
            }
        }
        case PM_TOKEN_UCOLON_COLON: {
            pm_token_t delimiter = parser->current;
            parser_lex(parser);

            expect1(parser, PM_TOKEN_CONSTANT, PM_ERR_CONSTANT_PATH_COLON_COLON_CONSTANT);
            pm_constant_path_node_t *node = pm_constant_path_node_create(parser, NULL, &delimiter, &parser->previous);

            return parse_pattern_constant_path(parser, captures, (pm_node_t *) node, (uint16_t) (depth + 1));
        }
        case PM_TOKEN_CONSTANT: {
            pm_token_t constant = parser->current;
            parser_lex(parser);

            pm_node_t *node = (pm_node_t *) pm_constant_read_node_create(parser, &constant);
            return parse_pattern_constant_path(parser, captures, node, (uint16_t) (depth + 1));
        }
        default:
            pm_parser_err_current(parser, diag_id);
            return (pm_node_t *) pm_missing_node_create(parser, parser->current.start, parser->current.end);
    }
}

/**
 * Parse any number of primitives joined by alternation and ended optionally by
 * assignment.
 */
static pm_node_t *
parse_pattern_primitives(pm_parser_t *parser, pm_constant_id_list_t *captures, pm_node_t *first_node, pm_diagnostic_id_t diag_id, uint16_t depth) {
    pm_node_t *node = first_node;

    while ((node == NULL) || accept1(parser, PM_TOKEN_PIPE)) {
        pm_token_t operator = parser->previous;

        switch (parser->current.type) {
            case PM_TOKEN_IDENTIFIER:
            case PM_TOKEN_BRACKET_LEFT_ARRAY:
            case PM_TOKEN_BRACE_LEFT:
            case PM_TOKEN_CARET:
            case PM_TOKEN_CONSTANT:
            case PM_TOKEN_UCOLON_COLON:
            case PM_TOKEN_UDOT_DOT:
            case PM_TOKEN_UDOT_DOT_DOT:
            case PM_CASE_PRIMITIVE: {
                if (node == NULL) {
                    node = parse_pattern_primitive(parser, captures, diag_id, (uint16_t) (depth + 1));
                } else {
                    pm_node_t *right = parse_pattern_primitive(parser, captures, PM_ERR_PATTERN_EXPRESSION_AFTER_PIPE, (uint16_t) (depth + 1));
                    node = (pm_node_t *) pm_alternation_pattern_node_create(parser, node, right, &operator);
                }

                break;
            }
            case PM_TOKEN_PARENTHESIS_LEFT:
            case PM_TOKEN_PARENTHESIS_LEFT_PARENTHESES: {
                pm_token_t opening = parser->current;
                parser_lex(parser);

                pm_node_t *body = parse_pattern(parser, captures, PM_PARSE_PATTERN_SINGLE, PM_ERR_PATTERN_EXPRESSION_AFTER_PAREN, (uint16_t) (depth + 1));
                accept1(parser, PM_TOKEN_NEWLINE);
                expect1(parser, PM_TOKEN_PARENTHESIS_RIGHT, PM_ERR_PATTERN_TERM_PAREN);
                pm_node_t *right = (pm_node_t *) pm_parentheses_node_create(parser, &opening, body, &parser->previous, 0);

                if (node == NULL) {
                    node = right;
                } else {
                    node = (pm_node_t *) pm_alternation_pattern_node_create(parser, node, right, &operator);
                }

                break;
            }
            default: {
                pm_parser_err_current(parser, diag_id);
                pm_node_t *right = (pm_node_t *) pm_missing_node_create(parser, parser->current.start, parser->current.end);

                if (node == NULL) {
                    node = right;
                } else {
                    node = (pm_node_t *) pm_alternation_pattern_node_create(parser, node, right, &operator);
                }

                break;
            }
        }
    }

    // If we have an =>, then we are assigning this pattern to a variable.
    // In this case we should create an assignment node.
    while (accept1(parser, PM_TOKEN_EQUAL_GREATER)) {
        pm_token_t operator = parser->previous;
        expect1(parser, PM_TOKEN_IDENTIFIER, PM_ERR_PATTERN_IDENT_AFTER_HROCKET);

        pm_constant_id_t constant_id = pm_parser_constant_id_token(parser, &parser->previous);
        int depth;

        if ((depth = pm_parser_local_depth_constant_id(parser, constant_id)) == -1) {
            pm_parser_local_add(parser, constant_id, parser->previous.start, parser->previous.end, 0);
        }

        parse_pattern_capture(parser, captures, constant_id, &PM_LOCATION_TOKEN_VALUE(&parser->previous));
        pm_local_variable_target_node_t *target = pm_local_variable_target_node_create(
            parser,
            &PM_LOCATION_TOKEN_VALUE(&parser->previous),
            constant_id,
            (uint32_t) (depth == -1 ? 0 : depth)
        );

        node = (pm_node_t *) pm_capture_pattern_node_create(parser, node, target, &operator);
    }

    return node;
}

/**
 * Parse a pattern matching expression.
 */
static pm_node_t *
parse_pattern(pm_parser_t *parser, pm_constant_id_list_t *captures, uint8_t flags, pm_diagnostic_id_t diag_id, uint16_t depth) {
    pm_node_t *node = NULL;

    bool leading_rest = false;
    bool trailing_rest = false;

    switch (parser->current.type) {
        case PM_TOKEN_LABEL: {
            parser_lex(parser);
            pm_node_t *key = (pm_node_t *) pm_symbol_node_label_create(parser, &parser->previous);
            node = (pm_node_t *) parse_pattern_hash(parser, captures, key, (uint16_t) (depth + 1));

            if (!(flags & PM_PARSE_PATTERN_TOP)) {
                pm_parser_err_node(parser, node, PM_ERR_PATTERN_HASH_IMPLICIT);
            }

            return node;
        }
        case PM_TOKEN_USTAR_STAR: {
            node = parse_pattern_keyword_rest(parser, captures);
            node = (pm_node_t *) parse_pattern_hash(parser, captures, node, (uint16_t) (depth + 1));

            if (!(flags & PM_PARSE_PATTERN_TOP)) {
                pm_parser_err_node(parser, node, PM_ERR_PATTERN_HASH_IMPLICIT);
            }

            return node;
        }
        case PM_TOKEN_STRING_BEGIN: {
            // We need special handling for string beginnings because they could
            // be dynamic symbols leading to hash patterns.
            node = parse_pattern_primitive(parser, captures, diag_id, (uint16_t) (depth + 1));

            if (pm_symbol_node_label_p(node)) {
                node = (pm_node_t *) parse_pattern_hash(parser, captures, node, (uint16_t) (depth + 1));

                if (!(flags & PM_PARSE_PATTERN_TOP)) {
                    pm_parser_err_node(parser, node, PM_ERR_PATTERN_HASH_IMPLICIT);
                }

                return node;
            }

            node = parse_pattern_primitives(parser, captures, node, diag_id, (uint16_t) (depth + 1));
            break;
        }
        case PM_TOKEN_USTAR: {
            if (flags & (PM_PARSE_PATTERN_TOP | PM_PARSE_PATTERN_MULTI)) {
                parser_lex(parser);
                node = (pm_node_t *) parse_pattern_rest(parser, captures);
                leading_rest = true;
                break;
            }
        }
        PRISM_FALLTHROUGH
        default:
            node = parse_pattern_primitives(parser, captures, NULL, diag_id, (uint16_t) (depth + 1));
            break;
    }

    // If we got a dynamic label symbol, then we need to treat it like the
    // beginning of a hash pattern.
    if (pm_symbol_node_label_p(node)) {
        return (pm_node_t *) parse_pattern_hash(parser, captures, node, (uint16_t) (depth + 1));
    }

    if ((flags & PM_PARSE_PATTERN_MULTI) && match1(parser, PM_TOKEN_COMMA)) {
        // If we have a comma, then we are now parsing either an array pattern
        // or a find pattern. We need to parse all of the patterns, put them
        // into a big list, and then determine which type of node we have.
        pm_node_list_t nodes = { 0 };
        pm_node_list_append(&nodes, node);

        // Gather up all of the patterns into the list.
        while (accept1(parser, PM_TOKEN_COMMA)) {
            // Break early here in case we have a trailing comma.
            if (match9(parser, PM_TOKEN_KEYWORD_THEN, PM_TOKEN_BRACE_RIGHT, PM_TOKEN_BRACKET_RIGHT, PM_TOKEN_PARENTHESIS_RIGHT, PM_TOKEN_SEMICOLON, PM_TOKEN_NEWLINE, PM_TOKEN_EOF,PM_TOKEN_KEYWORD_AND, PM_TOKEN_KEYWORD_OR)) {
                node = (pm_node_t *) pm_implicit_rest_node_create(parser, &parser->previous);
                pm_node_list_append(&nodes, node);
                trailing_rest = true;
                break;
            }

            if (accept1(parser, PM_TOKEN_USTAR)) {
                node = (pm_node_t *) parse_pattern_rest(parser, captures);

                // If we have already parsed a splat pattern, then this is an
                // error. We will continue to parse the rest of the patterns,
                // but we will indicate it as an error.
                if (trailing_rest) {
                    pm_parser_err_previous(parser, PM_ERR_PATTERN_REST);
                }

                trailing_rest = true;
            } else {
                node = parse_pattern_primitives(parser, captures, NULL, PM_ERR_PATTERN_EXPRESSION_AFTER_COMMA, (uint16_t) (depth + 1));
            }

            pm_node_list_append(&nodes, node);
        }

        // If the first pattern and the last pattern are rest patterns, then we
        // will call this a find pattern, regardless of how many rest patterns
        // are in between because we know we already added the appropriate
        // errors. Otherwise we will create an array pattern.
        if (leading_rest && PM_NODE_TYPE_P(nodes.nodes[nodes.size - 1], PM_SPLAT_NODE)) {
            node = (pm_node_t *) pm_find_pattern_node_create(parser, &nodes);

            if (nodes.size == 2) {
                pm_parser_err_node(parser, node, PM_ERR_PATTERN_FIND_MISSING_INNER);
            }
        } else {
            node = (pm_node_t *) pm_array_pattern_node_node_list_create(parser, &nodes);

            if (leading_rest && trailing_rest) {
                pm_parser_err_node(parser, node, PM_ERR_PATTERN_ARRAY_MULTIPLE_RESTS);
            }
        }

        xfree(nodes.nodes);
    } else if (leading_rest) {
        // Otherwise, if we parsed a single splat pattern, then we know we have
        // an array pattern, so we can go ahead and create that node.
        node = (pm_node_t *) pm_array_pattern_node_rest_create(parser, node);
    }

    return node;
}

/**
 * Incorporate a negative sign into a numeric node by subtracting 1 character
 * from its start bounds. If it's a compound node, then we will recursively
 * apply this function to its value.
 */
static inline void
parse_negative_numeric(pm_node_t *node) {
    switch (PM_NODE_TYPE(node)) {
        case PM_INTEGER_NODE: {
            pm_integer_node_t *cast = (pm_integer_node_t *) node;
            cast->base.location.start--;
            cast->value.negative = true;
            break;
        }
        case PM_FLOAT_NODE: {
            pm_float_node_t *cast = (pm_float_node_t *) node;
            cast->base.location.start--;
            cast->value = -cast->value;
            break;
        }
        case PM_RATIONAL_NODE: {
            pm_rational_node_t *cast = (pm_rational_node_t *) node;
            cast->base.location.start--;
            cast->numerator.negative = true;
            break;
        }
        case PM_IMAGINARY_NODE:
            node->location.start--;
            parse_negative_numeric(((pm_imaginary_node_t *) node)->numeric);
            break;
        default:
            assert(false && "unreachable");
            break;
    }
}

/**
 * Append an error to the error list on the parser using the given diagnostic
 * ID. This function is a specialization that handles formatting the specific
 * kind of error that is being appended.
 */
static void
pm_parser_err_prefix(pm_parser_t *parser, pm_diagnostic_id_t diag_id) {
    switch (diag_id) {
        case PM_ERR_HASH_KEY: {
            PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->previous, diag_id, pm_token_type_human(parser->previous.type));
            break;
        }
        case PM_ERR_HASH_VALUE:
        case PM_ERR_EXPECT_EXPRESSION_AFTER_OPERATOR: {
            PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, diag_id, pm_token_type_human(parser->current.type));
            break;
        }
        case PM_ERR_UNARY_RECEIVER: {
            const char *human = (parser->current.type == PM_TOKEN_EOF ? "end-of-input" : pm_token_type_human(parser->current.type));
            PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->previous, diag_id, human, parser->previous.start[0]);
            break;
        }
        case PM_ERR_UNARY_DISALLOWED:
        case PM_ERR_EXPECT_ARGUMENT: {
            PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, diag_id, pm_token_type_human(parser->current.type));
            break;
        }
        default:
            pm_parser_err_previous(parser, diag_id);
            break;
    }
}

/**
 * Ensures that the current retry token is valid in the current context.
 */
static void
parse_retry(pm_parser_t *parser, const pm_node_t *node) {
#define CONTEXT_NONE 0
#define CONTEXT_THROUGH_ENSURE 1
#define CONTEXT_THROUGH_ELSE 2

    pm_context_node_t *context_node = parser->current_context;
    int context = CONTEXT_NONE;

    while (context_node != NULL) {
        switch (context_node->context) {
            case PM_CONTEXT_BEGIN_RESCUE:
            case PM_CONTEXT_BLOCK_RESCUE:
            case PM_CONTEXT_CLASS_RESCUE:
            case PM_CONTEXT_DEF_RESCUE:
            case PM_CONTEXT_LAMBDA_RESCUE:
            case PM_CONTEXT_MODULE_RESCUE:
            case PM_CONTEXT_SCLASS_RESCUE:
            case PM_CONTEXT_DEFINED:
            case PM_CONTEXT_RESCUE_MODIFIER:
                // These are the good cases. We're allowed to have a retry here.
                return;
            case PM_CONTEXT_CLASS:
            case PM_CONTEXT_DEF:
            case PM_CONTEXT_DEF_PARAMS:
            case PM_CONTEXT_MAIN:
            case PM_CONTEXT_MODULE:
            case PM_CONTEXT_PREEXE:
            case PM_CONTEXT_SCLASS:
                // These are the bad cases. We're not allowed to have a retry in
                // these contexts.
                if (context == CONTEXT_NONE) {
                    pm_parser_err_node(parser, node, PM_ERR_INVALID_RETRY_WITHOUT_RESCUE);
                } else if (context == CONTEXT_THROUGH_ENSURE) {
                    pm_parser_err_node(parser, node, PM_ERR_INVALID_RETRY_AFTER_ENSURE);
                } else if (context == CONTEXT_THROUGH_ELSE) {
                    pm_parser_err_node(parser, node, PM_ERR_INVALID_RETRY_AFTER_ELSE);
                }
                return;
            case PM_CONTEXT_BEGIN_ELSE:
            case PM_CONTEXT_BLOCK_ELSE:
            case PM_CONTEXT_CLASS_ELSE:
            case PM_CONTEXT_DEF_ELSE:
            case PM_CONTEXT_LAMBDA_ELSE:
            case PM_CONTEXT_MODULE_ELSE:
            case PM_CONTEXT_SCLASS_ELSE:
                // These are also bad cases, but with a more specific error
                // message indicating the else.
                context = CONTEXT_THROUGH_ELSE;
                break;
            case PM_CONTEXT_BEGIN_ENSURE:
            case PM_CONTEXT_BLOCK_ENSURE:
            case PM_CONTEXT_CLASS_ENSURE:
            case PM_CONTEXT_DEF_ENSURE:
            case PM_CONTEXT_LAMBDA_ENSURE:
            case PM_CONTEXT_MODULE_ENSURE:
            case PM_CONTEXT_SCLASS_ENSURE:
                // These are also bad cases, but with a more specific error
                // message indicating the ensure.
                context = CONTEXT_THROUGH_ENSURE;
                break;
            case PM_CONTEXT_NONE:
                // This case should never happen.
                assert(false && "unreachable");
                break;
            case PM_CONTEXT_BEGIN:
            case PM_CONTEXT_BLOCK_BRACES:
            case PM_CONTEXT_BLOCK_KEYWORDS:
            case PM_CONTEXT_CASE_IN:
            case PM_CONTEXT_CASE_WHEN:
            case PM_CONTEXT_DEFAULT_PARAMS:
            case PM_CONTEXT_ELSE:
            case PM_CONTEXT_ELSIF:
            case PM_CONTEXT_EMBEXPR:
            case PM_CONTEXT_FOR_INDEX:
            case PM_CONTEXT_FOR:
            case PM_CONTEXT_IF:
            case PM_CONTEXT_LAMBDA_BRACES:
            case PM_CONTEXT_LAMBDA_DO_END:
            case PM_CONTEXT_LOOP_PREDICATE:
            case PM_CONTEXT_MULTI_TARGET:
            case PM_CONTEXT_PARENS:
            case PM_CONTEXT_POSTEXE:
            case PM_CONTEXT_PREDICATE:
            case PM_CONTEXT_TERNARY:
            case PM_CONTEXT_UNLESS:
            case PM_CONTEXT_UNTIL:
            case PM_CONTEXT_WHILE:
                // In these contexts we should continue walking up the list of
                // contexts.
                break;
        }

        context_node = context_node->prev;
    }

#undef CONTEXT_NONE
#undef CONTEXT_ENSURE
#undef CONTEXT_ELSE
}

/**
 * Ensures that the current yield token is valid in the current context.
 */
static void
parse_yield(pm_parser_t *parser, const pm_node_t *node) {
    pm_context_node_t *context_node = parser->current_context;

    while (context_node != NULL) {
        switch (context_node->context) {
            case PM_CONTEXT_DEF:
            case PM_CONTEXT_DEF_PARAMS:
            case PM_CONTEXT_DEFINED:
            case PM_CONTEXT_DEF_ENSURE:
            case PM_CONTEXT_DEF_RESCUE:
            case PM_CONTEXT_DEF_ELSE:
                // These are the good cases. We're allowed to have a block exit
                // in these contexts.
                return;
            case PM_CONTEXT_CLASS:
            case PM_CONTEXT_CLASS_ENSURE:
            case PM_CONTEXT_CLASS_RESCUE:
            case PM_CONTEXT_CLASS_ELSE:
            case PM_CONTEXT_MAIN:
            case PM_CONTEXT_MODULE:
            case PM_CONTEXT_MODULE_ENSURE:
            case PM_CONTEXT_MODULE_RESCUE:
            case PM_CONTEXT_MODULE_ELSE:
            case PM_CONTEXT_SCLASS:
            case PM_CONTEXT_SCLASS_RESCUE:
            case PM_CONTEXT_SCLASS_ENSURE:
            case PM_CONTEXT_SCLASS_ELSE:
                // These are the bad cases. We're not allowed to have a retry in
                // these contexts.
                pm_parser_err_node(parser, node, PM_ERR_INVALID_YIELD);
                return;
            case PM_CONTEXT_NONE:
                // This case should never happen.
                assert(false && "unreachable");
                break;
            case PM_CONTEXT_BEGIN:
            case PM_CONTEXT_BEGIN_ELSE:
            case PM_CONTEXT_BEGIN_ENSURE:
            case PM_CONTEXT_BEGIN_RESCUE:
            case PM_CONTEXT_BLOCK_BRACES:
            case PM_CONTEXT_BLOCK_KEYWORDS:
            case PM_CONTEXT_BLOCK_ELSE:
            case PM_CONTEXT_BLOCK_ENSURE:
            case PM_CONTEXT_BLOCK_RESCUE:
            case PM_CONTEXT_CASE_IN:
            case PM_CONTEXT_CASE_WHEN:
            case PM_CONTEXT_DEFAULT_PARAMS:
            case PM_CONTEXT_ELSE:
            case PM_CONTEXT_ELSIF:
            case PM_CONTEXT_EMBEXPR:
            case PM_CONTEXT_FOR_INDEX:
            case PM_CONTEXT_FOR:
            case PM_CONTEXT_IF:
            case PM_CONTEXT_LAMBDA_BRACES:
            case PM_CONTEXT_LAMBDA_DO_END:
            case PM_CONTEXT_LAMBDA_ELSE:
            case PM_CONTEXT_LAMBDA_ENSURE:
            case PM_CONTEXT_LAMBDA_RESCUE:
            case PM_CONTEXT_LOOP_PREDICATE:
            case PM_CONTEXT_MULTI_TARGET:
            case PM_CONTEXT_PARENS:
            case PM_CONTEXT_POSTEXE:
            case PM_CONTEXT_PREDICATE:
            case PM_CONTEXT_PREEXE:
            case PM_CONTEXT_RESCUE_MODIFIER:
            case PM_CONTEXT_TERNARY:
            case PM_CONTEXT_UNLESS:
            case PM_CONTEXT_UNTIL:
            case PM_CONTEXT_WHILE:
                // In these contexts we should continue walking up the list of
                // contexts.
                break;
        }

        context_node = context_node->prev;
    }
}

/**
 * This struct is used to pass information between the regular expression parser
 * and the error callback.
 */
typedef struct {
    /** The parser that we are parsing the regular expression for. */
    pm_parser_t *parser;

    /** The start of the regular expression. */
    const uint8_t *start;

    /** The end of the regular expression. */
    const uint8_t *end;

    /**
     * Whether or not the source of the regular expression is shared. This
     * impacts the location of error messages, because if it is shared then we
     * can use the location directly and if it is not, then we use the bounds of
     * the regular expression itself.
     */
    bool shared;
} parse_regular_expression_error_data_t;

/**
 * This callback is called when the regular expression parser encounters a
 * syntax error.
 */
static void
parse_regular_expression_error(const uint8_t *start, const uint8_t *end, const char *message, void *data) {
    parse_regular_expression_error_data_t *callback_data = (parse_regular_expression_error_data_t *) data;
    pm_location_t location;

    if (callback_data->shared) {
        location = (pm_location_t) { .start = start, .end = end };
    } else {
        location = (pm_location_t) { .start = callback_data->start, .end = callback_data->end };
    }

    PM_PARSER_ERR_FORMAT(callback_data->parser, location.start, location.end, PM_ERR_REGEXP_PARSE_ERROR, message);
}

/**
 * Parse the errors for the regular expression and add them to the parser.
 */
static void
parse_regular_expression_errors(pm_parser_t *parser, pm_regular_expression_node_t *node) {
    const pm_string_t *unescaped = &node->unescaped;
    parse_regular_expression_error_data_t error_data = {
        .parser = parser,
        .start = node->base.location.start,
        .end = node->base.location.end,
        .shared = unescaped->type == PM_STRING_SHARED
    };

    pm_regexp_parse(parser, pm_string_source(unescaped), pm_string_length(unescaped), PM_NODE_FLAG_P(node, PM_REGULAR_EXPRESSION_FLAGS_EXTENDED), NULL, NULL, parse_regular_expression_error, &error_data);
}

/**
 * Parse an expression that begins with the previous node that we just lexed.
 */
static inline pm_node_t *
parse_expression_prefix(pm_parser_t *parser, pm_binding_power_t binding_power, bool accepts_command_call, bool accepts_label, pm_diagnostic_id_t diag_id, uint16_t depth) {
    switch (parser->current.type) {
        case PM_TOKEN_BRACKET_LEFT_ARRAY: {
            parser_lex(parser);

            pm_array_node_t *array = pm_array_node_create(parser, &parser->previous);
            pm_accepts_block_stack_push(parser, true);
            bool parsed_bare_hash = false;

            while (!match2(parser, PM_TOKEN_BRACKET_RIGHT, PM_TOKEN_EOF)) {
                bool accepted_newline = accept1(parser, PM_TOKEN_NEWLINE);

                // Handle the case where we don't have a comma and we have a
                // newline followed by a right bracket.
                if (accepted_newline && match1(parser, PM_TOKEN_BRACKET_RIGHT)) {
                    break;
                }

                // Ensure that we have a comma between elements in the array.
                if (array->elements.size > 0) {
                    if (accept1(parser, PM_TOKEN_COMMA)) {
                        // If there was a comma but we also accepts a newline,
                        // then this is a syntax error.
                        if (accepted_newline) {
                            pm_parser_err_previous(parser, PM_ERR_INVALID_COMMA);
                        }
                    } else {
                        // If there was no comma, then we need to add a syntax
                        // error.
                        const uint8_t *location = parser->previous.end;
                        PM_PARSER_ERR_FORMAT(parser, location, location, PM_ERR_ARRAY_SEPARATOR, pm_token_type_human(parser->current.type));

                        parser->previous.start = location;
                        parser->previous.type = PM_TOKEN_MISSING;
                    }
                }

                // If we have a right bracket immediately following a comma,
                // this is allowed since it's a trailing comma. In this case we
                // can break out of the loop.
                if (match1(parser, PM_TOKEN_BRACKET_RIGHT)) break;

                pm_node_t *element;

                if (accept1(parser, PM_TOKEN_USTAR)) {
                    pm_token_t operator = parser->previous;
                    pm_node_t *expression = NULL;

                    if (match3(parser, PM_TOKEN_BRACKET_RIGHT, PM_TOKEN_COMMA, PM_TOKEN_EOF)) {
                        pm_parser_scope_forwarding_positionals_check(parser, &operator);
                    } else {
                        expression = parse_value_expression(parser, PM_BINDING_POWER_DEFINED, false, false, PM_ERR_ARRAY_EXPRESSION_AFTER_STAR, (uint16_t) (depth + 1));
                    }

                    element = (pm_node_t *) pm_splat_node_create(parser, &operator, expression);
                } else if (match2(parser, PM_TOKEN_LABEL, PM_TOKEN_USTAR_STAR)) {
                    if (parsed_bare_hash) {
                        pm_parser_err_current(parser, PM_ERR_EXPRESSION_BARE_HASH);
                    }

                    element = (pm_node_t *) pm_keyword_hash_node_create(parser);
                    pm_static_literals_t hash_keys = { 0 };

                    if (!match8(parser, PM_TOKEN_EOF, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON, PM_TOKEN_EOF, PM_TOKEN_BRACE_RIGHT, PM_TOKEN_BRACKET_RIGHT, PM_TOKEN_KEYWORD_DO, PM_TOKEN_PARENTHESIS_RIGHT)) {
                        parse_assocs(parser, &hash_keys, element, (uint16_t) (depth + 1));
                    }

                    pm_static_literals_free(&hash_keys);
                    parsed_bare_hash = true;
                } else {
                    element = parse_value_expression(parser, PM_BINDING_POWER_DEFINED, false, true, PM_ERR_ARRAY_EXPRESSION, (uint16_t) (depth + 1));

                    if (pm_symbol_node_label_p(element) || accept1(parser, PM_TOKEN_EQUAL_GREATER)) {
                        if (parsed_bare_hash) {
                            pm_parser_err_previous(parser, PM_ERR_EXPRESSION_BARE_HASH);
                        }

                        pm_keyword_hash_node_t *hash = pm_keyword_hash_node_create(parser);
                        pm_static_literals_t hash_keys = { 0 };
                        pm_hash_key_static_literals_add(parser, &hash_keys, element);

                        pm_token_t operator;
                        if (parser->previous.type == PM_TOKEN_EQUAL_GREATER) {
                            operator = parser->previous;
                        } else {
                            operator = not_provided(parser);
                        }

                        pm_node_t *value = parse_value_expression(parser, PM_BINDING_POWER_DEFINED, false, false, PM_ERR_HASH_VALUE, (uint16_t) (depth + 1));
                        pm_node_t *assoc = (pm_node_t *) pm_assoc_node_create(parser, element, &operator, value);
                        pm_keyword_hash_node_elements_append(hash, assoc);

                        element = (pm_node_t *) hash;
                        if (accept1(parser, PM_TOKEN_COMMA) && !match1(parser, PM_TOKEN_BRACKET_RIGHT)) {
                            parse_assocs(parser, &hash_keys, element, (uint16_t) (depth + 1));
                        }

                        pm_static_literals_free(&hash_keys);
                        parsed_bare_hash = true;
                    }
                }

                pm_array_node_elements_append(array, element);
                if (PM_NODE_TYPE_P(element, PM_MISSING_NODE)) break;
            }

            accept1(parser, PM_TOKEN_NEWLINE);

            if (!accept1(parser, PM_TOKEN_BRACKET_RIGHT)) {
                PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_ARRAY_TERM, pm_token_type_human(parser->current.type));
                parser->previous.start = parser->previous.end;
                parser->previous.type = PM_TOKEN_MISSING;
            }

            pm_array_node_close_set(array, &parser->previous);
            pm_accepts_block_stack_pop(parser);

            return (pm_node_t *) array;
        }
        case PM_TOKEN_PARENTHESIS_LEFT:
        case PM_TOKEN_PARENTHESIS_LEFT_PARENTHESES: {
            pm_token_t opening = parser->current;
            pm_node_flags_t flags = 0;

            pm_node_list_t current_block_exits = { 0 };
            pm_node_list_t *previous_block_exits = push_block_exits(parser, &current_block_exits);

            parser_lex(parser);
            while (true) {
                if (accept1(parser, PM_TOKEN_SEMICOLON)) {
                    flags |= PM_PARENTHESES_NODE_FLAGS_MULTIPLE_STATEMENTS;
                } else if (!accept1(parser, PM_TOKEN_NEWLINE)) {
                    break;
                }
            }

            // If this is the end of the file or we match a right parenthesis, then
            // we have an empty parentheses node, and we can immediately return.
            if (match2(parser, PM_TOKEN_PARENTHESIS_RIGHT, PM_TOKEN_EOF)) {
                expect1(parser, PM_TOKEN_PARENTHESIS_RIGHT, PM_ERR_EXPECT_RPAREN);

                pop_block_exits(parser, previous_block_exits);
                pm_node_list_free(&current_block_exits);

                return (pm_node_t *) pm_parentheses_node_create(parser, &opening, NULL, &parser->previous, flags);
            }

            // Otherwise, we're going to parse the first statement in the list
            // of statements within the parentheses.
            pm_accepts_block_stack_push(parser, true);
            context_push(parser, PM_CONTEXT_PARENS);
            pm_node_t *statement = parse_expression(parser, PM_BINDING_POWER_STATEMENT, true, false, PM_ERR_CANNOT_PARSE_EXPRESSION, (uint16_t) (depth + 1));
            context_pop(parser);

            // Determine if this statement is followed by a terminator. In the
            // case of a single statement, this is fine. But in the case of
            // multiple statements it's required.
            bool terminator_found = false;

            if (accept1(parser, PM_TOKEN_SEMICOLON)) {
                terminator_found = true;
                flags |= PM_PARENTHESES_NODE_FLAGS_MULTIPLE_STATEMENTS;
            } else if (accept1(parser, PM_TOKEN_NEWLINE)) {
                terminator_found = true;
            }

            if (terminator_found) {
                while (true) {
                    if (accept1(parser, PM_TOKEN_SEMICOLON)) {
                        flags |= PM_PARENTHESES_NODE_FLAGS_MULTIPLE_STATEMENTS;
                    } else if (!accept1(parser, PM_TOKEN_NEWLINE)) {
                        break;
                    }
                }
            }

            // If we hit a right parenthesis, then we're done parsing the
            // parentheses node, and we can check which kind of node we should
            // return.
            if (match1(parser, PM_TOKEN_PARENTHESIS_RIGHT)) {
                if (opening.type == PM_TOKEN_PARENTHESIS_LEFT_PARENTHESES) {
                    lex_state_set(parser, PM_LEX_STATE_ENDARG);
                }

                parser_lex(parser);
                pm_accepts_block_stack_pop(parser);

                pop_block_exits(parser, previous_block_exits);
                pm_node_list_free(&current_block_exits);

                if (PM_NODE_TYPE_P(statement, PM_MULTI_TARGET_NODE) || PM_NODE_TYPE_P(statement, PM_SPLAT_NODE)) {
                    // If we have a single statement and are ending on a right
                    // parenthesis, then we need to check if this is possibly a
                    // multiple target node.
                    pm_multi_target_node_t *multi_target;

                    if (PM_NODE_TYPE_P(statement, PM_MULTI_TARGET_NODE) && ((pm_multi_target_node_t *) statement)->lparen_loc.start == NULL) {
                        multi_target = (pm_multi_target_node_t *) statement;
                    } else {
                        multi_target = pm_multi_target_node_create(parser);
                        pm_multi_target_node_targets_append(parser, multi_target, statement);
                    }

                    pm_location_t lparen_loc = PM_LOCATION_TOKEN_VALUE(&opening);
                    pm_location_t rparen_loc = PM_LOCATION_TOKEN_VALUE(&parser->previous);

                    multi_target->lparen_loc = lparen_loc;
                    multi_target->rparen_loc = rparen_loc;
                    multi_target->base.location.start = lparen_loc.start;
                    multi_target->base.location.end = rparen_loc.end;

                    pm_node_t *result;
                    if (match1(parser, PM_TOKEN_COMMA) && (binding_power == PM_BINDING_POWER_STATEMENT)) {
                        result = parse_targets(parser, (pm_node_t *) multi_target, PM_BINDING_POWER_INDEX, (uint16_t) (depth + 1));
                        accept1(parser, PM_TOKEN_NEWLINE);
                    } else {
                        result = (pm_node_t *) multi_target;
                    }

                    if (context_p(parser, PM_CONTEXT_MULTI_TARGET)) {
                        // All set, this is explicitly allowed by the parent
                        // context.
                    } else if (context_p(parser, PM_CONTEXT_FOR_INDEX) && match1(parser, PM_TOKEN_KEYWORD_IN)) {
                        // All set, we're inside a for loop and we're parsing
                        // multiple targets.
                    } else if (binding_power != PM_BINDING_POWER_STATEMENT) {
                        // Multi targets are not allowed when it's not a
                        // statement level.
                        pm_parser_err_node(parser, result, PM_ERR_WRITE_TARGET_UNEXPECTED);
                    } else if (!match2(parser, PM_TOKEN_EQUAL, PM_TOKEN_PARENTHESIS_RIGHT)) {
                        // Multi targets must be followed by an equal sign in
                        // order to be valid (or a right parenthesis if they are
                        // nested).
                        pm_parser_err_node(parser, result, PM_ERR_WRITE_TARGET_UNEXPECTED);
                    }

                    return result;
                }

                // If we have a single statement and are ending on a right parenthesis
                // and we didn't return a multiple assignment node, then we can return a
                // regular parentheses node now.
                pm_statements_node_t *statements = pm_statements_node_create(parser);
                pm_statements_node_body_append(parser, statements, statement, true);

                return (pm_node_t *) pm_parentheses_node_create(parser, &opening, (pm_node_t *) statements, &parser->previous, flags);
            }

            // If we have more than one statement in the set of parentheses,
            // then we are going to parse all of them as a list of statements.
            // We'll do that here.
            context_push(parser, PM_CONTEXT_PARENS);
            flags |= PM_PARENTHESES_NODE_FLAGS_MULTIPLE_STATEMENTS;

            pm_statements_node_t *statements = pm_statements_node_create(parser);
            pm_statements_node_body_append(parser, statements, statement, true);

            // If we didn't find a terminator and we didn't find a right
            // parenthesis, then this is a syntax error.
            if (!terminator_found && !match1(parser, PM_TOKEN_EOF)) {
                PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_EXPECT_EOL_AFTER_STATEMENT, pm_token_type_human(parser->current.type));
            }

            // Parse each statement within the parentheses.
            while (true) {
                pm_node_t *node = parse_expression(parser, PM_BINDING_POWER_STATEMENT, true, false, PM_ERR_CANNOT_PARSE_EXPRESSION, (uint16_t) (depth + 1));
                pm_statements_node_body_append(parser, statements, node, true);

                // If we're recovering from a syntax error, then we need to stop
                // parsing the statements now.
                if (parser->recovering) {
                    // If this is the level of context where the recovery has
                    // happened, then we can mark the parser as done recovering.
                    if (match1(parser, PM_TOKEN_PARENTHESIS_RIGHT)) parser->recovering = false;
                    break;
                }

                // If we couldn't parse an expression at all, then we need to
                // bail out of the loop.
                if (PM_NODE_TYPE_P(node, PM_MISSING_NODE)) break;

                // If we successfully parsed a statement, then we are going to
                // need terminator to delimit them.
                if (accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON)) {
                    while (accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON));
                    if (match1(parser, PM_TOKEN_PARENTHESIS_RIGHT)) break;
                } else if (match1(parser, PM_TOKEN_PARENTHESIS_RIGHT)) {
                    break;
                } else if (!match1(parser, PM_TOKEN_EOF)) {
                    // If we're at the end of the file, then we're going to add
                    // an error after this for the ) anyway.
                    PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_EXPECT_EOL_AFTER_STATEMENT, pm_token_type_human(parser->current.type));
                }
            }

            context_pop(parser);
            pm_accepts_block_stack_pop(parser);
            expect1(parser, PM_TOKEN_PARENTHESIS_RIGHT, PM_ERR_EXPECT_RPAREN);

            // When we're parsing multi targets, we allow them to be followed by
            // a right parenthesis if they are at the statement level. This is
            // only possible if they are the final statement in a parentheses.
            // We need to explicitly reject that here.
            {
                pm_node_t *statement = statements->body.nodes[statements->body.size - 1];

                if (PM_NODE_TYPE_P(statement, PM_SPLAT_NODE)) {
                    pm_multi_target_node_t *multi_target = pm_multi_target_node_create(parser);
                    pm_multi_target_node_targets_append(parser, multi_target, statement);

                    statement = (pm_node_t *) multi_target;
                    statements->body.nodes[statements->body.size - 1] = statement;
                }

                if (PM_NODE_TYPE_P(statement, PM_MULTI_TARGET_NODE)) {
                    const uint8_t *offset = statement->location.end;
                    pm_token_t operator = { .type = PM_TOKEN_EQUAL, .start = offset, .end = offset };
                    pm_node_t *value = (pm_node_t *) pm_missing_node_create(parser, offset, offset);

                    statement = (pm_node_t *) pm_multi_write_node_create(parser, (pm_multi_target_node_t *) statement, &operator, value);
                    statements->body.nodes[statements->body.size - 1] = statement;

                    pm_parser_err_node(parser, statement, PM_ERR_WRITE_TARGET_UNEXPECTED);
                }
            }

            pop_block_exits(parser, previous_block_exits);
            pm_node_list_free(&current_block_exits);

            pm_void_statements_check(parser, statements, true);
            return (pm_node_t *) pm_parentheses_node_create(parser, &opening, (pm_node_t *) statements, &parser->previous, flags);
        }
        case PM_TOKEN_BRACE_LEFT: {
            // If we were passed a current_hash_keys via the parser, then that
            // means we're already parsing a hash and we want to share the set
            // of hash keys with this inner hash we're about to parse for the
            // sake of warnings. We'll set it to NULL after we grab it to make
            // sure subsequent expressions don't use it. Effectively this is a
            // way of getting around passing it to every call to
            // parse_expression.
            pm_static_literals_t *current_hash_keys = parser->current_hash_keys;
            parser->current_hash_keys = NULL;

            pm_accepts_block_stack_push(parser, true);
            parser_lex(parser);

            pm_hash_node_t *node = pm_hash_node_create(parser, &parser->previous);

            if (!match2(parser, PM_TOKEN_BRACE_RIGHT, PM_TOKEN_EOF)) {
                if (current_hash_keys != NULL) {
                    parse_assocs(parser, current_hash_keys, (pm_node_t *) node, (uint16_t) (depth + 1));
                } else {
                    pm_static_literals_t hash_keys = { 0 };
                    parse_assocs(parser, &hash_keys, (pm_node_t *) node, (uint16_t) (depth + 1));
                    pm_static_literals_free(&hash_keys);
                }

                accept1(parser, PM_TOKEN_NEWLINE);
            }

            pm_accepts_block_stack_pop(parser);
            expect1(parser, PM_TOKEN_BRACE_RIGHT, PM_ERR_HASH_TERM);
            pm_hash_node_closing_loc_set(node, &parser->previous);

            return (pm_node_t *) node;
        }
        case PM_TOKEN_CHARACTER_LITERAL: {
            parser_lex(parser);

            pm_token_t opening = parser->previous;
            opening.type = PM_TOKEN_STRING_BEGIN;
            opening.end = opening.start + 1;

            pm_token_t content = parser->previous;
            content.type = PM_TOKEN_STRING_CONTENT;
            content.start = content.start + 1;

            pm_token_t closing = not_provided(parser);
            pm_node_t *node = (pm_node_t *) pm_string_node_create_current_string(parser, &opening, &content, &closing);
            pm_node_flag_set(node, parse_unescaped_encoding(parser));

            // Characters can be followed by strings in which case they are
            // automatically concatenated.
            if (match1(parser, PM_TOKEN_STRING_BEGIN)) {
                return parse_strings(parser, node, false, (uint16_t) (depth + 1));
            }

            return node;
        }
        case PM_TOKEN_CLASS_VARIABLE: {
            parser_lex(parser);
            pm_node_t *node = (pm_node_t *) pm_class_variable_read_node_create(parser, &parser->previous);

            if (binding_power == PM_BINDING_POWER_STATEMENT && match1(parser, PM_TOKEN_COMMA)) {
                node = parse_targets_validate(parser, node, PM_BINDING_POWER_INDEX, (uint16_t) (depth + 1));
            }

            return node;
        }
        case PM_TOKEN_CONSTANT: {
            parser_lex(parser);
            pm_token_t constant = parser->previous;

            // If a constant is immediately followed by parentheses, then this is in
            // fact a method call, not a constant read.
            if (
                match1(parser, PM_TOKEN_PARENTHESIS_LEFT) ||
                (accepts_command_call && (token_begins_expression_p(parser->current.type) || match3(parser, PM_TOKEN_UAMPERSAND, PM_TOKEN_USTAR, PM_TOKEN_USTAR_STAR))) ||
                (pm_accepts_block_stack_p(parser) && match1(parser, PM_TOKEN_KEYWORD_DO)) ||
                match1(parser, PM_TOKEN_BRACE_LEFT)
            ) {
                pm_arguments_t arguments = { 0 };
                parse_arguments_list(parser, &arguments, true, accepts_command_call, (uint16_t) (depth + 1));
                return (pm_node_t *) pm_call_node_fcall_create(parser, &constant, &arguments);
            }

            pm_node_t *node = (pm_node_t *) pm_constant_read_node_create(parser, &parser->previous);

            if ((binding_power == PM_BINDING_POWER_STATEMENT) && match1(parser, PM_TOKEN_COMMA)) {
                // If we get here, then we have a comma immediately following a
                // constant, so we're going to parse this as a multiple assignment.
                node = parse_targets_validate(parser, node, PM_BINDING_POWER_INDEX, (uint16_t) (depth + 1));
            }

            return node;
        }
        case PM_TOKEN_UCOLON_COLON: {
            parser_lex(parser);
            pm_token_t delimiter = parser->previous;

            expect1(parser, PM_TOKEN_CONSTANT, PM_ERR_CONSTANT_PATH_COLON_COLON_CONSTANT);
            pm_node_t *node = (pm_node_t *) pm_constant_path_node_create(parser, NULL, &delimiter, &parser->previous);

            if ((binding_power == PM_BINDING_POWER_STATEMENT) && match1(parser, PM_TOKEN_COMMA)) {
                node = parse_targets_validate(parser, node, PM_BINDING_POWER_INDEX, (uint16_t) (depth + 1));
            }

            return node;
        }
        case PM_TOKEN_UDOT_DOT:
        case PM_TOKEN_UDOT_DOT_DOT: {
            pm_token_t operator = parser->current;
            parser_lex(parser);

            pm_node_t *right = parse_expression(parser, pm_binding_powers[operator.type].left, false, false, PM_ERR_EXPECT_EXPRESSION_AFTER_OPERATOR, (uint16_t) (depth + 1));

            // Unary .. and ... are special because these are non-associative
            // operators that can also be unary operators. In this case we need
            // to explicitly reject code that has a .. or ... that follows this
            // expression.
            if (match2(parser, PM_TOKEN_DOT_DOT, PM_TOKEN_DOT_DOT_DOT)) {
                pm_parser_err_current(parser, PM_ERR_UNEXPECTED_RANGE_OPERATOR);
            }

            return (pm_node_t *) pm_range_node_create(parser, NULL, &operator, right);
        }
        case PM_TOKEN_FLOAT:
            parser_lex(parser);
            return (pm_node_t *) pm_float_node_create(parser, &parser->previous);
        case PM_TOKEN_FLOAT_IMAGINARY:
            parser_lex(parser);
            return (pm_node_t *) pm_float_node_imaginary_create(parser, &parser->previous);
        case PM_TOKEN_FLOAT_RATIONAL:
            parser_lex(parser);
            return (pm_node_t *) pm_float_node_rational_create(parser, &parser->previous);
        case PM_TOKEN_FLOAT_RATIONAL_IMAGINARY:
            parser_lex(parser);
            return (pm_node_t *) pm_float_node_rational_imaginary_create(parser, &parser->previous);
        case PM_TOKEN_NUMBERED_REFERENCE: {
            parser_lex(parser);
            pm_node_t *node = (pm_node_t *) pm_numbered_reference_read_node_create(parser, &parser->previous);

            if (binding_power == PM_BINDING_POWER_STATEMENT && match1(parser, PM_TOKEN_COMMA)) {
                node = parse_targets_validate(parser, node, PM_BINDING_POWER_INDEX, (uint16_t) (depth + 1));
            }

            return node;
        }
        case PM_TOKEN_GLOBAL_VARIABLE: {
            parser_lex(parser);
            pm_node_t *node = (pm_node_t *) pm_global_variable_read_node_create(parser, &parser->previous);

            if (binding_power == PM_BINDING_POWER_STATEMENT && match1(parser, PM_TOKEN_COMMA)) {
                node = parse_targets_validate(parser, node, PM_BINDING_POWER_INDEX, (uint16_t) (depth + 1));
            }

            return node;
        }
        case PM_TOKEN_BACK_REFERENCE: {
            parser_lex(parser);
            pm_node_t *node = (pm_node_t *) pm_back_reference_read_node_create(parser, &parser->previous);

            if (binding_power == PM_BINDING_POWER_STATEMENT && match1(parser, PM_TOKEN_COMMA)) {
                node = parse_targets_validate(parser, node, PM_BINDING_POWER_INDEX, (uint16_t) (depth + 1));
            }

            return node;
        }
        case PM_TOKEN_IDENTIFIER:
        case PM_TOKEN_METHOD_NAME: {
            parser_lex(parser);
            pm_token_t identifier = parser->previous;
            pm_node_t *node = parse_variable_call(parser);

            if (PM_NODE_TYPE_P(node, PM_CALL_NODE)) {
                // If parse_variable_call returned with a call node, then we
                // know the identifier is not in the local table. In that case
                // we need to check if there are arguments following the
                // identifier.
                pm_call_node_t *call = (pm_call_node_t *) node;
                pm_arguments_t arguments = { 0 };

                if (parse_arguments_list(parser, &arguments, true, accepts_command_call, (uint16_t) (depth + 1))) {
                    // Since we found arguments, we need to turn off the
                    // variable call bit in the flags.
                    pm_node_flag_unset((pm_node_t *)call, PM_CALL_NODE_FLAGS_VARIABLE_CALL);

                    call->opening_loc = arguments.opening_loc;
                    call->arguments = arguments.arguments;
                    call->closing_loc = arguments.closing_loc;
                    call->block = arguments.block;

                    if (arguments.block != NULL) {
                        call->base.location.end = arguments.block->location.end;
                    } else if (arguments.closing_loc.start == NULL) {
                        if (arguments.arguments != NULL) {
                            call->base.location.end = arguments.arguments->base.location.end;
                        } else {
                            call->base.location.end = call->message_loc.end;
                        }
                    } else {
                        call->base.location.end = arguments.closing_loc.end;
                    }
                }
            } else {
                // Otherwise, we know the identifier is in the local table. This
                // can still be a method call if it is followed by arguments or
                // a block, so we need to check for that here.
                if (
                    (accepts_command_call && (token_begins_expression_p(parser->current.type) || match3(parser, PM_TOKEN_UAMPERSAND, PM_TOKEN_USTAR, PM_TOKEN_USTAR_STAR))) ||
                    (pm_accepts_block_stack_p(parser) && match1(parser, PM_TOKEN_KEYWORD_DO)) ||
                    match1(parser, PM_TOKEN_BRACE_LEFT)
                ) {
                    pm_arguments_t arguments = { 0 };
                    parse_arguments_list(parser, &arguments, true, accepts_command_call, (uint16_t) (depth + 1));
                    pm_call_node_t *fcall = pm_call_node_fcall_create(parser, &identifier, &arguments);

                    if (PM_NODE_TYPE_P(node, PM_IT_LOCAL_VARIABLE_READ_NODE)) {
                        // If we're about to convert an 'it' implicit local
                        // variable read into a method call, we need to remove
                        // it from the list of implicit local variables.
                        parse_target_implicit_parameter(parser, node);
                    } else {
                        // Otherwise, we're about to convert a regular local
                        // variable read into a method call, in which case we
                        // need to indicate that this was not a read for the
                        // purposes of warnings.
                        assert(PM_NODE_TYPE_P(node, PM_LOCAL_VARIABLE_READ_NODE));

                        if (pm_token_is_numbered_parameter(identifier.start, identifier.end)) {
                            parse_target_implicit_parameter(parser, node);
                        } else {
                            pm_local_variable_read_node_t *cast = (pm_local_variable_read_node_t *) node;
                            pm_locals_unread(&pm_parser_scope_find(parser, cast->depth)->locals, cast->name);
                        }
                    }

                    pm_node_destroy(parser, node);
                    return (pm_node_t *) fcall;
                }
            }

            if ((binding_power == PM_BINDING_POWER_STATEMENT) && match1(parser, PM_TOKEN_COMMA)) {
                node = parse_targets_validate(parser, node, PM_BINDING_POWER_INDEX, (uint16_t) (depth + 1));
            }

            return node;
        }
        case PM_TOKEN_HEREDOC_START: {
            // Here we have found a heredoc. We'll parse it and add it to the
            // list of strings.
            assert(parser->lex_modes.current->mode == PM_LEX_HEREDOC);
            pm_heredoc_lex_mode_t lex_mode = parser->lex_modes.current->as.heredoc.base;

            size_t common_whitespace = (size_t) -1;
            parser->lex_modes.current->as.heredoc.common_whitespace = &common_whitespace;

            parser_lex(parser);
            pm_token_t opening = parser->previous;

            pm_node_t *node;
            pm_node_t *part;

            if (match2(parser, PM_TOKEN_HEREDOC_END, PM_TOKEN_EOF)) {
                // If we get here, then we have an empty heredoc. We'll create
                // an empty content token and return an empty string node.
                expect1_heredoc_term(parser, lex_mode.ident_start, lex_mode.ident_length);
                pm_token_t content = parse_strings_empty_content(parser->previous.start);

                if (lex_mode.quote == PM_HEREDOC_QUOTE_BACKTICK) {
                    node = (pm_node_t *) pm_xstring_node_create_unescaped(parser, &opening, &content, &parser->previous, &PM_STRING_EMPTY);
                } else {
                    node = (pm_node_t *) pm_string_node_create_unescaped(parser, &opening, &content, &parser->previous, &PM_STRING_EMPTY);
                }

                node->location.end = opening.end;
            } else if ((part = parse_string_part(parser, (uint16_t) (depth + 1))) == NULL) {
                // If we get here, then we tried to find something in the
                // heredoc but couldn't actually parse anything, so we'll just
                // return a missing node.
                //
                // parse_string_part handles its own errors, so there is no need
                // for us to add one here.
                node = (pm_node_t *) pm_missing_node_create(parser, parser->previous.start, parser->previous.end);
            } else if (PM_NODE_TYPE_P(part, PM_STRING_NODE) && match2(parser, PM_TOKEN_HEREDOC_END, PM_TOKEN_EOF)) {
                // If we get here, then the part that we parsed was plain string
                // content and we're at the end of the heredoc, so we can return
                // just a string node with the heredoc opening and closing as
                // its opening and closing.
                pm_node_flag_set(part, parse_unescaped_encoding(parser));
                pm_string_node_t *cast = (pm_string_node_t *) part;

                cast->opening_loc = PM_LOCATION_TOKEN_VALUE(&opening);
                cast->closing_loc = PM_LOCATION_TOKEN_VALUE(&parser->current);
                cast->base.location = cast->opening_loc;

                if (lex_mode.quote == PM_HEREDOC_QUOTE_BACKTICK) {
                    assert(sizeof(pm_string_node_t) == sizeof(pm_x_string_node_t));
                    cast->base.type = PM_X_STRING_NODE;
                }

                if (lex_mode.indent == PM_HEREDOC_INDENT_TILDE && (common_whitespace != (size_t) -1) && (common_whitespace != 0)) {
                    parse_heredoc_dedent_string(&cast->unescaped, common_whitespace);
                }

                node = (pm_node_t *) cast;
                expect1_heredoc_term(parser, lex_mode.ident_start, lex_mode.ident_length);
            } else {
                // If we get here, then we have multiple parts in the heredoc,
                // so we'll need to create an interpolated string node to hold
                // them all.
                pm_node_list_t parts = { 0 };
                pm_node_list_append(&parts, part);

                while (!match2(parser, PM_TOKEN_HEREDOC_END, PM_TOKEN_EOF)) {
                    if ((part = parse_string_part(parser, (uint16_t) (depth + 1))) != NULL) {
                        pm_node_list_append(&parts, part);
                    }
                }

                // Now that we have all of the parts, create the correct type of
                // interpolated node.
                if (lex_mode.quote == PM_HEREDOC_QUOTE_BACKTICK) {
                    pm_interpolated_x_string_node_t *cast = pm_interpolated_xstring_node_create(parser, &opening, &opening);
                    cast->parts = parts;

                    expect1_heredoc_term(parser, lex_mode.ident_start, lex_mode.ident_length);
                    pm_interpolated_xstring_node_closing_set(cast, &parser->previous);

                    cast->base.location = cast->opening_loc;
                    node = (pm_node_t *) cast;
                } else {
                    pm_interpolated_string_node_t *cast = pm_interpolated_string_node_create(parser, &opening, &parts, &opening);
                    pm_node_list_free(&parts);

                    expect1_heredoc_term(parser, lex_mode.ident_start, lex_mode.ident_length);
                    pm_interpolated_string_node_closing_set(cast, &parser->previous);

                    cast->base.location = cast->opening_loc;
                    node = (pm_node_t *) cast;
                }

                // If this is a heredoc that is indented with a ~, then we need
                // to dedent each line by the common leading whitespace.
                if (lex_mode.indent == PM_HEREDOC_INDENT_TILDE && (common_whitespace != (size_t) -1) && (common_whitespace != 0)) {
                    pm_node_list_t *nodes;
                    if (lex_mode.quote == PM_HEREDOC_QUOTE_BACKTICK) {
                        nodes = &((pm_interpolated_x_string_node_t *) node)->parts;
                    } else {
                        nodes = &((pm_interpolated_string_node_t *) node)->parts;
                    }

                    parse_heredoc_dedent(parser, nodes, common_whitespace);
                }
            }

            if (match1(parser, PM_TOKEN_STRING_BEGIN)) {
                return parse_strings(parser, node, false, (uint16_t) (depth + 1));
            }

            return node;
        }
        case PM_TOKEN_INSTANCE_VARIABLE: {
            parser_lex(parser);
            pm_node_t *node = (pm_node_t *) pm_instance_variable_read_node_create(parser, &parser->previous);

            if (binding_power == PM_BINDING_POWER_STATEMENT && match1(parser, PM_TOKEN_COMMA)) {
                node = parse_targets_validate(parser, node, PM_BINDING_POWER_INDEX, (uint16_t) (depth + 1));
            }

            return node;
        }
        case PM_TOKEN_INTEGER: {
            pm_node_flags_t base = parser->integer_base;
            parser_lex(parser);
            return (pm_node_t *) pm_integer_node_create(parser, base, &parser->previous);
        }
        case PM_TOKEN_INTEGER_IMAGINARY: {
            pm_node_flags_t base = parser->integer_base;
            parser_lex(parser);
            return (pm_node_t *) pm_integer_node_imaginary_create(parser, base, &parser->previous);
        }
        case PM_TOKEN_INTEGER_RATIONAL: {
            pm_node_flags_t base = parser->integer_base;
            parser_lex(parser);
            return (pm_node_t *) pm_integer_node_rational_create(parser, base, &parser->previous);
        }
        case PM_TOKEN_INTEGER_RATIONAL_IMAGINARY: {
            pm_node_flags_t base = parser->integer_base;
            parser_lex(parser);
            return (pm_node_t *) pm_integer_node_rational_imaginary_create(parser, base, &parser->previous);
        }
        case PM_TOKEN_KEYWORD___ENCODING__:
            parser_lex(parser);
            return (pm_node_t *) pm_source_encoding_node_create(parser, &parser->previous);
        case PM_TOKEN_KEYWORD___FILE__:
            parser_lex(parser);
            return (pm_node_t *) pm_source_file_node_create(parser, &parser->previous);
        case PM_TOKEN_KEYWORD___LINE__:
            parser_lex(parser);
            return (pm_node_t *) pm_source_line_node_create(parser, &parser->previous);
        case PM_TOKEN_KEYWORD_ALIAS: {
            if (binding_power != PM_BINDING_POWER_STATEMENT) {
                pm_parser_err_current(parser, PM_ERR_STATEMENT_ALIAS);
            }

            parser_lex(parser);
            pm_token_t keyword = parser->previous;

            pm_node_t *new_name = parse_alias_argument(parser, true, (uint16_t) (depth + 1));
            pm_node_t *old_name = parse_alias_argument(parser, false, (uint16_t) (depth + 1));

            switch (PM_NODE_TYPE(new_name)) {
                case PM_BACK_REFERENCE_READ_NODE:
                case PM_NUMBERED_REFERENCE_READ_NODE:
                case PM_GLOBAL_VARIABLE_READ_NODE: {
                    if (PM_NODE_TYPE_P(old_name, PM_BACK_REFERENCE_READ_NODE) || PM_NODE_TYPE_P(old_name, PM_NUMBERED_REFERENCE_READ_NODE) || PM_NODE_TYPE_P(old_name, PM_GLOBAL_VARIABLE_READ_NODE)) {
                        if (PM_NODE_TYPE_P(old_name, PM_NUMBERED_REFERENCE_READ_NODE)) {
                            pm_parser_err_node(parser, old_name, PM_ERR_ALIAS_ARGUMENT_NUMBERED_REFERENCE);
                        }
                    } else {
                        pm_parser_err_node(parser, old_name, PM_ERR_ALIAS_ARGUMENT);
                    }

                    return (pm_node_t *) pm_alias_global_variable_node_create(parser, &keyword, new_name, old_name);
                }
                case PM_SYMBOL_NODE:
                case PM_INTERPOLATED_SYMBOL_NODE: {
                    if (!PM_NODE_TYPE_P(old_name, PM_SYMBOL_NODE) && !PM_NODE_TYPE_P(old_name, PM_INTERPOLATED_SYMBOL_NODE)) {
                        pm_parser_err_node(parser, old_name, PM_ERR_ALIAS_ARGUMENT);
                    }
                }
                PRISM_FALLTHROUGH
                default:
                    return (pm_node_t *) pm_alias_method_node_create(parser, &keyword, new_name, old_name);
            }
        }
        case PM_TOKEN_KEYWORD_CASE: {
            size_t opening_newline_index = token_newline_index(parser);
            parser_lex(parser);

            pm_token_t case_keyword = parser->previous;
            pm_node_t *predicate = NULL;

            pm_node_list_t current_block_exits = { 0 };
            pm_node_list_t *previous_block_exits = push_block_exits(parser, &current_block_exits);

            if (accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON)) {
                while (accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON));
                predicate = NULL;
            } else if (match3(parser, PM_TOKEN_KEYWORD_WHEN, PM_TOKEN_KEYWORD_IN, PM_TOKEN_KEYWORD_END)) {
                predicate = NULL;
             } else if (!token_begins_expression_p(parser->current.type)) {
                predicate = NULL;
            } else {
                predicate = parse_value_expression(parser, PM_BINDING_POWER_COMPOSITION, true, false, PM_ERR_CASE_EXPRESSION_AFTER_CASE, (uint16_t) (depth + 1));
                while (accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON));
            }

            if (match1(parser, PM_TOKEN_KEYWORD_END)) {
                parser_warn_indentation_mismatch(parser, opening_newline_index, &case_keyword, false, false);
                parser_lex(parser);

                pop_block_exits(parser, previous_block_exits);
                pm_node_list_free(&current_block_exits);

                pm_parser_err_token(parser, &case_keyword, PM_ERR_CASE_MISSING_CONDITIONS);
                return (pm_node_t *) pm_case_node_create(parser, &case_keyword, predicate, &parser->previous);
            }

            // At this point we can create a case node, though we don't yet know
            // if it is a case-in or case-when node.
            pm_token_t end_keyword = not_provided(parser);
            pm_node_t *node;

            if (match1(parser, PM_TOKEN_KEYWORD_WHEN)) {
                pm_case_node_t *case_node = pm_case_node_create(parser, &case_keyword, predicate, &end_keyword);
                pm_static_literals_t literals = { 0 };

                // At this point we've seen a when keyword, so we know this is a
                // case-when node. We will continue to parse the when nodes
                // until we hit the end of the list.
                while (match1(parser, PM_TOKEN_KEYWORD_WHEN)) {
                    parser_warn_indentation_mismatch(parser, opening_newline_index, &case_keyword, false, true);
                    parser_lex(parser);

                    pm_token_t when_keyword = parser->previous;
                    pm_when_node_t *when_node = pm_when_node_create(parser, &when_keyword);

                    do {
                        if (accept1(parser, PM_TOKEN_USTAR)) {
                            pm_token_t operator = parser->previous;
                            pm_node_t *expression = parse_value_expression(parser, PM_BINDING_POWER_DEFINED, false, false, PM_ERR_EXPECT_EXPRESSION_AFTER_STAR, (uint16_t) (depth + 1));

                            pm_splat_node_t *splat_node = pm_splat_node_create(parser, &operator, expression);
                            pm_when_node_conditions_append(when_node, (pm_node_t *) splat_node);

                            if (PM_NODE_TYPE_P(expression, PM_MISSING_NODE)) break;
                        } else {
                            pm_node_t *condition = parse_value_expression(parser, PM_BINDING_POWER_DEFINED, false, false, PM_ERR_CASE_EXPRESSION_AFTER_WHEN, (uint16_t) (depth + 1));
                            pm_when_node_conditions_append(when_node, condition);

                            // If we found a missing node, then this is a syntax
                            // error and we should stop looping.
                            if (PM_NODE_TYPE_P(condition, PM_MISSING_NODE)) break;

                            // If this is a string node, then we need to mark it
                            // as frozen because when clause strings are frozen.
                            if (PM_NODE_TYPE_P(condition, PM_STRING_NODE)) {
                                pm_node_flag_set(condition, PM_STRING_FLAGS_FROZEN | PM_NODE_FLAG_STATIC_LITERAL);
                            } else if (PM_NODE_TYPE_P(condition, PM_SOURCE_FILE_NODE)) {
                                pm_node_flag_set(condition, PM_NODE_FLAG_STATIC_LITERAL);
                            }

                            pm_when_clause_static_literals_add(parser, &literals, condition);
                        }
                    } while (accept1(parser, PM_TOKEN_COMMA));

                    if (accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON)) {
                        if (accept1(parser, PM_TOKEN_KEYWORD_THEN)) {
                            pm_when_node_then_keyword_loc_set(when_node, &parser->previous);
                        }
                    } else {
                        expect1(parser, PM_TOKEN_KEYWORD_THEN, PM_ERR_EXPECT_WHEN_DELIMITER);
                        pm_when_node_then_keyword_loc_set(when_node, &parser->previous);
                    }

                    if (!match3(parser, PM_TOKEN_KEYWORD_WHEN, PM_TOKEN_KEYWORD_ELSE, PM_TOKEN_KEYWORD_END)) {
                        pm_statements_node_t *statements = parse_statements(parser, PM_CONTEXT_CASE_WHEN, (uint16_t) (depth + 1));
                        if (statements != NULL) {
                            pm_when_node_statements_set(when_node, statements);
                        }
                    }

                    pm_case_node_condition_append(case_node, (pm_node_t *) when_node);
                }

                // If we didn't parse any conditions (in or when) then we need
                // to indicate that we have an error.
                if (case_node->conditions.size == 0) {
                    pm_parser_err_token(parser, &case_keyword, PM_ERR_CASE_MISSING_CONDITIONS);
                }

                pm_static_literals_free(&literals);
                node = (pm_node_t *) case_node;
            } else {
                pm_case_match_node_t *case_node = pm_case_match_node_create(parser, &case_keyword, predicate, &end_keyword);

                // If this is a case-match node (i.e., it is a pattern matching
                // case statement) then we must have a predicate.
                if (predicate == NULL) {
                    pm_parser_err_token(parser, &case_keyword, PM_ERR_CASE_MATCH_MISSING_PREDICATE);
                }

                // At this point we expect that we're parsing a case-in node. We
                // will continue to parse the in nodes until we hit the end of
                // the list.
                while (match1(parser, PM_TOKEN_KEYWORD_IN)) {
                    parser_warn_indentation_mismatch(parser, opening_newline_index, &case_keyword, false, true);

                    bool previous_pattern_matching_newlines = parser->pattern_matching_newlines;
                    parser->pattern_matching_newlines = true;

                    lex_state_set(parser, PM_LEX_STATE_BEG | PM_LEX_STATE_LABEL);
                    parser->command_start = false;
                    parser_lex(parser);

                    pm_token_t in_keyword = parser->previous;

                    pm_constant_id_list_t captures = { 0 };
                    pm_node_t *pattern = parse_pattern(parser, &captures, PM_PARSE_PATTERN_TOP | PM_PARSE_PATTERN_MULTI, PM_ERR_PATTERN_EXPRESSION_AFTER_IN, (uint16_t) (depth + 1));

                    parser->pattern_matching_newlines = previous_pattern_matching_newlines;
                    pm_constant_id_list_free(&captures);

                    // Since we're in the top-level of the case-in node we need
                    // to check for guard clauses in the form of `if` or
                    // `unless` statements.
                    if (accept1(parser, PM_TOKEN_KEYWORD_IF_MODIFIER)) {
                        pm_token_t keyword = parser->previous;
                        pm_node_t *predicate = parse_value_expression(parser, PM_BINDING_POWER_COMPOSITION, true, false, PM_ERR_CONDITIONAL_IF_PREDICATE, (uint16_t) (depth + 1));
                        pattern = (pm_node_t *) pm_if_node_modifier_create(parser, pattern, &keyword, predicate);
                    } else if (accept1(parser, PM_TOKEN_KEYWORD_UNLESS_MODIFIER)) {
                        pm_token_t keyword = parser->previous;
                        pm_node_t *predicate = parse_value_expression(parser, PM_BINDING_POWER_COMPOSITION, true, false, PM_ERR_CONDITIONAL_UNLESS_PREDICATE, (uint16_t) (depth + 1));
                        pattern = (pm_node_t *) pm_unless_node_modifier_create(parser, pattern, &keyword, predicate);
                    }

                    // Now we need to check for the terminator of the in node's
                    // pattern. It can be a newline or semicolon optionally
                    // followed by a `then` keyword.
                    pm_token_t then_keyword;
                    if (accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON)) {
                        if (accept1(parser, PM_TOKEN_KEYWORD_THEN)) {
                            then_keyword = parser->previous;
                        } else {
                            then_keyword = not_provided(parser);
                        }
                    } else {
                        expect1(parser, PM_TOKEN_KEYWORD_THEN, PM_ERR_EXPECT_IN_DELIMITER);
                        then_keyword = parser->previous;
                    }

                    // Now we can actually parse the statements associated with
                    // the in node.
                    pm_statements_node_t *statements;
                    if (match3(parser, PM_TOKEN_KEYWORD_IN, PM_TOKEN_KEYWORD_ELSE, PM_TOKEN_KEYWORD_END)) {
                        statements = NULL;
                    } else {
                        statements = parse_statements(parser, PM_CONTEXT_CASE_IN, (uint16_t) (depth + 1));
                    }

                    // Now that we have the full pattern and statements, we can
                    // create the node and attach it to the case node.
                    pm_node_t *condition = (pm_node_t *) pm_in_node_create(parser, pattern, statements, &in_keyword, &then_keyword);
                    pm_case_match_node_condition_append(case_node, condition);
                }

                // If we didn't parse any conditions (in or when) then we need
                // to indicate that we have an error.
                if (case_node->conditions.size == 0) {
                    pm_parser_err_token(parser, &case_keyword, PM_ERR_CASE_MISSING_CONDITIONS);
                }

                node = (pm_node_t *) case_node;
            }

            accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON);
            if (accept1(parser, PM_TOKEN_KEYWORD_ELSE)) {
                pm_token_t else_keyword = parser->previous;
                pm_else_node_t *else_node;

                if (!match1(parser, PM_TOKEN_KEYWORD_END)) {
                    else_node = pm_else_node_create(parser, &else_keyword, parse_statements(parser, PM_CONTEXT_ELSE, (uint16_t) (depth + 1)), &parser->current);
                } else {
                    else_node = pm_else_node_create(parser, &else_keyword, NULL, &parser->current);
                }

                if (PM_NODE_TYPE_P(node, PM_CASE_NODE)) {
                    pm_case_node_else_clause_set((pm_case_node_t *) node, else_node);
                } else {
                    pm_case_match_node_else_clause_set((pm_case_match_node_t *) node, else_node);
                }
            }

            parser_warn_indentation_mismatch(parser, opening_newline_index, &case_keyword, false, false);
            expect1(parser, PM_TOKEN_KEYWORD_END, PM_ERR_CASE_TERM);

            if (PM_NODE_TYPE_P(node, PM_CASE_NODE)) {
                pm_case_node_end_keyword_loc_set((pm_case_node_t *) node, &parser->previous);
            } else {
                pm_case_match_node_end_keyword_loc_set((pm_case_match_node_t *) node, &parser->previous);
            }

            pop_block_exits(parser, previous_block_exits);
            pm_node_list_free(&current_block_exits);

            return node;
        }
        case PM_TOKEN_KEYWORD_BEGIN: {
            size_t opening_newline_index = token_newline_index(parser);
            parser_lex(parser);

            pm_token_t begin_keyword = parser->previous;
            accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON);

            pm_node_list_t current_block_exits = { 0 };
            pm_node_list_t *previous_block_exits = push_block_exits(parser, &current_block_exits);
            pm_statements_node_t *begin_statements = NULL;

            if (!match4(parser, PM_TOKEN_KEYWORD_RESCUE, PM_TOKEN_KEYWORD_ENSURE, PM_TOKEN_KEYWORD_ELSE, PM_TOKEN_KEYWORD_END)) {
                pm_accepts_block_stack_push(parser, true);
                begin_statements = parse_statements(parser, PM_CONTEXT_BEGIN, (uint16_t) (depth + 1));
                pm_accepts_block_stack_pop(parser);
                accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON);
            }

            pm_begin_node_t *begin_node = pm_begin_node_create(parser, &begin_keyword, begin_statements);
            parse_rescues(parser, opening_newline_index, &begin_keyword, begin_node, PM_RESCUES_BEGIN, (uint16_t) (depth + 1));
            expect1(parser, PM_TOKEN_KEYWORD_END, PM_ERR_BEGIN_TERM);

            begin_node->base.location.end = parser->previous.end;
            pm_begin_node_end_keyword_set(begin_node, &parser->previous);

            pop_block_exits(parser, previous_block_exits);
            pm_node_list_free(&current_block_exits);

            return (pm_node_t *) begin_node;
        }
        case PM_TOKEN_KEYWORD_BEGIN_UPCASE: {
            pm_node_list_t current_block_exits = { 0 };
            pm_node_list_t *previous_block_exits = push_block_exits(parser, &current_block_exits);

            if (binding_power != PM_BINDING_POWER_STATEMENT) {
                pm_parser_err_current(parser, PM_ERR_STATEMENT_PREEXE_BEGIN);
            }

            parser_lex(parser);
            pm_token_t keyword = parser->previous;

            expect1(parser, PM_TOKEN_BRACE_LEFT, PM_ERR_BEGIN_UPCASE_BRACE);
            pm_token_t opening = parser->previous;
            pm_statements_node_t *statements = parse_statements(parser, PM_CONTEXT_PREEXE, (uint16_t) (depth + 1));

            expect1(parser, PM_TOKEN_BRACE_RIGHT, PM_ERR_BEGIN_UPCASE_TERM);
            pm_context_t context = parser->current_context->context;
            if ((context != PM_CONTEXT_MAIN) && (context != PM_CONTEXT_PREEXE)) {
                pm_parser_err_token(parser, &keyword, PM_ERR_BEGIN_UPCASE_TOPLEVEL);
            }

            flush_block_exits(parser, previous_block_exits);
            pm_node_list_free(&current_block_exits);

            return (pm_node_t *) pm_pre_execution_node_create(parser, &keyword, &opening, statements, &parser->previous);
        }
        case PM_TOKEN_KEYWORD_BREAK:
        case PM_TOKEN_KEYWORD_NEXT:
        case PM_TOKEN_KEYWORD_RETURN: {
            parser_lex(parser);

            pm_token_t keyword = parser->previous;
            pm_arguments_t arguments = { 0 };

            if (
                token_begins_expression_p(parser->current.type) ||
                match2(parser, PM_TOKEN_USTAR, PM_TOKEN_USTAR_STAR)
            ) {
                pm_binding_power_t binding_power = pm_binding_powers[parser->current.type].left;

                if (binding_power == PM_BINDING_POWER_UNSET || binding_power >= PM_BINDING_POWER_RANGE) {
                    parse_arguments(parser, &arguments, false, PM_TOKEN_EOF, (uint16_t) (depth + 1));
                }
            }

            switch (keyword.type) {
                case PM_TOKEN_KEYWORD_BREAK: {
                    pm_node_t *node = (pm_node_t *) pm_break_node_create(parser, &keyword, arguments.arguments);
                    if (!parser->partial_script) parse_block_exit(parser, node);
                    return node;
                }
                case PM_TOKEN_KEYWORD_NEXT: {
                    pm_node_t *node = (pm_node_t *) pm_next_node_create(parser, &keyword, arguments.arguments);
                    if (!parser->partial_script) parse_block_exit(parser, node);
                    return node;
                }
                case PM_TOKEN_KEYWORD_RETURN: {
                    pm_node_t *node = (pm_node_t *) pm_return_node_create(parser, &keyword, arguments.arguments);
                    parse_return(parser, node);
                    return node;
                }
                default:
                    assert(false && "unreachable");
                    return (pm_node_t *) pm_missing_node_create(parser, parser->previous.start, parser->previous.end);
            }
        }
        case PM_TOKEN_KEYWORD_SUPER: {
            parser_lex(parser);

            pm_token_t keyword = parser->previous;
            pm_arguments_t arguments = { 0 };
            parse_arguments_list(parser, &arguments, true, accepts_command_call, (uint16_t) (depth + 1));

            if (
                arguments.opening_loc.start == NULL &&
                arguments.arguments == NULL &&
                ((arguments.block == NULL) || PM_NODE_TYPE_P(arguments.block, PM_BLOCK_NODE))
            ) {
                return (pm_node_t *) pm_forwarding_super_node_create(parser, &keyword, &arguments);
            }

            return (pm_node_t *) pm_super_node_create(parser, &keyword, &arguments);
        }
        case PM_TOKEN_KEYWORD_YIELD: {
            parser_lex(parser);

            pm_token_t keyword = parser->previous;
            pm_arguments_t arguments = { 0 };
            parse_arguments_list(parser, &arguments, false, accepts_command_call, (uint16_t) (depth + 1));

            // It's possible that we've parsed a block argument through our
            // call to parse_arguments_list. If we found one, we should mark it
            // as invalid and destroy it, as we don't have a place for it on the
            // yield node.
            if (arguments.block != NULL) {
                pm_parser_err_node(parser, arguments.block, PM_ERR_UNEXPECTED_BLOCK_ARGUMENT);
                pm_node_destroy(parser, arguments.block);
                arguments.block = NULL;
            }

            pm_node_t *node = (pm_node_t *) pm_yield_node_create(parser, &keyword, &arguments.opening_loc, arguments.arguments, &arguments.closing_loc);
            if (!parser->parsing_eval && !parser->partial_script) parse_yield(parser, node);

            return node;
        }
        case PM_TOKEN_KEYWORD_CLASS: {
            size_t opening_newline_index = token_newline_index(parser);
            parser_lex(parser);

            pm_token_t class_keyword = parser->previous;
            pm_do_loop_stack_push(parser, false);

            pm_node_list_t current_block_exits = { 0 };
            pm_node_list_t *previous_block_exits = push_block_exits(parser, &current_block_exits);

            if (accept1(parser, PM_TOKEN_LESS_LESS)) {
                pm_token_t operator = parser->previous;
                pm_node_t *expression = parse_value_expression(parser, PM_BINDING_POWER_COMPOSITION, true, false, PM_ERR_EXPECT_EXPRESSION_AFTER_LESS_LESS, (uint16_t) (depth + 1));

                pm_parser_scope_push(parser, true);
                if (!match2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON)) {
                    PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_EXPECT_SINGLETON_CLASS_DELIMITER, pm_token_type_human(parser->current.type));
                }

                pm_node_t *statements = NULL;
                if (!match4(parser, PM_TOKEN_KEYWORD_RESCUE, PM_TOKEN_KEYWORD_ENSURE, PM_TOKEN_KEYWORD_ELSE, PM_TOKEN_KEYWORD_END)) {
                    pm_accepts_block_stack_push(parser, true);
                    statements = (pm_node_t *) parse_statements(parser, PM_CONTEXT_SCLASS, (uint16_t) (depth + 1));
                    pm_accepts_block_stack_pop(parser);
                }

                if (match2(parser, PM_TOKEN_KEYWORD_RESCUE, PM_TOKEN_KEYWORD_ENSURE)) {
                    assert(statements == NULL || PM_NODE_TYPE_P(statements, PM_STATEMENTS_NODE));
                    statements = (pm_node_t *) parse_rescues_implicit_begin(parser, opening_newline_index, &class_keyword, class_keyword.start, (pm_statements_node_t *) statements, PM_RESCUES_SCLASS, (uint16_t) (depth + 1));
                } else {
                    parser_warn_indentation_mismatch(parser, opening_newline_index, &class_keyword, false, false);
                }

                expect1(parser, PM_TOKEN_KEYWORD_END, PM_ERR_CLASS_TERM);

                pm_constant_id_list_t locals;
                pm_locals_order(parser, &parser->current_scope->locals, &locals, false);

                pm_parser_scope_pop(parser);
                pm_do_loop_stack_pop(parser);

                flush_block_exits(parser, previous_block_exits);
                pm_node_list_free(&current_block_exits);

                return (pm_node_t *) pm_singleton_class_node_create(parser, &locals, &class_keyword, &operator, expression, statements, &parser->previous);
            }

            pm_node_t *constant_path = parse_expression(parser, PM_BINDING_POWER_INDEX, false, false, PM_ERR_CLASS_NAME, (uint16_t) (depth + 1));
            pm_token_t name = parser->previous;
            if (name.type != PM_TOKEN_CONSTANT) {
                pm_parser_err_token(parser, &name, PM_ERR_CLASS_NAME);
            }

            pm_token_t inheritance_operator;
            pm_node_t *superclass;

            if (match1(parser, PM_TOKEN_LESS)) {
                inheritance_operator = parser->current;
                lex_state_set(parser, PM_LEX_STATE_BEG);

                parser->command_start = true;
                parser_lex(parser);

                superclass = parse_value_expression(parser, PM_BINDING_POWER_COMPOSITION, true, false, PM_ERR_CLASS_SUPERCLASS, (uint16_t) (depth + 1));
            } else {
                inheritance_operator = not_provided(parser);
                superclass = NULL;
            }

            pm_parser_scope_push(parser, true);

            if (inheritance_operator.type != PM_TOKEN_NOT_PROVIDED) {
                expect2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON, PM_ERR_CLASS_UNEXPECTED_END);
            } else {
                accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON);
            }
            pm_node_t *statements = NULL;

            if (!match4(parser, PM_TOKEN_KEYWORD_RESCUE, PM_TOKEN_KEYWORD_ENSURE, PM_TOKEN_KEYWORD_ELSE, PM_TOKEN_KEYWORD_END)) {
                pm_accepts_block_stack_push(parser, true);
                statements = (pm_node_t *) parse_statements(parser, PM_CONTEXT_CLASS, (uint16_t) (depth + 1));
                pm_accepts_block_stack_pop(parser);
            }

            if (match2(parser, PM_TOKEN_KEYWORD_RESCUE, PM_TOKEN_KEYWORD_ENSURE)) {
                assert(statements == NULL || PM_NODE_TYPE_P(statements, PM_STATEMENTS_NODE));
                statements = (pm_node_t *) parse_rescues_implicit_begin(parser, opening_newline_index, &class_keyword, class_keyword.start, (pm_statements_node_t *) statements, PM_RESCUES_CLASS, (uint16_t) (depth + 1));
            } else {
                parser_warn_indentation_mismatch(parser, opening_newline_index, &class_keyword, false, false);
            }

            expect1(parser, PM_TOKEN_KEYWORD_END, PM_ERR_CLASS_TERM);

            if (context_def_p(parser)) {
                pm_parser_err_token(parser, &class_keyword, PM_ERR_CLASS_IN_METHOD);
            }

            pm_constant_id_list_t locals;
            pm_locals_order(parser, &parser->current_scope->locals, &locals, false);

            pm_parser_scope_pop(parser);
            pm_do_loop_stack_pop(parser);

            if (!PM_NODE_TYPE_P(constant_path, PM_CONSTANT_PATH_NODE) && !(PM_NODE_TYPE_P(constant_path, PM_CONSTANT_READ_NODE))) {
                pm_parser_err_node(parser, constant_path, PM_ERR_CLASS_NAME);
            }

            pop_block_exits(parser, previous_block_exits);
            pm_node_list_free(&current_block_exits);

            return (pm_node_t *) pm_class_node_create(parser, &locals, &class_keyword, constant_path, &name, &inheritance_operator, superclass, statements, &parser->previous);
        }
        case PM_TOKEN_KEYWORD_DEF: {
            pm_node_list_t current_block_exits = { 0 };
            pm_node_list_t *previous_block_exits = push_block_exits(parser, &current_block_exits);

            pm_token_t def_keyword = parser->current;
            size_t opening_newline_index = token_newline_index(parser);

            pm_node_t *receiver = NULL;
            pm_token_t operator = not_provided(parser);
            pm_token_t name;

            // This context is necessary for lexing `...` in a bare params
            // correctly. It must be pushed before lexing the first param, so it
            // is here.
            context_push(parser, PM_CONTEXT_DEF_PARAMS);
            parser_lex(parser);

            // This will be false if the method name is not a valid identifier
            // but could be followed by an operator.
            bool valid_name = true;

            switch (parser->current.type) {
                case PM_CASE_OPERATOR:
                    pm_parser_scope_push(parser, true);
                    lex_state_set(parser, PM_LEX_STATE_ENDFN);
                    parser_lex(parser);

                    name = parser->previous;
                    break;
                case PM_TOKEN_IDENTIFIER: {
                    parser_lex(parser);

                    if (match2(parser, PM_TOKEN_DOT, PM_TOKEN_COLON_COLON)) {
                        receiver = parse_variable_call(parser);

                        pm_parser_scope_push(parser, true);
                        lex_state_set(parser, PM_LEX_STATE_FNAME);
                        parser_lex(parser);

                        operator = parser->previous;
                        name = parse_method_definition_name(parser);
                    } else {
                        pm_refute_numbered_parameter(parser, parser->previous.start, parser->previous.end);
                        pm_parser_scope_push(parser, true);

                        name = parser->previous;
                    }

                    break;
                }
                case PM_TOKEN_INSTANCE_VARIABLE:
                case PM_TOKEN_CLASS_VARIABLE:
                case PM_TOKEN_GLOBAL_VARIABLE:
                    valid_name = false;
                    PRISM_FALLTHROUGH
                case PM_TOKEN_CONSTANT:
                case PM_TOKEN_KEYWORD_NIL:
                case PM_TOKEN_KEYWORD_SELF:
                case PM_TOKEN_KEYWORD_TRUE:
                case PM_TOKEN_KEYWORD_FALSE:
                case PM_TOKEN_KEYWORD___FILE__:
                case PM_TOKEN_KEYWORD___LINE__:
                case PM_TOKEN_KEYWORD___ENCODING__: {
                    pm_parser_scope_push(parser, true);
                    parser_lex(parser);

                    pm_token_t identifier = parser->previous;

                    if (match2(parser, PM_TOKEN_DOT, PM_TOKEN_COLON_COLON)) {
                        lex_state_set(parser, PM_LEX_STATE_FNAME);
                        parser_lex(parser);
                        operator = parser->previous;

                        switch (identifier.type) {
                            case PM_TOKEN_CONSTANT:
                                receiver = (pm_node_t *) pm_constant_read_node_create(parser, &identifier);
                                break;
                            case PM_TOKEN_INSTANCE_VARIABLE:
                                receiver = (pm_node_t *) pm_instance_variable_read_node_create(parser, &identifier);
                                break;
                            case PM_TOKEN_CLASS_VARIABLE:
                                receiver = (pm_node_t *) pm_class_variable_read_node_create(parser, &identifier);
                                break;
                            case PM_TOKEN_GLOBAL_VARIABLE:
                                receiver = (pm_node_t *) pm_global_variable_read_node_create(parser, &identifier);
                                break;
                            case PM_TOKEN_KEYWORD_NIL:
                                receiver = (pm_node_t *) pm_nil_node_create(parser, &identifier);
                                break;
                            case PM_TOKEN_KEYWORD_SELF:
                                receiver = (pm_node_t *) pm_self_node_create(parser, &identifier);
                                break;
                            case PM_TOKEN_KEYWORD_TRUE:
                                receiver = (pm_node_t *) pm_true_node_create(parser, &identifier);
                                break;
                            case PM_TOKEN_KEYWORD_FALSE:
                                receiver = (pm_node_t *) pm_false_node_create(parser, &identifier);
                                break;
                            case PM_TOKEN_KEYWORD___FILE__:
                                receiver = (pm_node_t *) pm_source_file_node_create(parser, &identifier);
                                break;
                            case PM_TOKEN_KEYWORD___LINE__:
                                receiver = (pm_node_t *) pm_source_line_node_create(parser, &identifier);
                                break;
                            case PM_TOKEN_KEYWORD___ENCODING__:
                                receiver = (pm_node_t *) pm_source_encoding_node_create(parser, &identifier);
                                break;
                            default:
                                break;
                        }

                        name = parse_method_definition_name(parser);
                    } else {
                        if (!valid_name) {
                            PM_PARSER_ERR_TOKEN_FORMAT(parser, identifier, PM_ERR_DEF_NAME, pm_token_type_human(identifier.type));
                        }

                        name = identifier;
                    }
                    break;
                }
                case PM_TOKEN_PARENTHESIS_LEFT: {
                    // The current context is `PM_CONTEXT_DEF_PARAMS`, however
                    // the inner expression of this parenthesis should not be
                    // processed under this context. Thus, the context is popped
                    // here.
                    context_pop(parser);
                    parser_lex(parser);

                    pm_token_t lparen = parser->previous;
                    pm_node_t *expression = parse_value_expression(parser, PM_BINDING_POWER_COMPOSITION, true, false, PM_ERR_DEF_RECEIVER, (uint16_t) (depth + 1));

                    accept1(parser, PM_TOKEN_NEWLINE);
                    expect1(parser, PM_TOKEN_PARENTHESIS_RIGHT, PM_ERR_EXPECT_RPAREN);
                    pm_token_t rparen = parser->previous;

                    lex_state_set(parser, PM_LEX_STATE_FNAME);
                    expect2(parser, PM_TOKEN_DOT, PM_TOKEN_COLON_COLON, PM_ERR_DEF_RECEIVER_TERM);

                    operator = parser->previous;
                    receiver = (pm_node_t *) pm_parentheses_node_create(parser, &lparen, expression, &rparen, 0);

                    // To push `PM_CONTEXT_DEF_PARAMS` again is for the same
                    // reason as described the above.
                    pm_parser_scope_push(parser, true);
                    context_push(parser, PM_CONTEXT_DEF_PARAMS);
                    name = parse_method_definition_name(parser);
                    break;
                }
                default:
                    pm_parser_scope_push(parser, true);
                    name = parse_method_definition_name(parser);
                    break;
            }

            pm_token_t lparen;
            pm_token_t rparen;
            pm_parameters_node_t *params;

            switch (parser->current.type) {
                case PM_TOKEN_PARENTHESIS_LEFT: {
                    parser_lex(parser);
                    lparen = parser->previous;

                    if (match1(parser, PM_TOKEN_PARENTHESIS_RIGHT)) {
                        params = NULL;
                    } else {
                        params = parse_parameters(parser, PM_BINDING_POWER_DEFINED, true, false, true, true, false, (uint16_t) (depth + 1));
                    }

                    lex_state_set(parser, PM_LEX_STATE_BEG);
                    parser->command_start = true;

                    context_pop(parser);
                    if (!accept1(parser, PM_TOKEN_PARENTHESIS_RIGHT)) {
                        PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_DEF_PARAMS_TERM_PAREN, pm_token_type_human(parser->current.type));
                        parser->previous.start = parser->previous.end;
                        parser->previous.type = PM_TOKEN_MISSING;
                    }

                    rparen = parser->previous;
                    break;
                }
                case PM_CASE_PARAMETER: {
                    // If we're about to lex a label, we need to add the label
                    // state to make sure the next newline is ignored.
                    if (parser->current.type == PM_TOKEN_LABEL) {
                        lex_state_set(parser, parser->lex_state | PM_LEX_STATE_LABEL);
                    }

                    lparen = not_provided(parser);
                    rparen = not_provided(parser);
                    params = parse_parameters(parser, PM_BINDING_POWER_DEFINED, false, false, true, true, false, (uint16_t) (depth + 1));

                    context_pop(parser);
                    break;
                }
                default: {
                    lparen = not_provided(parser);
                    rparen = not_provided(parser);
                    params = NULL;

                    context_pop(parser);
                    break;
                }
            }

            pm_node_t *statements = NULL;
            pm_token_t equal;
            pm_token_t end_keyword;

            if (accept1(parser, PM_TOKEN_EQUAL)) {
                if (token_is_setter_name(&name)) {
                    pm_parser_err_token(parser, &name, PM_ERR_DEF_ENDLESS_SETTER);
                }
                equal = parser->previous;

                context_push(parser, PM_CONTEXT_DEF);
                pm_do_loop_stack_push(parser, false);
                statements = (pm_node_t *) pm_statements_node_create(parser);

                pm_node_t *statement = parse_expression(parser, PM_BINDING_POWER_DEFINED + 1, binding_power < PM_BINDING_POWER_COMPOSITION, false, PM_ERR_DEF_ENDLESS, (uint16_t) (depth + 1));

                if (accept1(parser, PM_TOKEN_KEYWORD_RESCUE_MODIFIER)) {
                    context_push(parser, PM_CONTEXT_RESCUE_MODIFIER);

                    pm_token_t rescue_keyword = parser->previous;
                    pm_node_t *value = parse_expression(parser, pm_binding_powers[PM_TOKEN_KEYWORD_RESCUE_MODIFIER].right, false, false, PM_ERR_RESCUE_MODIFIER_VALUE, (uint16_t) (depth + 1));
                    context_pop(parser);

                    statement = (pm_node_t *) pm_rescue_modifier_node_create(parser, statement, &rescue_keyword, value);
                }

                pm_statements_node_body_append(parser, (pm_statements_node_t *) statements, statement, false);
                pm_do_loop_stack_pop(parser);
                context_pop(parser);
                end_keyword = not_provided(parser);
            } else {
                equal = not_provided(parser);

                if (lparen.type == PM_TOKEN_NOT_PROVIDED) {
                    lex_state_set(parser, PM_LEX_STATE_BEG);
                    parser->command_start = true;
                    expect2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON, PM_ERR_DEF_PARAMS_TERM);
                } else {
                    accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON);
                }

                pm_accepts_block_stack_push(parser, true);
                pm_do_loop_stack_push(parser, false);

                if (!match4(parser, PM_TOKEN_KEYWORD_RESCUE, PM_TOKEN_KEYWORD_ENSURE, PM_TOKEN_KEYWORD_ELSE, PM_TOKEN_KEYWORD_END)) {
                    pm_accepts_block_stack_push(parser, true);
                    statements = (pm_node_t *) parse_statements(parser, PM_CONTEXT_DEF, (uint16_t) (depth + 1));
                    pm_accepts_block_stack_pop(parser);
                }

                if (match3(parser, PM_TOKEN_KEYWORD_RESCUE, PM_TOKEN_KEYWORD_ENSURE, PM_TOKEN_KEYWORD_ELSE)) {
                    assert(statements == NULL || PM_NODE_TYPE_P(statements, PM_STATEMENTS_NODE));
                    statements = (pm_node_t *) parse_rescues_implicit_begin(parser, opening_newline_index, &def_keyword, def_keyword.start, (pm_statements_node_t *) statements, PM_RESCUES_DEF, (uint16_t) (depth + 1));
                } else {
                    parser_warn_indentation_mismatch(parser, opening_newline_index, &def_keyword, false, false);
                }

                pm_accepts_block_stack_pop(parser);
                pm_do_loop_stack_pop(parser);

                expect1(parser, PM_TOKEN_KEYWORD_END, PM_ERR_DEF_TERM);
                end_keyword = parser->previous;
            }

            pm_constant_id_list_t locals;
            pm_locals_order(parser, &parser->current_scope->locals, &locals, false);
            pm_parser_scope_pop(parser);

            /**
             * If the final character is @. As is the case when defining
             * methods to override the unary operators, we should ignore
             * the @ in the same way we do for symbols.
             */
            pm_constant_id_t name_id = pm_parser_constant_id_location(parser, name.start, parse_operator_symbol_name(&name));

            flush_block_exits(parser, previous_block_exits);
            pm_node_list_free(&current_block_exits);

            return (pm_node_t *) pm_def_node_create(
                parser,
                name_id,
                &name,
                receiver,
                params,
                statements,
                &locals,
                &def_keyword,
                &operator,
                &lparen,
                &rparen,
                &equal,
                &end_keyword
            );
        }
        case PM_TOKEN_KEYWORD_DEFINED: {
            parser_lex(parser);
            pm_token_t keyword = parser->previous;

            pm_token_t lparen;
            pm_token_t rparen;
            pm_node_t *expression;
            context_push(parser, PM_CONTEXT_DEFINED);

            if (accept1(parser, PM_TOKEN_PARENTHESIS_LEFT)) {
                lparen = parser->previous;
                expression = parse_expression(parser, PM_BINDING_POWER_COMPOSITION, true, false, PM_ERR_DEFINED_EXPRESSION, (uint16_t) (depth + 1));

                if (parser->recovering) {
                    rparen = not_provided(parser);
                } else {
                    accept1(parser, PM_TOKEN_NEWLINE);
                    expect1(parser, PM_TOKEN_PARENTHESIS_RIGHT, PM_ERR_EXPECT_RPAREN);
                    rparen = parser->previous;
                }
            } else {
                lparen = not_provided(parser);
                rparen = not_provided(parser);
                expression = parse_expression(parser, PM_BINDING_POWER_DEFINED, false, false, PM_ERR_DEFINED_EXPRESSION, (uint16_t) (depth + 1));
            }

            context_pop(parser);
            return (pm_node_t *) pm_defined_node_create(
                parser,
                &lparen,
                expression,
                &rparen,
                &PM_LOCATION_TOKEN_VALUE(&keyword)
            );
        }
        case PM_TOKEN_KEYWORD_END_UPCASE: {
            if (binding_power != PM_BINDING_POWER_STATEMENT) {
                pm_parser_err_current(parser, PM_ERR_STATEMENT_POSTEXE_END);
            }

            parser_lex(parser);
            pm_token_t keyword = parser->previous;

            if (context_def_p(parser)) {
                pm_parser_warn_token(parser, &keyword, PM_WARN_END_IN_METHOD);
            }

            expect1(parser, PM_TOKEN_BRACE_LEFT, PM_ERR_END_UPCASE_BRACE);
            pm_token_t opening = parser->previous;
            pm_statements_node_t *statements = parse_statements(parser, PM_CONTEXT_POSTEXE, (uint16_t) (depth + 1));

            expect1(parser, PM_TOKEN_BRACE_RIGHT, PM_ERR_END_UPCASE_TERM);
            return (pm_node_t *) pm_post_execution_node_create(parser, &keyword, &opening, statements, &parser->previous);
        }
        case PM_TOKEN_KEYWORD_FALSE:
            parser_lex(parser);
            return (pm_node_t *) pm_false_node_create(parser, &parser->previous);
        case PM_TOKEN_KEYWORD_FOR: {
            size_t opening_newline_index = token_newline_index(parser);
            parser_lex(parser);

            pm_token_t for_keyword = parser->previous;
            pm_node_t *index;

            context_push(parser, PM_CONTEXT_FOR_INDEX);

            // First, parse out the first index expression.
            if (accept1(parser, PM_TOKEN_USTAR)) {
                pm_token_t star_operator = parser->previous;
                pm_node_t *name = NULL;

                if (token_begins_expression_p(parser->current.type)) {
                    name = parse_expression(parser, PM_BINDING_POWER_INDEX, false, false, PM_ERR_EXPECT_EXPRESSION_AFTER_STAR, (uint16_t) (depth + 1));
                }

                index = (pm_node_t *) pm_splat_node_create(parser, &star_operator, name);
            } else if (token_begins_expression_p(parser->current.type)) {
                index = parse_expression(parser, PM_BINDING_POWER_INDEX, false, false, PM_ERR_EXPECT_EXPRESSION_AFTER_COMMA, (uint16_t) (depth + 1));
            } else {
                pm_parser_err_token(parser, &for_keyword, PM_ERR_FOR_INDEX);
                index = (pm_node_t *) pm_missing_node_create(parser, for_keyword.start, for_keyword.end);
            }

            // Now, if there are multiple index expressions, parse them out.
            if (match1(parser, PM_TOKEN_COMMA)) {
                index = parse_targets(parser, index, PM_BINDING_POWER_INDEX, (uint16_t) (depth + 1));
            } else {
                index = parse_target(parser, index, false, false);
            }

            context_pop(parser);
            pm_do_loop_stack_push(parser, true);

            expect1(parser, PM_TOKEN_KEYWORD_IN, PM_ERR_FOR_IN);
            pm_token_t in_keyword = parser->previous;

            pm_node_t *collection = parse_value_expression(parser, PM_BINDING_POWER_COMPOSITION, true, false, PM_ERR_FOR_COLLECTION, (uint16_t) (depth + 1));
            pm_do_loop_stack_pop(parser);

            pm_token_t do_keyword;
            if (accept1(parser, PM_TOKEN_KEYWORD_DO_LOOP)) {
                do_keyword = parser->previous;
            } else {
                do_keyword = not_provided(parser);
                if (!match2(parser, PM_TOKEN_SEMICOLON, PM_TOKEN_NEWLINE)) {
                    PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_EXPECT_FOR_DELIMITER, pm_token_type_human(parser->current.type));
                }
            }

            pm_statements_node_t *statements = NULL;
            if (!match1(parser, PM_TOKEN_KEYWORD_END)) {
                statements = parse_statements(parser, PM_CONTEXT_FOR, (uint16_t) (depth + 1));
            }

            parser_warn_indentation_mismatch(parser, opening_newline_index, &for_keyword, false, false);
            expect1(parser, PM_TOKEN_KEYWORD_END, PM_ERR_FOR_TERM);

            return (pm_node_t *) pm_for_node_create(parser, index, collection, statements, &for_keyword, &in_keyword, &do_keyword, &parser->previous);
        }
        case PM_TOKEN_KEYWORD_IF:
            if (parser_end_of_line_p(parser)) {
                PM_PARSER_WARN_TOKEN_FORMAT_CONTENT(parser, parser->current, PM_WARN_KEYWORD_EOL);
            }

            size_t opening_newline_index = token_newline_index(parser);
            bool if_after_else = parser->previous.type == PM_TOKEN_KEYWORD_ELSE;
            parser_lex(parser);

            return parse_conditional(parser, PM_CONTEXT_IF, opening_newline_index, if_after_else, (uint16_t) (depth + 1));
        case PM_TOKEN_KEYWORD_UNDEF: {
            if (binding_power != PM_BINDING_POWER_STATEMENT) {
                pm_parser_err_current(parser, PM_ERR_STATEMENT_UNDEF);
            }

            parser_lex(parser);
            pm_undef_node_t *undef = pm_undef_node_create(parser, &parser->previous);
            pm_node_t *name = parse_undef_argument(parser, (uint16_t) (depth + 1));

            if (PM_NODE_TYPE_P(name, PM_MISSING_NODE)) {
                pm_node_destroy(parser, name);
            } else {
                pm_undef_node_append(undef, name);

                while (match1(parser, PM_TOKEN_COMMA)) {
                    lex_state_set(parser, PM_LEX_STATE_FNAME | PM_LEX_STATE_FITEM);
                    parser_lex(parser);
                    name = parse_undef_argument(parser, (uint16_t) (depth + 1));

                    if (PM_NODE_TYPE_P(name, PM_MISSING_NODE)) {
                        pm_node_destroy(parser, name);
                        break;
                    }

                    pm_undef_node_append(undef, name);
                }
            }

            return (pm_node_t *) undef;
        }
        case PM_TOKEN_KEYWORD_NOT: {
            parser_lex(parser);

            pm_token_t message = parser->previous;
            pm_arguments_t arguments = { 0 };
            pm_node_t *receiver = NULL;

            accept1(parser, PM_TOKEN_NEWLINE);

            if (accept1(parser, PM_TOKEN_PARENTHESIS_LEFT)) {
                pm_token_t lparen = parser->previous;

                if (accept1(parser, PM_TOKEN_PARENTHESIS_RIGHT)) {
                    receiver = (pm_node_t *) pm_parentheses_node_create(parser, &lparen, NULL, &parser->previous, 0);
                } else {
                    arguments.opening_loc = PM_LOCATION_TOKEN_VALUE(&lparen);
                    receiver = parse_expression(parser, PM_BINDING_POWER_COMPOSITION, true, false, PM_ERR_NOT_EXPRESSION, (uint16_t) (depth + 1));

                    if (!parser->recovering) {
                        accept1(parser, PM_TOKEN_NEWLINE);
                        expect1(parser, PM_TOKEN_PARENTHESIS_RIGHT, PM_ERR_EXPECT_RPAREN);
                        arguments.closing_loc = PM_LOCATION_TOKEN_VALUE(&parser->previous);
                    }
                }
            } else {
                receiver = parse_expression(parser, PM_BINDING_POWER_NOT, true, false, PM_ERR_NOT_EXPRESSION, (uint16_t) (depth + 1));
            }

            return (pm_node_t *) pm_call_node_not_create(parser, receiver, &message, &arguments);
        }
        case PM_TOKEN_KEYWORD_UNLESS: {
            size_t opening_newline_index = token_newline_index(parser);
            parser_lex(parser);

            return parse_conditional(parser, PM_CONTEXT_UNLESS, opening_newline_index, false, (uint16_t) (depth + 1));
        }
        case PM_TOKEN_KEYWORD_MODULE: {
            pm_node_list_t current_block_exits = { 0 };
            pm_node_list_t *previous_block_exits = push_block_exits(parser, &current_block_exits);

            size_t opening_newline_index = token_newline_index(parser);
            parser_lex(parser);
            pm_token_t module_keyword = parser->previous;

            pm_node_t *constant_path = parse_expression(parser, PM_BINDING_POWER_INDEX, false, false, PM_ERR_MODULE_NAME, (uint16_t) (depth + 1));
            pm_token_t name;

            // If we can recover from a syntax error that occurred while parsing
            // the name of the module, then we'll handle that here.
            if (PM_NODE_TYPE_P(constant_path, PM_MISSING_NODE)) {
                pop_block_exits(parser, previous_block_exits);
                pm_node_list_free(&current_block_exits);

                pm_token_t missing = (pm_token_t) { .type = PM_TOKEN_MISSING, .start = parser->previous.end, .end = parser->previous.end };
                return (pm_node_t *) pm_module_node_create(parser, NULL, &module_keyword, constant_path, &missing, NULL, &missing);
            }

            while (accept1(parser, PM_TOKEN_COLON_COLON)) {
                pm_token_t double_colon = parser->previous;

                expect1(parser, PM_TOKEN_CONSTANT, PM_ERR_CONSTANT_PATH_COLON_COLON_CONSTANT);
                constant_path = (pm_node_t *) pm_constant_path_node_create(parser, constant_path, &double_colon, &parser->previous);
            }

            // Here we retrieve the name of the module. If it wasn't a constant,
            // then it's possible that `module foo` was passed, which is a
            // syntax error. We handle that here as well.
            name = parser->previous;
            if (name.type != PM_TOKEN_CONSTANT) {
                pm_parser_err_token(parser, &name, PM_ERR_MODULE_NAME);
            }

            pm_parser_scope_push(parser, true);
            accept2(parser, PM_TOKEN_SEMICOLON, PM_TOKEN_NEWLINE);
            pm_node_t *statements = NULL;

            if (!match4(parser, PM_TOKEN_KEYWORD_RESCUE, PM_TOKEN_KEYWORD_ENSURE, PM_TOKEN_KEYWORD_ELSE, PM_TOKEN_KEYWORD_END)) {
                pm_accepts_block_stack_push(parser, true);
                statements = (pm_node_t *) parse_statements(parser, PM_CONTEXT_MODULE, (uint16_t) (depth + 1));
                pm_accepts_block_stack_pop(parser);
            }

            if (match3(parser, PM_TOKEN_KEYWORD_RESCUE, PM_TOKEN_KEYWORD_ENSURE, PM_TOKEN_KEYWORD_ELSE)) {
                assert(statements == NULL || PM_NODE_TYPE_P(statements, PM_STATEMENTS_NODE));
                statements = (pm_node_t *) parse_rescues_implicit_begin(parser, opening_newline_index, &module_keyword, module_keyword.start, (pm_statements_node_t *) statements, PM_RESCUES_MODULE, (uint16_t) (depth + 1));
            } else {
                parser_warn_indentation_mismatch(parser, opening_newline_index, &module_keyword, false, false);
            }

            pm_constant_id_list_t locals;
            pm_locals_order(parser, &parser->current_scope->locals, &locals, false);

            pm_parser_scope_pop(parser);
            expect1(parser, PM_TOKEN_KEYWORD_END, PM_ERR_MODULE_TERM);

            if (context_def_p(parser)) {
                pm_parser_err_token(parser, &module_keyword, PM_ERR_MODULE_IN_METHOD);
            }

            pop_block_exits(parser, previous_block_exits);
            pm_node_list_free(&current_block_exits);

            return (pm_node_t *) pm_module_node_create(parser, &locals, &module_keyword, constant_path, &name, statements, &parser->previous);
        }
        case PM_TOKEN_KEYWORD_NIL:
            parser_lex(parser);
            return (pm_node_t *) pm_nil_node_create(parser, &parser->previous);
        case PM_TOKEN_KEYWORD_REDO: {
            parser_lex(parser);

            pm_node_t *node = (pm_node_t *) pm_redo_node_create(parser, &parser->previous);
            if (!parser->partial_script) parse_block_exit(parser, node);

            return node;
        }
        case PM_TOKEN_KEYWORD_RETRY: {
            parser_lex(parser);

            pm_node_t *node = (pm_node_t *) pm_retry_node_create(parser, &parser->previous);
            parse_retry(parser, node);

            return node;
        }
        case PM_TOKEN_KEYWORD_SELF:
            parser_lex(parser);
            return (pm_node_t *) pm_self_node_create(parser, &parser->previous);
        case PM_TOKEN_KEYWORD_TRUE:
            parser_lex(parser);
            return (pm_node_t *) pm_true_node_create(parser, &parser->previous);
        case PM_TOKEN_KEYWORD_UNTIL: {
            size_t opening_newline_index = token_newline_index(parser);

            context_push(parser, PM_CONTEXT_LOOP_PREDICATE);
            pm_do_loop_stack_push(parser, true);

            parser_lex(parser);
            pm_token_t keyword = parser->previous;
            pm_node_t *predicate = parse_value_expression(parser, PM_BINDING_POWER_COMPOSITION, true, false, PM_ERR_CONDITIONAL_UNTIL_PREDICATE, (uint16_t) (depth + 1));

            pm_do_loop_stack_pop(parser);
            context_pop(parser);

            pm_token_t do_keyword;
            if (accept1(parser, PM_TOKEN_KEYWORD_DO_LOOP)) {
                do_keyword = parser->previous;
            } else {
                do_keyword = not_provided(parser);
                expect2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON, PM_ERR_CONDITIONAL_UNTIL_PREDICATE);
            }

            pm_statements_node_t *statements = NULL;
            if (!match1(parser, PM_TOKEN_KEYWORD_END)) {
                pm_accepts_block_stack_push(parser, true);
                statements = parse_statements(parser, PM_CONTEXT_UNTIL, (uint16_t) (depth + 1));
                pm_accepts_block_stack_pop(parser);
                accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON);
            }

            parser_warn_indentation_mismatch(parser, opening_newline_index, &keyword, false, false);
            expect1(parser, PM_TOKEN_KEYWORD_END, PM_ERR_UNTIL_TERM);

            return (pm_node_t *) pm_until_node_create(parser, &keyword, &do_keyword, &parser->previous, predicate, statements, 0);
        }
        case PM_TOKEN_KEYWORD_WHILE: {
            size_t opening_newline_index = token_newline_index(parser);

            context_push(parser, PM_CONTEXT_LOOP_PREDICATE);
            pm_do_loop_stack_push(parser, true);

            parser_lex(parser);
            pm_token_t keyword = parser->previous;
            pm_node_t *predicate = parse_value_expression(parser, PM_BINDING_POWER_COMPOSITION, true, false, PM_ERR_CONDITIONAL_WHILE_PREDICATE, (uint16_t) (depth + 1));

            pm_do_loop_stack_pop(parser);
            context_pop(parser);

            pm_token_t do_keyword;
            if (accept1(parser, PM_TOKEN_KEYWORD_DO_LOOP)) {
                do_keyword = parser->previous;
            } else {
                do_keyword = not_provided(parser);
                expect2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON, PM_ERR_CONDITIONAL_WHILE_PREDICATE);
            }

            pm_statements_node_t *statements = NULL;
            if (!match1(parser, PM_TOKEN_KEYWORD_END)) {
                pm_accepts_block_stack_push(parser, true);
                statements = parse_statements(parser, PM_CONTEXT_WHILE, (uint16_t) (depth + 1));
                pm_accepts_block_stack_pop(parser);
                accept2(parser, PM_TOKEN_NEWLINE, PM_TOKEN_SEMICOLON);
            }

            parser_warn_indentation_mismatch(parser, opening_newline_index, &keyword, false, false);
            expect1(parser, PM_TOKEN_KEYWORD_END, PM_ERR_WHILE_TERM);

            return (pm_node_t *) pm_while_node_create(parser, &keyword, &do_keyword, &parser->previous, predicate, statements, 0);
        }
        case PM_TOKEN_PERCENT_LOWER_I: {
            parser_lex(parser);
            pm_token_t opening = parser->previous;
            pm_array_node_t *array = pm_array_node_create(parser, &opening);

            while (!match2(parser, PM_TOKEN_STRING_END, PM_TOKEN_EOF)) {
                accept1(parser, PM_TOKEN_WORDS_SEP);
                if (match1(parser, PM_TOKEN_STRING_END)) break;

                if (match1(parser, PM_TOKEN_STRING_CONTENT)) {
                    pm_token_t opening = not_provided(parser);
                    pm_token_t closing = not_provided(parser);
                    pm_array_node_elements_append(array, (pm_node_t *) pm_symbol_node_create_current_string(parser, &opening, &parser->current, &closing));
                }

                expect1(parser, PM_TOKEN_STRING_CONTENT, PM_ERR_LIST_I_LOWER_ELEMENT);
            }

            pm_token_t closing = parser->current;
            if (match1(parser, PM_TOKEN_EOF)) {
                pm_parser_err_token(parser, &opening, PM_ERR_LIST_I_LOWER_TERM);
                closing = (pm_token_t) { .type = PM_TOKEN_MISSING, .start = parser->previous.end, .end = parser->previous.end };
            } else {
                expect1(parser, PM_TOKEN_STRING_END, PM_ERR_LIST_I_LOWER_TERM);
            }
            pm_array_node_close_set(array, &closing);

            return (pm_node_t *) array;
        }
        case PM_TOKEN_PERCENT_UPPER_I: {
            parser_lex(parser);
            pm_token_t opening = parser->previous;
            pm_array_node_t *array = pm_array_node_create(parser, &opening);

            // This is the current node that we are parsing that will be added to the
            // list of elements.
            pm_node_t *current = NULL;

            while (!match2(parser, PM_TOKEN_STRING_END, PM_TOKEN_EOF)) {
                switch (parser->current.type) {
                    case PM_TOKEN_WORDS_SEP: {
                        if (current == NULL) {
                            // If we hit a separator before we have any content, then we don't
                            // need to do anything.
                        } else {
                            // If we hit a separator after we've hit content, then we need to
                            // append that content to the list and reset the current node.
                            pm_array_node_elements_append(array, current);
                            current = NULL;
                        }

                        parser_lex(parser);
                        break;
                    }
                    case PM_TOKEN_STRING_CONTENT: {
                        pm_token_t opening = not_provided(parser);
                        pm_token_t closing = not_provided(parser);

                        if (current == NULL) {
                            // If we hit content and the current node is NULL, then this is
                            // the first string content we've seen. In that case we're going
                            // to create a new string node and set that to the current.
                            current = (pm_node_t *) pm_symbol_node_create_current_string(parser, &opening, &parser->current, &closing);
                            parser_lex(parser);
                        } else if (PM_NODE_TYPE_P(current, PM_INTERPOLATED_SYMBOL_NODE)) {
                            // If we hit string content and the current node is an
                            // interpolated string, then we need to append the string content
                            // to the list of child nodes.
                            pm_node_t *string = (pm_node_t *) pm_string_node_create_current_string(parser, &opening, &parser->current, &closing);
                            parser_lex(parser);

                            pm_interpolated_symbol_node_append((pm_interpolated_symbol_node_t *) current, string);
                        } else if (PM_NODE_TYPE_P(current, PM_SYMBOL_NODE)) {
                            // If we hit string content and the current node is a symbol node,
                            // then we need to convert the current node into an interpolated
                            // string and add the string content to the list of child nodes.
                            pm_symbol_node_t *cast = (pm_symbol_node_t *) current;
                            pm_token_t bounds = not_provided(parser);

                            pm_token_t content = { .type = PM_TOKEN_STRING_CONTENT, .start = cast->value_loc.start, .end = cast->value_loc.end };
                            pm_node_t *first_string = (pm_node_t *) pm_string_node_create_unescaped(parser, &bounds, &content, &bounds, &cast->unescaped);
                            pm_node_t *second_string = (pm_node_t *) pm_string_node_create_current_string(parser, &opening, &parser->previous, &closing);
                            parser_lex(parser);

                            pm_interpolated_symbol_node_t *interpolated = pm_interpolated_symbol_node_create(parser, &opening, NULL, &closing);
                            pm_interpolated_symbol_node_append(interpolated, first_string);
                            pm_interpolated_symbol_node_append(interpolated, second_string);

                            xfree(current);
                            current = (pm_node_t *) interpolated;
                        } else {
                            assert(false && "unreachable");
                        }

                        break;
                    }
                    case PM_TOKEN_EMBVAR: {
                        bool start_location_set = false;
                        if (current == NULL) {
                            // If we hit an embedded variable and the current node is NULL,
                            // then this is the start of a new string. We'll set the current
                            // node to a new interpolated string.
                            pm_token_t opening = not_provided(parser);
                            pm_token_t closing = not_provided(parser);
                            current = (pm_node_t *) pm_interpolated_symbol_node_create(parser, &opening, NULL, &closing);
                        } else if (PM_NODE_TYPE_P(current, PM_SYMBOL_NODE)) {
                            // If we hit an embedded variable and the current node is a string
                            // node, then we'll convert the current into an interpolated
                            // string and add the string node to the list of parts.
                            pm_token_t opening = not_provided(parser);
                            pm_token_t closing = not_provided(parser);
                            pm_interpolated_symbol_node_t *interpolated = pm_interpolated_symbol_node_create(parser, &opening, NULL, &closing);

                            current = (pm_node_t *) pm_symbol_node_to_string_node(parser, (pm_symbol_node_t *) current);
                            pm_interpolated_symbol_node_append(interpolated, current);
                            interpolated->base.location.start = current->location.start;
                            start_location_set = true;
                            current = (pm_node_t *) interpolated;
                        } else {
                            // If we hit an embedded variable and the current node is an
                            // interpolated string, then we'll just add the embedded variable.
                        }

                        pm_node_t *part = parse_string_part(parser, (uint16_t) (depth + 1));
                        pm_interpolated_symbol_node_append((pm_interpolated_symbol_node_t *) current, part);
                        if (!start_location_set) {
                            current->location.start = part->location.start;
                        }
                        break;
                    }
                    case PM_TOKEN_EMBEXPR_BEGIN: {
                        bool start_location_set = false;
                        if (current == NULL) {
                            // If we hit an embedded expression and the current node is NULL,
                            // then this is the start of a new string. We'll set the current
                            // node to a new interpolated string.
                            pm_token_t opening = not_provided(parser);
                            pm_token_t closing = not_provided(parser);
                            current = (pm_node_t *) pm_interpolated_symbol_node_create(parser, &opening, NULL, &closing);
                        } else if (PM_NODE_TYPE_P(current, PM_SYMBOL_NODE)) {
                            // If we hit an embedded expression and the current node is a
                            // string node, then we'll convert the current into an
                            // interpolated string and add the string node to the list of
                            // parts.
                            pm_token_t opening = not_provided(parser);
                            pm_token_t closing = not_provided(parser);
                            pm_interpolated_symbol_node_t *interpolated = pm_interpolated_symbol_node_create(parser, &opening, NULL, &closing);

                            current = (pm_node_t *) pm_symbol_node_to_string_node(parser, (pm_symbol_node_t *) current);
                            pm_interpolated_symbol_node_append(interpolated, current);
                            interpolated->base.location.start = current->location.start;
                            start_location_set = true;
                            current = (pm_node_t *) interpolated;
                        } else if (PM_NODE_TYPE_P(current, PM_INTERPOLATED_SYMBOL_NODE)) {
                            // If we hit an embedded expression and the current node is an
                            // interpolated string, then we'll just continue on.
                        } else {
                            assert(false && "unreachable");
                        }

                        pm_node_t *part = parse_string_part(parser, (uint16_t) (depth + 1));
                        pm_interpolated_symbol_node_append((pm_interpolated_symbol_node_t *) current, part);
                        if (!start_location_set) {
                            current->location.start = part->location.start;
                        }
                        break;
                    }
                    default:
                        expect1(parser, PM_TOKEN_STRING_CONTENT, PM_ERR_LIST_I_UPPER_ELEMENT);
                        parser_lex(parser);
                        break;
                }
            }

            // If we have a current node, then we need to append it to the list.
            if (current) {
                pm_array_node_elements_append(array, current);
            }

            pm_token_t closing = parser->current;
            if (match1(parser, PM_TOKEN_EOF)) {
                pm_parser_err_token(parser, &opening, PM_ERR_LIST_I_UPPER_TERM);
                closing = (pm_token_t) { .type = PM_TOKEN_MISSING, .start = parser->previous.end, .end = parser->previous.end };
            } else {
                expect1(parser, PM_TOKEN_STRING_END, PM_ERR_LIST_I_UPPER_TERM);
            }
            pm_array_node_close_set(array, &closing);

            return (pm_node_t *) array;
        }
        case PM_TOKEN_PERCENT_LOWER_W: {
            parser_lex(parser);
            pm_token_t opening = parser->previous;
            pm_array_node_t *array = pm_array_node_create(parser, &opening);

            // skip all leading whitespaces
            accept1(parser, PM_TOKEN_WORDS_SEP);

            while (!match2(parser, PM_TOKEN_STRING_END, PM_TOKEN_EOF)) {
                accept1(parser, PM_TOKEN_WORDS_SEP);
                if (match1(parser, PM_TOKEN_STRING_END)) break;

                if (match1(parser, PM_TOKEN_STRING_CONTENT)) {
                    pm_token_t opening = not_provided(parser);
                    pm_token_t closing = not_provided(parser);

                    pm_node_t *string = (pm_node_t *) pm_string_node_create_current_string(parser, &opening, &parser->current, &closing);
                    pm_array_node_elements_append(array, string);
                }

                expect1(parser, PM_TOKEN_STRING_CONTENT, PM_ERR_LIST_W_LOWER_ELEMENT);
            }

            pm_token_t closing = parser->current;
            if (match1(parser, PM_TOKEN_EOF)) {
                pm_parser_err_token(parser, &opening, PM_ERR_LIST_W_LOWER_TERM);
                closing = (pm_token_t) { .type = PM_TOKEN_MISSING, .start = parser->previous.end, .end = parser->previous.end };
            } else {
                expect1(parser, PM_TOKEN_STRING_END, PM_ERR_LIST_W_LOWER_TERM);
            }

            pm_array_node_close_set(array, &closing);
            return (pm_node_t *) array;
        }
        case PM_TOKEN_PERCENT_UPPER_W: {
            parser_lex(parser);
            pm_token_t opening = parser->previous;
            pm_array_node_t *array = pm_array_node_create(parser, &opening);

            // This is the current node that we are parsing that will be added
            // to the list of elements.
            pm_node_t *current = NULL;

            while (!match2(parser, PM_TOKEN_STRING_END, PM_TOKEN_EOF)) {
                switch (parser->current.type) {
                    case PM_TOKEN_WORDS_SEP: {
                        // Reset the explicit encoding if we hit a separator
                        // since each element can have its own encoding.
                        parser->explicit_encoding = NULL;

                        if (current == NULL) {
                            // If we hit a separator before we have any content,
                            // then we don't need to do anything.
                        } else {
                            // If we hit a separator after we've hit content,
                            // then we need to append that content to the list
                            // and reset the current node.
                            pm_array_node_elements_append(array, current);
                            current = NULL;
                        }

                        parser_lex(parser);
                        break;
                    }
                    case PM_TOKEN_STRING_CONTENT: {
                        pm_token_t opening = not_provided(parser);
                        pm_token_t closing = not_provided(parser);

                        pm_node_t *string = (pm_node_t *) pm_string_node_create_current_string(parser, &opening, &parser->current, &closing);
                        pm_node_flag_set(string, parse_unescaped_encoding(parser));
                        parser_lex(parser);

                        if (current == NULL) {
                            // If we hit content and the current node is NULL,
                            // then this is the first string content we've seen.
                            // In that case we're going to create a new string
                            // node and set that to the current.
                            current = string;
                        } else if (PM_NODE_TYPE_P(current, PM_INTERPOLATED_STRING_NODE)) {
                            // If we hit string content and the current node is
                            // an interpolated string, then we need to append
                            // the string content to the list of child nodes.
                            pm_interpolated_string_node_append((pm_interpolated_string_node_t *) current, string);
                        } else if (PM_NODE_TYPE_P(current, PM_STRING_NODE)) {
                            // If we hit string content and the current node is
                            // a string node, then we need to convert the
                            // current node into an interpolated string and add
                            // the string content to the list of child nodes.
                            pm_interpolated_string_node_t *interpolated = pm_interpolated_string_node_create(parser, &opening, NULL, &closing);
                            pm_interpolated_string_node_append(interpolated, current);
                            pm_interpolated_string_node_append(interpolated, string);
                            current = (pm_node_t *) interpolated;
                        } else {
                            assert(false && "unreachable");
                        }

                        break;
                    }
                    case PM_TOKEN_EMBVAR: {
                        if (current == NULL) {
                            // If we hit an embedded variable and the current
                            // node is NULL, then this is the start of a new
                            // string. We'll set the current node to a new
                            // interpolated string.
                            pm_token_t opening = not_provided(parser);
                            pm_token_t closing = not_provided(parser);
                            current = (pm_node_t *) pm_interpolated_string_node_create(parser, &opening, NULL, &closing);
                        } else if (PM_NODE_TYPE_P(current, PM_STRING_NODE)) {
                            // If we hit an embedded variable and the current
                            // node is a string node, then we'll convert the
                            // current into an interpolated string and add the
                            // string node to the list of parts.
                            pm_token_t opening = not_provided(parser);
                            pm_token_t closing = not_provided(parser);
                            pm_interpolated_string_node_t *interpolated = pm_interpolated_string_node_create(parser, &opening, NULL, &closing);
                            pm_interpolated_string_node_append(interpolated, current);
                            current = (pm_node_t *) interpolated;
                        } else {
                            // If we hit an embedded variable and the current
                            // node is an interpolated string, then we'll just
                            // add the embedded variable.
                        }

                        pm_node_t *part = parse_string_part(parser, (uint16_t) (depth + 1));
                        pm_interpolated_string_node_append((pm_interpolated_string_node_t *) current, part);
                        break;
                    }
                    case PM_TOKEN_EMBEXPR_BEGIN: {
                        if (current == NULL) {
                            // If we hit an embedded expression and the current
                            // node is NULL, then this is the start of a new
                            // string. We'll set the current node to a new
                            // interpolated string.
                            pm_token_t opening = not_provided(parser);
                            pm_token_t closing = not_provided(parser);
                            current = (pm_node_t *) pm_interpolated_string_node_create(parser, &opening, NULL, &closing);
                        } else if (PM_NODE_TYPE_P(current, PM_STRING_NODE)) {
                            // If we hit an embedded expression and the current
                            // node is a string node, then we'll convert the
                            // current into an interpolated string and add the
                            // string node to the list of parts.
                            pm_token_t opening = not_provided(parser);
                            pm_token_t closing = not_provided(parser);
                            pm_interpolated_string_node_t *interpolated = pm_interpolated_string_node_create(parser, &opening, NULL, &closing);
                            pm_interpolated_string_node_append(interpolated, current);
                            current = (pm_node_t *) interpolated;
                        } else if (PM_NODE_TYPE_P(current, PM_INTERPOLATED_STRING_NODE)) {
                            // If we hit an embedded expression and the current
                            // node is an interpolated string, then we'll just
                            // continue on.
                        } else {
                            assert(false && "unreachable");
                        }

                        pm_node_t *part = parse_string_part(parser, (uint16_t) (depth + 1));
                        pm_interpolated_string_node_append((pm_interpolated_string_node_t *) current, part);
                        break;
                    }
                    default:
                        expect1(parser, PM_TOKEN_STRING_CONTENT, PM_ERR_LIST_W_UPPER_ELEMENT);
                        parser_lex(parser);
                        break;
                }
            }

            // If we have a current node, then we need to append it to the list.
            if (current) {
                pm_array_node_elements_append(array, current);
            }

            pm_token_t closing = parser->current;
            if (match1(parser, PM_TOKEN_EOF)) {
                pm_parser_err_token(parser, &opening, PM_ERR_LIST_W_UPPER_TERM);
                closing = (pm_token_t) { .type = PM_TOKEN_MISSING, .start = parser->previous.end, .end = parser->previous.end };
            } else {
                expect1(parser, PM_TOKEN_STRING_END, PM_ERR_LIST_W_UPPER_TERM);
            }

            pm_array_node_close_set(array, &closing);
            return (pm_node_t *) array;
        }
        case PM_TOKEN_REGEXP_BEGIN: {
            pm_token_t opening = parser->current;
            parser_lex(parser);

            if (match1(parser, PM_TOKEN_REGEXP_END)) {
                // If we get here, then we have an end immediately after a start. In
                // that case we'll create an empty content token and return an
                // uninterpolated regular expression.
                pm_token_t content = (pm_token_t) {
                    .type = PM_TOKEN_STRING_CONTENT,
                    .start = parser->previous.end,
                    .end = parser->previous.end
                };

                parser_lex(parser);

                pm_node_t *node = (pm_node_t *) pm_regular_expression_node_create(parser, &opening, &content, &parser->previous);
                pm_node_flag_set(node, PM_REGULAR_EXPRESSION_FLAGS_FORCED_US_ASCII_ENCODING);

                return node;
            }

            pm_interpolated_regular_expression_node_t *interpolated;

            if (match1(parser, PM_TOKEN_STRING_CONTENT)) {
                // In this case we've hit string content so we know the regular
                // expression at least has something in it. We'll need to check if the
                // following token is the end (in which case we can return a plain
                // regular expression) or if it's not then it has interpolation.
                pm_string_t unescaped = parser->current_string;
                pm_token_t content = parser->current;
                bool ascii_only = parser->current_regular_expression_ascii_only;
                parser_lex(parser);

                // If we hit an end, then we can create a regular expression
                // node without interpolation, which can be represented more
                // succinctly and more easily compiled.
                if (accept1(parser, PM_TOKEN_REGEXP_END)) {
                    pm_regular_expression_node_t *node = (pm_regular_expression_node_t *) pm_regular_expression_node_create_unescaped(parser, &opening, &content, &parser->previous, &unescaped);

                    // If we're not immediately followed by a =~, then we want
                    // to parse all of the errors at this point. If it is
                    // followed by a =~, then it will get parsed higher up while
                    // parsing the named captures as well.
                    if (!match1(parser, PM_TOKEN_EQUAL_TILDE)) {
                        parse_regular_expression_errors(parser, node);
                    }

                    pm_node_flag_set((pm_node_t *) node, parse_and_validate_regular_expression_encoding(parser, &unescaped, ascii_only, node->base.flags));
                    return (pm_node_t *) node;
                }

                // If we get here, then we have interpolation so we'll need to create
                // a regular expression node with interpolation.
                interpolated = pm_interpolated_regular_expression_node_create(parser, &opening);

                pm_token_t opening = not_provided(parser);
                pm_token_t closing = not_provided(parser);
                pm_node_t *part = (pm_node_t *) pm_string_node_create_unescaped(parser, &opening, &parser->previous, &closing, &unescaped);

                if (parser->encoding == PM_ENCODING_US_ASCII_ENTRY) {
                    // This is extremely strange, but the first string part of a
                    // regular expression will always be tagged as binary if we
                    // are in a US-ASCII file, no matter its contents.
                    pm_node_flag_set(part, PM_STRING_FLAGS_FORCED_BINARY_ENCODING);
                }

                pm_interpolated_regular_expression_node_append(interpolated, part);
            } else {
                // If the first part of the body of the regular expression is not a
                // string content, then we have interpolation and we need to create an
                // interpolated regular expression node.
                interpolated = pm_interpolated_regular_expression_node_create(parser, &opening);
            }

            // Now that we're here and we have interpolation, we'll parse all of the
            // parts into the list.
            pm_node_t *part;
            while (!match2(parser, PM_TOKEN_REGEXP_END, PM_TOKEN_EOF)) {
                if ((part = parse_string_part(parser, (uint16_t) (depth + 1))) != NULL) {
                    pm_interpolated_regular_expression_node_append(interpolated, part);
                }
            }

            pm_token_t closing = parser->current;
            if (match1(parser, PM_TOKEN_EOF)) {
                pm_parser_err_token(parser, &opening, PM_ERR_REGEXP_TERM);
                closing = (pm_token_t) { .type = PM_TOKEN_MISSING, .start = parser->previous.end, .end = parser->previous.end };
            } else {
                expect1(parser, PM_TOKEN_REGEXP_END, PM_ERR_REGEXP_TERM);
            }

            pm_interpolated_regular_expression_node_closing_set(parser, interpolated, &closing);
            return (pm_node_t *) interpolated;
        }
        case PM_TOKEN_BACKTICK:
        case PM_TOKEN_PERCENT_LOWER_X: {
            parser_lex(parser);
            pm_token_t opening = parser->previous;

            // When we get here, we don't know if this string is going to have
            // interpolation or not, even though it is allowed. Still, we want to be
            // able to return a string node without interpolation if we can since
            // it'll be faster.
            if (match1(parser, PM_TOKEN_STRING_END)) {
                // If we get here, then we have an end immediately after a start. In
                // that case we'll create an empty content token and return an
                // uninterpolated string.
                pm_token_t content = (pm_token_t) {
                    .type = PM_TOKEN_STRING_CONTENT,
                    .start = parser->previous.end,
                    .end = parser->previous.end
                };

                parser_lex(parser);
                return (pm_node_t *) pm_xstring_node_create(parser, &opening, &content, &parser->previous);
            }

            pm_interpolated_x_string_node_t *node;

            if (match1(parser, PM_TOKEN_STRING_CONTENT)) {
                // In this case we've hit string content so we know the string
                // at least has something in it. We'll need to check if the
                // following token is the end (in which case we can return a
                // plain string) or if it's not then it has interpolation.
                pm_string_t unescaped = parser->current_string;
                pm_token_t content = parser->current;
                parser_lex(parser);

                if (match1(parser, PM_TOKEN_STRING_END)) {
                    pm_node_t *node = (pm_node_t *) pm_xstring_node_create_unescaped(parser, &opening, &content, &parser->current, &unescaped);
                    pm_node_flag_set(node, parse_unescaped_encoding(parser));
                    parser_lex(parser);
                    return node;
                }

                // If we get here, then we have interpolation so we'll need to
                // create a string node with interpolation.
                node = pm_interpolated_xstring_node_create(parser, &opening, &opening);

                pm_token_t opening = not_provided(parser);
                pm_token_t closing = not_provided(parser);

                pm_node_t *part = (pm_node_t *) pm_string_node_create_unescaped(parser, &opening, &parser->previous, &closing, &unescaped);
                pm_node_flag_set(part, parse_unescaped_encoding(parser));

                pm_interpolated_xstring_node_append(node, part);
            } else {
                // If the first part of the body of the string is not a string
                // content, then we have interpolation and we need to create an
                // interpolated string node.
                node = pm_interpolated_xstring_node_create(parser, &opening, &opening);
            }

            pm_node_t *part;
            while (!match2(parser, PM_TOKEN_STRING_END, PM_TOKEN_EOF)) {
                if ((part = parse_string_part(parser, (uint16_t) (depth + 1))) != NULL) {
                    pm_interpolated_xstring_node_append(node, part);
                }
            }

            pm_token_t closing = parser->current;
            if (match1(parser, PM_TOKEN_EOF)) {
                pm_parser_err_token(parser, &opening, PM_ERR_XSTRING_TERM);
                closing = (pm_token_t) { .type = PM_TOKEN_MISSING, .start = parser->previous.end, .end = parser->previous.end };
            } else {
                expect1(parser, PM_TOKEN_STRING_END, PM_ERR_XSTRING_TERM);
            }
            pm_interpolated_xstring_node_closing_set(node, &closing);

            return (pm_node_t *) node;
        }
        case PM_TOKEN_USTAR: {
            parser_lex(parser);

            // * operators at the beginning of expressions are only valid in the
            // context of a multiple assignment. We enforce that here. We'll
            // still lex past it though and create a missing node place.
            if (binding_power != PM_BINDING_POWER_STATEMENT) {
                pm_parser_err_prefix(parser, diag_id);
                return (pm_node_t *) pm_missing_node_create(parser, parser->previous.start, parser->previous.end);
            }

            pm_token_t operator = parser->previous;
            pm_node_t *name = NULL;

            if (token_begins_expression_p(parser->current.type)) {
                name = parse_expression(parser, PM_BINDING_POWER_INDEX, false, false, PM_ERR_EXPECT_EXPRESSION_AFTER_STAR, (uint16_t) (depth + 1));
            }

            pm_node_t *splat = (pm_node_t *) pm_splat_node_create(parser, &operator, name);

            if (match1(parser, PM_TOKEN_COMMA)) {
                return parse_targets_validate(parser, splat, PM_BINDING_POWER_INDEX, (uint16_t) (depth + 1));
            } else {
                return parse_target_validate(parser, splat, true);
            }
        }
        case PM_TOKEN_BANG: {
            if (binding_power > PM_BINDING_POWER_UNARY) {
                pm_parser_err_prefix(parser, PM_ERR_UNARY_DISALLOWED);
            }

            parser_lex(parser);

            pm_token_t operator = parser->previous;
            pm_node_t *receiver = parse_expression(parser, pm_binding_powers[parser->previous.type].right, binding_power < PM_BINDING_POWER_MATCH, false, PM_ERR_UNARY_RECEIVER, (uint16_t) (depth + 1));
            pm_call_node_t *node = pm_call_node_unary_create(parser, &operator, receiver, "!");

            pm_conditional_predicate(parser, receiver, PM_CONDITIONAL_PREDICATE_TYPE_NOT);
            return (pm_node_t *) node;
        }
        case PM_TOKEN_TILDE: {
            if (binding_power > PM_BINDING_POWER_UNARY) {
                pm_parser_err_prefix(parser, PM_ERR_UNARY_DISALLOWED);
            }
            parser_lex(parser);

            pm_token_t operator = parser->previous;
            pm_node_t *receiver = parse_expression(parser, pm_binding_powers[parser->previous.type].right, false, false, PM_ERR_UNARY_RECEIVER, (uint16_t) (depth + 1));
            pm_call_node_t *node = pm_call_node_unary_create(parser, &operator, receiver, "~");

            return (pm_node_t *) node;
        }
        case PM_TOKEN_UMINUS: {
            if (binding_power > PM_BINDING_POWER_UNARY) {
                pm_parser_err_prefix(parser, PM_ERR_UNARY_DISALLOWED);
            }
            parser_lex(parser);

            pm_token_t operator = parser->previous;
            pm_node_t *receiver = parse_expression(parser, pm_binding_powers[parser->previous.type].right, false, false, PM_ERR_UNARY_RECEIVER, (uint16_t) (depth + 1));
            pm_call_node_t *node = pm_call_node_unary_create(parser, &operator, receiver, "-@");

            return (pm_node_t *) node;
        }
        case PM_TOKEN_UMINUS_NUM: {
            parser_lex(parser);

            pm_token_t operator = parser->previous;
            pm_node_t *node = parse_expression(parser, pm_binding_powers[parser->previous.type].right, false, false, PM_ERR_UNARY_RECEIVER, (uint16_t) (depth + 1));

            if (accept1(parser, PM_TOKEN_STAR_STAR)) {
                pm_token_t exponent_operator = parser->previous;
                pm_node_t *exponent = parse_expression(parser, pm_binding_powers[exponent_operator.type].right, false, false, PM_ERR_EXPECT_ARGUMENT, (uint16_t) (depth + 1));
                node = (pm_node_t *) pm_call_node_binary_create(parser, node, &exponent_operator, exponent, 0);
                node = (pm_node_t *) pm_call_node_unary_create(parser, &operator, node, "-@");
            } else {
                switch (PM_NODE_TYPE(node)) {
                    case PM_INTEGER_NODE:
                    case PM_FLOAT_NODE:
                    case PM_RATIONAL_NODE:
                    case PM_IMAGINARY_NODE:
                        parse_negative_numeric(node);
                        break;
                    default:
                        node = (pm_node_t *) pm_call_node_unary_create(parser, &operator, node, "-@");
                        break;
                }
            }

            return node;
        }
        case PM_TOKEN_MINUS_GREATER: {
            int previous_lambda_enclosure_nesting = parser->lambda_enclosure_nesting;
            parser->lambda_enclosure_nesting = parser->enclosure_nesting;

            size_t opening_newline_index = token_newline_index(parser);
            pm_accepts_block_stack_push(parser, true);
            parser_lex(parser);

            pm_token_t operator = parser->previous;
            pm_parser_scope_push(parser, false);

            pm_block_parameters_node_t *block_parameters;

            switch (parser->current.type) {
                case PM_TOKEN_PARENTHESIS_LEFT: {
                    pm_token_t opening = parser->current;
                    parser_lex(parser);

                    if (match1(parser, PM_TOKEN_PARENTHESIS_RIGHT)) {
                        block_parameters = pm_block_parameters_node_create(parser, NULL, &opening);
                    } else {
                        block_parameters = parse_block_parameters(parser, false, &opening, true, true, (uint16_t) (depth + 1));
                    }

                    accept1(parser, PM_TOKEN_NEWLINE);
                    expect1(parser, PM_TOKEN_PARENTHESIS_RIGHT, PM_ERR_EXPECT_RPAREN);

                    pm_block_parameters_node_closing_set(block_parameters, &parser->previous);
                    break;
                }
                case PM_CASE_PARAMETER: {
                    pm_accepts_block_stack_push(parser, false);
                    pm_token_t opening = not_provided(parser);
                    block_parameters = parse_block_parameters(parser, false, &opening, true, false, (uint16_t) (depth + 1));
                    pm_accepts_block_stack_pop(parser);
                    break;
                }
                default: {
                    block_parameters = NULL;
                    break;
                }
            }

            pm_token_t opening;
            pm_node_t *body = NULL;
            parser->lambda_enclosure_nesting = previous_lambda_enclosure_nesting;

            if (accept1(parser, PM_TOKEN_LAMBDA_BEGIN)) {
                opening = parser->previous;

                if (!match1(parser, PM_TOKEN_BRACE_RIGHT)) {
                    body = (pm_node_t *) parse_statements(parser, PM_CONTEXT_LAMBDA_BRACES, (uint16_t) (depth + 1));
                }

                parser_warn_indentation_mismatch(parser, opening_newline_index, &operator, false, false);
                expect1(parser, PM_TOKEN_BRACE_RIGHT, PM_ERR_LAMBDA_TERM_BRACE);
            } else {
                expect1(parser, PM_TOKEN_KEYWORD_DO, PM_ERR_LAMBDA_OPEN);
                opening = parser->previous;

                if (!match3(parser, PM_TOKEN_KEYWORD_END, PM_TOKEN_KEYWORD_RESCUE, PM_TOKEN_KEYWORD_ENSURE)) {
                    pm_accepts_block_stack_push(parser, true);
                    body = (pm_node_t *) parse_statements(parser, PM_CONTEXT_LAMBDA_DO_END, (uint16_t) (depth + 1));
                    pm_accepts_block_stack_pop(parser);
                }

                if (match2(parser, PM_TOKEN_KEYWORD_RESCUE, PM_TOKEN_KEYWORD_ENSURE)) {
                    assert(body == NULL || PM_NODE_TYPE_P(body, PM_STATEMENTS_NODE));
                    body = (pm_node_t *) parse_rescues_implicit_begin(parser, opening_newline_index, &operator, opening.start, (pm_statements_node_t *) body, PM_RESCUES_LAMBDA, (uint16_t) (depth + 1));
                } else {
                    parser_warn_indentation_mismatch(parser, opening_newline_index, &operator, false, false);
                }

                expect1(parser, PM_TOKEN_KEYWORD_END, PM_ERR_LAMBDA_TERM_END);
            }

            pm_constant_id_list_t locals;
            pm_locals_order(parser, &parser->current_scope->locals, &locals, pm_parser_scope_toplevel_p(parser));
            pm_node_t *parameters = parse_blocklike_parameters(parser, (pm_node_t *) block_parameters, &operator, &parser->previous);

            pm_parser_scope_pop(parser);
            pm_accepts_block_stack_pop(parser);

            return (pm_node_t *) pm_lambda_node_create(parser, &locals, &operator, &opening, &parser->previous, parameters, body);
        }
        case PM_TOKEN_UPLUS: {
            if (binding_power > PM_BINDING_POWER_UNARY) {
                pm_parser_err_prefix(parser, PM_ERR_UNARY_DISALLOWED);
            }
            parser_lex(parser);

            pm_token_t operator = parser->previous;
            pm_node_t *receiver = parse_expression(parser, pm_binding_powers[parser->previous.type].right, false, false, PM_ERR_UNARY_RECEIVER, (uint16_t) (depth + 1));
            pm_call_node_t *node = pm_call_node_unary_create(parser, &operator, receiver, "+@");

            return (pm_node_t *) node;
        }
        case PM_TOKEN_STRING_BEGIN:
            return parse_strings(parser, NULL, accepts_label, (uint16_t) (depth + 1));
        case PM_TOKEN_SYMBOL_BEGIN: {
            pm_lex_mode_t lex_mode = *parser->lex_modes.current;
            parser_lex(parser);

            return parse_symbol(parser, &lex_mode, PM_LEX_STATE_END, (uint16_t) (depth + 1));
        }
        default: {
            pm_context_t recoverable = context_recoverable(parser, &parser->current);

            if (recoverable != PM_CONTEXT_NONE) {
                parser->recovering = true;

                // If the given error is not the generic one, then we'll add it
                // here because it will provide more context in addition to the
                // recoverable error that we will also add.
                if (diag_id != PM_ERR_CANNOT_PARSE_EXPRESSION) {
                    pm_parser_err_prefix(parser, diag_id);
                }

                // If we get here, then we are assuming this token is closing a
                // parent context, so we'll indicate that to the user so that
                // they know how we behaved.
                PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_UNEXPECTED_TOKEN_CLOSE_CONTEXT, pm_token_type_human(parser->current.type), context_human(recoverable));
            } else if (diag_id == PM_ERR_CANNOT_PARSE_EXPRESSION) {
                // We're going to make a special case here, because "cannot
                // parse expression" is pretty generic, and we know here that we
                // have an unexpected token.
                PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_UNEXPECTED_TOKEN_IGNORE, pm_token_type_human(parser->current.type));
            } else {
                pm_parser_err_prefix(parser, diag_id);
            }

            return (pm_node_t *) pm_missing_node_create(parser, parser->previous.start, parser->previous.end);
        }
    }
}

/**
 * Parse a value that is going to be written to some kind of variable or method
 * call. We need to handle this separately because the rescue modifier is
 * permitted on the end of the these expressions, which is a deviation from its
 * normal binding power.
 *
 * Note that this will only be called after an operator write, as in &&=, ||=,
 * or any of the binary operators that can be written to a variable.
 */
static pm_node_t *
parse_assignment_value(pm_parser_t *parser, pm_binding_power_t previous_binding_power, pm_binding_power_t binding_power, bool accepts_command_call, pm_diagnostic_id_t diag_id, uint16_t depth) {
    pm_node_t *value = parse_value_expression(parser, binding_power, previous_binding_power == PM_BINDING_POWER_ASSIGNMENT ? accepts_command_call : previous_binding_power < PM_BINDING_POWER_MATCH, false, diag_id, (uint16_t) (depth + 1));

    // Contradicting binding powers, the right-hand-side value of the assignment
    // allows the `rescue` modifier.
    if (match1(parser, PM_TOKEN_KEYWORD_RESCUE_MODIFIER)) {
        context_push(parser, PM_CONTEXT_RESCUE_MODIFIER);

        pm_token_t rescue = parser->current;
        parser_lex(parser);

        pm_node_t *right = parse_expression(parser, pm_binding_powers[PM_TOKEN_KEYWORD_RESCUE_MODIFIER].right, false, false, PM_ERR_RESCUE_MODIFIER_VALUE, (uint16_t) (depth + 1));
        context_pop(parser);

        return (pm_node_t *) pm_rescue_modifier_node_create(parser, value, &rescue, right);
    }

    return value;
}

/**
 * When a local variable write node is the value being written in a different
 * write, the local variable is considered "used".
 */
static void
parse_assignment_value_local(pm_parser_t *parser, const pm_node_t *node) {
    switch (PM_NODE_TYPE(node)) {
        case PM_BEGIN_NODE: {
            const pm_begin_node_t *cast = (const pm_begin_node_t *) node;
            if (cast->statements != NULL) parse_assignment_value_local(parser, (const pm_node_t *) cast->statements);
            break;
        }
        case PM_LOCAL_VARIABLE_WRITE_NODE: {
            const pm_local_variable_write_node_t *cast = (const pm_local_variable_write_node_t *) node;
            pm_locals_read(&pm_parser_scope_find(parser, cast->depth)->locals, cast->name);
            break;
        }
        case PM_PARENTHESES_NODE: {
            const pm_parentheses_node_t *cast = (const pm_parentheses_node_t *) node;
            if (cast->body != NULL) parse_assignment_value_local(parser, cast->body);
            break;
        }
        case PM_STATEMENTS_NODE: {
            const pm_statements_node_t *cast = (const pm_statements_node_t *) node;
            const pm_node_t *statement;

            PM_NODE_LIST_FOREACH(&cast->body, index, statement) {
                parse_assignment_value_local(parser, statement);
            }
            break;
        }
        default:
            break;
    }
}

/**
 * Parse the value (or values, through an implicit array) that is going to be
 * written to some kind of variable or method call. We need to handle this
 * separately because the rescue modifier is permitted on the end of the these
 * expressions, which is a deviation from its normal binding power.
 *
 * Additionally, if the value is a local variable write node (e.g., a = a = 1),
 * the "a" is marked as being used so the parser should not warn on it.
 *
 * Note that this will only be called after an = operator, as that is the only
 * operator that allows multiple values after it.
 */
static pm_node_t *
parse_assignment_values(pm_parser_t *parser, pm_binding_power_t previous_binding_power, pm_binding_power_t binding_power, bool accepts_command_call, pm_diagnostic_id_t diag_id, uint16_t depth) {
    bool permitted = true;
    if (previous_binding_power != PM_BINDING_POWER_STATEMENT && match1(parser, PM_TOKEN_USTAR)) permitted = false;

    pm_node_t *value = parse_starred_expression(parser, binding_power, previous_binding_power == PM_BINDING_POWER_ASSIGNMENT ? accepts_command_call : previous_binding_power < PM_BINDING_POWER_MATCH, diag_id, (uint16_t) (depth + 1));
    if (!permitted) pm_parser_err_node(parser, value, PM_ERR_UNEXPECTED_MULTI_WRITE);

    parse_assignment_value_local(parser, value);
    bool single_value = true;

    if (previous_binding_power == PM_BINDING_POWER_STATEMENT && (PM_NODE_TYPE_P(value, PM_SPLAT_NODE) || match1(parser, PM_TOKEN_COMMA))) {
        single_value = false;

        pm_token_t opening = not_provided(parser);
        pm_array_node_t *array = pm_array_node_create(parser, &opening);

        pm_array_node_elements_append(array, value);
        value = (pm_node_t *) array;

        while (accept1(parser, PM_TOKEN_COMMA)) {
            pm_node_t *element = parse_starred_expression(parser, binding_power, false, PM_ERR_ARRAY_ELEMENT, (uint16_t) (depth + 1));

            pm_array_node_elements_append(array, element);
            if (PM_NODE_TYPE_P(element, PM_MISSING_NODE)) break;

            parse_assignment_value_local(parser, element);
        }
    }

    // Contradicting binding powers, the right-hand-side value of the assignment
    // allows the `rescue` modifier.
    if ((single_value || (binding_power == (PM_BINDING_POWER_MULTI_ASSIGNMENT + 1))) && match1(parser, PM_TOKEN_KEYWORD_RESCUE_MODIFIER)) {
        context_push(parser, PM_CONTEXT_RESCUE_MODIFIER);

        pm_token_t rescue = parser->current;
        parser_lex(parser);

        bool accepts_command_call_inner = false;

        // RHS can accept command call iff the value is a call with arguments
        // but without parenthesis.
        if (PM_NODE_TYPE_P(value, PM_CALL_NODE)) {
            pm_call_node_t *call_node = (pm_call_node_t *) value;
            if ((call_node->arguments != NULL) && (call_node->opening_loc.start == NULL)) {
                accepts_command_call_inner = true;
            }
        }

        pm_node_t *right = parse_expression(parser, pm_binding_powers[PM_TOKEN_KEYWORD_RESCUE_MODIFIER].right, accepts_command_call_inner, false, PM_ERR_RESCUE_MODIFIER_VALUE, (uint16_t) (depth + 1));
        context_pop(parser);

        return (pm_node_t *) pm_rescue_modifier_node_create(parser, value, &rescue, right);
    }

    return value;
}

/**
 * Ensure a call node that is about to become a call operator node does not
 * have arguments or a block attached. If it does, then we'll need to add an
 * error message and destroy the arguments/block. Ideally we would keep the node
 * around so that consumers would still have access to it, but we don't have a
 * great structure for that at the moment.
 */
static void
parse_call_operator_write(pm_parser_t *parser, pm_call_node_t *call_node, const pm_token_t *operator) {
    if (call_node->arguments != NULL) {
        pm_parser_err_token(parser, operator, PM_ERR_OPERATOR_WRITE_ARGUMENTS);
        pm_node_destroy(parser, (pm_node_t *) call_node->arguments);
        call_node->arguments = NULL;
    }

    if (call_node->block != NULL) {
        pm_parser_err_token(parser, operator, PM_ERR_OPERATOR_WRITE_BLOCK);
        pm_node_destroy(parser, (pm_node_t *) call_node->block);
        call_node->block = NULL;
    }
}

/**
 * This struct is used to pass information between the regular expression parser
 * and the named capture callback.
 */
typedef struct {
    /** The parser that is parsing the regular expression. */
    pm_parser_t *parser;

    /** The call node wrapping the regular expression node. */
    pm_call_node_t *call;

    /** The match write node that is being created. */
    pm_match_write_node_t *match;

    /** The list of names that have been parsed. */
    pm_constant_id_list_t names;

    /**
     * Whether the content of the regular expression is shared. This impacts
     * whether or not we used owned constants or shared constants in the
     * constant pool for the names of the captures.
     */
    bool shared;
} parse_regular_expression_named_capture_data_t;

static inline const uint8_t *
pm_named_capture_escape_hex(pm_buffer_t *unescaped, const uint8_t *cursor, const uint8_t *end) {
    cursor++;

    if (cursor < end && pm_char_is_hexadecimal_digit(*cursor)) {
        uint8_t value = escape_hexadecimal_digit(*cursor);
        cursor++;

        if (cursor < end && pm_char_is_hexadecimal_digit(*cursor)) {
            value = (uint8_t) ((value << 4) | escape_hexadecimal_digit(*cursor));
            cursor++;
        }

        pm_buffer_append_byte(unescaped, value);
    } else {
        pm_buffer_append_string(unescaped, "\\x", 2);
    }

    return cursor;
}

static inline const uint8_t *
pm_named_capture_escape_octal(pm_buffer_t *unescaped, const uint8_t *cursor, const uint8_t *end) {
    uint8_t value = (uint8_t) (*cursor - '0');
    cursor++;

    if (cursor < end && pm_char_is_octal_digit(*cursor)) {
        value = ((uint8_t) (value << 3)) | ((uint8_t) (*cursor - '0'));
        cursor++;

        if (cursor < end && pm_char_is_octal_digit(*cursor)) {
            value = ((uint8_t) (value << 3)) | ((uint8_t) (*cursor - '0'));
            cursor++;
        }
    }

    pm_buffer_append_byte(unescaped, value);
    return cursor;
}

static inline const uint8_t *
pm_named_capture_escape_unicode(pm_parser_t *parser, pm_buffer_t *unescaped, const uint8_t *cursor, const uint8_t *end) {
    const uint8_t *start = cursor - 1;
    cursor++;

    if (cursor >= end) {
        pm_buffer_append_string(unescaped, "\\u", 2);
        return cursor;
    }

    if (*cursor != '{') {
        size_t length = pm_strspn_hexadecimal_digit(cursor, MIN(end - cursor, 4));
        uint32_t value = escape_unicode(parser, cursor, length);

        if (!pm_buffer_append_unicode_codepoint(unescaped, value)) {
            pm_buffer_append_string(unescaped, (const char *) start, (size_t) ((cursor + length) - start));
        }

        return cursor + length;
    }

    cursor++;
    for (;;) {
        while (cursor < end && *cursor == ' ') cursor++;

        if (cursor >= end) break;
        if (*cursor == '}') {
            cursor++;
            break;
        }

        size_t length = pm_strspn_hexadecimal_digit(cursor, end - cursor);
        uint32_t value = escape_unicode(parser, cursor, length);

        (void) pm_buffer_append_unicode_codepoint(unescaped, value);
        cursor += length;
    }

    return cursor;
}

static void
pm_named_capture_escape(pm_parser_t *parser, pm_buffer_t *unescaped, const uint8_t *source, const size_t length, const uint8_t *cursor) {
    const uint8_t *end = source + length;
    pm_buffer_append_string(unescaped, (const char *) source, (size_t) (cursor - source));

    for (;;) {
        if (++cursor >= end) {
            pm_buffer_append_byte(unescaped, '\\');
            return;
        }

        switch (*cursor) {
            case 'x':
                cursor = pm_named_capture_escape_hex(unescaped, cursor, end);
                break;
            case '0': case '1': case '2': case '3': case '4': case '5': case '6': case '7':
                cursor = pm_named_capture_escape_octal(unescaped, cursor, end);
                break;
            case 'u':
                cursor = pm_named_capture_escape_unicode(parser, unescaped, cursor, end);
                break;
            default:
                pm_buffer_append_byte(unescaped, '\\');
                break;
        }

        const uint8_t *next_cursor = pm_memchr(cursor, '\\', (size_t) (end - cursor), parser->encoding_changed, parser->encoding);
        if (next_cursor == NULL) break;

        pm_buffer_append_string(unescaped, (const char *) cursor, (size_t) (next_cursor - cursor));
        cursor = next_cursor;
    }

    pm_buffer_append_string(unescaped, (const char *) cursor, (size_t) (end - cursor));
}

/**
 * This callback is called when the regular expression parser encounters a named
 * capture group.
 */
static void
parse_regular_expression_named_capture(const pm_string_t *capture, void *data) {
    parse_regular_expression_named_capture_data_t *callback_data = (parse_regular_expression_named_capture_data_t *) data;

    pm_parser_t *parser = callback_data->parser;
    pm_call_node_t *call = callback_data->call;
    pm_constant_id_list_t *names = &callback_data->names;

    const uint8_t *source = pm_string_source(capture);
    size_t length = pm_string_length(capture);
    pm_buffer_t unescaped = { 0 };

    // First, we need to handle escapes within the name of the capture group.
    // This is because regular expressions have three different representations
    // in prism. The first is the plain source code. The second is the
    // representation that will be sent to the regular expression engine, which
    // is the value of the "unescaped" field. This is poorly named, because it
    // actually still contains escapes, just a subset of them that the regular
    // expression engine knows how to handle. The third representation is fully
    // unescaped, which is what we need.
    const uint8_t *cursor = pm_memchr(source, '\\', length, parser->encoding_changed, parser->encoding);
    if (PRISM_UNLIKELY(cursor != NULL)) {
        pm_named_capture_escape(parser, &unescaped, source, length, cursor);
        source = (const uint8_t *) pm_buffer_value(&unescaped);
        length = pm_buffer_length(&unescaped);
    }

    pm_location_t location;
    pm_constant_id_t name;

    // If the name of the capture group isn't a valid identifier, we do
    // not add it to the local table.
    if (!pm_slice_is_valid_local(parser, source, source + length)) {
        pm_buffer_free(&unescaped);
        return;
    }

    if (callback_data->shared) {
        // If the unescaped string is a slice of the source, then we can
        // copy the names directly. The pointers will line up.
        location = (pm_location_t) { .start = source, .end = source + length };
        name = pm_parser_constant_id_location(parser, location.start, location.end);
    } else {
        // Otherwise, the name is a slice of the malloc-ed owned string,
        // in which case we need to copy it out into a new string.
        location = (pm_location_t) { .start = call->receiver->location.start, .end = call->receiver->location.end };

        void *memory = xmalloc(length);
        if (memory == NULL) abort();

        memcpy(memory, source, length);
        name = pm_parser_constant_id_owned(parser, (uint8_t *) memory, length);
    }

    // Add this name to the list of constants if it is valid, not duplicated,
    // and not a keyword.
    if (name != 0 && !pm_constant_id_list_includes(names, name)) {
        pm_constant_id_list_append(names, name);

        int depth;
        if ((depth = pm_parser_local_depth_constant_id(parser, name)) == -1) {
            // If the local is not already a local but it is a keyword, then we
            // do not want to add a capture for this.
            if (pm_local_is_keyword((const char *) source, length)) {
                pm_buffer_free(&unescaped);
                return;
            }

            // If the identifier is not already a local, then we will add it to
            // the local table.
            pm_parser_local_add(parser, name, location.start, location.end, 0);
        }

        // Here we lazily create the MatchWriteNode since we know we're
        // about to add a target.
        if (callback_data->match == NULL) {
            callback_data->match = pm_match_write_node_create(parser, call);
        }

        // Next, create the local variable target and add it to the list of
        // targets for the match.
        pm_node_t *target = (pm_node_t *) pm_local_variable_target_node_create(parser, &location, name, depth == -1 ? 0 : (uint32_t) depth);
        pm_node_list_append(&callback_data->match->targets, target);
    }

    pm_buffer_free(&unescaped);
}

/**
 * Potentially change a =~ with a regular expression with named captures into a
 * match write node.
 */
static pm_node_t *
parse_regular_expression_named_captures(pm_parser_t *parser, const pm_string_t *content, pm_call_node_t *call, bool extended_mode) {
    parse_regular_expression_named_capture_data_t callback_data = {
        .parser = parser,
        .call = call,
        .names = { 0 },
        .shared = content->type == PM_STRING_SHARED
    };

    parse_regular_expression_error_data_t error_data = {
        .parser = parser,
        .start = call->receiver->location.start,
        .end = call->receiver->location.end,
        .shared = content->type == PM_STRING_SHARED
    };

    pm_regexp_parse(parser, pm_string_source(content), pm_string_length(content), extended_mode, parse_regular_expression_named_capture, &callback_data, parse_regular_expression_error, &error_data);
    pm_constant_id_list_free(&callback_data.names);

    if (callback_data.match != NULL) {
        return (pm_node_t *) callback_data.match;
    } else {
        return (pm_node_t *) call;
    }
}

static inline pm_node_t *
parse_expression_infix(pm_parser_t *parser, pm_node_t *node, pm_binding_power_t previous_binding_power, pm_binding_power_t binding_power, bool accepts_command_call, uint16_t depth) {
    pm_token_t token = parser->current;

    switch (token.type) {
        case PM_TOKEN_EQUAL: {
            switch (PM_NODE_TYPE(node)) {
                case PM_CALL_NODE: {
                    // If we have no arguments to the call node and we need this
                    // to be a target then this is either a method call or a
                    // local variable write. This _must_ happen before the value
                    // is parsed because it could be referenced in the value.
                    pm_call_node_t *call_node = (pm_call_node_t *) node;
                    if (PM_NODE_FLAG_P(call_node, PM_CALL_NODE_FLAGS_VARIABLE_CALL)) {
                        pm_parser_local_add_location(parser, call_node->message_loc.start, call_node->message_loc.end, 0);
                    }
                }
                PRISM_FALLTHROUGH
                case PM_CASE_WRITABLE: {
                    parser_lex(parser);
                    pm_node_t *value = parse_assignment_values(parser, previous_binding_power, PM_NODE_TYPE_P(node, PM_MULTI_TARGET_NODE) ? PM_BINDING_POWER_MULTI_ASSIGNMENT + 1 : binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_EQUAL, (uint16_t) (depth + 1));

                    if (PM_NODE_TYPE_P(node, PM_MULTI_TARGET_NODE) && previous_binding_power != PM_BINDING_POWER_STATEMENT) {
                        pm_parser_err_node(parser, node, PM_ERR_UNEXPECTED_MULTI_WRITE);
                    }

                    return parse_write(parser, node, &token, value);
                }
                case PM_SPLAT_NODE: {
                    pm_multi_target_node_t *multi_target = pm_multi_target_node_create(parser);
                    pm_multi_target_node_targets_append(parser, multi_target, node);

                    parser_lex(parser);
                    pm_node_t *value = parse_assignment_values(parser, previous_binding_power, PM_BINDING_POWER_MULTI_ASSIGNMENT + 1, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_EQUAL, (uint16_t) (depth + 1));
                    return parse_write(parser, (pm_node_t *) multi_target, &token, value);
                }
                case PM_SOURCE_ENCODING_NODE:
                case PM_FALSE_NODE:
                case PM_SOURCE_FILE_NODE:
                case PM_SOURCE_LINE_NODE:
                case PM_NIL_NODE:
                case PM_SELF_NODE:
                case PM_TRUE_NODE: {
                    // In these special cases, we have specific error messages
                    // and we will replace them with local variable writes.
                    parser_lex(parser);
                    pm_node_t *value = parse_assignment_values(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_EQUAL, (uint16_t) (depth + 1));
                    return parse_unwriteable_write(parser, node, &token, value);
                }
                default:
                    // In this case we have an = sign, but we don't know what
                    // it's for. We need to treat it as an error. We'll mark it
                    // as an error and skip past it.
                    parser_lex(parser);
                    pm_parser_err_token(parser, &token, PM_ERR_EXPRESSION_NOT_WRITABLE);
                    return node;
            }
        }
        case PM_TOKEN_AMPERSAND_AMPERSAND_EQUAL: {
            switch (PM_NODE_TYPE(node)) {
                case PM_BACK_REFERENCE_READ_NODE:
                case PM_NUMBERED_REFERENCE_READ_NODE:
                    PM_PARSER_ERR_NODE_FORMAT_CONTENT(parser, node, PM_ERR_WRITE_TARGET_READONLY);
                PRISM_FALLTHROUGH
                case PM_GLOBAL_VARIABLE_READ_NODE: {
                    parser_lex(parser);

                    pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_AMPAMPEQ, (uint16_t) (depth + 1));
                    pm_node_t *result = (pm_node_t *) pm_global_variable_and_write_node_create(parser, node, &token, value);

                    pm_node_destroy(parser, node);
                    return result;
                }
                case PM_CLASS_VARIABLE_READ_NODE: {
                    parser_lex(parser);

                    pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_AMPAMPEQ, (uint16_t) (depth + 1));
                    pm_node_t *result = (pm_node_t *) pm_class_variable_and_write_node_create(parser, (pm_class_variable_read_node_t *) node, &token, value);

                    pm_node_destroy(parser, node);
                    return result;
                }
                case PM_CONSTANT_PATH_NODE: {
                    parser_lex(parser);

                    pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_AMPAMPEQ, (uint16_t) (depth + 1));
                    pm_node_t *write = (pm_node_t *) pm_constant_path_and_write_node_create(parser, (pm_constant_path_node_t *) node, &token, value);

                    return parse_shareable_constant_write(parser, write);
                }
                case PM_CONSTANT_READ_NODE: {
                    parser_lex(parser);

                    pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_AMPAMPEQ, (uint16_t) (depth + 1));
                    pm_node_t *write = (pm_node_t *) pm_constant_and_write_node_create(parser, (pm_constant_read_node_t *) node, &token, value);

                    pm_node_destroy(parser, node);
                    return parse_shareable_constant_write(parser, write);
                }
                case PM_INSTANCE_VARIABLE_READ_NODE: {
                    parser_lex(parser);

                    pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_AMPAMPEQ, (uint16_t) (depth + 1));
                    pm_node_t *result = (pm_node_t *) pm_instance_variable_and_write_node_create(parser, (pm_instance_variable_read_node_t *) node, &token, value);

                    pm_node_destroy(parser, node);
                    return result;
                }
                case PM_IT_LOCAL_VARIABLE_READ_NODE: {
                    pm_constant_id_t name = pm_parser_local_add_constant(parser, "it", 2);
                    parser_lex(parser);

                    pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_AMPAMPEQ, (uint16_t) (depth + 1));
                    pm_node_t *result = (pm_node_t *) pm_local_variable_and_write_node_create(parser, node, &token, value, name, 0);

                    parse_target_implicit_parameter(parser, node);
                    pm_node_destroy(parser, node);
                    return result;
                }
                case PM_LOCAL_VARIABLE_READ_NODE: {
                    if (pm_token_is_numbered_parameter(node->location.start, node->location.end)) {
                        PM_PARSER_ERR_FORMAT(parser, node->location.start, node->location.end, PM_ERR_PARAMETER_NUMBERED_RESERVED, node->location.start);
                        parse_target_implicit_parameter(parser, node);
                    }

                    pm_local_variable_read_node_t *cast = (pm_local_variable_read_node_t *) node;
                    parser_lex(parser);

                    pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_AMPAMPEQ, (uint16_t) (depth + 1));
                    pm_node_t *result = (pm_node_t *) pm_local_variable_and_write_node_create(parser, node, &token, value, cast->name, cast->depth);

                    pm_node_destroy(parser, node);
                    return result;
                }
                case PM_CALL_NODE: {
                    pm_call_node_t *cast = (pm_call_node_t *) node;

                    // If we have a vcall (a method with no arguments and no
                    // receiver that could have been a local variable) then we
                    // will transform it into a local variable write.
                    if (PM_NODE_FLAG_P(cast, PM_CALL_NODE_FLAGS_VARIABLE_CALL)) {
                        pm_location_t *message_loc = &cast->message_loc;
                        pm_refute_numbered_parameter(parser, message_loc->start, message_loc->end);

                        pm_constant_id_t constant_id = pm_parser_local_add_location(parser, message_loc->start, message_loc->end, 1);
                        parser_lex(parser);

                        pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_AMPAMPEQ, (uint16_t) (depth + 1));
                        pm_node_t *result = (pm_node_t *) pm_local_variable_and_write_node_create(parser, (pm_node_t *) cast, &token, value, constant_id, 0);

                        pm_node_destroy(parser, (pm_node_t *) cast);
                        return result;
                    }

                    // Move past the token here so that we have already added
                    // the local variable by this point.
                    parser_lex(parser);

                    // If there is no call operator and the message is "[]" then
                    // this is an aref expression, and we can transform it into
                    // an aset expression.
                    if (PM_NODE_FLAG_P(cast, PM_CALL_NODE_FLAGS_INDEX)) {
                        pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_AMPAMPEQ, (uint16_t) (depth + 1));
                        return (pm_node_t *) pm_index_and_write_node_create(parser, cast, &token, value);
                    }

                    // If this node cannot be writable, then we have an error.
                    if (pm_call_node_writable_p(parser, cast)) {
                        parse_write_name(parser, &cast->name);
                    } else {
                        pm_parser_err_node(parser, node, PM_ERR_WRITE_TARGET_UNEXPECTED);
                    }

                    parse_call_operator_write(parser, cast, &token);
                    pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_AMPAMPEQ, (uint16_t) (depth + 1));
                    return (pm_node_t *) pm_call_and_write_node_create(parser, cast, &token, value);
                }
                case PM_MULTI_WRITE_NODE: {
                    parser_lex(parser);
                    pm_parser_err_token(parser, &token, PM_ERR_AMPAMPEQ_MULTI_ASSIGN);
                    return node;
                }
                default:
                    parser_lex(parser);

                    // In this case we have an &&= sign, but we don't know what it's for.
                    // We need to treat it as an error. For now, we'll mark it as an error
                    // and just skip right past it.
                    pm_parser_err_token(parser, &token, PM_ERR_EXPECT_EXPRESSION_AFTER_AMPAMPEQ);
                    return node;
            }
        }
        case PM_TOKEN_PIPE_PIPE_EQUAL: {
            switch (PM_NODE_TYPE(node)) {
                case PM_BACK_REFERENCE_READ_NODE:
                case PM_NUMBERED_REFERENCE_READ_NODE:
                    PM_PARSER_ERR_NODE_FORMAT_CONTENT(parser, node, PM_ERR_WRITE_TARGET_READONLY);
                PRISM_FALLTHROUGH
                case PM_GLOBAL_VARIABLE_READ_NODE: {
                    parser_lex(parser);

                    pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_PIPEPIPEEQ, (uint16_t) (depth + 1));
                    pm_node_t *result = (pm_node_t *) pm_global_variable_or_write_node_create(parser, node, &token, value);

                    pm_node_destroy(parser, node);
                    return result;
                }
                case PM_CLASS_VARIABLE_READ_NODE: {
                    parser_lex(parser);

                    pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_PIPEPIPEEQ, (uint16_t) (depth + 1));
                    pm_node_t *result = (pm_node_t *) pm_class_variable_or_write_node_create(parser, (pm_class_variable_read_node_t *) node, &token, value);

                    pm_node_destroy(parser, node);
                    return result;
                }
                case PM_CONSTANT_PATH_NODE: {
                    parser_lex(parser);

                    pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_PIPEPIPEEQ, (uint16_t) (depth + 1));
                    pm_node_t *write = (pm_node_t *) pm_constant_path_or_write_node_create(parser, (pm_constant_path_node_t *) node, &token, value);

                    return parse_shareable_constant_write(parser, write);
                }
                case PM_CONSTANT_READ_NODE: {
                    parser_lex(parser);

                    pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_PIPEPIPEEQ, (uint16_t) (depth + 1));
                    pm_node_t *write = (pm_node_t *) pm_constant_or_write_node_create(parser, (pm_constant_read_node_t *) node, &token, value);

                    pm_node_destroy(parser, node);
                    return parse_shareable_constant_write(parser, write);
                }
                case PM_INSTANCE_VARIABLE_READ_NODE: {
                    parser_lex(parser);

                    pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_PIPEPIPEEQ, (uint16_t) (depth + 1));
                    pm_node_t *result = (pm_node_t *) pm_instance_variable_or_write_node_create(parser, (pm_instance_variable_read_node_t *) node, &token, value);

                    pm_node_destroy(parser, node);
                    return result;
                }
                case PM_IT_LOCAL_VARIABLE_READ_NODE: {
                    pm_constant_id_t name = pm_parser_local_add_constant(parser, "it", 2);
                    parser_lex(parser);

                    pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_PIPEPIPEEQ, (uint16_t) (depth + 1));
                    pm_node_t *result = (pm_node_t *) pm_local_variable_or_write_node_create(parser, node, &token, value, name, 0);

                    parse_target_implicit_parameter(parser, node);
                    pm_node_destroy(parser, node);
                    return result;
                }
                case PM_LOCAL_VARIABLE_READ_NODE: {
                    if (pm_token_is_numbered_parameter(node->location.start, node->location.end)) {
                        PM_PARSER_ERR_FORMAT(parser, node->location.start, node->location.end, PM_ERR_PARAMETER_NUMBERED_RESERVED, node->location.start);
                        parse_target_implicit_parameter(parser, node);
                    }

                    pm_local_variable_read_node_t *cast = (pm_local_variable_read_node_t *) node;
                    parser_lex(parser);

                    pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_PIPEPIPEEQ, (uint16_t) (depth + 1));
                    pm_node_t *result = (pm_node_t *) pm_local_variable_or_write_node_create(parser, node, &token, value, cast->name, cast->depth);

                    pm_node_destroy(parser, node);
                    return result;
                }
                case PM_CALL_NODE: {
                    pm_call_node_t *cast = (pm_call_node_t *) node;

                    // If we have a vcall (a method with no arguments and no
                    // receiver that could have been a local variable) then we
                    // will transform it into a local variable write.
                    if (PM_NODE_FLAG_P(cast, PM_CALL_NODE_FLAGS_VARIABLE_CALL)) {
                        pm_location_t *message_loc = &cast->message_loc;
                        pm_refute_numbered_parameter(parser, message_loc->start, message_loc->end);

                        pm_constant_id_t constant_id = pm_parser_local_add_location(parser, message_loc->start, message_loc->end, 1);
                        parser_lex(parser);

                        pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_PIPEPIPEEQ, (uint16_t) (depth + 1));
                        pm_node_t *result = (pm_node_t *) pm_local_variable_or_write_node_create(parser, (pm_node_t *) cast, &token, value, constant_id, 0);

                        pm_node_destroy(parser, (pm_node_t *) cast);
                        return result;
                    }

                    // Move past the token here so that we have already added
                    // the local variable by this point.
                    parser_lex(parser);

                    // If there is no call operator and the message is "[]" then
                    // this is an aref expression, and we can transform it into
                    // an aset expression.
                    if (PM_NODE_FLAG_P(cast, PM_CALL_NODE_FLAGS_INDEX)) {
                        pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_PIPEPIPEEQ, (uint16_t) (depth + 1));
                        return (pm_node_t *) pm_index_or_write_node_create(parser, cast, &token, value);
                    }

                    // If this node cannot be writable, then we have an error.
                    if (pm_call_node_writable_p(parser, cast)) {
                        parse_write_name(parser, &cast->name);
                    } else {
                        pm_parser_err_node(parser, node, PM_ERR_WRITE_TARGET_UNEXPECTED);
                    }

                    parse_call_operator_write(parser, cast, &token);
                    pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_PIPEPIPEEQ, (uint16_t) (depth + 1));
                    return (pm_node_t *) pm_call_or_write_node_create(parser, cast, &token, value);
                }
                case PM_MULTI_WRITE_NODE: {
                    parser_lex(parser);
                    pm_parser_err_token(parser, &token, PM_ERR_PIPEPIPEEQ_MULTI_ASSIGN);
                    return node;
                }
                default:
                    parser_lex(parser);

                    // In this case we have an ||= sign, but we don't know what it's for.
                    // We need to treat it as an error. For now, we'll mark it as an error
                    // and just skip right past it.
                    pm_parser_err_token(parser, &token, PM_ERR_EXPECT_EXPRESSION_AFTER_PIPEPIPEEQ);
                    return node;
            }
        }
        case PM_TOKEN_AMPERSAND_EQUAL:
        case PM_TOKEN_CARET_EQUAL:
        case PM_TOKEN_GREATER_GREATER_EQUAL:
        case PM_TOKEN_LESS_LESS_EQUAL:
        case PM_TOKEN_MINUS_EQUAL:
        case PM_TOKEN_PERCENT_EQUAL:
        case PM_TOKEN_PIPE_EQUAL:
        case PM_TOKEN_PLUS_EQUAL:
        case PM_TOKEN_SLASH_EQUAL:
        case PM_TOKEN_STAR_EQUAL:
        case PM_TOKEN_STAR_STAR_EQUAL: {
            switch (PM_NODE_TYPE(node)) {
                case PM_BACK_REFERENCE_READ_NODE:
                case PM_NUMBERED_REFERENCE_READ_NODE:
                    PM_PARSER_ERR_NODE_FORMAT_CONTENT(parser, node, PM_ERR_WRITE_TARGET_READONLY);
                PRISM_FALLTHROUGH
                case PM_GLOBAL_VARIABLE_READ_NODE: {
                    parser_lex(parser);

                    pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_OPERATOR, (uint16_t) (depth + 1));
                    pm_node_t *result = (pm_node_t *) pm_global_variable_operator_write_node_create(parser, node, &token, value);

                    pm_node_destroy(parser, node);
                    return result;
                }
                case PM_CLASS_VARIABLE_READ_NODE: {
                    parser_lex(parser);

                    pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_OPERATOR, (uint16_t) (depth + 1));
                    pm_node_t *result = (pm_node_t *) pm_class_variable_operator_write_node_create(parser, (pm_class_variable_read_node_t *) node, &token, value);

                    pm_node_destroy(parser, node);
                    return result;
                }
                case PM_CONSTANT_PATH_NODE: {
                    parser_lex(parser);

                    pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_OPERATOR, (uint16_t) (depth + 1));
                    pm_node_t *write = (pm_node_t *) pm_constant_path_operator_write_node_create(parser, (pm_constant_path_node_t *) node, &token, value);

                    return parse_shareable_constant_write(parser, write);
                }
                case PM_CONSTANT_READ_NODE: {
                    parser_lex(parser);

                    pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_OPERATOR, (uint16_t) (depth + 1));
                    pm_node_t *write = (pm_node_t *) pm_constant_operator_write_node_create(parser, (pm_constant_read_node_t *) node, &token, value);

                    pm_node_destroy(parser, node);
                    return parse_shareable_constant_write(parser, write);
                }
                case PM_INSTANCE_VARIABLE_READ_NODE: {
                    parser_lex(parser);

                    pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_OPERATOR, (uint16_t) (depth + 1));
                    pm_node_t *result = (pm_node_t *) pm_instance_variable_operator_write_node_create(parser, (pm_instance_variable_read_node_t *) node, &token, value);

                    pm_node_destroy(parser, node);
                    return result;
                }
                case PM_IT_LOCAL_VARIABLE_READ_NODE: {
                    pm_constant_id_t name = pm_parser_local_add_constant(parser, "it", 2);
                    parser_lex(parser);

                    pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_OPERATOR, (uint16_t) (depth + 1));
                    pm_node_t *result = (pm_node_t *) pm_local_variable_operator_write_node_create(parser, node, &token, value, name, 0);

                    parse_target_implicit_parameter(parser, node);
                    pm_node_destroy(parser, node);
                    return result;
                }
                case PM_LOCAL_VARIABLE_READ_NODE: {
                    if (pm_token_is_numbered_parameter(node->location.start, node->location.end)) {
                        PM_PARSER_ERR_FORMAT(parser, node->location.start, node->location.end, PM_ERR_PARAMETER_NUMBERED_RESERVED, node->location.start);
                        parse_target_implicit_parameter(parser, node);
                    }

                    pm_local_variable_read_node_t *cast = (pm_local_variable_read_node_t *) node;
                    parser_lex(parser);

                    pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_OPERATOR, (uint16_t) (depth + 1));
                    pm_node_t *result = (pm_node_t *) pm_local_variable_operator_write_node_create(parser, node, &token, value, cast->name, cast->depth);

                    pm_node_destroy(parser, node);
                    return result;
                }
                case PM_CALL_NODE: {
                    parser_lex(parser);
                    pm_call_node_t *cast = (pm_call_node_t *) node;

                    // If we have a vcall (a method with no arguments and no
                    // receiver that could have been a local variable) then we
                    // will transform it into a local variable write.
                    if (PM_NODE_FLAG_P(cast, PM_CALL_NODE_FLAGS_VARIABLE_CALL)) {
                        pm_location_t *message_loc = &cast->message_loc;
                        pm_refute_numbered_parameter(parser, message_loc->start, message_loc->end);

                        pm_constant_id_t constant_id = pm_parser_local_add_location(parser, message_loc->start, message_loc->end, 1);
                        pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_OPERATOR, (uint16_t) (depth + 1));
                        pm_node_t *result = (pm_node_t *) pm_local_variable_operator_write_node_create(parser, (pm_node_t *) cast, &token, value, constant_id, 0);

                        pm_node_destroy(parser, (pm_node_t *) cast);
                        return result;
                    }

                    // If there is no call operator and the message is "[]" then
                    // this is an aref expression, and we can transform it into
                    // an aset expression.
                    if (PM_NODE_FLAG_P(cast, PM_CALL_NODE_FLAGS_INDEX)) {
                        pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_OPERATOR, (uint16_t) (depth + 1));
                        return (pm_node_t *) pm_index_operator_write_node_create(parser, cast, &token, value);
                    }

                    // If this node cannot be writable, then we have an error.
                    if (pm_call_node_writable_p(parser, cast)) {
                        parse_write_name(parser, &cast->name);
                    } else {
                        pm_parser_err_node(parser, node, PM_ERR_WRITE_TARGET_UNEXPECTED);
                    }

                    parse_call_operator_write(parser, cast, &token);
                    pm_node_t *value = parse_assignment_value(parser, previous_binding_power, binding_power, accepts_command_call, PM_ERR_EXPECT_EXPRESSION_AFTER_OPERATOR, (uint16_t) (depth + 1));
                    return (pm_node_t *) pm_call_operator_write_node_create(parser, cast, &token, value);
                }
                case PM_MULTI_WRITE_NODE: {
                    parser_lex(parser);
                    pm_parser_err_token(parser, &token, PM_ERR_OPERATOR_MULTI_ASSIGN);
                    return node;
                }
                default:
                    parser_lex(parser);

                    // In this case we have an operator but we don't know what it's for.
                    // We need to treat it as an error. For now, we'll mark it as an error
                    // and just skip right past it.
                    PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->previous, PM_ERR_EXPECT_EXPRESSION_AFTER_OPERATOR, pm_token_type_human(parser->current.type));
                    return node;
            }
        }
        case PM_TOKEN_AMPERSAND_AMPERSAND:
        case PM_TOKEN_KEYWORD_AND: {
            parser_lex(parser);

            pm_node_t *right = parse_expression(parser, binding_power, parser->previous.type == PM_TOKEN_KEYWORD_AND, false, PM_ERR_EXPECT_EXPRESSION_AFTER_OPERATOR, (uint16_t) (depth + 1));
            return (pm_node_t *) pm_and_node_create(parser, node, &token, right);
        }
        case PM_TOKEN_KEYWORD_OR:
        case PM_TOKEN_PIPE_PIPE: {
            parser_lex(parser);

            pm_node_t *right = parse_expression(parser, binding_power, parser->previous.type == PM_TOKEN_KEYWORD_OR, false, PM_ERR_EXPECT_EXPRESSION_AFTER_OPERATOR, (uint16_t) (depth + 1));
            return (pm_node_t *) pm_or_node_create(parser, node, &token, right);
        }
        case PM_TOKEN_EQUAL_TILDE: {
            // Note that we _must_ parse the value before adding the local
            // variables in order to properly mirror the behavior of Ruby. For
            // example,
            //
            //     /(?<foo>bar)/ =~ foo
            //
            // In this case, `foo` should be a method call and not a local yet.
            parser_lex(parser);
            pm_node_t *argument = parse_expression(parser, binding_power, false, false, PM_ERR_EXPECT_EXPRESSION_AFTER_OPERATOR, (uint16_t) (depth + 1));

            // By default, we're going to create a call node and then return it.
            pm_call_node_t *call = pm_call_node_binary_create(parser, node, &token, argument, 0);
            pm_node_t *result = (pm_node_t *) call;

            // If the receiver of this =~ is a regular expression node, then we
            // need to introduce local variables for it based on its named
            // capture groups.
            if (PM_NODE_TYPE_P(node, PM_INTERPOLATED_REGULAR_EXPRESSION_NODE)) {
                // It's possible to have an interpolated regular expression node
                // that only contains strings. This is because it can be split
                // up by a heredoc. In this case we need to concat the unescaped
                // strings together and then parse them as a regular expression.
                pm_node_list_t *parts = &((pm_interpolated_regular_expression_node_t *) node)->parts;

                bool interpolated = false;
                size_t total_length = 0;

                pm_node_t *part;
                PM_NODE_LIST_FOREACH(parts, index, part) {
                    if (PM_NODE_TYPE_P(part, PM_STRING_NODE)) {
                        total_length += pm_string_length(&((pm_string_node_t *) part)->unescaped);
                    } else {
                        interpolated = true;
                        break;
                    }
                }

                if (!interpolated && total_length > 0) {
                    void *memory = xmalloc(total_length);
                    if (!memory) abort();

                    uint8_t *cursor = memory;
                    PM_NODE_LIST_FOREACH(parts, index, part) {
                        pm_string_t *unescaped = &((pm_string_node_t *) part)->unescaped;
                        size_t length = pm_string_length(unescaped);

                        memcpy(cursor, pm_string_source(unescaped), length);
                        cursor += length;
                    }

                    pm_string_t owned;
                    pm_string_owned_init(&owned, (uint8_t *) memory, total_length);

                    result = parse_regular_expression_named_captures(parser, &owned, call, PM_NODE_FLAG_P(node, PM_REGULAR_EXPRESSION_FLAGS_EXTENDED));
                    pm_string_free(&owned);
                }
            } else if (PM_NODE_TYPE_P(node, PM_REGULAR_EXPRESSION_NODE)) {
                // If we have a regular expression node, then we can just parse
                // the named captures directly off the unescaped string.
                const pm_string_t *content = &((pm_regular_expression_node_t *) node)->unescaped;
                result = parse_regular_expression_named_captures(parser, content, call, PM_NODE_FLAG_P(node, PM_REGULAR_EXPRESSION_FLAGS_EXTENDED));
            }

            return result;
        }
        case PM_TOKEN_UAMPERSAND:
        case PM_TOKEN_USTAR:
        case PM_TOKEN_USTAR_STAR:
            // The only times this will occur are when we are in an error state,
            // but we'll put them in here so that errors can propagate.
        case PM_TOKEN_BANG_EQUAL:
        case PM_TOKEN_BANG_TILDE:
        case PM_TOKEN_EQUAL_EQUAL:
        case PM_TOKEN_EQUAL_EQUAL_EQUAL:
        case PM_TOKEN_LESS_EQUAL_GREATER:
        case PM_TOKEN_CARET:
        case PM_TOKEN_PIPE:
        case PM_TOKEN_AMPERSAND:
        case PM_TOKEN_GREATER_GREATER:
        case PM_TOKEN_LESS_LESS:
        case PM_TOKEN_MINUS:
        case PM_TOKEN_PLUS:
        case PM_TOKEN_PERCENT:
        case PM_TOKEN_SLASH:
        case PM_TOKEN_STAR:
        case PM_TOKEN_STAR_STAR: {
            parser_lex(parser);
            pm_token_t operator = parser->previous;
            switch (PM_NODE_TYPE(node)) {
                case PM_RESCUE_MODIFIER_NODE: {
                    pm_rescue_modifier_node_t *cast = (pm_rescue_modifier_node_t *) node;
                    if (PM_NODE_TYPE_P(cast->rescue_expression, PM_MATCH_PREDICATE_NODE) || PM_NODE_TYPE_P(cast->rescue_expression, PM_MATCH_REQUIRED_NODE)) {
                        PM_PARSER_ERR_TOKEN_FORMAT(parser, operator, PM_ERR_EXPECT_EOL_AFTER_STATEMENT, pm_token_type_human(operator.type));
                    }
                    break;
                }
                case PM_AND_NODE: {
                    pm_and_node_t *cast = (pm_and_node_t *) node;
                    if (PM_NODE_TYPE_P(cast->right, PM_MATCH_PREDICATE_NODE) || PM_NODE_TYPE_P(cast->right, PM_MATCH_REQUIRED_NODE)) {
                        PM_PARSER_ERR_TOKEN_FORMAT(parser, operator, PM_ERR_EXPECT_EOL_AFTER_STATEMENT, pm_token_type_human(operator.type));
                    }
                    break;
                }
                case PM_OR_NODE: {
                    pm_or_node_t *cast = (pm_or_node_t *) node;
                    if (PM_NODE_TYPE_P(cast->right, PM_MATCH_PREDICATE_NODE) || PM_NODE_TYPE_P(cast->right, PM_MATCH_REQUIRED_NODE)) {
                        PM_PARSER_ERR_TOKEN_FORMAT(parser, operator, PM_ERR_EXPECT_EOL_AFTER_STATEMENT, pm_token_type_human(operator.type));
                    }
                    break;
                }
                default:
                    break;
            }

            pm_node_t *argument = parse_expression(parser, binding_power, false, false, PM_ERR_EXPECT_EXPRESSION_AFTER_OPERATOR, (uint16_t) (depth + 1));
            return (pm_node_t *) pm_call_node_binary_create(parser, node, &token, argument, 0);
        }
        case PM_TOKEN_GREATER:
        case PM_TOKEN_GREATER_EQUAL:
        case PM_TOKEN_LESS:
        case PM_TOKEN_LESS_EQUAL: {
            if (PM_NODE_TYPE_P(node, PM_CALL_NODE) && PM_NODE_FLAG_P(node, PM_CALL_NODE_FLAGS_COMPARISON)) {
                PM_PARSER_WARN_TOKEN_FORMAT_CONTENT(parser, parser->current, PM_WARN_COMPARISON_AFTER_COMPARISON);
            }

            parser_lex(parser);
            pm_node_t *argument = parse_expression(parser, binding_power, false, false, PM_ERR_EXPECT_EXPRESSION_AFTER_OPERATOR, (uint16_t) (depth + 1));
            return (pm_node_t *) pm_call_node_binary_create(parser, node, &token, argument, PM_CALL_NODE_FLAGS_COMPARISON);
        }
        case PM_TOKEN_AMPERSAND_DOT:
        case PM_TOKEN_DOT: {
            parser_lex(parser);
            pm_token_t operator = parser->previous;
            pm_arguments_t arguments = { 0 };

            // This if statement handles the foo.() syntax.
            if (match1(parser, PM_TOKEN_PARENTHESIS_LEFT)) {
                parse_arguments_list(parser, &arguments, true, false, (uint16_t) (depth + 1));
                return (pm_node_t *) pm_call_node_shorthand_create(parser, node, &operator, &arguments);
            }

            switch (PM_NODE_TYPE(node)) {
                case PM_RESCUE_MODIFIER_NODE: {
                    pm_rescue_modifier_node_t *cast = (pm_rescue_modifier_node_t *) node;
                    if (PM_NODE_TYPE_P(cast->rescue_expression, PM_MATCH_PREDICATE_NODE) || PM_NODE_TYPE_P(cast->rescue_expression, PM_MATCH_REQUIRED_NODE)) {
                        PM_PARSER_ERR_TOKEN_FORMAT(parser, operator, PM_ERR_EXPECT_EOL_AFTER_STATEMENT, pm_token_type_human(operator.type));
                    }
                    break;
                }
                case PM_AND_NODE: {
                    pm_and_node_t *cast = (pm_and_node_t *) node;
                    if (PM_NODE_TYPE_P(cast->right, PM_MATCH_PREDICATE_NODE) || PM_NODE_TYPE_P(cast->right, PM_MATCH_REQUIRED_NODE)) {
                        PM_PARSER_ERR_TOKEN_FORMAT(parser, operator, PM_ERR_EXPECT_EOL_AFTER_STATEMENT, pm_token_type_human(operator.type));
                    }
                    break;
                }
                case PM_OR_NODE: {
                    pm_or_node_t *cast = (pm_or_node_t *) node;
                    if (PM_NODE_TYPE_P(cast->right, PM_MATCH_PREDICATE_NODE) || PM_NODE_TYPE_P(cast->right, PM_MATCH_REQUIRED_NODE)) {
                        PM_PARSER_ERR_TOKEN_FORMAT(parser, operator, PM_ERR_EXPECT_EOL_AFTER_STATEMENT, pm_token_type_human(operator.type));
                    }
                    break;
                }
                default:
                    break;
            }

            pm_token_t message;

            switch (parser->current.type) {
                case PM_CASE_OPERATOR:
                case PM_CASE_KEYWORD:
                case PM_TOKEN_CONSTANT:
                case PM_TOKEN_IDENTIFIER:
                case PM_TOKEN_METHOD_NAME: {
                    parser_lex(parser);
                    message = parser->previous;
                    break;
                }
                default: {
                    PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_EXPECT_MESSAGE, pm_token_type_human(parser->current.type));
                    message = (pm_token_t) { .type = PM_TOKEN_MISSING, .start = parser->previous.end, .end = parser->previous.end };
                }
            }

            parse_arguments_list(parser, &arguments, true, accepts_command_call, (uint16_t) (depth + 1));
            pm_call_node_t *call = pm_call_node_call_create(parser, node, &operator, &message, &arguments);

            if (
                (previous_binding_power == PM_BINDING_POWER_STATEMENT) &&
                arguments.arguments == NULL &&
                arguments.opening_loc.start == NULL &&
                match1(parser, PM_TOKEN_COMMA)
            ) {
                return parse_targets_validate(parser, (pm_node_t *) call, PM_BINDING_POWER_INDEX, (uint16_t) (depth + 1));
            } else {
                return (pm_node_t *) call;
            }
        }
        case PM_TOKEN_DOT_DOT:
        case PM_TOKEN_DOT_DOT_DOT: {
            parser_lex(parser);

            pm_node_t *right = NULL;
            if (token_begins_expression_p(parser->current.type)) {
                right = parse_expression(parser, binding_power, false, false, PM_ERR_EXPECT_EXPRESSION_AFTER_OPERATOR, (uint16_t) (depth + 1));
            }

            return (pm_node_t *) pm_range_node_create(parser, node, &token, right);
        }
        case PM_TOKEN_KEYWORD_IF_MODIFIER: {
            pm_token_t keyword = parser->current;
            parser_lex(parser);

            pm_node_t *predicate = parse_value_expression(parser, binding_power, true, false, PM_ERR_CONDITIONAL_IF_PREDICATE, (uint16_t) (depth + 1));
            return (pm_node_t *) pm_if_node_modifier_create(parser, node, &keyword, predicate);
        }
        case PM_TOKEN_KEYWORD_UNLESS_MODIFIER: {
            pm_token_t keyword = parser->current;
            parser_lex(parser);

            pm_node_t *predicate = parse_value_expression(parser, binding_power, true, false, PM_ERR_CONDITIONAL_UNLESS_PREDICATE, (uint16_t) (depth + 1));
            return (pm_node_t *) pm_unless_node_modifier_create(parser, node, &keyword, predicate);
        }
        case PM_TOKEN_KEYWORD_UNTIL_MODIFIER: {
            parser_lex(parser);
            pm_statements_node_t *statements = pm_statements_node_create(parser);
            pm_statements_node_body_append(parser, statements, node, true);

            pm_node_t *predicate = parse_value_expression(parser, binding_power, true, false, PM_ERR_CONDITIONAL_UNTIL_PREDICATE, (uint16_t) (depth + 1));
            return (pm_node_t *) pm_until_node_modifier_create(parser, &token, predicate, statements, PM_NODE_TYPE_P(node, PM_BEGIN_NODE) ? PM_LOOP_FLAGS_BEGIN_MODIFIER : 0);
        }
        case PM_TOKEN_KEYWORD_WHILE_MODIFIER: {
            parser_lex(parser);
            pm_statements_node_t *statements = pm_statements_node_create(parser);
            pm_statements_node_body_append(parser, statements, node, true);

            pm_node_t *predicate = parse_value_expression(parser, binding_power, true, false, PM_ERR_CONDITIONAL_WHILE_PREDICATE, (uint16_t) (depth + 1));
            return (pm_node_t *) pm_while_node_modifier_create(parser, &token, predicate, statements, PM_NODE_TYPE_P(node, PM_BEGIN_NODE) ? PM_LOOP_FLAGS_BEGIN_MODIFIER : 0);
        }
        case PM_TOKEN_QUESTION_MARK: {
            context_push(parser, PM_CONTEXT_TERNARY);
            pm_node_list_t current_block_exits = { 0 };
            pm_node_list_t *previous_block_exits = push_block_exits(parser, &current_block_exits);

            pm_token_t qmark = parser->current;
            parser_lex(parser);

            pm_node_t *true_expression = parse_expression(parser, PM_BINDING_POWER_DEFINED, false, false, PM_ERR_TERNARY_EXPRESSION_TRUE, (uint16_t) (depth + 1));

            if (parser->recovering) {
                // If parsing the true expression of this ternary resulted in a syntax
                // error that we can recover from, then we're going to put missing nodes
                // and tokens into the remaining places. We want to be sure to do this
                // before the `expect` function call to make sure it doesn't
                // accidentally move past a ':' token that occurs after the syntax
                // error.
                pm_token_t colon = (pm_token_t) { .type = PM_TOKEN_MISSING, .start = parser->previous.end, .end = parser->previous.end };
                pm_node_t *false_expression = (pm_node_t *) pm_missing_node_create(parser, colon.start, colon.end);

                context_pop(parser);
                pop_block_exits(parser, previous_block_exits);
                pm_node_list_free(&current_block_exits);

                return (pm_node_t *) pm_if_node_ternary_create(parser, node, &qmark, true_expression, &colon, false_expression);
            }

            accept1(parser, PM_TOKEN_NEWLINE);
            expect1(parser, PM_TOKEN_COLON, PM_ERR_TERNARY_COLON);

            pm_token_t colon = parser->previous;
            pm_node_t *false_expression = parse_expression(parser, PM_BINDING_POWER_DEFINED, false, false, PM_ERR_TERNARY_EXPRESSION_FALSE, (uint16_t) (depth + 1));

            context_pop(parser);
            pop_block_exits(parser, previous_block_exits);
            pm_node_list_free(&current_block_exits);

            return (pm_node_t *) pm_if_node_ternary_create(parser, node, &qmark, true_expression, &colon, false_expression);
        }
        case PM_TOKEN_COLON_COLON: {
            parser_lex(parser);
            pm_token_t delimiter = parser->previous;

            switch (parser->current.type) {
                case PM_TOKEN_CONSTANT: {
                    parser_lex(parser);
                    pm_node_t *path;

                    if (
                        (parser->current.type == PM_TOKEN_PARENTHESIS_LEFT) ||
                        (accepts_command_call && (token_begins_expression_p(parser->current.type) || match3(parser, PM_TOKEN_UAMPERSAND, PM_TOKEN_USTAR, PM_TOKEN_USTAR_STAR)))
                    ) {
                        // If we have a constant immediately following a '::' operator, then
                        // this can either be a constant path or a method call, depending on
                        // what follows the constant.
                        //
                        // If we have parentheses, then this is a method call. That would
                        // look like Foo::Bar().
                        pm_token_t message = parser->previous;
                        pm_arguments_t arguments = { 0 };

                        parse_arguments_list(parser, &arguments, true, accepts_command_call, (uint16_t) (depth + 1));
                        path = (pm_node_t *) pm_call_node_call_create(parser, node, &delimiter, &message, &arguments);
                    } else {
                        // Otherwise, this is a constant path. That would look like Foo::Bar.
                        path = (pm_node_t *) pm_constant_path_node_create(parser, node, &delimiter, &parser->previous);
                    }

                    // If this is followed by a comma then it is a multiple assignment.
                    if (previous_binding_power == PM_BINDING_POWER_STATEMENT && match1(parser, PM_TOKEN_COMMA)) {
                        return parse_targets_validate(parser, path, PM_BINDING_POWER_INDEX, (uint16_t) (depth + 1));
                    }

                    return path;
                }
                case PM_CASE_OPERATOR:
                case PM_CASE_KEYWORD:
                case PM_TOKEN_IDENTIFIER:
                case PM_TOKEN_METHOD_NAME: {
                    parser_lex(parser);
                    pm_token_t message = parser->previous;

                    // If we have an identifier following a '::' operator, then it is for
                    // sure a method call.
                    pm_arguments_t arguments = { 0 };
                    parse_arguments_list(parser, &arguments, true, accepts_command_call, (uint16_t) (depth + 1));
                    pm_call_node_t *call = pm_call_node_call_create(parser, node, &delimiter, &message, &arguments);

                    // If this is followed by a comma then it is a multiple assignment.
                    if (previous_binding_power == PM_BINDING_POWER_STATEMENT && match1(parser, PM_TOKEN_COMMA)) {
                        return parse_targets_validate(parser, (pm_node_t *) call, PM_BINDING_POWER_INDEX, (uint16_t) (depth + 1));
                    }

                    return (pm_node_t *) call;
                }
                case PM_TOKEN_PARENTHESIS_LEFT: {
                    // If we have a parenthesis following a '::' operator, then it is the
                    // method call shorthand. That would look like Foo::(bar).
                    pm_arguments_t arguments = { 0 };
                    parse_arguments_list(parser, &arguments, true, false, (uint16_t) (depth + 1));

                    return (pm_node_t *) pm_call_node_shorthand_create(parser, node, &delimiter, &arguments);
                }
                default: {
                    expect1(parser, PM_TOKEN_CONSTANT, PM_ERR_CONSTANT_PATH_COLON_COLON_CONSTANT);
                    return (pm_node_t *) pm_constant_path_node_create(parser, node, &delimiter, &parser->previous);
                }
            }
        }
        case PM_TOKEN_KEYWORD_RESCUE_MODIFIER: {
            context_push(parser, PM_CONTEXT_RESCUE_MODIFIER);
            parser_lex(parser);
            accept1(parser, PM_TOKEN_NEWLINE);

            pm_node_t *value = parse_expression(parser, binding_power, true, false, PM_ERR_RESCUE_MODIFIER_VALUE, (uint16_t) (depth + 1));
            context_pop(parser);

            return (pm_node_t *) pm_rescue_modifier_node_create(parser, node, &token, value);
        }
        case PM_TOKEN_BRACKET_LEFT: {
            parser_lex(parser);

            pm_arguments_t arguments = { 0 };
            arguments.opening_loc = PM_LOCATION_TOKEN_VALUE(&parser->previous);

            if (!accept1(parser, PM_TOKEN_BRACKET_RIGHT)) {
                pm_accepts_block_stack_push(parser, true);
                parse_arguments(parser, &arguments, false, PM_TOKEN_BRACKET_RIGHT, (uint16_t) (depth + 1));
                pm_accepts_block_stack_pop(parser);
                expect1(parser, PM_TOKEN_BRACKET_RIGHT, PM_ERR_EXPECT_RBRACKET);
            }

            arguments.closing_loc = PM_LOCATION_TOKEN_VALUE(&parser->previous);

            // If we have a comma after the closing bracket then this is a multiple
            // assignment and we should parse the targets.
            if (previous_binding_power == PM_BINDING_POWER_STATEMENT && match1(parser, PM_TOKEN_COMMA)) {
                pm_call_node_t *aref = pm_call_node_aref_create(parser, node, &arguments);
                return parse_targets_validate(parser, (pm_node_t *) aref, PM_BINDING_POWER_INDEX, (uint16_t) (depth + 1));
            }

            // If we're at the end of the arguments, we can now check if there is a
            // block node that starts with a {. If there is, then we can parse it and
            // add it to the arguments.
            pm_block_node_t *block = NULL;
            if (accept1(parser, PM_TOKEN_BRACE_LEFT)) {
                block = parse_block(parser, (uint16_t) (depth + 1));
                pm_arguments_validate_block(parser, &arguments, block);
            } else if (pm_accepts_block_stack_p(parser) && accept1(parser, PM_TOKEN_KEYWORD_DO)) {
                block = parse_block(parser, (uint16_t) (depth + 1));
            }

            if (block != NULL) {
                if (arguments.block != NULL) {
                    pm_parser_err_node(parser, (pm_node_t *) block, PM_ERR_ARGUMENT_AFTER_BLOCK);
                    if (arguments.arguments == NULL) {
                        arguments.arguments = pm_arguments_node_create(parser);
                    }
                    pm_arguments_node_arguments_append(arguments.arguments, arguments.block);
                }

                arguments.block = (pm_node_t *) block;
            }

            return (pm_node_t *) pm_call_node_aref_create(parser, node, &arguments);
        }
        case PM_TOKEN_KEYWORD_IN: {
            bool previous_pattern_matching_newlines = parser->pattern_matching_newlines;
            parser->pattern_matching_newlines = true;

            pm_token_t operator = parser->current;
            parser->command_start = false;
            lex_state_set(parser, PM_LEX_STATE_BEG | PM_LEX_STATE_LABEL);
            parser_lex(parser);

            pm_constant_id_list_t captures = { 0 };
            pm_node_t *pattern = parse_pattern(parser, &captures, PM_PARSE_PATTERN_TOP | PM_PARSE_PATTERN_MULTI, PM_ERR_PATTERN_EXPRESSION_AFTER_IN, (uint16_t) (depth + 1));

            parser->pattern_matching_newlines = previous_pattern_matching_newlines;
            pm_constant_id_list_free(&captures);

            return (pm_node_t *) pm_match_predicate_node_create(parser, node, pattern, &operator);
        }
        case PM_TOKEN_EQUAL_GREATER: {
            bool previous_pattern_matching_newlines = parser->pattern_matching_newlines;
            parser->pattern_matching_newlines = true;

            pm_token_t operator = parser->current;
            parser->command_start = false;
            lex_state_set(parser, PM_LEX_STATE_BEG | PM_LEX_STATE_LABEL);
            parser_lex(parser);

            pm_constant_id_list_t captures = { 0 };
            pm_node_t *pattern = parse_pattern(parser, &captures, PM_PARSE_PATTERN_TOP | PM_PARSE_PATTERN_MULTI, PM_ERR_PATTERN_EXPRESSION_AFTER_HROCKET, (uint16_t) (depth + 1));

            parser->pattern_matching_newlines = previous_pattern_matching_newlines;
            pm_constant_id_list_free(&captures);

            return (pm_node_t *) pm_match_required_node_create(parser, node, pattern, &operator);
        }
        default:
            assert(false && "unreachable");
            return NULL;
    }
}

#undef PM_PARSE_PATTERN_SINGLE
#undef PM_PARSE_PATTERN_TOP
#undef PM_PARSE_PATTERN_MULTI

/**
 * Determine if a given call node looks like a "command", which means it has
 * arguments but does not have parentheses.
 */
static inline bool
pm_call_node_command_p(const pm_call_node_t *node) {
    return (
        (node->opening_loc.start == NULL) &&
        (node->block == NULL || PM_NODE_TYPE_P(node->block, PM_BLOCK_ARGUMENT_NODE)) &&
        (node->arguments != NULL || node->block != NULL)
    );
}

/**
 * Parse an expression at the given point of the parser using the given binding
 * power to parse subsequent chains. If this function finds a syntax error, it
 * will append the error message to the parser's error list.
 *
 * Consumers of this function should always check parser->recovering to
 * determine if they need to perform additional cleanup.
 */
static pm_node_t *
parse_expression(pm_parser_t *parser, pm_binding_power_t binding_power, bool accepts_command_call, bool accepts_label, pm_diagnostic_id_t diag_id, uint16_t depth) {
    if (PRISM_UNLIKELY(depth >= PRISM_DEPTH_MAXIMUM)) {
        pm_parser_err_current(parser, PM_ERR_NESTING_TOO_DEEP);
        return (pm_node_t *) pm_missing_node_create(parser, parser->current.start, parser->current.end);
    }

    pm_node_t *node = parse_expression_prefix(parser, binding_power, accepts_command_call, accepts_label, diag_id, depth);

    switch (PM_NODE_TYPE(node)) {
        case PM_MISSING_NODE:
            // If we found a syntax error, then the type of node returned by
            // parse_expression_prefix is going to be a missing node.
            return node;
        case PM_PRE_EXECUTION_NODE:
        case PM_POST_EXECUTION_NODE:
        case PM_ALIAS_GLOBAL_VARIABLE_NODE:
        case PM_ALIAS_METHOD_NODE:
        case PM_MULTI_WRITE_NODE:
        case PM_UNDEF_NODE:
            // These expressions are statements, and cannot be followed by
            // operators (except modifiers).
            if (pm_binding_powers[parser->current.type].left > PM_BINDING_POWER_MODIFIER) {
                return node;
            }
            break;
        case PM_CALL_NODE:
            // If we have a call node, then we need to check if it looks like a
            // method call without parentheses that contains arguments. If it
            // does, then it has different rules for parsing infix operators,
            // namely that it only accepts composition (and/or) and modifiers
            // (if/unless/etc.).
            if ((pm_binding_powers[parser->current.type].left > PM_BINDING_POWER_COMPOSITION) && pm_call_node_command_p((pm_call_node_t *) node)) {
                return node;
            }
            break;
        case PM_SYMBOL_NODE:
            // If we have a symbol node that is being parsed as a label, then we
            // need to immediately return, because there should never be an
            // infix operator following this node.
            if (pm_symbol_node_label_p(node)) {
                return node;
            }
            break;
        default:
            break;
    }

    // Otherwise we'll look and see if the next token can be parsed as an infix
    // operator. If it can, then we'll parse it using parse_expression_infix.
    pm_binding_powers_t current_binding_powers;
    pm_token_type_t current_token_type;

    while (
        current_token_type = parser->current.type,
        current_binding_powers = pm_binding_powers[current_token_type],
        binding_power <= current_binding_powers.left &&
        current_binding_powers.binary
     ) {
        node = parse_expression_infix(parser, node, binding_power, current_binding_powers.right, accepts_command_call, (uint16_t) (depth + 1));

        switch (PM_NODE_TYPE(node)) {
            case PM_MULTI_WRITE_NODE:
                // Multi-write nodes are statements, and cannot be followed by
                // operators except modifiers.
                if (pm_binding_powers[parser->current.type].left > PM_BINDING_POWER_MODIFIER) {
                    return node;
                }
                break;
            case PM_CLASS_VARIABLE_WRITE_NODE:
            case PM_CONSTANT_PATH_WRITE_NODE:
            case PM_CONSTANT_WRITE_NODE:
            case PM_GLOBAL_VARIABLE_WRITE_NODE:
            case PM_INSTANCE_VARIABLE_WRITE_NODE:
            case PM_LOCAL_VARIABLE_WRITE_NODE:
                // These expressions are statements, by virtue of the right-hand
                // side of their write being an implicit array.
                if (PM_NODE_FLAG_P(node, PM_WRITE_NODE_FLAGS_IMPLICIT_ARRAY) && pm_binding_powers[parser->current.type].left > PM_BINDING_POWER_MODIFIER) {
                    return node;
                }
                break;
            case PM_CALL_NODE:
                // These expressions are also statements, by virtue of the
                // right-hand side of the expression (i.e., the last argument to
                // the call node) being an implicit array.
                if (PM_NODE_FLAG_P(node, PM_CALL_NODE_FLAGS_IMPLICIT_ARRAY) && pm_binding_powers[parser->current.type].left > PM_BINDING_POWER_MODIFIER) {
                    return node;
                }
                break;
            default:
                break;
        }

        // If the operator is nonassoc and we should not be able to parse the
        // upcoming infix operator, break.
        if (current_binding_powers.nonassoc) {
            // If this is a non-assoc operator and we are about to parse the
            // exact same operator, then we need to add an error.
            if (match1(parser, current_token_type)) {
                PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_NON_ASSOCIATIVE_OPERATOR, pm_token_type_human(parser->current.type), pm_token_type_human(current_token_type));
                break;
            }

            // If this is an endless range, then we need to reject a couple of
            // additional operators because it violates the normal operator
            // precedence rules. Those patterns are:
            //
            //     1.. & 2
            //     1.. * 2
            //
            if (PM_NODE_TYPE_P(node, PM_RANGE_NODE) && ((pm_range_node_t *) node)->right == NULL) {
                if (match4(parser, PM_TOKEN_UAMPERSAND, PM_TOKEN_USTAR, PM_TOKEN_DOT, PM_TOKEN_AMPERSAND_DOT)) {
                    PM_PARSER_ERR_TOKEN_FORMAT(parser, parser->current, PM_ERR_NON_ASSOCIATIVE_OPERATOR, pm_token_type_human(parser->current.type), pm_token_type_human(current_token_type));
                    break;
                }

                if (PM_BINDING_POWER_TERM <= pm_binding_powers[parser->current.type].left) {
                    break;
                }
            } else if (current_binding_powers.left <= pm_binding_powers[parser->current.type].left) {
                break;
            }
        }

        if (accepts_command_call) {
            // A command-style method call is only accepted on method chains.
            // Thus, we check whether the parsed node can continue method chains.
            // The method chain can continue if the parsed node is one of the following five kinds:
            // (1) index access: foo[1]
            // (2) attribute access: foo.bar
            // (3) method call with parenthesis: foo.bar(1)
            // (4) method call with a block: foo.bar do end
            // (5) constant path: foo::Bar
            switch (node->type) {
                case PM_CALL_NODE: {
                    pm_call_node_t *cast = (pm_call_node_t *)node;
                    if (
                        // (1) foo[1]
                        !(
                            cast->call_operator_loc.start == NULL &&
                            cast->message_loc.start != NULL &&
                            cast->message_loc.start[0] == '[' &&
                            cast->message_loc.end[-1] == ']'
                        ) &&
                        // (2) foo.bar
                        !(
                            cast->call_operator_loc.start != NULL &&
                            cast->arguments == NULL &&
                            cast->block == NULL &&
                            cast->opening_loc.start == NULL
                        ) &&
                        // (3) foo.bar(1)
                        !(
                            cast->call_operator_loc.start != NULL &&
                            cast->opening_loc.start != NULL
                        ) &&
                        // (4) foo.bar do end
                        !(
                            cast->block != NULL && PM_NODE_TYPE_P(cast->block, PM_BLOCK_NODE)
                        )
                     ) {
                        accepts_command_call = false;
                    }
                    break;
                }
                // (5) foo::Bar
                case PM_CONSTANT_PATH_NODE:
                    break;
                default:
                    accepts_command_call = false;
                    break;
            }
        }
    }

    return node;
}

/**
 * ruby -p, ruby -n, ruby -a, and ruby -l options will mutate the AST. We
 * perform that mutation here.
 */
static pm_statements_node_t *
wrap_statements(pm_parser_t *parser, pm_statements_node_t *statements) {
    if (PM_PARSER_COMMAND_LINE_OPTION_P(parser)) {
        if (statements == NULL) {
            statements = pm_statements_node_create(parser);
        }

        pm_arguments_node_t *arguments = pm_arguments_node_create(parser);
        pm_arguments_node_arguments_append(
            arguments,
            (pm_node_t *) pm_global_variable_read_node_synthesized_create(parser, pm_parser_constant_id_constant(parser, "$_", 2))
        );

        pm_statements_node_body_append(parser, statements, (pm_node_t *) pm_call_node_fcall_synthesized_create(
            parser,
            arguments,
            pm_parser_constant_id_constant(parser, "print", 5)
        ), true);
    }

    if (PM_PARSER_COMMAND_LINE_OPTION_N(parser)) {
        if (PM_PARSER_COMMAND_LINE_OPTION_A(parser)) {
            if (statements == NULL) {
                statements = pm_statements_node_create(parser);
            }

            pm_arguments_node_t *arguments = pm_arguments_node_create(parser);
            pm_arguments_node_arguments_append(
                arguments,
                (pm_node_t *) pm_global_variable_read_node_synthesized_create(parser, pm_parser_constant_id_constant(parser, "$;", 2))
            );

            pm_global_variable_read_node_t *receiver = pm_global_variable_read_node_synthesized_create(parser, pm_parser_constant_id_constant(parser, "$_", 2));
            pm_call_node_t *call = pm_call_node_call_synthesized_create(parser, (pm_node_t *) receiver, "split", arguments);

            pm_global_variable_write_node_t *write = pm_global_variable_write_node_synthesized_create(
                parser,
                pm_parser_constant_id_constant(parser, "$F", 2),
                (pm_node_t *) call
            );

            pm_statements_node_body_prepend(statements, (pm_node_t *) write);
        }

        pm_arguments_node_t *arguments = pm_arguments_node_create(parser);
        pm_arguments_node_arguments_append(
            arguments,
            (pm_node_t *) pm_global_variable_read_node_synthesized_create(parser, pm_parser_constant_id_constant(parser, "$/", 2))
        );

        if (PM_PARSER_COMMAND_LINE_OPTION_L(parser)) {
            pm_keyword_hash_node_t *keywords = pm_keyword_hash_node_create(parser);
            pm_keyword_hash_node_elements_append(keywords, (pm_node_t *) pm_assoc_node_create(
                parser,
                (pm_node_t *) pm_symbol_node_synthesized_create(parser, "chomp"),
                &(pm_token_t) { .type = PM_TOKEN_NOT_PROVIDED, .start = parser->start, .end = parser->start },
                (pm_node_t *) pm_true_node_synthesized_create(parser)
            ));

            pm_arguments_node_arguments_append(arguments, (pm_node_t *) keywords);
            pm_node_flag_set((pm_node_t *) arguments, PM_ARGUMENTS_NODE_FLAGS_CONTAINS_KEYWORDS);
        }

        pm_statements_node_t *wrapped_statements = pm_statements_node_create(parser);
        pm_statements_node_body_append(parser, wrapped_statements, (pm_node_t *) pm_while_node_synthesized_create(
            parser,
            (pm_node_t *) pm_call_node_fcall_synthesized_create(parser, arguments, pm_parser_constant_id_constant(parser, "gets", 4)),
            statements
        ), true);

        statements = wrapped_statements;
    }

    return statements;
}

/**
 * Parse the top-level program node.
 */
static pm_node_t *
parse_program(pm_parser_t *parser) {
    // If the current scope is NULL, then we want to push a new top level scope.
    // The current scope could exist in the event that we are parsing an eval
    // and the user has passed into scopes that already exist.
    if (parser->current_scope == NULL) {
        pm_parser_scope_push(parser, true);
    }

    pm_node_list_t current_block_exits = { 0 };
    pm_node_list_t *previous_block_exits = push_block_exits(parser, &current_block_exits);

    parser_lex(parser);
    pm_statements_node_t *statements = parse_statements(parser, PM_CONTEXT_MAIN, 0);

    if (statements != NULL && !parser->parsing_eval) {
        // If we have statements, then the top-level statement should be
        // explicitly checked as well. We have to do this here because
        // everywhere else we check all but the last statement.
        assert(statements->body.size > 0);
        pm_void_statement_check(parser, statements->body.nodes[statements->body.size - 1]);
    }

    pm_constant_id_list_t locals;
    pm_locals_order(parser, &parser->current_scope->locals, &locals, true);
    pm_parser_scope_pop(parser);

    // At the top level, see if we need to wrap the statements in a program
    // node with a while loop based on the options.
    if (parser->command_line & (PM_OPTIONS_COMMAND_LINE_P | PM_OPTIONS_COMMAND_LINE_N)) {
        statements = wrap_statements(parser, statements);
    } else {
        flush_block_exits(parser, previous_block_exits);
        pm_node_list_free(&current_block_exits);
    }

    // If this is an empty file, then we're still going to parse all of the
    // statements in order to gather up all of the comments and such. Here we'll
    // correct the location information.
    if (statements == NULL) {
        statements = pm_statements_node_create(parser);
        pm_statements_node_location_set(statements, parser->start, parser->start);
    }

    return (pm_node_t *) pm_program_node_create(parser, &locals, statements);
}

/******************************************************************************/
/* External functions                                                         */
/******************************************************************************/

/**
 * A vendored version of strnstr that is used to find a substring within a
 * string with a given length. This function is used to search for the Ruby
 * engine name within a shebang when the -x option is passed to Ruby.
 *
 * The only modification that we made here is that we don't do NULL byte checks
 * because we know the little parameter will not have a NULL byte and we allow
 * the big parameter to have them.
 */
static const char *
pm_strnstr(const char *big, const char *little, size_t big_length) {
    size_t little_length = strlen(little);

    for (const char *big_end = big + big_length; big < big_end; big++) {
        if (*big == *little && memcmp(big, little, little_length) == 0) return big;
    }

    return NULL;
}

#ifdef _WIN32
#define pm_parser_warn_shebang_carriage_return(parser, start, length) ((void) 0)
#else
/**
 * Potentially warn the user if the shebang that has been found to include
 * "ruby" has a carriage return at the end, as that can cause problems on some
 * platforms.
 */
static void
pm_parser_warn_shebang_carriage_return(pm_parser_t *parser, const uint8_t *start, size_t length) {
    if (length > 2 && start[length - 2] == '\r' && start[length - 1] == '\n') {
        pm_parser_warn(parser, start, start + length, PM_WARN_SHEBANG_CARRIAGE_RETURN);
    }
}
#endif

/**
 * Process the shebang when initializing the parser. This function assumes that
 * the shebang_callback option has already been checked for nullability.
 */
static void
pm_parser_init_shebang(pm_parser_t *parser, const pm_options_t *options, const char *engine, size_t length) {
    const char *switches = pm_strnstr(engine, " -", length);
    if (switches == NULL) return;

    pm_options_t next_options = *options;
    options->shebang_callback(
        &next_options,
        (const uint8_t *) (switches + 1),
        length - ((size_t) (switches - engine)) - 1,
        options->shebang_callback_data
    );

    size_t encoding_length;
    if ((encoding_length = pm_string_length(&next_options.encoding)) > 0) {
        const uint8_t *encoding_source = pm_string_source(&next_options.encoding);
        parser_lex_magic_comment_encoding_value(parser, encoding_source, encoding_source + encoding_length);
    }

    parser->command_line = next_options.command_line;
    parser->frozen_string_literal = next_options.frozen_string_literal;
}

/**
 * Initialize a parser with the given start and end pointers.
 */
PRISM_EXPORTED_FUNCTION void
pm_parser_init(pm_parser_t *parser, const uint8_t *source, size_t size, const pm_options_t *options) {
    assert(source != NULL);

    *parser = (pm_parser_t) {
        .node_id = 0,
        .lex_state = PM_LEX_STATE_BEG,
        .enclosure_nesting = 0,
        .lambda_enclosure_nesting = -1,
        .brace_nesting = 0,
        .do_loop_stack = 0,
        .accepts_block_stack = 0,
        .lex_modes = {
            .index = 0,
            .stack = {{ .mode = PM_LEX_DEFAULT }},
            .current = &parser->lex_modes.stack[0],
        },
        .start = source,
        .end = source + size,
        .previous = { .type = PM_TOKEN_EOF, .start = source, .end = source },
        .current = { .type = PM_TOKEN_EOF, .start = source, .end = source },
        .next_start = NULL,
        .heredoc_end = NULL,
        .data_loc = { .start = NULL, .end = NULL },
        .comment_list = { 0 },
        .magic_comment_list = { 0 },
        .warning_list = { 0 },
        .error_list = { 0 },
        .current_scope = NULL,
        .current_context = NULL,
        .encoding = PM_ENCODING_UTF_8_ENTRY,
        .encoding_changed_callback = NULL,
        .encoding_comment_start = source,
        .lex_callback = NULL,
        .filepath = { 0 },
        .constant_pool = { 0 },
        .newline_list = { 0 },
        .integer_base = 0,
        .current_string = PM_STRING_EMPTY,
        .start_line = 1,
        .explicit_encoding = NULL,
        .command_line = 0,
        .parsing_eval = false,
        .partial_script = false,
        .command_start = true,
        .recovering = false,
        .encoding_locked = false,
        .encoding_changed = false,
        .pattern_matching_newlines = false,
        .in_keyword_arg = false,
        .current_block_exits = NULL,
        .semantic_token_seen = false,
        .frozen_string_literal = PM_OPTIONS_FROZEN_STRING_LITERAL_UNSET,
        .current_regular_expression_ascii_only = false,
        .warn_mismatched_indentation = true
    };

    // Initialize the constant pool. We're going to completely guess as to the
    // number of constants that we'll need based on the size of the input. The
    // ratio we chose here is actually less arbitrary than you might think.
    //
    // We took ~50K Ruby files and measured the size of the file versus the
    // number of constants that were found in those files. Then we found the
    // average and standard deviation of the ratios of constants/bytesize. Then
    // we added 1.34 standard deviations to the average to get a ratio that
    // would fit 75% of the files (for a two-tailed distribution). This works
    // because there was about a 0.77 correlation and the distribution was
    // roughly normal.
    //
    // This ratio will need to change if we add more constants to the constant
    // pool for another node type.
    uint32_t constant_size = ((uint32_t) size) / 95;
    pm_constant_pool_init(&parser->constant_pool, constant_size < 4 ? 4 : constant_size);

    // Initialize the newline list. Similar to the constant pool, we're going to
    // guess at the number of newlines that we'll need based on the size of the
    // input.
    size_t newline_size = size / 22;
    pm_newline_list_init(&parser->newline_list, source, newline_size < 4 ? 4 : newline_size);

    // If options were provided to this parse, establish them here.
    if (options != NULL) {
        // filepath option
        parser->filepath = options->filepath;

        // line option
        parser->start_line = options->line;

        // encoding option
        size_t encoding_length = pm_string_length(&options->encoding);
        if (encoding_length > 0) {
            const uint8_t *encoding_source = pm_string_source(&options->encoding);
            parser_lex_magic_comment_encoding_value(parser, encoding_source, encoding_source + encoding_length);
        }

        // encoding_locked option
        parser->encoding_locked = options->encoding_locked;

        // frozen_string_literal option
        parser->frozen_string_literal = options->frozen_string_literal;

        // command_line option
        parser->command_line = options->command_line;

        // version option
        parser->version = options->version;

        // partial_script
        parser->partial_script = options->partial_script;

        // scopes option
        parser->parsing_eval = options->scopes_count > 0;
        if (parser->parsing_eval) parser->warn_mismatched_indentation = false;

        for (size_t scope_index = 0; scope_index < options->scopes_count; scope_index++) {
            const pm_options_scope_t *scope = pm_options_scope_get(options, scope_index);
            pm_parser_scope_push(parser, scope_index == 0);

            // Scopes given from the outside are not allowed to have numbered
            // parameters.
            parser->current_scope->parameters = ((pm_scope_parameters_t) scope->forwarding) | PM_SCOPE_PARAMETERS_IMPLICIT_DISALLOWED;

            for (size_t local_index = 0; local_index < scope->locals_count; local_index++) {
                const pm_string_t *local = pm_options_scope_local_get(scope, local_index);

                const uint8_t *source = pm_string_source(local);
                size_t length = pm_string_length(local);

                void *allocated = xmalloc(length);
                if (allocated == NULL) continue;

                memcpy(allocated, source, length);
                pm_parser_local_add_owned(parser, (uint8_t *) allocated, length);
            }
        }
    }

    pm_accepts_block_stack_push(parser, true);

    // Skip past the UTF-8 BOM if it exists.
    if (size >= 3 && source[0] == 0xef && source[1] == 0xbb && source[2] == 0xbf) {
        parser->current.end += 3;
        parser->encoding_comment_start += 3;

        if (parser->encoding != PM_ENCODING_UTF_8_ENTRY) {
            parser->encoding = PM_ENCODING_UTF_8_ENTRY;
            if (parser->encoding_changed_callback != NULL) parser->encoding_changed_callback(parser);
        }
    }

    // If the -x command line flag is set, or the first shebang of the file does
    // not include "ruby", then we'll search for a shebang that does include
    // "ruby" and start parsing from there.
    bool search_shebang = PM_PARSER_COMMAND_LINE_OPTION_X(parser);

    // If the first two bytes of the source are a shebang, then we will do a bit
    // of extra processing.
    //
    // First, we'll indicate that the encoding comment is at the end of the
    // shebang. This means that when a shebang is present the encoding comment
    // can begin on the second line.
    //
    // Second, we will check if the shebang includes "ruby". If it does, then we
    // we will start parsing from there. We will also potentially warning the
    // user if there is a carriage return at the end of the shebang. We will
    // also potentially call the shebang callback if this is the main script to
    // allow the caller to parse the shebang and find any command-line options.
    // If the shebang does not include "ruby" and this is the main script being
    // parsed, then we will start searching the file for a shebang that does
    // contain "ruby" as if -x were passed on the command line.
    const uint8_t *newline = next_newline(parser->start, parser->end - parser->start);
    size_t length = (size_t) ((newline != NULL ? newline : parser->end) - parser->start);

    if (length > 2 && parser->current.end[0] == '#' && parser->current.end[1] == '!') {
        const char *engine;

        if ((engine = pm_strnstr((const char *) parser->start, "ruby", length)) != NULL) {
            if (newline != NULL) {
                parser->encoding_comment_start = newline + 1;

                if (options == NULL || options->main_script) {
                    pm_parser_warn_shebang_carriage_return(parser, parser->start, length + 1);
                }
            }

            if (options != NULL && options->main_script && options->shebang_callback != NULL) {
                pm_parser_init_shebang(parser, options, engine, length - ((size_t) (engine - (const char *) parser->start)));
            }

            search_shebang = false;
        } else if (options->main_script && !parser->parsing_eval) {
            search_shebang = true;
        }
    }

    // Here we're going to find the first shebang that includes "ruby" and start
    // parsing from there.
    if (search_shebang) {
        // If a shebang that includes "ruby" is not found, then we're going to a
        // a load error to the list of errors on the parser.
        bool found_shebang = false;

        // This is going to point to the start of each line as we check it.
        // We'll maintain a moving window looking at each line at they come.
        const uint8_t *cursor = parser->start;

        // The newline pointer points to the end of the current line that we're
        // considering. If it is NULL, then we're at the end of the file.
        const uint8_t *newline = next_newline(cursor, parser->end - cursor);

        while (newline != NULL) {
            pm_newline_list_append(&parser->newline_list, newline);

            cursor = newline + 1;
            newline = next_newline(cursor, parser->end - cursor);

            size_t length = (size_t) ((newline != NULL ? newline : parser->end) - cursor);
            if (length > 2 && cursor[0] == '#' && cursor[1] == '!') {
                const char *engine;
                if ((engine = pm_strnstr((const char *) cursor, "ruby", length)) != NULL) {
                    found_shebang = true;

                    if (newline != NULL) {
                        pm_parser_warn_shebang_carriage_return(parser, cursor, length + 1);
                        parser->encoding_comment_start = newline + 1;
                    }

                    if (options != NULL && options->shebang_callback != NULL) {
                        pm_parser_init_shebang(parser, options, engine, length - ((size_t) (engine - (const char *) cursor)));
                    }

                    break;
                }
            }
        }

        if (found_shebang) {
            parser->previous = (pm_token_t) { .type = PM_TOKEN_EOF, .start = cursor, .end = cursor };
            parser->current = (pm_token_t) { .type = PM_TOKEN_EOF, .start = cursor, .end = cursor };
        } else {
            pm_parser_err(parser, parser->start, parser->start, PM_ERR_SCRIPT_NOT_FOUND);
            pm_newline_list_clear(&parser->newline_list);
        }
    }

    // The encoding comment can start after any amount of inline whitespace, so
    // here we'll advance it to the first non-inline-whitespace character so
    // that it is ready for future comparisons.
    parser->encoding_comment_start += pm_strspn_inline_whitespace(parser->encoding_comment_start, parser->end - parser->encoding_comment_start);
}

/**
 * Register a callback that will be called whenever prism changes the encoding
 * it is using to parse based on the magic comment.
 */
PRISM_EXPORTED_FUNCTION void
pm_parser_register_encoding_changed_callback(pm_parser_t *parser, pm_encoding_changed_callback_t callback) {
    parser->encoding_changed_callback = callback;
}

/**
 * Free all of the memory associated with the comment list.
 */
static inline void
pm_comment_list_free(pm_list_t *list) {
    pm_list_node_t *node, *next;

    for (node = list->head; node != NULL; node = next) {
        next = node->next;

        pm_comment_t *comment = (pm_comment_t *) node;
        xfree(comment);
    }
}

/**
 * Free all of the memory associated with the magic comment list.
 */
static inline void
pm_magic_comment_list_free(pm_list_t *list) {
    pm_list_node_t *node, *next;

    for (node = list->head; node != NULL; node = next) {
        next = node->next;

        pm_magic_comment_t *magic_comment = (pm_magic_comment_t *) node;
        xfree(magic_comment);
    }
}

/**
 * Free any memory associated with the given parser.
 */
PRISM_EXPORTED_FUNCTION void
pm_parser_free(pm_parser_t *parser) {
    pm_string_free(&parser->filepath);
    pm_diagnostic_list_free(&parser->error_list);
    pm_diagnostic_list_free(&parser->warning_list);
    pm_comment_list_free(&parser->comment_list);
    pm_magic_comment_list_free(&parser->magic_comment_list);
    pm_constant_pool_free(&parser->constant_pool);
    pm_newline_list_free(&parser->newline_list);

    while (parser->current_scope != NULL) {
        // Normally, popping the scope doesn't free the locals since it is
        // assumed that ownership has transferred to the AST. However if we have
        // scopes while we're freeing the parser, it's likely they came from
        // eval scopes and we need to free them explicitly here.
        pm_parser_scope_pop(parser);
    }

    while (parser->lex_modes.index >= PM_LEX_STACK_SIZE) {
        lex_mode_pop(parser);
    }
}

/**
 * Parse the Ruby source associated with the given parser and return the tree.
 */
PRISM_EXPORTED_FUNCTION pm_node_t *
pm_parse(pm_parser_t *parser) {
    return parse_program(parser);
}

/**
 * Read into the stream until the gets callback returns false. If the last read
 * line from the stream matches an __END__ marker, then halt and return false,
 * otherwise return true.
 */
static bool
pm_parse_stream_read(pm_buffer_t *buffer, void *stream, pm_parse_stream_fgets_t *stream_fgets) {
#define LINE_SIZE 4096
    char line[LINE_SIZE];

    while (memset(line, '\n', LINE_SIZE), stream_fgets(line, LINE_SIZE, stream) != NULL) {
        size_t length = LINE_SIZE;
        while (length > 0 && line[length - 1] == '\n') length--;

        if (length == LINE_SIZE) {
            // If we read a line that is the maximum size and it doesn't end
            // with a newline, then we'll just append it to the buffer and
            // continue reading.
            length--;
            pm_buffer_append_string(buffer, line, length);
            continue;
        }

        // Append the line to the buffer.
        length--;
        pm_buffer_append_string(buffer, line, length);

        // Check if the line matches the __END__ marker. If it does, then stop
        // reading and return false. In most circumstances, this means we should
        // stop reading from the stream so that the DATA constant can pick it
        // up.
        switch (length) {
            case 7:
                if (strncmp(line, "__END__", 7) == 0) return false;
                break;
            case 8:
                if (strncmp(line, "__END__\n", 8) == 0) return false;
                break;
            case 9:
                if (strncmp(line, "__END__\r\n", 9) == 0) return false;
                break;
        }
    }

    return true;
#undef LINE_SIZE
}

/**
 * Determine if there was an unterminated heredoc at the end of the input, which
 * would mean the stream isn't finished and we should keep reading.
 *
 * For the other lex modes we can check if the lex mode has been closed, but for
 * heredocs when we hit EOF we close the lex mode and then go back to parse the
 * rest of the line after the heredoc declaration so that we get more of the
 * syntax tree.
 */
static bool
pm_parse_stream_unterminated_heredoc_p(pm_parser_t *parser) {
    pm_diagnostic_t *diagnostic = (pm_diagnostic_t *) parser->error_list.head;

    for (; diagnostic != NULL; diagnostic = (pm_diagnostic_t *) diagnostic->node.next) {
        if (diagnostic->diag_id == PM_ERR_HEREDOC_TERM) {
            return true;
        }
    }

    return false;
}

/**
 * Parse a stream of Ruby source and return the tree.
 *
 * Prism is designed around having the entire source in memory at once, but you
 * can stream stdin in to Ruby so we need to support a streaming API.
 */
PRISM_EXPORTED_FUNCTION pm_node_t *
pm_parse_stream(pm_parser_t *parser, pm_buffer_t *buffer, void *stream, pm_parse_stream_fgets_t *stream_fgets, const pm_options_t *options) {
    pm_buffer_init(buffer);

    bool eof = pm_parse_stream_read(buffer, stream, stream_fgets);
    pm_parser_init(parser, (const uint8_t *) pm_buffer_value(buffer), pm_buffer_length(buffer), options);
    pm_node_t *node = pm_parse(parser);

    while (!eof && parser->error_list.size > 0 && (parser->lex_modes.index > 0 || pm_parse_stream_unterminated_heredoc_p(parser))) {
        pm_node_destroy(parser, node);
        eof = pm_parse_stream_read(buffer, stream, stream_fgets);

        pm_parser_free(parser);
        pm_parser_init(parser, (const uint8_t *) pm_buffer_value(buffer), pm_buffer_length(buffer), options);
        node = pm_parse(parser);
    }

    return node;
}

/**
 * Parse the source and return true if it parses without errors or warnings.
 */
PRISM_EXPORTED_FUNCTION bool
pm_parse_success_p(const uint8_t *source, size_t size, const char *data) {
    pm_options_t options = { 0 };
    pm_options_read(&options, data);

    pm_parser_t parser;
    pm_parser_init(&parser, source, size, &options);

    pm_node_t *node = pm_parse(&parser);
    pm_node_destroy(&parser, node);

    bool result = parser.error_list.size == 0;
    pm_parser_free(&parser);
    pm_options_free(&options);

    return result;
}

#undef PM_CASE_KEYWORD
#undef PM_CASE_OPERATOR
#undef PM_CASE_WRITABLE
#undef PM_STRING_EMPTY
#undef PM_LOCATION_NODE_BASE_VALUE
#undef PM_LOCATION_NODE_VALUE
#undef PM_LOCATION_NULL_VALUE
#undef PM_LOCATION_TOKEN_VALUE

// We optionally support serializing to a binary string. For systems that don't
// want or need this functionality, it can be turned off with the
// PRISM_EXCLUDE_SERIALIZATION define.
#ifndef PRISM_EXCLUDE_SERIALIZATION

static inline void
pm_serialize_header(pm_buffer_t *buffer) {
    pm_buffer_append_string(buffer, "PRISM", 5);
    pm_buffer_append_byte(buffer, PRISM_VERSION_MAJOR);
    pm_buffer_append_byte(buffer, PRISM_VERSION_MINOR);
    pm_buffer_append_byte(buffer, PRISM_VERSION_PATCH);
    pm_buffer_append_byte(buffer, PRISM_SERIALIZE_ONLY_SEMANTICS_FIELDS ? 1 : 0);
}

/**
 * Serialize the AST represented by the given node to the given buffer.
 */
PRISM_EXPORTED_FUNCTION void
pm_serialize(pm_parser_t *parser, pm_node_t *node, pm_buffer_t *buffer) {
    pm_serialize_header(buffer);
    pm_serialize_content(parser, node, buffer);
    pm_buffer_append_byte(buffer, '\0');
}

/**
 * Parse and serialize the AST represented by the given source to the given
 * buffer.
 */
PRISM_EXPORTED_FUNCTION void
pm_serialize_parse(pm_buffer_t *buffer, const uint8_t *source, size_t size, const char *data) {
    pm_options_t options = { 0 };
    pm_options_read(&options, data);

    pm_parser_t parser;
    pm_parser_init(&parser, source, size, &options);

    pm_node_t *node = pm_parse(&parser);

    pm_serialize_header(buffer);
    pm_serialize_content(&parser, node, buffer);
    pm_buffer_append_byte(buffer, '\0');

    pm_node_destroy(&parser, node);
    pm_parser_free(&parser);
    pm_options_free(&options);
}

/**
 * Parse and serialize the AST represented by the source that is read out of the
 * given stream into to the given buffer.
 */
PRISM_EXPORTED_FUNCTION void
pm_serialize_parse_stream(pm_buffer_t *buffer, void *stream, pm_parse_stream_fgets_t *stream_fgets, const char *data) {
    pm_parser_t parser;
    pm_options_t options = { 0 };
    pm_options_read(&options, data);

    pm_buffer_t parser_buffer;
    pm_node_t *node = pm_parse_stream(&parser, &parser_buffer, stream, stream_fgets, &options);
    pm_serialize_header(buffer);
    pm_serialize_content(&parser, node, buffer);
    pm_buffer_append_byte(buffer, '\0');

    pm_node_destroy(&parser, node);
    pm_buffer_free(&parser_buffer);
    pm_parser_free(&parser);
    pm_options_free(&options);
}

/**
 * Parse and serialize the comments in the given source to the given buffer.
 */
PRISM_EXPORTED_FUNCTION void
pm_serialize_parse_comments(pm_buffer_t *buffer, const uint8_t *source, size_t size, const char *data) {
    pm_options_t options = { 0 };
    pm_options_read(&options, data);

    pm_parser_t parser;
    pm_parser_init(&parser, source, size, &options);

    pm_node_t *node = pm_parse(&parser);
    pm_serialize_header(buffer);
    pm_serialize_encoding(parser.encoding, buffer);
    pm_buffer_append_varsint(buffer, parser.start_line);
    pm_serialize_comment_list(&parser, &parser.comment_list, buffer);

    pm_node_destroy(&parser, node);
    pm_parser_free(&parser);
    pm_options_free(&options);
}

#endif

/******************************************************************************/
/* Slice queries for the Ruby API                                             */
/******************************************************************************/

/** The category of slice returned from pm_slice_type. */
typedef enum {
    /** Returned when the given encoding name is invalid. */
    PM_SLICE_TYPE_ERROR = -1,

    /** Returned when no other types apply to the slice. */
    PM_SLICE_TYPE_NONE,

    /** Returned when the slice is a valid local variable name. */
    PM_SLICE_TYPE_LOCAL,

    /** Returned when the slice is a valid constant name. */
    PM_SLICE_TYPE_CONSTANT,

    /** Returned when the slice is a valid method name. */
    PM_SLICE_TYPE_METHOD_NAME
} pm_slice_type_t;

/**
 * Check that the slice is a valid local variable name or constant.
 */
pm_slice_type_t
pm_slice_type(const uint8_t *source, size_t length, const char *encoding_name) {
    // first, get the right encoding object
    const pm_encoding_t *encoding = pm_encoding_find((const uint8_t *) encoding_name, (const uint8_t *) (encoding_name + strlen(encoding_name)));
    if (encoding == NULL) return PM_SLICE_TYPE_ERROR;

    // check that there is at least one character
    if (length == 0) return PM_SLICE_TYPE_NONE;

    size_t width;
    if ((width = encoding->alpha_char(source, (ptrdiff_t) length)) != 0) {
        // valid because alphabetical
    } else if (*source == '_') {
        // valid because underscore
        width = 1;
    } else if ((*source >= 0x80) && ((width = encoding->char_width(source, (ptrdiff_t) length)) > 0)) {
        // valid because multibyte
    } else {
        // invalid because no match
        return PM_SLICE_TYPE_NONE;
    }

    // determine the type of the slice based on the first character
    const uint8_t *end = source + length;
    pm_slice_type_t result = encoding->isupper_char(source, end - source) ? PM_SLICE_TYPE_CONSTANT : PM_SLICE_TYPE_LOCAL;

    // next, iterate through all of the bytes of the string to ensure that they
    // are all valid identifier characters
    source += width;

    while (source < end) {
        if ((width = encoding->alnum_char(source, end - source)) != 0) {
            // valid because alphanumeric
            source += width;
        } else if (*source == '_') {
            // valid because underscore
            source++;
        } else if ((*source >= 0x80) && ((width = encoding->char_width(source, end - source)) > 0)) {
            // valid because multibyte
            source += width;
        } else {
            // invalid because no match
            break;
        }
    }

    // accept a ! or ? at the end of the slice as a method name
    if (*source == '!' || *source == '?' || *source == '=') {
        source++;
        result = PM_SLICE_TYPE_METHOD_NAME;
    }

    // valid if we are at the end of the slice
    return source == end ? result : PM_SLICE_TYPE_NONE;
}

/**
 * Check that the slice is a valid local variable name.
 */
PRISM_EXPORTED_FUNCTION pm_string_query_t
pm_string_query_local(const uint8_t *source, size_t length, const char *encoding_name) {
    switch (pm_slice_type(source, length, encoding_name)) {
        case PM_SLICE_TYPE_ERROR:
            return PM_STRING_QUERY_ERROR;
        case PM_SLICE_TYPE_NONE:
        case PM_SLICE_TYPE_CONSTANT:
        case PM_SLICE_TYPE_METHOD_NAME:
            return PM_STRING_QUERY_FALSE;
        case PM_SLICE_TYPE_LOCAL:
            return PM_STRING_QUERY_TRUE;
    }

    assert(false && "unreachable");
    return PM_STRING_QUERY_FALSE;
}

/**
 * Check that the slice is a valid constant name.
 */
PRISM_EXPORTED_FUNCTION pm_string_query_t
pm_string_query_constant(const uint8_t *source, size_t length, const char *encoding_name) {
    switch (pm_slice_type(source, length, encoding_name)) {
        case PM_SLICE_TYPE_ERROR:
            return PM_STRING_QUERY_ERROR;
        case PM_SLICE_TYPE_NONE:
        case PM_SLICE_TYPE_LOCAL:
        case PM_SLICE_TYPE_METHOD_NAME:
            return PM_STRING_QUERY_FALSE;
        case PM_SLICE_TYPE_CONSTANT:
            return PM_STRING_QUERY_TRUE;
    }

    assert(false && "unreachable");
    return PM_STRING_QUERY_FALSE;
}

/**
 * Check that the slice is a valid method name.
 */
PRISM_EXPORTED_FUNCTION pm_string_query_t
pm_string_query_method_name(const uint8_t *source, size_t length, const char *encoding_name) {
#define B(p) ((p) ? PM_STRING_QUERY_TRUE : PM_STRING_QUERY_FALSE)
#define C1(c) (*source == c)
#define C2(s) (memcmp(source, s, 2) == 0)
#define C3(s) (memcmp(source, s, 3) == 0)

    switch (pm_slice_type(source, length, encoding_name)) {
        case PM_SLICE_TYPE_ERROR:
            return PM_STRING_QUERY_ERROR;
        case PM_SLICE_TYPE_NONE:
            break;
        case PM_SLICE_TYPE_LOCAL:
            // numbered parameters are not valid method names
            return B((length != 2) || (source[0] != '_') || (source[1] == '0') || !pm_char_is_decimal_digit(source[1]));
        case PM_SLICE_TYPE_CONSTANT:
            // all constants are valid method names
        case PM_SLICE_TYPE_METHOD_NAME:
            // all method names are valid method names
            return PM_STRING_QUERY_TRUE;
    }

    switch (length) {
        case 1:
            return B(C1('&') || C1('`') || C1('!') || C1('^') || C1('>') || C1('<') || C1('-') || C1('%') || C1('|') || C1('+') || C1('/') || C1('*') || C1('~'));
        case 2:
            return B(C2("!=") || C2("!~") || C2("[]") || C2("==") || C2("=~") || C2(">=") || C2(">>") || C2("<=") || C2("<<") || C2("**"));
        case 3:
            return B(C3("===") || C3("<=>") || C3("[]="));
        default:
            return PM_STRING_QUERY_FALSE;
    }

#undef B
#undef C1
#undef C2
#undef C3
}
