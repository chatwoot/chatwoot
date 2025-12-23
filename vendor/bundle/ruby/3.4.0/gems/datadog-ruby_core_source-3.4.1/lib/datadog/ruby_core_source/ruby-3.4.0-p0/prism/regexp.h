/**
 * @file regexp.h
 *
 * A regular expression parser.
 */
#ifndef PRISM_REGEXP_H
#define PRISM_REGEXP_H

#include "prism/defines.h"
#include "prism/parser.h"
#include "prism/encoding.h"
#include "prism/util/pm_memchr.h"
#include "prism/util/pm_string.h"

#include <stdbool.h>
#include <stddef.h>
#include <string.h>

/**
 * This callback is called when a named capture group is found.
 */
typedef void (*pm_regexp_name_callback_t)(const pm_string_t *name, void *data);

/**
 * This callback is called when a parse error is found.
 */
typedef void (*pm_regexp_error_callback_t)(const uint8_t *start, const uint8_t *end, const char *message, void *data);

/**
 * Parse a regular expression.
 *
 * @param parser The parser that is currently being used.
 * @param source The source code to parse.
 * @param size The size of the source code.
 * @param extended_mode Whether to parse the regular expression in extended mode.
 * @param name_callback The optional callback to call when a named capture group is found.
 * @param name_data The optional data to pass to the name callback.
 * @param error_callback The callback to call when a parse error is found.
 * @param error_data The data to pass to the error callback.
 */
PRISM_EXPORTED_FUNCTION void pm_regexp_parse(pm_parser_t *parser, const uint8_t *source, size_t size, bool extended_mode, pm_regexp_name_callback_t name_callback, void *name_data, pm_regexp_error_callback_t error_callback, void *error_data);

#endif
