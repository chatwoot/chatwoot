// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include <cmath>
#include <string>
#include <iostream>
#include <iomanip>
#include <stdint.h>
#include <stdint.h>

#include "ast.hpp"
#include "inspect.hpp"
#include "context.hpp"
#include "listize.hpp"
#include "color_maps.hpp"
#include "utf8/checked.h"

namespace Sass {

  Inspect::Inspect(const Emitter& emi)
  : Emitter(emi)
  { }
  Inspect::~Inspect() { }

  // statements
  void Inspect::operator()(Block* block)
  {
    if (!block->is_root()) {
      add_open_mapping(block);
      append_scope_opener();
    }
    if (output_style() == NESTED) indentation += block->tabs();
    for (size_t i = 0, L = block->length(); i < L; ++i) {
      (*block)[i]->perform(this);
    }
    if (output_style() == NESTED) indentation -= block->tabs();
    if (!block->is_root()) {
      append_scope_closer();
      add_close_mapping(block);
    }

  }

  void Inspect::operator()(StyleRule* ruleset)
  {
    if (ruleset->selector()) {
      ruleset->selector()->perform(this);
    }
    if (ruleset->block()) {
      ruleset->block()->perform(this);
    }
  }

  void Inspect::operator()(Keyframe_Rule* rule)
  {
    if (rule->name()) rule->name()->perform(this);
    if (rule->block()) rule->block()->perform(this);
  }

  void Inspect::operator()(Bubble* bubble)
  {
    append_indentation();
    append_token("::BUBBLE", bubble);
    append_scope_opener();
    bubble->node()->perform(this);
    append_scope_closer();
  }

  void Inspect::operator()(MediaRule* rule)
  {
    append_indentation();
    append_token("@media", rule);
    append_mandatory_space();
    if (rule->block()) {
      rule->block()->perform(this);
    }
  }

  void Inspect::operator()(CssMediaRule* rule)
  {
    if (output_style() == NESTED)
      indentation += rule->tabs();
    append_indentation();
    append_token("@media", rule);
    append_mandatory_space();
    in_media_block = true;
    bool joinIt = false;
    for (auto query : rule->elements()) {
      if (joinIt) {
        append_comma_separator();
        append_optional_space();
      }
      operator()(query);
      joinIt = true;
    }
    if (rule->block()) {
      rule->block()->perform(this);
    }
    in_media_block = false;
    if (output_style() == NESTED)
      indentation -= rule->tabs();
  }

  void Inspect::operator()(CssMediaQuery* query)
  {
    bool joinIt = false;
    if (!query->modifier().empty()) {
      append_string(query->modifier());
      append_mandatory_space();
    }
    if (!query->type().empty()) {
      append_string(query->type());
      joinIt = true;
    }
    for (auto feature : query->features()) {
      if (joinIt) {
        append_mandatory_space();
        append_string("and");
        append_mandatory_space();
      }
      append_string(feature);
      joinIt = true;
    }
  }

  void Inspect::operator()(SupportsRule* feature_block)
  {
    append_indentation();
    append_token("@supports", feature_block);
    append_mandatory_space();
    feature_block->condition()->perform(this);
    feature_block->block()->perform(this);
  }

  void Inspect::operator()(AtRootRule* at_root_block)
  {
    append_indentation();
    append_token("@at-root ", at_root_block);
    append_mandatory_space();
    if(at_root_block->expression()) at_root_block->expression()->perform(this);
    if(at_root_block->block()) at_root_block->block()->perform(this);
  }

  void Inspect::operator()(AtRule* at_rule)
  {
    append_indentation();
    append_token(at_rule->keyword(), at_rule);
    if (at_rule->selector()) {
      append_mandatory_space();
      bool was_wrapped = in_wrapped;
      in_wrapped = true;
      at_rule->selector()->perform(this);
      in_wrapped = was_wrapped;
    }
    if (at_rule->value()) {
      append_mandatory_space();
      at_rule->value()->perform(this);
    }
    if (at_rule->block()) {
      at_rule->block()->perform(this);
    }
    else {
      append_delimiter();
    }
  }

