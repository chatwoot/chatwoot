// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include <iostream>
#include <typeinfo>
#include <vector>

#include "cssize.hpp"
#include "context.hpp"

namespace Sass {

  Cssize::Cssize(Context& ctx)
  : traces(ctx.traces),
    block_stack(BlockStack()),
    p_stack(sass::vector<Statement*>())
  { }

  Statement* Cssize::parent()
  {
    return p_stack.size() ? p_stack.back() : block_stack.front();
  }

  Block* Cssize::operator()(Block* b)
  {
    Block_Obj bb = SASS_MEMORY_NEW(Block, b->pstate(), b->length(), b->is_root());
    // bb->tabs(b->tabs());
    block_stack.push_back(bb);
    append_block(b, bb);
    block_stack.pop_back();
    return bb.detach();
  }

  Statement* Cssize::operator()(Trace* t)
  {
    traces.push_back(Backtrace(t->pstate()));
    auto result = t->block()->perform(this);
    traces.pop_back();
    return result;
  }

  Statement* Cssize::operator()(Declaration* d)
  {
    String_Obj property = Cast<String>(d->property());

    if (Declaration* dd = Cast<Declaration>(parent())) {
      String_Obj parent_property = Cast<String>(dd->property());
      property = SASS_MEMORY_NEW(String_Constant,
                                 d->property()->pstate(),
                                 parent_property->to_string() + "-" + property->to_string());
      if (!dd->value()) {
        d->tabs(dd->tabs() + 1);
      }
    }

    Declaration_Obj dd = SASS_MEMORY_NEW(Declaration,
                                      d->pstate(),
                                      property,
                                      d->value(),
                                      d->is_important(),
                                      d->is_custom_property());
    dd->is_indented(d->is_indented());
    dd->tabs(d->tabs());

    p_stack.push_back(dd);
    Block_Obj bb = d->block() ? operator()(d->block()) : NULL;
    p_stack.pop_back();

    if (bb && bb->length()) {
      if (dd->value() && !dd->value()->is_invisible()) {
        bb->unshift(dd);
      }
      return bb.detach();
    }
    else if (dd->value() && !dd->value()->is_invisible()) {
      return dd.detach();
    }

    return 0;
  }

  Statement* Cssize::operator()(AtRule* r)
  {
    if (!r->block() || !r->block()->length()) return r;

    if (parent()->statement_type() == Statement::RULESET)
    {
      return r->is_keyframes() ? SASS_MEMORY_NEW(Bubble, r->pstate(), r) : bubble(r);
    }

    p_stack.push_back(r);
    AtRuleObj rr = SASS_MEMORY_NEW(AtRule,
                                  r->pstate(),
                                  r->keyword(),
                                  r->selector(),
                                  r->block() ? operator()(r->block()) : 0);
    if (r->value()) rr->value(r->value());
    p_stack.pop_back();

    bool directive_exists = false;
    size_t L = rr->block() ? rr->block()->length() : 0;
    for (size_t i = 0; i < L && !directive_exists; ++i) {
      Statement_Obj s = r->block()->at(i);
      if (s->statement_type() != Statement::BUBBLE) directive_exists = true;
      else {
        Bubble_Obj s_obj = Cast<Bubble>(s);
        s = s_obj->node();
        if (s->statement_type() != Statement::DIRECTIVE) directive_exists = false;
        else directive_exists = (Cast<AtRule>(s)->keyword() == rr->keyword());
      }

    }

    Block* result = SASS_MEMORY_NEW(Block, rr->pstate());
    if (!(directive_exists || rr->is_keyframes()))
    {
      AtRule* empty_node = Cast<AtRule>(rr);
      empty_node->block(SASS_MEMORY_NEW(Block, rr->block() ? rr->block()->pstate() : rr->pstate()));
      result->append(empty_node);
    }

    Block_Obj db = rr->block();
    if (db.isNull()) db = SASS_MEMORY_NEW(Block, rr->pstate());
    Block_Obj ss = debubble(db, rr);
    for (size_t i = 0, L = ss->length(); i < L; ++i) {
      result->append(ss->at(i));
    }

    return result;
  }

