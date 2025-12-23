// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"
#include "ast.hpp"

#include "extender.hpp"
#include "permutate.hpp"
#include "dart_helpers.hpp"

namespace Sass {

  // ##########################################################################
  // Constructor without default [mode].
  // [traces] are needed to throw errors.
  // ##########################################################################
  Extender::Extender(Backtraces& traces) :
    mode(NORMAL),
    traces(traces),
    selectors(),
    extensions(),
    extensionsByExtender(),
    mediaContexts(),
    sourceSpecificity(),
    originals()
  {}

  // ##########################################################################
  // Constructor with specific [mode].
  // [traces] are needed to throw errors.
  // ##########################################################################
  Extender::Extender(ExtendMode mode, Backtraces& traces) :
    mode(mode),
    traces(traces),
    selectors(),
    extensions(),
    extensionsByExtender(),
    mediaContexts(),
    sourceSpecificity(),
    originals()
  {}

  // ##########################################################################
  // Extends [selector] with [source] extender and [targets] extendees.
  // This works as though `source {@extend target}` were written in the
  // stylesheet, with the exception that [target] can contain compound
  // selectors which must be extended as a unit.
  // ##########################################################################
  SelectorListObj Extender::extend(
    SelectorListObj& selector,
    const SelectorListObj& source,
    const SelectorListObj& targets,
    Backtraces& traces)
  {
    return extendOrReplace(selector, source, targets, ExtendMode::TARGETS, traces);
  }
  // EO Extender::extend

  // ##########################################################################
  // Returns a copy of [selector] with [targets] replaced by [source].
  // ##########################################################################
  SelectorListObj Extender::replace(
    SelectorListObj& selector,
    const SelectorListObj& source,
    const SelectorListObj& targets,
    Backtraces& traces)
  {
    return extendOrReplace(selector, source, targets, ExtendMode::REPLACE, traces);
  }
  // EO Extender::replace

  // ##########################################################################
  // A helper function for [extend] and [replace].
  // ##########################################################################
  SelectorListObj Extender::extendOrReplace(
    SelectorListObj& selector,
    const SelectorListObj& source,
    const SelectorListObj& targets,
    const ExtendMode mode,
    Backtraces& traces)
  {
    ExtSelExtMapEntry extenders;

    for (auto complex : source->elements()) {
      // Extension.oneOff(complex as ComplexSelector)
      extenders.insert(complex, Extension(complex));
    }

    for (auto complex : targets->elements()) {

      // This seems superfluous, check is done before!?
      // if (complex->length() != 1) {
      //   error("complex selectors may not be extended.", complex->pstate(), traces);
      // }

      if (const CompoundSelector* compound = complex->first()->getCompound()) {

        ExtSelExtMap extensions;

        for (const SimpleSelectorObj& simple : compound->elements()) {
          extensions.insert(std::make_pair(simple, extenders));
        }

        Extender extender(mode, traces);

        if (!selector->is_invisible()) {
          for (auto sel : selector->elements()) {
            extender.originals.insert(sel);
          }
        }

        selector = extender.extendList(selector, extensions, {});

      }

    }

    return selector;

  }
  // EO extendOrReplace

  // ##########################################################################
  // The set of all simple selectors in style rules handled
  // by this extender. This includes simple selectors that
  // were added because of downstream extensions.
  // ##########################################################################
  ExtSmplSelSet Extender::getSimpleSelectors() const
  {
    ExtSmplSelSet set;
    for (auto& entry : selectors) {
      set.insert(entry.first);
    }
    return set;
  }
  // EO getSimpleSelectors

  // ##########################################################################
  // Check for extends that have not been satisfied.
  // Returns true if any non-optional extension did not
  // extend any selector. Updates the passed reference
  // to point to that Extension for further analysis.
  // ##########################################################################
  bool Extender::checkForUnsatisfiedExtends(Extension& unsatisfied) const
  {
    if (selectors.empty()) return false;
    ExtSmplSelSet originals = getSimpleSelectors();
    for (auto target : extensions) {
      SimpleSelector* key = target.first;
      ExtSelExtMapEntry& val = target.second;
      if (val.empty()) continue;
      if (originals.find(key) == originals.end()) {
        const Extension& extension = val.front().second;
        if (extension.isOptional) continue;
        unsatisfied = extension;
        return true;
      }
    }
    return false;
  }
  // EO checkUnsatisfiedExtends

