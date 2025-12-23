// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include "ast.hpp"
#include "to_value.hpp"

namespace Sass {

  // Custom_Error is a valid value
  Value* To_Value::operator()(Custom_Error* e)
  {
    return e;
  }

  // Custom_Warning is a valid value
  Value* To_Value::operator()(Custom_Warning* w)
  {
    return w;
  }

  // Boolean is a valid value
  Value* To_Value::operator()(Boolean* b)
  {
    return b;
  }

  // Number is a valid value
  Value* To_Value::operator()(Number* n)
  {
    return n;
  }

  // Color is a valid value
  Value* To_Value::operator()(Color_RGBA* c)
  {
    return c;
  }

  // Color is a valid value
  Value* To_Value::operator()(Color_HSLA* c)
  {
    return c;
  }

  // String_Constant is a valid value
  Value* To_Value::operator()(String_Constant* s)
  {
    return s;
  }

  // String_Quoted is a valid value
  Value* To_Value::operator()(String_Quoted* s)
  {
    return s;
  }

  // List is a valid value
  Value* To_Value::operator()(List* l)
  {
    List_Obj ll = SASS_MEMORY_NEW(List,
                               l->pstate(),
                               l->length(),
                               l->separator(),
                               l->is_arglist(),
                               l->is_bracketed());
    for (size_t i = 0, L = l->length(); i < L; ++i) {
      ll->append((*l)[i]->perform(this));
    }
    return ll.detach();
  }

  // Map is a valid value
  Value* To_Value::operator()(Map* m)
  {
    return m;
  }

  // Null is a valid value
  Value* To_Value::operator()(Null* n)
  {
    return n;
  }

  // Function is a valid value
  Value* To_Value::operator()(Function* n)
  {
    return n;
  }

  // Argument returns its value
  Value* To_Value::operator()(Argument* arg)
  {
    if (!arg->name().empty()) return 0;
    return arg->value()->perform(this);
  }

  // SelectorList is converted to a string
  Value* To_Value::operator()(SelectorList* s)
  {
    return SASS_MEMORY_NEW(String_Quoted,
                           s->pstate(),
                           s->to_string(ctx.c_options));
  }

  // Binary_Expression is converted to a string
  Value* To_Value::operator()(Binary_Expression* s)
  {
    return SASS_MEMORY_NEW(String_Quoted,
                           s->pstate(),
                           s->to_string(ctx.c_options));
  }

};
