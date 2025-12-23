#ifndef SASS_SOURCE_DATA_H
#define SASS_SOURCE_DATA_H

#include "sass.hpp"
#include "memory.hpp"

namespace Sass {

  class SourceSpan;

  class SourceData :
    public SharedObj {
  public:
    SourceData();
    virtual size_t size() const = 0;
    virtual size_t getSrcId() const = 0;
    virtual const char* end() const = 0;
    virtual const char* begin() const = 0;
    virtual const char* getPath() const = 0;
    // virtual Offset getPosition() const = 0;
    virtual const char* getRawData() const = 0;
    virtual SourceSpan getSourceSpan() = 0;

    sass::string to_string() const override {
      return sass::string{ begin(), end() };
    }
    ~SourceData() {}
  };

}

#endif
