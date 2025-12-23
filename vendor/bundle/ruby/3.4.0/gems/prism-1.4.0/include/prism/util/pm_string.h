/**
 * @file pm_string.h
 *
 * A generic string type that can have various ownership semantics.
 */
#ifndef PRISM_STRING_H
#define PRISM_STRING_H

#include "prism/defines.h"

#include <assert.h>
#include <errno.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

// The following headers are necessary to read files using demand paging.
#ifdef _WIN32
#include <windows.h>
#elif defined(_POSIX_MAPPED_FILES)
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#elif defined(PRISM_HAS_FILESYSTEM)
#include <fcntl.h>
#include <sys/stat.h>
#endif

/**
 * A generic string type that can have various ownership semantics.
 */
typedef struct {
    /** A pointer to the start of the string. */
    const uint8_t *source;

    /** The length of the string in bytes of memory. */
    size_t length;

    /** The type of the string. This field determines how the string should be freed. */
    enum {
        /** This string is a constant string, and should not be freed. */
        PM_STRING_CONSTANT,

        /** This is a slice of another string, and should not be freed. */
        PM_STRING_SHARED,

        /** This string owns its memory, and should be freed using `pm_string_free`. */
        PM_STRING_OWNED,

#ifdef PRISM_HAS_MMAP
        /** This string is a memory-mapped file, and should be freed using `pm_string_free`. */
        PM_STRING_MAPPED
#endif
    } type;
} pm_string_t;

/**
 * Returns the size of the pm_string_t struct. This is necessary to allocate the
 * correct amount of memory in the FFI backend.
 *
 * @return The size of the pm_string_t struct.
 */
PRISM_EXPORTED_FUNCTION size_t pm_string_sizeof(void);

/**
 * Defines an empty string. This is useful for initializing a string that will
 * be filled in later.
 */
#define PM_STRING_EMPTY ((pm_string_t) { .type = PM_STRING_CONSTANT, .source = NULL, .length = 0 })

/**
 * Initialize a shared string that is based on initial input.
 *
 * @param string The string to initialize.
 * @param start The start of the string.
 * @param end The end of the string.
 */
void pm_string_shared_init(pm_string_t *string, const uint8_t *start, const uint8_t *end);

/**
 * Initialize an owned string that is responsible for freeing allocated memory.
 *
 * @param string The string to initialize.
 * @param source The source of the string.
 * @param length The length of the string.
 */
void pm_string_owned_init(pm_string_t *string, uint8_t *source, size_t length);

/**
 * Initialize a constant string that doesn't own its memory source.
 *
 * @param string The string to initialize.
 * @param source The source of the string.
 * @param length The length of the string.
 */
void pm_string_constant_init(pm_string_t *string, const char *source, size_t length);

/**
 * Represents the result of calling pm_string_mapped_init or
 * pm_string_file_init. We need this additional information because there is
 * not a platform-agnostic way to indicate that the file that was attempted to
 * be opened was a directory.
 */
typedef enum {
    /** Indicates that the string was successfully initialized. */
    PM_STRING_INIT_SUCCESS = 0,
    /**
     * Indicates a generic error from a string_*_init function, where the type
     * of error should be read from `errno` or `GetLastError()`.
     */
    PM_STRING_INIT_ERROR_GENERIC = 1,
    /**
     * Indicates that the file that was attempted to be opened was a directory.
     */
    PM_STRING_INIT_ERROR_DIRECTORY = 2
} pm_string_init_result_t;

/**
 * Read the file indicated by the filepath parameter into source and load its
 * contents and size into the given `pm_string_t`. The given `pm_string_t`
 * should be freed using `pm_string_free` when it is no longer used.
 *
 * We want to use demand paging as much as possible in order to avoid having to
 * read the entire file into memory (which could be detrimental to performance
 * for large files). This means that if we're on windows we'll use
 * `MapViewOfFile`, on POSIX systems that have access to `mmap` we'll use
 * `mmap`, and on other POSIX systems we'll use `read`.
 *
 * @param string The string to initialize.
 * @param filepath The filepath to read.
 * @return The success of the read, indicated by the value of the enum.
 */
PRISM_EXPORTED_FUNCTION pm_string_init_result_t pm_string_mapped_init(pm_string_t *string, const char *filepath);

/**
 * Read the file indicated by the filepath parameter into source and load its
 * contents and size into the given `pm_string_t`. The given `pm_string_t`
 * should be freed using `pm_string_free` when it is no longer used.
 *
 * @param string The string to initialize.
 * @param filepath The filepath to read.
 * @return The success of the read, indicated by the value of the enum.
 */
PRISM_EXPORTED_FUNCTION pm_string_init_result_t pm_string_file_init(pm_string_t *string, const char *filepath);

/**
 * Ensure the string is owned. If it is not, then reinitialize it as owned and
 * copy over the previous source.
 *
 * @param string The string to ensure is owned.
 */
void pm_string_ensure_owned(pm_string_t *string);

/**
 * Compare the underlying lengths and bytes of two strings. Returns 0 if the
 * strings are equal, a negative number if the left string is less than the
 * right string, and a positive number if the left string is greater than the
 * right string.
 *
 * @param left The left string to compare.
 * @param right The right string to compare.
 * @return The comparison result.
 */
int pm_string_compare(const pm_string_t *left, const pm_string_t *right);

/**
 * Returns the length associated with the string.
 *
 * @param string The string to get the length of.
 * @return The length of the string.
 */
PRISM_EXPORTED_FUNCTION size_t pm_string_length(const pm_string_t *string);

/**
 * Returns the start pointer associated with the string.
 *
 * @param string The string to get the start pointer of.
 * @return The start pointer of the string.
 */
PRISM_EXPORTED_FUNCTION const uint8_t * pm_string_source(const pm_string_t *string);

/**
 * Free the associated memory of the given string.
 *
 * @param string The string to free.
 */
PRISM_EXPORTED_FUNCTION void pm_string_free(pm_string_t *string);

#endif