  void Inspect::operator()(Declaration* dec)
  {
    if (dec->value()->concrete_type() == Expression::NULL_VAL) return;
    bool was_decl = in_declaration;
    in_declaration = true;
    LOCAL_FLAG(in_custom_property, dec->is_custom_property());

    if (output_style() == NESTED)
      indentation += dec->tabs();
    append_indentation();
    if (dec->property())
      dec->property()->perform(this);
    append_colon_separator();

    if (dec->value()->concrete_type() == Expression::SELECTOR) {
      ExpressionObj ls = Listize::perform(dec->value());
      ls->perform(this);
    } else {
      dec->value()->perform(this);
    }

    if (dec->is_important()) {
      append_optional_space();
      append_string("!important");
    }
    append_delimiter();
    if (output_style() == NESTED)
      indentation -= dec->tabs();
    in_declaration = was_decl;
  }

  void Inspect::operator()(Assignment* assn)
  {
    append_token(assn->variable(), assn);
    append_colon_separator();
    assn->value()->perform(this);
    if (assn->is_default()) {
      append_optional_space();
      append_string("!default");
    }
    append_delimiter();
  }

  void Inspect::operator()(Import* import)
  {
    if (!import->urls().empty()) {
      append_token("@import", import);
      append_mandatory_space();

      import->urls().front()->perform(this);
      if (import->urls().size() == 1) {
        if (import->import_queries()) {
          append_mandatory_space();
          import->import_queries()->perform(this);
        }
      }
      append_delimiter();
      for (size_t i = 1, S = import->urls().size(); i < S; ++i) {
        append_mandatory_linefeed();
        append_token("@import", import);
        append_mandatory_space();

        import->urls()[i]->perform(this);
        if (import->urls().size() - 1 == i) {
          if (import->import_queries()) {
            append_mandatory_space();
            import->import_queries()->perform(this);
          }
        }
        append_delimiter();
      }
    }
  }

  void Inspect::operator()(Import_Stub* import)
  {
    append_indentation();
    append_token("@import", import);
    append_mandatory_space();
    append_string(import->imp_path());
    append_delimiter();
  }

  void Inspect::operator()(WarningRule* warning)
  {
    append_indentation();
    append_token("@warn", warning);
    append_mandatory_space();
    warning->message()->perform(this);
    append_delimiter();
  }

  void Inspect::operator()(ErrorRule* error)
  {
    append_indentation();
    append_token("@error", error);
    append_mandatory_space();
    error->message()->perform(this);
    append_delimiter();
  }

  void Inspect::operator()(DebugRule* debug)
  {
    append_indentation();
    append_token("@debug", debug);
    append_mandatory_space();
    debug->value()->perform(this);
    append_delimiter();
  }

  void Inspect::operator()(Comment* comment)
  {
    in_comment = true;
    comment->text()->perform(this);
    in_comment = false;
  }

  void Inspect::operator()(If* cond)
  {
    append_indentation();
    append_token("@if", cond);
    append_mandatory_space();
    cond->predicate()->perform(this);
    cond->block()->perform(this);
    if (cond->alternative()) {
      append_optional_linefeed();
      append_indentation();
      append_string("else");
      cond->alternative()->perform(this);
    }
  }

  void Inspect::operator()(ForRule* loop)
  {
    append_indentation();
    append_token("@for", loop);
    append_mandatory_space();
    append_string(loop->variable());
    append_string(" from ");
    loop->lower_bound()->perform(this);
    append_string(loop->is_inclusive() ? " through " : " to ");
    loop->upper_bound()->perform(this);
    loop->block()->perform(this);
  }

  void Inspect::operator()(EachRule* loop)
  {
    append_indentation();
    append_token("@each", loop);
    append_mandatory_space();
    append_string(loop->variables()[0]);
    for (size_t i = 1, L = loop->variables().size(); i < L; ++i) {
      append_comma_separator();
      append_string(loop->variables()[i]);
    }
    append_string(" in ");
    loop->list()->perform(this);
    loop->block()->perform(this);
  }

  void Inspect::operator()(WhileRule* loop)
  {
    append_indentation();
    append_token("@while", loop);
    append_mandatory_space();
    loop->predicate()->perform(this);
    loop->block()->perform(this);
  }

  void Inspect::operator()(Return* ret)
  {
    append_indentation();
    append_token("@return", ret);
    append_mandatory_space();
    ret->value()->perform(this);
    append_delimiter();
  }

  void Inspect::operator()(ExtendRule* extend)
  {
    append_indentation();
    append_token("@extend", extend);
    append_mandatory_space();
    extend->selector()->perform(this);
    append_delimiter();
  }

