#include "prism/extension.h"

#ifdef _WIN32
#include <ruby/win32.h>
#endif

// NOTE: this file should contain only bindings. All non-trivial logic should be
// in libprism so it can be shared its the various callers.

VALUE rb_cPrism;
VALUE rb_cPrismNode;
VALUE rb_cPrismSource;
VALUE rb_cPrismToken;
VALUE rb_cPrismLocation;

VALUE rb_cPrismComment;
VALUE rb_cPrismInlineComment;
VALUE rb_cPrismEmbDocComment;
VALUE rb_cPrismMagicComment;
VALUE rb_cPrismParseError;
VALUE rb_cPrismParseWarning;
VALUE rb_cPrismResult;
VALUE rb_cPrismParseResult;
VALUE rb_cPrismLexResult;
VALUE rb_cPrismParseLexResult;
VALUE rb_cPrismStringQuery;
VALUE rb_cPrismScope;

VALUE rb_cPrismDebugEncoding;

ID rb_id_option_command_line;
ID rb_id_option_encoding;
ID rb_id_option_filepath;
ID rb_id_option_freeze;
ID rb_id_option_frozen_string_literal;
ID rb_id_option_line;
ID rb_id_option_main_script;
ID rb_id_option_partial_script;
ID rb_id_option_scopes;
ID rb_id_option_version;
ID rb_id_source_for;
ID rb_id_forwarding_positionals;
ID rb_id_forwarding_keywords;
ID rb_id_forwarding_block;
ID rb_id_forwarding_all;

/******************************************************************************/
/* IO of Ruby code                                                            */
/******************************************************************************/

/**
 * Check if the given VALUE is a string. If it's not a string, then raise a
 * TypeError. Otherwise return the VALUE as a C string.
 */
static const char *
check_string(VALUE value) {
    // Check if the value is a string. If it's not, then raise a type error.
    if (!RB_TYPE_P(value, T_STRING)) {
        rb_raise(rb_eTypeError, "wrong argument type %" PRIsVALUE " (expected String)", rb_obj_class(value));
    }

    // Otherwise, return the value as a C string.
    return RSTRING_PTR(value);
}

/**
 * Load the contents and size of the given string into the given pm_string_t.
 */
static void
input_load_string(pm_string_t *input, VALUE string) {
    // Check if the string is a string. If it's not, then raise a type error.
    if (!RB_TYPE_P(string, T_STRING)) {
        rb_raise(rb_eTypeError, "wrong argument type %" PRIsVALUE " (expected String)", rb_obj_class(string));
    }

    pm_string_constant_init(input, RSTRING_PTR(string), RSTRING_LEN(string));
}

/******************************************************************************/
/* Building C options from Ruby options                                       */
/******************************************************************************/

/**
 * Build the scopes associated with the provided Ruby keyword value.
 */
static void
build_options_scopes(pm_options_t *options, VALUE scopes) {
    // Check if the value is an array. If it's not, then raise a type error.
    if (!RB_TYPE_P(scopes, T_ARRAY)) {
        rb_raise(rb_eTypeError, "wrong argument type %"PRIsVALUE" (expected Array)", rb_obj_class(scopes));
    }

    // Initialize the scopes array.
    size_t scopes_count = RARRAY_LEN(scopes);
    if (!pm_options_scopes_init(options, scopes_count)) {
        rb_raise(rb_eNoMemError, "failed to allocate memory");
    }

    // Iterate over the scopes and add them to the options.
    for (size_t scope_index = 0; scope_index < scopes_count; scope_index++) {
        VALUE scope = rb_ary_entry(scopes, scope_index);

        // The scope can be either an array or it can be a Prism::Scope object.
        // Parse out the correct values here from either.
        VALUE locals;
        uint8_t forwarding = PM_OPTIONS_SCOPE_FORWARDING_NONE;

        if (RB_TYPE_P(scope, T_ARRAY)) {
            locals = scope;
        } else if (rb_obj_is_kind_of(scope, rb_cPrismScope)) {
            locals = rb_ivar_get(scope, rb_intern("@locals"));
            if (!RB_TYPE_P(locals, T_ARRAY)) {
                rb_raise(rb_eTypeError, "wrong argument type %"PRIsVALUE" (expected Array)", rb_obj_class(locals));
            }

            VALUE names = rb_ivar_get(scope, rb_intern("@forwarding"));
            if (!RB_TYPE_P(names, T_ARRAY)) {
                rb_raise(rb_eTypeError, "wrong argument type %"PRIsVALUE" (expected Array)", rb_obj_class(names));
            }

            size_t names_count = RARRAY_LEN(names);
            for (size_t name_index = 0; name_index < names_count; name_index++) {
                VALUE name = rb_ary_entry(names, name_index);

                // Check that the name is a symbol. If it's not, then raise
                // a type error.
                if (!RB_TYPE_P(name, T_SYMBOL)) {
                    rb_raise(rb_eTypeError, "wrong argument type %"PRIsVALUE" (expected Symbol)", rb_obj_class(name));
                }

                ID id = SYM2ID(name);
                if (id == rb_id_forwarding_positionals) {
                    forwarding |= PM_OPTIONS_SCOPE_FORWARDING_POSITIONALS;
                } else if (id == rb_id_forwarding_keywords) {
                    forwarding |= PM_OPTIONS_SCOPE_FORWARDING_KEYWORDS;
                } else if (id == rb_id_forwarding_block) {
                    forwarding |= PM_OPTIONS_SCOPE_FORWARDING_BLOCK;
                } else if (id == rb_id_forwarding_all) {
                    forwarding |= PM_OPTIONS_SCOPE_FORWARDING_ALL;
                } else {
                    rb_raise(rb_eArgError, "invalid forwarding value: %" PRIsVALUE, name);
                }
            }
        } else {
            rb_raise(rb_eTypeError, "wrong argument type %"PRIsVALUE" (expected Array or Prism::Scope)", rb_obj_class(scope));
        }

        // Initialize the scope array.
        size_t locals_count = RARRAY_LEN(locals);
        pm_options_scope_t *options_scope = &options->scopes[scope_index];
        if (!pm_options_scope_init(options_scope, locals_count)) {
            rb_raise(rb_eNoMemError, "failed to allocate memory");
        }

        // Iterate over the locals and add them to the scope.
        for (size_t local_index = 0; local_index < locals_count; local_index++) {
            VALUE local = rb_ary_entry(locals, local_index);

            // Check that the local is a symbol. If it's not, then raise a
            // type error.
            if (!RB_TYPE_P(local, T_SYMBOL)) {
                rb_raise(rb_eTypeError, "wrong argument type %"PRIsVALUE" (expected Symbol)", rb_obj_class(local));
            }

            // Add the local to the scope.
            pm_string_t *scope_local = &options_scope->locals[local_index];
            const char *name = rb_id2name(SYM2ID(local));
            pm_string_constant_init(scope_local, name, strlen(name));
        }

        // Now set the forwarding options.
        pm_options_scope_forwarding_set(options_scope, forwarding);
    }
}

