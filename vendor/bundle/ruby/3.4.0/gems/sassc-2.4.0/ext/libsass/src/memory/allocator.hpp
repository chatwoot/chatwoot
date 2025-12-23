#ifndef SASS_ALLOCATOR_H
#define SASS_ALLOCATOR_H

#include "config.hpp"
#include "../settings.hpp"
#include "../MurmurHash2.hpp"

#include <vector>
#include <limits>
#include <iostream>
#include <algorithm>
#include <functional>

namespace Sass {

#ifndef SASS_CUSTOM_ALLOCATOR

  template <typename T> using Allocator = std::allocator<T>;

#else

  void* allocateMem(size_t size);

  void deallocateMem(void* ptr, size_t size = 1);

  template<typename T>
  class Allocator
  {
  public:

    // Allocator traits
    typedef T                 type;            
    typedef type              value_type;      
    typedef value_type*       pointer;         
    typedef value_type const* const_pointer;   
    typedef value_type&       reference;       
    typedef value_type const& const_reference; 
    typedef std::size_t       size_type;       
    typedef std::ptrdiff_t    difference_type; 

    template<typename U>
    struct rebind
    {
      typedef Allocator<U> other;
    };

    // Constructor
    Allocator(void) {}

    // Copy Constructor
    template<typename U>
    Allocator(Allocator<U> const&)
    {}

    // allocate but don't initialize count of elements of type T
    pointer allocate(size_type count, const_pointer /* hint */ = 0)
    {
      return (pointer)(Sass::allocateMem(count * sizeof(T)));
    }

    // deallocate storage ptr of deleted elements
    void deallocate(pointer ptr, size_type count)
    {
      Sass::deallocateMem(ptr, count);
    }

    // return maximum number of elements that can be allocated
    size_type max_size() const throw()
    {
      return std::numeric_limits<size_type>::max() / sizeof(T);
    }

    // Address of object
    type* address(type& obj) const { return &obj; }
    type const* address(type const& obj) const { return &obj; }

    // Construct object
    void construct(type* ptr, type const& ref) const
    {
      // In-place copy construct
      new(ptr) type(ref);
    }

    // Destroy object
    void destroy(type* ptr) const
    {
      // Call destructor
      ptr->~type();
    }

  };

  template<typename T, typename U>
    bool operator==(Allocator<T> const& left,
      Allocator<U> const& right)
  {
    return true;
  }

  template<typename T, typename U>
    bool operator!=(Allocator<T> const& left,
      Allocator<U> const& right)
  {
    return !(left == right);
  }

#endif

  namespace sass {
    template <typename T> using vector = std::vector<T, Sass::Allocator<T>>;
    using string = std::basic_string<char, std::char_traits<char>, Sass::Allocator<char>>;
    using sstream = std::basic_stringstream<char, std::char_traits<char>, Sass::Allocator<char>>;
    using ostream = std::basic_ostringstream<char, std::char_traits<char>, Sass::Allocator<char>>;
    using istream = std::basic_istringstream<char, std::char_traits<char>, Sass::Allocator<char>>;
  }

}

#ifdef SASS_CUSTOM_ALLOCATOR

namespace std {
  // Only GCC seems to need this specialization!?
  template <> struct hash<Sass::sass::string> {
  public:
    inline size_t operator()(
      const Sass::sass::string& name) const
    {
      return MurmurHash2(
        (void*)name.c_str(),
        (int)name.size(),
        0x73617373);
    }
  };
}

#endif

#endif
