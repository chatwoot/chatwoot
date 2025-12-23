// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"
#include "ast.hpp"

#include "util_string.hpp"

namespace Sass {

  // ##########################################################################
  // To compare/debug against libsass you can use debugger.hpp:
  // c++: std::cerr << "result " << debug_vec(compound) << "\n";
  // dart: stderr.writeln("result " + compound.toString());
  // ##########################################################################

  // ##########################################################################
  // Returns whether [list1] is a superselector of [list2].
  // That is, whether [list1] matches every element that
  // [list2] matches, as well as possibly additional elements.
  // ##########################################################################
  bool listIsSuperslector(
    const sass::vector<ComplexSelectorObj>& list1,
    const sass::vector<ComplexSelectorObj>& list2);

  // ##########################################################################
  // Returns whether [complex1] is a superselector of [complex2].
  // That is, whether [complex1] matches every element that
  // [complex2] matches, as well as possibly additional elements.
  // ##########################################################################
  bool complexIsSuperselector(
    const sass::vector<SelectorComponentObj>& complex1,
    const sass::vector<SelectorComponentObj>& complex2);

  // ##########################################################################
  // Returns all pseudo selectors in [compound] that have
  // a selector argument, and that have the given [name].
  // ##########################################################################
  sass::vector<PseudoSelectorObj> selectorPseudoNamed(
    CompoundSelectorObj compound, sass::string name)
  {
    sass::vector<PseudoSelectorObj> rv;
    for (SimpleSelectorObj sel : compound->elements()) {
      if (PseudoSelectorObj pseudo = Cast<PseudoSelector>(sel)) {
        if (pseudo->isClass() && pseudo->selector()) {
          if (sel->name() == name) {
            rv.push_back(sel);
          }
        }
      }
    }
    return rv;
  }
  // EO selectorPseudoNamed

  // ##########################################################################
  // Returns whether [simple1] is a superselector of [simple2].
  // That is, whether [simple1] matches every element that
  // [simple2] matches, as well as possibly additional elements.
  // ##########################################################################
  bool simpleIsSuperselector(
    const SimpleSelectorObj& simple1,
    const SimpleSelectorObj& simple2)
  {
    // If they are equal they are superselectors
    if (ObjEqualityFn(simple1, simple2)) {
      return true;
    }
    // Some selector pseudoclasses can match normal selectors.
    if (const PseudoSelector* pseudo = Cast<PseudoSelector>(simple2)) {
      if (pseudo->selector() && isSubselectorPseudo(pseudo->normalized())) {
        for (auto complex : pseudo->selector()->elements()) {
          // Make sure we have exacly one items
          if (complex->length() != 1) {
            return false;
          }
          // That items must be a compound selector
          if (auto compound = Cast<CompoundSelector>(complex->at(0))) {
            // It must contain the lhs simple selector
            if (!compound->contains(simple1)) { 
              return false;
            }
          }
        }
        return true;
      }
    }
    return false;
  }
  // EO simpleIsSuperselector

  // ##########################################################################
  // Returns whether [simple] is a superselector of [compound].
  // That is, whether [simple] matches every element that
  // [compound] matches, as well as possibly additional elements.
  // ##########################################################################
  bool simpleIsSuperselectorOfCompound(
    const SimpleSelectorObj& simple,
    const CompoundSelectorObj& compound)
  {
    for (SimpleSelectorObj simple2 : compound->elements()) {
      if (simpleIsSuperselector(simple, simple2)) {
        return true;
      }
    }
    return false;
  }
  // EO simpleIsSuperselectorOfCompound

  // ##########################################################################
  // ##########################################################################
  bool typeIsSuperselectorOfCompound(
    const TypeSelectorObj& type,
    const CompoundSelectorObj& compound)
  {
    for (const SimpleSelectorObj& simple : compound->elements()) {
      if (const TypeSelectorObj& rhs = Cast<TypeSelector>(simple)) {
        if (*type != *rhs) return true;
      }
    }
    return false;
  }
  // EO typeIsSuperselectorOfCompound

