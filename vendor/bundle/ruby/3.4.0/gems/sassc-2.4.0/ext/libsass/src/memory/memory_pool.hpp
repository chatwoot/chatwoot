#ifndef SASS_MEMORY_POOL_H
#define SASS_MEMORY_POOL_H

#include <stdlib.h>
#include <iostream>
#include <algorithm>
#include <climits>
#include <vector>

namespace Sass {

  // SIMPLE MEMORY-POOL ALLOCATOR WITH FREE-LIST ON TOP

  // This is a memory pool allocator with a free list on top.
  // We only allocate memory arenas from the system in specific
  // sizes (`SassAllocatorArenaSize`). Users claim memory slices
  // of certain sizes from the pool. If the allocation is too big
  // to fit into our buckets, we use regular malloc/free instead.

  // When the systems starts, we allocate the first arena and then
  // start to give out addresses to memory slices. During that
  // we steadily increase `offset` until the current arena is full.
  // Once that happens we allocate a new arena and continue.
  // https://en.wikipedia.org/wiki/Memory_pool

  // Fragments that get deallocated are not really freed, we put
  // them on our free-list. For every bucket we have a pointer to
  // the first item for reuse. That item itself holds a pointer to
  // the previously free item (regular free-list implementation).
  // https://en.wikipedia.org/wiki/Free_list

  // On allocation calls we first check if there is any suitable
  // item on the free-list. If there is we pop it from the stack
  // and return it to the caller. Otherwise we have to take out
  // a new slice from the current `arena` and increase `offset`.

  // Note that this is not thread safe. This is on purpose as we
  // want to use the memory pool in a thread local usage. In order
  // to get this thread safe you need to only allocate one pool
  // per thread. This can be achieved by using thread local PODs.
  // Simply create a pool on the first allocation and dispose
  // it once all allocations have been returned. E.g. by using:
  // static thread_local size_t allocations;
  // static thread_local MemoryPool* pool;

  class MemoryPool {

    // Current arena we fill up
    char* arena;

    // Position into the arena
    size_t offset = std::string::npos;

    // A list of full arenas
    std::vector<void*> arenas;

    // One pointer for every bucket (zero init)
    #ifdef _MSC_VER
    #pragma warning (suppress:4351)
    #endif
    void* freeList[SassAllocatorBuckets]{};

    // Increase the address until it sits on a
    // memory aligned address (maybe use `aligned`).
    inline static size_t alignMemAddr(size_t addr) {
      return (addr + SASS_MEM_ALIGN - 1) & ~(SASS_MEM_ALIGN - 1);
    }

  public:

    // Default ctor
    MemoryPool() :
      // Wait for first allocation
      arena(nullptr),
      // Set to maximum value in order to
      // make an allocation on the first run
      offset(std::string::npos)
    {
    }

    // Destructor
    ~MemoryPool() {
      // Delete full arenas
      for (auto area : arenas) {
        free(area);
      }
      // Delete current arena
      free(arena);

    }

    // Allocate a slice of the memory pool
    void* allocate(size_t size)
    {

      // Increase size so its memory is aligned
      size = alignMemAddr(
        // Make sure we have enough space for us to
        // create the pointer to the free list later
        std::max(sizeof(void*), size)
        // and the size needed for our book-keeping
        + SassAllocatorBookSize);

      // Size must be multiple of alignment
      // So we can derive bucket index from it
      size_t bucket = size / SASS_MEM_ALIGN;

      // Everything bigger is allocated via malloc
      // Malloc is optimized for exactly this case
      if (bucket >= SassAllocatorBuckets) {
        char* buffer = (char*)malloc(size);
        if (buffer == nullptr) {
          throw std::bad_alloc();
        }
        // Mark it for deallocation via free
        ((unsigned int*)buffer)[0] = UINT_MAX;
        // Return pointer after our book-keeping space
        return (void*)(buffer + SassAllocatorBookSize);
      }
      // Use custom allocator
      else {
        // Get item from free list
        void*& free = freeList[bucket];
        // Do we have a free item?
        if (free != nullptr) {
          // Copy pointer to return
          void* ptr = free;
          // Update free list pointer
          free = ((void**)ptr)[0];
          // Return popped item
          return ptr;
        }
      }

      // Make sure we have enough space in the arena
      if (!arena || offset > SassAllocatorArenaSize - size) {
        if (arena) arenas.emplace_back(arena);
        arena = (char*)malloc(SassAllocatorArenaSize);
        if (arena == nullptr) throw std::bad_alloc();
        offset = SassAllocatorArenaHeadSize;
      }

      // Get pointer into the arena
      char* buffer = arena + offset;
      // Consume object size
      offset += size;

      // Set the bucket index for this slice
      ((unsigned int*)buffer)[0] = (unsigned int)bucket;

      // Return pointer after our book-keeping space
      return (void*)(buffer + SassAllocatorBookSize);

    }
    // EO allocate

    void deallocate(void* ptr)
    {

      // Rewind buffer from pointer
      char* buffer = (char*)ptr -
        SassAllocatorBookSize;

      // Get the bucket index stored in the header
      unsigned int bucket = ((unsigned int*)buffer)[0];

      // Check allocation method
      if (bucket != UINT_MAX) {
        // Let memory point to previous item in free list
        ((void**)ptr)[0] = freeList[bucket];
        // Free list now points to our memory
        freeList[bucket] = (void*)ptr;
      }
      else {
        // Release memory
        free(buffer);
      }

    }
    // EO deallocate

  };

}

#endif
