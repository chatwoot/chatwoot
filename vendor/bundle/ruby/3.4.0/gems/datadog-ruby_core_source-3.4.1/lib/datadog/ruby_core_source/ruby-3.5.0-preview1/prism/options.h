/**
 * @file options.h
 *
 * The options that can be passed to parsing.
 */
#ifndef PRISM_OPTIONS_H
#define PRISM_OPTIONS_H

#include "prism/defines.h"
#include "prism/util/pm_char.h"
#include "prism/util/pm_string.h"

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/**
 * String literals should be made frozen.
 */
#define PM_OPTIONS_FROZEN_STRING_LITERAL_DISABLED   ((int8_t) -1)

/**
 * String literals may be frozen or mutable depending on the implementation
 * default.
 */
#define PM_OPTIONS_FROZEN_STRING_LITERAL_UNSET      ((int8_t)  0)

/**
 * String literals should be made mutable.
 */
#define PM_OPTIONS_FROZEN_STRING_LITERAL_ENABLED    ((int8_t)  1)

/**
 * A scope of locals surrounding the code that is being parsed.
 */
typedef struct pm_options_scope {
    /** The number of locals in the scope. */
    size_t locals_count;

    /** The names of the locals in the scope. */
    pm_string_t *locals;

    /** Flags for the set of forwarding parameters in this scope. */
    uint8_t forwarding;
} pm_options_scope_t;

/** The default value for parameters. */
static const uint8_t PM_OPTIONS_SCOPE_FORWARDING_NONE = 0x0;

/** When the scope is fowarding with the * parameter. */
static const uint8_t PM_OPTIONS_SCOPE_FORWARDING_POSITIONALS = 0x1;

/** When the scope is fowarding with the ** parameter. */
static const uint8_t PM_OPTIONS_SCOPE_FORWARDING_KEYWORDS = 0x2;

/** When the scope is fowarding with the & parameter. */
static const uint8_t PM_OPTIONS_SCOPE_FORWARDING_BLOCK = 0x4;

/** When the scope is fowarding with the ... parameter. */
static const uint8_t PM_OPTIONS_SCOPE_FORWARDING_ALL = 0x8;

// Forward declaration needed by the callback typedef.
struct pm_options;

/**
 * The callback called when additional switches are found in a shebang comment
 * that need to be processed by the runtime.
 *
 * @param options The options struct that may be updated by this callback.
 *   Certain fields will be checked for changes, specifically encoding,
 *   command_line, and frozen_string_literal.
 * @param source The source of the shebang comment.
 * @param length The length of the source.
 * @param shebang_callback_data Any additional data that should be passed along
 *   to the callback.
 */
typedef void (*pm_options_shebang_callback_t)(struct pm_options *options, const uint8_t *source, size_t length, void *shebang_callback_data);

/**
 * The version of Ruby syntax that we should be parsing with. This is used to
 * allow consumers to specify which behavior they want in case they need to
 * parse in the same way as a specific version of CRuby would have.
 */
typedef enum {
    /** The current version of prism. */
    PM_OPTIONS_VERSION_LATEST = 0,

    /** The vendored version of prism in CRuby 3.3.x. */
    PM_OPTIONS_VERSION_CRUBY_3_3 = 1,

    /** The vendored version of prism in CRuby 3.4.x. */
    PM_OPTIONS_VERSION_CRUBY_3_4 = 2
} pm_options_version_t;

/**
 * The options that can be passed to the parser.
 */
