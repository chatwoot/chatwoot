/**
 * @file parser.h
 *
 * The parser used to parse Ruby source.
 */
#ifndef PRISM_PARSER_H
#define PRISM_PARSER_H

#include "prism/ast.h"
#include "prism/defines.h"
#include "prism/encoding.h"
#include "prism/util/pm_constant_pool.h"
#include "prism/util/pm_list.h"
#include "prism/util/pm_newline_list.h"
#include "prism/util/pm_state_stack.h"
#include "prism/util/pm_string.h"

#include <stdbool.h>

// TODO: remove this by renaming the original flag
/**
 * Temporary alias for the PM_NODE_FLAG_STATIC_KEYS flag.
 */
#define PM_KEYWORD_HASH_NODE_FLAGS_SYMBOL_KEYS PM_KEYWORD_HASH_NODE_FLAGS_STATIC_KEYS

/**
 * This enum provides various bits that represent different kinds of states that
 * the lexer can track. This is used to determine which kind of token to return
 * based on the context of the parser.
 */
typedef enum {
    PM_LEX_STATE_BIT_BEG,
    PM_LEX_STATE_BIT_END,
    PM_LEX_STATE_BIT_ENDARG,
    PM_LEX_STATE_BIT_ENDFN,
    PM_LEX_STATE_BIT_ARG,
    PM_LEX_STATE_BIT_CMDARG,
    PM_LEX_STATE_BIT_MID,
    PM_LEX_STATE_BIT_FNAME,
    PM_LEX_STATE_BIT_DOT,
    PM_LEX_STATE_BIT_CLASS,
    PM_LEX_STATE_BIT_LABEL,
    PM_LEX_STATE_BIT_LABELED,
    PM_LEX_STATE_BIT_FITEM
} pm_lex_state_bit_t;

/**
 * This enum combines the various bits from the above enum into individual
 * values that represent the various states of the lexer.
 */
typedef enum {
    PM_LEX_STATE_NONE = 0,
    PM_LEX_STATE_BEG = (1 << PM_LEX_STATE_BIT_BEG),
    PM_LEX_STATE_END = (1 << PM_LEX_STATE_BIT_END),
    PM_LEX_STATE_ENDARG = (1 << PM_LEX_STATE_BIT_ENDARG),
    PM_LEX_STATE_ENDFN = (1 << PM_LEX_STATE_BIT_ENDFN),
    PM_LEX_STATE_ARG = (1 << PM_LEX_STATE_BIT_ARG),
    PM_LEX_STATE_CMDARG = (1 << PM_LEX_STATE_BIT_CMDARG),
    PM_LEX_STATE_MID = (1 << PM_LEX_STATE_BIT_MID),
    PM_LEX_STATE_FNAME = (1 << PM_LEX_STATE_BIT_FNAME),
    PM_LEX_STATE_DOT = (1 << PM_LEX_STATE_BIT_DOT),
    PM_LEX_STATE_CLASS = (1 << PM_LEX_STATE_BIT_CLASS),
    PM_LEX_STATE_LABEL = (1 << PM_LEX_STATE_BIT_LABEL),
    PM_LEX_STATE_LABELED = (1 << PM_LEX_STATE_BIT_LABELED),
    PM_LEX_STATE_FITEM = (1 << PM_LEX_STATE_BIT_FITEM),
    PM_LEX_STATE_BEG_ANY = PM_LEX_STATE_BEG | PM_LEX_STATE_MID | PM_LEX_STATE_CLASS,
    PM_LEX_STATE_ARG_ANY = PM_LEX_STATE_ARG | PM_LEX_STATE_CMDARG,
    PM_LEX_STATE_END_ANY = PM_LEX_STATE_END | PM_LEX_STATE_ENDARG | PM_LEX_STATE_ENDFN
} pm_lex_state_t;

/**
 * The type of quote that a heredoc uses.
 */
typedef enum {
    PM_HEREDOC_QUOTE_NONE,
    PM_HEREDOC_QUOTE_SINGLE = '\'',
    PM_HEREDOC_QUOTE_DOUBLE = '"',
    PM_HEREDOC_QUOTE_BACKTICK = '`',
} pm_heredoc_quote_t;

/**
 * The type of indentation that a heredoc uses.
 */
typedef enum {
    PM_HEREDOC_INDENT_NONE,
    PM_HEREDOC_INDENT_DASH,
    PM_HEREDOC_INDENT_TILDE,
} pm_heredoc_indent_t;

