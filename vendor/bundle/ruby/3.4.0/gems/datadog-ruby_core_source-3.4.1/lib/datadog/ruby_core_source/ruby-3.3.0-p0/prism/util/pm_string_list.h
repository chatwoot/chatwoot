/**
 * @file pm_string_list.h
 *
 * A list of strings.
 */
#ifndef PRISM_STRING_LIST_H
#define PRISM_STRING_LIST_H

#include "prism/defines.h"
#include "prism/util/pm_string.h"

#include <stddef.h>
#include <stdlib.h>

/**
 * A list of strings.
 */
typedef struct {
    /** The length of the string list. */
    size_t length;

    /** The capacity of the string list that has been allocated. */
    size_t capacity;

    /** A pointer to the start of the string list. */
    pm_string_t *strings;
} pm_string_list_t;

/**
 * Append a pm_string_t to the given string list.
 *
 * @param string_list The string list to append to.
 * @param string The string to append.
 */
void pm_string_list_append(pm_string_list_t *string_list, pm_string_t *string);

/**
 * Free the memory associated with the string list.
 *
 * @param string_list The string list to free.
 */
PRISM_EXPORTED_FUNCTION void pm_string_list_free(pm_string_list_t *string_list);

#endif