  Statement* Cssize::operator()(Keyframe_Rule* r)
  {
    if (!r->block() || !r->block()->length()) return r;

    Keyframe_Rule_Obj rr = SASS_MEMORY_NEW(Keyframe_Rule,
                                        r->pstate(),
                                        operator()(r->block()));
    if (!r->name().isNull()) rr->name(r->name());

    return debubble(rr->block(), rr);
  }

  Statement* Cssize::operator()(StyleRule* r)
  {
    p_stack.push_back(r);
    // this can return a string schema
    // string schema is not a statement!
    // r->block() is already a string schema
    // and that is coming from propset expand
    Block* bb = operator()(r->block());
    // this should protect us (at least a bit) from our mess
    // fixing this properly is harder that it should be ...
    if (Cast<Statement>(bb) == NULL) {
      error("Illegal nesting: Only properties may be nested beneath properties.", r->block()->pstate(), traces);
    }
    StyleRuleObj rr = SASS_MEMORY_NEW(StyleRule,
                                  r->pstate(),
                                  r->selector(),
                                  bb);

    rr->is_root(r->is_root());
    // rr->tabs(r->block()->tabs());
    p_stack.pop_back();

    if (!rr->block()) {
      error("Illegal nesting: Only properties may be nested beneath properties.", r->block()->pstate(), traces);
    }

    Block_Obj props = SASS_MEMORY_NEW(Block, rr->block()->pstate());
    Block* rules = SASS_MEMORY_NEW(Block, rr->block()->pstate());
    for (size_t i = 0, L = rr->block()->length(); i < L; i++)
    {
      Statement* s = rr->block()->at(i);
      if (bubblable(s)) rules->append(s);
      if (!bubblable(s)) props->append(s);
    }

    if (props->length())
    {
      Block_Obj pb = SASS_MEMORY_NEW(Block, rr->block()->pstate());
      pb->concat(props);
      rr->block(pb);

      for (size_t i = 0, L = rules->length(); i < L; i++)
      {
        Statement* stm = rules->at(i);
        stm->tabs(stm->tabs() + 1);
      }

      rules->unshift(rr);
    }

    Block* ptr = rules;
    rules = debubble(rules);
    void* lp = ptr;
    void* rp = rules;
    if (lp != rp) {
      Block_Obj obj = ptr;
    }

    if (!(!rules->length() ||
          !bubblable(rules->last()) ||
          parent()->statement_type() == Statement::RULESET))
    {
      rules->last()->group_end(true);
    }
    return rules;
  }

  Statement* Cssize::operator()(Null* m)
  {
    return 0;
  }

  Statement* Cssize::operator()(CssMediaRule* m)
  {
    if (parent()->statement_type() == Statement::RULESET)
    {
      return bubble(m);
    }

    if (parent()->statement_type() == Statement::MEDIA)
    {
      return SASS_MEMORY_NEW(Bubble, m->pstate(), m);
    }

    p_stack.push_back(m);

    CssMediaRuleObj mm = SASS_MEMORY_NEW(CssMediaRule, m->pstate(), m->block());
    mm->concat(m->elements());
    mm->block(operator()(m->block()));
    mm->tabs(m->tabs());

    p_stack.pop_back();

    return debubble(mm->block(), mm);
  }

  Statement* Cssize::operator()(SupportsRule* m)
  {
    if (!m->block()->length())
    { return m; }

    if (parent()->statement_type() == Statement::RULESET)
    { return bubble(m); }

    p_stack.push_back(m);

    SupportsRuleObj mm = SASS_MEMORY_NEW(SupportsRule,
                                       m->pstate(),
                                       m->condition(),
                                       operator()(m->block()));
    mm->tabs(m->tabs());

    p_stack.pop_back();

    return debubble(mm->block(), mm);
  }