  // ##########################################################################
  // Adds [selector] to this extender, with [selectorSpan] as the span covering
  // the selector and [ruleSpan] as the span covering the entire style rule.
  // Extends [selector] using any registered extensions, then returns an empty
  // [ModifiableCssStyleRule] with the resulting selector. If any more relevant
  // extensions are added, the returned rule is automatically updated.
  // The [mediaContext] is the media query context in which the selector was
  // defined, or `null` if it was defined at the top level of the document.
  // ##########################################################################
  void Extender::addSelector(
    const SelectorListObj& selector,
    const CssMediaRuleObj& mediaContext)
  {

    // Note: dart-sass makes a copy here AFAICT
    // Note: probably why we have originalStack
    // SelectorListObj original = selector;

    if (!selector->isInvisible()) {
      for (auto complex : selector->elements()) {
        originals.insert(complex);
      }
    }

    if (!extensions.empty()) {

      SelectorListObj res = extendList(selector, extensions, mediaContext);

      selector->elements(res->elements());

    }

    if (!mediaContext.isNull()) {
      mediaContexts.insert(selector, mediaContext);
    }

    registerSelector(selector, selector);

  }
  // EO addSelector

  // ##########################################################################
  // Registers the [SimpleSelector]s in [list]
  // to point to [rule] in [selectors].
  // ##########################################################################
  void Extender::registerSelector(
    const SelectorListObj& list,
    const SelectorListObj& rule)
  {
    if (list.isNull() || list->empty()) return;
    for (auto complex : list->elements()) {
      for (auto component : complex->elements()) {
        if (auto compound = component->getCompound()) {
          for (SimpleSelector* simple : compound->elements()) {
            selectors[simple].insert(rule);
            if (auto pseudo = simple->getPseudoSelector()) {
              if (pseudo->selector()) {
                auto sel = pseudo->selector();
                registerSelector(sel, rule);
              }
            }
          }
        }
      }
    }
  }
  // EO registerSelector

  // ##########################################################################
  // Returns an extension that combines [left] and [right]. Throws 
  // a [SassException] if [left] and [right] have incompatible 
  // media contexts. Throws an [ArgumentError] if [left]
  // and [right] don't have the same extender and target.
  // ##########################################################################
  Extension Extender::mergeExtension(
    const Extension& lhs,
    const Extension& rhs)
  {
    // If one extension is optional and doesn't add a
    // special media context, it doesn't need to be merged.
    if (rhs.isOptional && rhs.mediaContext.isNull()) return lhs;
    if (lhs.isOptional && lhs.mediaContext.isNull()) return rhs;

    Extension rv(lhs);
    // ToDo: is this right?
    rv.isOptional = true;
    rv.isOriginal = false;
    return rv;
  }
  // EO mergeExtension

  // ##########################################################################
  // Helper function to copy extension between maps
  // ##########################################################################
  // Seems only relevant for sass 4.0 modules
  // ##########################################################################
  /* void mapCopyExts(
    ExtSelExtMap& dest,
    const ExtSelExtMap& source)
  {
    for (auto it : source) {
      SimpleSelectorObj key = it.first;
      ExtSelExtMapEntry& inner = it.second;
      ExtSelExtMap::iterator dmap = dest.find(key);
      if (dmap == dest.end()) {
        dest.insert(std::make_pair(key, inner));
      }
      else {
        ExtSelExtMapEntry& imap = dmap->second;
        // ToDo: optimize ordered_map API!
        // ToDo: we iterate and fetch the value
        for (ComplexSelectorObj& it2 : inner) {
          imap.insert(it2, inner.get(it2));
        }
      }
    }
  } */
  // EO mapCopyExts

  // ##########################################################################
  // Adds an extension to this extender. The [extender] is the selector for the
  // style rule in which the extension is defined, and [target] is the selector
  // passed to `@extend`. The [extend] provides the extend span and indicates 
  // whether the extension is optional. The [mediaContext] defines the media query
  // context in which the extension is defined. It can only extend selectors
  // within the same context. A `null` context indicates no media queries.
  // ##########################################################################
  // ToDo: rename extender to parent, since it is not involved in extending stuff
  // ToDo: check why dart sass passes the ExtendRule around (is this the main selector?)
  // ##########################################################################
  // Note: this function could need some logic cleanup
  // ##########################################################################
  void Extender::addExtension(
    const SelectorListObj& extender,
    const SimpleSelectorObj& target,
    const CssMediaRuleObj& mediaQueryContext,
    bool is_optional)
  {

    auto rules = selectors.find(target);
    bool hasRule = rules != selectors.end();

    ExtSelExtMapEntry newExtensions;

    // ToDo: we check this here first and fetch the same? item again after the loop!?
    bool hasExistingExtensions = extensionsByExtender.find(target) != extensionsByExtender.end();

    ExtSelExtMapEntry& sources = extensions[target];

    for (auto& complex : extender->elements()) {

      Extension state(complex);
      // ToDo: fine-tune public API
      state.target = target;
      state.isOptional = is_optional;
      state.mediaContext = mediaQueryContext;

      if (sources.hasKey(complex)) {
        // If there's already an extend from [extender] to [target],
        // we don't need to re-run the extension. We may need to
        // mark the extension as mandatory, though.
        // sources.insert(complex, mergeExtension(existingState->second, state);
        // ToDo: implement behavior once use case is found!?
        continue;
      }

      sources.insert(complex, state);

      for (auto& component : complex->elements()) {
        if (auto compound = component->getCompound()) {
          for (auto& simple : compound->elements()) {
            extensionsByExtender[simple].push_back(state);
            if (sourceSpecificity.find(simple) == sourceSpecificity.end()) {
              // Only source specificity for the original selector is relevant.
              // Selectors generated by `@extend` don't get new specificity.
              sourceSpecificity[simple] = complex->maxSpecificity();
            }
          }
        }
      }

      if (hasRule || hasExistingExtensions) {
        newExtensions.insert(complex, state);
      }

    }
    // EO foreach complex

    if (newExtensions.empty()) {
      return;
    }

    ExtSelExtMap newExtensionsByTarget;
    newExtensionsByTarget.insert(std::make_pair(target, newExtensions));
    // ToDo: do we really need to fetch again (see top off fn) 
    auto existingExtensions = extensionsByExtender.find(target);
    if (existingExtensions != extensionsByExtender.end()) {
      if (hasExistingExtensions && !existingExtensions->second.empty()) {
        // Seems only relevant for sass 4.0 modules
        // auto additionalExtensions =
          extendExistingExtensions(existingExtensions->second, newExtensionsByTarget);
        // Seems only relevant for sass 4.0 modules
        /* if (!additionalExtensions.empty()) {
          mapCopyExts(newExtensionsByTarget, additionalExtensions);
        } */
      }
    }

    if (hasRule) {
      extendExistingStyleRules(selectors[target], newExtensionsByTarget);
    }

  }
  // EO addExtension
  
