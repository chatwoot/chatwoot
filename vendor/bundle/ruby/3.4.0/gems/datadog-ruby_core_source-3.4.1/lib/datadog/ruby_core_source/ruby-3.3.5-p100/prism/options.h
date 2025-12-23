/**
 * @file options.h
 *
 * The options that can be passed to parsing.
 */
#ifndef PRISM_OPTIONS_H
#define PRISM_OPTIONS_H

#include "prism/defines.h"
#include "prism/util/pm_string.h"

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/**
 * A scope of locals surrounding the code that is being parsed.
 */
typedef struct pm_options_scope {
    /** The number of locals in the scope. */
    size_t locals_count;

    /** The names of the locals in the scope. */
    pm_string_t *locals;
} pm_options_scope_t;

/**
 * The options that can be passed to the parser.
 */
typedef struct {
    /** The name of the file that is currently being parsed. */
    pm_string_t filepath;

    /**
     * The line within the file that the parse starts on. This value is
     * 0-indexed.
     */
    int32_t line;

    /**
     * The name of the encoding that the source file is in. Note that this must
     * correspond to a name that can be found with Encoding.find in Ruby.
     */
    pm_string_t encoding;

    /**
     * The number of scopes surrounding the code that is being parsed.
     */
    size_t scopes_count;

    /**
     * The scopes surrounding the code that is being parsed. For most parses
     * this will be NULL, but for evals it will be the locals that are in scope
     * surrounding the eval.
     */
    pm_options_scope_t *scopes;

    /** Whether or not the frozen string literal option has been set. */
    bool frozen_string_literal;

    /**
     * Whether or not we should suppress warnings. This is purposefully negated
     * so that the default is to not suppress warnings, which allows us to still
     * create an options struct with zeroed memory.
     */
    bool suppress_warnings;
} pm_options_t;

/**
 * Set the filepath option on the given options struct.
 *
 * @param options The options struct to set the filepath on.
 * @param filepath The filepath to set.
 */
PRISM_EXPORTED_FUNCTION void pm_options_filepath_set(pm_options_t *options, const char *filepath);

/**
 * Set the line option on the given options struct.
 *
 * @param options The options struct to set the line on.
 * @param line The line to set.
 */
PRISM_EXPORTED_FUNCTION void pm_options_line_set(pm_options_t *options, int32_t line);

/**
 * Set the encoding option on the given options struct.
 *
 * @param options The options struct to set the encoding on.
 * @param encoding The encoding to set.
 */
PRISM_EXPORTED_FUNCTION void pm_options_encoding_set(pm_options_t *options, const char *encoding);

/**
 * Set the frozen string literal option on the given options struct.
 *
 * @param options The options struct to set the frozen string literal value on.
 * @param frozen_string_literal The frozen string literal value to set.
 */
PRISM_EXPORTED_FUNCTION void pm_options_frozen_string_literal_set(pm_options_t *options, bool frozen_string_literal);

/**
 * Set the suppress warnings option on the given options struct.
 *
 * @param options The options struct to set the suppress warnings value on.
 * @param suppress_warnings The suppress warnings value to set.
 */
PRISM_EXPORTED_FUNCTION void pm_options_suppress_warnings_set(pm_options_t *options, bool suppress_warnings);

/**
 * Allocate and zero out the scopes array on the given options struct.
 *
 * @param options The options struct to initialize the scopes array on.
 * @param scopes_count The number of scopes to allocate.
 */
PRISM_EXPORTED_FUNCTION void pm_options_scopes_init(pm_options_t *options, size_t scopes_count);

/**
 * Return a pointer to the scope at the given index within the given options.
 *
 * @param options The options struct to get the scope from.
 * @param index The index of the scope to get.
 * @return A pointer to the scope at the given index.
 */
PRISM_EXPORTED_FUNCTION const pm_options_scope_t * pm_options_scope_get(const pm_options_t *options, size_t index);

/**
 * Create a new options scope struct. This will hold a set of locals that are in
 * scope surrounding the code that is being parsed.
 *
 * @param scope The scope struct to initialize.
 * @param locals_count The number of locals to allocate.
 */
PRISM_EXPORTED_FUNCTION void pm_options_scope_init(pm_options_scope_t *scope, size_t locals_count);

/**
 * Return a pointer to the local at the given index within the given scope.
 *
 * @param scope The scope struct to get the local from.
 * @param index The index of the local to get.
 * @return A pointer to the local at the given index.
 */
PRISM_EXPORTED_FUNCTION const pm_string_t * pm_options_scope_local_get(const pm_options_scope_t *scope, size_t index);

/**
 * Free the internal memory associated with the options.
 *
 * @param options The options struct whose internal memory should be freed.
 */
PRISM_EXPORTED_FUNCTION void pm_options_free(pm_options_t *options);

/**
 * Deserialize an options struct from the given binary string. This is used to
 * pass options to the parser from an FFI call so that consumers of the library
 * from an FFI perspective don't have to worry about the structure of our
 * options structs. Since the source of these calls will be from Ruby
 * implementation internals we assume it is from a trusted source.
 *
 * `data` is assumed to be a valid pointer pointing to well-formed data. The
 * layout of this data should be the same every time, and is described below:
 *
 * | # bytes | field                      |
 * | ------- | -------------------------- |
 * | `4`     | the length of the filepath |
 * | ...     | the filepath bytes         |
 * | `4`     | the line number            |
 * | `4`     | the length the encoding    |
 * | ...     | the encoding bytes         |
 * | `1`     | frozen string literal      |
 * | `1`     | suppress warnings          |
 * | `4`     | the number of scopes       |
 * | ...     | the scopes                 |
 *
 * Each scope is layed out as follows:
 *
 * | # bytes | field                      |
 * | ------- | -------------------------- |
 * | `4`     | the number of locals       |
 * | ...     | the locals                 |
 *
 * Each local is layed out as follows:
 *
 * | # bytes | field                      |
 * | ------- | -------------------------- |
 * | `4`     | the length of the local    |
 * | ...     | the local bytes            |
 *
 * Some additional things to note about this layout:
 *
 * * The filepath can have a length of 0, in which case we'll consider it an
 *   empty string.
 * * The line number should be 0-indexed.
 * * The encoding can have a length of 0, in which case we'll use the default
 *   encoding (UTF-8). If it's not 0, it should correspond to a name of an
 *   encoding that can be passed to `Encoding.find` in Ruby.
 * * The frozen string literal and suppress warnings fields are booleans, so
 *   their values should be either 0 or 1.
 * * The number of scopes can be 0.
 *
 * @param options The options struct to deserialize into.
 * @param data The binary string to deserialize from.
 */
void pm_options_read(pm_options_t *options, const char *data);

#endif
