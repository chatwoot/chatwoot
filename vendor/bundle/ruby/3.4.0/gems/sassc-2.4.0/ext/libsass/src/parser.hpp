#ifndef SASS_PARSER_H
#define SASS_PARSER_H

// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include <string>
#include <vector>

#include "ast.hpp"
#include "position.hpp"
#include "context.hpp"
#include "position.hpp"
#include "prelexer.hpp"
#include "source.hpp"

#ifndef MAX_NESTING
// Note that this limit is not an exact science
// it depends on various factors, which some are
// not under our control (compile time or even OS
// dependent settings on the available stack size)
// It should fix most common segfault cases though.
#define MAX_NESTING 512
#endif

struct Lookahead {
  const char* found;
  const char* error;
  const char* position;
  bool parsable;
  bool has_interpolants;
  bool is_custom_property;
};

namespace Sass {

  class Parser : public SourceSpan {
  public:

    enum Scope { Root, Mixin, Function, Media, Control, Properties, Rules, AtRoot };

    Context& ctx;
    sass::vector<Block_Obj> block_stack;
    sass::vector<Scope> stack;
    SourceDataObj source;
    const char* begin;
    const char* position;
    const char* end;
    Offset before_token;
    Offset after_token;
    SourceSpan pstate;
    Backtraces traces;
    size_t indentation;
    size_t nestings;
    bool allow_parent;
    Token lexed;

    Parser(SourceData* source, Context& ctx, Backtraces, bool allow_parent = true);

    // special static parsers to convert strings into certain selectors
    static SelectorListObj parse_selector(SourceData* source, Context& ctx, Backtraces, bool allow_parent = true);

#ifdef __clang__

    // lex and peak uses the template parameter to branch on the action, which
    // triggers clangs tautological comparison on the single-comparison
    // branches. This is not a bug, just a merging of behaviour into
    // one function

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-compare"

#endif


    // skip current token and next whitespace
    // moves SourceSpan right before next token
    void advanceToNextToken();

    bool peek_newline(const char* start = 0);

    // skip over spaces, tabs and line comments
    template <Prelexer::prelexer mx>
    const char* sneak(const char* start = 0)
    {
      using namespace Prelexer;

      // maybe use optional start position from arguments?
      const char* it_position = start ? start : position;

      // skip white-space?
      if (mx == spaces ||
          mx == no_spaces ||
          mx == css_comments ||
          mx == css_whitespace ||
          mx == optional_spaces ||
          mx == optional_css_comments ||
          mx == optional_css_whitespace
      ) {
        return it_position;
      }

      // skip over spaces, tabs and sass line comments
      const char* pos = optional_css_whitespace(it_position);
      // always return a valid position
      return pos ? pos : it_position;

    }

    // match will not skip over space, tabs and line comment
    // return the position where the lexer match will occur
    template <Prelexer::prelexer mx>
    const char* match(const char* start = 0)
    {
      // match the given prelexer
      return mx(position);
    }

    // peek will only skip over space, tabs and line comment
    // return the position where the lexer match will occur
    template <Prelexer::prelexer mx>
    const char* peek(const char* start = 0)
    {

      // sneak up to the actual token we want to lex
      // this should skip over white-space if desired
      const char* it_before_token = sneak < mx >(start);

      // match the given prelexer
      const char* match = mx(it_before_token);

      // check if match is in valid range
      return match <= end ? match : 0;

    }

    // white-space handling is built into the lexer
    // this way you do not need to parse it yourself
    // some matchers don't accept certain white-space
    // we do not support start arg, since we manipulate
    // sourcemap offset and we modify the position pointer!
    // lex will only skip over space, tabs and line comment
    template <Prelexer::prelexer mx>
    const char* lex(bool lazy = true, bool force = false)
    {

      if (*position == 0) return 0;

      // position considered before lexed token
      // we can skip whitespace or comments for
      // lazy developers (but we need control)
      const char* it_before_token = position;

      // sneak up to the actual token we want to lex
      // this should skip over white-space if desired
      if (lazy) it_before_token = sneak < mx >(position);

      // now call matcher to get position after token
      const char* it_after_token = mx(it_before_token);

      // check if match is in valid range
      if (it_after_token > end) return 0;

      // maybe we want to update the parser state anyway?
      if (force == false) {
        // assertion that we got a valid match
        if (it_after_token == 0) return 0;
        // assertion that we actually lexed something
        if (it_after_token == it_before_token) return 0;
      }

      // create new lexed token object (holds the parse results)
      lexed = Token(position, it_before_token, it_after_token);

      // advance position (add whitespace before current token)
      before_token = after_token.add(position, it_before_token);

      // update after_token position for current token
      after_token.add(it_before_token, it_after_token);

      // ToDo: could probably do this incremental on original object (API wants offset?)
      pstate = SourceSpan(source, before_token, after_token - before_token);

      // advance internal char iterator
      return position = it_after_token;

    }

