#ifndef SASS_LISTIZE_H
#define SASS_LISTIZE_H

// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include "ast_fwd_decl.hpp"
#include "operation.hpp"

namespace Sass {

  struct Backtrace;

  class Listize : public Operation_CRTP<Expression*, Listize> {

  public:

    static Expression* perform(AST_Node* node);

  public:
    Listize();
    ~Listize() { }

    Expression* operator()(SelectorList*);
    Expression* operator()(ComplexSelector*);
    Expression* operator()(CompoundSelector*);

    // generic fallback
    template <typename U>
    Expression* fallback(U x)
    { return Cast<Expression>(x); }
  };

}

#endif
