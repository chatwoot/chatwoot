#ifndef SASS_REMOVE_PLACEHOLDERS_H
#define SASS_REMOVE_PLACEHOLDERS_H

#include "ast_fwd_decl.hpp"
#include "operation.hpp"

namespace Sass {

  class Remove_Placeholders : public Operation_CRTP<void, Remove_Placeholders> {

  public:

    SelectorList* remove_placeholders(SelectorList*);
    void remove_placeholders(SimpleSelector* simple);
    void remove_placeholders(CompoundSelector* complex);
    void remove_placeholders(ComplexSelector* complex);


  public:
    Remove_Placeholders();
    ~Remove_Placeholders() { }

    void operator()(Block*);
    void operator()(StyleRule*);
    void operator()(CssMediaRule*);
    void operator()(SupportsRule*);
    void operator()(AtRule*);

    // ignore missed types
    template <typename U>
    void fallback(U x) {}

  };

}

#endif
