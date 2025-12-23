/**
 * @file node.h
 *
 * Functions related to nodes in the AST.
 */
#ifndef PRISM_NODE_H
#define PRISM_NODE_H

#include "prism/defines.h"
#include "prism/parser.h"

/**
 * Append a new node onto the end of the node list.
 *
 * @param list The list to append to.
 * @param node The node to append.
 */
void pm_node_list_append(pm_node_list_t *list, pm_node_t *node);

/**
 * Deallocate a node and all of its children.
 *
 * @param parser The parser that owns the node.
 * @param node The node to deallocate.
 */
PRISM_EXPORTED_FUNCTION void pm_node_destroy(pm_parser_t *parser, struct pm_node *node);

/**
 * This struct stores the information gathered by the pm_node_memsize function.
 * It contains both the memory footprint and additionally metadata about the
 * shape of the tree.
 */
typedef struct {
    /** The total memory footprint of the node and all of its children. */
    size_t memsize;

    /** The number of children the node has. */
    size_t node_count;
} pm_memsize_t;

/**
 * Calculates the memory footprint of a given node.
 *
 * @param node The node to calculate the memory footprint of.
 * @param memsize The memory footprint of the node and all of its children.
 */
PRISM_EXPORTED_FUNCTION void pm_node_memsize(pm_node_t *node, pm_memsize_t *memsize);

/**
 * Returns a string representation of the given node type.
 *
 * @param node_type The node type to convert to a string.
 * @return A string representation of the given node type.
 */
PRISM_EXPORTED_FUNCTION const char * pm_node_type_to_str(pm_node_type_t node_type);

#endif