  // ##########################################################################
  // ##########################################################################
  bool idIsSuperselectorOfCompound(
    const IDSelectorObj& id,
    const CompoundSelectorObj& compound)
  {
    for (const SimpleSelectorObj& simple : compound->elements()) {
      if (const IDSelectorObj& rhs = Cast<IDSelector>(simple)) {
        if (*id != *rhs) return true;
      }
    }
    return false;
  }
  // EO idIsSuperselectorOfCompound

  // ##########################################################################
  // ##########################################################################
  bool pseudoIsSuperselectorOfPseudo(
    const PseudoSelectorObj& pseudo1,
    const PseudoSelectorObj& pseudo2,
    const ComplexSelectorObj& parent
  )
  {
    if (!pseudo2->selector()) return false;
    if (pseudo1->name() == pseudo2->name()) {
      SelectorListObj list = pseudo2->selector();
      return listIsSuperslector(list->elements(), { parent });
    }
    return false;
  }
  // EO pseudoIsSuperselectorOfPseudo

  // ##########################################################################
  // ##########################################################################
  bool pseudoNotIsSuperselectorOfCompound(
    const PseudoSelectorObj& pseudo1,
    const CompoundSelectorObj& compound2,
    const ComplexSelectorObj& parent)
  {
    for (const SimpleSelectorObj& simple2 : compound2->elements()) {
      if (const TypeSelectorObj& type2 = Cast<TypeSelector>(simple2)) {
        if (const CompoundSelectorObj& compound1 = Cast<CompoundSelector>(parent->last())) {
          if (typeIsSuperselectorOfCompound(type2, compound1)) return true;
        }
      }
      else if (const IDSelectorObj& id2 = Cast<IDSelector>(simple2)) {
        if (const CompoundSelectorObj& compound1 = Cast<CompoundSelector>(parent->last())) {
          if (idIsSuperselectorOfCompound(id2, compound1)) return true;
        }
      }
      else if (const PseudoSelectorObj& pseudo2 = Cast<PseudoSelector>(simple2)) {
        if (pseudoIsSuperselectorOfPseudo(pseudo1, pseudo2, parent)) return true;
      }
    }
    return false;
  }
  // pseudoNotIsSuperselectorOfCompound

  // ##########################################################################
  // Returns whether [pseudo1] is a superselector of [compound2].
  // That is, whether [pseudo1] matches every element that [compound2]
  // matches, as well as possibly additional elements. This assumes that
  // [pseudo1]'s `selector` argument is not `null`. If [parents] is passed,
  // it represents the parents of [compound2]. This is relevant for pseudo
  // selectors with selector arguments, where we may need to know if the
  // parent selectors in the selector argument match [parents].
  // ##########################################################################
  bool selectorPseudoIsSuperselector(
    const PseudoSelectorObj& pseudo1,
    const CompoundSelectorObj& compound2,
    // ToDo: is this really the most convenient way to do this?
    sass::vector<SelectorComponentObj>::const_iterator parents_from,
    sass::vector<SelectorComponentObj>::const_iterator parents_to)
  {

    // ToDo: move normalization function
    sass::string name(Util::unvendor(pseudo1->name()));

    if (name == "matches" || name == "any") {
      sass::vector<PseudoSelectorObj> pseudos =
        selectorPseudoNamed(compound2, pseudo1->name());
      SelectorListObj selector1 = pseudo1->selector();
      for (PseudoSelectorObj pseudo2 : pseudos) {
        SelectorListObj selector = pseudo2->selector();
        if (selector1->isSuperselectorOf(selector)) {
          return true;
        }
      }

      for (ComplexSelectorObj complex1 : selector1->elements()) {
        sass::vector<SelectorComponentObj> parents;
        for (auto cur = parents_from; cur != parents_to; cur++) {
          parents.push_back(*cur);
        }
        parents.push_back(compound2);
        if (complexIsSuperselector(complex1->elements(), parents)) {
          return true;
        }
      }

    }
    else if (name == "has" || name == "host" || name == "host-context" || name == "slotted") {
      sass::vector<PseudoSelectorObj> pseudos =
        selectorPseudoNamed(compound2, pseudo1->name());
      SelectorListObj selector1 = pseudo1->selector();
      for (PseudoSelectorObj pseudo2 : pseudos) {
        SelectorListObj selector = pseudo2->selector();
        if (selector1->isSuperselectorOf(selector)) {
          return true;
        }
      }

    }
    else if (name == "not") {
      for (ComplexSelectorObj complex : pseudo1->selector()->elements()) {
        if (!pseudoNotIsSuperselectorOfCompound(pseudo1, compound2, complex)) return false;
      }
      return true;
    }
    else if (name == "current") {
      sass::vector<PseudoSelectorObj> pseudos =
        selectorPseudoNamed(compound2, "current");
      for (PseudoSelectorObj pseudo2 : pseudos) {
        if (ObjEqualityFn(pseudo1, pseudo2)) return true;
      }

    }
    else if (name == "nth-child" || name == "nth-last-child") {
      for (auto simple2 : compound2->elements()) {
        if (PseudoSelectorObj pseudo2 = simple2->getPseudoSelector()) {
          if (pseudo1->name() != pseudo2->name()) continue;
          if (!ObjEqualityFn(pseudo1->argument(), pseudo2->argument())) continue;
          if (pseudo1->selector()->isSuperselectorOf(pseudo2->selector())) return true;
        }
      }
      return false;
    }

    return false;

  }
  // EO selectorPseudoIsSuperselector