  void Inspect::operator()(Definition* def)
  {
    append_indentation();
    if (def->type() == Definition::MIXIN) {
      append_token("@mixin", def);
      append_mandatory_space();
    } else {
      append_token("@function", def);
      append_mandatory_space();
    }
    append_string(def->name());
    def->parameters()->perform(this);
    def->block()->perform(this);
  }

  void Inspect::operator()(Mixin_Call* call)
  {
    append_indentation();
    append_token("@include", call);
    append_mandatory_space();
    append_string(call->name());
    if (call->arguments()) {
      call->arguments()->perform(this);
    }
    if (call->block()) {
      append_optional_space();
      call->block()->perform(this);
    }
    if (!call->block()) append_delimiter();
  }

  void Inspect::operator()(Content* content)
  {
    append_indentation();
    append_token("@content", content);
    append_delimiter();
  }

  void Inspect::operator()(Map* map)
  {
    if (output_style() == TO_SASS && map->empty()) {
      append_string("()");
      return;
    }
    if (map->empty()) return;
    if (map->is_invisible()) return;
    bool items_output = false;
    append_string("(");
    for (auto key : map->keys()) {
      if (items_output) append_comma_separator();
      key->perform(this);
      append_colon_separator();
      LOCAL_FLAG(in_space_array, true);
      LOCAL_FLAG(in_comma_array, true);
      map->at(key)->perform(this);
      items_output = true;
    }
    append_string(")");
  }

  sass::string Inspect::lbracket(List* list) {
    return list->is_bracketed() ? "[" : "(";
  }

  sass::string Inspect::rbracket(List* list) {
    return list->is_bracketed() ? "]" : ")";
  }

  void Inspect::operator()(List* list)
  {
    if (list->empty() && (output_style() == TO_SASS || list->is_bracketed())) {
      append_string(lbracket(list));
      append_string(rbracket(list));
      return;
    }
    sass::string sep(list->separator() == SASS_SPACE ? " " : ",");
    if ((output_style() != COMPRESSED) && sep == ",") sep += " ";
    else if (in_media_block && sep != " ") sep += " "; // verified
    if (list->empty()) return;
    bool items_output = false;

    bool was_space_array = in_space_array;
    bool was_comma_array = in_comma_array;
    // if the list is bracketed, always include the left bracket
    if (list->is_bracketed()) {
      append_string(lbracket(list));
    }
    // probably ruby sass eqivalent of element_needs_parens
    else if (output_style() == TO_SASS &&
        list->length() == 1 &&
        !list->from_selector() &&
        !Cast<List>(list->at(0)) &&
        !Cast<SelectorList>(list->at(0))
    ) {
      append_string(lbracket(list));
    }
    else if (!in_declaration && (list->separator() == SASS_HASH ||
        (list->separator() == SASS_SPACE && in_space_array) ||
        (list->separator() == SASS_COMMA && in_comma_array)
    )) {
      append_string(lbracket(list));
    }

    if (list->separator() == SASS_SPACE) in_space_array = true;
    else if (list->separator() == SASS_COMMA) in_comma_array = true;

    for (size_t i = 0, L = list->size(); i < L; ++i) {
      if (list->separator() == SASS_HASH)
      { sep[0] = i % 2 ? ':' : ','; }
      ExpressionObj list_item = list->at(i);
      if (output_style() != TO_SASS) {
        if (list_item->is_invisible()) {
          // this fixes an issue with "" in a list
          if (!Cast<String_Constant>(list_item)) {
            continue;
          }
        }
      }
      if (items_output) {
        append_string(sep);
      }
      if (items_output && sep != " ")
        append_optional_space();
      list_item->perform(this);
      items_output = true;
    }

    in_comma_array = was_comma_array;
    in_space_array = was_space_array;

    // if the list is bracketed, always include the right bracket
    if (list->is_bracketed()) {
      if (list->separator() == SASS_COMMA && list->size() == 1) {
        append_string(",");
      }
      append_string(rbracket(list));
    }
    // probably ruby sass eqivalent of element_needs_parens
    else if (output_style() == TO_SASS &&
        list->length() == 1 &&
        !list->from_selector() &&
        !Cast<List>(list->at(0)) &&
        !Cast<SelectorList>(list->at(0))
    ) {
      append_string(",");
      append_string(rbracket(list));
    }
    else if (!in_declaration && (list->separator() == SASS_HASH ||
        (list->separator() == SASS_SPACE && in_space_array) ||
        (list->separator() == SASS_COMMA && in_comma_array)
    )) {
      append_string(rbracket(list));
    }

  }

