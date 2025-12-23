// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include "ast.hpp"
#include "permutate.hpp"
#include "util_string.hpp"

namespace Sass {

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  Selector::Selector(SourceSpan pstate)
  : Expression(pstate),
    hash_(0)
  { concrete_type(SELECTOR); }

  Selector::Selector(const Selector* ptr)
  : Expression(ptr),
    hash_(ptr->hash_)
  { concrete_type(SELECTOR); }


  bool Selector::has_real_parent_ref() const
  {
    return false;
  }

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  Selector_Schema::Selector_Schema(SourceSpan pstate, String_Obj c)
  : AST_Node(pstate),
    contents_(c),
    connect_parent_(true),
    hash_(0)
  { }
  Selector_Schema::Selector_Schema(const Selector_Schema* ptr)
  : AST_Node(ptr),
    contents_(ptr->contents_),
    connect_parent_(ptr->connect_parent_),
    hash_(ptr->hash_)
  { }

  unsigned long Selector_Schema::specificity() const
  {
    return 0;
  }

  size_t Selector_Schema::hash() const {
    if (hash_ == 0) {
      hash_combine(hash_, contents_->hash());
    }
    return hash_;
  }

  bool Selector_Schema::has_real_parent_ref() const
  {
    // Note: disabled since it does not seem to do anything?
    // if (String_Schema_Obj schema = Cast<String_Schema>(contents())) {
    // if (schema->empty()) return false;
    // const auto first = schema->first();
    // return Cast<Parent_Reference>(first);
    // }
    return false;
  }

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  SimpleSelector::SimpleSelector(SourceSpan pstate, sass::string n)
  : Selector(pstate), ns_(""), name_(n), has_ns_(false)
  {
    size_t pos = n.find('|');
    // found some namespace
    if (pos != sass::string::npos) {
      has_ns_ = true;
      ns_ = n.substr(0, pos);
      name_ = n.substr(pos + 1);
    }
  }
  SimpleSelector::SimpleSelector(const SimpleSelector* ptr)
  : Selector(ptr),
    ns_(ptr->ns_),
    name_(ptr->name_),
    has_ns_(ptr->has_ns_)
  { }

  sass::string SimpleSelector::ns_name() const
  {
    if (!has_ns_) return name_;
    else return ns_ + "|" + name_;
  }

  size_t SimpleSelector::hash() const
  {
    if (hash_ == 0) {
      hash_combine(hash_, name());
      hash_combine(hash_, (int)SELECTOR);
      hash_combine(hash_, (int)simple_type());
      if (has_ns_) hash_combine(hash_, ns());
    }
    return hash_;
  }

  bool SimpleSelector::empty() const {
    return ns().empty() && name().empty();
  }

  // namespace compare functions
  bool SimpleSelector::is_ns_eq(const SimpleSelector& r) const
  {
    return has_ns_ == r.has_ns_ && ns_ == r.ns_;
  }

  // namespace query functions
  bool SimpleSelector::is_universal_ns() const
  {
    return has_ns_ && ns_ == "*";
  }

  bool SimpleSelector::is_empty_ns() const
  {
    return !has_ns_ || ns_ == "";
  }

  bool SimpleSelector::has_empty_ns() const
  {
    return has_ns_ && ns_ == "";
  }

  bool SimpleSelector::has_qualified_ns() const
  {
    return has_ns_ && ns_ != "" && ns_ != "*";
  }

  // name query functions
  bool SimpleSelector::is_universal() const
  {
    return name_ == "*";
  }

  bool SimpleSelector::has_placeholder()
  {
    return false;
  }

  bool SimpleSelector::has_real_parent_ref() const
  {
    return false;
  };

  bool SimpleSelector::is_pseudo_element() const
  {
    return false;
  }