    // lex_css skips over space, tabs, line and block comment
    // all block comments will be consumed and thrown away
    // source-map position will point to token after the comment
    template <Prelexer::prelexer mx>
    const char* lex_css()
    {
      // copy old token
      Token prev = lexed;
      // store previous pointer
      const char* oldpos = position;
      Offset bt = before_token;
      Offset at = after_token;
      SourceSpan op = pstate;
      // throw away comments
      // update srcmap position
      lex < Prelexer::css_comments >();
      // now lex a new token
      const char* pos = lex< mx >();
      // maybe restore prev state
      if (pos == 0) {
        pstate = op;
        lexed = prev;
        position = oldpos;
        after_token = at;
        before_token = bt;
      }
      // return match
      return pos;
    }

    // all block comments will be skipped and thrown away
    template <Prelexer::prelexer mx>
    const char* peek_css(const char* start = 0)
    {
      // now peek a token (skip comments first)
      return peek< mx >(peek < Prelexer::css_comments >(start));
    }

#ifdef __clang__

#pragma clang diagnostic pop

#endif

    void error(sass::string msg);
    // generate message with given and expected sample
    // text before and in the middle are configurable
    void css_error(const sass::string& msg,
                   const sass::string& prefix = " after ",
                   const sass::string& middle = ", was: ",
                   const bool trim = true);
    void read_bom();

    Block_Obj parse();
    Import_Obj parse_import();
    Definition_Obj parse_definition(Definition::Type which_type);
    Parameters_Obj parse_parameters();
    Parameter_Obj parse_parameter();
    Mixin_Call_Obj parse_include_directive();
    Arguments_Obj parse_arguments();
    Argument_Obj parse_argument();
    Assignment_Obj parse_assignment();
    StyleRuleObj parse_ruleset(Lookahead lookahead);
    SelectorListObj parseSelectorList(bool chroot);
    ComplexSelectorObj parseComplexSelector(bool chroot);
    Selector_Schema_Obj parse_selector_schema(const char* end_of_selector, bool chroot);
    CompoundSelectorObj parseCompoundSelector();
    SimpleSelectorObj parse_simple_selector();
    PseudoSelectorObj parse_negated_selector2();
    Expression* parse_binominal();
    SimpleSelectorObj parse_pseudo_selector();
    AttributeSelectorObj parse_attribute_selector();
    Block_Obj parse_block(bool is_root = false);
    Block_Obj parse_css_block(bool is_root = false);
    bool parse_block_nodes(bool is_root = false);
    bool parse_block_node(bool is_root = false);

    Declaration_Obj parse_declaration();
    ExpressionObj parse_map();
    ExpressionObj parse_bracket_list();
    ExpressionObj parse_list(bool delayed = false);
    ExpressionObj parse_comma_list(bool delayed = false);
    ExpressionObj parse_space_list();
    ExpressionObj parse_disjunction();
    ExpressionObj parse_conjunction();
    ExpressionObj parse_relation();
    ExpressionObj parse_expression();
    ExpressionObj parse_operators();
    ExpressionObj parse_factor();
    ExpressionObj parse_value();
    Function_Call_Obj parse_calc_function();
    Function_Call_Obj parse_function_call();
    Function_Call_Obj parse_function_call_schema();
    String_Obj parse_url_function_string();
    String_Obj parse_url_function_argument();
    String_Obj parse_interpolated_chunk(Token, bool constant = false, bool css = true);
    String_Obj parse_string();
    ValueObj parse_static_value();
    String_Schema_Obj parse_css_variable_value();
    String_Obj parse_ie_property();
    String_Obj parse_ie_keyword_arg();
    String_Schema_Obj parse_value_schema(const char* stop);
    String_Obj parse_identifier_schema();
    If_Obj parse_if_directive(bool else_if = false);
    ForRuleObj parse_for_directive();
    EachRuleObj parse_each_directive();
    WhileRuleObj parse_while_directive();
    MediaRule_Obj parseMediaRule();
    sass::vector<CssMediaQuery_Obj> parseCssMediaQueries();
    sass::string parseIdentifier();
    CssMediaQuery_Obj parseCssMediaQuery();
    Return_Obj parse_return_directive();
    Content_Obj parse_content_directive();
    void parse_charset_directive();
    List_Obj parse_media_queries();
    Media_Query_Obj parse_media_query();
    Media_Query_ExpressionObj parse_media_expression();
    SupportsRuleObj parse_supports_directive();
    SupportsConditionObj parse_supports_condition(bool top_level);
    SupportsConditionObj parse_supports_negation();
    SupportsConditionObj parse_supports_operator(bool top_level);
    SupportsConditionObj parse_supports_interpolation();
    SupportsConditionObj parse_supports_declaration();
    SupportsConditionObj parse_supports_condition_in_parens(bool parens_required);
    AtRootRuleObj parse_at_root_block();
    At_Root_Query_Obj parse_at_root_query();
    String_Schema_Obj parse_almost_any_value();
    AtRuleObj parse_directive();
    WarningRuleObj parse_warning();
    ErrorRuleObj parse_error();
    DebugRuleObj parse_debug();

