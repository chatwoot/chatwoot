// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include <cstdlib>
#include <cmath>
#include <iostream>
#include <sstream>
#include <iomanip>
#include <typeinfo>

#include "file.hpp"
#include "eval.hpp"
#include "ast.hpp"
#include "bind.hpp"
#include "util.hpp"
#include "inspect.hpp"
#include "operators.hpp"
#include "environment.hpp"
#include "position.hpp"
#include "sass/values.h"
#include "to_value.hpp"
#include "ast2c.hpp"
#include "c2ast.hpp"
#include "context.hpp"
#include "backtrace.hpp"
#include "lexer.hpp"
#include "prelexer.hpp"
#include "parser.hpp"
#include "expand.hpp"
#include "color_maps.hpp"
#include "sass_functions.hpp"
#include "error_handling.hpp"
#include "util_string.hpp"

namespace Sass {

  Eval::Eval(Expand& exp)
  : exp(exp),
    ctx(exp.ctx),
    traces(exp.traces),
    force(false),
    is_in_comment(false),
    is_in_selector_schema(false)
  {
    bool_true = SASS_MEMORY_NEW(Boolean, "[NA]", true);
    bool_false = SASS_MEMORY_NEW(Boolean, "[NA]", false);
  }
  Eval::~Eval() { }

  Env* Eval::environment()
  {
    return exp.environment();
  }

  const sass::string Eval::cwd()
  {
    return ctx.cwd();
  }

  struct Sass_Inspect_Options& Eval::options()
  {
    return ctx.c_options;
  }

  struct Sass_Compiler* Eval::compiler()
  {
    return ctx.c_compiler;
  }

  EnvStack& Eval::env_stack()
  {
    return exp.env_stack;
  }

  sass::vector<Sass_Callee>& Eval::callee_stack()
  {
    return ctx.callee_stack;
  }

  Expression* Eval::operator()(Block* b)
  {
    Expression* val = 0;
    for (size_t i = 0, L = b->length(); i < L; ++i) {
      val = b->at(i)->perform(this);
      if (val) return val;
    }
    return val;
  }

  Expression* Eval::operator()(Assignment* a)
  {
    Env* env = environment();
    sass::string var(a->variable());
    if (a->is_global()) {
      if (!env->has_global(var)) {
        deprecated(
          "!global assignments won't be able to declare new variables in future versions.",
          "Consider adding `" + var + ": null` at the top level.",
          true, a->pstate());
      }
      if (a->is_default()) {
        if (env->has_global(var)) {
          Expression* e = Cast<Expression>(env->get_global(var));
          if (!e || e->concrete_type() == Expression::NULL_VAL) {
            env->set_global(var, a->value()->perform(this));
          }
        }
        else {
          env->set_global(var, a->value()->perform(this));
        }
      }
      else {
        env->set_global(var, a->value()->perform(this));
      }
    }
    else if (a->is_default()) {
      if (env->has_lexical(var)) {
        auto cur = env;
        while (cur && cur->is_lexical()) {
          if (cur->has_local(var)) {
            if (AST_Node_Obj node = cur->get_local(var)) {
              Expression* e = Cast<Expression>(node);
              if (!e || e->concrete_type() == Expression::NULL_VAL) {
                cur->set_local(var, a->value()->perform(this));
              }
            }
            else {
              throw std::runtime_error("Env not in sync");
            }
            return 0;
          }
          cur = cur->parent();
        }
        throw std::runtime_error("Env not in sync");
      }
      else if (env->has_global(var)) {
        if (AST_Node_Obj node = env->get_global(var)) {
          Expression* e = Cast<Expression>(node);
          if (!e || e->concrete_type() == Expression::NULL_VAL) {
            env->set_global(var, a->value()->perform(this));
          }
        }
      }
      else if (env->is_lexical()) {
        env->set_local(var, a->value()->perform(this));
      }
      else {
        env->set_local(var, a->value()->perform(this));
      }
    }
    else {
      env->set_lexical(var, a->value()->perform(this));
    }
    return 0;
  }

  Expression* Eval::operator()(If* i)
  {
    ExpressionObj rv;
    Env env(environment());
    env_stack().push_back(&env);
    ExpressionObj cond = i->predicate()->perform(this);
    if (!cond->is_false()) {
      rv = i->block()->perform(this);
    }
    else {
      Block_Obj alt = i->alternative();
      if (alt) rv = alt->perform(this);
    }
    env_stack().pop_back();
    return rv.detach();
  }

  // For does not create a new env scope
  // But iteration vars are reset afterwards
  Expression* Eval::operator()(ForRule* f)
  {
    sass::string variable(f->variable());
    ExpressionObj low = f->lower_bound()->perform(this);
    if (low->concrete_type() != Expression::NUMBER) {
      traces.push_back(Backtrace(low->pstate()));
      throw Exception::TypeMismatch(traces, *low, "integer");
    }
    ExpressionObj high = f->upper_bound()->perform(this);
    if (high->concrete_type() != Expression::NUMBER) {
      traces.push_back(Backtrace(high->pstate()));
      throw Exception::TypeMismatch(traces, *high, "integer");
    }
    Number_Obj sass_start = Cast<Number>(low);
    Number_Obj sass_end = Cast<Number>(high);
    // check if units are valid for sequence
    if (sass_start->unit() != sass_end->unit()) {
      sass::ostream msg; msg << "Incompatible units: '"
        << sass_end->unit() << "' and '"
        << sass_start->unit() << "'.";
      error(msg.str(), low->pstate(), traces);
    }
    double start = sass_start->value();
    double end = sass_end->value();
    // only create iterator once in this environment
    Env env(environment(), true);
    env_stack().push_back(&env);
    Block_Obj body = f->block();
    Expression* val = 0;
    if (start < end) {
      if (f->is_inclusive()) ++end;
      for (double i = start;
           i < end;
           ++i) {
        Number_Obj it = SASS_MEMORY_NEW(Number, low->pstate(), i, sass_end->unit());
        env.set_local(variable, it);
        val = body->perform(this);
        if (val) break;
      }
    } else {
      if (f->is_inclusive()) --end;
      for (double i = start;
           i > end;
           --i) {
        Number_Obj it = SASS_MEMORY_NEW(Number, low->pstate(), i, sass_end->unit());
        env.set_local(variable, it);
        val = body->perform(this);
        if (val) break;
      }
    }
    env_stack().pop_back();
    return val;
  }

