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
#include "prism/util/pm_string_list.h"
#include "prism/util/pm_string.h"

#include <stdbool.h>
#include <stddef.h>
#include <string.h>

/**
 * Parse a regular expression and extract the names of all of the named capture
 * groups.
 *
 * @param source The source code to parse.
 * @param size The size of the source code.
 * @param named_captures The list to add the names of the named capture groups.
 * @param encoding_changed Whether or not the encoding changed from the default.
 * @param encoding The encoding of the source code.
 * @return Whether or not the parsing was successful.
 */
PRISM_EXPORTED_FUNCTION bool pm_regexp_named_capture_group_names(const uint8_t *source, size_t size, pm_string_list_t *named_captures, bool encoding_changed, const pm_encoding_t *encoding);

#endif