  Statement* Cssize::operator()(AtRootRule* m)
  {
    bool tmp = false;
    for (size_t i = 0, L = p_stack.size(); i < L; ++i) {
      Statement* s = p_stack[i];
      tmp |= m->exclude_node(s);
    }

    if (!tmp && m->block())
    {
      Block* bb = operator()(m->block());
      for (size_t i = 0, L = bb->length(); i < L; ++i) {
        // (bb->elements())[i]->tabs(m->tabs());
        Statement_Obj stm = bb->at(i);
        if (bubblable(stm)) stm->tabs(stm->tabs() + m->tabs());
      }
      if (bb->length() && bubblable(bb->last())) bb->last()->group_end(m->group_end());
      return bb;
    }

    if (m->exclude_node(parent()))
    {
      return SASS_MEMORY_NEW(Bubble, m->pstate(), m);
    }

    return bubble(m);
  }

  Statement* Cssize::bubble(AtRule* m)
  {
    Block* bb = SASS_MEMORY_NEW(Block, this->parent()->pstate());
    ParentStatementObj new_rule = Cast<ParentStatement>(SASS_MEMORY_COPY(this->parent()));
    new_rule->block(bb);
    new_rule->tabs(this->parent()->tabs());
    new_rule->block()->concat(m->block());

    Block_Obj wrapper_block = SASS_MEMORY_NEW(Block, m->block() ? m->block()->pstate() : m->pstate());
    wrapper_block->append(new_rule);
    AtRuleObj mm = SASS_MEMORY_NEW(AtRule,
                                  m->pstate(),
                                  m->keyword(),
                                  m->selector(),
                                  wrapper_block);
    if (m->value()) mm->value(m->value());

    Bubble* bubble = SASS_MEMORY_NEW(Bubble, mm->pstate(), mm);
    return bubble;
  }

  Statement* Cssize::bubble(AtRootRule* m)
  {
    if (!m || !m->block()) return NULL;
    Block* bb = SASS_MEMORY_NEW(Block, this->parent()->pstate());
    ParentStatementObj new_rule = Cast<ParentStatement>(SASS_MEMORY_COPY(this->parent()));
    Block* wrapper_block = SASS_MEMORY_NEW(Block, m->block()->pstate());
    if (new_rule) {
      new_rule->block(bb);
      new_rule->tabs(this->parent()->tabs());
      new_rule->block()->concat(m->block());
      wrapper_block->append(new_rule);
    }

    AtRootRule* mm = SASS_MEMORY_NEW(AtRootRule,
                                        m->pstate(),
                                        wrapper_block,
                                        m->expression());
    Bubble* bubble = SASS_MEMORY_NEW(Bubble, mm->pstate(), mm);
    return bubble;
  }

  Statement* Cssize::bubble(SupportsRule* m)
  {
    StyleRuleObj parent = Cast<StyleRule>(SASS_MEMORY_COPY(this->parent()));

    Block* bb = SASS_MEMORY_NEW(Block, parent->block()->pstate());
    StyleRule* new_rule = SASS_MEMORY_NEW(StyleRule,
                                        parent->pstate(),
                                        parent->selector(),
                                        bb);
    new_rule->tabs(parent->tabs());
    new_rule->block()->concat(m->block());

    Block* wrapper_block = SASS_MEMORY_NEW(Block, m->block()->pstate());
    wrapper_block->append(new_rule);
    SupportsRule* mm = SASS_MEMORY_NEW(SupportsRule,
                                       m->pstate(),
                                       m->condition(),
                                       wrapper_block);

    mm->tabs(m->tabs());

    Bubble* bubble = SASS_MEMORY_NEW(Bubble, mm->pstate(), mm);
    return bubble;
  }

  Statement* Cssize::bubble(CssMediaRule* m)
  {
    StyleRuleObj parent = Cast<StyleRule>(SASS_MEMORY_COPY(this->parent()));

    Block* bb = SASS_MEMORY_NEW(Block, parent->block()->pstate());
    StyleRule* new_rule = SASS_MEMORY_NEW(StyleRule,
      parent->pstate(),
      parent->selector(),
      bb);
    new_rule->tabs(parent->tabs());
    new_rule->block()->concat(m->block());

    Block* wrapper_block = SASS_MEMORY_NEW(Block, m->block()->pstate());
    wrapper_block->append(new_rule);
    CssMediaRuleObj mm = SASS_MEMORY_NEW(CssMediaRule,
      m->pstate(),
      wrapper_block);
    mm->concat(m->elements());

    mm->tabs(m->tabs());

    return SASS_MEMORY_NEW(Bubble, mm->pstate(), mm);
  }

