#include "prism/util/pm_list.h"

/**
 * Returns true if the given list is empty.
 */
PRISM_EXPORTED_FUNCTION bool
pm_list_empty_p(pm_list_t *list) {
    return list->head == NULL;
}

/**
 * Returns the size of the list.
 */
PRISM_EXPORTED_FUNCTION size_t
pm_list_size(pm_list_t *list) {
    return list->size;
}

/**
 * Append a node to the given list.
 */
void
pm_list_append(pm_list_t *list, pm_list_node_t *node) {
    if (list->head == NULL) {
        list->head = node;
    } else {
        list->tail->next = node;
    }

    list->tail = node;
    list->size++;
}

/**
 * Deallocate the internal state of the given list.
 */
PRISM_EXPORTED_FUNCTION void
pm_list_free(pm_list_t *list) {
    pm_list_node_t *node = list->head;
    pm_list_node_t *next;

    while (node != NULL) {
        next = node->next;
        xfree(node);
        node = next;
    }

    list->size = 0;
}
