#include "ast.hpp"
#include "units.hpp"
#include "position.hpp"
#include "backtrace.hpp"
#include "sass/values.h"
#include "ast_fwd_decl.hpp"
#include "error_handling.hpp"

namespace Sass {

  Value* c2ast(union Sass_Value* v, Backtraces traces, SourceSpan pstate)
  {
    using std::strlen;
    using std::strcpy;
    Value* e = NULL;
    switch (sass_value_get_tag(v)) {
      case SASS_BOOLEAN: {
        e = SASS_MEMORY_NEW(Boolean, pstate, !!sass_boolean_get_value(v));
      } break;
      case SASS_NUMBER: {
        e = SASS_MEMORY_NEW(Number, pstate, sass_number_get_value(v), sass_number_get_unit(v));
      } break;
      case SASS_COLOR: {
        e = SASS_MEMORY_NEW(Color_RGBA, pstate, sass_color_get_r(v), sass_color_get_g(v), sass_color_get_b(v), sass_color_get_a(v));
      } break;
      case SASS_STRING: {
        if (sass_string_is_quoted(v))
          e = SASS_MEMORY_NEW(String_Quoted, pstate, sass_string_get_value(v));
        else {
          e = SASS_MEMORY_NEW(String_Constant, pstate, sass_string_get_value(v));
        }
      } break;
      case SASS_LIST: {
        List* l = SASS_MEMORY_NEW(List, pstate, sass_list_get_length(v), sass_list_get_separator(v));
        for (size_t i = 0, L = sass_list_get_length(v); i < L; ++i) {
          l->append(c2ast(sass_list_get_value(v, i), traces, pstate));
        }
        l->is_bracketed(sass_list_get_is_bracketed(v));
        e = l;
      } break;
      case SASS_MAP: {
        Map* m = SASS_MEMORY_NEW(Map, pstate);
        for (size_t i = 0, L = sass_map_get_length(v); i < L; ++i) {
          *m << std::make_pair(
            c2ast(sass_map_get_key(v, i), traces, pstate),
            c2ast(sass_map_get_value(v, i), traces, pstate));
        }
        e = m;
      } break;
      case SASS_NULL: {
        e = SASS_MEMORY_NEW(Null, pstate);
      } break;
      case SASS_ERROR: {
        error("Error in C function: " + sass::string(sass_error_get_message(v)), pstate, traces);
      } break;
      case SASS_WARNING: {
        error("Warning in C function: " + sass::string(sass_warning_get_message(v)), pstate, traces);
      } break;
      default: break;
    }
    return e;
  }

}