/**
 * When lexing Ruby source, the lexer has a small amount of state to tell which
 * kind of token it is currently lexing. For example, when we find the start of
 * a string, the first token that we return is a TOKEN_STRING_BEGIN token. After
 * that the lexer is now in the PM_LEX_STRING mode, and will return tokens that
 * are found as part of a string.
 */
typedef struct pm_lex_mode {
    /** The type of this lex mode. */
    enum {
        /** This state is used when any given token is being lexed. */
        PM_LEX_DEFAULT,

        /**
         * This state is used when we're lexing as normal but inside an embedded
         * expression of a string.
         */
        PM_LEX_EMBEXPR,

        /**
         * This state is used when we're lexing a variable that is embedded
         * directly inside of a string with the # shorthand.
         */
        PM_LEX_EMBVAR,

        /** This state is used when you are inside the content of a heredoc. */
        PM_LEX_HEREDOC,

        /**
         * This state is used when we are lexing a list of tokens, as in a %w
         * word list literal or a %i symbol list literal.
         */
        PM_LEX_LIST,

        /**
         * This state is used when a regular expression has been begun and we
         * are looking for the terminator.
         */
        PM_LEX_REGEXP,

        /**
         * This state is used when we are lexing a string or a string-like
         * token, as in string content with either quote or an xstring.
         */
        PM_LEX_STRING
    } mode;

    /** The data associated with this type of lex mode. */
    union {
        struct {
            /** This keeps track of the nesting level of the list. */
            size_t nesting;

            /** Whether or not interpolation is allowed in this list. */
            bool interpolation;

            /**
             * When lexing a list, it takes into account balancing the
             * terminator if the terminator is one of (), [], {}, or <>.
             */
            uint8_t incrementor;

            /** This is the terminator of the list literal. */
            uint8_t terminator;

            /**
             * This is the character set that should be used to delimit the
             * tokens within the list.
             */
            uint8_t breakpoints[11];
        } list;

        struct {
            /**
             * This keeps track of the nesting level of the regular expression.
             */
            size_t nesting;

            /**
             * When lexing a regular expression, it takes into account balancing
             * the terminator if the terminator is one of (), [], {}, or <>.
             */
            uint8_t incrementor;

            /** This is the terminator of the regular expression. */
            uint8_t terminator;

            /**
             * This is the character set that should be used to delimit the
             * tokens within the regular expression.
             */
            uint8_t breakpoints[6];
        } regexp;

        struct {
            /** This keeps track of the nesting level of the string. */
            size_t nesting;

            /** Whether or not interpolation is allowed in this string. */
            bool interpolation;

            /**
             * Whether or not at the end of the string we should allow a :,
             * which would indicate this was a dynamic symbol instead of a
             * string.
             */
            bool label_allowed;

            /**
             * When lexing a string, it takes into account balancing the
             * terminator if the terminator is one of (), [], {}, or <>.
             */
            uint8_t incrementor;

            /**
             * This is the terminator of the string. It is typically either a
             * single or double quote.
             */
            uint8_t terminator;

            /**
             * This is the character set that should be used to delimit the
             * tokens within the string.
             */
            uint8_t breakpoints[6];
        } string;

        struct {
            /** A pointer to the start of the heredoc identifier. */
            const uint8_t *ident_start;

            /** The length of the heredoc identifier. */
            size_t ident_length;

            /** The type of quote that the heredoc uses. */
            pm_heredoc_quote_t quote;

            /** The type of indentation that the heredoc uses. */
            pm_heredoc_indent_t indent;

            /**
             * This is the pointer to the character where lexing should resume
             * once the heredoc has been completely processed.
             */
            const uint8_t *next_start;

            /**
             * This is used to track the amount of common whitespace on each
             * line so that we know how much to dedent each line in the case of
             * a tilde heredoc.
             */
            size_t common_whitespace;
        } heredoc;
    } as;

    /** The previous lex state so that it knows how to pop. */
    struct pm_lex_mode *prev;
} pm_lex_mode_t;

/**
 * We pre-allocate a certain number of lex states in order to avoid having to
 * call malloc too many times while parsing. You really shouldn't need more than
 * this because you only really nest deeply when doing string interpolation.
 */
#define PM_LEX_STACK_SIZE 4