/**
 * An iterator function that is called for each key-value in the keywords hash.
 */
static int
build_options_i(VALUE key, VALUE value, VALUE argument) {
    pm_options_t *options = (pm_options_t *) argument;
    ID key_id = SYM2ID(key);

    if (key_id == rb_id_option_filepath) {
        if (!NIL_P(value)) pm_options_filepath_set(options, check_string(value));
    } else if (key_id == rb_id_option_encoding) {
        if (!NIL_P(value)) {
            if (value == Qfalse) {
                pm_options_encoding_locked_set(options, true);
            } else {
                pm_options_encoding_set(options, rb_enc_name(rb_to_encoding(value)));
            }
        }
    } else if (key_id == rb_id_option_line) {
        if (!NIL_P(value)) pm_options_line_set(options, NUM2INT(value));
    } else if (key_id == rb_id_option_frozen_string_literal) {
        if (!NIL_P(value)) pm_options_frozen_string_literal_set(options, RTEST(value));
    } else if (key_id == rb_id_option_version) {
        if (!NIL_P(value)) {
            const char *version = check_string(value);

            if (!pm_options_version_set(options, version, RSTRING_LEN(value))) {
                rb_raise(rb_eArgError, "invalid version: %" PRIsVALUE, value);
            }
        }
    } else if (key_id == rb_id_option_scopes) {
        if (!NIL_P(value)) build_options_scopes(options, value);
    } else if (key_id == rb_id_option_command_line) {
        if (!NIL_P(value)) {
            const char *string = check_string(value);
            uint8_t command_line = 0;

            for (size_t index = 0; index < strlen(string); index++) {
                switch (string[index]) {
                    case 'a': command_line |= PM_OPTIONS_COMMAND_LINE_A; break;
                    case 'e': command_line |= PM_OPTIONS_COMMAND_LINE_E; break;
                    case 'l': command_line |= PM_OPTIONS_COMMAND_LINE_L; break;
                    case 'n': command_line |= PM_OPTIONS_COMMAND_LINE_N; break;
                    case 'p': command_line |= PM_OPTIONS_COMMAND_LINE_P; break;
                    case 'x': command_line |= PM_OPTIONS_COMMAND_LINE_X; break;
                    default: rb_raise(rb_eArgError, "invalid command line flag: '%c'", string[index]); break;
                }
            }

            pm_options_command_line_set(options, command_line);
        }
    } else if (key_id == rb_id_option_main_script) {
        if (!NIL_P(value)) pm_options_main_script_set(options, RTEST(value));
    } else if (key_id == rb_id_option_partial_script) {
        if (!NIL_P(value)) pm_options_partial_script_set(options, RTEST(value));
    } else if (key_id == rb_id_option_freeze) {
        if (!NIL_P(value)) pm_options_freeze_set(options, RTEST(value));
    } else {
        rb_raise(rb_eArgError, "unknown keyword: %" PRIsVALUE, key);
    }

    return ST_CONTINUE;
}

/**
 * We need a struct here to pass through rb_protect and it has to be a single
 * value. Because the sizeof(VALUE) == sizeof(void *), we're going to pass this
 * through as an opaque pointer and cast it on both sides.
 */
struct build_options_data {
    pm_options_t *options;
    VALUE keywords;
};

/**
 * Build the set of options from the given keywords. Note that this can raise a
 * Ruby error if the options are not valid.
 */
static VALUE
build_options(VALUE argument) {
    struct build_options_data *data = (struct build_options_data *) argument;
    rb_hash_foreach(data->keywords, build_options_i, (VALUE) data->options);
    return Qnil;
}

/**
 * Extract the options from the given keyword arguments.
 */
static void
extract_options(pm_options_t *options, VALUE filepath, VALUE keywords) {
    options->line = 1; // default

    if (!NIL_P(keywords)) {
        struct build_options_data data = { .options = options, .keywords = keywords };
        struct build_options_data *argument = &data;

        int state = 0;
        rb_protect(build_options, (VALUE) argument, &state);

        if (state != 0) {
            pm_options_free(options);
            rb_jump_tag(state);
        }
    }

    if (!NIL_P(filepath)) {
        if (!RB_TYPE_P(filepath, T_STRING)) {
            pm_options_free(options);
            rb_raise(rb_eTypeError, "wrong argument type %"PRIsVALUE" (expected String)", rb_obj_class(filepath));
        }

        pm_options_filepath_set(options, RSTRING_PTR(filepath));
    }
}

/**
 * Read options for methods that look like (source, **options).
 */
static void
string_options(int argc, VALUE *argv, pm_string_t *input, pm_options_t *options) {
    VALUE string;
    VALUE keywords;
    rb_scan_args(argc, argv, "1:", &string, &keywords);

    extract_options(options, Qnil, keywords);
    input_load_string(input, string);
}

/**
 * Read options for methods that look like (filepath, **options).
 */
static void
file_options(int argc, VALUE *argv, pm_string_t *input, pm_options_t *options, VALUE *encoded_filepath) {
    VALUE filepath;
    VALUE keywords;
    rb_scan_args(argc, argv, "1:", &filepath, &keywords);

    Check_Type(filepath, T_STRING);
    *encoded_filepath = rb_str_encode_ospath(filepath);
    extract_options(options, *encoded_filepath, keywords);

    const char *source = (const char *) pm_string_source(&options->filepath);
    pm_string_init_result_t result;

    switch (result = pm_string_file_init(input, source)) {
        case PM_STRING_INIT_SUCCESS:
            break;
        case PM_STRING_INIT_ERROR_GENERIC: {
            pm_options_free(options);

#ifdef _WIN32
            int e = rb_w32_map_errno(GetLastError());
#else
            int e = errno;
#endif

            rb_syserr_fail(e, source);
            break;
        }
        case PM_STRING_INIT_ERROR_DIRECTORY:
            pm_options_free(options);
            rb_syserr_fail(EISDIR, source);
            break;
        default:
            pm_options_free(options);
            rb_raise(rb_eRuntimeError, "Unknown error (%d) initializing file: %s", result, source);
            break;
    }
}

