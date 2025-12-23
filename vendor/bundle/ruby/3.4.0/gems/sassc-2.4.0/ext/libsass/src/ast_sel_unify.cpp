// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include "ast.hpp"

namespace Sass {

  // ##########################################################################
  // Returns the contents of a [SelectorList] that matches only 
  // elements that are matched by both [complex1] and [complex2].
  // If no such list can be produced, returns `null`.
  // ##########################################################################
  // ToDo: fine-tune API to avoid unnecessary wrapper allocations
  // ##########################################################################
  sass::vector<sass::vector<SelectorComponentObj>> unifyComplex(
    const sass::vector<sass::vector<SelectorComponentObj>>& complexes)
  {

    SASS_ASSERT(!complexes.empty(), "Can't unify empty list");
    if (complexes.size() == 1) return complexes;

    CompoundSelectorObj unifiedBase = SASS_MEMORY_NEW(CompoundSelector, SourceSpan("[phony]"));
    for (auto complex : complexes) {
      SelectorComponentObj base = complex.back();
      if (CompoundSelector * comp = base->getCompound()) {
        if (unifiedBase->empty()) {
          unifiedBase->concat(comp);
        }
        else {
          for (SimpleSelectorObj simple : comp->elements()) {
            unifiedBase = simple->unifyWith(unifiedBase);
            if (unifiedBase.isNull()) return {};
          }
        }
      }
      else {
        return {};
      }
    }

    sass::vector<sass::vector<SelectorComponentObj>> complexesWithoutBases;
    for (size_t i = 0; i < complexes.size(); i += 1) {
      sass::vector<SelectorComponentObj> sel = complexes[i];
      sel.pop_back(); // remove last item (base) from the list
      complexesWithoutBases.push_back(std::move(sel));
    }

    complexesWithoutBases.back().push_back(unifiedBase);

    return weave(complexesWithoutBases);

  }
  // EO unifyComplex

  // ##########################################################################
  // Returns a [CompoundSelector] that matches only elements
  // that are matched by both [compound1] and [compound2].
  // If no such selector can be produced, returns `null`.
  // ##########################################################################
  CompoundSelector* CompoundSelector::unifyWith(CompoundSelector* rhs)
  {
    if (empty()) return rhs;
    CompoundSelectorObj unified = SASS_MEMORY_COPY(rhs);
    for (const SimpleSelectorObj& sel : elements()) {
      unified = sel->unifyWith(unified);
      if (unified.isNull()) break;
    }
    return unified.detach();
  }
  // EO CompoundSelector::unifyWith(CompoundSelector*)

  // ##########################################################################
  // Returns the compoments of a [CompoundSelector] that matches only elements
  // matched by both this and [compound]. By default, this just returns a copy
  // of [compound] with this selector added to the end, or returns the original
  // array if this selector already exists in it. Returns `null` if unification
  // is impossible—for example, if there are multiple ID selectors.
  // ##########################################################################
  // This is implemented in `selector/simple.dart` as `SimpleSelector::unify`
  // ##########################################################################
  CompoundSelector* SimpleSelector::unifyWith(CompoundSelector* rhs)
  {

    if (rhs->length() == 1) {
      if (rhs->get(0)->is_universal()) {
        CompoundSelector* this_compound = SASS_MEMORY_NEW(CompoundSelector, pstate());
        this_compound->append(SASS_MEMORY_COPY(this));
        CompoundSelector* unified = rhs->get(0)->unifyWith(this_compound);
        if (unified == nullptr || unified != this_compound) delete this_compound;
        return unified;
      }
    }
    for (const SimpleSelectorObj& sel : rhs->elements()) {
      if (*this == *sel) {
        return rhs;
      }
    }

    CompoundSelectorObj result = SASS_MEMORY_NEW(CompoundSelector, rhs->pstate());

    bool addedThis = false;
    for (auto simple : rhs->elements()) {
      // Make sure pseudo selectors always come last.
      if (!addedThis && simple->getPseudoSelector()) {
        result->append(this);
        addedThis = true;
      }
      result->append(simple);
    }

    if (!addedThis) {
      result->append(this);
    }
    return result.detach();

  }
  // EO SimpleSelector::unifyWith(CompoundSelector*)

  // ##########################################################################
  // This is implemented in `selector/type.dart` as `PseudoSelector::unify`
  // ##########################################################################
  CompoundSelector* TypeSelector::unifyWith(CompoundSelector* rhs)
  {
    if (rhs->empty()) {
      rhs->append(this);
      return rhs;
    }
    TypeSelector* type = Cast<TypeSelector>(rhs->at(0));
    if (type != nullptr) {
      SimpleSelector* unified = unifyWith(type);
      if (unified == nullptr) {
        return nullptr;
      }
      rhs->elements()[0] = unified;
    }
    else if (!is_universal() || (has_ns_ && ns_ != "*")) {
      rhs->insert(rhs->begin(), this);
    }
    return rhs;
  }