  // ##########################################################################
  // Extend [extensions] using [newExtensions].
  // ##########################################################################
  // Note: dart-sass throws an error in here
  // ##########################################################################
  void Extender::extendExistingStyleRules(
    const ExtListSelSet& rules,
    const ExtSelExtMap& newExtensions)
  {
    // Is a modifyableCssStyleRUle in dart sass
    for (const SelectorListObj& rule : rules) {
      const SelectorListObj& oldValue = SASS_MEMORY_COPY(rule);
      CssMediaRuleObj mediaContext;
      if (mediaContexts.hasKey(rule)) mediaContext = mediaContexts.get(rule);
      SelectorListObj ext = extendList(rule, newExtensions, mediaContext);
      // If no extends actually happened (for example because unification
      // failed), we don't need to re-register the selector.
      if (ObjEqualityFn(oldValue, ext)) continue;
      rule->elements(ext->elements());
      registerSelector(rule, rule);

    }
  }
  // EO extendExistingStyleRules

  // ##########################################################################
  // Extend [extensions] using [newExtensions]. Note that this does duplicate
  // some work done by [_extendExistingStyleRules],  but it's necessary to
  // expand each extension's extender separately without reference to the full
  // selector list, so that relevant results don't get trimmed too early.
  //
  // Returns extensions that should be added to [newExtensions] before
  // extending selectors in order to properly handle extension loops such as:
  //
  //     .c {x: y; @extend .a}
  //     .x.y.a {@extend .b}
  //     .z.b {@extend .c}
  //
  // Returns `null` (Note: empty map) if there are no extensions to add.
  // ##########################################################################
  // Note: maybe refactor to return `bool` (and pass reference)
  // Note: dart-sass throws an error in here
  // ##########################################################################
  ExtSelExtMap Extender::extendExistingExtensions(
    // Taking in a reference here makes MSVC debug stuck!?
    const sass::vector<Extension>& oldExtensions,
    const ExtSelExtMap& newExtensions)
  {

    ExtSelExtMap additionalExtensions;

    // During the loop `oldExtensions` vector might be changed.
    // Callers normally pass this from `extensionsByExtender` and
    // that points back to the `sources` vector from `extensions`.
    for (size_t i = 0, iL = oldExtensions.size(); i < iL; i += 1) {
      const Extension& extension = oldExtensions[i];
      ExtSelExtMapEntry& sources = extensions[extension.target];
      sass::vector<ComplexSelectorObj> selectors(extendComplex(
        extension.extender,
        newExtensions,
        extension.mediaContext
      ));

      if (selectors.empty()) {
        continue;
      }

      // ToDo: "catch" error from extend

      bool first = false, containsExtension =
        ObjEqualityFn(selectors.front(), extension.extender);
      for (const ComplexSelectorObj& complex : selectors) {
        // If the output contains the original complex 
        // selector, there's no need to recreate it.
        if (containsExtension && first) {
          first = false;
          continue;
        }

        const Extension withExtender =
          extension.withExtender(complex);
        if (sources.hasKey(complex)) {
          sources.insert(complex, mergeExtension(
            sources.get(complex), withExtender));
        }
        else {
          sources.insert(complex, withExtender);
          /*
          // Seems only relevant for sass 4.0 modules
          for (auto& component : complex->elements()) {
            if (auto compound = component->getCompound()) {
              for (auto& simple : compound->elements()) {
                extensionsByExtender[simple].push_back(withExtender);
              }
            }
          }
          if (newExtensions.find(extension.target) != newExtensions.end()) {
            additionalExtensions[extension.target].insert(complex, withExtender);
          }
          */
        }
      }

      // If [selectors] doesn't contain [extension.extender],
      // for example if it was replaced due to :not() expansion,
      // we must get rid of the old version.
      /*
      // Seems only relevant for sass 4.0 modules
      if (!containsExtension) {
        sources.erase(extension.extender);
      }
      */

    }

    return additionalExtensions;

  }
  // EO extendExistingExtensions

