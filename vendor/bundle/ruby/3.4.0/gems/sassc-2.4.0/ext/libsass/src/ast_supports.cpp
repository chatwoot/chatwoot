// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"
#include "ast.hpp"


namespace Sass {

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  SupportsRule::SupportsRule(SourceSpan pstate, SupportsConditionObj condition, Block_Obj block)
  : ParentStatement(pstate, block), condition_(condition)
  { statement_type(SUPPORTS); }
  SupportsRule::SupportsRule(const SupportsRule* ptr)
  : ParentStatement(ptr), condition_(ptr->condition_)
  { statement_type(SUPPORTS); }
  bool SupportsRule::bubbles() { return true; }

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  SupportsCondition::SupportsCondition(SourceSpan pstate)
  : Expression(pstate)
  { }

  SupportsCondition::SupportsCondition(const SupportsCondition* ptr)
  : Expression(ptr)
  { }

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  SupportsOperation::SupportsOperation(SourceSpan pstate, SupportsConditionObj l, SupportsConditionObj r, Operand o)
  : SupportsCondition(pstate), left_(l), right_(r), operand_(o)
  { }
  SupportsOperation::SupportsOperation(const SupportsOperation* ptr)
  : SupportsCondition(ptr),
    left_(ptr->left_),
    right_(ptr->right_),
    operand_(ptr->operand_)
  { }

  bool SupportsOperation::needs_parens(SupportsConditionObj cond) const
  {
    if (SupportsOperationObj op = Cast<SupportsOperation>(cond)) {
      return op->operand() != operand();
    }
    return Cast<SupportsNegation>(cond) != NULL;
  }

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  SupportsNegation::SupportsNegation(SourceSpan pstate, SupportsConditionObj c)
  : SupportsCondition(pstate), condition_(c)
  { }
  SupportsNegation::SupportsNegation(const SupportsNegation* ptr)
  : SupportsCondition(ptr), condition_(ptr->condition_)
  { }

  bool SupportsNegation::needs_parens(SupportsConditionObj cond) const
  {
    return Cast<SupportsNegation>(cond) ||
           Cast<SupportsOperation>(cond);
  }

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  SupportsDeclaration::SupportsDeclaration(SourceSpan pstate, ExpressionObj f, ExpressionObj v)
  : SupportsCondition(pstate), feature_(f), value_(v)
  { }
  SupportsDeclaration::SupportsDeclaration(const SupportsDeclaration* ptr)
  : SupportsCondition(ptr),
    feature_(ptr->feature_),
    value_(ptr->value_)
  { }

  bool SupportsDeclaration::needs_parens(SupportsConditionObj cond) const
  {
    return false;
  }

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  Supports_Interpolation::Supports_Interpolation(SourceSpan pstate, ExpressionObj v)
  : SupportsCondition(pstate), value_(v)
  { }
  Supports_Interpolation::Supports_Interpolation(const Supports_Interpolation* ptr)
  : SupportsCondition(ptr),
    value_(ptr->value_)
  { }

  bool Supports_Interpolation::needs_parens(SupportsConditionObj cond) const
  {
    return false;
  }

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

  IMPLEMENT_AST_OPERATORS(SupportsRule);
  IMPLEMENT_AST_OPERATORS(SupportsCondition);
  IMPLEMENT_AST_OPERATORS(SupportsOperation);
  IMPLEMENT_AST_OPERATORS(SupportsNegation);
  IMPLEMENT_AST_OPERATORS(SupportsDeclaration);
  IMPLEMENT_AST_OPERATORS(Supports_Interpolation);

  /////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////

}
