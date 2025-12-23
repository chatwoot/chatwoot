#include "prism/options.h"

/**
 * Set the shebang callback option on the given options struct.
 */
PRISM_EXPORTED_FUNCTION void
pm_options_shebang_callback_set(pm_options_t *options, pm_options_shebang_callback_t shebang_callback, void *shebang_callback_data) {
    options->shebang_callback = shebang_callback;
    options->shebang_callback_data = shebang_callback_data;
}

/**
 * Set the filepath option on the given options struct.
 */
PRISM_EXPORTED_FUNCTION void
pm_options_filepath_set(pm_options_t *options, const char *filepath) {
    pm_string_constant_init(&options->filepath, filepath, strlen(filepath));
}

/**
 * Set the encoding option on the given options struct.
 */
PRISM_EXPORTED_FUNCTION void
pm_options_encoding_set(pm_options_t *options, const char *encoding) {
    pm_string_constant_init(&options->encoding, encoding, strlen(encoding));
}

/**
 * Set the encoding_locked option on the given options struct.
 */
PRISM_EXPORTED_FUNCTION void
pm_options_encoding_locked_set(pm_options_t *options, bool encoding_locked) {
    options->encoding_locked = encoding_locked;
}

/**
 * Set the line option on the given options struct.
 */
PRISM_EXPORTED_FUNCTION void
pm_options_line_set(pm_options_t *options, int32_t line) {
    options->line = line;
}

/**
 * Set the frozen string literal option on the given options struct.
 */
PRISM_EXPORTED_FUNCTION void
pm_options_frozen_string_literal_set(pm_options_t *options, bool frozen_string_literal) {
    options->frozen_string_literal = frozen_string_literal ? PM_OPTIONS_FROZEN_STRING_LITERAL_ENABLED : PM_OPTIONS_FROZEN_STRING_LITERAL_DISABLED;
}

/**
 * Sets the command line option on the given options struct.
 */
PRISM_EXPORTED_FUNCTION void
pm_options_command_line_set(pm_options_t *options, uint8_t command_line) {
    options->command_line = command_line;
}

/**
 * Checks if the given slice represents a number.
 */
static inline bool
is_number(const char *string, size_t length) {
    return pm_strspn_decimal_digit((const uint8_t *) string, (ptrdiff_t) length) == length;
}

/**
 * Set the version option on the given options struct by parsing the given
 * string. If the string contains an invalid option, this returns false.
 * Otherwise, it returns true.
 */
PRISM_EXPORTED_FUNCTION bool
pm_options_version_set(pm_options_t *options, const char *version, size_t length) {
    if (version == NULL) {
        options->version = PM_OPTIONS_VERSION_LATEST;
        return true;
    }

    if (length == 3) {
        if (strncmp(version, "3.3", 3) == 0) {
            options->version = PM_OPTIONS_VERSION_CRUBY_3_3;
            return true;
        }

        if (strncmp(version, "3.4", 3) == 0) {
            options->version = PM_OPTIONS_VERSION_CRUBY_3_4;
            return true;
        }

        if (strncmp(version, "3.5", 3) == 0) {
            options->version = PM_OPTIONS_VERSION_LATEST;
            return true;
        }

        return false;
    }

    if (length >= 4) {
        if (strncmp(version, "3.3.", 4) == 0 && is_number(version + 4, length - 4)) {
            options->version = PM_OPTIONS_VERSION_CRUBY_3_3;
            return true;
        }

        if (strncmp(version, "3.4.", 4) == 0 && is_number(version + 4, length - 4)) {
            options->version = PM_OPTIONS_VERSION_CRUBY_3_4;
            return true;
        }

        if (strncmp(version, "3.5.", 4) == 0 && is_number(version + 4, length - 4)) {
            options->version = PM_OPTIONS_VERSION_LATEST;
            return true;
        }
    }

    if (length >= 6) {
        if (strncmp(version, "latest", 7) == 0) { // 7 to compare the \0 as well
            options->version = PM_OPTIONS_VERSION_LATEST;
            return true;
        }
    }

    return false;
}

/**
 * Set the main script option on the given options struct.
 */
PRISM_EXPORTED_FUNCTION void
pm_options_main_script_set(pm_options_t *options, bool main_script) {
    options->main_script = main_script;
}

/**
 * Set the partial script option on the given options struct.
 */
PRISM_EXPORTED_FUNCTION void
pm_options_partial_script_set(pm_options_t *options, bool partial_script) {
    options->partial_script = partial_script;
}

/**
 * Set the freeze option on the given options struct.
 */
PRISM_EXPORTED_FUNCTION void
pm_options_freeze_set(pm_options_t *options, bool freeze) {
    options->freeze = freeze;
}

// For some reason, GCC analyzer thinks we're leaking allocated scopes and
// locals here, even though we definitely aren't. This is a false positive.
// Ideally we wouldn't need to suppress this.
#if defined(__GNUC__) && (__GNUC__ >= 10)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wanalyzer-malloc-leak"
#endif

/**
 * Allocate and zero out the scopes array on the given options struct.
 */
PRISM_EXPORTED_FUNCTION bool
pm_options_scopes_init(pm_options_t *options, size_t scopes_count) {
    options->scopes_count = scopes_count;
    options->scopes = xcalloc(scopes_count, sizeof(pm_options_scope_t));
    return options->scopes != NULL;
}