  // Eval does not create a new env scope
  // But iteration vars are reset afterwards
  Expression* Eval::operator()(EachRule* e)
  {
    sass::vector<sass::string> variables(e->variables());
    ExpressionObj expr = e->list()->perform(this);
    Env env(environment(), true);
    env_stack().push_back(&env);
    List_Obj list;
    Map* map = nullptr;
    if (expr->concrete_type() == Expression::MAP) {
      map = Cast<Map>(expr);
    }
    else if (SelectorList * ls = Cast<SelectorList>(expr)) {
      ExpressionObj rv = Listize::perform(ls);
      list = Cast<List>(rv);
    }
    else if (expr->concrete_type() != Expression::LIST) {
      list = SASS_MEMORY_NEW(List, expr->pstate(), 1, SASS_COMMA);
      list->append(expr);
    }
    else {
      list = Cast<List>(expr);
    }

    Block_Obj body = e->block();
    ExpressionObj val;

    if (map) {
      for (ExpressionObj key : map->keys()) {
        ExpressionObj value = map->at(key);

        if (variables.size() == 1) {
          List* variable = SASS_MEMORY_NEW(List, map->pstate(), 2, SASS_SPACE);
          variable->append(key);
          variable->append(value);
          env.set_local(variables[0], variable);
        } else {
          env.set_local(variables[0], key);
          env.set_local(variables[1], value);
        }

        val = body->perform(this);
        if (val) break;
      }
    }
    else {
      if (list->length() == 1 && Cast<SelectorList>(list)) {
        list = Cast<List>(list);
      }
      for (size_t i = 0, L = list->length(); i < L; ++i) {
        Expression* item = list->at(i);
        // unwrap value if the expression is an argument
        if (Argument* arg = Cast<Argument>(item)) item = arg->value();
        // check if we got passed a list of args (investigate)
        if (List* scalars = Cast<List>(item)) {
          if (variables.size() == 1) {
            Expression* var = scalars;
            env.set_local(variables[0], var);
          } else {
            // https://github.com/sass/libsass/issues/3078
            for (size_t j = 0, K = variables.size(); j < K; ++j) {
              env.set_local(variables[j], j >= scalars->length()
                ? SASS_MEMORY_NEW(Null, expr->pstate()) : scalars->at(j));
            }
          }
        } else {
          if (variables.size() > 0) {
            env.set_local(variables.at(0), item);
            for (size_t j = 1, K = variables.size(); j < K; ++j) {
              // XXX: this is never hit via spec tests
              Expression* res = SASS_MEMORY_NEW(Null, expr->pstate());
              env.set_local(variables[j], res);
            }
          }
        }
        val = body->perform(this);
        if (val) break;
      }
    }
    env_stack().pop_back();
    return val.detach();
  }

  Expression* Eval::operator()(WhileRule* w)
  {
    ExpressionObj pred = w->predicate();
    Block_Obj body = w->block();
    Env env(environment(), true);
    env_stack().push_back(&env);
    ExpressionObj cond = pred->perform(this);
    while (!cond->is_false()) {
      ExpressionObj val = body->perform(this);
      if (val) {
        env_stack().pop_back();
        return val.detach();
      }
      cond = pred->perform(this);
    }
    env_stack().pop_back();
    return 0;
  }

  Expression* Eval::operator()(Return* r)
  {
    return r->value()->perform(this);
  }

  Expression* Eval::operator()(WarningRule* w)
  {
    Sass_Output_Style outstyle = options().output_style;
    options().output_style = NESTED;
    ExpressionObj message = w->message()->perform(this);
    Env* env = environment();

    // try to use generic function
    if (env->has("@warn[f]")) {

      // add call stack entry
      callee_stack().push_back({
        "@warn",
        w->pstate().getPath(),
        w->pstate().getLine(),
        w->pstate().getColumn(),
        SASS_CALLEE_FUNCTION,
        { env }
      });

      Definition* def = Cast<Definition>((*env)["@warn[f]"]);
      // Block_Obj          body   = def->block();
      // Native_Function func   = def->native_function();
      Sass_Function_Entry c_function = def->c_function();
      Sass_Function_Fn c_func = sass_function_get_function(c_function);

      AST2C ast2c;
      union Sass_Value* c_args = sass_make_list(1, SASS_COMMA, false);
      sass_list_set_value(c_args, 0, message->perform(&ast2c));
      union Sass_Value* c_val = c_func(c_args, c_function, compiler());
      options().output_style = outstyle;
      callee_stack().pop_back();
      sass_delete_value(c_args);
      sass_delete_value(c_val);
      return 0;

    }

    sass::string result(unquote(message->to_sass()));
    std::cerr << "WARNING: " << result << std::endl;
    traces.push_back(Backtrace(w->pstate()));
    std::cerr << traces_to_string(traces, "         ");
    std::cerr << std::endl;
    options().output_style = outstyle;
    traces.pop_back();
    return 0;
  }

  Expression* Eval::operator()(ErrorRule* e)
  {
    Sass_Output_Style outstyle = options().output_style;
    options().output_style = NESTED;
    ExpressionObj message = e->message()->perform(this);
    Env* env = environment();

    // try to use generic function
    if (env->has("@error[f]")) {

      // add call stack entry
      callee_stack().push_back({
        "@error",
        e->pstate().getPath(),
        e->pstate().getLine(),
        e->pstate().getColumn(),
        SASS_CALLEE_FUNCTION,
        { env }
      });

      Definition* def = Cast<Definition>((*env)["@error[f]"]);
      // Block_Obj          body   = def->block();
      // Native_Function func   = def->native_function();
      Sass_Function_Entry c_function = def->c_function();
      Sass_Function_Fn c_func = sass_function_get_function(c_function);

      AST2C ast2c;
      union Sass_Value* c_args = sass_make_list(1, SASS_COMMA, false);
      sass_list_set_value(c_args, 0, message->perform(&ast2c));
      union Sass_Value* c_val = c_func(c_args, c_function, compiler());
      options().output_style = outstyle;
      callee_stack().pop_back();
      sass_delete_value(c_args);
      sass_delete_value(c_val);
      return 0;

    }

    sass::string result(unquote(message->to_sass()));
    options().output_style = outstyle;
    error(result, e->pstate(), traces);
    return 0;
  }

  Expression* Eval::operator()(DebugRule* d)
  {
    Sass_Output_Style outstyle = options().output_style;
    options().output_style = NESTED;
    ExpressionObj message = d->value()->perform(this);
    Env* env = environment();

    // try to use generic function
    if (env->has("@debug[f]")) {

      // add call stack entry
      callee_stack().push_back({
        "@debug",
        d->pstate().getPath(),
        d->pstate().getLine(),
        d->pstate().getColumn(),
        SASS_CALLEE_FUNCTION,
        { env }
      });

      Definition* def = Cast<Definition>((*env)["@debug[f]"]);
      // Block_Obj          body   = def->block();
      // Native_Function func   = def->native_function();
      Sass_Function_Entry c_function = def->c_function();
      Sass_Function_Fn c_func = sass_function_get_function(c_function);

      AST2C ast2c;
      union Sass_Value* c_args = sass_make_list(1, SASS_COMMA, false);
      sass_list_set_value(c_args, 0, message->perform(&ast2c));
      union Sass_Value* c_val = c_func(c_args, c_function, compiler());
      options().output_style = outstyle;
      callee_stack().pop_back();
      sass_delete_value(c_args);
      sass_delete_value(c_val);
      return 0;

    }

    sass::string result(unquote(message->to_sass()));
    sass::string abs_path(Sass::File::rel2abs(d->pstate().getPath(), cwd(), cwd()));
    sass::string rel_path(Sass::File::abs2rel(d->pstate().getPath(), cwd(), cwd()));
    sass::string output_path(Sass::File::path_for_console(rel_path, abs_path, d->pstate().getPath()));
    options().output_style = outstyle;

    std::cerr << output_path << ":" << d->pstate().getLine() << " DEBUG: " << result;
    std::cerr << std::endl;
    return 0;
  }


