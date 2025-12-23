#ifndef SASS_MEMORY_CONFIG_H
#define SASS_MEMORY_CONFIG_H

// Define memory alignment requirements
#define SASS_MEM_ALIGN sizeof(unsigned int)

// Minimal alignment for memory fragments. Must be a multiple
// of `SASS_MEM_ALIGN` and should not be too big (maybe 1 or 2)
#define SassAllocatorHeadSize sizeof(unsigned int)

// The number of bytes we use for our book-keeping before every
// memory fragment. Needed to know to which bucket we belongs on
// deallocations, or if it should go directly to the `free` call.
#define SassAllocatorBookSize sizeof(unsigned int)

// Bytes reserve for book-keeping on the arenas
// Currently unused and for later optimization
#define SassAllocatorArenaHeadSize 0

#endif