typedef struct pm_options {
    /**
     * The callback to call when additional switches are found in a shebang
     * comment.
     */
    pm_options_shebang_callback_t shebang_callback;

    /**
     * Any additional data that should be passed along to the shebang callback
     * if one was set.
     */
    void *shebang_callback_data;

    /** The name of the file that is currently being parsed. */
    pm_string_t filepath;

    /**
     * The line within the file that the parse starts on. This value is
     * 1-indexed.
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
     * surrounding the eval. Scopes are ordered from the outermost scope to the
     * innermost one.
     */
    pm_options_scope_t *scopes;

    /**
     * The version of prism that we should be parsing with. This is used to
     * allow consumers to specify which behavior they want in case they need to
     * parse exactly as a specific version of CRuby.
     */
    pm_options_version_t version;

    /** A bitset of the various options that were set on the command line. */
    uint8_t command_line;

    /**
    * Whether or not the frozen string literal option has been set.
    * May be:
    *  - PM_OPTIONS_FROZEN_STRING_LITERAL_DISABLED
    *  - PM_OPTIONS_FROZEN_STRING_LITERAL_ENABLED
    *  - PM_OPTIONS_FROZEN_STRING_LITERAL_UNSET
    */
    int8_t frozen_string_literal;

    /**
     * Whether or not the encoding magic comments should be respected. This is a
     * niche use-case where you want to parse a file with a specific encoding
     * but ignore any encoding magic comments at the top of the file.
     */
    bool encoding_locked;

    /**
     * When the file being parsed is the main script, the shebang will be
     * considered for command-line flags (or for implicit -x). The caller needs
     * to pass this information to the parser so that it can behave correctly.
     */
    bool main_script;

    /**
     * When the file being parsed is considered a "partial" script, jumps will
     * not be marked as errors if they are not contained within loops/blocks.
     * This is used in the case that you're parsing a script that you know will
     * be embedded inside another script later, but you do not have that context
     * yet. For example, when parsing an ERB template that will be evaluated
     * inside another script.
     */
    bool partial_script;

    /**
     * Whether or not the parser should freeze the nodes that it creates. This
     * makes it possible to have a deeply frozen AST that is safe to share
     * between concurrency primitives.
     */
    bool freeze;
} pm_options_t;

/**
 * A bit representing whether or not the command line -a option was set. -a
 * splits the input line $_ into $F.
 */
static const uint8_t PM_OPTIONS_COMMAND_LINE_A = 0x1;

/**
 * A bit representing whether or not the command line -e option was set. -e
 * allow the user to specify a script to be executed. This is necessary for
 * prism to know because certain warnings are not generated when -e is used.
 */
static const uint8_t PM_OPTIONS_COMMAND_LINE_E = 0x2;

/**
 * A bit representing whether or not the command line -l option was set. -l
 * chomps the input line by default.
 */
static const uint8_t PM_OPTIONS_COMMAND_LINE_L = 0x4;

/**
 * A bit representing whether or not the command line -n option was set. -n
 * wraps the script in a while gets loop.
 */
static const uint8_t PM_OPTIONS_COMMAND_LINE_N = 0x8;

/**
 * A bit representing whether or not the command line -p option was set. -p
 * prints the value of $_ at the end of each loop.
 */
static const uint8_t PM_OPTIONS_COMMAND_LINE_P = 0x10;

/**
 * A bit representing whether or not the command line -x option was set. -x
 * searches the input file for a shebang that matches the current Ruby engine.
 */
static const uint8_t PM_OPTIONS_COMMAND_LINE_X = 0x20;

/**
 * Set the shebang callback option on the given options struct.
 *
 * @param options The options struct to set the shebang callback on.
 * @param shebang_callback The shebang callback to set.
 * @param shebang_callback_data Any additional data that should be passed along
 *   to the callback.
 */
PRISM_EXPORTED_FUNCTION void pm_options_shebang_callback_set(pm_options_t *options, pm_options_shebang_callback_t shebang_callback, void *shebang_callback_data);

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
 * Set the encoding_locked option on the given options struct.
 *
 * @param options The options struct to set the encoding_locked value on.
 * @param encoding_locked The encoding_locked value to set.
 */
PRISM_EXPORTED_FUNCTION void pm_options_encoding_locked_set(pm_options_t *options, bool encoding_locked);

/**
 * Set the frozen string literal option on the given options struct.
 *
 * @param options The options struct to set the frozen string literal value on.
 * @param frozen_string_literal The frozen string literal value to set.
 */
PRISM_EXPORTED_FUNCTION void pm_options_frozen_string_literal_set(pm_options_t *options, bool frozen_string_literal);

