#ifndef SASS_OPERATORS_H
#define SASS_OPERATORS_H

#include "values.hpp"
#include "sass/values.h"

namespace Sass {

  namespace Operators {

    // equality operator using AST Node operator==
    bool eq(ExpressionObj, ExpressionObj);
    bool neq(ExpressionObj, ExpressionObj);
    // specific operators based on cmp and eq
    bool lt(ExpressionObj, ExpressionObj);
    bool gt(ExpressionObj, ExpressionObj);
    bool lte(ExpressionObj, ExpressionObj);
    bool gte(ExpressionObj, ExpressionObj);
    // arithmetic for all the combinations that matter
    Value* op_strings(Sass::Operand, Value&, Value&, struct Sass_Inspect_Options opt, const SourceSpan& pstate, bool delayed = false);
    Value* op_colors(enum Sass_OP, const Color_RGBA&, const Color_RGBA&, struct Sass_Inspect_Options opt, const SourceSpan& pstate, bool delayed = false);
    Value* op_numbers(enum Sass_OP, const Number&, const Number&, struct Sass_Inspect_Options opt, const SourceSpan& pstate, bool delayed = false);
    Value* op_number_color(enum Sass_OP, const Number&, const Color_RGBA&, struct Sass_Inspect_Options opt, const SourceSpan& pstate, bool delayed = false);
    Value* op_color_number(enum Sass_OP, const Color_RGBA&, const Number&, struct Sass_Inspect_Options opt, const SourceSpan& pstate, bool delayed = false);

  };

}

#endif