  CompoundSelectorObj SimpleSelector::wrapInCompound()
  {
    CompoundSelectorObj selector =
      SASS_MEMORY_NEW(CompoundSelector, pstate());
    selector->append(this);
    return selector;
  }
  ComplexSelectorObj SimpleSelector::wrapInComplex()
  {
    ComplexSelectorObj selector =
      SASS_MEMORY_NEW(ComplexSelector, pstate());
    selector->append(wrapInCompound());
    return selector;
  }

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  PlaceholderSelector::PlaceholderSelector(SourceSpan pstate, sass::string n)
  : SimpleSelector(pstate, n)
  { simple_type(PLACEHOLDER_SEL); }
  PlaceholderSelector::PlaceholderSelector(const PlaceholderSelector* ptr)
  : SimpleSelector(ptr)
  { simple_type(PLACEHOLDER_SEL); }
  unsigned long PlaceholderSelector::specificity() const
  {
    return Constants::Specificity_Base;
  }
  bool PlaceholderSelector::has_placeholder() {
    return true;
  }

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  TypeSelector::TypeSelector(SourceSpan pstate, sass::string n)
  : SimpleSelector(pstate, n)
  { simple_type(TYPE_SEL); }
  TypeSelector::TypeSelector(const TypeSelector* ptr)
  : SimpleSelector(ptr)
  { simple_type(TYPE_SEL); }

  unsigned long TypeSelector::specificity() const
  {
    if (name() == "*") return 0;
    else return Constants::Specificity_Element;
  }

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  ClassSelector::ClassSelector(SourceSpan pstate, sass::string n)
  : SimpleSelector(pstate, n)
  { simple_type(CLASS_SEL); }
  ClassSelector::ClassSelector(const ClassSelector* ptr)
  : SimpleSelector(ptr)
  { simple_type(CLASS_SEL); }

  unsigned long ClassSelector::specificity() const
  {
    return Constants::Specificity_Class;
  }

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  IDSelector::IDSelector(SourceSpan pstate, sass::string n)
  : SimpleSelector(pstate, n)
  { simple_type(ID_SEL); }
  IDSelector::IDSelector(const IDSelector* ptr)
  : SimpleSelector(ptr)
  { simple_type(ID_SEL); }

  unsigned long IDSelector::specificity() const
  {
    return Constants::Specificity_ID;
  }

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  AttributeSelector::AttributeSelector(SourceSpan pstate, sass::string n, sass::string m, String_Obj v, char o)
  : SimpleSelector(pstate, n), matcher_(m), value_(v), modifier_(o)
  { simple_type(ATTRIBUTE_SEL); }
  AttributeSelector::AttributeSelector(const AttributeSelector* ptr)
  : SimpleSelector(ptr),
    matcher_(ptr->matcher_),
    value_(ptr->value_),
    modifier_(ptr->modifier_)
  { simple_type(ATTRIBUTE_SEL); }

  size_t AttributeSelector::hash() const
  {
    if (hash_ == 0) {
      hash_combine(hash_, SimpleSelector::hash());
      hash_combine(hash_, std::hash<sass::string>()(matcher()));
      if (value_) hash_combine(hash_, value_->hash());
    }
    return hash_;
  }

  unsigned long AttributeSelector::specificity() const
  {
    return Constants::Specificity_Attr;
  }

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  PseudoSelector::PseudoSelector(SourceSpan pstate, sass::string name, bool element)
  : SimpleSelector(pstate, name),
    normalized_(Util::unvendor(name)),
    argument_({}),
    selector_({}),
    isSyntacticClass_(!element),
    isClass_(!element && !isFakePseudoElement(normalized_))
  { simple_type(PSEUDO_SEL); }
  PseudoSelector::PseudoSelector(const PseudoSelector* ptr)
  : SimpleSelector(ptr),
    normalized_(ptr->normalized()),
    argument_(ptr->argument()),
    selector_(ptr->selector()),
    isSyntacticClass_(ptr->isSyntacticClass()),
    isClass_(ptr->isClass())
  { simple_type(PSEUDO_SEL); }

  // A pseudo-element is made of two colons (::) followed by the name.
  // The `::` notation is introduced by the current document in order to
  // establish a discrimination between pseudo-classes and pseudo-elements.
  // For compatibility with existing style sheets, user agents must also
  // accept the previous one-colon notation for pseudo-elements introduced
  // in CSS levels 1 and 2 (namely, :first-line, :first-letter, :before and
  // :after). This compatibility is not allowed for the new pseudo-elements
  // introduced in this specification.
  bool PseudoSelector::is_pseudo_element() const
  {
    return isElement();
  }

  size_t PseudoSelector::hash() const
  {
    if (hash_ == 0) {
      hash_combine(hash_, SimpleSelector::hash());
      if (selector_) hash_combine(hash_, selector_->hash());
      if (argument_) hash_combine(hash_, argument_->hash());
    }
    return hash_;
  }

