/**
 * @file static_literals.h
 *
 * A set of static literal nodes that can be checked for duplicates.
 */
#ifndef PRISM_STATIC_LITERALS_H
#define PRISM_STATIC_LITERALS_H

#include "prism/defines.h"
#include "prism/ast.h"
#include "prism/util/pm_newline_list.h"

#include <assert.h>
#include <stdbool.h>

/**
 * An internal hash table for a set of nodes.
 */
typedef struct {
    /** The array of nodes in the hash table. */
    pm_node_t **nodes;

    /** The size of the hash table. */
    uint32_t size;

    /** The space that has been allocated in the hash table. */
    uint32_t capacity;
} pm_node_hash_t;

/**
 * Certain sets of nodes (hash keys and when clauses) check for duplicate nodes
 * to alert the user of potential issues. To do this, we keep a set of the nodes
 * that have been seen so far, and compare whenever we find a new node.
 *
 * We bucket the nodes based on their type to minimize the number of comparisons
 * that need to be performed.
 */
typedef struct {
    /**
     * This is the set of IntegerNode and SourceLineNode instances.
     */
    pm_node_hash_t integer_nodes;

    /**
     * This is the set of FloatNode instances.
     */
    pm_node_hash_t float_nodes;

    /**
     * This is the set of RationalNode and ImaginaryNode instances.
     */
    pm_node_hash_t number_nodes;

    /**
     * This is the set of StringNode and SourceFileNode instances.
     */
    pm_node_hash_t string_nodes;

    /**
     * This is the set of RegularExpressionNode instances.
     */
    pm_node_hash_t regexp_nodes;

    /**
     * This is the set of SymbolNode instances.
     */
    pm_node_hash_t symbol_nodes;

    /**
     * A pointer to the last TrueNode instance that was inserted, or NULL.
     */
    pm_node_t *true_node;

    /**
     * A pointer to the last FalseNode instance that was inserted, or NULL.
     */
    pm_node_t *false_node;

    /**
     * A pointer to the last NilNode instance that was inserted, or NULL.
     */
    pm_node_t *nil_node;

    /**
     * A pointer to the last SourceEncodingNode instance that was inserted, or
     * NULL.
     */
    pm_node_t *source_encoding_node;
} pm_static_literals_t;

/**
 * Add a node to the set of static literals.
 *
 * @param newline_list The list of newline offsets to use to calculate lines.
 * @param start_line The line number that the parser starts on.
 * @param literals The set of static literals to add the node to.
 * @param node The node to add to the set.
 * @param replace Whether to replace the previous node if one already exists.
 * @return A pointer to the node that is being overwritten, if there is one.
 */
pm_node_t * pm_static_literals_add(const pm_newline_list_t *newline_list, int32_t start_line, pm_static_literals_t *literals, pm_node_t *node, bool replace);

/**
 * Free the internal memory associated with the given static literals set.
 *
 * @param literals The set of static literals to free.
 */
void pm_static_literals_free(pm_static_literals_t *literals);

/**
 * Create a string-based representation of the given static literal.
 *
 * @param buffer The buffer to write the string to.
 * @param newline_list The list of newline offsets to use to calculate lines.
 * @param start_line The line number that the parser starts on.
 * @param encoding_name The name of the encoding of the source being parsed.
 * @param node The node to create a string representation of.
 */
void pm_static_literal_inspect(pm_buffer_t *buffer, const pm_newline_list_t *newline_list, int32_t start_line, const char *encoding_name, const pm_node_t *node);

#endif