#ifndef PRISM_EXCLUDE_SERIALIZATION

/******************************************************************************/
/* Serializing the AST                                                        */
/******************************************************************************/

/**
 * Dump the AST corresponding to the given input to a string.
 */
static VALUE
dump_input(pm_string_t *input, const pm_options_t *options) {
    pm_buffer_t buffer;
    if (!pm_buffer_init(&buffer)) {
        rb_raise(rb_eNoMemError, "failed to allocate memory");
    }

    pm_parser_t parser;
    pm_parser_init(&parser, pm_string_source(input), pm_string_length(input), options);

    pm_node_t *node = pm_parse(&parser);
    pm_serialize(&parser, node, &buffer);

    VALUE result = rb_str_new(pm_buffer_value(&buffer), pm_buffer_length(&buffer));
    pm_node_destroy(&parser, node);
    pm_buffer_free(&buffer);
    pm_parser_free(&parser);

    return result;
}

/**
 * call-seq:
 *   Prism::dump(source, **options) -> String
 *
 * Dump the AST corresponding to the given string to a string. For supported
 * options, see Prism::parse.
 */
static VALUE
dump(int argc, VALUE *argv, VALUE self) {
    pm_string_t input;
    pm_options_t options = { 0 };
    string_options(argc, argv, &input, &options);

#ifdef PRISM_BUILD_DEBUG
    size_t length = pm_string_length(&input);
    char* dup = xmalloc(length);
    memcpy(dup, pm_string_source(&input), length);
    pm_string_constant_init(&input, dup, length);
#endif

    VALUE value = dump_input(&input, &options);
    if (options.freeze) rb_obj_freeze(value);

#ifdef PRISM_BUILD_DEBUG
    xfree(dup);
#endif

    pm_string_free(&input);
    pm_options_free(&options);

    return value;
}

/**
 * call-seq:
 *   Prism::dump_file(filepath, **options) -> String
 *
 * Dump the AST corresponding to the given file to a string. For supported
 * options, see Prism::parse.
 */
static VALUE
dump_file(int argc, VALUE *argv, VALUE self) {
    pm_string_t input;
    pm_options_t options = { 0 };

    VALUE encoded_filepath;
    file_options(argc, argv, &input, &options, &encoded_filepath);

    VALUE value = dump_input(&input, &options);
    pm_string_free(&input);
    pm_options_free(&options);

    return value;
}

#endif

/******************************************************************************/
/* Extracting values for the parse result                                     */
/******************************************************************************/

/**
 * The same as rb_class_new_instance, but accepts an additional boolean to
 * indicate whether or not the resulting class instance should be frozen.
 */
static inline VALUE
rb_class_new_instance_freeze(int argc, const VALUE *argv, VALUE klass, bool freeze) {
    VALUE value = rb_class_new_instance(argc, argv, klass);
    if (freeze) rb_obj_freeze(value);
    return value;
}

/**
 * Create a new Location instance from the given parser and bounds.
 */
static inline VALUE
parser_location(const pm_parser_t *parser, VALUE source, bool freeze, const uint8_t *start, size_t length) {
    VALUE argv[] = { source, LONG2FIX(start - parser->start), LONG2FIX(length) };
    return rb_class_new_instance_freeze(3, argv, rb_cPrismLocation, freeze);
}

/**
 * Create a new Location instance from the given parser and location.
 */
#define PARSER_LOCATION_LOC(parser, source, freeze, loc) \
    parser_location(parser, source, freeze, loc.start, (size_t) (loc.end - loc.start))

/**
 * Build a new Comment instance from the given parser and comment.
 */
static inline VALUE
parser_comment(const pm_parser_t *parser, VALUE source, bool freeze, const pm_comment_t *comment) {
    VALUE argv[] = { PARSER_LOCATION_LOC(parser, source, freeze, comment->location) };
    VALUE type = (comment->type == PM_COMMENT_EMBDOC) ? rb_cPrismEmbDocComment : rb_cPrismInlineComment;
    return rb_class_new_instance_freeze(1, argv, type, freeze);
}

/**
 * Extract the comments out of the parser into an array.
 */
static VALUE
parser_comments(const pm_parser_t *parser, VALUE source, bool freeze) {
    VALUE comments = rb_ary_new_capa(parser->comment_list.size);

    for (
        const pm_comment_t *comment = (const pm_comment_t *) parser->comment_list.head;
        comment != NULL;
        comment = (const pm_comment_t *) comment->node.next
    ) {
        VALUE value = parser_comment(parser, source, freeze, comment);
        rb_ary_push(comments, value);
    }

    if (freeze) rb_obj_freeze(comments);
    return comments;
}

/**
 * Build a new MagicComment instance from the given parser and magic comment.
 */
static inline VALUE
parser_magic_comment(const pm_parser_t *parser, VALUE source, bool freeze, const pm_magic_comment_t *magic_comment) {
    VALUE key_loc = parser_location(parser, source, freeze, magic_comment->key_start, magic_comment->key_length);
    VALUE value_loc = parser_location(parser, source, freeze, magic_comment->value_start, magic_comment->value_length);
    VALUE argv[] = { key_loc, value_loc };
    return rb_class_new_instance_freeze(2, argv, rb_cPrismMagicComment, freeze);
}

/**
 * Extract the magic comments out of the parser into an array.
 */
static VALUE
parser_magic_comments(const pm_parser_t *parser, VALUE source, bool freeze) {
    VALUE magic_comments = rb_ary_new_capa(parser->magic_comment_list.size);

    for (
        const pm_magic_comment_t *magic_comment = (const pm_magic_comment_t *) parser->magic_comment_list.head;
        magic_comment != NULL;
        magic_comment = (const pm_magic_comment_t *) magic_comment->node.next
    ) {
        VALUE value = parser_magic_comment(parser, source, freeze, magic_comment);
        rb_ary_push(magic_comments, value);
    }

    if (freeze) rb_obj_freeze(magic_comments);
    return magic_comments;
}

/**
 * Extract out the data location from the parser into a Location instance if one
 * exists.
 */