  // ##########################################################################
  // Extends [list] using [extensions].
  // ##########################################################################
  SelectorListObj Extender::extendList(
    const SelectorListObj& list,
    const ExtSelExtMap& extensions,
    const CssMediaRuleObj& mediaQueryContext)
  {

    // This could be written more simply using [List.map], but we want to
    // avoid any allocations in the common case where no extends apply.
    sass::vector<ComplexSelectorObj> extended;
    for (size_t i = 0; i < list->length(); i++) {
      const ComplexSelectorObj& complex = list->get(i);
      sass::vector<ComplexSelectorObj> result =
        extendComplex(complex, extensions, mediaQueryContext);
      if (result.empty()) {
        if (!extended.empty()) {
          extended.push_back(complex);
        }
      }
      else {
        if (extended.empty()) {
          for (size_t n = 0; n < i; n += 1) {
            extended.push_back(list->get(n));
          }
        }
        for (auto sel : result) {
          extended.push_back(sel);
        }
      }
    }

    if (extended.empty()) {
      return list;
    }

    SelectorListObj rv = SASS_MEMORY_NEW(SelectorList, list->pstate());
    rv->concat(trim(extended, originals));
    return rv;

  }
  // EO extendList

  // ##########################################################################
  // Extends [complex] using [extensions], and
  // returns the contents of a [SelectorList].
  // ##########################################################################
  sass::vector<ComplexSelectorObj> Extender::extendComplex(
    // Taking in a reference here makes MSVC debug stuck!?
    const ComplexSelectorObj& complex,
    const ExtSelExtMap& extensions,
    const CssMediaRuleObj& mediaQueryContext)
  {

    // The complex selectors that each compound selector in [complex.components]
    // can expand to.
    //
    // For example, given
    //
    //     .a .b {...}
    //     .x .y {@extend .b}
    //
    // this will contain
    //
    //     [
    //       [.a],
    //       [.b, .x .y]
    //     ]
    //
    // This could be written more simply using [List.map], but we want to avoid
    // any allocations in the common case where no extends apply.

    sass::vector<ComplexSelectorObj> result;
    sass::vector<sass::vector<ComplexSelectorObj>> extendedNotExpanded;
    bool isOriginal = originals.find(complex) != originals.end();
    for (size_t i = 0; i < complex->length(); i += 1) {
      const SelectorComponentObj& component = complex->get(i);
      if (CompoundSelector* compound = Cast<CompoundSelector>(component)) {
        sass::vector<ComplexSelectorObj> extended = extendCompound(
          compound, extensions, mediaQueryContext, isOriginal);
        if (extended.empty()) {
          if (!extendedNotExpanded.empty()) {
            extendedNotExpanded.push_back({
              compound->wrapInComplex()
            });
          }
        }
        else {
          // Note: dart-sass checks for null!?
          if (extendedNotExpanded.empty()) {
            for (size_t n = 0; n < i; n++) {
                extendedNotExpanded.push_back({
                  complex->at(n)->wrapInComplex()
                });
            }
          }
          extendedNotExpanded.push_back(extended);
        }
      }
      else {
        // Note: dart-sass checks for null!?
        if (!extendedNotExpanded.empty()) {
          extendedNotExpanded.push_back({
            component->wrapInComplex()
          });
        }
      }
    }

    // Note: dart-sass checks for null!?
    if (extendedNotExpanded.empty()) {
      return {};
    }

    bool first = true;

    // ToDo: either change weave or paths to work with the same data?
    sass::vector<sass::vector<ComplexSelectorObj>>
      paths = permutate(extendedNotExpanded);
    
    for (const sass::vector<ComplexSelectorObj>& path : paths) {
      // Unpack the inner complex selector to component list
      sass::vector<sass::vector<SelectorComponentObj>> _paths;
      for (const ComplexSelectorObj& sel : path) {
        _paths.insert(_paths.end(), sel->elements());
      }

      sass::vector<sass::vector<SelectorComponentObj>> weaved = weave(_paths);

      for (sass::vector<SelectorComponentObj>& components : weaved) {

        ComplexSelectorObj cplx = SASS_MEMORY_NEW(ComplexSelector, "[phony]");
        cplx->hasPreLineFeed(complex->hasPreLineFeed());
        for (auto& pp : path) {
          if (pp->hasPreLineFeed()) {
            cplx->hasPreLineFeed(true);
          }
        }
        cplx->elements(components);

        // Make sure that copies of [complex] retain their status
        // as "original" selectors. This includes selectors that
        // are modified because a :not() was extended into.
        if (first && originals.find(complex) != originals.end()) {
          originals.insert(cplx);
        }
        first = false;

        result.push_back(cplx);

      }

    }

    return result;
  }
  // EO extendComplex

