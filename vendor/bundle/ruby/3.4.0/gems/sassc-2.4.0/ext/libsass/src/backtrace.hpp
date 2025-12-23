#ifndef SASS_BACKTRACE_H
#define SASS_BACKTRACE_H

#include <vector>
#include <sstream>
#include "file.hpp"
#include "position.hpp"

namespace Sass {

  struct Backtrace {

    SourceSpan pstate;
    sass::string caller;

    Backtrace(SourceSpan pstate, sass::string c = "")
    : pstate(pstate),
      caller(c)
    { }

  };

  typedef sass::vector<Backtrace> Backtraces;

  const sass::string traces_to_string(Backtraces traces, sass::string indent = "\t");

}

#endif