  bool Cssize::bubblable(Statement* s)
  {
    return Cast<StyleRule>(s) || (s && s->bubbles());
  }

  Block* Cssize::flatten(const Block* b)
  {
    Block* result = SASS_MEMORY_NEW(Block, b->pstate(), 0, b->is_root());
    for (size_t i = 0, L = b->length(); i < L; ++i) {
      Statement* ss = b->at(i);
      if (const Block* bb = Cast<Block>(ss)) {
        Block_Obj bs = flatten(bb);
        for (size_t j = 0, K = bs->length(); j < K; ++j) {
          result->append(bs->at(j));
        }
      }
      else {
        result->append(ss);
      }
    }
    return result;
  }

  sass::vector<std::pair<bool, Block_Obj>> Cssize::slice_by_bubble(Block* b)
  {
    sass::vector<std::pair<bool, Block_Obj>> results;

    for (size_t i = 0, L = b->length(); i < L; ++i) {
      Statement_Obj value = b->at(i);
      bool key = Cast<Bubble>(value) != NULL;

      if (!results.empty() && results.back().first == key)
      {
        Block_Obj wrapper_block = results.back().second;
        wrapper_block->append(value);
      }
      else
      {
        Block* wrapper_block = SASS_MEMORY_NEW(Block, value->pstate());
        wrapper_block->append(value);
        results.push_back(std::make_pair(key, wrapper_block));
      }
    }
    return results;
  }

  Block* Cssize::debubble(Block* children, Statement* parent)
  {
    ParentStatementObj previous_parent;
    sass::vector<std::pair<bool, Block_Obj>> baz = slice_by_bubble(children);
    Block_Obj result = SASS_MEMORY_NEW(Block, children->pstate());

    for (size_t i = 0, L = baz.size(); i < L; ++i) {
      bool is_bubble = baz[i].first;
      Block_Obj slice = baz[i].second;

      if (!is_bubble) {
        if (!parent) {
          result->append(slice);
        }
        else if (previous_parent) {
          previous_parent->block()->concat(slice);
        }
        else {
          previous_parent = SASS_MEMORY_COPY(parent);
          previous_parent->block(slice);
          previous_parent->tabs(parent->tabs());

          result->append(previous_parent);
        }
        continue;
      }

      for (size_t j = 0, K = slice->length(); j < K; ++j)
      {
        Statement_Obj ss;
        Statement_Obj stm = slice->at(j);
        // this has to go now here (too bad)
        Bubble_Obj node = Cast<Bubble>(stm);

        CssMediaRule* rule1 = NULL;
        CssMediaRule* rule2 = NULL;
        if (parent) rule1 = Cast<CssMediaRule>(parent);
        if (node) rule2 = Cast<CssMediaRule>(node->node());
        if (rule1 || rule2) {
          ss = node->node();
        }

        ss = node->node();

        if (!ss) {
          continue;
        }

        ss->tabs(ss->tabs() + node->tabs());
        ss->group_end(node->group_end());

        Block_Obj bb = SASS_MEMORY_NEW(Block,
                                    children->pstate(),
                                    children->length(),
                                    children->is_root());
        auto evaled = ss->perform(this);
        if (evaled) bb->append(evaled);

        Block_Obj wrapper_block = SASS_MEMORY_NEW(Block,
                                              children->pstate(),
                                              children->length(),
                                              children->is_root());

        Block* wrapper = flatten(bb);
        wrapper_block->append(wrapper);

        if (wrapper->length()) {
          previous_parent = {};
        }

        if (wrapper_block) {
          result->append(wrapper_block);
        }
      }
    }

    return flatten(result);
  }

  void Cssize::append_block(Block* b, Block* cur)
  {
    for (size_t i = 0, L = b->length(); i < L; ++i) {
      Statement_Obj ith = b->at(i)->perform(this);
      if (Block_Obj bb = Cast<Block>(ith)) {
        for (size_t j = 0, K = bb->length(); j < K; ++j) {
          cur->append(bb->at(j));
        }
      }
      else if (ith) {
        cur->append(ith);
      }
    }
  }

}
