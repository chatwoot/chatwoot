#include "ast.hpp"

namespace Sass {

  #define IMPLEMENT_BASE_CAST(T) \
  template<> \
  T* Cast(AST_Node* ptr) { \
    return dynamic_cast<T*>(ptr); \
  }; \
  \
  template<> \
  const T* Cast(const AST_Node* ptr) { \
    return dynamic_cast<const T*>(ptr); \
  }; \

  IMPLEMENT_BASE_CAST(AST_Node)
  IMPLEMENT_BASE_CAST(Expression)
  IMPLEMENT_BASE_CAST(Statement)
  IMPLEMENT_BASE_CAST(ParentStatement)
  IMPLEMENT_BASE_CAST(PreValue)
  IMPLEMENT_BASE_CAST(Value)
  IMPLEMENT_BASE_CAST(Color)
  IMPLEMENT_BASE_CAST(List)
  IMPLEMENT_BASE_CAST(String)
  IMPLEMENT_BASE_CAST(String_Constant)
  IMPLEMENT_BASE_CAST(SupportsCondition)
  IMPLEMENT_BASE_CAST(Selector)
  IMPLEMENT_BASE_CAST(SelectorComponent)
  IMPLEMENT_BASE_CAST(SimpleSelector)

}