  // ##########################################################################
  // Returns whether [compound1] is a superselector of [compound2].
  // That is, whether [compound1] matches every element that [compound2]
  // matches, as well as possibly additional elements. If [parents] is
  // passed, it represents the parents of [compound2]. This is relevant
  // for pseudo selectors with selector arguments, where we may need to
  // know if the parent selectors in the selector argument match [parents].
  // ##########################################################################
  bool compoundIsSuperselector(
    const CompoundSelectorObj& compound1,
    const CompoundSelectorObj& compound2,
    // ToDo: is this really the most convenient way to do this?
    const sass::vector<SelectorComponentObj>::const_iterator parents_from,
    const sass::vector<SelectorComponentObj>::const_iterator parents_to)
  {
    // Every selector in [compound1.components] must have
    // a matching selector in [compound2.components].
    for (SimpleSelectorObj simple1 : compound1->elements()) {
      PseudoSelectorObj pseudo1 = Cast<PseudoSelector>(simple1);
      if (pseudo1 && pseudo1->selector()) {
        if (!selectorPseudoIsSuperselector(pseudo1, compound2, parents_from, parents_to)) {
          return false;
        }
      }
      else if (!simpleIsSuperselectorOfCompound(simple1, compound2)) {
        return false;
      }
    }
    // [compound1] can't be a superselector of a selector
    // with pseudo-elements that [compound2] doesn't share.
    for (SimpleSelectorObj simple2 : compound2->elements()) {
      PseudoSelectorObj pseudo2 = Cast<PseudoSelector>(simple2);
      if (pseudo2 && pseudo2->isElement()) {
        if (!simpleIsSuperselectorOfCompound(pseudo2, compound1)) {
          return false;
        }
      }
    }
    return true;
  }
  // EO compoundIsSuperselector

  // ##########################################################################
  // Returns whether [compound1] is a superselector of [compound2].
  // That is, whether [compound1] matches every element that [compound2]
  // matches, as well as possibly additional elements. If [parents] is
  // passed, it represents the parents of [compound2]. This is relevant
  // for pseudo selectors with selector arguments, where we may need to
  // know if the parent selectors in the selector argument match [parents].
  // ##########################################################################
  bool compoundIsSuperselector(
    const CompoundSelectorObj& compound1,
    const CompoundSelectorObj& compound2,
    const sass::vector<SelectorComponentObj>& parents)
  {
    return compoundIsSuperselector(
      compound1, compound2,
      parents.begin(), parents.end()
    );
  }
  // EO compoundIsSuperselector