/**
 * The parser used to parse Ruby source.
 */
typedef struct pm_parser pm_parser_t;

/**
 * While parsing, we keep track of a stack of contexts. This is helpful for
 * error recovery so that we can pop back to a previous context when we hit a
 * token that is understood by a parent context but not by the current context.
 */
typedef enum {
    /** a begin statement */
    PM_CONTEXT_BEGIN,

    /** expressions in block arguments using braces */
    PM_CONTEXT_BLOCK_BRACES,

    /** expressions in block arguments using do..end */
    PM_CONTEXT_BLOCK_KEYWORDS,

    /** a case when statements */
    PM_CONTEXT_CASE_WHEN,

    /** a case in statements */
    PM_CONTEXT_CASE_IN,

    /** a class declaration */
    PM_CONTEXT_CLASS,

    /** a method definition */
    PM_CONTEXT_DEF,

    /** a method definition's parameters */
    PM_CONTEXT_DEF_PARAMS,

    /** a method definition's default parameter */
    PM_CONTEXT_DEFAULT_PARAMS,

    /** an else clause */
    PM_CONTEXT_ELSE,

    /** an elsif clause */
    PM_CONTEXT_ELSIF,

    /** an interpolated expression */
    PM_CONTEXT_EMBEXPR,

    /** an ensure statement */
    PM_CONTEXT_ENSURE,

    /** an ensure statement within a method definition */
    PM_CONTEXT_ENSURE_DEF,

    /** a for loop */
    PM_CONTEXT_FOR,

    /** a for loop's index */
    PM_CONTEXT_FOR_INDEX,

    /** an if statement */
    PM_CONTEXT_IF,

    /** a lambda expression with braces */
    PM_CONTEXT_LAMBDA_BRACES,

    /** a lambda expression with do..end */
    PM_CONTEXT_LAMBDA_DO_END,

    /** the top level context */
    PM_CONTEXT_MAIN,

    /** a module declaration */
    PM_CONTEXT_MODULE,

    /** a parenthesized expression */
    PM_CONTEXT_PARENS,

    /** an END block */
    PM_CONTEXT_POSTEXE,

    /** a predicate inside an if/elsif/unless statement */
    PM_CONTEXT_PREDICATE,

    /** a BEGIN block */
    PM_CONTEXT_PREEXE,

    /** a rescue else statement */
    PM_CONTEXT_RESCUE_ELSE,

    /** a rescue else statement within a method definition */
    PM_CONTEXT_RESCUE_ELSE_DEF,

    /** a rescue statement */
    PM_CONTEXT_RESCUE,

    /** a rescue statement within a method definition */
    PM_CONTEXT_RESCUE_DEF,

    /** a singleton class definition */
    PM_CONTEXT_SCLASS,

    /** an unless statement */
    PM_CONTEXT_UNLESS,

    /** an until statement */
    PM_CONTEXT_UNTIL,

    /** a while statement */
    PM_CONTEXT_WHILE,
} pm_context_t;

/** This is a node in a linked list of contexts. */
typedef struct pm_context_node {
    /** The context that this node represents. */
    pm_context_t context;

    /** A pointer to the previous context in the linked list. */
    struct pm_context_node *prev;
} pm_context_node_t;

/** This is the type of a comment that we've found while parsing. */
typedef enum {
    PM_COMMENT_INLINE,
    PM_COMMENT_EMBDOC
} pm_comment_type_t;

/**
 * This is a node in the linked list of comments that we've found while parsing.
 *
 * @extends pm_list_node_t
 */
typedef struct pm_comment {
    /** The embedded base node. */
    pm_list_node_t node;

    /** The location of the comment in the source. */
    pm_location_t location;

    /** The type of comment that we've found. */
    pm_comment_type_t type;
} pm_comment_t;

/**
 * This is a node in the linked list of magic comments that we've found while
 * parsing.
 *
 * @extends pm_list_node_t
 */
typedef struct {
    /** The embedded base node. */
    pm_list_node_t node;

    /** A pointer to the start of the key in the source. */
    const uint8_t *key_start;

    /** A pointer to the start of the value in the source. */
    const uint8_t *value_start;

    /** The length of the key in the source. */
    uint32_t key_length;

    /** The length of the value in the source. */
    uint32_t value_length;
} pm_magic_comment_t;

/**
 * When the encoding that is being used to parse the source is changed by prism,
 * we provide the ability here to call out to a user-defined function.
 */