  unsigned long PseudoSelector::specificity() const
  {
    if (is_pseudo_element())
      return Constants::Specificity_Element;
    return Constants::Specificity_Pseudo;
  }

  PseudoSelectorObj PseudoSelector::withSelector(SelectorListObj selector)
  {
    PseudoSelectorObj pseudo = SASS_MEMORY_COPY(this);
    pseudo->selector(selector);
    return pseudo;
  }

  bool PseudoSelector::empty() const
  {
    // Only considered empty if selector is
    // available but has no items in it.
    return selector() && selector()->empty();
  }

  void PseudoSelector::cloneChildren()
  {
    if (selector().isNull()) selector({});
    else selector(SASS_MEMORY_CLONE(selector()));
  }

  bool PseudoSelector::has_real_parent_ref() const {
    if (!selector()) return false;
    return selector()->has_real_parent_ref();
  }

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  SelectorList::SelectorList(SourceSpan pstate, size_t s)
  : Selector(pstate),
    Vectorized<ComplexSelectorObj>(s),
    is_optional_(false)
  { }
  SelectorList::SelectorList(const SelectorList* ptr)
    : Selector(ptr),
    Vectorized<ComplexSelectorObj>(*ptr),
    is_optional_(ptr->is_optional_)
  { }

  size_t SelectorList::hash() const
  {
    if (Selector::hash_ == 0) {
      hash_combine(Selector::hash_, Vectorized::hash());
    }
    return Selector::hash_;
  }

  bool SelectorList::has_real_parent_ref() const
  {
    for (ComplexSelectorObj s : elements()) {
      if (s && s->has_real_parent_ref()) return true;
    }
    return false;
  }

  void SelectorList::cloneChildren()
  {
    for (size_t i = 0, l = length(); i < l; i++) {
      at(i) = SASS_MEMORY_CLONE(at(i));
    }
  }

  unsigned long SelectorList::specificity() const
  {
    return 0;
  }

  bool SelectorList::isInvisible() const
  {
    if (length() == 0) return true;
    for (size_t i = 0; i < length(); i += 1) {
      if (get(i)->isInvisible()) return true;
    }
    return false;
  }

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  ComplexSelector::ComplexSelector(SourceSpan pstate)
  : Selector(pstate),
    Vectorized<SelectorComponentObj>(),
    chroots_(false),
    hasPreLineFeed_(false)
  {
  }
  ComplexSelector::ComplexSelector(const ComplexSelector* ptr)
  : Selector(ptr),
    Vectorized<SelectorComponentObj>(ptr->elements()),
    chroots_(ptr->chroots()),
    hasPreLineFeed_(ptr->hasPreLineFeed())
  {
  }

  void ComplexSelector::cloneChildren()
  {
    for (size_t i = 0, l = length(); i < l; i++) {
      at(i) = SASS_MEMORY_CLONE(at(i));
    }
  }

  unsigned long ComplexSelector::specificity() const
  {
    int sum = 0;
    for (auto component : elements()) {
      sum += component->specificity();
    }
    return sum;
  }

  bool ComplexSelector::isInvisible() const
  {
    if (length() == 0) return true;
    for (size_t i = 0; i < length(); i += 1) {
      if (CompoundSelectorObj compound = get(i)->getCompound()) {
        if (compound->isInvisible()) return true;
      }
    }
    return false;
  }

  SelectorListObj ComplexSelector::wrapInList()
  {
    SelectorListObj selector =
      SASS_MEMORY_NEW(SelectorList, pstate());
    selector->append(this);
    return selector;
  }

  size_t ComplexSelector::hash() const
  {
    if (Selector::hash_ == 0) {
      hash_combine(Selector::hash_, Vectorized::hash());
      // ToDo: this breaks some extend lookup
      // hash_combine(Selector::hash_, chroots_);
    }
    return Selector::hash_;
  }

  bool ComplexSelector::has_placeholder() const {
    for (size_t i = 0, L = length(); i < L; ++i) {
      if (get(i)->has_placeholder()) return true;
    }
    return false;
  }

  bool ComplexSelector::has_real_parent_ref() const
  {
    for (auto item : elements()) {
      if (item->has_real_parent_ref()) return true;
    }
    return false;
  }

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  SelectorComponent::SelectorComponent(SourceSpan pstate, bool postLineBreak)
  : Selector(pstate),
    hasPostLineBreak_(postLineBreak)
  {
  }

