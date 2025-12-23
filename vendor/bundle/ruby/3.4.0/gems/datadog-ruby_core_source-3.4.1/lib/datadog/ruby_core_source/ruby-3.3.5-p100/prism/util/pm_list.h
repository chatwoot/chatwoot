/**
 * @file pm_list.h
 *
 * An abstract linked list.
 */
#ifndef PRISM_LIST_H
#define PRISM_LIST_H

#include "prism/defines.h"

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

/**
 * This struct represents an abstract linked list that provides common
 * functionality. It is meant to be used any time a linked list is necessary to
 * store data.
 *
 * The linked list itself operates off a set of pointers. Because the pointers
 * are not necessarily sequential, they can be of any size. We use this fact to
 * allow the consumer of this linked list to extend the node struct to include
 * any data they want. This is done by using the pm_list_node_t as the first
 * member of the struct.
 *
 * For example, if we want to store a list of integers, we can do the following:
 *
 * ```c
 * typedef struct {
 *     pm_list_node_t node;
 *     int value;
 * } pm_int_node_t;
 *
 * pm_list_t list = { 0 };
 * pm_int_node_t *node = malloc(sizeof(pm_int_node_t));
 * node->value = 5;
 *
 * pm_list_append(&list, &node->node);
 * ```
 *
 * The pm_list_t struct is used to represent the overall linked list. It
 * contains a pointer to the head and tail of the list. This allows for easy
 * iteration and appending of new nodes.
 */
typedef struct pm_list_node {
    /** A pointer to the next node in the list. */
    struct pm_list_node *next;
} pm_list_node_t;

/**
 * This represents the overall linked list. It keeps a pointer to the head and
 * tail so that iteration is easy and pushing new nodes is easy.
 */
typedef struct {
    /** The size of the list. */
    size_t size;

    /** A pointer to the head of the list. */
    pm_list_node_t *head;

    /** A pointer to the tail of the list. */
    pm_list_node_t *tail;
} pm_list_t;

/**
 * Returns true if the given list is empty.
 *
 * @param list The list to check.
 * @return True if the given list is empty, otherwise false.
 */
PRISM_EXPORTED_FUNCTION bool pm_list_empty_p(pm_list_t *list);

/**
 * Returns the size of the list.
 *
 * @param list The list to check.
 * @return The size of the list.
 */
PRISM_EXPORTED_FUNCTION size_t pm_list_size(pm_list_t *list);

/**
 * Append a node to the given list.
 *
 * @param list The list to append to.
 * @param node The node to append.
 */
void pm_list_append(pm_list_t *list, pm_list_node_t *node);

/**
 * Deallocate the internal state of the given list.
 *
 * @param list The list to free.
 */
PRISM_EXPORTED_FUNCTION void pm_list_free(pm_list_t *list);

#endif