static VALUE
parser_data_loc(const pm_parser_t *parser, VALUE source, bool freeze) {
    if (parser->data_loc.end == NULL) {
        return Qnil;
    } else {
        return PARSER_LOCATION_LOC(parser, source, freeze, parser->data_loc);
    }
}

/**
 * Extract the errors out of the parser into an array.
 */
static VALUE
parser_errors(const pm_parser_t *parser, rb_encoding *encoding, VALUE source, bool freeze) {
    VALUE errors = rb_ary_new_capa(parser->error_list.size);

    for (
        const pm_diagnostic_t *error = (const pm_diagnostic_t *) parser->error_list.head;
        error != NULL;
        error = (const pm_diagnostic_t *) error->node.next
    ) {
        VALUE type = ID2SYM(rb_intern(pm_diagnostic_id_human(error->diag_id)));
        VALUE message = rb_obj_freeze(rb_enc_str_new_cstr(error->message, encoding));
        VALUE location = PARSER_LOCATION_LOC(parser, source, freeze, error->location);

        VALUE level = Qnil;
        switch (error->level) {
            case PM_ERROR_LEVEL_SYNTAX:
                level = ID2SYM(rb_intern("syntax"));
                break;
            case PM_ERROR_LEVEL_ARGUMENT:
                level = ID2SYM(rb_intern("argument"));
                break;
            case PM_ERROR_LEVEL_LOAD:
                level = ID2SYM(rb_intern("load"));
                break;
            default:
                rb_raise(rb_eRuntimeError, "Unknown level: %" PRIu8, error->level);
        }

        VALUE argv[] = { type, message, location, level };
        VALUE value = rb_class_new_instance_freeze(4, argv, rb_cPrismParseError, freeze);
        rb_ary_push(errors, value);
    }

    if (freeze) rb_obj_freeze(errors);
    return errors;
}

/**
 * Extract the warnings out of the parser into an array.
 */
static VALUE
parser_warnings(const pm_parser_t *parser, rb_encoding *encoding, VALUE source, bool freeze) {
    VALUE warnings = rb_ary_new_capa(parser->warning_list.size);

    for (
        const pm_diagnostic_t *warning = (const pm_diagnostic_t *) parser->warning_list.head;
        warning != NULL;
        warning = (const pm_diagnostic_t *) warning->node.next
    ) {
        VALUE type = ID2SYM(rb_intern(pm_diagnostic_id_human(warning->diag_id)));
        VALUE message = rb_obj_freeze(rb_enc_str_new_cstr(warning->message, encoding));
        VALUE location = PARSER_LOCATION_LOC(parser, source, freeze, warning->location);

        VALUE level = Qnil;
        switch (warning->level) {
            case PM_WARNING_LEVEL_DEFAULT:
                level = ID2SYM(rb_intern("default"));
                break;
            case PM_WARNING_LEVEL_VERBOSE:
                level = ID2SYM(rb_intern("verbose"));
                break;
            default:
                rb_raise(rb_eRuntimeError, "Unknown level: %" PRIu8, warning->level);
        }

        VALUE argv[] = { type, message, location, level };
        VALUE value = rb_class_new_instance_freeze(4, argv, rb_cPrismParseWarning, freeze);
        rb_ary_push(warnings, value);
    }

    if (freeze) rb_obj_freeze(warnings);
    return warnings;
}

/**
 * Create a new parse result from the given parser, value, encoding, and source.
 */
static VALUE
parse_result_create(VALUE class, const pm_parser_t *parser, VALUE value, rb_encoding *encoding, VALUE source, bool freeze) {
    VALUE result_argv[] = {
        value,
        parser_comments(parser, source, freeze),
        parser_magic_comments(parser, source, freeze),
        parser_data_loc(parser, source, freeze),
        parser_errors(parser, encoding, source, freeze),
        parser_warnings(parser, encoding, source, freeze),
        source
    };

    return rb_class_new_instance_freeze(7, result_argv, class, freeze);
}

/******************************************************************************/
/* Lexing Ruby code                                                           */
/******************************************************************************/

/**
 * This struct gets stored in the parser and passed in to the lex callback any
 * time a new token is found. We use it to store the necessary information to
 * initialize a Token instance.
 */
typedef struct {
    VALUE source;
    VALUE tokens;
    rb_encoding *encoding;
    bool freeze;
} parse_lex_data_t;

/**
 * This is passed as a callback to the parser. It gets called every time a new
 * token is found. Once found, we initialize a new instance of Token and push it
 * onto the tokens array.
 */
static void
parse_lex_token(void *data, pm_parser_t *parser, pm_token_t *token) {
    parse_lex_data_t *parse_lex_data = (parse_lex_data_t *) parser->lex_callback->data;

    VALUE value = pm_token_new(parser, token, parse_lex_data->encoding, parse_lex_data->source, parse_lex_data->freeze);
    VALUE yields = rb_assoc_new(value, INT2FIX(parser->lex_state));

    if (parse_lex_data->freeze) {
        rb_obj_freeze(value);
        rb_obj_freeze(yields);
    }

    rb_ary_push(parse_lex_data->tokens, yields);
}

/**
 * This is called whenever the encoding changes based on the magic comment at
 * the top of the file. We use it to update the encoding that we are using to
 * create tokens.
 */
static void
parse_lex_encoding_changed_callback(pm_parser_t *parser) {
    parse_lex_data_t *parse_lex_data = (parse_lex_data_t *) parser->lex_callback->data;
    parse_lex_data->encoding = rb_enc_find(parser->encoding->name);

    // Since the encoding changed, we need to go back and change the encoding of
    // the tokens that were already lexed. This is only going to end up being
    // one or two tokens, since the encoding can only change at the top of the
    // file.
    VALUE tokens = parse_lex_data->tokens;
    VALUE next_tokens = rb_ary_new();

    for (long index = 0; index < RARRAY_LEN(tokens); index++) {
        VALUE yields = rb_ary_entry(tokens, index);
        VALUE token = rb_ary_entry(yields, 0);

        VALUE value = rb_ivar_get(token, rb_intern("@value"));
        VALUE next_value = rb_str_dup(value);

        rb_enc_associate(next_value, parse_lex_data->encoding);
        if (parse_lex_data->freeze) rb_obj_freeze(next_value);

        VALUE next_token_argv[] = {
            parse_lex_data->source,
            rb_ivar_get(token, rb_intern("@type")),
            next_value,
            rb_ivar_get(token, rb_intern("@location"))
        };

        VALUE next_token = rb_class_new_instance(4, next_token_argv, rb_cPrismToken);
        VALUE next_yields = rb_assoc_new(next_token, rb_ary_entry(yields, 1));

        if (parse_lex_data->freeze) {
            rb_obj_freeze(next_token);
            rb_obj_freeze(next_yields);
        }

        rb_ary_push(next_tokens, next_yields);
    }

    rb_ary_replace(parse_lex_data->tokens, next_tokens);
}

