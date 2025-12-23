/**
 * @file prism.h
 *
 * The main header file for the prism parser.
 */
#ifndef PRISM_H
#define PRISM_H

#include "prism/defines.h"
#include "prism/util/pm_buffer.h"
#include "prism/util/pm_char.h"
#include "prism/util/pm_memchr.h"
#include "prism/util/pm_strncasecmp.h"
#include "prism/util/pm_strpbrk.h"
#include "prism/ast.h"
#include "prism/diagnostic.h"
#include "prism/node.h"
#include "prism/options.h"
#include "prism/pack.h"
#include "prism/parser.h"
#include "prism/prettyprint.h"
#include "prism/regexp.h"
#include "prism/version.h"

#include <assert.h>
#include <errno.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef _WIN32
#include <strings.h>
#endif

/**
 * The prism version and the serialization format.
 *
 * @returns The prism version as a constant string.
 */
PRISM_EXPORTED_FUNCTION const char * pm_version(void);

/**
 * Initialize a parser with the given start and end pointers.
 *
 * @param parser The parser to initialize.
 * @param source The source to parse.
 * @param size The size of the source.
 * @param options The optional options to use when parsing.
 */
PRISM_EXPORTED_FUNCTION void pm_parser_init(pm_parser_t *parser, const uint8_t *source, size_t size, const pm_options_t *options);

/**
 * Register a callback that will be called whenever prism changes the encoding
 * it is using to parse based on the magic comment.
 *
 * @param parser The parser to register the callback with.
 * @param callback The callback to register.
 */
PRISM_EXPORTED_FUNCTION void pm_parser_register_encoding_changed_callback(pm_parser_t *parser, pm_encoding_changed_callback_t callback);

/**
 * Free any memory associated with the given parser.
 *
 * @param parser The parser to free.
 */
PRISM_EXPORTED_FUNCTION void pm_parser_free(pm_parser_t *parser);

/**
 * Initiate the parser with the given parser.
 *
 * @param parser The parser to use.
 * @return The AST representing the source.
 */
PRISM_EXPORTED_FUNCTION pm_node_t * pm_parse(pm_parser_t *parser);

/**
 * Serialize the given list of comments to the given buffer.
 *
 * @param parser The parser to serialize.
 * @param list The list of comments to serialize.
 * @param buffer The buffer to serialize to.
 */
void pm_serialize_comment_list(pm_parser_t *parser, pm_list_t *list, pm_buffer_t *buffer);

/**
 * Serialize the name of the encoding to the buffer.
 *
 * @param encoding The encoding to serialize.
 * @param buffer The buffer to serialize to.
 */
void pm_serialize_encoding(const pm_encoding_t *encoding, pm_buffer_t *buffer);

/**
 * Serialize the encoding, metadata, nodes, and constant pool.
 *
 * @param parser The parser to serialize.
 * @param node The node to serialize.
 * @param buffer The buffer to serialize to.
 */
void pm_serialize_content(pm_parser_t *parser, pm_node_t *node, pm_buffer_t *buffer);

/**
 * Serialize the AST represented by the given node to the given buffer.
 *
 * @param parser The parser to serialize.
 * @param node The node to serialize.
 * @param buffer The buffer to serialize to.
 */
PRISM_EXPORTED_FUNCTION void pm_serialize(pm_parser_t *parser, pm_node_t *node, pm_buffer_t *buffer);

/**
 * Parse the given source to the AST and dump the AST to the given buffer.
 *
 * @param buffer The buffer to serialize to.
 * @param source The source to parse.
 * @param size The size of the source.
 * @param data The optional data to pass to the parser.
 */
PRISM_EXPORTED_FUNCTION void pm_serialize_parse(pm_buffer_t *buffer, const uint8_t *source, size_t size, const char *data);

/**
 * Parse and serialize the comments in the given source to the given buffer.
 *
 * @param buffer The buffer to serialize to.
 * @param source The source to parse.
 * @param size The size of the source.
 * @param data The optional data to pass to the parser.
 */
PRISM_EXPORTED_FUNCTION void pm_serialize_parse_comments(pm_buffer_t *buffer, const uint8_t *source, size_t size, const char *data);

/**
 * Lex the given source and serialize to the given buffer.
 *
 * @param source The source to lex.
 * @param size The size of the source.
 * @param buffer The buffer to serialize to.
 * @param data The optional data to pass to the lexer.
 */
PRISM_EXPORTED_FUNCTION void pm_serialize_lex(pm_buffer_t *buffer, const uint8_t *source, size_t size, const char *data);