  SelectorComponent::SelectorComponent(const SelectorComponent* ptr)
  : Selector(ptr),
    hasPostLineBreak_(ptr->hasPostLineBreak())
  { }

  void SelectorComponent::cloneChildren()
  {
  }

  unsigned long SelectorComponent::specificity() const
  {
    return 0;
  }

  // Wrap the compound selector with a complex selector
  ComplexSelector* SelectorComponent::wrapInComplex()
  {
    auto complex = SASS_MEMORY_NEW(ComplexSelector, pstate());
    complex->append(this);
    return complex;
  }

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  SelectorCombinator::SelectorCombinator(SourceSpan pstate, SelectorCombinator::Combinator combinator, bool postLineBreak)
    : SelectorComponent(pstate, postLineBreak),
    combinator_(combinator)
  {
  }
  SelectorCombinator::SelectorCombinator(const SelectorCombinator* ptr)
    : SelectorComponent(ptr->pstate(), false),
      combinator_(ptr->combinator())
  { }

  void SelectorCombinator::cloneChildren()
  {
  }

  unsigned long SelectorCombinator::specificity() const
  {
    return 0;
  }

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  CompoundSelector::CompoundSelector(SourceSpan pstate, bool postLineBreak)
    : SelectorComponent(pstate, postLineBreak),
      Vectorized<SimpleSelectorObj>(),
      hasRealParent_(false),
      extended_(false)
  {
  }
  CompoundSelector::CompoundSelector(const CompoundSelector* ptr)
    : SelectorComponent(ptr),
      Vectorized<SimpleSelectorObj>(*ptr),
      hasRealParent_(ptr->hasRealParent()),
      extended_(ptr->extended())
  { }

  size_t CompoundSelector::hash() const
  {
    if (Selector::hash_ == 0) {
      hash_combine(Selector::hash_, Vectorized::hash());
      hash_combine(Selector::hash_, hasRealParent_);
    }
    return Selector::hash_;
  }

  bool CompoundSelector::has_real_parent_ref() const
  {
    if (hasRealParent()) return true;
    // ToDo: dart sass has another check?
    // if (Cast<TypeSelector>(front)) {
    //  if (front->ns() != "") return false;
    // }
    for (const SimpleSelector* s : elements()) {
      if (s && s->has_real_parent_ref()) return true;
    }
    return false;
  }

  bool CompoundSelector::has_placeholder() const
  {
    if (length() == 0) return false;
    for (SimpleSelectorObj ss : elements()) {
      if (ss->has_placeholder()) return true;
    }
    return false;
  }

  void CompoundSelector::cloneChildren()
  {
    for (size_t i = 0, l = length(); i < l; i++) {
      at(i) = SASS_MEMORY_CLONE(at(i));
    }
  }

  unsigned long CompoundSelector::specificity() const
  {
    int sum = 0;
    for (size_t i = 0, L = length(); i < L; ++i)
    { sum += get(i)->specificity(); }
    return sum;
  }

  bool CompoundSelector::isInvisible() const
  {
    for (size_t i = 0; i < length(); i += 1) {
      if (!get(i)->isInvisible()) return false;
    }
    return true;
  }

  bool CompoundSelector::isSuperselectorOf(const CompoundSelector* sub, sass::string wrapped) const
  {
    CompoundSelector* rhs2 = const_cast<CompoundSelector*>(sub);
    CompoundSelector* lhs2 = const_cast<CompoundSelector*>(this);
    return compoundIsSuperselector(lhs2, rhs2, {});
  }

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  MediaRule::MediaRule(SourceSpan pstate, Block_Obj block) :
    ParentStatement(pstate, block),
    schema_({})
  {
    statement_type(MEDIA);
  }

  MediaRule::MediaRule(const MediaRule* ptr) :
    ParentStatement(ptr),
    schema_(ptr->schema_)
  {
    statement_type(MEDIA);
  }

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  CssMediaRule::CssMediaRule(SourceSpan pstate, Block_Obj block) :
    ParentStatement(pstate, block),
    Vectorized()
  {
    statement_type(MEDIA);
  }

  CssMediaRule::CssMediaRule(const CssMediaRule* ptr) :
    ParentStatement(ptr),
    Vectorized(*ptr)
  {
    statement_type(MEDIA);
  }