  void Inspect::operator()(Binary_Expression* expr)
  {
    expr->left()->perform(this);
    if ( in_media_block ||
         (output_style() == INSPECT) || (
          expr->op().ws_before
          && (!expr->is_interpolant())
          && (expr->is_left_interpolant() ||
              expr->is_right_interpolant())

    )) append_string(" ");
    switch (expr->optype()) {
      case Sass_OP::AND: append_string("&&"); break;
      case Sass_OP::OR:  append_string("||");  break;
      case Sass_OP::EQ:  append_string("==");  break;
      case Sass_OP::NEQ: append_string("!=");  break;
      case Sass_OP::GT:  append_string(">");   break;
      case Sass_OP::GTE: append_string(">=");  break;
      case Sass_OP::LT:  append_string("<");   break;
      case Sass_OP::LTE: append_string("<=");  break;
      case Sass_OP::ADD: append_string("+");   break;
      case Sass_OP::SUB: append_string("-");   break;
      case Sass_OP::MUL: append_string("*");   break;
      case Sass_OP::DIV: append_string("/"); break;
      case Sass_OP::MOD: append_string("%");   break;
      default: break; // shouldn't get here
    }
    if ( in_media_block ||
         (output_style() == INSPECT) || (
          expr->op().ws_after
          && (!expr->is_interpolant())
          && (expr->is_left_interpolant() ||
              expr->is_right_interpolant())
    )) append_string(" ");
    expr->right()->perform(this);
  }

  void Inspect::operator()(Unary_Expression* expr)
  {
    if (expr->optype() == Unary_Expression::PLUS)       append_string("+");
    else if (expr->optype() == Unary_Expression::SLASH) append_string("/");
    else                                                append_string("-");
    expr->operand()->perform(this);
  }

  void Inspect::operator()(Function_Call* call)
  {
    append_token(call->name(), call);
    call->arguments()->perform(this);
  }

  void Inspect::operator()(Variable* var)
  {
    append_token(var->name(), var);
  }

  void Inspect::operator()(Number* n)
  {

    // reduce units
    n->reduce();

    sass::ostream ss;
    ss.precision(opt.precision);
    ss << std::fixed << n->value();

    sass::string res = ss.str();
    size_t s = res.length();

    // delete trailing zeros
    for(s = s - 1; s > 0; --s)
    {
        if(res[s] == '0') {
          res.erase(s, 1);
        }
        else break;
    }

    // delete trailing decimal separator
    if(res[s] == '.') res.erase(s, 1);

    // some final cosmetics
    if (res == "0.0") res = "0";
    else if (res == "") res = "0";
    else if (res == "-0") res = "0";
    else if (res == "-0.0") res = "0";
    else if (opt.output_style == COMPRESSED)
    {
      if (n->zero()) {
        // check if handling negative nr
        size_t off = res[0] == '-' ? 1 : 0;
        // remove leading zero from floating point in compressed mode
        if (res[off] == '0' && res[off+1] == '.') res.erase(off, 1);
      }
    }

    // add unit now
    res += n->unit();

    if (opt.output_style == TO_CSS && !n->is_valid_css_unit()) {
      // traces.push_back(Backtrace(nr->pstate()));
      throw Exception::InvalidValue({}, *n);
    }

    // output the final token
    append_token(res, n);
  }

  // helper function for serializing colors
  template <size_t range>
  static double cap_channel(double c) {
    if      (c > range) return range;
    else if (c < 0)     return 0;
    else                return c;
  }