  Expression* Eval::operator()(List* l)
  {
    // special case for unevaluated map
    if (l->separator() == SASS_HASH) {
      Map_Obj lm = SASS_MEMORY_NEW(Map,
                                l->pstate(),
                                l->length() / 2);
      for (size_t i = 0, L = l->length(); i < L; i += 2)
      {
        ExpressionObj key = (*l)[i+0]->perform(this);
        ExpressionObj val = (*l)[i+1]->perform(this);
        // make sure the color key never displays its real name
        key->is_delayed(true); // verified
        *lm << std::make_pair(key, val);
      }
      if (lm->has_duplicate_key()) {
        traces.push_back(Backtrace(l->pstate()));
        throw Exception::DuplicateKeyError(traces, *lm, *l);
      }

      lm->is_interpolant(l->is_interpolant());
      return lm->perform(this);
    }
    // check if we should expand it
    if (l->is_expanded()) return l;
    // regular case for unevaluated lists
    List_Obj ll = SASS_MEMORY_NEW(List,
                               l->pstate(),
                               l->length(),
                               l->separator(),
                               l->is_arglist(),
                               l->is_bracketed());
    for (size_t i = 0, L = l->length(); i < L; ++i) {
      ll->append((*l)[i]->perform(this));
    }
    ll->is_interpolant(l->is_interpolant());
    ll->from_selector(l->from_selector());
    ll->is_expanded(true);
    return ll.detach();
  }

  Expression* Eval::operator()(Map* m)
  {
    if (m->is_expanded()) return m;

    // make sure we're not starting with duplicate keys.
    // the duplicate key state will have been set in the parser phase.
    if (m->has_duplicate_key()) {
      traces.push_back(Backtrace(m->pstate()));
      throw Exception::DuplicateKeyError(traces, *m, *m);
    }

    Map_Obj mm = SASS_MEMORY_NEW(Map,
                                m->pstate(),
                                m->length());
    for (auto key : m->keys()) {
      Expression* ex_key = key->perform(this);
      Expression* ex_val = m->at(key);
      if (ex_val == NULL) continue;
      ex_val = ex_val->perform(this);
      *mm << std::make_pair(ex_key, ex_val);
    }

    // check the evaluated keys aren't duplicates.
    if (mm->has_duplicate_key()) {
      traces.push_back(Backtrace(m->pstate()));
      throw Exception::DuplicateKeyError(traces, *mm, *m);
    }

    mm->is_expanded(true);
    return mm.detach();
  }