/**
 * Parse the given input and return a ParseResult containing just the tokens or
 * the nodes and tokens.
 */
static VALUE
parse_lex_input(pm_string_t *input, const pm_options_t *options, bool return_nodes) {
    pm_parser_t parser;
    pm_parser_init(&parser, pm_string_source(input), pm_string_length(input), options);
    pm_parser_register_encoding_changed_callback(&parser, parse_lex_encoding_changed_callback);

    VALUE source_string = rb_str_new((const char *) pm_string_source(input), pm_string_length(input));
    VALUE offsets = rb_ary_new_capa(parser.newline_list.size);
    VALUE source = rb_funcall(rb_cPrismSource, rb_id_source_for, 3, source_string, LONG2NUM(parser.start_line), offsets);

    parse_lex_data_t parse_lex_data = {
        .source = source,
        .tokens = rb_ary_new(),
        .encoding = rb_utf8_encoding(),
        .freeze = options->freeze,
    };

    parse_lex_data_t *data = &parse_lex_data;
    pm_lex_callback_t lex_callback = (pm_lex_callback_t) {
        .data = (void *) data,
        .callback = parse_lex_token,
    };

    parser.lex_callback = &lex_callback;
    pm_node_t *node = pm_parse(&parser);

    // Here we need to update the Source object to have the correct
    // encoding for the source string and the correct newline offsets.
    // We do it here because we've already created the Source object and given
    // it over to all of the tokens, and both of these are only set after pm_parse().
    rb_encoding *encoding = rb_enc_find(parser.encoding->name);
    rb_enc_associate(source_string, encoding);

    for (size_t index = 0; index < parser.newline_list.size; index++) {
        rb_ary_push(offsets, ULONG2NUM(parser.newline_list.offsets[index]));
    }

    if (options->freeze) {
        rb_obj_freeze(source_string);
        rb_obj_freeze(offsets);
        rb_obj_freeze(source);
        rb_obj_freeze(parse_lex_data.tokens);
    }

    VALUE result;
    if (return_nodes) {
        VALUE value = rb_ary_new_capa(2);
        rb_ary_push(value, pm_ast_new(&parser, node, parse_lex_data.encoding, source, options->freeze));
        rb_ary_push(value, parse_lex_data.tokens);
        if (options->freeze) rb_obj_freeze(value);
        result = parse_result_create(rb_cPrismParseLexResult, &parser, value, parse_lex_data.encoding, source, options->freeze);
    } else {
        result = parse_result_create(rb_cPrismLexResult, &parser, parse_lex_data.tokens, parse_lex_data.encoding, source, options->freeze);
    }

    pm_node_destroy(&parser, node);
    pm_parser_free(&parser);

    return result;
}

/**
 * call-seq:
 *   Prism::lex(source, **options) -> LexResult
 *
 * Return a LexResult instance that contains an array of Token instances
 * corresponding to the given string. For supported options, see Prism::parse.
 */
static VALUE
lex(int argc, VALUE *argv, VALUE self) {
    pm_string_t input;
    pm_options_t options = { 0 };
    string_options(argc, argv, &input, &options);

    VALUE result = parse_lex_input(&input, &options, false);
    pm_string_free(&input);
    pm_options_free(&options);

    return result;
}

/**
 * call-seq:
 *   Prism::lex_file(filepath, **options) -> LexResult
 *
 * Return a LexResult instance that contains an array of Token instances
 * corresponding to the given file. For supported options, see Prism::parse.
 */
static VALUE
lex_file(int argc, VALUE *argv, VALUE self) {
    pm_string_t input;
    pm_options_t options = { 0 };

    VALUE encoded_filepath;
    file_options(argc, argv, &input, &options, &encoded_filepath);

    VALUE value = parse_lex_input(&input, &options, false);
    pm_string_free(&input);
    pm_options_free(&options);

    return value;
}

/******************************************************************************/
/* Parsing Ruby code                                                          */
/******************************************************************************/

/**
 * Parse the given input and return a ParseResult instance.
 */
static VALUE
parse_input(pm_string_t *input, const pm_options_t *options) {
    pm_parser_t parser;
    pm_parser_init(&parser, pm_string_source(input), pm_string_length(input), options);

    pm_node_t *node = pm_parse(&parser);
    rb_encoding *encoding = rb_enc_find(parser.encoding->name);

    VALUE source = pm_source_new(&parser, encoding, options->freeze);
    VALUE value = pm_ast_new(&parser, node, encoding, source, options->freeze);
    VALUE result = parse_result_create(rb_cPrismParseResult, &parser, value, encoding, source, options->freeze);

    if (options->freeze) {
        rb_obj_freeze(source);
    }

    pm_node_destroy(&parser, node);
    pm_parser_free(&parser);

    return result;
}

/**
 * call-seq:
 *   Prism::parse(source, **options) -> ParseResult
 *
 * Parse the given string and return a ParseResult instance. The options that
 * are supported are:
 *
 * * `command_line` - either nil or a string of the various options that were
 *       set on the command line. Valid values are combinations of "a", "l",
 *       "n", "p", and "x".
 * * `encoding` - the encoding of the source being parsed. This should be an
 *       encoding or nil.
 * * `filepath` - the filepath of the source being parsed. This should be a
 *       string or nil.
 * * `freeze` - whether or not to deeply freeze the AST. This should be a
 *       boolean or nil.
 * * `frozen_string_literal` - whether or not the frozen string literal pragma
 *       has been set. This should be a boolean or nil.
 * * `line` - the line number that the parse starts on. This should be an
 *       integer or nil. Note that this is 1-indexed.
 * * `main_script` - a boolean indicating whether or not the source being parsed
 *       is the main script being run by the interpreter. This controls whether
 *       or not shebangs are parsed for additional flags and whether or not the
 *       parser will attempt to find a matching shebang if the first one does
 *       not contain the word "ruby".
 * * `partial_script` - when the file being parsed is considered a "partial"
 *       script, jumps will not be marked as errors if they are not contained
 *       within loops/blocks. This is used in the case that you're parsing a
 *       script that you know will be embedded inside another script later, but
 *       you do not have that context yet. For example, when parsing an ERB
 *       template that will be evaluated inside another script.
 * * `scopes` - the locals that are in scope surrounding the code that is being
 *       parsed. This should be an array of arrays of symbols or nil. Scopes are
 *       ordered from the outermost scope to the innermost one.
 * * `version` - the version of Ruby syntax that prism should used to parse Ruby
 *       code. By default prism assumes you want to parse with the latest
 *       version of Ruby syntax (which you can trigger with `nil` or
 *       `"latest"`). You may also restrict the syntax to a specific version of
 *       Ruby, e.g., with `"3.3.0"`. To parse with the same syntax version that
 *       the current Ruby is running use `version: RUBY_VERSION`. Raises
 *       ArgumentError if the version is not currently supported by Prism.
 */
