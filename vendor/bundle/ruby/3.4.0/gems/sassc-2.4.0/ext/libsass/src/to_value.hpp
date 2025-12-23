#ifndef SASS_TO_VALUE_H
#define SASS_TO_VALUE_H

#include "operation.hpp"
#include "sass/values.h"
#include "ast_fwd_decl.hpp"

namespace Sass {

  class To_Value : public Operation_CRTP<Value*, To_Value> {

  private:

    Context& ctx;

  public:

    To_Value(Context& ctx)
    : ctx(ctx)
    { }
    ~To_Value() { }
    using Operation<Value*>::operator();

    Value* operator()(Argument*);
    Value* operator()(Boolean*);
    Value* operator()(Number*);
    Value* operator()(Color_RGBA*);
    Value* operator()(Color_HSLA*);
    Value* operator()(String_Constant*);
    Value* operator()(String_Quoted*);
    Value* operator()(Custom_Warning*);
    Value* operator()(Custom_Error*);
    Value* operator()(List*);
    Value* operator()(Map*);
    Value* operator()(Null*);
    Value* operator()(Function*);

    // convert to string via `To_String`
    Value* operator()(SelectorList*);
    Value* operator()(Binary_Expression*);

  };

}

#endif
