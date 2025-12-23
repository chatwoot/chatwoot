#ifndef SASS_FN_UTILS_H
#define SASS_FN_UTILS_H

// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include "units.hpp"
#include "backtrace.hpp"
#include "environment.hpp"
#include "ast_fwd_decl.hpp"
#include "error_handling.hpp"

namespace Sass {

  #define FN_PROTOTYPE \
    Env& env, \
    Env& d_env, \
    Context& ctx, \
    Signature sig, \
    SourceSpan pstate, \
    Backtraces& traces, \
    SelectorStack selector_stack, \
    SelectorStack original_stack \

  typedef const char* Signature;
  typedef PreValue* (*Native_Function)(FN_PROTOTYPE);
  #define BUILT_IN(name) PreValue* name(FN_PROTOTYPE)

  #define ARG(argname, argtype) get_arg<argtype>(argname, env, sig, pstate, traces)
  // special function for weird hsla percent (10px == 10% == 10 != 0.1)
  #define ARGVAL(argname) get_arg_val(argname, env, sig, pstate, traces) // double

  Definition* make_native_function(Signature, Native_Function, Context& ctx);
  Definition* make_c_function(Sass_Function_Entry c_func, Context& ctx);

  namespace Functions {

    template <typename T>
    T* get_arg(const sass::string& argname, Env& env, Signature sig, SourceSpan pstate, Backtraces traces)
    {
      T* val = Cast<T>(env[argname]);
      if (!val) {
        error("argument `" + argname + "` of `" + sig + "` must be a " + T::type_name(), pstate, traces);
      }
      return val;
    }

    Map* get_arg_m(const sass::string& argname, Env& env, Signature sig, SourceSpan pstate, Backtraces traces); // maps only
    Number* get_arg_n(const sass::string& argname, Env& env, Signature sig, SourceSpan pstate, Backtraces traces); // numbers only
    double alpha_num(const sass::string& argname, Env& env, Signature sig, SourceSpan pstate, Backtraces traces); // colors only
    double color_num(const sass::string& argname, Env& env, Signature sig, SourceSpan pstate, Backtraces traces); // colors only
    double get_arg_r(const sass::string& argname, Env& env, Signature sig, SourceSpan pstate, Backtraces traces, double lo, double hi); // colors only
    double get_arg_val(const sass::string& argname, Env& env, Signature sig, SourceSpan pstate, Backtraces traces); // shared
    SelectorListObj get_arg_sels(const sass::string& argname, Env& env, Signature sig, SourceSpan pstate, Backtraces traces, Context& ctx); // selectors only
    CompoundSelectorObj get_arg_sel(const sass::string& argname, Env& env, Signature sig, SourceSpan pstate, Backtraces traces, Context& ctx); // selectors only

  }

}

#endif
