#ifndef SASS_SETTINGS_H
#define SASS_SETTINGS_H

// Global compile time settings should go here

// When enabled we use our custom memory pool allocator
// With intense workloads this can double the performance
// Max memory usage mostly only grows by a slight amount
// #define SASS_CUSTOM_ALLOCATOR

// How many buckets should we have for the free-list
// Determines when allocations go directly to malloc/free
// For maximum size of managed items multiply by alignment
#define SassAllocatorBuckets 512

// The size of the memory pool arenas in bytes.
#define SassAllocatorArenaSize (1024 * 256)

#endif