  // ##########################################################################
  // Returns whether [complex1] is a superselector of [complex2].
  // That is, whether [complex1] matches every element that
  // [complex2] matches, as well as possibly additional elements.
  // ##########################################################################
  bool complexIsSuperselector(
    const sass::vector<SelectorComponentObj>& complex1,
    const sass::vector<SelectorComponentObj>& complex2)
  {

    // Selectors with trailing operators are neither superselectors nor subselectors.
    if (!complex1.empty() && Cast<SelectorCombinator>(complex1.back())) return false;
    if (!complex2.empty() && Cast<SelectorCombinator>(complex2.back())) return false;

    size_t i1 = 0, i2 = 0;
    while (true) {

      size_t remaining1 = complex1.size() - i1;
      size_t remaining2 = complex2.size() - i2;

      if (remaining1 == 0 || remaining2 == 0) {
        return false;
      }
      // More complex selectors are never
      // superselectors of less complex ones.
      if (remaining1 > remaining2) {
        return false;
      }

      // Selectors with leading operators are
      // neither superselectors nor subselectors.
      if (Cast<SelectorCombinator>(complex1[i1])) {
        return false;
      }
      if (Cast<SelectorCombinator>(complex2[i2])) {
        return false;
      }

      CompoundSelectorObj compound1 = Cast<CompoundSelector>(complex1[i1]);
      CompoundSelectorObj compound2 = Cast<CompoundSelector>(complex2.back());

      if (remaining1 == 1) {
        sass::vector<SelectorComponentObj>::const_iterator parents_to = complex2.end();
        sass::vector<SelectorComponentObj>::const_iterator parents_from = complex2.begin();
        std::advance(parents_from, i2 + 1); // equivalent to dart `.skip(i2 + 1)`
        bool rv = compoundIsSuperselector(compound1, compound2, parents_from, parents_to);
        sass::vector<SelectorComponentObj> pp;

        sass::vector<SelectorComponentObj>::const_iterator end = parents_to;
        sass::vector<SelectorComponentObj>::const_iterator beg = parents_from;
        while (beg != end) {
          pp.push_back(*beg);
          beg++;
        }

        return rv;
      }

      // Find the first index where `complex2.sublist(i2, afterSuperselector)`
      // is a subselector of [compound1]. We stop before the superselector
      // would encompass all of [complex2] because we know [complex1] has 
      // more than one element, and consuming all of [complex2] wouldn't 
      // leave anything for the rest of [complex1] to match.
      size_t afterSuperselector = i2 + 1;
      for (; afterSuperselector < complex2.size(); afterSuperselector++) {
        SelectorComponentObj component2 = complex2[afterSuperselector - 1];
        if (CompoundSelectorObj compound2 = Cast<CompoundSelector>(component2)) {
          sass::vector<SelectorComponentObj>::const_iterator parents_to = complex2.begin();
          sass::vector<SelectorComponentObj>::const_iterator parents_from = complex2.begin();
          // complex2.take(afterSuperselector - 1).skip(i2 + 1)
          std::advance(parents_from, i2 + 1); // equivalent to dart `.skip`
          std::advance(parents_to, afterSuperselector); // equivalent to dart `.take`
          if (compoundIsSuperselector(compound1, compound2, parents_from, parents_to)) {
            break;
          }
        }
      }
      if (afterSuperselector == complex2.size()) {
        return false;
      }

      SelectorComponentObj component1 = complex1[i1 + 1],
        component2 = complex2[afterSuperselector];

      SelectorCombinatorObj combinator1 = Cast<SelectorCombinator>(component1);
      SelectorCombinatorObj combinator2 = Cast<SelectorCombinator>(component2);

      if (!combinator1.isNull()) {

        if (combinator2.isNull()) {
          return false;
        }
        // `.a ~ .b` is a superselector of `.a + .b`,
        // but otherwise the combinators must match.
        if (combinator1->isGeneralCombinator()) {
          if (combinator2->isChildCombinator()) {
            return false;
          }
        }
        else if (*combinator1 != *combinator2) {
          return false;
        }

        // `.foo > .baz` is not a superselector of `.foo > .bar > .baz` or
        // `.foo > .bar .baz`, despite the fact that `.baz` is a superselector of
        // `.bar > .baz` and `.bar .baz`. Same goes for `+` and `~`.
        if (remaining1 == 3 && remaining2 > 3) {
          return false;
        }

        i1 += 2; i2 = afterSuperselector + 1;

      }
      else if (!combinator2.isNull()) {
        if (!combinator2->isChildCombinator()) {
          return false;
        }
        i1 += 1; i2 = afterSuperselector + 1;
      }
      else {
        i1 += 1; i2 = afterSuperselector;
      }
    }

    return false;

  }
  // EO complexIsSuperselector

