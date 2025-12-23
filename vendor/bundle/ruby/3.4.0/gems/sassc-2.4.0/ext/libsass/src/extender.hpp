#ifndef SASS_EXTENDER_H
#define SASS_EXTENDER_H

#include <set>
#include <map>
#include <string>

#include "ast_helpers.hpp"
#include "ast_fwd_decl.hpp"
#include "operation.hpp"
#include "extension.hpp"
#include "backtrace.hpp"
#include "ordered_map.hpp"

namespace Sass {

  // ##########################################################################
  // Different hash map types used by extender
  // ##########################################################################

  // This is special (ptrs!)
  typedef std::unordered_set<
    ComplexSelectorObj,
    ObjPtrHash,
    ObjPtrEquality
  > ExtCplxSelSet;

  typedef std::unordered_set<
    SimpleSelectorObj,
    ObjHash,
    ObjEquality
  > ExtSmplSelSet;

  typedef std::unordered_set<
    SelectorListObj,
    ObjPtrHash,
    ObjPtrEquality
  > ExtListSelSet;

  typedef std::unordered_map<
    SimpleSelectorObj,
    ExtListSelSet,
    ObjHash,
    ObjEquality
  > ExtSelMap;

  typedef ordered_map<
    ComplexSelectorObj,
    Extension,
    ObjHash,
    ObjEquality
  > ExtSelExtMapEntry;

  typedef std::unordered_map<
    SimpleSelectorObj,
    ExtSelExtMapEntry,
    ObjHash,
    ObjEquality
  > ExtSelExtMap;

  typedef std::unordered_map <
    SimpleSelectorObj,
    sass::vector<
      Extension
    >,
    ObjHash,
    ObjEquality
  > ExtByExtMap;

  class Extender : public Operation_CRTP<void, Extender> {

  public:

    enum ExtendMode { TARGETS, REPLACE, NORMAL, };

  private:

    // ##########################################################################
    // The mode that controls this extender's behavior.
    // ##########################################################################
    ExtendMode mode;

    // ##########################################################################
    // Shared backtraces with context and expander. Needed the throw
    // errors when e.g. extending across media query boundaries.
    // ##########################################################################
    Backtraces& traces;

    // ##########################################################################
    // A map from all simple selectors in the stylesheet to the rules that
    // contain them.This is used to find which rules an `@extend` applies to.
    // ##########################################################################
    ExtSelMap selectors;

    // ##########################################################################
    // A map from all extended simple selectors
    // to the sources of those extensions.
    // ##########################################################################
    ExtSelExtMap extensions;

    // ##########################################################################
    // A map from all simple selectors in extenders to
    // the extensions that those extenders define.
    // ##########################################################################
    ExtByExtMap extensionsByExtender;

    // ##########################################################################
    // A map from CSS rules to the media query contexts they're defined in.
    // This tracks the contexts in which each style rule is defined.
    // If a rule is defined at the top level, it doesn't have an entry.
    // ##########################################################################
    ordered_map<
      SelectorListObj,
      CssMediaRuleObj,
      ObjPtrHash,
      ObjPtrEquality
    > mediaContexts;
    
    // ##########################################################################
    // A map from [SimpleSelector]s to the specificity of their source selectors.
    // This tracks the maximum specificity of the [ComplexSelector] that originally 
    // contained each [SimpleSelector]. This allows us to ensure we don't trim any
    // selectors that need to exist to satisfy the [second law that of extend][].
    // [second law of extend]: https://github.com/sass/sass/issues/324#issuecomment-4607184
    // ##########################################################################
    std::unordered_map<
      SimpleSelectorObj,
      size_t,
      ObjPtrHash,
      ObjPtrEquality
    > sourceSpecificity;

    // ##########################################################################
    // A set of [ComplexSelector]s that were originally part of their
    // component [SelectorList]s, as opposed to being added by `@extend`.
    // This allows us to ensure that we don't trim any selectors
    // that need to exist to satisfy the [first law of extend][].
    // ##########################################################################
    ExtCplxSelSet originals;

  public:

    // Constructor without default [mode].
    // [traces] are needed to throw errors.
    Extender(Backtraces& traces);

    // ##########################################################################
    // Constructor with specific [mode].
    // [traces] are needed to throw errors.
    // ##########################################################################
    Extender(ExtendMode mode, Backtraces& traces);

    // ##########################################################################
    // Empty desctructor
    // ##########################################################################
    ~Extender() {};