  // ##########################################################################
  // This is implemented in `selector/id.dart` as `PseudoSelector::unify`
  // ##########################################################################
  CompoundSelector* IDSelector::unifyWith(CompoundSelector* rhs)
  {
    for (const SimpleSelector* sel : rhs->elements()) {
      if (const IDSelector* id_sel = Cast<IDSelector>(sel)) {
        if (id_sel->name() != name()) return nullptr;
      }
    }
    return SimpleSelector::unifyWith(rhs);
  }

  // ##########################################################################
  // This is implemented in `selector/pseudo.dart` as `PseudoSelector::unify`
  // ##########################################################################
  CompoundSelector* PseudoSelector::unifyWith(CompoundSelector* compound)
  {

    if (compound->length() == 1 && compound->first()->is_universal()) {
      // std::cerr << "implement universal pseudo\n";
    }

    for (const SimpleSelectorObj& sel : compound->elements()) {
      if (*this == *sel) {
        return compound;
      }
    }

    CompoundSelectorObj result = SASS_MEMORY_NEW(CompoundSelector, compound->pstate());

    bool addedThis = false;
    for (auto simple : compound->elements()) {
      // Make sure pseudo selectors always come last.
      if (PseudoSelectorObj pseudo = simple->getPseudoSelector()) {
        if (pseudo->isElement()) {
          // A given compound selector may only contain one pseudo element. If
          // [compound] has a different one than [this], unification fails.
          if (isElement()) {
            return {};
          }
          // Otherwise, this is a pseudo selector and
          // should come before pseduo elements.
          result->append(this);
          addedThis = true;
        }
      }
      result->append(simple);
    }

    if (!addedThis) {
      result->append(this);
    }

    return result.detach();

  }
  // EO PseudoSelector::unifyWith(CompoundSelector*

  // ##########################################################################
  // This is implemented in `extend/functions.dart` as `unifyUniversalAndElement`
  // Returns a [SimpleSelector] that matches only elements that are matched by
  // both [selector1] and [selector2], which must both be either [UniversalSelector]s
  // or [TypeSelector]s. If no such selector can be produced, returns `null`.
  // Note: libsass handles universal selector directly within the type selector
  // ##########################################################################
  SimpleSelector* TypeSelector::unifyWith(const SimpleSelector* rhs)
  {
    bool rhs_ns = false;
    if (!(is_ns_eq(*rhs) || rhs->is_universal_ns())) {
      if (!is_universal_ns()) {
        return nullptr;
      }
      rhs_ns = true;
    }
    bool rhs_name = false;
    if (!(name_ == rhs->name() || rhs->is_universal())) {
      if (!(is_universal())) {
        return nullptr;
      }
      rhs_name = true;
    }
    if (rhs_ns) {
      ns(rhs->ns());
      has_ns(rhs->has_ns());
    }
    if (rhs_name) name(rhs->name());
    return this;
  }
  // EO TypeSelector::unifyWith(const SimpleSelector*)

  // ##########################################################################
  // Unify two complex selectors. Internally calls `unifyComplex`
  // and then wraps the result in newly create ComplexSelectors.
  // ##########################################################################
  SelectorList* ComplexSelector::unifyWith(ComplexSelector* rhs)
  {
    SelectorListObj list = SASS_MEMORY_NEW(SelectorList, pstate());
    sass::vector<sass::vector<SelectorComponentObj>> rv =
       unifyComplex({ elements(), rhs->elements() });
    for (sass::vector<SelectorComponentObj> items : rv) {
      ComplexSelectorObj sel = SASS_MEMORY_NEW(ComplexSelector, pstate());
      sel->elements() = std::move(items);
      list->append(sel);
    }
    return list.detach();
  }
  // EO ComplexSelector::unifyWith(ComplexSelector*)

  // ##########################################################################
  // only called from the sass function `selector-unify`
  // ##########################################################################
  SelectorList* SelectorList::unifyWith(SelectorList* rhs)
  {
    SelectorList* slist = SASS_MEMORY_NEW(SelectorList, pstate());
    // Unify all of children with RHS's children,
    // storing the results in `unified_complex_selectors`
    for (ComplexSelectorObj& seq1 : elements()) {
      for (ComplexSelectorObj& seq2 : rhs->elements()) {
        if (SelectorListObj unified = seq1->unifyWith(seq2)) {
          std::move(unified->begin(), unified->end(),
            std::inserter(slist->elements(), slist->end()));
        }
      }
    }
    return slist;
  }
  // EO SelectorList::unifyWith(SelectorList*)

  // ##########################################################################
  // ##########################################################################

}