  // ##########################################################################
  // Like [complexIsSuperselector], but compares [complex1]
  // and [complex2] as though they shared an implicit base
  // [SimpleSelector]. For example, `B` is not normally a
  // superselector of `B A`, since it doesn't match elements
  // that match `A`. However, it *is* a parent superselector,
  // since `B X` is a superselector of `B A X`.
  // ##########################################################################
  bool complexIsParentSuperselector(
    const sass::vector<SelectorComponentObj>& complex1,
    const sass::vector<SelectorComponentObj>& complex2)
  {
    // Try some simple heuristics to see if we can avoid allocations.
    if (complex1.empty() && complex2.empty()) return false;
    if (Cast<SelectorCombinator>(complex1.front())) return false;
    if (Cast<SelectorCombinator>(complex2.front())) return false;
    if (complex1.size() > complex2.size()) return false;
    // TODO(nweiz): There's got to be a way to do this without a bunch of extra allocations...
    sass::vector<SelectorComponentObj> cplx1(complex1);
    sass::vector<SelectorComponentObj> cplx2(complex2);
    CompoundSelectorObj base = SASS_MEMORY_NEW(CompoundSelector, "[tmp]");
    cplx1.push_back(base); cplx2.push_back(base);
    return complexIsSuperselector(cplx1, cplx2);
  }
  // EO complexIsParentSuperselector

  // ##########################################################################
  // Returns whether [list] has a superselector for [complex].
  // That is, whether an item in [list] matches every element that
  // [complex] matches, as well as possibly additional elements.
  // ##########################################################################
  bool listHasSuperslectorForComplex(
    sass::vector<ComplexSelectorObj> list,
    ComplexSelectorObj complex)
  {
    // Return true if every [complex] selector on [list2]
    // is a super selector of the full selector [list1].
    for (ComplexSelectorObj lhs : list) {
      if (complexIsSuperselector(lhs->elements(), complex->elements())) {
        return true;
      }
    }
    return false;
  }
  // listIsSuperslectorOfComplex

  // ##########################################################################
  // Returns whether [list1] is a superselector of [list2].
  // That is, whether [list1] matches every element that
  // [list2] matches, as well as possibly additional elements.
  // ##########################################################################
  bool listIsSuperslector(
    const sass::vector<ComplexSelectorObj>& list1,
    const sass::vector<ComplexSelectorObj>& list2)
  {
    // Return true if every [complex] selector on [list2]
    // is a super selector of the full selector [list1].
    for (ComplexSelectorObj complex : list2) {
      if (!listHasSuperslectorForComplex(list1, complex)) {
        return false;
      }
    }
    return true;
  }
  // EO listIsSuperslector

  // ##########################################################################
  // Implement selector methods (dispatch to functions)
  // ##########################################################################
  bool SelectorList::isSuperselectorOf(const SelectorList* sub) const
  {
    return listIsSuperslector(elements(), sub->elements());
  }
  bool ComplexSelector::isSuperselectorOf(const ComplexSelector* sub) const
  {
    return complexIsSuperselector(elements(), sub->elements());
  }

  // ##########################################################################
  // ##########################################################################

}
