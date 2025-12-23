#ifndef SASS_STYLESHEET_H
#define SASS_STYLESHEET_H

// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include "ast_fwd_decl.hpp"
#include "extender.hpp"
#include "file.hpp"

namespace Sass {

  // parsed stylesheet from loaded resource
  // this should be a `Module` for sass 4.0
  class StyleSheet : public Resource {
    public:

      // The canonical URL for this module's source file. This may be `null`
      // if the module was loaded from a string without a URL provided.
      // Uri get url;

      // Modules that this module uses.
      // List<Module> get upstream;

      // The module's variables.
      // Map<String, Value> get variables;

      // The module's functions. Implementations must ensure
      // that each [Callable] is stored under its own name.
      // Map<String, Callable> get functions;

      // The module's mixins. Implementations must ensure that
      // each [Callable] is stored under its own name.
      // Map<String, Callable> get mixins;

      // The extensions defined in this module, which is also able to update
      // [css]'s style rules in-place based on downstream extensions.
      // Extender extender;

      // The module's CSS tree.
      Block_Obj root;

    public:

      // default argument constructor
      StyleSheet(const Resource& res, Block_Obj root);

      // Copy constructor
      StyleSheet(const StyleSheet& res);

  };


}

#endif