static VALUE
parse(int argc, VALUE *argv, VALUE self) {
    pm_string_t input;
    pm_options_t options = { 0 };
    string_options(argc, argv, &input, &options);

#ifdef PRISM_BUILD_DEBUG
    size_t length = pm_string_length(&input);
    char* dup = xmalloc(length);
    memcpy(dup, pm_string_source(&input), length);
    pm_string_constant_init(&input, dup, length);
#endif

    VALUE value = parse_input(&input, &options);

#ifdef PRISM_BUILD_DEBUG
    xfree(dup);
#endif

    pm_string_free(&input);
    pm_options_free(&options);
    return value;
}

/**
 * call-seq:
 *   Prism::parse_file(filepath, **options) -> ParseResult
 *
 * Parse the given file and return a ParseResult instance. For supported
 * options, see Prism::parse.
 */
static VALUE
parse_file(int argc, VALUE *argv, VALUE self) {
    pm_string_t input;
    pm_options_t options = { 0 };

    VALUE encoded_filepath;
    file_options(argc, argv, &input, &options, &encoded_filepath);

    VALUE value = parse_input(&input, &options);
    pm_string_free(&input);
    pm_options_free(&options);

    return value;
}

/**
 * Parse the given input and return nothing.
 */
static void
profile_input(pm_string_t *input, const pm_options_t *options) {
    pm_parser_t parser;
    pm_parser_init(&parser, pm_string_source(input), pm_string_length(input), options);

    pm_node_t *node = pm_parse(&parser);
    pm_node_destroy(&parser, node);
    pm_parser_free(&parser);
}

/**
 * call-seq:
 *   Prism::profile(source, **options) -> nil
 *
 * Parse the given string and return nothing. This method is meant to allow
 * profilers to avoid the overhead of reifying the AST to Ruby. For supported
 * options, see Prism::parse.
 */
static VALUE
profile(int argc, VALUE *argv, VALUE self) {
    pm_string_t input;
    pm_options_t options = { 0 };

    string_options(argc, argv, &input, &options);
    profile_input(&input, &options);
    pm_string_free(&input);
    pm_options_free(&options);

    return Qnil;
}

/**
 * call-seq:
 *   Prism::profile_file(filepath, **options) -> nil
 *
 * Parse the given file and return nothing. This method is meant to allow
 * profilers to avoid the overhead of reifying the AST to Ruby. For supported
 * options, see Prism::parse.
 */
static VALUE
profile_file(int argc, VALUE *argv, VALUE self) {
    pm_string_t input;
    pm_options_t options = { 0 };

    VALUE encoded_filepath;
    file_options(argc, argv, &input, &options, &encoded_filepath);

    profile_input(&input, &options);
    pm_string_free(&input);
    pm_options_free(&options);

    return Qnil;
}

/**
 * An implementation of fgets that is suitable for use with Ruby IO objects.
 */
static char *
parse_stream_fgets(char *string, int size, void *stream) {
    RUBY_ASSERT(size > 0);

    VALUE line = rb_funcall((VALUE) stream, rb_intern("gets"), 1, INT2FIX(size - 1));
    if (NIL_P(line)) {
        return NULL;
    }

    const char *cstr = RSTRING_PTR(line);
    long length = RSTRING_LEN(line);

    memcpy(string, cstr, length);
    string[length] = '\0';

    return string;
}

/**
 * call-seq:
 *   Prism::parse_stream(stream, **options) -> ParseResult
 *
 * Parse the given object that responds to `gets` and return a ParseResult
 * instance. The options that are supported are the same as Prism::parse.
 */
static VALUE
parse_stream(int argc, VALUE *argv, VALUE self) {
    VALUE stream;
    VALUE keywords;
    rb_scan_args(argc, argv, "1:", &stream, &keywords);

    pm_options_t options = { 0 };
    extract_options(&options, Qnil, keywords);

    pm_parser_t parser;
    pm_buffer_t buffer;

    pm_node_t *node = pm_parse_stream(&parser, &buffer, (void *) stream, parse_stream_fgets, &options);
    rb_encoding *encoding = rb_enc_find(parser.encoding->name);

    VALUE source = pm_source_new(&parser, encoding, options.freeze);
    VALUE value = pm_ast_new(&parser, node, encoding, source, options.freeze);
    VALUE result = parse_result_create(rb_cPrismParseResult, &parser, value, encoding, source, options.freeze);

    pm_node_destroy(&parser, node);
    pm_buffer_free(&buffer);
    pm_parser_free(&parser);

    return result;
}

/**
 * Parse the given input and return an array of Comment objects.
 */
static VALUE
parse_input_comments(pm_string_t *input, const pm_options_t *options) {
    pm_parser_t parser;
    pm_parser_init(&parser, pm_string_source(input), pm_string_length(input), options);

    pm_node_t *node = pm_parse(&parser);
    rb_encoding *encoding = rb_enc_find(parser.encoding->name);

    VALUE source = pm_source_new(&parser, encoding, options->freeze);
    VALUE comments = parser_comments(&parser, source, options->freeze);

    pm_node_destroy(&parser, node);
    pm_parser_free(&parser);

    return comments;
}

/**
 * call-seq:
 *   Prism::parse_comments(source, **options) -> Array
 *
 * Parse the given string and return an array of Comment objects. For supported
 * options, see Prism::parse.
 */
