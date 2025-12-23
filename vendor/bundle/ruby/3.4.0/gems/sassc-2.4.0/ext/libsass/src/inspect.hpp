#ifndef SASS_INSPECT_H
#define SASS_INSPECT_H

#include "position.hpp"
#include "operation.hpp"
#include "emitter.hpp"

namespace Sass {
  class Context;

  class Inspect : public Operation_CRTP<void, Inspect>, public Emitter {
  protected:
    // import all the class-specific methods and override as desired
    using Operation_CRTP<void, Inspect>::operator();

  public:

    Inspect(const Emitter& emi);
    virtual ~Inspect();

    // statements
    virtual void operator()(Block*);
    virtual void operator()(StyleRule*);
    virtual void operator()(Bubble*);
    virtual void operator()(SupportsRule*);
    virtual void operator()(AtRootRule*);
    virtual void operator()(AtRule*);
    virtual void operator()(Keyframe_Rule*);
    virtual void operator()(Declaration*);
    virtual void operator()(Assignment*);
    virtual void operator()(Import*);
    virtual void operator()(Import_Stub*);
    virtual void operator()(WarningRule*);
    virtual void operator()(ErrorRule*);
    virtual void operator()(DebugRule*);
    virtual void operator()(Comment*);
    virtual void operator()(If*);
    virtual void operator()(ForRule*);
    virtual void operator()(EachRule*);
    virtual void operator()(WhileRule*);
    virtual void operator()(Return*);
    virtual void operator()(ExtendRule*);
    virtual void operator()(Definition*);
    virtual void operator()(Mixin_Call*);
    virtual void operator()(Content*);
    // expressions
    virtual void operator()(Map*);
    virtual void operator()(Function*);
    virtual void operator()(List*);
    virtual void operator()(Binary_Expression*);
    virtual void operator()(Unary_Expression*);
    virtual void operator()(Function_Call*);
    // virtual void operator()(Custom_Warning*);
    // virtual void operator()(Custom_Error*);
    virtual void operator()(Variable*);
    virtual void operator()(Number*);
    virtual void operator()(Color_RGBA*);
    virtual void operator()(Color_HSLA*);
    virtual void operator()(Boolean*);
    virtual void operator()(String_Schema*);
    virtual void operator()(String_Constant*);
    virtual void operator()(String_Quoted*);
    virtual void operator()(Custom_Error*);
    virtual void operator()(Custom_Warning*);
    virtual void operator()(SupportsOperation*);
    virtual void operator()(SupportsNegation*);
    virtual void operator()(SupportsDeclaration*);
    virtual void operator()(Supports_Interpolation*);
    virtual void operator()(MediaRule*);
    virtual void operator()(CssMediaRule*);
    virtual void operator()(CssMediaQuery*);
    virtual void operator()(Media_Query*);
    virtual void operator()(Media_Query_Expression*);
    virtual void operator()(At_Root_Query*);
    virtual void operator()(Null*);
    virtual void operator()(Parent_Reference* p);
    // parameters and arguments
    virtual void operator()(Parameter*);
    virtual void operator()(Parameters*);
    virtual void operator()(Argument*);
    virtual void operator()(Arguments*);
    // selectors
    virtual void operator()(Selector_Schema*);
    virtual void operator()(PlaceholderSelector*);
    virtual void operator()(TypeSelector*);
    virtual void operator()(ClassSelector*);
    virtual void operator()(IDSelector*);
    virtual void operator()(AttributeSelector*);
    virtual void operator()(PseudoSelector*);
    virtual void operator()(SelectorComponent*);
    virtual void operator()(SelectorCombinator*);
    virtual void operator()(CompoundSelector*);
    virtual void operator()(ComplexSelector*);
    virtual void operator()(SelectorList*);
    virtual sass::string lbracket(List*);
    virtual sass::string rbracket(List*);

  };

}
#endif