  Expression* Eval::operator()(Binary_Expression* b_in)
  {

    ExpressionObj lhs = b_in->left();
    ExpressionObj rhs = b_in->right();
    enum Sass_OP op_type = b_in->optype();

    if (op_type == Sass_OP::AND) {
      // LOCAL_FLAG(force, true);
      lhs = lhs->perform(this);
      if (!*lhs) return lhs.detach();
      return rhs->perform(this);
    }
    else if (op_type == Sass_OP::OR) {
      // LOCAL_FLAG(force, true);
      lhs = lhs->perform(this);
      if (*lhs) return lhs.detach();
      return rhs->perform(this);
    }

    // Evaluate variables as early o
    while (Variable* l_v = Cast<Variable>(lhs)) {
      lhs = operator()(l_v);
    }
    while (Variable* r_v = Cast<Variable>(rhs)) {
      rhs = operator()(r_v);
    }

    Binary_ExpressionObj b = b_in;

    // Evaluate sub-expressions early on
    while (Binary_Expression* l_b = Cast<Binary_Expression>(lhs)) {
      if (!force && l_b->is_delayed()) break;
      lhs = operator()(l_b);
    }
    while (Binary_Expression* r_b = Cast<Binary_Expression>(rhs)) {
      if (!force && r_b->is_delayed()) break;
      rhs = operator()(r_b);
    }

    // don't eval delayed expressions (the '/' when used as a separator)
    if (!force && op_type == Sass_OP::DIV && b->is_delayed()) {
      b->right(b->right()->perform(this));
      b->left(b->left()->perform(this));
      return b.detach();
    }

    // specific types we know are final
    // handle them early to avoid overhead
    if (Number* l_n = Cast<Number>(lhs)) {
      // lhs is number and rhs is number
      if (Number* r_n = Cast<Number>(rhs)) {
        try {
          switch (op_type) {
            case Sass_OP::EQ: return *l_n == *r_n ? bool_true : bool_false;
            case Sass_OP::NEQ: return *l_n == *r_n ? bool_false : bool_true;
            case Sass_OP::LT: return *l_n < *r_n ? bool_true : bool_false;
            case Sass_OP::GTE: return *l_n < *r_n ? bool_false : bool_true;
            case Sass_OP::LTE: return *l_n < *r_n || *l_n == *r_n ? bool_true : bool_false;
            case Sass_OP::GT: return *l_n < *r_n || *l_n == *r_n ? bool_false : bool_true;
            case Sass_OP::ADD: case Sass_OP::SUB: case Sass_OP::MUL: case Sass_OP::DIV: case Sass_OP::MOD:
              return Operators::op_numbers(op_type, *l_n, *r_n, options(), b_in->pstate());
            default: break;
          }
        }
        catch (Exception::OperationError& err)
        {
          traces.push_back(Backtrace(b_in->pstate()));
          throw Exception::SassValueError(traces, b_in->pstate(), err);
        }
      }
      // lhs is number and rhs is color
      // Todo: allow to work with HSLA colors
      else if (Color* r_col = Cast<Color>(rhs)) {
        Color_RGBA_Obj r_c = r_col->toRGBA();
        try {
          switch (op_type) {
            case Sass_OP::EQ: return *l_n == *r_c ? bool_true : bool_false;
            case Sass_OP::NEQ: return *l_n == *r_c ? bool_false : bool_true;
            case Sass_OP::ADD: case Sass_OP::SUB: case Sass_OP::MUL: case Sass_OP::DIV: case Sass_OP::MOD:
              return Operators::op_number_color(op_type, *l_n, *r_c, options(), b_in->pstate());
            default: break;
          }
        }
        catch (Exception::OperationError& err)
        {
          traces.push_back(Backtrace(b_in->pstate()));
          throw Exception::SassValueError(traces, b_in->pstate(), err);
        }
      }
    }
    else if (Color* l_col = Cast<Color>(lhs)) {
      Color_RGBA_Obj l_c = l_col->toRGBA();
      // lhs is color and rhs is color
      if (Color* r_col = Cast<Color>(rhs)) {
        Color_RGBA_Obj r_c = r_col->toRGBA();
        try {
          switch (op_type) {
            case Sass_OP::EQ: return *l_c == *r_c ? bool_true : bool_false;
            case Sass_OP::NEQ: return *l_c == *r_c ? bool_false : bool_true;
            case Sass_OP::LT: return *l_c < *r_c ? bool_true : bool_false;
            case Sass_OP::GTE: return *l_c < *r_c ? bool_false : bool_true;
            case Sass_OP::LTE: return *l_c < *r_c || *l_c == *r_c ? bool_true : bool_false;
            case Sass_OP::GT: return *l_c < *r_c || *l_c == *r_c ? bool_false : bool_true;
            case Sass_OP::ADD: case Sass_OP::SUB: case Sass_OP::MUL: case Sass_OP::DIV: case Sass_OP::MOD:
              return Operators::op_colors(op_type, *l_c, *r_c, options(), b_in->pstate());
            default: break;
          }
        }
        catch (Exception::OperationError& err)
        {
          traces.push_back(Backtrace(b_in->pstate()));
          throw Exception::SassValueError(traces, b_in->pstate(), err);
        }
      }
      // lhs is color and rhs is number
      else if (Number* r_n = Cast<Number>(rhs)) {
        try {
          switch (op_type) {
            case Sass_OP::EQ: return *l_c == *r_n ? bool_true : bool_false;
            case Sass_OP::NEQ: return *l_c == *r_n ? bool_false : bool_true;
            case Sass_OP::ADD: case Sass_OP::SUB: case Sass_OP::MUL: case Sass_OP::DIV: case Sass_OP::MOD:
              return Operators::op_color_number(op_type, *l_c, *r_n, options(), b_in->pstate());
            default: break;
          }
        }
        catch (Exception::OperationError& err)
        {
          traces.push_back(Backtrace(b_in->pstate()));
          throw Exception::SassValueError(traces, b_in->pstate(), err);
        }
      }
    }

    String_Schema_Obj ret_schema;

    // only the last item will be used to eval the binary expression
    if (String_Schema* s_l = Cast<String_Schema>(b->left())) {
      if (!s_l->has_interpolant() && (!s_l->is_right_interpolant())) {
        ret_schema = SASS_MEMORY_NEW(String_Schema, b->pstate());
        Binary_ExpressionObj bin_ex = SASS_MEMORY_NEW(Binary_Expression, b->pstate(),
                                                    b->op(), s_l->last(), b->right());
        bin_ex->is_delayed(b->left()->is_delayed() || b->right()->is_delayed()); // unverified
        for (size_t i = 0; i < s_l->length() - 1; ++i) {
          ret_schema->append(s_l->at(i)->perform(this));
        }
        ret_schema->append(bin_ex->perform(this));
        return ret_schema->perform(this);
      }
    }
    if (String_Schema* s_r = Cast<String_Schema>(b->right())) {

      if (!s_r->has_interpolant() && (!s_r->is_left_interpolant() || op_type == Sass_OP::DIV)) {
        ret_schema = SASS_MEMORY_NEW(String_Schema, b->pstate());
        Binary_ExpressionObj bin_ex = SASS_MEMORY_NEW(Binary_Expression, b->pstate(),
                                                    b->op(), b->left(), s_r->first());
        bin_ex->is_delayed(b->left()->is_delayed() || b->right()->is_delayed()); // verified
        ret_schema->append(bin_ex->perform(this));
        for (size_t i = 1; i < s_r->length(); ++i) {
          ret_schema->append(s_r->at(i)->perform(this));
        }
        return ret_schema->perform(this);
      }
    }

    // fully evaluate their values
    if (op_type == Sass_OP::EQ ||
        op_type == Sass_OP::NEQ ||
        op_type == Sass_OP::GT ||
        op_type == Sass_OP::GTE ||
        op_type == Sass_OP::LT ||
        op_type == Sass_OP::LTE)
    {
      LOCAL_FLAG(force, true);
      lhs->is_expanded(false);
      lhs->set_delayed(false);
      lhs = lhs->perform(this);
      rhs->is_expanded(false);
      rhs->set_delayed(false);
      rhs = rhs->perform(this);
    }
    else {
      lhs = lhs->perform(this);
    }

    // not a logical connective, so go ahead and eval the rhs
    rhs = rhs->perform(this);
    AST_Node_Obj lu = lhs;
    AST_Node_Obj ru = rhs;

    Expression::Type l_type;
    Expression::Type r_type;

    // Is one of the operands an interpolant?
    String_Schema_Obj s1 = Cast<String_Schema>(b->left());
    String_Schema_Obj s2 = Cast<String_Schema>(b->right());
    Binary_ExpressionObj b1 = Cast<Binary_Expression>(b->left());
    Binary_ExpressionObj b2 = Cast<Binary_Expression>(b->right());

    bool schema_op = false;

    bool force_delay = (s2 && s2->is_left_interpolant()) ||
                       (s1 && s1->is_right_interpolant()) ||
                       (b1 && b1->is_right_interpolant()) ||
                       (b2 && b2->is_left_interpolant());

    if ((s1 && s1->has_interpolants()) || (s2 && s2->has_interpolants()) || force_delay)
    {
      if (op_type == Sass_OP::DIV || op_type == Sass_OP::MUL || op_type == Sass_OP::MOD || op_type == Sass_OP::ADD || op_type == Sass_OP::SUB ||
          op_type == Sass_OP::EQ) {
        // If possible upgrade LHS to a number (for number to string compare)
        if (String_Constant* str = Cast<String_Constant>(lhs)) {
          sass::string value(str->value());
          const char* start = value.c_str();
          if (Prelexer::sequence < Prelexer::dimension, Prelexer::end_of_file >(start) != 0) {
            lhs = Parser::lexed_dimension(b->pstate(), str->value());
          }
        }
        // If possible upgrade RHS to a number (for string to number compare)
        if (String_Constant* str = Cast<String_Constant>(rhs)) {
          sass::string value(str->value());
          const char* start = value.c_str();
          if (Prelexer::sequence < Prelexer::dimension, Prelexer::number >(start) != 0) {
            rhs = Parser::lexed_dimension(b->pstate(), str->value());
          }
        }
      }

      To_Value to_value(ctx);
      ValueObj v_l = Cast<Value>(lhs->perform(&to_value));
      ValueObj v_r = Cast<Value>(rhs->perform(&to_value));

      if (force_delay) {
        sass::string str("");
        str += v_l->to_string(options());
        if (b->op().ws_before) str += " ";
        str += b->separator();
        if (b->op().ws_after) str += " ";
        str += v_r->to_string(options());
        String_Constant* val = SASS_MEMORY_NEW(String_Constant, b->pstate(), str);
        val->is_interpolant(b->left()->has_interpolant());
        return val;
      }
    }

    // see if it's a relational expression
    try {
      switch(op_type) {
        case Sass_OP::EQ:  return SASS_MEMORY_NEW(Boolean, b->pstate(), Operators::eq(lhs, rhs));
        case Sass_OP::NEQ: return SASS_MEMORY_NEW(Boolean, b->pstate(), Operators::neq(lhs, rhs));
        case Sass_OP::GT:  return SASS_MEMORY_NEW(Boolean, b->pstate(), Operators::gt(lhs, rhs));
        case Sass_OP::GTE: return SASS_MEMORY_NEW(Boolean, b->pstate(), Operators::gte(lhs, rhs));
        case Sass_OP::LT:  return SASS_MEMORY_NEW(Boolean, b->pstate(), Operators::lt(lhs, rhs));
        case Sass_OP::LTE: return SASS_MEMORY_NEW(Boolean, b->pstate(), Operators::lte(lhs, rhs));
        default: break;
      }
    }
    catch (Exception::OperationError& err)
    {
      traces.push_back(Backtrace(b->pstate()));
      throw Exception::SassValueError(traces, b->pstate(), err);
    }

    l_type = lhs->concrete_type();
    r_type = rhs->concrete_type();

    // ToDo: throw error in op functions
    // ToDo: then catch and re-throw them
    ExpressionObj rv;
    try {
      SourceSpan pstate(b->pstate());
      if (l_type == Expression::NUMBER && r_type == Expression::NUMBER) {
        Number* l_n = Cast<Number>(lhs);
        Number* r_n = Cast<Number>(rhs);
        l_n->reduce(); r_n->reduce();
        rv = Operators::op_numbers(op_type, *l_n, *r_n, options(), pstate);
      }
      else if (l_type == Expression::NUMBER && r_type == Expression::COLOR) {
        Number* l_n = Cast<Number>(lhs);
        Color_RGBA_Obj r_c = Cast<Color>(rhs)->toRGBA();
        rv = Operators::op_number_color(op_type, *l_n, *r_c, options(), pstate);
      }
      else if (l_type == Expression::COLOR && r_type == Expression::NUMBER) {
        Color_RGBA_Obj l_c = Cast<Color>(lhs)->toRGBA();
        Number* r_n = Cast<Number>(rhs);
        rv = Operators::op_color_number(op_type, *l_c, *r_n, options(), pstate);
      }
      else if (l_type == Expression::COLOR && r_type == Expression::COLOR) {
        Color_RGBA_Obj l_c = Cast<Color>(lhs)->toRGBA();
        Color_RGBA_Obj r_c = Cast<Color>(rhs)->toRGBA();
        rv = Operators::op_colors(op_type, *l_c, *r_c, options(), pstate);
      }
      else {
        To_Value to_value(ctx);
        // this will leak if perform does not return a value!
        ValueObj v_l = Cast<Value>(lhs->perform(&to_value));
        ValueObj v_r = Cast<Value>(rhs->perform(&to_value));
        bool interpolant = b->is_right_interpolant() ||
                           b->is_left_interpolant() ||
                           b->is_interpolant();
        if (op_type == Sass_OP::SUB) interpolant = false;
        // if (op_type == Sass_OP::DIV) interpolant = true;
        // check for type violations
        if (l_type == Expression::MAP || l_type == Expression::FUNCTION_VAL) {
          traces.push_back(Backtrace(v_l->pstate()));
          throw Exception::InvalidValue(traces, *v_l);
        }
        if (r_type == Expression::MAP || l_type == Expression::FUNCTION_VAL) {
          traces.push_back(Backtrace(v_r->pstate()));
          throw Exception::InvalidValue(traces, *v_r);
        }
        Value* ex = Operators::op_strings(b->op(), *v_l, *v_r, options(), pstate, !interpolant); // pass true to compress
        if (String_Constant* str = Cast<String_Constant>(ex))
        {
          if (str->concrete_type() == Expression::STRING)
          {
            String_Constant* lstr = Cast<String_Constant>(lhs);
            String_Constant* rstr = Cast<String_Constant>(rhs);
            if (op_type != Sass_OP::SUB) {
              if (String_Constant* org = lstr ? lstr : rstr)
              { str->quote_mark(org->quote_mark()); }
            }
          }
        }
        ex->is_interpolant(b->is_interpolant());
        rv = ex;
      }
    }
    catch (Exception::OperationError& err)
    {
      traces.push_back(Backtrace(b->pstate()));
      // throw Exception::Base(b->pstate(), err.what());
      throw Exception::SassValueError(traces, b->pstate(), err);
    }

    if (rv) {
      if (schema_op) {
        // XXX: this is never hit via spec tests
        (*s2)[0] = rv;
        rv = s2->perform(this);
      }
    }

    return rv.detach();

  }

