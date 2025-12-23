#ifndef SASS_SOURCE_H
#define SASS_SOURCE_H

#include "sass.hpp"
#include "memory.hpp"
#include "position.hpp"
#include "source_data.hpp"

namespace Sass {

  class SourceFile :
    public SourceData {
  protected:
    char* path;
    char* data;
    size_t length;
    size_t srcid;
  public:

    SourceFile(
      const char* path,
      const char* data,
      size_t srcid);

    ~SourceFile();

    const char* end() const override final;
    const char* begin() const override final;
    virtual const char* getRawData() const override;
    virtual SourceSpan getSourceSpan() override;

    size_t size() const override final {
      return length;
    }

    virtual const char* getPath() const override {
      return path;
    }

    virtual size_t getSrcId() const override {
      return srcid;
    }

  };

  class SynthFile :
    public SourceData {
  protected:
    const char* path;
  public:

    SynthFile(
      const char* path) :
      path(path)
    {}

    ~SynthFile() {}

    const char* end() const override final { return nullptr; }
    const char* begin() const override final { return nullptr; };
    virtual const char* getRawData() const override { return nullptr; };
    virtual SourceSpan getSourceSpan() override { return SourceSpan(path); };

    size_t size() const override final {
      return 0;
    }

    virtual const char* getPath() const override {
      return path;
    }

    virtual size_t getSrcId() const override {
      return std::string::npos;
    }

  };
  

  class ItplFile :
    public SourceFile {
  private:
    SourceSpan pstate;
  public:

    ItplFile(const char* data,
      const SourceSpan& pstate);

    // Offset getPosition() const override final;
    const char* getRawData() const override final;
    SourceSpan getSourceSpan() override final;
  };

}

#endif
