// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include <iostream>
#include <typeinfo>
#include <string>

#include "listize.hpp"
#include "context.hpp"
#include "backtrace.hpp"
#include "error_handling.hpp"

namespace Sass {

  Listize::Listize()
  {  }

  Expression* Listize::perform(AST_Node* node)
  {
    Listize listize;
    return node->perform(&listize);
  }

  Expression* Listize::operator()(SelectorList* sel)
  {
    List_Obj l = SASS_MEMORY_NEW(List, sel->pstate(), sel->length(), SASS_COMMA);
    l->from_selector(true);
    for (size_t i = 0, L = sel->length(); i < L; ++i) {
      if (!sel->at(i)) continue;
      l->append(sel->at(i)->perform(this));
    }
    if (l->length()) return l.detach();
    return SASS_MEMORY_NEW(Null, l->pstate());
  }

  Expression* Listize::operator()(CompoundSelector* sel)
  {
    sass::string str;
    for (size_t i = 0, L = sel->length(); i < L; ++i) {
      Expression* e = (*sel)[i]->perform(this);
      if (e) str += e->to_string();
    }
    return SASS_MEMORY_NEW(String_Quoted, sel->pstate(), str);
  }

  Expression* Listize::operator()(ComplexSelector* sel)
  {
    List_Obj l = SASS_MEMORY_NEW(List, sel->pstate());
    // ToDo: investigate what this does
    // Note: seems reated to parent ref
    l->from_selector(true);

    for (auto component : sel->elements()) {
      if (CompoundSelectorObj compound = Cast<CompoundSelector>(component)) {
        if (!compound->empty()) {
          ExpressionObj hh = compound->perform(this);
          if (hh) l->append(hh);
        }
      }
      else if (component) {
        l->append(SASS_MEMORY_NEW(String_Quoted, component->pstate(), component->to_string()));
      }
    }

    if (l->length() == 0) return 0;
    return l.detach();
  }

}