  CssMediaQuery::CssMediaQuery(SourceSpan pstate) :
    AST_Node(pstate),
    modifier_(""),
    type_(""),
    features_()
  {
  }

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  bool CssMediaQuery::operator==(const CssMediaQuery& rhs) const
  {
    return type_ == rhs.type_
      && modifier_ == rhs.modifier_
      && features_ == rhs.features_;
  }

  // Implemented after dart-sass (maybe move to other class?)
  CssMediaQuery_Obj CssMediaQuery::merge(CssMediaQuery_Obj& other)
  {

    sass::string ourType = this->type();
    Util::ascii_str_tolower(&ourType);

    sass::string theirType = other->type();
    Util::ascii_str_tolower(&theirType);

    sass::string ourModifier = this->modifier();
    Util::ascii_str_tolower(&ourModifier);

    sass::string theirModifier = other->modifier();
    Util::ascii_str_tolower(&theirModifier);

    sass::string type;
    sass::string modifier;
    sass::vector<sass::string> features;

    if (ourType.empty() && theirType.empty()) {
      CssMediaQuery_Obj query = SASS_MEMORY_NEW(CssMediaQuery, pstate());
      sass::vector<sass::string> f1(this->features());
      sass::vector<sass::string> f2(other->features());
      features.insert(features.end(), f1.begin(), f1.end());
      features.insert(features.end(), f2.begin(), f2.end());
      query->features(features);
      return query;
    }

    if ((ourModifier == "not") != (theirModifier == "not")) {
      if (ourType == theirType) {
        sass::vector<sass::string> negativeFeatures =
          ourModifier == "not" ? this->features() : other->features();
        sass::vector<sass::string> positiveFeatures =
          ourModifier == "not" ? other->features() : this->features();

        // If the negative features are a subset of the positive features, the
        // query is empty. For example, `not screen and (color)` has no
        // intersection with `screen and (color) and (grid)`.
        // However, `not screen and (color)` *does* intersect with `screen and
        // (grid)`, because it means `not (screen and (color))` and so it allows
        // a screen with no color but with a grid.
        if (listIsSubsetOrEqual(negativeFeatures, positiveFeatures)) {
          return SASS_MEMORY_NEW(CssMediaQuery, pstate());
        }
        else {
          return {};
        }
      }
      else if (this->matchesAllTypes() || other->matchesAllTypes()) {
        return {};
      }

      if (ourModifier == "not") {
        modifier = theirModifier;
        type = theirType;
        features = other->features();
      }
      else {
        modifier = ourModifier;
        type = ourType;
        features = this->features();
      }
    }
    else if (ourModifier == "not") {
      SASS_ASSERT(theirModifier == "not", "modifiers not is sync");

      // CSS has no way of representing "neither screen nor print".
      if (ourType != theirType) return {};

      auto moreFeatures = this->features().size() > other->features().size()
        ? this->features()
        : other->features();
      auto fewerFeatures = this->features().size() > other->features().size()
        ? other->features()
        : this->features();

      // If one set of features is a superset of the other,
      // use those features because they're strictly narrower.
      if (listIsSubsetOrEqual(fewerFeatures, moreFeatures)) {
        modifier = ourModifier; // "not"
        type = ourType;
        features = moreFeatures;
      }
      else {
        // Otherwise, there's no way to
        // represent the intersection.
        return {};
      }

    }
    else {
      if (this->matchesAllTypes()) {
        modifier = theirModifier;
        // Omit the type if either input query did, since that indicates that they
        // aren't targeting a browser that requires "all and".
        type = (other->matchesAllTypes() && ourType.empty()) ? "" : theirType;
        sass::vector<sass::string> f1(this->features());
        sass::vector<sass::string> f2(other->features());
        features.insert(features.end(), f1.begin(), f1.end());
        features.insert(features.end(), f2.begin(), f2.end());
      }
      else if (other->matchesAllTypes()) {
        modifier = ourModifier;
        type = ourType;
        sass::vector<sass::string> f1(this->features());
        sass::vector<sass::string> f2(other->features());
        features.insert(features.end(), f1.begin(), f1.end());
        features.insert(features.end(), f2.begin(), f2.end());
      }
      else if (ourType != theirType) {
        return SASS_MEMORY_NEW(CssMediaQuery, pstate());
      }
      else {
        modifier = ourModifier.empty() ? theirModifier : ourModifier;
        type = ourType;
        sass::vector<sass::string> f1(this->features());
        sass::vector<sass::string> f2(other->features());
        features.insert(features.end(), f1.begin(), f1.end());
        features.insert(features.end(), f2.begin(), f2.end());
      }
    }

    CssMediaQuery_Obj query = SASS_MEMORY_NEW(CssMediaQuery, pstate());
    query->modifier(modifier == ourModifier ? this->modifier() : other->modifier());
    query->type(ourType.empty() ? other->type() : this->type());
    query->features(features);
    return query;
  }

