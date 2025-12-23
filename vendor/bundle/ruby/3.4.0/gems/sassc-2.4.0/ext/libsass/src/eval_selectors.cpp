// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"
#include "expand.hpp"
#include "eval.hpp"
#include "ast.hpp"


namespace Sass {

  SelectorList* Eval::operator()(SelectorList* s)
  {
    sass::vector<SelectorListObj> rv;
    SelectorListObj sl = SASS_MEMORY_NEW(SelectorList, s->pstate());
    for (size_t i = 0, iL = s->length(); i < iL; ++i) {
      rv.push_back(operator()(s->get(i)));
    }

    // we should actually permutate parent first
    // but here we have permutated the selector first
    size_t round = 0;
    while (round != sass::string::npos) {
      bool abort = true;
      for (size_t i = 0, iL = rv.size(); i < iL; ++i) {
        if (rv[i]->length() > round) {
          sl->append((*rv[i])[round]);
          abort = false;
        }
      }
      if (abort) {
        round = sass::string::npos;
      }
      else {
        ++round;
      }

    }
    return sl.detach();
  }

  SelectorComponent* Eval::operator()(SelectorComponent* s)
  {
    return {};
  }

  SelectorList* Eval::operator()(ComplexSelector* s)
  {
    bool implicit_parent = !exp.old_at_root_without_rule;
    if (is_in_selector_schema) exp.pushNullSelector();
    SelectorListObj other = s->resolve_parent_refs(
      exp.getOriginalStack(), traces, implicit_parent);
    if (is_in_selector_schema) exp.popNullSelector();

    for (size_t i = 0; i < other->length(); i++) {
      ComplexSelectorObj sel = other->at(i);
      for (size_t n = 0; n < sel->length(); n++) {
        if (CompoundSelectorObj comp = Cast<CompoundSelector>(sel->at(n))) {
          sel->at(n) = operator()(comp);
        }
      }
    }

    return other.detach();
  }

  CompoundSelector* Eval::operator()(CompoundSelector* s)
  {
    for (size_t i = 0; i < s->length(); i++) {
      SimpleSelector* ss = s->at(i);
      // skip parents here (called via resolve_parent_refs)
      s->at(i) = Cast<SimpleSelector>(ss->perform(this));
    }
    return s;
  }
}