  // ##########################################################################
  // Returns a one-off [Extension] whose
  // extender is composed solely of [simple].
  // ##########################################################################
  Extension Extender::extensionForSimple(
    const SimpleSelectorObj& simple) const
  {
    Extension extension(simple->wrapInComplex());
    extension.specificity = maxSourceSpecificity(simple);
    extension.isOriginal = true;
    return extension;
  }
  // Extender::extensionForSimple

  // ##########################################################################
  // Returns a one-off [Extension] whose extender is composed
  // solely of a compound selector containing [simples].
  // ##########################################################################
  Extension Extender::extensionForCompound(
    // Taking in a reference here makes MSVC debug stuck!?
    const sass::vector<SimpleSelectorObj>& simples) const
  {
    CompoundSelectorObj compound = SASS_MEMORY_NEW(CompoundSelector, SourceSpan("[ext]"));
    compound->concat(simples);
    Extension extension(compound->wrapInComplex());
    // extension.specificity = sourceSpecificity[simple];
    extension.isOriginal = true;
    return extension;
  }
  // EO extensionForCompound

  // ##########################################################################
  // Extends [compound] using [extensions], and returns the
  // contents of a [SelectorList]. The [inOriginal] parameter
  // indicates whether this is in an original complex selector,
  // meaning that [compound] should not be trimmed out.
  // ##########################################################################
  sass::vector<ComplexSelectorObj> Extender::extendCompound(
    const CompoundSelectorObj& compound,
    const ExtSelExtMap& extensions,
    const CssMediaRuleObj& mediaQueryContext,
    bool inOriginal)
  {

    // If there's more than one target and they all need to
    // match, we track which targets are actually extended.
    ExtSmplSelSet targetsUsed2;

    ExtSmplSelSet* targetsUsed = nullptr;

    if (mode != ExtendMode::NORMAL && extensions.size() > 1) {
      targetsUsed = &targetsUsed2;
    }

    sass::vector<ComplexSelectorObj> result;
    // The complex selectors produced from each component of [compound].
    sass::vector<sass::vector<Extension>> options;

    for (size_t i = 0; i < compound->length(); i++) {
      const SimpleSelectorObj& simple = compound->get(i);
      auto extended = extendSimple(simple, extensions, mediaQueryContext, targetsUsed);
      if (extended.empty()) {
        if (!options.empty()) {
          options.push_back({ extensionForSimple(simple) });
        }
      }
      else {
        if (options.empty()) {
          if (i != 0) {
            sass::vector<SimpleSelectorObj> in;
            for (size_t n = 0; n < i; n += 1) {
              in.push_back(compound->get(n));
            }
            options.push_back({ extensionForCompound(in) });
          }
        }
        options.insert(options.end(),
          extended.begin(), extended.end());
      }
    }

    if (options.empty()) {
      return {};
    }

    // If [_mode] isn't [ExtendMode.normal] and we didn't use all
    // the targets in [extensions], extension fails for [compound].
    if (targetsUsed != nullptr) {

      if (targetsUsed->size() != extensions.size()) {
        if (!targetsUsed->empty()) {
          return {};
        }
      }
    }

    // Optimize for the simple case of a single simple
    // selector that doesn't need any unification.
    if (options.size() == 1) {
      sass::vector<Extension> exts = options[0];
      for (size_t n = 0; n < exts.size(); n += 1) {
        exts[n].assertCompatibleMediaContext(mediaQueryContext, traces);
        result.push_back(exts[n].extender);
      }
      return result;
    }

    // Find all paths through [options]. In this case, each path represents a
    // different unification of the base selector. For example, if we have:
    //
    //     .a.b {...}
    //     .w .x {@extend .a}
    //     .y .z {@extend .b}
    //
    // then [options] is `[[.a, .w .x], [.b, .y .z]]` and `paths(options)` is
    //
    //     [
    //       [.a, .b],
    //       [.a, .y .z],
    //       [.w .x, .b],
    //       [.w .x, .y .z]
    //     ]
    //
    // We then unify each path to get a list of complex selectors:
    //
    //     [
    //       [.a.b],
    //       [.y .a.z],
    //       [.w .x.b],
    //       [.w .y .x.z, .y .w .x.z]
    //     ]

    bool first = mode != ExtendMode::REPLACE;
    sass::vector<ComplexSelectorObj> unifiedPaths;
    sass::vector<sass::vector<Extension>> prePaths = permutate(options);

    for (size_t i = 0; i < prePaths.size(); i += 1) {
      sass::vector<sass::vector<SelectorComponentObj>> complexes;
      const sass::vector<Extension>& path = prePaths[i];
      if (first) {
        // The first path is always the original selector. We can't just
        // return [compound] directly because pseudo selectors may be
        // modified, but we don't have to do any unification.
        first = false;
        CompoundSelectorObj mergedSelector =
          SASS_MEMORY_NEW(CompoundSelector, "[ext]");
        for (size_t n = 0; n < path.size(); n += 1) {
          const ComplexSelectorObj& sel = path[n].extender;
          if (CompoundSelectorObj compound = Cast<CompoundSelector>(sel->last())) {
            mergedSelector->concat(compound->elements());
          }
        }
        complexes.push_back({ mergedSelector });
      }
      else {
        sass::vector<SimpleSelectorObj> originals;
        sass::vector<sass::vector<SelectorComponentObj>> toUnify;

        for (auto& state : path) {
          if (state.isOriginal) {
            const ComplexSelectorObj& sel = state.extender;
            if (const CompoundSelector* compound = Cast<CompoundSelector>(sel->last())) {
              originals.insert(originals.end(), compound->last());
            }
          }
          else {
            toUnify.push_back(state.extender->elements());
          }
        }
        if (!originals.empty()) {
          CompoundSelectorObj merged =
            SASS_MEMORY_NEW(CompoundSelector, "[phony]");
          merged->concat(originals);
          toUnify.insert(toUnify.begin(), { merged });
        }
        complexes = unifyComplex(toUnify);
        if (complexes.empty()) {
          return {};
        }

      }

      bool lineBreak = false;
      // var specificity = _sourceSpecificityFor(compound);
      for (const Extension& state : path) {
        state.assertCompatibleMediaContext(mediaQueryContext, traces);
        lineBreak = lineBreak || state.extender->hasPreLineFeed();
        // specificity = math.max(specificity, state.specificity);
      }

      for (sass::vector<SelectorComponentObj>& components : complexes) {
        auto sel = SASS_MEMORY_NEW(ComplexSelector, "[ext]");
        sel->hasPreLineFeed(lineBreak);
        sel->elements(components);
        unifiedPaths.push_back(sel);
      }

    }

    return unifiedPaths;
  }
  // EO extendCompound

