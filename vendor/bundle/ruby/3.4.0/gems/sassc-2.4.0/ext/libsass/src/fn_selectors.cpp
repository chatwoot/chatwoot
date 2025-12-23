#include <numeric>

#include "parser.hpp"
#include "extender.hpp"
#include "listize.hpp"
#include "fn_utils.hpp"
#include "fn_selectors.hpp"

namespace Sass {

  namespace Functions {

    Signature selector_nest_sig = "selector-nest($selectors...)";
    BUILT_IN(selector_nest)
    {
      List* arglist = ARG("$selectors", List);

      // Not enough parameters
      if (arglist->length() == 0) {
        error(
          "$selectors: At least one selector must be passed for `selector-nest'",
          pstate, traces);
      }

      // Parse args into vector of selectors
      SelectorStack parsedSelectors;
      for (size_t i = 0, L = arglist->length(); i < L; ++i) {
        ExpressionObj exp = Cast<Expression>(arglist->value_at_index(i));
        if (exp->concrete_type() == Expression::NULL_VAL) {
          error(
            "$selectors: null is not a valid selector: it must be a string,\n"
            "a list of strings, or a list of lists of strings for 'selector-nest'",
            pstate, traces);
        }
        if (String_Constant_Obj str = Cast<String_Constant>(exp)) {
          str->quote_mark(0);
        }
        sass::string exp_src = exp->to_string(ctx.c_options);
        ItplFile* source = SASS_MEMORY_NEW(ItplFile, exp_src.c_str(), exp->pstate());
        SelectorListObj sel = Parser::parse_selector(source, ctx, traces);
        parsedSelectors.push_back(sel);
      }

      // Nothing to do
      if( parsedSelectors.empty() ) {
        return SASS_MEMORY_NEW(Null, pstate);
      }

      // Set the first element as the `result`, keep
      // appending to as we go down the parsedSelector vector.
      SelectorStack::iterator itr = parsedSelectors.begin();
      SelectorListObj& result = *itr;
      ++itr;

      for(;itr != parsedSelectors.end(); ++itr) {
        SelectorListObj& child = *itr;
        original_stack.push_back(result);
        SelectorListObj rv = child->resolve_parent_refs(original_stack, traces);
        result->elements(rv->elements());
        original_stack.pop_back();
      }

      return Cast<Value>(Listize::perform(result));
    }

    Signature selector_append_sig = "selector-append($selectors...)";
    BUILT_IN(selector_append)
    {
      List* arglist = ARG("$selectors", List);

      // Not enough parameters
      if (arglist->empty()) {
        error(
          "$selectors: At least one selector must be "
          "passed for `selector-append'",
          pstate, traces);
      }

      // Parse args into vector of selectors
      SelectorStack parsedSelectors;
      parsedSelectors.push_back({});
      for (size_t i = 0, L = arglist->length(); i < L; ++i) {
        Expression* exp = Cast<Expression>(arglist->value_at_index(i));
        if (exp->concrete_type() == Expression::NULL_VAL) {
          error(
            "$selectors: null is not a valid selector: it must be a string,\n"
             "a list of strings, or a list of lists of strings for 'selector-append'",
            pstate, traces);
        }
        if (String_Constant* str = Cast<String_Constant>(exp)) {
          str->quote_mark(0);
        }
        sass::string exp_src = exp->to_string();
        ItplFile* source = SASS_MEMORY_NEW(ItplFile, exp_src.c_str(), exp->pstate());
        SelectorListObj sel = Parser::parse_selector(source, ctx, traces, true);

        for (auto& complex : sel->elements()) {
          if (complex->empty()) {
            complex->append(SASS_MEMORY_NEW(CompoundSelector, "[phony]"));
          }
          if (CompoundSelector* comp = Cast<CompoundSelector>(complex->first())) {
            comp->hasRealParent(true);
            complex->chroots(true);
          }
        }

        if (parsedSelectors.size() > 1) {

          if (!sel->has_real_parent_ref()) {
            auto parent = parsedSelectors.back();
            for (auto& complex : parent->elements()) {
              if (CompoundSelector* comp = Cast<CompoundSelector>(complex->first())) {
                comp->hasRealParent(false);
              }
            }
            error("Can't append \"" + sel->to_string() + "\" to \"" +
              parent->to_string() + "\" for `selector-append'",
              pstate, traces);
          }

          // Build the resolved stack from the left. It's cheaper to directly
          // calculate and update each resolved selcted from the left, than to
          // recursively calculate them from the right side, as we would need
          // to go through the whole stack depth to build the final results.
          // E.g. 'a', 'b', 'x, y' => 'a' => 'a b' => 'a b x, a b y'
          // vs 'a', 'b', 'x, y' => 'x' => 'b x' => 'a b x', 'y' ...
          parsedSelectors.push_back(sel->resolve_parent_refs(parsedSelectors, traces, true));
        }
        else {
          parsedSelectors.push_back(sel);
        }
      }

      // Nothing to do
      if( parsedSelectors.empty() ) {
        return SASS_MEMORY_NEW(Null, pstate);
      }

      return Cast<Value>(Listize::perform(parsedSelectors.back()));
    }

    Signature selector_unify_sig = "selector-unify($selector1, $selector2)";
    BUILT_IN(selector_unify)
    {
      SelectorListObj selector1 = ARGSELS("$selector1");
      SelectorListObj selector2 = ARGSELS("$selector2");
      SelectorListObj result = selector1->unifyWith(selector2);
      return Cast<Value>(Listize::perform(result));
    }

    Signature simple_selectors_sig = "simple-selectors($selector)";
    BUILT_IN(simple_selectors)
    {
      CompoundSelectorObj sel = ARGSEL("$selector");

      List* l = SASS_MEMORY_NEW(List, sel->pstate(), sel->length(), SASS_COMMA);

      for (size_t i = 0, L = sel->length(); i < L; ++i) {
        const SimpleSelectorObj& ss = sel->get(i);
        sass::string ss_string = ss->to_string() ;
        l->append(SASS_MEMORY_NEW(String_Quoted, ss->pstate(), ss_string));
      }

      return l;
    }

    Signature selector_extend_sig = "selector-extend($selector, $extendee, $extender)";
    BUILT_IN(selector_extend)
    {
      SelectorListObj selector = ARGSELS("$selector");
      SelectorListObj target = ARGSELS("$extendee");
      SelectorListObj source = ARGSELS("$extender");
      SelectorListObj result = Extender::extend(selector, source, target, traces);
      return Cast<Value>(Listize::perform(result));
    }

    Signature selector_replace_sig = "selector-replace($selector, $original, $replacement)";
    BUILT_IN(selector_replace)
    {
      SelectorListObj selector = ARGSELS("$selector");
      SelectorListObj target = ARGSELS("$original");
      SelectorListObj source = ARGSELS("$replacement");
      SelectorListObj result = Extender::replace(selector, source, target, traces);
      return Cast<Value>(Listize::perform(result));
    }

    Signature selector_parse_sig = "selector-parse($selector)";
    BUILT_IN(selector_parse)
    {
      SelectorListObj selector = ARGSELS("$selector");
      return Cast<Value>(Listize::perform(selector));
    }

    Signature is_superselector_sig = "is-superselector($super, $sub)";
    BUILT_IN(is_superselector)
    {
      SelectorListObj sel_sup = ARGSELS("$super");
      SelectorListObj sel_sub = ARGSELS("$sub");
      bool result = sel_sup->isSuperselectorOf(sel_sub);
      return SASS_MEMORY_NEW(Boolean, pstate, result);
    }

  }

}
