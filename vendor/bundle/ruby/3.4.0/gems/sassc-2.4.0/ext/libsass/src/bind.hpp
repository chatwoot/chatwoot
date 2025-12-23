#ifndef SASS_BIND_H
#define SASS_BIND_H

#include <string>
#include "backtrace.hpp"
#include "environment.hpp"
#include "ast_fwd_decl.hpp"

namespace Sass {

  void bind(sass::string type, sass::string name, Parameters_Obj, Arguments_Obj, Env*, Eval*, Backtraces& traces);

}

#endif