static VALUE
parse_comments(int argc, VALUE *argv, VALUE self) {
    pm_string_t input;
    pm_options_t options = { 0 };
    string_options(argc, argv, &input, &options);

    VALUE result = parse_input_comments(&input, &options);
    pm_string_free(&input);
    pm_options_free(&options);

    return result;
}

/**
 * call-seq:
 *   Prism::parse_file_comments(filepath, **options) -> Array
 *
 * Parse the given file and return an array of Comment objects. For supported
 * options, see Prism::parse.
 */
static VALUE
parse_file_comments(int argc, VALUE *argv, VALUE self) {
    pm_string_t input;
    pm_options_t options = { 0 };

    VALUE encoded_filepath;
    file_options(argc, argv, &input, &options, &encoded_filepath);

    VALUE value = parse_input_comments(&input, &options);
    pm_string_free(&input);
    pm_options_free(&options);

    return value;
}

/**
 * call-seq:
 *   Prism::parse_lex(source, **options) -> ParseLexResult
 *
 * Parse the given string and return a ParseLexResult instance that contains a
 * 2-element array, where the first element is the AST and the second element is
 * an array of Token instances.
 *
 * This API is only meant to be used in the case where you need both the AST and
 * the tokens. If you only need one or the other, use either Prism::parse or
 * Prism::lex.
 *
 * For supported options, see Prism::parse.
 */
static VALUE
parse_lex(int argc, VALUE *argv, VALUE self) {
    pm_string_t input;
    pm_options_t options = { 0 };
    string_options(argc, argv, &input, &options);

    VALUE value = parse_lex_input(&input, &options, true);
    pm_string_free(&input);
    pm_options_free(&options);

    return value;
}

/**
 * call-seq:
 *   Prism::parse_lex_file(filepath, **options) -> ParseLexResult
 *
 * Parse the given file and return a ParseLexResult instance that contains a
 * 2-element array, where the first element is the AST and the second element is
 * an array of Token instances.
 *
 * This API is only meant to be used in the case where you need both the AST and
 * the tokens. If you only need one or the other, use either Prism::parse_file
 * or Prism::lex_file.
 *
 * For supported options, see Prism::parse.
 */
static VALUE
parse_lex_file(int argc, VALUE *argv, VALUE self) {
    pm_string_t input;
    pm_options_t options = { 0 };

    VALUE encoded_filepath;
    file_options(argc, argv, &input, &options, &encoded_filepath);

    VALUE value = parse_lex_input(&input, &options, true);
    pm_string_free(&input);
    pm_options_free(&options);

    return value;
}

/**
 * Parse the given input and return true if it parses without errors.
 */
static VALUE
parse_input_success_p(pm_string_t *input, const pm_options_t *options) {
    pm_parser_t parser;
    pm_parser_init(&parser, pm_string_source(input), pm_string_length(input), options);

    pm_node_t *node = pm_parse(&parser);
    pm_node_destroy(&parser, node);

    VALUE result = parser.error_list.size == 0 ? Qtrue : Qfalse;
    pm_parser_free(&parser);

    return result;
}

/**
 * call-seq:
 *   Prism::parse_success?(source, **options) -> bool
 *
 * Parse the given string and return true if it parses without errors. For
 * supported options, see Prism::parse.
 */
static VALUE
parse_success_p(int argc, VALUE *argv, VALUE self) {
    pm_string_t input;
    pm_options_t options = { 0 };
    string_options(argc, argv, &input, &options);

    VALUE result = parse_input_success_p(&input, &options);
    pm_string_free(&input);
    pm_options_free(&options);

    return result;
}

/**
 * call-seq:
 *   Prism::parse_failure?(source, **options) -> bool
 *
 * Parse the given string and return true if it parses with errors. For
 * supported options, see Prism::parse.
 */
static VALUE
parse_failure_p(int argc, VALUE *argv, VALUE self) {
    return RTEST(parse_success_p(argc, argv, self)) ? Qfalse : Qtrue;
}

/**
 * call-seq:
 *   Prism::parse_file_success?(filepath, **options) -> bool
 *
 * Parse the given file and return true if it parses without errors. For
 * supported options, see Prism::parse.
 */
static VALUE
parse_file_success_p(int argc, VALUE *argv, VALUE self) {
    pm_string_t input;
    pm_options_t options = { 0 };

    VALUE encoded_filepath;
    file_options(argc, argv, &input, &options, &encoded_filepath);

    VALUE result = parse_input_success_p(&input, &options);
    pm_string_free(&input);
    pm_options_free(&options);

    return result;
}

/**
 * call-seq:
 *   Prism::parse_file_failure?(filepath, **options) -> bool
 *
 * Parse the given file and return true if it parses with errors. For
 * supported options, see Prism::parse.
 */
static VALUE
parse_file_failure_p(int argc, VALUE *argv, VALUE self) {
    return RTEST(parse_file_success_p(argc, argv, self)) ? Qfalse : Qtrue;
}

/******************************************************************************/
/* String query methods                                                       */
/******************************************************************************/

/**
 * Process the result of a call to a string query method and return an
 * appropriate value.
 */
static VALUE
string_query(pm_string_query_t result) {
    switch (result) {
        case PM_STRING_QUERY_ERROR:
            rb_raise(rb_eArgError, "Invalid or non ascii-compatible encoding");
            return Qfalse;
        case PM_STRING_QUERY_FALSE:
            return Qfalse;
        case PM_STRING_QUERY_TRUE:
            return Qtrue;
    }
    return Qfalse;
}

/**
 * call-seq:
 *   Prism::StringQuery::local?(string) -> bool
 *
 * Returns true if the string constitutes a valid local variable name. Note that
 * this means the names that can be set through Binding#local_variable_set, not
 * necessarily the ones that can be set through a local variable assignment.
 */
static VALUE
string_query_local_p(VALUE self, VALUE string) {
    const uint8_t *source = (const uint8_t *) check_string(string);
    return string_query(pm_string_query_local(source, RSTRING_LEN(string), rb_enc_get(string)->name));
}

/**
 * call-seq:
 *   Prism::StringQuery::constant?(string) -> bool
 *
 * Returns true if the string constitutes a valid constant name. Note that this
 * means the names that can be set through Module#const_set, not necessarily the
 * ones that can be set through a constant assignment.
 */
