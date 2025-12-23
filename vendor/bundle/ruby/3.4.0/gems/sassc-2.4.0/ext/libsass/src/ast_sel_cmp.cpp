// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include "ast_selectors.hpp"

namespace Sass {

  /*#########################################################################*/
  // Compare against base class on right hand side
  // try to find the most specialized implementation
  /*#########################################################################*/

  // Selector lists can be compared to comma lists
  bool SelectorList::operator== (const Expression& rhs) const
  {
    if (auto l = Cast<List>(&rhs)) { return *this == *l; }
    if (auto s = Cast<Selector>(&rhs)) { return *this == *s; }
    if (Cast<String>(&rhs) || Cast<Null>(&rhs)) { return false; }
    throw std::runtime_error("invalid selector base classes to compare");
  }

  // Selector lists can be compared to comma lists
  bool SelectorList::operator== (const Selector& rhs) const
  {
    if (auto sel = Cast<SelectorList>(&rhs)) { return *this == *sel; }
    if (auto sel = Cast<ComplexSelector>(&rhs)) { return *this == *sel; }
    if (auto sel = Cast<CompoundSelector>(&rhs)) { return *this == *sel; }
    if (auto sel = Cast<SimpleSelector>(&rhs)) { return *this == *sel; }
    if (auto list = Cast<List>(&rhs)) { return *this == *list; }
    throw std::runtime_error("invalid selector base classes to compare");
  }

  bool ComplexSelector::operator== (const Selector& rhs) const
  {
    if (auto sel = Cast<SelectorList>(&rhs)) { return *this == *sel; }
    if (auto sel = Cast<ComplexSelector>(&rhs)) { return *sel == *this; }
    if (auto sel = Cast<CompoundSelector>(&rhs)) { return *this == *sel; }
    if (auto sel = Cast<SimpleSelector>(&rhs)) { return *this == *sel; }
    throw std::runtime_error("invalid selector base classes to compare");
  }

  bool SelectorCombinator::operator== (const Selector& rhs) const
  {
    if (auto cpx = Cast<SelectorCombinator>(&rhs)) { return *this == *cpx; }
    return false;
  }

  bool CompoundSelector::operator== (const Selector& rhs) const
  {
    if (auto sel = Cast<SimpleSelector>(&rhs)) { return *this == *sel; }
    if (auto sel = Cast<SelectorList>(&rhs)) { return *this == *sel; }
    if (auto sel = Cast<ComplexSelector>(&rhs)) { return *this == *sel; }
    if (auto sel = Cast<CompoundSelector>(&rhs)) { return *this == *sel; }
    throw std::runtime_error("invalid selector base classes to compare");
  }

  bool SimpleSelector::operator== (const Selector& rhs) const
  {
    if (auto sel = Cast<SelectorList>(&rhs)) { return *this == *sel; }
    if (auto sel = Cast<ComplexSelector>(&rhs)) { return *this == *sel; }
    if (auto sel = Cast<CompoundSelector>(&rhs)) { return *this == *sel; }
    if (auto sel = Cast<SimpleSelector>(&rhs)) return *this == *sel;
    throw std::runtime_error("invalid selector base classes to compare");
  }

  /*#########################################################################*/
  /*#########################################################################*/

  bool SelectorList::operator== (const SelectorList& rhs) const
  {
    if (&rhs == this) return true;
    if (rhs.length() != length()) return false;
    std::unordered_set<const ComplexSelector*, PtrObjHash, PtrObjEquality> lhs_set;
    lhs_set.reserve(length());
    for (const ComplexSelectorObj& element : elements()) {
      lhs_set.insert(element.ptr());
    }
    for (const ComplexSelectorObj& element : rhs.elements()) {
      if (lhs_set.find(element.ptr()) == lhs_set.end()) return false;
    }
    return true;
  }



  /*#########################################################################*/
  // Compare SelectorList against all other selector types
  /*#########################################################################*/

  bool SelectorList::operator== (const ComplexSelector& rhs) const
  {
    // If both are empty they are equal
    if (empty() && rhs.empty()) return true;
    // Must have exactly one item
    if (length() != 1) return false;
    // Compare simple selectors
    return *get(0) == rhs;
  }

  bool SelectorList::operator== (const CompoundSelector& rhs) const
  {
    // If both are empty they are equal
    if (empty() && rhs.empty()) return true;
    // Must have exactly one item
    if (length() != 1) return false;
    // Compare simple selectors
    return *get(0) == rhs;
  }