    Value* color_or_string(const sass::string& lexed) const;

    // be more like ruby sass
    ExpressionObj lex_almost_any_value_token();
    ExpressionObj lex_almost_any_value_chars();
    ExpressionObj lex_interp_string();
    ExpressionObj lex_interp_uri();
    ExpressionObj lex_interpolation();

    // these will throw errors
    Token lex_variable();
    Token lex_identifier();

    void parse_block_comments(bool store = true);

    Lookahead lookahead_for_value(const char* start = 0);
    Lookahead lookahead_for_selector(const char* start = 0);
    Lookahead lookahead_for_include(const char* start = 0);

    ExpressionObj fold_operands(ExpressionObj base, sass::vector<ExpressionObj>& operands, Operand op);
    ExpressionObj fold_operands(ExpressionObj base, sass::vector<ExpressionObj>& operands, sass::vector<Operand>& ops, size_t i = 0);

    void throw_syntax_error(sass::string message, size_t ln = 0);
    void throw_read_error(sass::string message, size_t ln = 0);


    template <Prelexer::prelexer open, Prelexer::prelexer close>
    ExpressionObj lex_interp()
    {
      if (lex < open >(false)) {
        String_Schema_Obj schema = SASS_MEMORY_NEW(String_Schema, pstate);
        // std::cerr << "LEX [[" << sass::string(lexed) << "]]\n";
        schema->append(SASS_MEMORY_NEW(String_Constant, pstate, lexed));
        if (position[0] == '#' && position[1] == '{') {
          ExpressionObj itpl = lex_interpolation();
          if (!itpl.isNull()) schema->append(itpl);
          while (lex < close >(false)) {
            // std::cerr << "LEX [[" << sass::string(lexed) << "]]\n";
            schema->append(SASS_MEMORY_NEW(String_Constant, pstate, lexed));
            if (position[0] == '#' && position[1] == '{') {
              ExpressionObj itpl = lex_interpolation();
              if (!itpl.isNull()) schema->append(itpl);
            } else {
              return schema;
            }
          }
        } else {
          return SASS_MEMORY_NEW(String_Constant, pstate, lexed);
        }
      }
      return {};
    }

  public:
    static Number* lexed_number(const SourceSpan& pstate, const sass::string& parsed);
    static Number* lexed_dimension(const SourceSpan& pstate, const sass::string& parsed);
    static Number* lexed_percentage(const SourceSpan& pstate, const sass::string& parsed);
    static Value* lexed_hex_color(const SourceSpan& pstate, const sass::string& parsed);
  private:
    Number* lexed_number(const sass::string& parsed) { return lexed_number(pstate, parsed); };
    Number* lexed_dimension(const sass::string& parsed) { return lexed_dimension(pstate, parsed); };
    Number* lexed_percentage(const sass::string& parsed) { return lexed_percentage(pstate, parsed); };
    Value* lexed_hex_color(const sass::string& parsed) { return lexed_hex_color(pstate, parsed); };

    static const char* re_attr_sensitive_close(const char* src);
    static const char* re_attr_insensitive_close(const char* src);

  };

  size_t check_bom_chars(const char* src, const char *end, const unsigned char* bom, size_t len);
}

#endif