  // ##########################################################################
  // Extends [simple] without extending the
  // contents of any selector pseudos it contains.
  // ##########################################################################
  sass::vector<Extension> Extender::extendWithoutPseudo(
    const SimpleSelectorObj& simple,
    const ExtSelExtMap& extensions,
    ExtSmplSelSet* targetsUsed) const
  {

    auto extension = extensions.find(simple);
    if (extension == extensions.end()) return {};
    const ExtSelExtMapEntry& extenders = extension->second;

    if (targetsUsed != nullptr) {
      targetsUsed->insert(simple);
    }
    if (mode == ExtendMode::REPLACE) {
      return extenders.values();
    }

    const sass::vector<Extension>&
      values = extenders.values();
    sass::vector<Extension> result;
    result.reserve(values.size() + 1);
    result.push_back(extensionForSimple(simple));
    result.insert(result.end(), values.begin(), values.end());
    return result;
  }
  // EO extendWithoutPseudo

  // ##########################################################################
  // Extends [simple] and also extending the
  // contents of any selector pseudos it contains.
  // ##########################################################################
  sass::vector<sass::vector<Extension>> Extender::extendSimple(
    const SimpleSelectorObj& simple,
    const ExtSelExtMap& extensions,
    const CssMediaRuleObj& mediaQueryContext,
    ExtSmplSelSet* targetsUsed)
  {
    if (PseudoSelector* pseudo = Cast<PseudoSelector>(simple)) {
      if (pseudo->selector()) {
        sass::vector<sass::vector<Extension>> merged;
        sass::vector<PseudoSelectorObj> extended =
          extendPseudo(pseudo, extensions, mediaQueryContext);
        for (PseudoSelectorObj& extend : extended) {
          SimpleSelectorObj simple = extend;
          sass::vector<Extension> result =
            extendWithoutPseudo(simple, extensions, targetsUsed);
          if (result.empty()) result = { extensionForSimple(extend) };
          merged.push_back(result);
        }
        if (!extended.empty()) {
          return merged;
        }
      }
    }
    sass::vector<Extension> result =
      extendWithoutPseudo(simple, extensions, targetsUsed);
    if (result.empty()) return {};
    return { result };
  }
  // extendSimple