  CssMediaQuery::CssMediaQuery(const CssMediaQuery* ptr) :
    AST_Node(*ptr),
    modifier_(ptr->modifier_),
    type_(ptr->type_),
    features_(ptr->features_)
  {
  }

  /////////////////////////////////////////////////////////////////////////
  // ToDo: finalize specificity implementation
  /////////////////////////////////////////////////////////////////////////

  size_t SelectorList::maxSpecificity() const
  {
    size_t specificity = 0;
    for (auto complex : elements()) {
      specificity = std::max(specificity, complex->maxSpecificity());
    }
    return specificity;
  }

  size_t SelectorList::minSpecificity() const
  {
    size_t specificity = 0;
    for (auto complex : elements()) {
      specificity = std::min(specificity, complex->minSpecificity());
    }
    return specificity;
  }

  size_t CompoundSelector::maxSpecificity() const
  {
    size_t specificity = 0;
    for (auto simple : elements()) {
      specificity += simple->maxSpecificity();
    }
    return specificity;
  }

  size_t CompoundSelector::minSpecificity() const
  {
    size_t specificity = 0;
    for (auto simple : elements()) {
      specificity += simple->minSpecificity();
    }
    return specificity;
  }

  size_t ComplexSelector::maxSpecificity() const
  {
    size_t specificity = 0;
    for (auto component : elements()) {
      specificity += component->maxSpecificity();
    }
    return specificity;
  }

  size_t ComplexSelector::minSpecificity() const
  {
    size_t specificity = 0;
    for (auto component : elements()) {
      specificity += component->minSpecificity();
    }
    return specificity;
  }

  /////////////////////////////////////////////////////////////////////////
  // ToDo: this might be done easier with new selector format
  /////////////////////////////////////////////////////////////////////////

  sass::vector<ComplexSelectorObj>
    CompoundSelector::resolve_parent_refs(SelectorStack pstack, Backtraces& traces, bool implicit_parent)
  {

    auto parent = pstack.back();
    sass::vector<ComplexSelectorObj> rv;

    for (SimpleSelectorObj simple : elements()) {
      if (PseudoSelector * pseudo = Cast<PseudoSelector>(simple)) {
        if (SelectorList* sel = Cast<SelectorList>(pseudo->selector())) {
          if (parent) {
            pseudo->selector(sel->resolve_parent_refs(
              pstack, traces, implicit_parent));
          }
        }
      }
    }

    // Mix with parents from stack
    if (hasRealParent()) {

      if (parent.isNull()) {
        return { wrapInComplex() };
      }
      else {
        for (auto complex : parent->elements()) {
          // The parent complex selector has a compound selector
          if (CompoundSelectorObj tail = Cast<CompoundSelector>(complex->last())) {
            // Create a copy to alter it
            complex = SASS_MEMORY_COPY(complex);
            tail = SASS_MEMORY_COPY(tail);

            // Check if we can merge front with back
            if (length() > 0 && tail->length() > 0) {
              SimpleSelectorObj back = tail->last();
              SimpleSelectorObj front = first();
              auto simple_back = Cast<SimpleSelector>(back);
              auto simple_front = Cast<TypeSelector>(front);
              if (simple_front && simple_back) {
                simple_back = SASS_MEMORY_COPY(simple_back);
                auto name = simple_back->name();
                name += simple_front->name();
                simple_back->name(name);
                tail->elements().back() = simple_back;
                tail->elements().insert(tail->end(),
                  begin() + 1, end());
              }
              else {
                tail->concat(this);
              }
            }
            else {
              tail->concat(this);
            }

            complex->elements().back() = tail;
            // Append to results
            rv.push_back(complex);
          }
          else {
            // Can't insert parent that ends with a combinator
            // where the parent selector is followed by something
            if (parent && length() > 0) {
              throw Exception::InvalidParent(parent, traces, this);
            }
            // Create a copy to alter it
            complex = SASS_MEMORY_COPY(complex);
            // Just append ourself
            complex->append(this);
            // Append to results
            rv.push_back(complex);
          }
        }
      }
    }

    // No parents
    else {
      // Create a new wrapper to wrap ourself
      auto complex = SASS_MEMORY_NEW(ComplexSelector, pstate());
      // Just append ourself
      complex->append(this);
      // Append to results
      rv.push_back(complex);
    }

    return rv;

  }