/**
 * Sets the command line option on the given options struct.
 *
 * @param options The options struct to set the command line option on.
 * @param command_line The command_line value to set.
 */
PRISM_EXPORTED_FUNCTION void pm_options_command_line_set(pm_options_t *options, uint8_t command_line);

/**
 * Set the version option on the given options struct by parsing the given
 * string. If the string contains an invalid option, this returns false.
 * Otherwise, it returns true.
 *
 * @param options The options struct to set the version on.
 * @param version The version to set.
 * @param length The length of the version string.
 * @return Whether or not the version was parsed successfully.
 */
PRISM_EXPORTED_FUNCTION bool pm_options_version_set(pm_options_t *options, const char *version, size_t length);

/**
 * Set the main script option on the given options struct.
 *
 * @param options The options struct to set the main script value on.
 * @param main_script The main script value to set.
 */
PRISM_EXPORTED_FUNCTION void pm_options_main_script_set(pm_options_t *options, bool main_script);

/**
 * Set the partial script option on the given options struct.
 *
 * @param options The options struct to set the partial script value on.
 * @param partial_script The partial script value to set.
 */
PRISM_EXPORTED_FUNCTION void pm_options_partial_script_set(pm_options_t *options, bool partial_script);

/**
 * Set the freeze option on the given options struct.
 *
 * @param options The options struct to set the freeze value on.
 * @param freeze The freeze value to set.
 */
PRISM_EXPORTED_FUNCTION void pm_options_freeze_set(pm_options_t *options, bool freeze);

/**
 * Allocate and zero out the scopes array on the given options struct.
 *
 * @param options The options struct to initialize the scopes array on.
 * @param scopes_count The number of scopes to allocate.
 * @return Whether or not the scopes array was initialized successfully.
 */
PRISM_EXPORTED_FUNCTION bool pm_options_scopes_init(pm_options_t *options, size_t scopes_count);

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
 * @return Whether or not the scope was initialized successfully.
 */
PRISM_EXPORTED_FUNCTION bool pm_options_scope_init(pm_options_scope_t *scope, size_t locals_count);

/**
 * Return a pointer to the local at the given index within the given scope.
 *
 * @param scope The scope struct to get the local from.
 * @param index The index of the local to get.
 * @return A pointer to the local at the given index.
 */
PRISM_EXPORTED_FUNCTION const pm_string_t * pm_options_scope_local_get(const pm_options_scope_t *scope, size_t index);

/**
 * Set the forwarding option on the given scope struct.
 *
 * @param scope The scope struct to set the forwarding on.
 * @param forwarding The forwarding value to set.
 */
PRISM_EXPORTED_FUNCTION void pm_options_scope_forwarding_set(pm_options_scope_t *scope, uint8_t forwarding);

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
 * | `1`     | -p command line option     |
 * | `1`     | -n command line option     |
 * | `1`     | -l command line option     |
 * | `1`     | -a command line option     |
 * | `1`     | the version                |
 * | `1`     | encoding locked            |
 * | `1`     | main script                |
 * | `1`     | partial script             |
 * | `1`     | freeze                     |
 * | `4`     | the number of scopes       |
 * | ...     | the scopes                 |
 *
 * The version field is an enum, so it should be one of the following values:
 *
 * | value | version                   |
 * | ----- | ------------------------- |
 * | `0`   | use the latest version of prism |
 * | `1`   | use the version of prism that is vendored in CRuby 3.3.0 |
 *
 * Each scope is laid out as follows:
 *
 * | # bytes | field                      |
 * | ------- | -------------------------- |
 * | `4`     | the number of locals       |
 * | `1`     | the forwarding flags       |
 * | ...     | the locals                 |
 *
 * Each local is laid out as follows:
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
 * * The frozen string literal, encoding locked, main script, and partial script
 *   fields are booleans, so their values should be either 0 or 1.
 * * The number of scopes can be 0.
 *
 * @param options The options struct to deserialize into.
 * @param data The binary string to deserialize from.
 */
void pm_options_read(pm_options_t *options, const char *data);

#endif