/**
 * Return a pointer to the scope at the given index within the given options.
 */
PRISM_EXPORTED_FUNCTION const pm_options_scope_t *
pm_options_scope_get(const pm_options_t *options, size_t index) {
    return &options->scopes[index];
}

/**
 * Create a new options scope struct. This will hold a set of locals that are in
 * scope surrounding the code that is being parsed.
 */
PRISM_EXPORTED_FUNCTION bool
pm_options_scope_init(pm_options_scope_t *scope, size_t locals_count) {
    scope->locals_count = locals_count;
    scope->locals = xcalloc(locals_count, sizeof(pm_string_t));
    scope->forwarding = PM_OPTIONS_SCOPE_FORWARDING_NONE;
    return scope->locals != NULL;
}

/**
 * Return a pointer to the local at the given index within the given scope.
 */
PRISM_EXPORTED_FUNCTION const pm_string_t *
pm_options_scope_local_get(const pm_options_scope_t *scope, size_t index) {
    return &scope->locals[index];
}

/**
 * Set the forwarding option on the given scope struct.
 */
PRISM_EXPORTED_FUNCTION void
pm_options_scope_forwarding_set(pm_options_scope_t *scope, uint8_t forwarding) {
    scope->forwarding = forwarding;
}

/**
 * Free the internal memory associated with the options.
 */
PRISM_EXPORTED_FUNCTION void
pm_options_free(pm_options_t *options) {
    pm_string_free(&options->filepath);
    pm_string_free(&options->encoding);

    for (size_t scope_index = 0; scope_index < options->scopes_count; scope_index++) {
        pm_options_scope_t *scope = &options->scopes[scope_index];

        for (size_t local_index = 0; local_index < scope->locals_count; local_index++) {
            pm_string_free(&scope->locals[local_index]);
        }

        xfree(scope->locals);
    }

    xfree(options->scopes);
}

/**
 * Read a 32-bit unsigned integer from a pointer. This function is used to read
 * the options that are passed into the parser from the Ruby implementation. It
 * handles aligned and unaligned reads.
 */
static uint32_t
pm_options_read_u32(const char *data) {
    if (((uintptr_t) data) % sizeof(uint32_t) == 0) {
        return *((uint32_t *) data);
    } else {
        uint32_t value;
        memcpy(&value, data, sizeof(uint32_t));
        return value;
    }
}

/**
 * Read a 32-bit signed integer from a pointer. This function is used to read
 * the options that are passed into the parser from the Ruby implementation. It
 * handles aligned and unaligned reads.
 */
static int32_t
pm_options_read_s32(const char *data) {
    if (((uintptr_t) data) % sizeof(int32_t) == 0) {
        return *((int32_t *) data);
    } else {
        int32_t value;
        memcpy(&value, data, sizeof(int32_t));
        return value;
    }
}

/**
 * Deserialize an options struct from the given binary string. This is used to
 * pass options to the parser from an FFI call so that consumers of the library
 * from an FFI perspective don't have to worry about the structure of our
 * options structs. Since the source of these calls will be from Ruby
 * implementation internals we assume it is from a trusted source.
 */
void
pm_options_read(pm_options_t *options, const char *data) {
    options->line = 1; // default
    if (data == NULL) return;

    uint32_t filepath_length = pm_options_read_u32(data);
    data += 4;

    if (filepath_length > 0) {
        pm_string_constant_init(&options->filepath, data, filepath_length);
        data += filepath_length;
    }

    options->line = pm_options_read_s32(data);
    data += 4;

    uint32_t encoding_length = pm_options_read_u32(data);
    data += 4;

    if (encoding_length > 0) {
        pm_string_constant_init(&options->encoding, data, encoding_length);
        data += encoding_length;
    }

    options->frozen_string_literal = (int8_t) *data++;
    options->command_line = (uint8_t) *data++;
    options->version = (pm_options_version_t) *data++;
    options->encoding_locked = ((uint8_t) *data++) > 0;
    options->main_script = ((uint8_t) *data++) > 0;
    options->partial_script = ((uint8_t) *data++) > 0;
    options->freeze = ((uint8_t) *data++) > 0;

    uint32_t scopes_count = pm_options_read_u32(data);
    data += 4;

    if (scopes_count > 0) {
        if (!pm_options_scopes_init(options, scopes_count)) return;

        for (size_t scope_index = 0; scope_index < scopes_count; scope_index++) {
            uint32_t locals_count = pm_options_read_u32(data);
            data += 4;

            pm_options_scope_t *scope = &options->scopes[scope_index];
            if (!pm_options_scope_init(scope, locals_count)) {
                pm_options_free(options);
                return;
            }

            uint8_t forwarding = (uint8_t) *data++;
            pm_options_scope_forwarding_set(&options->scopes[scope_index], forwarding);

            for (size_t local_index = 0; local_index < locals_count; local_index++) {
                uint32_t local_length = pm_options_read_u32(data);
                data += 4;

                pm_string_constant_init(&scope->locals[local_index], data, local_length);
                data += local_length;
            }
        }
    }
}

#if defined(__GNUC__) && (__GNUC__ >= 10)
#pragma GCC diagnostic pop
#endif
