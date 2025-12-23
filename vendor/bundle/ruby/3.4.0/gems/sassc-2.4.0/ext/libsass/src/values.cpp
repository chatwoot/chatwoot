// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include "sass.h"
#include "values.hpp"

#include <stdint.h>

namespace Sass {

  // convert value from C++ side to C-API
  union Sass_Value* ast_node_to_sass_value (const Expression* val)
  {
    if (val->concrete_type() == Expression::NUMBER)
    {
      const Number* res = Cast<Number>(val);
      return sass_make_number(res->value(), res->unit().c_str());
    }
    else if (val->concrete_type() == Expression::COLOR)
    {
      if (const Color_RGBA* rgba = Cast<Color_RGBA>(val)) {
        return sass_make_color(rgba->r(), rgba->g(), rgba->b(), rgba->a());
      } else {
        // ToDo: allow to also use HSLA colors!!
        Color_RGBA_Obj col = Cast<Color>(val)->copyAsRGBA();
        return sass_make_color(col->r(), col->g(), col->b(), col->a());
      }
    }
    else if (val->concrete_type() == Expression::LIST)
    {
      const List* l = Cast<List>(val);
      union Sass_Value* list = sass_make_list(l->size(), l->separator(), l->is_bracketed());
      for (size_t i = 0, L = l->length(); i < L; ++i) {
        ExpressionObj obj = l->at(i);
        auto val = ast_node_to_sass_value(obj);
        sass_list_set_value(list, i, val);
      }
      return list;
    }
    else if (val->concrete_type() == Expression::MAP)
    {
      const Map* m = Cast<Map>(val);
      union Sass_Value* map = sass_make_map(m->length());
      size_t i = 0; for (ExpressionObj key : m->keys()) {
        sass_map_set_key(map, i, ast_node_to_sass_value(key));
        sass_map_set_value(map, i, ast_node_to_sass_value(m->at(key)));
        ++ i;
      }
      return map;
    }
    else if (val->concrete_type() == Expression::NULL_VAL)
    {
      return sass_make_null();
    }
    else if (val->concrete_type() == Expression::BOOLEAN)
    {
      const Boolean* res = Cast<Boolean>(val);
      return sass_make_boolean(res->value());
    }
    else if (val->concrete_type() == Expression::STRING)
    {
      if (const String_Quoted* qstr = Cast<String_Quoted>(val))
      {
        return sass_make_qstring(qstr->value().c_str());
      }
      else if (const String_Constant* cstr = Cast<String_Constant>(val))
      {
        return sass_make_string(cstr->value().c_str());
      }
    }
    return sass_make_error("unknown sass value type");
  }

  // convert value from C-API to C++ side
  Value* sass_value_to_ast_node (const union Sass_Value* val)
  {
    switch (sass_value_get_tag(val)) {
      case SASS_NUMBER:
        return SASS_MEMORY_NEW(Number,
                               SourceSpan("[C-VALUE]"),
                               sass_number_get_value(val),
                               sass_number_get_unit(val));
      case SASS_BOOLEAN:
        return SASS_MEMORY_NEW(Boolean,
                               SourceSpan("[C-VALUE]"),
                               sass_boolean_get_value(val));
      case SASS_COLOR:
        // ToDo: allow to also use HSLA colors!!
        return SASS_MEMORY_NEW(Color_RGBA,
                               SourceSpan("[C-VALUE]"),
                               sass_color_get_r(val),
                               sass_color_get_g(val),
                               sass_color_get_b(val),
                               sass_color_get_a(val));
      case SASS_STRING:
        if (sass_string_is_quoted(val)) {
          return SASS_MEMORY_NEW(String_Quoted,
                                 SourceSpan("[C-VALUE]"),
                                 sass_string_get_value(val));
        }
        return SASS_MEMORY_NEW(String_Constant,
                                 SourceSpan("[C-VALUE]"),
                                 sass_string_get_value(val));
      case SASS_LIST: {
        List* l = SASS_MEMORY_NEW(List,
                                  SourceSpan("[C-VALUE]"),
                                  sass_list_get_length(val),
                                  sass_list_get_separator(val));
        for (size_t i = 0, L = sass_list_get_length(val); i < L; ++i) {
          l->append(sass_value_to_ast_node(sass_list_get_value(val, i)));
        }
        l->is_bracketed(sass_list_get_is_bracketed(val));
        return l;
      }
      case SASS_MAP: {
        Map* m = SASS_MEMORY_NEW(Map, SourceSpan("[C-VALUE]"));
        for (size_t i = 0, L = sass_map_get_length(val); i < L; ++i) {
          *m << std::make_pair(
            sass_value_to_ast_node(sass_map_get_key(val, i)),
            sass_value_to_ast_node(sass_map_get_value(val, i)));
        }
        return m;
      }
      case SASS_NULL:
        return SASS_MEMORY_NEW(Null, SourceSpan("[C-VALUE]"));
      case SASS_ERROR:
        return SASS_MEMORY_NEW(Custom_Error,
                               SourceSpan("[C-VALUE]"),
                               sass_error_get_message(val));
      case SASS_WARNING:
        return SASS_MEMORY_NEW(Custom_Warning,
                               SourceSpan("[C-VALUE]"),
                               sass_warning_get_message(val));
      default: break;
    }
    return 0;
  }

}