typedef void (*pm_encoding_changed_callback_t)(pm_parser_t *parser);

/**
 * When you are lexing through a file, the lexer needs all of the information
 * that the parser additionally provides (for example, the local table). So if
 * you want to properly lex Ruby, you need to actually lex it in the context of
 * the parser. In order to provide this functionality, we optionally allow a
 * struct to be attached to the parser that calls back out to a user-provided
 * callback when each token is lexed.
 */
typedef struct {
    /**
     * This opaque pointer is used to provide whatever information the user
     * deemed necessary to the callback. In our case we use it to pass the array
     * that the tokens get appended into.
     */
    void *data;

    /**
     * This is the callback that is called when a token is lexed. It is passed
     * the opaque data pointer, the parser, and the token that was lexed.
     */
    void (*callback)(void *data, pm_parser_t *parser, pm_token_t *token);
} pm_lex_callback_t;

/**
 * This struct represents a node in a linked list of scopes. Some scopes can see
 * into their parent scopes, while others cannot.
 */
typedef struct pm_scope {
    /** The IDs of the locals in the given scope. */
    pm_constant_id_list_t locals;

    /** A pointer to the previous scope in the linked list. */
    struct pm_scope *previous;

    /**
     * A boolean indicating whether or not this scope can see into its parent.
     * If closed is true, then the scope cannot see into its parent.
     */
    bool closed;

    /**
     * A boolean indicating whether or not this scope has explicit parameters.
     * This is necessary to determine whether or not numbered parameters are
     * allowed.
     */
    bool explicit_params;

    /**
     * An integer indicating the number of numbered parameters on this scope.
     * This is necessary to determine if child blocks are allowed to use
     * numbered parameters, and to pass information to consumers of the AST
     * about how many numbered parameters exist.
     */
    uint8_t numbered_parameters;
} pm_scope_t;

/**
 * This struct represents the overall parser. It contains a reference to the
 * source file, as well as pointers that indicate where in the source it's
 * currently parsing. It also contains the most recent and current token that
 * it's considering.
 */
struct pm_parser {
    /** The current state of the lexer. */
    pm_lex_state_t lex_state;

    /** Tracks the current nesting of (), [], and {}. */
    int enclosure_nesting;

    /**
     * Used to temporarily track the nesting of enclosures to determine if a {
     * is the beginning of a lambda following the parameters of a lambda.
     */
    int lambda_enclosure_nesting;

    /**
     * Used to track the nesting of braces to ensure we get the correct value
     * when we are interpolating blocks with braces.
     */
    int brace_nesting;

    /**
     * The stack used to determine if a do keyword belongs to the predicate of a
     * while, until, or for loop.
     */
    pm_state_stack_t do_loop_stack;

    /**
     * The stack used to determine if a do keyword belongs to the beginning of a
     * block.
     */
    pm_state_stack_t accepts_block_stack;

    /** A stack of lex modes. */
    struct {
        /** The current mode of the lexer. */
        pm_lex_mode_t *current;

        /** The stack of lexer modes. */
        pm_lex_mode_t stack[PM_LEX_STACK_SIZE];

        /** The current index into the lexer mode stack. */
        size_t index;
    } lex_modes;

    /** The pointer to the start of the source. */
    const uint8_t *start;

    /** The pointer to the end of the source. */
    const uint8_t *end;

    /** The previous token we were considering. */
    pm_token_t previous;

    /** The current token we're considering. */
    pm_token_t current;

    /**
     * This is a special field set on the parser when we need the parser to jump
     * to a specific location when lexing the next token, as opposed to just
     * using the end of the previous token. Normally this is NULL.
     */
    const uint8_t *next_start;

    /**
     * This field indicates the end of a heredoc whose identifier was found on
     * the current line. If another heredoc is found on the same line, then this
     * will be moved forward to the end of that heredoc. If no heredocs are
     * found on a line then this is NULL.
     */
    const uint8_t *heredoc_end;

    /** The list of comments that have been found while parsing. */
    pm_list_t comment_list;

    /** The list of magic comments that have been found while parsing. */
    pm_list_t magic_comment_list;

    /** The optional location of the __END__ keyword and its contents. */
    pm_location_t data_loc;

    /** The list of warnings that have been found while parsing. */
    pm_list_t warning_list;

    /** The list of errors that have been found while parsing. */
    pm_list_t error_list;

