// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include "ast_helpers.hpp"
#include "extension.hpp"
#include "ast.hpp"

namespace Sass {

  // ##########################################################################
  // Static function to create a copy with a new extender
  // ##########################################################################
  Extension Extension::withExtender(const ComplexSelectorObj& newExtender) const
  {
    Extension extension(newExtender);
    extension.specificity = specificity;
    extension.isOptional = isOptional;
    extension.target = target;
    return extension;
  }

  // ##########################################################################
  // Asserts that the [mediaContext] for a selector is
  // compatible with the query context for this extender.
  // ##########################################################################
  void Extension::assertCompatibleMediaContext(CssMediaRuleObj mediaQueryContext, Backtraces& traces) const
  {

    if (this->mediaContext.isNull()) return;

    if (mediaQueryContext && ObjPtrEqualityFn(mediaContext->block(), mediaQueryContext->block())) return;

    if (ObjEqualityFn<CssMediaRuleObj>(mediaQueryContext, mediaContext)) return;

    throw Exception::ExtendAcrossMedia(traces, *this);

  }

  // ##########################################################################
  // ##########################################################################

}
