#ifndef SASS_AST_SUPPORTS_H
#define SASS_AST_SUPPORTS_H

// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include <set>
#include <deque>
#include <vector>
#include <string>
#include <sstream>
#include <iostream>
#include <typeinfo>
#include <algorithm>
#include "sass/base.h"
#include "ast_fwd_decl.hpp"

#include "util.hpp"
#include "units.hpp"
#include "context.hpp"
#include "position.hpp"
#include "constants.hpp"
#include "operation.hpp"
#include "position.hpp"
#include "inspect.hpp"
#include "source_map.hpp"
#include "environment.hpp"
#include "error_handling.hpp"
#include "ast_def_macros.hpp"
#include "ast_fwd_decl.hpp"
#include "source_map.hpp"
#include "fn_utils.hpp"

#include "sass.h"

namespace Sass {

  ////////////////////
  // `@supports` rule.
  ////////////////////
  class SupportsRule : public ParentStatement {
    ADD_PROPERTY(SupportsConditionObj, condition)
  public:
    SupportsRule(SourceSpan pstate, SupportsConditionObj condition, Block_Obj block = {});
    bool bubbles() override;
    ATTACH_AST_OPERATIONS(SupportsRule)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  //////////////////////////////////////////////////////
  // The abstract superclass of all Supports conditions.
  //////////////////////////////////////////////////////
  class SupportsCondition : public Expression {
  public:
    SupportsCondition(SourceSpan pstate);
    virtual bool needs_parens(SupportsConditionObj cond) const { return false; }
    ATTACH_AST_OPERATIONS(SupportsCondition)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ////////////////////////////////////////////////////////////
  // An operator condition (e.g. `CONDITION1 and CONDITION2`).
  ////////////////////////////////////////////////////////////
  class SupportsOperation : public SupportsCondition {
  public:
    enum Operand { AND, OR };
  private:
    ADD_PROPERTY(SupportsConditionObj, left);
    ADD_PROPERTY(SupportsConditionObj, right);
    ADD_PROPERTY(Operand, operand);
  public:
    SupportsOperation(SourceSpan pstate, SupportsConditionObj l, SupportsConditionObj r, Operand o);
    virtual bool needs_parens(SupportsConditionObj cond) const override;
    ATTACH_AST_OPERATIONS(SupportsOperation)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  //////////////////////////////////////////
  // A negation condition (`not CONDITION`).
  //////////////////////////////////////////
  class SupportsNegation : public SupportsCondition {
  private:
    ADD_PROPERTY(SupportsConditionObj, condition);
  public:
    SupportsNegation(SourceSpan pstate, SupportsConditionObj c);
    virtual bool needs_parens(SupportsConditionObj cond) const override;
    ATTACH_AST_OPERATIONS(SupportsNegation)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  /////////////////////////////////////////////////////
  // A declaration condition (e.g. `(feature: value)`).
  /////////////////////////////////////////////////////
  class SupportsDeclaration : public SupportsCondition {
  private:
    ADD_PROPERTY(ExpressionObj, feature);
    ADD_PROPERTY(ExpressionObj, value);
  public:
    SupportsDeclaration(SourceSpan pstate, ExpressionObj f, ExpressionObj v);
    virtual bool needs_parens(SupportsConditionObj cond) const override;
    ATTACH_AST_OPERATIONS(SupportsDeclaration)
    ATTACH_CRTP_PERFORM_METHODS()
  };

  ///////////////////////////////////////////////
  // An interpolation condition (e.g. `#{$var}`).
  ///////////////////////////////////////////////
  class Supports_Interpolation : public SupportsCondition {
  private:
    ADD_PROPERTY(ExpressionObj, value);
  public:
    Supports_Interpolation(SourceSpan pstate, ExpressionObj v);
    virtual bool needs_parens(SupportsConditionObj cond) const override;
    ATTACH_AST_OPERATIONS(Supports_Interpolation)
    ATTACH_CRTP_PERFORM_METHODS()
  };

}

#endif