  void Inspect::operator()(Color_RGBA* c)
  {
    // output the final token
    sass::ostream ss;

    // original color name
    // maybe an unknown token
    sass::string name = c->disp();

    // resolved color
    sass::string res_name = name;

    double r = Sass::round(cap_channel<0xff>(c->r()), opt.precision);
    double g = Sass::round(cap_channel<0xff>(c->g()), opt.precision);
    double b = Sass::round(cap_channel<0xff>(c->b()), opt.precision);
    double a = cap_channel<1>   (c->a());

    // get color from given name (if one was given at all)
    if (name != "" && name_to_color(name)) {
      const Color_RGBA* n = name_to_color(name);
      r = Sass::round(cap_channel<0xff>(n->r()), opt.precision);
      g = Sass::round(cap_channel<0xff>(n->g()), opt.precision);
      b = Sass::round(cap_channel<0xff>(n->b()), opt.precision);
      a = cap_channel<1>   (n->a());
    }
    // otherwise get the possible resolved color name
    else {
      double numval = r * 0x10000 + g * 0x100 + b;
      if (color_to_name(numval))
        res_name = color_to_name(numval);
    }

    sass::ostream hexlet;
    // dart sass compressed all colors in regular css always
    // ruby sass and libsass does it only when not delayed
    // since color math is going to be removed, this can go too
    bool compressed = opt.output_style == COMPRESSED;
    hexlet << '#' << std::setw(1) << std::setfill('0');
    // create a short color hexlet if there is any need for it
    if (compressed && is_color_doublet(r, g, b) && a == 1) {
      hexlet << std::hex << std::setw(1) << (static_cast<unsigned long>(r) >> 4);
      hexlet << std::hex << std::setw(1) << (static_cast<unsigned long>(g) >> 4);
      hexlet << std::hex << std::setw(1) << (static_cast<unsigned long>(b) >> 4);
    } else {
      hexlet << std::hex << std::setw(2) << static_cast<unsigned long>(r);
      hexlet << std::hex << std::setw(2) << static_cast<unsigned long>(g);
      hexlet << std::hex << std::setw(2) << static_cast<unsigned long>(b);
    }

    if (compressed && !c->is_delayed()) name = "";
    if (opt.output_style == INSPECT && a >= 1) {
      append_token(hexlet.str(), c);
      return;
    }

    // retain the originally specified color definition if unchanged
    if (name != "") {
      ss << name;
    }
    else if (a >= 1) {
      if (res_name != "") {
        if (compressed && hexlet.str().size() < res_name.size()) {
          ss << hexlet.str();
        } else {
          ss << res_name;
        }
      }
      else {
        ss << hexlet.str();
      }
    }
    else {
      ss << "rgba(";
      ss << static_cast<unsigned long>(r) << ",";
      if (!compressed) ss << " ";
      ss << static_cast<unsigned long>(g) << ",";
      if (!compressed) ss << " ";
      ss << static_cast<unsigned long>(b) << ",";
      if (!compressed) ss << " ";
      ss << a << ')';
    }

    append_token(ss.str(), c);

  }

  void Inspect::operator()(Color_HSLA* c)
  {
    Color_RGBA_Obj rgba = c->toRGBA();
    operator()(rgba);
  }

  void Inspect::operator()(Boolean* b)
  {
    // output the final token
    append_token(b->value() ? "true" : "false", b);
  }

  void Inspect::operator()(String_Schema* ss)
  {
    // Evaluation should turn these into String_Constants,
    // so this method is only for inspection purposes.
    for (size_t i = 0, L = ss->length(); i < L; ++i) {
      if ((*ss)[i]->is_interpolant()) append_string("#{");
      (*ss)[i]->perform(this);
      if ((*ss)[i]->is_interpolant()) append_string("}");
    }
  }

  void Inspect::operator()(String_Constant* s)
  {
    append_token(s->value(), s);
  }

  void Inspect::operator()(String_Quoted* s)
  {
    if (const char q = s->quote_mark()) {
      append_token(quote(s->value(), q), s);
    } else {
      append_token(s->value(), s);
    }
  }

  void Inspect::operator()(Custom_Error* e)
  {
    append_token(e->message(), e);
  }

  void Inspect::operator()(Custom_Warning* w)
  {
    append_token(w->message(), w);
  }

  void Inspect::operator()(SupportsOperation* so)
  {

    if (so->needs_parens(so->left())) append_string("(");
    so->left()->perform(this);
    if (so->needs_parens(so->left())) append_string(")");

    if (so->operand() == SupportsOperation::AND) {
      append_mandatory_space();
      append_token("and", so);
      append_mandatory_space();
    } else if (so->operand() == SupportsOperation::OR) {
      append_mandatory_space();
      append_token("or", so);
      append_mandatory_space();
    }

    if (so->needs_parens(so->right())) append_string("(");
    so->right()->perform(this);
    if (so->needs_parens(so->right())) append_string(")");
  }

  void Inspect::operator()(SupportsNegation* sn)
  {
    append_token("not", sn);
    append_mandatory_space();
    if (sn->needs_parens(sn->condition())) append_string("(");
    sn->condition()->perform(this);
    if (sn->needs_parens(sn->condition())) append_string(")");
  }