  Expression* Eval::operator()(Unary_Expression* u)
  {
    ExpressionObj operand = u->operand()->perform(this);
    if (u->optype() == Unary_Expression::NOT) {
      Boolean* result = SASS_MEMORY_NEW(Boolean, u->pstate(), (bool)*operand);
      result->value(!result->value());
      return result;
    }
    else if (Number_Obj nr = Cast<Number>(operand)) {
      // negate value for minus unary expression
      if (u->optype() == Unary_Expression::MINUS) {
        Number_Obj cpy = SASS_MEMORY_COPY(nr);
        cpy->value( - cpy->value() ); // negate value
        return cpy.detach(); // return the copy
      }
      else if (u->optype() == Unary_Expression::SLASH) {
        sass::string str = '/' + nr->to_string(options());
        return SASS_MEMORY_NEW(String_Constant, u->pstate(), str);
      }
      // nothing for positive
      return nr.detach();
    }
    else {
      // Special cases: +/- variables which evaluate to null output just +/-,
      // but +/- null itself outputs the string
      if (operand->concrete_type() == Expression::NULL_VAL && Cast<Variable>(u->operand())) {
        u->operand(SASS_MEMORY_NEW(String_Quoted, u->pstate(), ""));
      }
      // Never apply unary opertions on colors @see #2140
      else if (Color* color = Cast<Color>(operand)) {
        // Use the color name if this was eval with one
        if (color->disp().length() > 0) {
          Unary_ExpressionObj cpy = SASS_MEMORY_COPY(u);
          cpy->operand(SASS_MEMORY_NEW(String_Constant, operand->pstate(), color->disp()));
          return SASS_MEMORY_NEW(String_Quoted,
                                 cpy->pstate(),
                                 cpy->inspect());
        }
      }
      else {
        Unary_ExpressionObj cpy = SASS_MEMORY_COPY(u);
        cpy->operand(operand);
        return SASS_MEMORY_NEW(String_Quoted,
                               cpy->pstate(),
                               cpy->inspect());
      }

      return SASS_MEMORY_NEW(String_Quoted,
                             u->pstate(),
                             u->inspect());
    }
    // unreachable
    return u;
  }