static VALUE
string_query_constant_p(VALUE self, VALUE string) {
    const uint8_t *source = (const uint8_t *) check_string(string);
    return string_query(pm_string_query_constant(source, RSTRING_LEN(string), rb_enc_get(string)->name));
}

/**
 * call-seq:
 *   Prism::StringQuery::method_name?(string) -> bool
 *
 * Returns true if the string constitutes a valid method name.
 */
static VALUE
string_query_method_name_p(VALUE self, VALUE string) {
    const uint8_t *source = (const uint8_t *) check_string(string);
    return string_query(pm_string_query_method_name(source, RSTRING_LEN(string), rb_enc_get(string)->name));
}

/******************************************************************************/
/* Initialization of the extension                                            */
/******************************************************************************/

/**
 * The init function that Ruby calls when loading this extension.
 */
RUBY_FUNC_EXPORTED void
Init_prism(void) {
    // Make sure that the prism library version matches the expected version.
    // Otherwise something was compiled incorrectly.
    if (strcmp(pm_version(), EXPECTED_PRISM_VERSION) != 0) {
        rb_raise(
            rb_eRuntimeError,
            "The prism library version (%s) does not match the expected version (%s)",
            pm_version(),
            EXPECTED_PRISM_VERSION
        );
    }

    // Grab up references to all of the constants that we're going to need to
    // reference throughout this extension.
    rb_cPrism = rb_define_module("Prism");
    rb_cPrismNode = rb_define_class_under(rb_cPrism, "Node", rb_cObject);
    rb_cPrismSource = rb_define_class_under(rb_cPrism, "Source", rb_cObject);
    rb_cPrismToken = rb_define_class_under(rb_cPrism, "Token", rb_cObject);
    rb_cPrismLocation = rb_define_class_under(rb_cPrism, "Location", rb_cObject);
    rb_cPrismComment = rb_define_class_under(rb_cPrism, "Comment", rb_cObject);
    rb_cPrismInlineComment = rb_define_class_under(rb_cPrism, "InlineComment", rb_cPrismComment);
    rb_cPrismEmbDocComment = rb_define_class_under(rb_cPrism, "EmbDocComment", rb_cPrismComment);
    rb_cPrismMagicComment = rb_define_class_under(rb_cPrism, "MagicComment", rb_cObject);
    rb_cPrismParseError = rb_define_class_under(rb_cPrism, "ParseError", rb_cObject);
    rb_cPrismParseWarning = rb_define_class_under(rb_cPrism, "ParseWarning", rb_cObject);
    rb_cPrismResult = rb_define_class_under(rb_cPrism, "Result", rb_cObject);
    rb_cPrismParseResult = rb_define_class_under(rb_cPrism, "ParseResult", rb_cPrismResult);
    rb_cPrismLexResult = rb_define_class_under(rb_cPrism, "LexResult", rb_cPrismResult);
    rb_cPrismParseLexResult = rb_define_class_under(rb_cPrism, "ParseLexResult", rb_cPrismResult);
    rb_cPrismStringQuery = rb_define_class_under(rb_cPrism, "StringQuery", rb_cObject);
    rb_cPrismScope = rb_define_class_under(rb_cPrism, "Scope", rb_cObject);

    // Intern all of the IDs eagerly that we support so that we don't have to do
    // it every time we parse.
    rb_id_option_command_line = rb_intern_const("command_line");
    rb_id_option_encoding = rb_intern_const("encoding");
    rb_id_option_filepath = rb_intern_const("filepath");
    rb_id_option_freeze = rb_intern_const("freeze");
    rb_id_option_frozen_string_literal = rb_intern_const("frozen_string_literal");
    rb_id_option_line = rb_intern_const("line");
    rb_id_option_main_script = rb_intern_const("main_script");
    rb_id_option_partial_script = rb_intern_const("partial_script");
    rb_id_option_scopes = rb_intern_const("scopes");
    rb_id_option_version = rb_intern_const("version");
    rb_id_source_for = rb_intern("for");
    rb_id_forwarding_positionals = rb_intern("*");
    rb_id_forwarding_keywords = rb_intern("**");
    rb_id_forwarding_block = rb_intern("&");
    rb_id_forwarding_all = rb_intern("...");

    /**
     * The version of the prism library.
     */
    rb_define_const(rb_cPrism, "VERSION", rb_str_freeze(rb_str_new_cstr(EXPECTED_PRISM_VERSION)));

    // First, the functions that have to do with lexing and parsing.
    rb_define_singleton_method(rb_cPrism, "lex", lex, -1);
    rb_define_singleton_method(rb_cPrism, "lex_file", lex_file, -1);
    rb_define_singleton_method(rb_cPrism, "parse", parse, -1);
    rb_define_singleton_method(rb_cPrism, "parse_file", parse_file, -1);
    rb_define_singleton_method(rb_cPrism, "profile", profile, -1);
    rb_define_singleton_method(rb_cPrism, "profile_file", profile_file, -1);
    rb_define_singleton_method(rb_cPrism, "parse_stream", parse_stream, -1);
    rb_define_singleton_method(rb_cPrism, "parse_comments", parse_comments, -1);
    rb_define_singleton_method(rb_cPrism, "parse_file_comments", parse_file_comments, -1);
    rb_define_singleton_method(rb_cPrism, "parse_lex", parse_lex, -1);
    rb_define_singleton_method(rb_cPrism, "parse_lex_file", parse_lex_file, -1);
    rb_define_singleton_method(rb_cPrism, "parse_success?", parse_success_p, -1);
    rb_define_singleton_method(rb_cPrism, "parse_failure?", parse_failure_p, -1);
    rb_define_singleton_method(rb_cPrism, "parse_file_success?", parse_file_success_p, -1);
    rb_define_singleton_method(rb_cPrism, "parse_file_failure?", parse_file_failure_p, -1);

#ifndef PRISM_EXCLUDE_SERIALIZATION
    rb_define_singleton_method(rb_cPrism, "dump", dump, -1);
    rb_define_singleton_method(rb_cPrism, "dump_file", dump_file, -1);
#endif

    rb_define_singleton_method(rb_cPrismStringQuery, "local?", string_query_local_p, 1);
    rb_define_singleton_method(rb_cPrismStringQuery, "constant?", string_query_constant_p, 1);
    rb_define_singleton_method(rb_cPrismStringQuery, "method_name?", string_query_method_name_p, 1);

    // Next, initialize the other APIs.
    Init_prism_api_node();
    Init_prism_pack();
}