    // ##########################################################################
    // Extends [selector] with [source] extender and [targets] extendees.
    // This works as though `source {@extend target}` were written in the
    // stylesheet, with the exception that [target] can contain compound
    // selectors which must be extended as a unit.
    // ##########################################################################
    static SelectorListObj extend(
      SelectorListObj& selector,
      const SelectorListObj& source,
      const SelectorListObj& target,
      Backtraces& traces);

    // ##########################################################################
    // Returns a copy of [selector] with [targets] replaced by [source].
    // ##########################################################################
    static SelectorListObj replace(
      SelectorListObj& selector,
      const SelectorListObj& source,
      const SelectorListObj& target,
      Backtraces& traces);

    // ##########################################################################
    // Adds [selector] to this extender, with [selectorSpan] as the span covering
    // the selector and [ruleSpan] as the span covering the entire style rule.
    // Extends [selector] using any registered extensions, then returns an empty
    // [ModifiableCssStyleRule] with the resulting selector. If any more relevant
    // extensions are added, the returned rule is automatically updated.
    // The [mediaContext] is the media query context in which the selector was
    // defined, or `null` if it was defined at the top level of the document.
    // ##########################################################################
    void addSelector(
      const SelectorListObj& selector,
      const CssMediaRuleObj& mediaContext);

    // ##########################################################################
    // Registers the [SimpleSelector]s in [list]
    // to point to [rule] in [selectors].
    // ##########################################################################
    void registerSelector(
      const SelectorListObj& list,
      const SelectorListObj& rule);

    // ##########################################################################
    // Adds an extension to this extender. The [extender] is the selector for the
    // style rule in which the extension is defined, and [target] is the selector
    // passed to `@extend`. The [extend] provides the extend span and indicates 
    // whether the extension is optional. The [mediaContext] defines the media query
    // context in which the extension is defined. It can only extend selectors
    // within the same context. A `null` context indicates no media queries.
    // ##########################################################################
    void addExtension(
      const SelectorListObj& extender,
      const SimpleSelectorObj& target,
      const CssMediaRuleObj& mediaQueryContext,
      bool is_optional = false);

    // ##########################################################################
    // The set of all simple selectors in style rules handled
    // by this extender. This includes simple selectors that
    // were added because of downstream extensions.
    // ##########################################################################
    ExtSmplSelSet getSimpleSelectors() const;

    // ##########################################################################
    // Check for extends that have not been satisfied.
    // Returns true if any non-optional extension did not
    // extend any selector. Updates the passed reference
    // to point to that Extension for further analysis.
    // ##########################################################################
    bool checkForUnsatisfiedExtends(
      Extension& unsatisfied) const;

  private:

    // ##########################################################################
    // A helper function for [extend] and [replace].
    // ##########################################################################
    static SelectorListObj extendOrReplace(
      SelectorListObj& selector,
      const SelectorListObj& source,
      const SelectorListObj& target,
      const ExtendMode mode,
      Backtraces& traces);

    // ##########################################################################
    // Returns an extension that combines [left] and [right]. Throws 
    // a [SassException] if [left] and [right] have incompatible 
    // media contexts. Throws an [ArgumentError] if [left]
    // and [right] don't have the same extender and target.
    // ##########################################################################
    static Extension mergeExtension(
      const Extension& lhs,
      const Extension& rhs);

    // ##########################################################################
    // Extend [extensions] using [newExtensions].
    // ##########################################################################
    // Note: dart-sass throws an error in here
    // ##########################################################################
    void extendExistingStyleRules(
      const ExtListSelSet& rules,
      const ExtSelExtMap& newExtensions);

    // ##########################################################################
    // Extend [extensions] using [newExtensions]. Note that this does duplicate
    // some work done by [_extendExistingStyleRules],  but it's necessary to
    // expand each extension's extender separately without reference to the full
    // selector list, so that relevant results don't get trimmed too early.
    // Returns `null` (Note: empty map) if there are no extensions to add.
    // ##########################################################################
    ExtSelExtMap extendExistingExtensions(
      // Taking in a reference here makes MSVC debug stuck!?
      const sass::vector<Extension>& extensions,
      const ExtSelExtMap& newExtensions);

    // ##########################################################################
    // Extends [list] using [extensions].
    // ##########################################################################
    SelectorListObj extendList(
      const SelectorListObj& list,
      const ExtSelExtMap& extensions,
      const CssMediaRuleObj& mediaContext);