  bool cmpSimpleSelectors(SimpleSelector* a, SimpleSelector* b)
  {
    return (a->getSortOrder() < b->getSortOrder());
  }

  void CompoundSelector::sortChildren()
  {
    std::sort(begin(), end(), cmpSimpleSelectors);
  }

  /* better return sass::vector? only - is empty container anyway? */
  SelectorList* ComplexSelector::resolve_parent_refs(SelectorStack pstack, Backtraces& traces, bool implicit_parent)
  {

    sass::vector<sass::vector<ComplexSelectorObj>> vars;

    auto parent = pstack.back();

    if (has_real_parent_ref() && !parent) {
      throw Exception::TopLevelParent(traces, pstate());
    }

    if (!chroots() && parent) {

      if (!has_real_parent_ref() && !implicit_parent) {
        SelectorList* retval = SASS_MEMORY_NEW(SelectorList, pstate(), 1);
        retval->append(this);
        return retval;
      }

      vars.push_back(parent->elements());
    }

    for (auto sel : elements()) {
      if (CompoundSelectorObj comp = Cast<CompoundSelector>(sel)) {
        auto asd = comp->resolve_parent_refs(pstack, traces, implicit_parent);
        if (asd.size() > 0) vars.push_back(asd);
      }
      else {
        // ToDo: merge together sequences whenever possible
        auto cont = SASS_MEMORY_NEW(ComplexSelector, pstate());
        cont->append(sel);
        vars.push_back({ cont });
      }
    }

    // Need complex selectors to preserve linefeeds
    sass::vector<sass::vector<ComplexSelectorObj>> res = permutateAlt(vars);

    // std::reverse(std::begin(res), std::end(res));

    auto lst = SASS_MEMORY_NEW(SelectorList, pstate());
    for (auto items : res) {
      if (items.size() > 0) {
        ComplexSelectorObj first = SASS_MEMORY_COPY(items[0]);
        first->hasPreLineFeed(first->hasPreLineFeed() || (!has_real_parent_ref() && hasPreLineFeed()));
        // ToDo: remove once we know how to handle line feeds
        // ToDo: currently a mashup between ruby and dart sass
        // if (has_real_parent_ref()) first->has_line_feed(false);
        // first->has_line_break(first->has_line_break() || has_line_break());
        first->chroots(true); // has been resolved by now
        for (size_t i = 1; i < items.size(); i += 1) {
          first->concat(items[i]);
        }
        lst->append(first);
      }
    }

    return lst;

  }

  SelectorList* SelectorList::resolve_parent_refs(SelectorStack pstack, Backtraces& traces, bool implicit_parent)
  {
    SelectorList* rv = SASS_MEMORY_NEW(SelectorList, pstate());
    for (auto sel : elements()) {
      // Note: this one is tricky as we get back a pointer from resolve parents ...
      SelectorListObj res = sel->resolve_parent_refs(pstack, traces, implicit_parent);
      // Note: ... and concat will only append the items in elements
      // Therefore by passing it directly, the container will leak!
      rv->concat(res);
    }
    return rv;
  }

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  IMPLEMENT_AST_OPERATORS(Selector_Schema);
  IMPLEMENT_AST_OPERATORS(PlaceholderSelector);
  IMPLEMENT_AST_OPERATORS(AttributeSelector);
  IMPLEMENT_AST_OPERATORS(TypeSelector);
  IMPLEMENT_AST_OPERATORS(ClassSelector);
  IMPLEMENT_AST_OPERATORS(IDSelector);
  IMPLEMENT_AST_OPERATORS(PseudoSelector);
  IMPLEMENT_AST_OPERATORS(SelectorCombinator);
  IMPLEMENT_AST_OPERATORS(CompoundSelector);
  IMPLEMENT_AST_OPERATORS(ComplexSelector);
  IMPLEMENT_AST_OPERATORS(SelectorList);

}