  Expression* Eval::operator()(Function_Call* c)
  {
    if (traces.size() > Constants::MaxCallStack) {
        // XXX: this is never hit via spec tests
        sass::ostream stm;
        stm << "Stack depth exceeded max of " << Constants::MaxCallStack;
        error(stm.str(), c->pstate(), traces);
    }

    if (Cast<String_Schema>(c->sname())) {
      ExpressionObj evaluated_name = c->sname()->perform(this);
      ExpressionObj evaluated_args = c->arguments()->perform(this);
      sass::string str(evaluated_name->to_string());
      str += evaluated_args->to_string();
      return SASS_MEMORY_NEW(String_Constant, c->pstate(), str);
    }

    sass::string name(Util::normalize_underscores(c->name()));
    sass::string full_name(name + "[f]");

    // we make a clone here, need to implement that further
    Arguments_Obj args = c->arguments();

    Env* env = environment();
    if (!env->has(full_name) || (!c->via_call() && Prelexer::re_special_fun(name.c_str()))) {
      if (!env->has("*[f]")) {
        for (Argument_Obj arg : args->elements()) {
          if (List_Obj ls = Cast<List>(arg->value())) {
            if (ls->size() == 0) error("() isn't a valid CSS value.", c->pstate(), traces);
          }
        }
        args = Cast<Arguments>(args->perform(this));
        Function_Call_Obj lit = SASS_MEMORY_NEW(Function_Call,
                                             c->pstate(),
                                             c->name(),
                                             args);
        if (args->has_named_arguments()) {
          error("Plain CSS function " + c->name() + " doesn't support keyword arguments", c->pstate(), traces);
        }
        String_Quoted* str = SASS_MEMORY_NEW(String_Quoted,
                                             c->pstate(),
                                             lit->to_string(options()));
        str->is_interpolant(c->is_interpolant());
        return str;
      } else {
        // call generic function
        full_name = "*[f]";
      }
    }

    // further delay for calls
    if (full_name != "call[f]") {
      args->set_delayed(false); // verified
    }
    if (full_name != "if[f]") {
      args = Cast<Arguments>(args->perform(this));
    }
    Definition* def = Cast<Definition>((*env)[full_name]);

    if (c->func()) def = c->func()->definition();

    if (def->is_overload_stub()) {
      sass::ostream ss;
      size_t L = args->length();
      // account for rest arguments
      if (args->has_rest_argument() && args->length() > 0) {
        // get the rest arguments list
        List* rest = Cast<List>(args->last()->value());
        // arguments before rest argument plus rest
        if (rest) L += rest->length() - 1;
      }
      ss << full_name << L;
      full_name = ss.str();
      sass::string resolved_name(full_name);
      if (!env->has(resolved_name)) error("overloaded function `" + sass::string(c->name()) + "` given wrong number of arguments", c->pstate(), traces);
      def = Cast<Definition>((*env)[resolved_name]);
    }

    ExpressionObj     result = c;
    Block_Obj          body   = def->block();
    Native_Function func   = def->native_function();
    Sass_Function_Entry c_function = def->c_function();

    if (c->is_css()) return result.detach();

    Parameters_Obj params = def->parameters();
    Env fn_env(def->environment());
    env_stack().push_back(&fn_env);

    if (func || body) {
      bind(sass::string("Function"), c->name(), params, args, &fn_env, this, traces);
      sass::string msg(", in function `" + c->name() + "`");
      traces.push_back(Backtrace(c->pstate(), msg));
      callee_stack().push_back({
        c->name().c_str(),
        c->pstate().getPath(),
        c->pstate().getLine(),
        c->pstate().getColumn(),
        SASS_CALLEE_FUNCTION,
        { env }
      });

      // eval the body if user-defined or special, invoke underlying CPP function if native
      if (body /* && !Prelexer::re_special_fun(name.c_str()) */) {
        result = body->perform(this);
      }
      else if (func) {
        result = func(fn_env, *env, ctx, def->signature(), c->pstate(), traces, exp.getSelectorStack(), exp.originalStack);
      }
      if (!result) {
        error(sass::string("Function ") + c->name() + " finished without @return", c->pstate(), traces);
      }
      callee_stack().pop_back();
      traces.pop_back();
    }

    // else if it's a user-defined c function
    // convert call into C-API compatible form
    else if (c_function) {
      Sass_Function_Fn c_func = sass_function_get_function(c_function);
      if (full_name == "*[f]") {
        String_Quoted_Obj str = SASS_MEMORY_NEW(String_Quoted, c->pstate(), c->name());
        Arguments_Obj new_args = SASS_MEMORY_NEW(Arguments, c->pstate());
        new_args->append(SASS_MEMORY_NEW(Argument, c->pstate(), str));
        new_args->concat(args);
        args = new_args;
      }

      // populates env with default values for params
      sass::string ff(c->name());
      bind(sass::string("Function"), c->name(), params, args, &fn_env, this, traces);
      sass::string msg(", in function `" + c->name() + "`");
      traces.push_back(Backtrace(c->pstate(), msg));
      callee_stack().push_back({
        c->name().c_str(),
        c->pstate().getPath(),
        c->pstate().getLine(),
        c->pstate().getColumn(),
        SASS_CALLEE_C_FUNCTION,
        { env }
      });

      AST2C ast2c;
      union Sass_Value* c_args = sass_make_list(params->length(), SASS_COMMA, false);
      for(size_t i = 0; i < params->length(); i++) {
        Parameter_Obj param = params->at(i);
        sass::string key = param->name();
        AST_Node_Obj node = fn_env.get_local(key);
        ExpressionObj arg = Cast<Expression>(node);
        sass_list_set_value(c_args, i, arg->perform(&ast2c));
      }
      union Sass_Value* c_val = c_func(c_args, c_function, compiler());
      if (sass_value_get_tag(c_val) == SASS_ERROR) {
        sass::string message("error in C function " + c->name() + ": " + sass_error_get_message(c_val));
        sass_delete_value(c_val);
        sass_delete_value(c_args);
        error(message, c->pstate(), traces);
      } else if (sass_value_get_tag(c_val) == SASS_WARNING) {
        sass::string message("warning in C function " + c->name() + ": " + sass_warning_get_message(c_val));
        sass_delete_value(c_val);
        sass_delete_value(c_args);
        error(message, c->pstate(), traces);
      }
      result = c2ast(c_val, traces, c->pstate());

      callee_stack().pop_back();
      traces.pop_back();
      sass_delete_value(c_args);
      if (c_val != c_args)
        sass_delete_value(c_val);
    }

    // link back to function definition
    // only do this for custom functions
    if (result->pstate().getSrcId() == sass::string::npos)
      result->pstate(c->pstate());

    result = result->perform(this);
    result->is_interpolant(c->is_interpolant());
    env_stack().pop_back();
    return result.detach();
  }