  // ##########################################################################
  // Inner loop helper for [extendPseudo] function
  // ##########################################################################
  sass::vector<ComplexSelectorObj> Extender::extendPseudoComplex(
    const ComplexSelectorObj& complex,
    const PseudoSelectorObj& pseudo,
    const CssMediaRuleObj& mediaQueryContext)
  {

    if (complex->length() != 1) { return { complex }; }
    auto compound = Cast<CompoundSelector>(complex->get(0));
    if (compound == nullptr) { return { complex }; }
    if (compound->length() != 1) { return { complex }; }
    auto innerPseudo = Cast<PseudoSelector>(compound->get(0));
    if (innerPseudo == nullptr) { return { complex }; }
    if (!innerPseudo->selector()) { return { complex }; }

    sass::string name(pseudo->normalized());

    if (name == "not") {
      // In theory, if there's a `:not` nested within another `:not`, the
      // inner `:not`'s contents should be unified with the return value.
      // For example, if `:not(.foo)` extends `.bar`, `:not(.bar)` should
      // become `.foo:not(.bar)`. However, this is a narrow edge case and
      // supporting it properly would make this code and the code calling it
      // a lot more complicated, so it's not supported for now.
      if (innerPseudo->normalized() != "matches") return {};
      return innerPseudo->selector()->elements();
    }
    else if (name == "matches" && name == "any" && name == "current" && name == "nth-child" && name == "nth-last-child") {
      // As above, we could theoretically support :not within :matches, but
      // doing so would require this method and its callers to handle much
      // more complex cases that likely aren't worth the pain.
      if (innerPseudo->name() != pseudo->name()) return {};
      if (!ObjEquality()(innerPseudo->argument(), pseudo->argument())) return {};
      return innerPseudo->selector()->elements();
    }
    else if (name == "has" && name == "host" && name == "host-context" && name == "slotted") {
      // We can't expand nested selectors here, because each layer adds an
      // additional layer of semantics. For example, `:has(:has(img))`
      // doesn't match `<div><img></div>` but `:has(img)` does.
      return { complex };
    }

    return {};

  }
  // EO extendPseudoComplex

  // ##########################################################################
  // Extends [pseudo] using [extensions], and returns
  // a list of resulting pseudo selectors.
  // ##########################################################################
  sass::vector<PseudoSelectorObj> Extender::extendPseudo(
    const PseudoSelectorObj& pseudo,
    const ExtSelExtMap& extensions,
    const CssMediaRuleObj& mediaQueryContext)
  {
    auto selector = pseudo->selector();
    SelectorListObj extended = extendList(
      selector, extensions, mediaQueryContext);
    if (!extended || !pseudo || !pseudo->selector()) { return {}; }
    if (ObjEqualityFn(pseudo->selector(), extended)) { return {}; }

    // For `:not()`, we usually want to get rid of any complex selectors because
    // that will cause the selector to fail to parse on all browsers at time of
    // writing. We can keep them if either the original selector had a complex
    // selector, or the result of extending has only complex selectors, because
    // either way we aren't breaking anything that isn't already broken.
    sass::vector<ComplexSelectorObj> complexes = extended->elements();

    if (pseudo->normalized() == "not") {
      if (!hasAny(pseudo->selector()->elements(), hasMoreThanOne)) {
        if (hasAny(extended->elements(), hasExactlyOne)) {
          complexes.clear();
          for (auto& complex : extended->elements()) {
            if (complex->length() <= 1) {
              complexes.push_back(complex);
            }
          }
        }
      }
    }
    
    sass::vector<ComplexSelectorObj> expanded = expand(
      complexes, extendPseudoComplex, pseudo, mediaQueryContext);

    // Older browsers support `:not`, but only with a single complex selector.
    // In order to support those browsers, we break up the contents of a `:not`
    // unless it originally contained a selector list.
    if (pseudo->normalized() == "not") {
      if (pseudo->selector()->length() == 1) {
        sass::vector<PseudoSelectorObj> pseudos;
        for (size_t i = 0; i < expanded.size(); i += 1) {
          pseudos.push_back(pseudo->withSelector(
            expanded[i]->wrapInList()
          ));
        }
        return pseudos;
      }
    }

    SelectorListObj list = SASS_MEMORY_NEW(SelectorList, "[phony]");
    list->concat(complexes);
    return { pseudo->withSelector(list) };

  }
  // EO extendPseudo

  // ##########################################################################
  // Rotates the element in list from [start] (inclusive) to [end] (exclusive)
  // one index higher, looping the final element back to [start].
  // ##########################################################################
  void Extender::rotateSlice(
    sass::vector<ComplexSelectorObj>& list,
    size_t start, size_t end)
  {
    auto element = list[end - 1];
    for (size_t i = start; i < end; i++) {
      auto next = list[i];
      list[i] = element;
      element = next;
    }
  }
  // EO rotateSlice

