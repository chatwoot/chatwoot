#ifndef SASS_OPERATION_H
#define SASS_OPERATION_H

// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

// base classes to implement curiously recurring template pattern (CRTP)
// https://en.wikipedia.org/wiki/Curiously_recurring_template_pattern

#include <typeinfo>
#include <stdexcept>

#include "ast_fwd_decl.hpp"
#include "ast_def_macros.hpp"

namespace Sass {

  #define ATTACH_ABSTRACT_CRTP_PERFORM_METHODS()\
    virtual void perform(Operation<void>* op) = 0; \
    virtual Value* perform(Operation<Value*>* op) = 0; \
    virtual sass::string perform(Operation<sass::string>* op) = 0; \
    virtual AST_Node* perform(Operation<AST_Node*>* op) = 0; \
    virtual Selector* perform(Operation<Selector*>* op) = 0; \
    virtual Statement* perform(Operation<Statement*>* op) = 0; \
    virtual Expression* perform(Operation<Expression*>* op) = 0; \
    virtual union Sass_Value* perform(Operation<union Sass_Value*>* op) = 0; \
    virtual SupportsCondition* perform(Operation<SupportsCondition*>* op) = 0; \

  // you must add operators to every class
  // ensures `this` of actual instance type
  // we therefore call the specific operator
  // they are virtual so most specific is used
  #define ATTACH_CRTP_PERFORM_METHODS()\
    virtual void perform(Operation<void>* op) override { return (*op)(this); } \
    virtual Value* perform(Operation<Value*>* op) override { return (*op)(this); } \
    virtual sass::string perform(Operation<sass::string>* op) override { return (*op)(this); } \
    virtual AST_Node* perform(Operation<AST_Node*>* op) override { return (*op)(this); } \
    virtual Selector* perform(Operation<Selector*>* op) override { return (*op)(this); } \
    virtual Statement* perform(Operation<Statement*>* op) override { return (*op)(this); } \
    virtual Expression* perform(Operation<Expression*>* op) override { return (*op)(this); } \
    virtual union Sass_Value* perform(Operation<union Sass_Value*>* op) override { return (*op)(this); } \
    virtual SupportsCondition* perform(Operation<SupportsCondition*>* op) override { return (*op)(this); } \

  template<typename T>
  class Operation {
  public:
    virtual T operator()(AST_Node* x)               = 0;
    // statements
    virtual T operator()(Block* x)                  = 0;
    virtual T operator()(StyleRule* x)                = 0;
    virtual T operator()(Bubble* x)                 = 0;
    virtual T operator()(Trace* x)                  = 0;
    virtual T operator()(SupportsRule* x)         = 0;
    virtual T operator()(MediaRule* x) = 0;
    virtual T operator()(CssMediaRule* x) = 0;
    virtual T operator()(CssMediaQuery* x) = 0;
    virtual T operator()(AtRootRule* x)          = 0;
    virtual T operator()(AtRule* x)              = 0;
    virtual T operator()(Keyframe_Rule* x)          = 0;
    virtual T operator()(Declaration* x)            = 0;
    virtual T operator()(Assignment* x)             = 0;
    virtual T operator()(Import* x)                 = 0;
    virtual T operator()(Import_Stub* x)            = 0;
    virtual T operator()(WarningRule* x)                = 0;
    virtual T operator()(ErrorRule* x)                  = 0;
    virtual T operator()(DebugRule* x)                  = 0;
    virtual T operator()(Comment* x)                = 0;
    virtual T operator()(If* x)                     = 0;
    virtual T operator()(ForRule* x)                    = 0;
    virtual T operator()(EachRule* x)                   = 0;
    virtual T operator()(WhileRule* x)                  = 0;
    virtual T operator()(Return* x)                 = 0;
    virtual T operator()(Content* x)                = 0;
    virtual T operator()(ExtendRule* x)              = 0;
    virtual T operator()(Definition* x)             = 0;
    virtual T operator()(Mixin_Call* x)             = 0;
    // expressions
    virtual T operator()(Null* x)                   = 0;
    virtual T operator()(List* x)                   = 0;
    virtual T operator()(Map* x)                    = 0;
    virtual T operator()(Function* x)               = 0;
    virtual T operator()(Binary_Expression* x)      = 0;
    virtual T operator()(Unary_Expression* x)       = 0;
    virtual T operator()(Function_Call* x)          = 0;
    virtual T operator()(Custom_Warning* x)         = 0;
    virtual T operator()(Custom_Error* x)           = 0;
    virtual T operator()(Variable* x)               = 0;
    virtual T operator()(Number* x)                 = 0;
    virtual T operator()(Color* x)                  = 0;
    virtual T operator()(Color_RGBA* x)             = 0;
    virtual T operator()(Color_HSLA* x)             = 0;
    virtual T operator()(Boolean* x)                = 0;
    virtual T operator()(String_Schema* x)          = 0;
    virtual T operator()(String_Quoted* x)          = 0;
    virtual T operator()(String_Constant* x)        = 0;
    virtual T operator()(SupportsCondition* x)     = 0;
    virtual T operator()(SupportsOperation* x)      = 0;
    virtual T operator()(SupportsNegation* x)      = 0;
    virtual T operator()(SupportsDeclaration* x)   = 0;
    virtual T operator()(Supports_Interpolation* x) = 0;
    virtual T operator()(Media_Query* x) = 0;
    virtual T operator()(Media_Query_Expression* x) = 0;
    virtual T operator()(At_Root_Query* x)          = 0;
    virtual T operator()(Parent_Reference* x)        = 0;
    // parameters and arguments
    virtual T operator()(Parameter* x)              = 0;
    virtual T operator()(Parameters* x)             = 0;
    virtual T operator()(Argument* x)               = 0;
    virtual T operator()(Arguments* x)              = 0;
    // selectors
    virtual T operator()(Selector_Schema* x)        = 0;
    virtual T operator()(PlaceholderSelector* x)   = 0;
    virtual T operator()(TypeSelector* x)       = 0;
    virtual T operator()(ClassSelector* x)         = 0;
    virtual T operator()(IDSelector* x)            = 0;
    virtual T operator()(AttributeSelector* x)     = 0;
    virtual T operator()(PseudoSelector* x)        = 0;
    virtual T operator()(SelectorComponent* x) = 0;
    virtual T operator()(SelectorCombinator* x) = 0;
    virtual T operator()(CompoundSelector* x) = 0;
    virtual T operator()(ComplexSelector* x) = 0;
    virtual T operator()(SelectorList* x) = 0;

  };