  void Inspect::operator()(SupportsDeclaration* sd)
  {
    append_string("(");
    sd->feature()->perform(this);
    append_string(": ");
    sd->value()->perform(this);
    append_string(")");
  }

  void Inspect::operator()(Supports_Interpolation* sd)
  {
    sd->value()->perform(this);
  }

  void Inspect::operator()(Media_Query* mq)
  {
    size_t i = 0;
    if (mq->media_type()) {
      if      (mq->is_negated())    append_string("not ");
      else if (mq->is_restricted()) append_string("only ");
      mq->media_type()->perform(this);
    }
    else {
      (*mq)[i++]->perform(this);
    }
    for (size_t L = mq->length(); i < L; ++i) {
      append_string(" and ");
      (*mq)[i]->perform(this);
    }
  }

  void Inspect::operator()(Media_Query_Expression* mqe)
  {
    if (mqe->is_interpolated()) {
      mqe->feature()->perform(this);
    }
    else {
      append_string("(");
      mqe->feature()->perform(this);
      if (mqe->value()) {
        append_string(": "); // verified
        mqe->value()->perform(this);
      }
      append_string(")");
    }
  }

  void Inspect::operator()(At_Root_Query* ae)
  {
    if (ae->feature()) {
      append_string("(");
      ae->feature()->perform(this);
      if (ae->value()) {
        append_colon_separator();
        ae->value()->perform(this);
      }
      append_string(")");
    }
  }

  void Inspect::operator()(Function* f)
  {
    append_token("get-function", f);
    append_string("(");
    append_string(quote(f->name()));
    append_string(")");
  }

  void Inspect::operator()(Null* n)
  {
    // output the final token
    append_token("null", n);
  }

  // parameters and arguments
  void Inspect::operator()(Parameter* p)
  {
    append_token(p->name(), p);
    if (p->default_value()) {
      append_colon_separator();
      p->default_value()->perform(this);
    }
    else if (p->is_rest_parameter()) {
      append_string("...");
    }
  }

  void Inspect::operator()(Parameters* p)
  {
    append_string("(");
    if (!p->empty()) {
      (*p)[0]->perform(this);
      for (size_t i = 1, L = p->length(); i < L; ++i) {
        append_comma_separator();
        (*p)[i]->perform(this);
      }
    }
    append_string(")");
  }

  void Inspect::operator()(Argument* a)
  {
    if (!a->name().empty()) {
      append_token(a->name(), a);
      append_colon_separator();
    }
    if (!a->value()) return;
    // Special case: argument nulls can be ignored
    if (a->value()->concrete_type() == Expression::NULL_VAL) {
      return;
    }
    if (a->value()->concrete_type() == Expression::STRING) {
      String_Constant* s = Cast<String_Constant>(a->value());
      if (s) s->perform(this);
    } else {
      a->value()->perform(this);
    }
    if (a->is_rest_argument()) {
      append_string("...");
    }
  }

  void Inspect::operator()(Arguments* a)
  {
    append_string("(");
    if (!a->empty()) {
      (*a)[0]->perform(this);
      for (size_t i = 1, L = a->length(); i < L; ++i) {
        append_string(", "); // verified
        // Sass Bug? append_comma_separator();
        (*a)[i]->perform(this);
      }
    }
    append_string(")");
  }

  void Inspect::operator()(Selector_Schema* s)
  {
    s->contents()->perform(this);
  }

  void Inspect::operator()(Parent_Reference* p)
  {
    append_string("&");
  }

  void Inspect::operator()(PlaceholderSelector* s)
  {
    append_token(s->name(), s);

  }

  void Inspect::operator()(TypeSelector* s)
  {
    append_token(s->ns_name(), s);
  }

  void Inspect::operator()(ClassSelector* s)
  {
    append_token(s->ns_name(), s);
  }

  void Inspect::operator()(IDSelector* s)
  {
    append_token(s->ns_name(), s);
  }

  void Inspect::operator()(AttributeSelector* s)
  {
    append_string("[");
    add_open_mapping(s);
    append_token(s->ns_name(), s);
    if (!s->matcher().empty()) {
      append_string(s->matcher());
      if (s->value() && *s->value()) {
        s->value()->perform(this);
      }
    }
    add_close_mapping(s);
    if (s->modifier() != 0) {
      append_mandatory_space();
      append_char(s->modifier());
    }
    append_string("]");
  }

