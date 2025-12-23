// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include "ast2c.hpp"
#include "ast.hpp"

namespace Sass {

  union Sass_Value* AST2C::operator()(Boolean* b)
  { return sass_make_boolean(b->value()); }

  union Sass_Value* AST2C::operator()(Number* n)
  { return sass_make_number(n->value(), n->unit().c_str()); }

  union Sass_Value* AST2C::operator()(Custom_Warning* w)
  { return sass_make_warning(w->message().c_str()); }

  union Sass_Value* AST2C::operator()(Custom_Error* e)
  { return sass_make_error(e->message().c_str()); }

  union Sass_Value* AST2C::operator()(Color_RGBA* c)
  { return sass_make_color(c->r(), c->g(), c->b(), c->a()); }

  union Sass_Value* AST2C::operator()(Color_HSLA* c)
  {
    Color_RGBA_Obj rgba = c->copyAsRGBA();
    return operator()(rgba.ptr());
  }

  union Sass_Value* AST2C::operator()(String_Constant* s)
  {
    if (s->quote_mark()) {
      return sass_make_qstring(s->value().c_str());
    } else {
      return sass_make_string(s->value().c_str());
    }
  }

  union Sass_Value* AST2C::operator()(String_Quoted* s)
  { return sass_make_qstring(s->value().c_str()); }

  union Sass_Value* AST2C::operator()(List* l)
  {
    union Sass_Value* v = sass_make_list(l->length(), l->separator(), l->is_bracketed());
    for (size_t i = 0, L = l->length(); i < L; ++i) {
      sass_list_set_value(v, i, (*l)[i]->perform(this));
    }
    return v;
  }

  union Sass_Value* AST2C::operator()(Map* m)
  {
    union Sass_Value* v = sass_make_map(m->length());
    int i = 0;
    for (auto key : m->keys()) {
      sass_map_set_key(v, i, key->perform(this));
      sass_map_set_value(v, i, m->at(key)->perform(this));
      i++;
    }
    return v;
  }

  union Sass_Value* AST2C::operator()(Arguments* a)
  {
    union Sass_Value* v = sass_make_list(a->length(), SASS_COMMA, false);
    for (size_t i = 0, L = a->length(); i < L; ++i) {
      sass_list_set_value(v, i, (*a)[i]->perform(this));
    }
    return v;
  }

  union Sass_Value* AST2C::operator()(Argument* a)
  { return a->value()->perform(this); }

  // not strictly necessary because of the fallback
  union Sass_Value* AST2C::operator()(Null* n)
  { return sass_make_null(); }

};
