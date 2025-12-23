#ifndef SASS_AST2C_H
#define SASS_AST2C_H

#include "ast_fwd_decl.hpp"
#include "operation.hpp"
#include "sass/values.h"

namespace Sass {

  class AST2C : public Operation_CRTP<union Sass_Value*, AST2C> {

  public:

    AST2C() { }
    ~AST2C() { }

    union Sass_Value* operator()(Boolean*);
    union Sass_Value* operator()(Number*);
    union Sass_Value* operator()(Color_RGBA*);
    union Sass_Value* operator()(Color_HSLA*);
    union Sass_Value* operator()(String_Constant*);
    union Sass_Value* operator()(String_Quoted*);
    union Sass_Value* operator()(Custom_Warning*);
    union Sass_Value* operator()(Custom_Error*);
    union Sass_Value* operator()(List*);
    union Sass_Value* operator()(Map*);
    union Sass_Value* operator()(Null*);
    union Sass_Value* operator()(Arguments*);
    union Sass_Value* operator()(Argument*);

    // return sass error if type is not supported
    union Sass_Value* fallback(AST_Node* x)
    { return sass_make_error("unknown type for C-API"); }

  };

}

#endif