  Expression* Eval::operator()(Variable* v)
  {
    ExpressionObj value;
    Env* env = environment();
    const sass::string& name(v->name());
    EnvResult rv(env->find(name));
    if (rv.found) value = static_cast<Expression*>(rv.it->second.ptr());
    else error("Undefined variable: \"" + v->name() + "\".", v->pstate(), traces);
    if (Argument* arg = Cast<Argument>(value)) value = arg->value();
    if (Number* nr = Cast<Number>(value)) nr->zero(true); // force flag
    value->is_interpolant(v->is_interpolant());
    if (force) value->is_expanded(false);
    value->set_delayed(false); // verified
    value = value->perform(this);
    if(!force) rv.it->second = value;
    return value.detach();
  }

  Expression* Eval::operator()(Color_RGBA* c)
  {
    return c;
  }

  Expression* Eval::operator()(Color_HSLA* c)
  {
    return c;
  }

  Expression* Eval::operator()(Number* n)
  {
    return n;
  }

  Expression* Eval::operator()(Boolean* b)
  {
    return b;
  }

  void Eval::interpolation(Context& ctx, sass::string& res, ExpressionObj ex, bool into_quotes, bool was_itpl) {

    bool needs_closing_brace = false;

    if (Arguments* args = Cast<Arguments>(ex)) {
      List* ll = SASS_MEMORY_NEW(List, args->pstate(), 0, SASS_COMMA);
      for(auto arg : args->elements()) {
        ll->append(arg->value());
      }
      ll->is_interpolant(args->is_interpolant());
      needs_closing_brace = true;
      res += "(";
      ex = ll;
    }
    if (Number* nr = Cast<Number>(ex)) {
      Number reduced(nr);
      reduced.reduce();
      if (!reduced.is_valid_css_unit()) {
        traces.push_back(Backtrace(nr->pstate()));
        throw Exception::InvalidValue(traces, *nr);
      }
    }
    if (Argument* arg = Cast<Argument>(ex)) {
      ex = arg->value();
    }
    if (String_Quoted* sq = Cast<String_Quoted>(ex)) {
      if (was_itpl) {
        bool was_interpolant = ex->is_interpolant();
        ex = SASS_MEMORY_NEW(String_Constant, sq->pstate(), sq->value());
        ex->is_interpolant(was_interpolant);
      }
    }

    if (Cast<Null>(ex)) { return; }

    // parent selector needs another go
    if (Cast<Parent_Reference>(ex)) {
      // XXX: this is never hit via spec tests
      ex = ex->perform(this);
    }

    if (List* l = Cast<List>(ex)) {
      List_Obj ll = SASS_MEMORY_NEW(List, l->pstate(), 0, l->separator());
      // this fixes an issue with bourbon sample, not really sure why
      // if (l->size() && Cast<Null>((*l)[0])) { res += ""; }
      for(ExpressionObj item : *l) {
        item->is_interpolant(l->is_interpolant());
        sass::string rl(""); interpolation(ctx, rl, item, into_quotes, l->is_interpolant());
        bool is_null = Cast<Null>(item) != 0; // rl != ""
        if (!is_null) ll->append(SASS_MEMORY_NEW(String_Quoted, item->pstate(), rl));
      }
      // Check indicates that we probably should not get a list
      // here. Normally single list items are already unwrapped.
      if (l->size() > 1) {
        // string_to_output would fail "#{'_\a' '_\a'}";
        sass::string str(ll->to_string(options()));
        str = read_hex_escapes(str); // read escapes
        newline_to_space(str); // replace directly
        res += str; // append to result string
      } else {
        res += (ll->to_string(options()));
      }
      ll->is_interpolant(l->is_interpolant());
    }

    // Value
    // Function_Call
    // Selector_List
    // String_Quoted
    // String_Constant
    // Binary_Expression
    else {
      // ex = ex->perform(this);
      if (into_quotes && ex->is_interpolant()) {
        res += evacuate_escapes(ex ? ex->to_string(options()) : "");
      } else {
        sass::string str(ex ? ex->to_string(options()) : "");
        if (into_quotes) str = read_hex_escapes(str);
        res += str; // append to result string
      }
    }

    if (needs_closing_brace) res += ")";

  }

  Expression* Eval::operator()(String_Schema* s)
  {
    size_t L = s->length();
    bool into_quotes = false;
    if (L > 1) {
      if (!Cast<String_Quoted>((*s)[0]) && !Cast<String_Quoted>((*s)[L - 1])) {
      if (String_Constant* l = Cast<String_Constant>((*s)[0])) {
        if (String_Constant* r = Cast<String_Constant>((*s)[L - 1])) {
          if (r->value().size() > 0) {
            if (l->value()[0] == '"' && r->value()[r->value().size() - 1] == '"') into_quotes = true;
            if (l->value()[0] == '\'' && r->value()[r->value().size() - 1] == '\'') into_quotes = true;
          }
        }
      }
      }
    }
    bool was_quoted = false;
    bool was_interpolant = false;
    sass::string res("");
    for (size_t i = 0; i < L; ++i) {
      bool is_quoted = Cast<String_Quoted>((*s)[i]) != NULL;
      if (was_quoted && !(*s)[i]->is_interpolant() && !was_interpolant) { res += " "; }
      else if (i > 0 && is_quoted && !(*s)[i]->is_interpolant() && !was_interpolant) { res += " "; }
      ExpressionObj ex = (*s)[i]->perform(this);
      interpolation(ctx, res, ex, into_quotes, ex->is_interpolant());
      was_quoted = Cast<String_Quoted>((*s)[i]) != NULL;
      was_interpolant = (*s)[i]->is_interpolant();

    }
    if (!s->is_interpolant()) {
      if (s->length() > 1 && res == "") return SASS_MEMORY_NEW(Null, s->pstate());
      String_Constant_Obj str = SASS_MEMORY_NEW(String_Constant, s->pstate(), res, s->css());
      return str.detach();
    }
    // string schema seems to have a special unquoting behavior (also handles "nested" quotes)
    String_Quoted_Obj str = SASS_MEMORY_NEW(String_Quoted, s->pstate(), res, 0, false, false, false, s->css());
    // if (s->is_interpolant()) str->quote_mark(0);
    // String_Constant* str = SASS_MEMORY_NEW(String_Constant, s->pstate(), res);
    if (str->quote_mark()) str->quote_mark('*');
    else if (!is_in_comment) str->value(string_to_output(str->value()));
    str->is_interpolant(s->is_interpolant());
    return str.detach();
  }


  Expression* Eval::operator()(String_Constant* s)
  {
    return s;
  }

  Expression* Eval::operator()(String_Quoted* s)
  {
    String_Quoted* str = SASS_MEMORY_NEW(String_Quoted, s->pstate(), "");
    str->value(s->value());
    str->quote_mark(s->quote_mark());
    str->is_interpolant(s->is_interpolant());
    return str;
  }

  Expression* Eval::operator()(SupportsOperation* c)
  {
    Expression* left = c->left()->perform(this);
    Expression* right = c->right()->perform(this);
    SupportsOperation* cc = SASS_MEMORY_NEW(SupportsOperation,
                                 c->pstate(),
                                 Cast<SupportsCondition>(left),
                                 Cast<SupportsCondition>(right),
                                 c->operand());
    return cc;
  }

