#include "ast.hpp"
#include "expand.hpp"
#include "fn_utils.hpp"
#include "fn_miscs.hpp"
#include "util_string.hpp"

namespace Sass {

  namespace Functions {

    //////////////////////////
    // INTROSPECTION FUNCTIONS
    //////////////////////////

    Signature type_of_sig = "type-of($value)";
    BUILT_IN(type_of)
    {
      Expression* v = ARG("$value", Expression);
      return SASS_MEMORY_NEW(String_Quoted, pstate, v->type());
    }

    Signature variable_exists_sig = "variable-exists($name)";
    BUILT_IN(variable_exists)
    {
      sass::string s = Util::normalize_underscores(unquote(ARG("$name", String_Constant)->value()));

      if(d_env.has("$"+s)) {
        return SASS_MEMORY_NEW(Boolean, pstate, true);
      }
      else {
        return SASS_MEMORY_NEW(Boolean, pstate, false);
      }
    }

    Signature global_variable_exists_sig = "global-variable-exists($name)";
    BUILT_IN(global_variable_exists)
    {
      sass::string s = Util::normalize_underscores(unquote(ARG("$name", String_Constant)->value()));

      if(d_env.has_global("$"+s)) {
        return SASS_MEMORY_NEW(Boolean, pstate, true);
      }
      else {
        return SASS_MEMORY_NEW(Boolean, pstate, false);
      }
    }

    Signature function_exists_sig = "function-exists($name)";
    BUILT_IN(function_exists)
    {
      String_Constant* ss = Cast<String_Constant>(env["$name"]);
      if (!ss) {
        error("$name: " + (env["$name"]->to_string()) + " is not a string for `function-exists'", pstate, traces);
      }

      sass::string name = Util::normalize_underscores(unquote(ss->value()));

      if(d_env.has(name+"[f]")) {
        return SASS_MEMORY_NEW(Boolean, pstate, true);
      }
      else {
        return SASS_MEMORY_NEW(Boolean, pstate, false);
      }
    }

    Signature mixin_exists_sig = "mixin-exists($name)";
    BUILT_IN(mixin_exists)
    {
      sass::string s = Util::normalize_underscores(unquote(ARG("$name", String_Constant)->value()));

      if(d_env.has(s+"[m]")) {
        return SASS_MEMORY_NEW(Boolean, pstate, true);
      }
      else {
        return SASS_MEMORY_NEW(Boolean, pstate, false);
      }
    }

    Signature feature_exists_sig = "feature-exists($feature)";
    BUILT_IN(feature_exists)
    {
      sass::string s = unquote(ARG("$feature", String_Constant)->value());

      static const auto *const features = new std::unordered_set<sass::string> {
        "global-variable-shadowing",
        "extend-selector-pseudoclass",
        "at-error",
        "units-level-3",
        "custom-property"
      };
      return SASS_MEMORY_NEW(Boolean, pstate, features->find(s) != features->end());
    }

    Signature call_sig = "call($function, $args...)";
    BUILT_IN(call)
    {
      sass::string function;
      Function* ff = Cast<Function>(env["$function"]);
      String_Constant* ss = Cast<String_Constant>(env["$function"]);

      if (ss) {
        function = Util::normalize_underscores(unquote(ss->value()));
        std::cerr << "DEPRECATION WARNING: ";
        std::cerr << "Passing a string to call() is deprecated and will be illegal" << std::endl;
        std::cerr << "in Sass 4.0. Use call(get-function(" + quote(function) + ")) instead." << std::endl;
        std::cerr << std::endl;
      } else if (ff) {
        function = ff->name();
      }

      List_Obj arglist = SASS_MEMORY_COPY(ARG("$args", List));

      Arguments_Obj args = SASS_MEMORY_NEW(Arguments, pstate);
      // sass::string full_name(name + "[f]");
      // Definition* def = d_env.has(full_name) ? Cast<Definition>((d_env)[full_name]) : 0;
      // Parameters* params = def ? def->parameters() : 0;
      // size_t param_size = params ? params->length() : 0;
      for (size_t i = 0, L = arglist->length(); i < L; ++i) {
        ExpressionObj expr = arglist->value_at_index(i);
        // if (params && params->has_rest_parameter()) {
        //   Parameter_Obj p = param_size > i ? (*params)[i] : 0;
        //   List* list = Cast<List>(expr);
        //   if (list && p && !p->is_rest_parameter()) expr = (*list)[0];
        // }
        if (arglist->is_arglist()) {
          ExpressionObj obj = arglist->at(i);
          Argument_Obj arg = (Argument*) obj.ptr(); // XXX
          args->append(SASS_MEMORY_NEW(Argument,
                                       pstate,
                                       expr,
                                       arg ? arg->name() : "",
                                       arg ? arg->is_rest_argument() : false,
                                       arg ? arg->is_keyword_argument() : false));
        } else {
          args->append(SASS_MEMORY_NEW(Argument, pstate, expr));
        }
      }
      Function_Call_Obj func = SASS_MEMORY_NEW(Function_Call, pstate, function, args);

      Expand expand(ctx, &d_env, &selector_stack, &original_stack);
      func->via_call(true); // calc invoke is allowed
      if (ff) func->func(ff);
      return Cast<PreValue>(func->perform(&expand.eval));
    }

