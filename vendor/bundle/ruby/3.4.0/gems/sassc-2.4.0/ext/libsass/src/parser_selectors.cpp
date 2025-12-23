// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include "parser.hpp"

namespace Sass {

  using namespace Prelexer;
  using namespace Constants;

  ComplexSelectorObj Parser::parseComplexSelector(bool chroot)
  {

    NESTING_GUARD(nestings);

    lex < block_comment >();
    advanceToNextToken();

    ComplexSelectorObj sel = SASS_MEMORY_NEW(ComplexSelector, pstate);

    if (peek < end_of_file >()) return sel;

    while (true) {

      lex < block_comment >();
      advanceToNextToken();

      // check for child (+) combinator
      if (lex < exactly < selector_combinator_child > >()) {
        sel->append(SASS_MEMORY_NEW(SelectorCombinator, pstate, SelectorCombinator::CHILD, peek_newline()));
      }
      // check for general sibling (~) combinator
      else if (lex < exactly < selector_combinator_general > >()) {
        sel->append(SASS_MEMORY_NEW(SelectorCombinator, pstate, SelectorCombinator::GENERAL, peek_newline()));
      }
      // check for adjecant sibling (+) combinator
      else if (lex < exactly < selector_combinator_adjacent > >()) {
        sel->append(SASS_MEMORY_NEW(SelectorCombinator, pstate, SelectorCombinator::ADJACENT, peek_newline()));
      }
      // check if we can parse a compound selector
      else if (CompoundSelectorObj compound = parseCompoundSelector()) {
        sel->append(compound);
      }
      else {
        break;
      }
    }

    if (sel->empty()) return {};

    // check if we parsed any parent references
    sel->chroots(sel->has_real_parent_ref() || chroot);

    sel->update_pstate(pstate);

    return sel;

  }

  SelectorListObj Parser::parseSelectorList(bool chroot)
  {

    bool reloop;
    bool had_linefeed = false;
    NESTING_GUARD(nestings);
    SelectorListObj list = SASS_MEMORY_NEW(SelectorList, pstate);

    if (peek_css< alternatives < end_of_file, exactly <'{'>, exactly <','> > >()) {
      css_error("Invalid CSS", " after ", ": expected selector, was ");
    }

    do {
      reloop = false;

      had_linefeed = had_linefeed || peek_newline();

      if (peek_css< alternatives < class_char < selector_list_delims > > >())
        break; // in case there are superfluous commas at the end

      // now parse the complex selector
      ComplexSelectorObj complex = parseComplexSelector(chroot);
      if (complex.isNull()) return list.detach();
      complex->hasPreLineFeed(had_linefeed);

      had_linefeed = false;

      while (peek_css< exactly<','> >())
      {
        lex< css_comments >(false);
        // consume everything up and including the comma separator
        reloop = lex< exactly<','> >() != 0;
        // remember line break (also between some commas)
        had_linefeed = had_linefeed || peek_newline();
        // remember line break (also between some commas)
      }
      list->append(complex);

    } while (reloop);

    while (lex_css< kwd_optional >()) {
      list->is_optional(true);
    }

    // update for end position
    list->update_pstate(pstate);

    return list.detach();
  }

  // parse one compound selector, which is basically
  // a list of simple selectors (directly adjacent)
  // lex them exactly (without skipping white-space)
  CompoundSelectorObj Parser::parseCompoundSelector()
  {
    // init an empty compound selector wrapper
    CompoundSelectorObj seq = SASS_MEMORY_NEW(CompoundSelector, pstate);

    // skip initial white-space
    lex < block_comment >();
    advanceToNextToken();

    if (lex< exactly<'&'> >(false))
    {
      // ToDo: check the conditions and try to simplify flag passing
      if (!allow_parent) error("Parent selectors aren't allowed here.");
      // Create and append a new parent selector object
      seq->hasRealParent(true);
    }

    // parse list
    while (true)
    {
      // remove all block comments
      // leaves trailing white-space
      lex < block_comment >();
      // parse parent selector
      if (lex< exactly<'&'> >(false))
      {
        // parent selector only allowed at start
        // upcoming Sass may allow also trailing
        SourceSpan state(pstate);
        sass::string found("&");
        if (lex < identifier >()) {
          found += sass::string(lexed);
        }
        sass::string sel(seq->hasRealParent() ? "&" : "");
        if (!seq->empty()) { sel = seq->last()->to_string({ NESTED, 5 }); }
        // ToDo: parser should throw parser exceptions
        error("Invalid CSS after \"" + sel + "\": expected \"{\", was \"" + found + "\"\n\n"
          "\"" + found + "\" may only be used at the beginning of a compound selector.");
      }
      // parse functional
      else if (match < re_functional >())
        {
          seq->append(parse_simple_selector());
        }

      // parse type selector
      else if (lex< re_type_selector >(false))
      {
        seq->append(SASS_MEMORY_NEW(TypeSelector, pstate, lexed));
      }
      // peek for abort conditions
      else if (peek< spaces >()) break;
      else if (peek< end_of_file >()) { break; }
      else if (peek_css < class_char < selector_combinator_ops > >()) break;
      else if (peek_css < class_char < complex_selector_delims > >()) break;
      // otherwise parse another simple selector
      else {
        SimpleSelectorObj sel = parse_simple_selector();
        if (!sel) return {};
        seq->append(sel);
      }
    }
    // EO while true

    if (seq && !peek_css<alternatives<end_of_file,exactly<'{'>>>()) {
      seq->hasPostLineBreak(peek_newline());
    }

    // We may have set hasRealParent
    if (seq && seq->empty() && !seq->hasRealParent()) return {};

    return seq;
  }


}
