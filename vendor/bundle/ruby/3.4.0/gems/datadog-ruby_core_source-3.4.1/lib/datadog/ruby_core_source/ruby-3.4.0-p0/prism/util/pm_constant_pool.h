/**
 * @file pm_constant_pool.h
 *
 * A data structure that stores a set of strings.
 *
 * Each string is assigned a unique id, which can be used to compare strings for
 * equality. This comparison ends up being much faster than strcmp, since it
 * only requires a single integer comparison.
 */
#ifndef PRISM_CONSTANT_POOL_H
#define PRISM_CONSTANT_POOL_H

#include "prism/defines.h"

#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

/**
 * When we allocate constants into the pool, we reserve 0 to mean that the slot
 * is not yet filled. This constant is reused in other places to indicate the
 * lack of a constant id.
 */
#define PM_CONSTANT_ID_UNSET 0

/**
 * A constant id is a unique identifier for a constant in the constant pool.
 */
typedef uint32_t pm_constant_id_t;

/**
 * A list of constant IDs. Usually used to represent a set of locals.
 */
typedef struct {
    /** The number of constant ids in the list. */
    size_t size;

    /** The number of constant ids that have been allocated in the list. */
    size_t capacity;

    /** The constant ids in the list. */
    pm_constant_id_t *ids;
} pm_constant_id_list_t;

/**
 * Initialize a list of constant ids.
 *
 * @param list The list to initialize.
 */
void pm_constant_id_list_init(pm_constant_id_list_t *list);

/**
 * Initialize a list of constant ids with a given capacity.
 *
 * @param list The list to initialize.
 * @param capacity The initial capacity of the list.
 */
void pm_constant_id_list_init_capacity(pm_constant_id_list_t *list, size_t capacity);

/**
 * Append a constant id to a list of constant ids. Returns false if any
 * potential reallocations fail.
 *
 * @param list The list to append to.
 * @param id The id to append.
 * @return Whether the append succeeded.
 */
bool pm_constant_id_list_append(pm_constant_id_list_t *list, pm_constant_id_t id);

/**
 * Insert a constant id into a list of constant ids at the specified index.
 *
 * @param list The list to insert into.
 * @param index The index at which to insert.
 * @param id The id to insert.
 */
void pm_constant_id_list_insert(pm_constant_id_list_t *list, size_t index, pm_constant_id_t id);

/**
 * Checks if the current constant id list includes the given constant id.
 *
 * @param list The list to check.
 * @param id The id to check for.
 * @return Whether the list includes the given id.
 */
bool pm_constant_id_list_includes(pm_constant_id_list_t *list, pm_constant_id_t id);

/**
 * Free the memory associated with a list of constant ids.
 *
 * @param list The list to free.
 */
void pm_constant_id_list_free(pm_constant_id_list_t *list);

/**
 * The type of bucket in the constant pool hash map. This determines how the
 * bucket should be freed.
 */
typedef unsigned int pm_constant_pool_bucket_type_t;

/** By default, each constant is a slice of the source. */
static const pm_constant_pool_bucket_type_t PM_CONSTANT_POOL_BUCKET_DEFAULT = 0;

/** An owned constant is one for which memory has been allocated. */
static const pm_constant_pool_bucket_type_t PM_CONSTANT_POOL_BUCKET_OWNED = 1;

/** A constant constant is known at compile time. */
static const pm_constant_pool_bucket_type_t PM_CONSTANT_POOL_BUCKET_CONSTANT = 2;

/** A bucket in the hash map. */
typedef struct {
    /** The incremental ID used for indexing back into the pool. */
    unsigned int id: 30;

    /** The type of the bucket, which determines how to free it. */
    pm_constant_pool_bucket_type_t type: 2;

    /** The hash of the bucket. */
    uint32_t hash;
} pm_constant_pool_bucket_t;

/** A constant in the pool which effectively stores a string. */
typedef struct {
    /** A pointer to the start of the string. */
    const uint8_t *start;

    /** The length of the string. */
    size_t length;
} pm_constant_t;

/** The overall constant pool, which stores constants found while parsing. */
typedef struct {
    /** The buckets in the hash map. */
    pm_constant_pool_bucket_t *buckets;

    /** The constants that are stored in the buckets. */
    pm_constant_t *constants;

    /** The number of buckets in the hash map. */
    uint32_t size;

    /** The number of buckets that have been allocated in the hash map. */
    uint32_t capacity;
} pm_constant_pool_t;

/**
 * Initialize a new constant pool with a given capacity.
 *
 * @param pool The pool to initialize.
 * @param capacity The initial capacity of the pool.
 * @return Whether the initialization succeeded.
 */
bool pm_constant_pool_init(pm_constant_pool_t *pool, uint32_t capacity);

/**
 * Return a pointer to the constant indicated by the given constant id.
 *
 * @param pool The pool to get the constant from.
 * @param constant_id The id of the constant to get.
 * @return A pointer to the constant.
 */
pm_constant_t * pm_constant_pool_id_to_constant(const pm_constant_pool_t *pool, pm_constant_id_t constant_id);

/**
 * Find a constant in a constant pool. Returns the id of the constant, or 0 if
 * the constant is not found.
 *
 * @param pool The pool to find the constant in.
 * @param start A pointer to the start of the constant.
 * @param length The length of the constant.
 * @return The id of the constant.
 */
pm_constant_id_t pm_constant_pool_find(const pm_constant_pool_t *pool, const uint8_t *start, size_t length);

/**
 * Insert a constant into a constant pool that is a slice of a source string.
 * Returns the id of the constant, or 0 if any potential calls to resize fail.
 *
 * @param pool The pool to insert the constant into.
 * @param start A pointer to the start of the constant.
 * @param length The length of the constant.
 * @return The id of the constant.
 */
pm_constant_id_t pm_constant_pool_insert_shared(pm_constant_pool_t *pool, const uint8_t *start, size_t length);

/**
 * Insert a constant into a constant pool from memory that is now owned by the
 * constant pool. Returns the id of the constant, or 0 if any potential calls to
 * resize fail.
 *
 * @param pool The pool to insert the constant into.
 * @param start A pointer to the start of the constant.
 * @param length The length of the constant.
 * @return The id of the constant.
 */
pm_constant_id_t pm_constant_pool_insert_owned(pm_constant_pool_t *pool, uint8_t *start, size_t length);

/**
 * Insert a constant into a constant pool from memory that is constant. Returns
 * the id of the constant, or 0 if any potential calls to resize fail.
 *
 * @param pool The pool to insert the constant into.
 * @param start A pointer to the start of the constant.
 * @param length The length of the constant.
 * @return The id of the constant.
 */
pm_constant_id_t pm_constant_pool_insert_constant(pm_constant_pool_t *pool, const uint8_t *start, size_t length);

/**
 * Free the memory associated with a constant pool.
 *
 * @param pool The pool to free.
 */
void pm_constant_pool_free(pm_constant_pool_t *pool);

#endif