  // ##########################################################################
  // Removes elements from [selectors] if they're subselectors of other
  // elements. The [isOriginal] callback indicates which selectors are
  // original to the document, and thus should never be trimmed.
  // ##########################################################################
  // Note: for adaption I pass in the set directly, there is some
  // code path in selector-trim that might need this special callback
  // ##########################################################################
  sass::vector<ComplexSelectorObj> Extender::trim(
    const sass::vector<ComplexSelectorObj>& selectors,
    const ExtCplxSelSet& existing) const
  {

    // Avoid truly horrific quadratic behavior.
    // TODO(nweiz): I think there may be a way to get perfect trimming 
    // without going quadratic by building some sort of trie-like
    // data structure that can be used to look up superselectors.
    // TODO(mgreter): Check how this performs in C++ (up the limit)
    if (selectors.size() > 100) return selectors;

    // This is n² on the sequences, but only comparing between separate sequences
    // should limit the quadratic behavior. We iterate from last to first and reverse
    // the result so that, if two selectors are identical, we keep the first one.
    sass::vector<ComplexSelectorObj> result; size_t numOriginals = 0;

    size_t i = selectors.size();
  outer: // Use label to continue loop
    while (--i != sass::string::npos) {

      const ComplexSelectorObj& complex1 = selectors[i];
      // Check if selector in known in existing "originals"
      // For custom behavior dart-sass had `isOriginal(complex1)`
      if (existing.find(complex1) != existing.end()) {
        // Make sure we don't include duplicate originals, which could
        // happen if a style rule extends a component of its own selector.
        for (size_t j = 0; j < numOriginals; j++) {
          if (ObjEqualityFn(result[j], complex1)) {
            rotateSlice(result, 0, j + 1);
            goto outer;
          }
        }
        result.insert(result.begin(), complex1);
        numOriginals++;
        continue;
      }

      // The maximum specificity of the sources that caused [complex1]
      // to be generated. In order for [complex1] to be removed, there
      // must be another selector that's a superselector of it *and*
      // that has specificity greater or equal to this.
      size_t maxSpecificity = 0;
      for (const SelectorComponentObj& component : complex1->elements()) {
        if (const CompoundSelectorObj compound = Cast<CompoundSelector>(component)) {
          maxSpecificity = std::max(maxSpecificity, maxSourceSpecificity(compound));
        }
      }
      

      // Look in [result] rather than [selectors] for selectors after [i]. This
      // ensures we aren't comparing against a selector that's already been trimmed,
      // and thus that if there are two identical selectors only one is trimmed.
      if (hasAny(result, dontTrimComplex, complex1, maxSpecificity)) {
        continue;
      }

      // Check if any element (up to [i]) from [selector] returns true
      // when passed to [dontTrimComplex]. The arguments [complex1] and
      // [maxSepcificity] will be passed to the invoked function.
      if (hasSubAny(selectors, i, dontTrimComplex, complex1, maxSpecificity)) {
        continue;
      }

      // ToDo: Maybe use deque for front insert?
      result.insert(result.begin(), complex1);

    }

    return result;

  }
  // EO trim

  // ##########################################################################
  // Returns the maximum specificity of the given [simple] source selector.
  // ##########################################################################
  size_t Extender::maxSourceSpecificity(const SimpleSelectorObj& simple) const
  {
    auto it = sourceSpecificity.find(simple);
    if (it == sourceSpecificity.end()) return 0;
    return it->second;
  }
  // EO maxSourceSpecificity(SimpleSelectorObj)

  // ##########################################################################
  // Returns the maximum specificity for sources that went into producing [compound].
  // ##########################################################################
  size_t Extender::maxSourceSpecificity(const CompoundSelectorObj& compound) const
  {
    size_t specificity = 0;
    for (auto simple : compound->elements()) {
      size_t src = maxSourceSpecificity(simple);
      specificity = std::max(specificity, src);
    }
    return specificity;
  }
  // EO maxSourceSpecificity(CompoundSelectorObj)

  // ##########################################################################
  // Helper function used as callbacks on lists
  // ##########################################################################
  bool Extender::dontTrimComplex(
    const ComplexSelector* complex2,
    const ComplexSelector* complex1,
    const size_t maxSpecificity)
  {
    if (complex2->minSpecificity() < maxSpecificity) return false;
    return complex2->isSuperselectorOf(complex1);
  }
  // EO dontTrimComplex

  // ##########################################################################
  // Helper function used as callbacks on lists
  // ##########################################################################
  bool Extender::hasExactlyOne(const ComplexSelectorObj& vec)
  {
    return vec->length() == 1;
  }
  // EO hasExactlyOne

  // ##########################################################################
  // Helper function used as callbacks on lists
  // ##########################################################################
  bool Extender::hasMoreThanOne(const ComplexSelectorObj& vec)
  {
    return vec->length() > 1;
  }
  // hasMoreThanOne

}