    ////////////////////
    // BOOLEAN FUNCTIONS
    ////////////////////

    Signature not_sig = "not($value)";
    BUILT_IN(sass_not)
    {
      return SASS_MEMORY_NEW(Boolean, pstate, ARG("$value", Expression)->is_false());
    }

    Signature if_sig = "if($condition, $if-true, $if-false)";
    BUILT_IN(sass_if)
    {
      Expand expand(ctx, &d_env, &selector_stack, &original_stack);
      ExpressionObj cond = ARG("$condition", Expression)->perform(&expand.eval);
      bool is_true = !cond->is_false();
      ExpressionObj res = ARG(is_true ? "$if-true" : "$if-false", Expression);
      ValueObj qwe = Cast<Value>(res->perform(&expand.eval));
      // res = res->perform(&expand.eval.val_eval);
      qwe->set_delayed(false); // clone?
      return qwe.detach();
    }

    //////////////////////////
    // MISCELLANEOUS FUNCTIONS
    //////////////////////////

    Signature inspect_sig = "inspect($value)";
    BUILT_IN(inspect)
    {
      Expression* v = ARG("$value", Expression);
      if (v->concrete_type() == Expression::NULL_VAL) {
        return SASS_MEMORY_NEW(String_Constant, pstate, "null");
      } else if (v->concrete_type() == Expression::BOOLEAN && v->is_false()) {
        return SASS_MEMORY_NEW(String_Constant, pstate, "false");
      } else if (v->concrete_type() == Expression::STRING) {
        String_Constant *s = Cast<String_Constant>(v);
        if (s->quote_mark()) {
          return SASS_MEMORY_NEW(String_Constant, pstate, quote(s->value(), s->quote_mark()));
        } else {
          return s;
        }
      } else {
        // ToDo: fix to_sass for nested parentheses
        Sass_Output_Style old_style;
        old_style = ctx.c_options.output_style;
        ctx.c_options.output_style = TO_SASS;
        Emitter emitter(ctx.c_options);
        Inspect i(emitter);
        i.in_declaration = false;
        v->perform(&i);
        ctx.c_options.output_style = old_style;
        return SASS_MEMORY_NEW(String_Quoted, pstate, i.get_buffer());
      }
    }

    Signature content_exists_sig = "content-exists()";
    BUILT_IN(content_exists)
    {
      if (!d_env.has_global("is_in_mixin")) {
        error("Cannot call content-exists() except within a mixin.", pstate, traces);
      }
      return SASS_MEMORY_NEW(Boolean, pstate, d_env.has_lexical("@content[m]"));
    }

    Signature get_function_sig = "get-function($name, $css: false)";
    BUILT_IN(get_function)
    {
      String_Constant* ss = Cast<String_Constant>(env["$name"]);
      if (!ss) {
        error("$name: " + (env["$name"]->to_string()) + " is not a string for `get-function'", pstate, traces);
      }

      sass::string name = Util::normalize_underscores(unquote(ss->value()));
      sass::string full_name = name + "[f]";

      Boolean_Obj css = ARG("$css", Boolean);
      if (!css->is_false()) {
        Definition* def = SASS_MEMORY_NEW(Definition,
                                         pstate,
                                         name,
                                         SASS_MEMORY_NEW(Parameters, pstate),
                                         SASS_MEMORY_NEW(Block, pstate, 0, false),
                                         Definition::FUNCTION);
        return SASS_MEMORY_NEW(Function, pstate, def, true);
      }


      if (!d_env.has_global(full_name)) {
        error("Function not found: " + name, pstate, traces);
      }

      Definition* def = Cast<Definition>(d_env[full_name]);
      return SASS_MEMORY_NEW(Function, pstate, def, false);
    }

  }

}
