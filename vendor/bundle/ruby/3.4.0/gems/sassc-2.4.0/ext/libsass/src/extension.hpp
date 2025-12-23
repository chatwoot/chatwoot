#ifndef SASS_EXTENSION_H
#define SASS_EXTENSION_H

// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include <unordered_map>
#include <unordered_set>
#include "ast_fwd_decl.hpp"
#include "backtrace.hpp"

namespace Sass {

  class Extension {

  public:

    // The selector in which the `@extend` appeared.
    ComplexSelectorObj extender;

    // The selector that's being extended.
    // `null` for one-off extensions.
    SimpleSelectorObj target;

    // The minimum specificity required for any
    // selector generated from this extender.
    size_t specificity;

    // Whether this extension is optional.
    bool isOptional;

    // Whether this is a one-off extender representing a selector that was
    // originally in the document, rather than one defined with `@extend`.
    bool isOriginal;

    bool isSatisfied;

    // The media query context to which this extend is restricted,
    // or `null` if it can apply within any context.
    CssMediaRuleObj mediaContext;

    // Creates a one-off extension that's not intended to be modified over time.
    // If [specificity] isn't passed, it defaults to `extender.maxSpecificity`.
    Extension(ComplexSelectorObj extender) :
      extender(extender),
      target({}),
      specificity(0),
      isOptional(true),
      isOriginal(false),
      isSatisfied(false),
      mediaContext({}) {

    }

    // Copy constructor
    Extension(const Extension& extension) :
      extender(extension.extender),
      target(extension.target),
      specificity(extension.specificity),
      isOptional(extension.isOptional),
      isOriginal(extension.isOriginal),
      isSatisfied(extension.isSatisfied),
      mediaContext(extension.mediaContext) {

    }

    // Default constructor
    Extension() :
      extender({}),
      target({}),
      specificity(0),
      isOptional(false),
      isOriginal(false),
      isSatisfied(false),
      mediaContext({}) {
    }

    // Asserts that the [mediaContext] for a selector is 
    // compatible with the query context for this extender.
    void assertCompatibleMediaContext(CssMediaRuleObj mediaContext, Backtraces& traces) const;

    Extension withExtender(const ComplexSelectorObj& newExtender) const;

  };

}

#endif