  // example: Operation_CRTP<Expression*, Eval>
  // T is the base return type of all visitors
  // D is the class derived visitor class
  // normally you want to implement all operators
  template <typename T, typename D>
  class Operation_CRTP : public Operation<T> {
  public:
    T operator()(AST_Node* x)               { return static_cast<D*>(this)->fallback(x); }
    // statements
    T operator()(Block* x)                  { return static_cast<D*>(this)->fallback(x); }
    T operator()(StyleRule* x)                { return static_cast<D*>(this)->fallback(x); }
    T operator()(Bubble* x)                 { return static_cast<D*>(this)->fallback(x); }
    T operator()(Trace* x)                  { return static_cast<D*>(this)->fallback(x); }
    T operator()(SupportsRule* x)         { return static_cast<D*>(this)->fallback(x); }
    T operator()(MediaRule* x) { return static_cast<D*>(this)->fallback(x); }
    T operator()(CssMediaRule* x) { return static_cast<D*>(this)->fallback(x); }
    T operator()(CssMediaQuery* x) { return static_cast<D*>(this)->fallback(x); }
    T operator()(AtRootRule* x)          { return static_cast<D*>(this)->fallback(x); }
    T operator()(AtRule* x)              { return static_cast<D*>(this)->fallback(x); }
    T operator()(Keyframe_Rule* x)          { return static_cast<D*>(this)->fallback(x); }
    T operator()(Declaration* x)            { return static_cast<D*>(this)->fallback(x); }
    T operator()(Assignment* x)             { return static_cast<D*>(this)->fallback(x); }
    T operator()(Import* x)                 { return static_cast<D*>(this)->fallback(x); }
    T operator()(Import_Stub* x)            { return static_cast<D*>(this)->fallback(x); }
    T operator()(WarningRule* x)                { return static_cast<D*>(this)->fallback(x); }
    T operator()(ErrorRule* x)                  { return static_cast<D*>(this)->fallback(x); }
    T operator()(DebugRule* x)                  { return static_cast<D*>(this)->fallback(x); }
    T operator()(Comment* x)                { return static_cast<D*>(this)->fallback(x); }
    T operator()(If* x)                     { return static_cast<D*>(this)->fallback(x); }
    T operator()(ForRule* x)                    { return static_cast<D*>(this)->fallback(x); }
    T operator()(EachRule* x)                   { return static_cast<D*>(this)->fallback(x); }
    T operator()(WhileRule* x)                  { return static_cast<D*>(this)->fallback(x); }
    T operator()(Return* x)                 { return static_cast<D*>(this)->fallback(x); }
    T operator()(Content* x)                { return static_cast<D*>(this)->fallback(x); }
    T operator()(ExtendRule* x)              { return static_cast<D*>(this)->fallback(x); }
    T operator()(Definition* x)             { return static_cast<D*>(this)->fallback(x); }
    T operator()(Mixin_Call* x)             { return static_cast<D*>(this)->fallback(x); }
    // expressions
    T operator()(Null* x)                   { return static_cast<D*>(this)->fallback(x); }
    T operator()(List* x)                   { return static_cast<D*>(this)->fallback(x); }
    T operator()(Map* x)                    { return static_cast<D*>(this)->fallback(x); }
    T operator()(Function* x)               { return static_cast<D*>(this)->fallback(x); }
    T operator()(Binary_Expression* x)      { return static_cast<D*>(this)->fallback(x); }
    T operator()(Unary_Expression* x)       { return static_cast<D*>(this)->fallback(x); }
    T operator()(Function_Call* x)          { return static_cast<D*>(this)->fallback(x); }
    T operator()(Custom_Warning* x)         { return static_cast<D*>(this)->fallback(x); }
    T operator()(Custom_Error* x)           { return static_cast<D*>(this)->fallback(x); }
    T operator()(Variable* x)               { return static_cast<D*>(this)->fallback(x); }
    T operator()(Number* x)                 { return static_cast<D*>(this)->fallback(x); }
    T operator()(Color* x)                  { return static_cast<D*>(this)->fallback(x); }
    T operator()(Color_RGBA* x)             { return static_cast<D*>(this)->fallback(x); }
    T operator()(Color_HSLA* x)             { return static_cast<D*>(this)->fallback(x); }
    T operator()(Boolean* x)                { return static_cast<D*>(this)->fallback(x); }
    T operator()(String_Schema* x)          { return static_cast<D*>(this)->fallback(x); }
    T operator()(String_Constant* x)        { return static_cast<D*>(this)->fallback(x); }
    T operator()(String_Quoted* x)          { return static_cast<D*>(this)->fallback(x); }
    T operator()(SupportsCondition* x)     { return static_cast<D*>(this)->fallback(x); }
    T operator()(SupportsOperation* x)      { return static_cast<D*>(this)->fallback(x); }
    T operator()(SupportsNegation* x)      { return static_cast<D*>(this)->fallback(x); }
    T operator()(SupportsDeclaration* x)   { return static_cast<D*>(this)->fallback(x); }
    T operator()(Supports_Interpolation* x) { return static_cast<D*>(this)->fallback(x); }
    T operator()(Media_Query* x)            { return static_cast<D*>(this)->fallback(x); }
    T operator()(Media_Query_Expression* x) { return static_cast<D*>(this)->fallback(x); }
    T operator()(At_Root_Query* x)          { return static_cast<D*>(this)->fallback(x); }
    T operator()(Parent_Reference* x)        { return static_cast<D*>(this)->fallback(x); }
    // parameters and arguments
    T operator()(Parameter* x)              { return static_cast<D*>(this)->fallback(x); }
    T operator()(Parameters* x)             { return static_cast<D*>(this)->fallback(x); }
    T operator()(Argument* x)               { return static_cast<D*>(this)->fallback(x); }
    T operator()(Arguments* x)              { return static_cast<D*>(this)->fallback(x); }
    // selectors
    T operator()(Selector_Schema* x)        { return static_cast<D*>(this)->fallback(x); }
    T operator()(PlaceholderSelector* x)   { return static_cast<D*>(this)->fallback(x); }
    T operator()(TypeSelector* x)       { return static_cast<D*>(this)->fallback(x); }
    T operator()(ClassSelector* x)         { return static_cast<D*>(this)->fallback(x); }
    T operator()(IDSelector* x)            { return static_cast<D*>(this)->fallback(x); }
    T operator()(AttributeSelector* x)     { return static_cast<D*>(this)->fallback(x); }
    T operator()(PseudoSelector* x)        { return static_cast<D*>(this)->fallback(x); }
    T operator()(SelectorComponent* x) { return static_cast<D*>(this)->fallback(x); }
    T operator()(SelectorCombinator* x) { return static_cast<D*>(this)->fallback(x); }
    T operator()(CompoundSelector* x) { return static_cast<D*>(this)->fallback(x); }
    T operator()(ComplexSelector* x) { return static_cast<D*>(this)->fallback(x); }
    T operator()(SelectorList* x) { return static_cast<D*>(this)->fallback(x); }

    // fallback with specific type U
    // will be called if not overloaded
    template <typename U> inline T fallback(U x)
    {
      throw std::runtime_error(
        std::string(typeid(*this).name()) + ": CRTP not implemented for " + typeid(x).name());
    }

  };

}

#endif