    // ##########################################################################
    // Extends [complex] using [extensions], and
    // returns the contents of a [SelectorList].
    // ##########################################################################
    sass::vector<ComplexSelectorObj> extendComplex(
      // Taking in a reference here makes MSVC debug stuck!?
      const ComplexSelectorObj& list,
      const ExtSelExtMap& extensions,
      const CssMediaRuleObj& mediaQueryContext);

    // ##########################################################################
    // Returns a one-off [Extension] whose
    // extender is composed solely of [simple].
    // ##########################################################################
    Extension extensionForSimple(
      const SimpleSelectorObj& simple) const;

    // ##########################################################################
    // Returns a one-off [Extension] whose extender is composed
    // solely of a compound selector containing [simples].
    // ##########################################################################
    Extension extensionForCompound(
      // Taking in a reference here makes MSVC debug stuck!?
      const sass::vector<SimpleSelectorObj>& simples) const;

    // ##########################################################################
    // Extends [compound] using [extensions], and returns the
    // contents of a [SelectorList]. The [inOriginal] parameter
    // indicates whether this is in an original complex selector,
    // meaning that [compound] should not be trimmed out.
    // ##########################################################################
    sass::vector<ComplexSelectorObj> extendCompound(
      const CompoundSelectorObj& compound,
      const ExtSelExtMap& extensions,
      const CssMediaRuleObj& mediaQueryContext,
      bool inOriginal = false);

    // ##########################################################################
    // Extends [simple] without extending the
    // contents of any selector pseudos it contains.
    // ##########################################################################
    sass::vector<Extension> extendWithoutPseudo(
      const SimpleSelectorObj& simple,
      const ExtSelExtMap& extensions,
      ExtSmplSelSet* targetsUsed) const;

    // ##########################################################################
    // Extends [simple] and also extending the
    // contents of any selector pseudos it contains.
    // ##########################################################################
    sass::vector<sass::vector<Extension>> extendSimple(
      const SimpleSelectorObj& simple,
      const ExtSelExtMap& extensions,
      const CssMediaRuleObj& mediaQueryContext,
      ExtSmplSelSet* targetsUsed);

    // ##########################################################################
    // Inner loop helper for [extendPseudo] function
    // ##########################################################################
    static sass::vector<ComplexSelectorObj> extendPseudoComplex(
      const ComplexSelectorObj& complex,
      const PseudoSelectorObj& pseudo,
      const CssMediaRuleObj& mediaQueryContext);

    // ##########################################################################
    // Extends [pseudo] using [extensions], and returns
    // a list of resulting pseudo selectors.
    // ##########################################################################
    sass::vector<PseudoSelectorObj> extendPseudo(
      const PseudoSelectorObj& pseudo,
      const ExtSelExtMap& extensions,
      const CssMediaRuleObj& mediaQueryContext);

    // ##########################################################################
    // Rotates the element in list from [start] (inclusive) to [end] (exclusive)
    // one index higher, looping the final element back to [start].
    // ##########################################################################
    static void rotateSlice(
      sass::vector<ComplexSelectorObj>& list,
      size_t start, size_t end);

    // ##########################################################################
    // Removes elements from [selectors] if they're subselectors of other
    // elements. The [isOriginal] callback indicates which selectors are
    // original to the document, and thus should never be trimmed.
    // ##########################################################################
    sass::vector<ComplexSelectorObj> trim(
      const sass::vector<ComplexSelectorObj>& selectors,
      const ExtCplxSelSet& set) const;

    // ##########################################################################
    // Returns the maximum specificity of the given [simple] source selector.
    // ##########################################################################
    size_t maxSourceSpecificity(const SimpleSelectorObj& simple) const;

    // ##########################################################################
    // Returns the maximum specificity for sources that went into producing [compound].
    // ##########################################################################
    size_t maxSourceSpecificity(const CompoundSelectorObj& compound) const;

    // ##########################################################################
    // Helper function used as callbacks on lists
    // ##########################################################################
    static bool dontTrimComplex(
      const ComplexSelector* complex2,
      const ComplexSelector* complex1,
      const size_t maxSpecificity);

    // ##########################################################################
    // Helper function used as callbacks on lists
    // ##########################################################################
    static bool hasExactlyOne(const ComplexSelectorObj& vec);
    static bool hasMoreThanOne(const ComplexSelectorObj& vec);

  };

}

#endif