/**
 * Parse and serialize both the AST and the tokens represented by the given
 * source to the given buffer.
 *
 * @param buffer The buffer to serialize to.
 * @param source The source to parse.
 * @param size The size of the source.
 * @param data The optional data to pass to the parser.
 */
PRISM_EXPORTED_FUNCTION void pm_serialize_parse_lex(pm_buffer_t *buffer, const uint8_t *source, size_t size, const char *data);

/**
 * Parse the source and return true if it parses without errors or warnings.
 *
 * @param source The source to parse.
 * @param size The size of the source.
 * @param data The optional data to pass to the parser.
 * @return True if the source parses without errors or warnings.
 */
PRISM_EXPORTED_FUNCTION bool pm_parse_success_p(const uint8_t *source, size_t size, const char *data);

/**
 * Returns a string representation of the given token type.
 *
 * @param token_type The token type to convert to a string.
 * @return A string representation of the given token type.
 */
PRISM_EXPORTED_FUNCTION const char * pm_token_type_to_str(pm_token_type_t token_type);

/**
 * @mainpage
 *
 * Prism is a parser for the Ruby programming language. It is designed to be
 * portable, error tolerant, and maintainable. It is written in C99 and has no
 * dependencies. It is currently being integrated into
 * [CRuby](https://github.com/ruby/ruby),
 * [JRuby](https://github.com/jruby/jruby),
 * [TruffleRuby](https://github.com/oracle/truffleruby),
 * [Sorbet](https://github.com/sorbet/sorbet), and
 * [Syntax Tree](https://github.com/ruby-syntax-tree/syntax_tree).
 *
 * @section getting-started Getting started
 *
 * If you're vendoring this project and compiling it statically then as long as
 * you have a C99 compiler you will be fine. If you're linking against it as
 * shared library, then you should compile with `-fvisibility=hidden` and
 * `-DPRISM_EXPORT_SYMBOLS` to tell prism to make only its public interface
 * visible.
 *
 * @section parsing Parsing
 *
 * In order to parse Ruby code, the structures and functions that you're going
 * to want to use and be aware of are:
 *
 * * `pm_parser_t` - the main parser structure
 * * `pm_parser_init` - initialize a parser
 * * `pm_parse` - parse and return the root node
 * * `pm_node_destroy` - deallocate the root node returned by `pm_parse`
 * * `pm_parser_free` - free the internal memory of the parser
 *
 * Putting all of this together would look something like:
 *
 * ```c
 * void parse(const uint8_t *source, size_t length) {
 *     pm_parser_t parser;
 *     pm_parser_init(&parser, source, length, NULL);
 *
 *     pm_node_t *root = pm_parse(&parser);
 *     printf("PARSED!\n");
 *
 *     pm_node_destroy(&parser, root);
 *     pm_parser_free(&parser);
 * }
 * ```
 *
 * All of the nodes "inherit" from `pm_node_t` by embedding those structures as
 * their first member. This means you can downcast and upcast any node in the
 * tree to a `pm_node_t`.
 *
 * @section serializing Serializing
 *
 * Prism provides the ability to serialize the AST and its related metadata into
 * a binary format. This format is designed to be portable to different
 * languages and runtimes so that you only need to make one FFI call in order to
 * parse Ruby code. The structures and functions that you're going to want to
 * use and be aware of are:
 *
 * * `pm_buffer_t` - a small buffer object that will hold the serialized AST
 * * `pm_buffer_free` - free the memory associated with the buffer
 * * `pm_serialize` - serialize the AST into a buffer
 * * `pm_serialize_parse` - parse and serialize the AST into a buffer
 *
 * Putting all of this together would look something like:
 *
 * ```c
 * void serialize(const uint8_t *source, size_t length) {
 *     pm_buffer_t buffer = { 0 };
 *
 *     pm_serialize_parse(&buffer, source, length, NULL);
 *     printf("SERIALIZED!\n");
 *
 *     pm_buffer_free(&buffer);
 * }
 * ```
 *
 * @section inspecting Inspecting
 *
 * Prism provides the ability to inspect the AST by pretty-printing nodes. You
 * can do this with the `pm_prettyprint` function, which you would use like:
 *
 * ```c
 * void prettyprint(const uint8_t *source, size_t length) {
 *     pm_parser_t parser;
 *     pm_parser_init(&parser, source, length, NULL);
 *
 *     pm_node_t *root = pm_parse(&parser);
 *     pm_buffer_t buffer = { 0 };
 *
 *     pm_prettyprint(&buffer, &parser, root);
 *     printf("*.s%\n", (int) buffer.length, buffer.value);
 *
 *     pm_buffer_free(&buffer);
 *     pm_node_destroy(&parser, root);
 *     pm_parser_free(&parser);
 * }
 * ```
 */

#endif