  void Inspect::operator()(PseudoSelector* s)
  {

    if (s->name() != "") {
      append_string(":");
      if (s->isSyntacticElement()) {
        append_string(":");
      }
      append_token(s->ns_name(), s);
      if (s->selector() || s->argument()) {
        bool was = in_wrapped;
        in_wrapped = true;
        append_string("(");
        if (s->argument()) {
          s->argument()->perform(this);
        }
        if (s->selector() && s->argument()) {
          append_mandatory_space();
        }
        bool was_comma_array = in_comma_array;
        in_comma_array = false;
        if (s->selector()) {
          s->selector()->perform(this);
        }
        in_comma_array = was_comma_array;
        append_string(")");
        in_wrapped = was;
      }
    }
  }

  void Inspect::operator()(SelectorList* g)
  {

    if (g->empty()) {
      if (output_style() == TO_SASS) {
        append_token("()", g);
      }
      return;
    }


    bool was_comma_array = in_comma_array;
    // probably ruby sass eqivalent of element_needs_parens
    if (output_style() == TO_SASS && g->length() == 1 &&
      (!Cast<List>((*g)[0]) &&
        !Cast<SelectorList>((*g)[0]))) {
      append_string("(");
    }
    else if (!in_declaration && in_comma_array) {
      append_string("(");
    }

    if (in_declaration) in_comma_array = true;

    for (size_t i = 0, L = g->length(); i < L; ++i) {

      if (!in_wrapped && i == 0) append_indentation();
      if ((*g)[i] == nullptr) continue;
      if (g->at(i)->length() == 0) continue;
      schedule_mapping(g->at(i)->last());
      // add_open_mapping((*g)[i]->last());
      (*g)[i]->perform(this);
      // add_close_mapping((*g)[i]->last());
      if (i < L - 1) {
        scheduled_space = 0;
        append_comma_separator();
      }
    }

    in_comma_array = was_comma_array;
    // probably ruby sass eqivalent of element_needs_parens
    if (output_style() == TO_SASS && g->length() == 1 &&
      (!Cast<List>((*g)[0]) &&
        !Cast<SelectorList>((*g)[0]))) {
      append_string(",)");
    }
    else if (!in_declaration && in_comma_array) {
      append_string(")");
    }

  }
  void Inspect::operator()(ComplexSelector* sel)
  {
    if (sel->hasPreLineFeed()) {
      append_optional_linefeed();
      if (!in_wrapped && output_style() == NESTED) {
        append_indentation();
      }
    }
    const SelectorComponent* prev = nullptr;
    for (auto& item : sel->elements()) {
      if (prev != nullptr) {
        if (item->getCombinator() || prev->getCombinator()) {
          append_optional_space();
        } else {
          append_mandatory_space();
        }
      }
      item->perform(this);
      prev = item.ptr();
    }
  }

  void Inspect::operator()(SelectorComponent* sel)
  {
    // You should probably never call this method directly
    // But in case anyone does, we will do the upcasting
    if (auto comp = Cast<CompoundSelector>(sel)) operator()(comp);
    if (auto comb = Cast<SelectorCombinator>(sel)) operator()(comb);
  }

  void Inspect::operator()(CompoundSelector* sel)
  {
    if (sel->hasRealParent()) {
      append_string("&");
    }
    sel->sortChildren();
    for (auto& item : sel->elements()) {
      item->perform(this);
    }
    // Add the post line break (from ruby sass)
    // Dart sass uses another logic for newlines
    if (sel->hasPostLineBreak()) {
      if (output_style() != COMPACT) {
        append_optional_linefeed();
      }
    }
  }

  void Inspect::operator()(SelectorCombinator* sel)
  {
    append_optional_space();
    switch (sel->combinator()) {
      case SelectorCombinator::Combinator::CHILD: append_string(">"); break;
      case SelectorCombinator::Combinator::GENERAL: append_string("~"); break;
      case SelectorCombinator::Combinator::ADJACENT: append_string("+"); break;
    }
    append_optional_space();
    // Add the post line break (from ruby sass)
    // Dart sass uses another logic for newlines
    if (sel->hasPostLineBreak()) {
      if (output_style() != COMPACT) {
        // append_optional_linefeed();
      }
    }
  }

}