    /** The current local scope. */
    pm_scope_t *current_scope;

    /** The current parsing context. */
    pm_context_node_t *current_context;

    /**
     * The encoding functions for the current file is attached to the parser as
     * it's parsing so that it can change with a magic comment.
     */
    const pm_encoding_t *encoding;

    /**
     * When the encoding that is being used to parse the source is changed by
     * prism, we provide the ability here to call out to a user-defined
     * function.
     */
    pm_encoding_changed_callback_t encoding_changed_callback;

    /**
     * This pointer indicates where a comment must start if it is to be
     * considered an encoding comment.
     */
    const uint8_t *encoding_comment_start;

    /**
     * This is an optional callback that can be attached to the parser that will
     * be called whenever a new token is lexed by the parser.
     */
    pm_lex_callback_t *lex_callback;

    /**
     * This is the path of the file being parsed. We use the filepath when
     * constructing SourceFileNodes.
     */
    pm_string_t filepath_string;

    /**
     * This constant pool keeps all of the constants defined throughout the file
     * so that we can reference them later.
     */
    pm_constant_pool_t constant_pool;

    /** This is the list of newline offsets in the source file. */
    pm_newline_list_t newline_list;

    /**
     * We want to add a flag to integer nodes that indicates their base. We only
     * want to parse these once, but we don't have space on the token itself to
     * communicate this information. So we store it here and pass it through
     * when we find tokens that we need it for.
     */
    pm_node_flags_t integer_base;

    /**
     * This string is used to pass information from the lexer to the parser. It
     * is particularly necessary because of escape sequences.
     */
    pm_string_t current_string;

    /**
     * The line number at the start of the parse. This will be used to offset
     * the line numbers of all of the locations.
     */
    int32_t start_line;

    /**
     * When a string-like expression is being lexed, any byte or escape sequence
     * that resolves to a value whose top bit is set (i.e., >= 0x80) will
     * explicitly set the encoding to the same encoding as the source.
     * Alternatively, if a unicode escape sequence is used (e.g., \\u{80}) that
     * resolves to a value whose top bit is set, then the encoding will be
     * explicitly set to UTF-8.
     *
     * The _next_ time this happens, if the encoding that is about to become the
     * explicitly set encoding does not match the previously set explicit
     * encoding, a mixed encoding error will be emitted.
     *
     * When the expression is finished being lexed, the explicit encoding
     * controls the encoding of the expression. For the most part this means
     * that the expression will either be encoded in the source encoding or
     * UTF-8. This holds for all encodings except US-ASCII. If the source is
     * US-ASCII and an explicit encoding was set that was _not_ UTF-8, then the
     * expression will be encoded as ASCII-8BIT.
     *
     * Note that if the expression is a list, different elements within the same
     * list can have different encodings, so this will get reset between each
     * element. Furthermore all of this only applies to lists that support
     * interpolation, because otherwise escapes that could change the encoding
     * are ignored.
     *
     * At first glance, it may make more sense for this to live on the lexer
     * mode, but we need it here to communicate back to the parser for character
     * literals that do not push a new lexer mode.
     */
    const pm_encoding_t *explicit_encoding;

    /** Whether or not we're at the beginning of a command. */
    bool command_start;

    /** Whether or not we're currently recovering from a syntax error. */
    bool recovering;

    /**
     * Whether or not the encoding has been changed by a magic comment. We use
     * this to provide a fast path for the lexer instead of going through the
     * function pointer.
     */
    bool encoding_changed;

    /**
     * This flag indicates that we are currently parsing a pattern matching
     * expression and impacts that calculation of newlines.
     */
    bool pattern_matching_newlines;

    /** This flag indicates that we are currently parsing a keyword argument. */
    bool in_keyword_arg;

    /** The current parameter name id on parsing its default value. */
    pm_constant_id_t current_param_name;

    /**
     * Whether or not the parser has seen a token that has semantic meaning
     * (i.e., a token that is not a comment or whitespace).
     */
    bool semantic_token_seen;

    /**
     * Whether or not we have found a frozen_string_literal magic comment with
     * a true value.
     */
    bool frozen_string_literal;

    /**
     * Whether or not we should emit warnings. This will be set to false if the
     * consumer of the library specified it, usually because they are parsing
     * when $VERBOSE is nil.
     */
    bool suppress_warnings;
};

#endif