  Expression* Eval::operator()(SupportsNegation* c)
  {
    Expression* condition = c->condition()->perform(this);
    SupportsNegation* cc = SASS_MEMORY_NEW(SupportsNegation,
                                 c->pstate(),
                                 Cast<SupportsCondition>(condition));
    return cc;
  }

  Expression* Eval::operator()(SupportsDeclaration* c)
  {
    Expression* feature = c->feature()->perform(this);
    Expression* value = c->value()->perform(this);
    SupportsDeclaration* cc = SASS_MEMORY_NEW(SupportsDeclaration,
                              c->pstate(),
                              feature,
                              value);
    return cc;
  }

  Expression* Eval::operator()(Supports_Interpolation* c)
  {
    Expression* value = c->value()->perform(this);
    Supports_Interpolation* cc = SASS_MEMORY_NEW(Supports_Interpolation,
                            c->pstate(),
                            value);
    return cc;
  }

  Expression* Eval::operator()(At_Root_Query* e)
  {
    ExpressionObj feature = e->feature();
    feature = (feature ? feature->perform(this) : 0);
    ExpressionObj value = e->value();
    value = (value ? value->perform(this) : 0);
    Expression* ee = SASS_MEMORY_NEW(At_Root_Query,
                                     e->pstate(),
                                     Cast<String>(feature),
                                     value);
    return ee;
  }

  Media_Query* Eval::operator()(Media_Query* q)
  {
    String_Obj t = q->media_type();
    t = static_cast<String*>(t.isNull() ? 0 : t->perform(this));
    Media_Query_Obj qq = SASS_MEMORY_NEW(Media_Query,
                                      q->pstate(),
                                      t,
                                      q->length(),
                                      q->is_negated(),
                                      q->is_restricted());
    for (size_t i = 0, L = q->length(); i < L; ++i) {
      qq->append(static_cast<Media_Query_Expression*>((*q)[i]->perform(this)));
    }
    return qq.detach();
  }

  Expression* Eval::operator()(Media_Query_Expression* e)
  {
    ExpressionObj feature = e->feature();
    feature = (feature ? feature->perform(this) : 0);
    if (feature && Cast<String_Quoted>(feature)) {
      feature = SASS_MEMORY_NEW(String_Quoted,
                                  feature->pstate(),
                                  Cast<String_Quoted>(feature)->value());
    }
    ExpressionObj value = e->value();
    value = (value ? value->perform(this) : 0);
    if (value && Cast<String_Quoted>(value)) {
      // XXX: this is never hit via spec tests
      value = SASS_MEMORY_NEW(String_Quoted,
                                value->pstate(),
                                Cast<String_Quoted>(value)->value());
    }
    return SASS_MEMORY_NEW(Media_Query_Expression,
                           e->pstate(),
                           feature,
                           value,
                           e->is_interpolated());
  }

  Expression* Eval::operator()(Null* n)
  {
    return n;
  }

  Expression* Eval::operator()(Argument* a)
  {
    ExpressionObj val = a->value()->perform(this);
    bool is_rest_argument = a->is_rest_argument();
    bool is_keyword_argument = a->is_keyword_argument();

    if (a->is_rest_argument()) {
      if (val->concrete_type() == Expression::MAP) {
        is_rest_argument = false;
        is_keyword_argument = true;
      }
      else if(val->concrete_type() != Expression::LIST) {
        List_Obj wrapper = SASS_MEMORY_NEW(List,
                                        val->pstate(),
                                        0,
                                        SASS_COMMA,
                                        true);
        wrapper->append(val);
        val = wrapper;
      }
    }
    return SASS_MEMORY_NEW(Argument,
                           a->pstate(),
                           val,
                           a->name(),
                           is_rest_argument,
                           is_keyword_argument);
  }

  Expression* Eval::operator()(Arguments* a)
  {
    Arguments_Obj aa = SASS_MEMORY_NEW(Arguments, a->pstate());
    if (a->length() == 0) return aa.detach();
    for (size_t i = 0, L = a->length(); i < L; ++i) {
      ExpressionObj rv = (*a)[i]->perform(this);
      Argument* arg = Cast<Argument>(rv);
      if (!(arg->is_rest_argument() || arg->is_keyword_argument())) {
        aa->append(arg);
      }
    }

    if (a->has_rest_argument()) {
      ExpressionObj rest = a->get_rest_argument()->perform(this);
      ExpressionObj splat = Cast<Argument>(rest)->value()->perform(this);

      Sass_Separator separator = SASS_COMMA;
      List* ls = Cast<List>(splat);
      Map* ms = Cast<Map>(splat);

      List_Obj arglist = SASS_MEMORY_NEW(List,
                                      splat->pstate(),
                                      0,
                                      ls ? ls->separator() : separator,
                                      true);

      if (ls && ls->is_arglist()) {
        arglist->concat(ls);
      } else if (ms) {
        aa->append(SASS_MEMORY_NEW(Argument, splat->pstate(), ms, "", false, true));
      } else if (ls) {
        arglist->concat(ls);
      } else {
        arglist->append(splat);
      }
      if (arglist->length()) {
        aa->append(SASS_MEMORY_NEW(Argument, splat->pstate(), arglist, "", true));
      }
    }

    if (a->has_keyword_argument()) {
      ExpressionObj rv = a->get_keyword_argument()->perform(this);
      Argument* rvarg = Cast<Argument>(rv);
      ExpressionObj kwarg = rvarg->value()->perform(this);

      aa->append(SASS_MEMORY_NEW(Argument, kwarg->pstate(), kwarg, "", false, true));
    }
    return aa.detach();
  }

  Expression* Eval::operator()(Comment* c)
  {
    return 0;
  }

  SelectorList* Eval::operator()(Selector_Schema* s)
  {
    LOCAL_FLAG(is_in_selector_schema, true);
    // the parser will look for a brace to end the selector
    ExpressionObj sel = s->contents()->perform(this);
    sass::string result_str(sel->to_string(options()));
    result_str = unquote(Util::rtrim(result_str));
    ItplFile* source = SASS_MEMORY_NEW(ItplFile,
      result_str.c_str(), s->pstate());
    Parser p(source, ctx, traces);

    // If a schema contains a reference to parent it is already
    // connected to it, so don't connect implicitly anymore
    SelectorListObj parsed = p.parseSelectorList(true);
    flag_is_in_selector_schema.reset();
    return parsed.detach();
  }

  Expression* Eval::operator()(Parent_Reference* p)
  {
    if (SelectorListObj pr = exp.original()) {
      return operator()(pr);
    } else {
      return SASS_MEMORY_NEW(Null, p->pstate());
    }
  }

  SimpleSelector* Eval::operator()(SimpleSelector* s)
  {
    return s;
  }

  PseudoSelector* Eval::operator()(PseudoSelector* pseudo)
  {
    // ToDo: should we eval selector?
    return pseudo;
  };

}