  bool SelectorList::operator== (const SimpleSelector& rhs) const
  {
    // If both are empty they are equal
    if (empty() && rhs.empty()) return true;
    // Must have exactly one item
    if (length() != 1) return false;
    // Compare simple selectors
    return *get(0) == rhs;
  }

  /*#########################################################################*/
  // Compare ComplexSelector against itself
  /*#########################################################################*/

  bool ComplexSelector::operator== (const ComplexSelector& rhs) const
  {
    size_t len = length();
    size_t rlen = rhs.length();
    if (len != rlen) return false;
    for (size_t i = 0; i < len; i += 1) {
      if (*get(i) != *rhs.get(i)) return false;
    }
    return true;
  }

  /*#########################################################################*/
  // Compare ComplexSelector against all other selector types
  /*#########################################################################*/

  bool ComplexSelector::operator== (const SelectorList& rhs) const
  {
    // If both are empty they are equal
    if (empty() && rhs.empty()) return true;
    // Must have exactly one item
    if (rhs.length() != 1) return false;
    // Compare complex selector
    return *this == *rhs.get(0);
  }

  bool ComplexSelector::operator== (const CompoundSelector& rhs) const
  {
    // If both are empty they are equal
    if (empty() && rhs.empty()) return true;
    // Must have exactly one item
    if (length() != 1) return false;
    // Compare compound selector
    return *get(0) == rhs;
  }

  bool ComplexSelector::operator== (const SimpleSelector& rhs) const
  {
    // If both are empty they are equal
    if (empty() && rhs.empty()) return true;
    // Must have exactly one item
    if (length() != 1) return false;
    // Compare simple selectors
    return *get(0) == rhs;
  }

  /*#########################################################################*/
  // Compare SelectorCombinator against itself
  /*#########################################################################*/

  bool SelectorCombinator::operator==(const SelectorCombinator& rhs) const
  {
    return combinator() == rhs.combinator();
  }

  /*#########################################################################*/
  // Compare SelectorCombinator against SelectorComponent
  /*#########################################################################*/

  bool SelectorCombinator::operator==(const SelectorComponent& rhs) const
  {
    if (const SelectorCombinator * sel = rhs.getCombinator()) {
      return *this == *sel;
    }
    return false;
  }

  bool CompoundSelector::operator==(const SelectorComponent& rhs) const
  {
    if (const CompoundSelector * sel = rhs.getCompound()) {
      return *this == *sel;
    }
    return false;
  }

  /*#########################################################################*/
  // Compare CompoundSelector against itself
  /*#########################################################################*/
  // ToDo: Verifiy implementation
  /*#########################################################################*/

  bool CompoundSelector::operator== (const CompoundSelector& rhs) const
  {
    // std::cerr << "comp vs comp\n";
    if (&rhs == this) return true;
    if (rhs.length() != length()) return false;
    std::unordered_set<const SimpleSelector*, PtrObjHash, PtrObjEquality> lhs_set;
    lhs_set.reserve(length());
    for (const SimpleSelectorObj& element : elements()) {
      lhs_set.insert(element.ptr());
    }
    // there is no break?!
    for (const SimpleSelectorObj& element : rhs.elements()) {
      if (lhs_set.find(element.ptr()) == lhs_set.end()) return false;
    }
    return true;
  }


  /*#########################################################################*/
  // Compare CompoundSelector against all other selector types
  /*#########################################################################*/

  bool CompoundSelector::operator== (const SelectorList& rhs) const
  {
    // If both are empty they are equal
    if (empty() && rhs.empty()) return true;
    // Must have exactly one item
    if (rhs.length() != 1) return false;
    // Compare complex selector
    return *this == *rhs.get(0);
  }

  bool CompoundSelector::operator== (const ComplexSelector& rhs) const
  {
    // If both are empty they are equal
    if (empty() && rhs.empty()) return true;
    // Must have exactly one item
    if (rhs.length() != 1) return false;
    // Compare compound selector
    return *this == *rhs.get(0);
  }

  bool CompoundSelector::operator== (const SimpleSelector& rhs) const
  {
    // If both are empty they are equal
    if (empty() && rhs.empty()) return false;
    // Must have exactly one item
    size_t rlen = length();
    if (rlen > 1) return false;
    if (rlen == 0) return true;
    // Compare simple selectors
    return *get(0) < rhs;
  }

