#include <stdio.h>
#include <string.h>
#include "source.hpp"
#include "utf8/checked.h"
#include "position.hpp"

namespace Sass {

  SourceData::SourceData()
    : SharedObj()
  {
  }

  SourceFile::SourceFile(
    const char* path,
    const char* data,
    size_t srcid) :
    SourceData(),
    path(sass_copy_c_string(path)),
    data(sass_copy_c_string(data)),
    length(0),
    srcid(srcid)
  {
    length = strlen(data);
  }

  SourceFile::~SourceFile() {
    sass_free_memory(path);
    sass_free_memory(data);
  }

  const char* SourceFile::end() const
  {
    return data + length;
  }

  const char* SourceFile::begin() const
  {
    return data;
  }

  const char* SourceFile::getRawData() const
  {
    return data;
  }

  SourceSpan SourceFile::getSourceSpan()
  {
    return SourceSpan(this);
  }

  ItplFile::ItplFile(const char* data, const SourceSpan& pstate) :
    SourceFile(pstate.getPath(),
      data, pstate.getSrcId()),
    pstate(pstate)
  {}

  const char* ItplFile::getRawData() const
  {
    return pstate.getRawData();
  }

  SourceSpan ItplFile::getSourceSpan()
  {
    return SourceSpan(pstate);
  }

}