  /*#########################################################################*/
  // Compare SimpleSelector against itself (upcast from abstract base)
  /*#########################################################################*/

  // DOES NOT EXIST FOR ABSTRACT BASE CLASS

  /*#########################################################################*/
  // Compare SimpleSelector against all other selector types
  /*#########################################################################*/

  bool SimpleSelector::operator== (const SelectorList& rhs) const
  {
    // If both are empty they are equal
    if (empty() && rhs.empty()) return true;
    // Must have exactly one item
    if (rhs.length() != 1) return false;
    // Compare complex selector
    return *this == *rhs.get(0);
  }

  bool SimpleSelector::operator== (const ComplexSelector& rhs) const
  {
    // If both are empty they are equal
    if (empty() && rhs.empty()) return true;
    // Must have exactly one item
    if (rhs.length() != 1) return false;
    // Compare compound selector
    return *this == *rhs.get(0);
  }

  bool SimpleSelector::operator== (const CompoundSelector& rhs) const
  {
    // If both are empty they are equal
    if (empty() && rhs.empty()) return false;
    // Must have exactly one item
    if (rhs.length() != 1) return false;
    // Compare simple selector
    return *this == *rhs.get(0);
  }

  /*#########################################################################*/
  /*#########################################################################*/

  bool IDSelector::operator== (const SimpleSelector& rhs) const
  {
    auto sel = Cast<IDSelector>(&rhs);
    return sel ? *this == *sel : false;
  }

  bool TypeSelector::operator== (const SimpleSelector& rhs) const
  {
    auto sel = Cast<TypeSelector>(&rhs);
    return sel ? *this == *sel : false;
  }

  bool ClassSelector::operator== (const SimpleSelector& rhs) const
  {
    auto sel = Cast<ClassSelector>(&rhs);
    return sel ? *this == *sel : false;
  }

  bool PseudoSelector::operator== (const SimpleSelector& rhs) const
  {
    auto sel = Cast<PseudoSelector>(&rhs);
    return sel ? *this == *sel : false;
  }

  bool AttributeSelector::operator== (const SimpleSelector& rhs) const
  {
    auto sel = Cast<AttributeSelector>(&rhs);
    return sel ? *this == *sel : false;
  }

  bool PlaceholderSelector::operator== (const SimpleSelector& rhs) const
  {
    auto sel = Cast<PlaceholderSelector>(&rhs);
    return sel ? *this == *sel : false;
  }

  /*#########################################################################*/
  /*#########################################################################*/

  bool IDSelector::operator== (const IDSelector& rhs) const
  {
    // ID has no namespacing
    return name() == rhs.name();
  }

  bool TypeSelector::operator== (const TypeSelector& rhs) const
  {
    return is_ns_eq(rhs) && name() == rhs.name();
  }

  bool ClassSelector::operator== (const ClassSelector& rhs) const
  {
    // Class has no namespacing
    return name() == rhs.name();
  }

  bool PlaceholderSelector::operator== (const PlaceholderSelector& rhs) const
  {
    // Placeholder has no namespacing
    return name() == rhs.name();
  }

  bool AttributeSelector::operator== (const AttributeSelector& rhs) const
  {
    // smaller return, equal go on, bigger abort
    if (is_ns_eq(rhs)) {
      if (name() != rhs.name()) return false;
      if (matcher() != rhs.matcher()) return false;
      if (modifier() != rhs.modifier()) return false;
      const String* lhs_val = value();
      const String* rhs_val = rhs.value();
      return PtrObjEquality()(lhs_val, rhs_val);
    }
    else { return false; }
  }

  bool PseudoSelector::operator== (const PseudoSelector& rhs) const
  {
    if (is_ns_eq(rhs)) {
      if (name() != rhs.name()) return false;
      if (isElement() != rhs.isElement()) return false;
      const String* lhs_arg = argument();
      const String* rhs_arg = rhs.argument();
      if (!PtrObjEquality()(lhs_arg, rhs_arg)) return false;
      const SelectorList* lhs_sel = selector();
      const SelectorList* rhs_sel = rhs.selector();
      return PtrObjEquality()(lhs_sel, rhs_sel);
    }
    else { return false; }
  }

  /*#########################################################################*/
  /*#########################################################################*/

}
