// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"
#include "ast.hpp"
#include "check_nesting.hpp"

namespace Sass {

  CheckNesting::CheckNesting()
  : parents(sass::vector<Statement*>()),
    traces(sass::vector<Backtrace>()),
    parent(0), current_mixin_definition(0)
  { }

  void error(AST_Node* node, Backtraces traces, sass::string msg) {
    traces.push_back(Backtrace(node->pstate()));
    throw Exception::InvalidSass(node->pstate(), traces, msg);
  }

  Statement* CheckNesting::visit_children(Statement* parent)
  {
    Statement* old_parent = this->parent;

    if (AtRootRule* root = Cast<AtRootRule>(parent)) {
      sass::vector<Statement*> old_parents = this->parents;
      sass::vector<Statement*> new_parents;

      for (size_t i = 0, L = this->parents.size(); i < L; i++) {
        Statement* p = this->parents.at(i);
        if (!root->exclude_node(p)) {
          new_parents.push_back(p);
        }
      }
      this->parents = new_parents;

      for (size_t i = this->parents.size(); i > 0; i--) {
        Statement* p = 0;
        Statement* gp = 0;
        if (i > 0) p = this->parents.at(i - 1);
        if (i > 1) gp = this->parents.at(i - 2);

        if (!this->is_transparent_parent(p, gp)) {
          this->parent = p;
          break;
        }
      }

      AtRootRule* ar = Cast<AtRootRule>(parent);
      Block* ret = ar->block();

      if (ret != NULL) {
        for (auto n : ret->elements()) {
          n->perform(this);
        }
      }

      this->parent = old_parent;
      this->parents = old_parents;

      return ret;
    }

    if (!this->is_transparent_parent(parent, old_parent)) {
      this->parent = parent;
    }

    this->parents.push_back(parent);

    Block* b = Cast<Block>(parent);

    if (Trace* trace = Cast<Trace>(parent)) {
      if (trace->type() == 'i') {
        this->traces.push_back(Backtrace(trace->pstate()));
      }
    }

    if (!b) {
      if (ParentStatement* bb = Cast<ParentStatement>(parent)) {
        b = bb->block();
      }
    }

    if (b) {
      for (auto n : b->elements()) {
        n->perform(this);
      }
    }

    this->parent = old_parent;
    this->parents.pop_back();

    if (Trace* trace = Cast<Trace>(parent)) {
      if (trace->type() == 'i') {
        this->traces.pop_back();
      }
    }

    return b;
  }


  Statement* CheckNesting::operator()(Block* b)
  {
    return this->visit_children(b);
  }

  Statement* CheckNesting::operator()(Definition* n)
  {
    if (!this->should_visit(n)) return NULL;
    if (!is_mixin(n)) {
      visit_children(n);
      return n;
    }

    Definition* old_mixin_definition = this->current_mixin_definition;
    this->current_mixin_definition = n;

    visit_children(n);

    this->current_mixin_definition = old_mixin_definition;

    return n;
  }

  Statement* CheckNesting::operator()(If* i)
  {
    this->visit_children(i);

    if (Block* b = Cast<Block>(i->alternative())) {
      for (auto n : b->elements()) n->perform(this);
    }

    return i;
  }

  bool CheckNesting::should_visit(Statement* node)
  {
    if (!this->parent) return true;

    if (Cast<Content>(node))
    { this->invalid_content_parent(this->parent, node); }

    if (is_charset(node))
    { this->invalid_charset_parent(this->parent, node); }

    if (Cast<ExtendRule>(node))
    { this->invalid_extend_parent(this->parent, node); }

    // if (Cast<Import>(node))
    // { this->invalid_import_parent(this->parent); }

    if (this->is_mixin(node))
    { this->invalid_mixin_definition_parent(this->parent, node); }

    if (this->is_function(node))
    { this->invalid_function_parent(this->parent, node); }

    if (this->is_function(this->parent))
    { this->invalid_function_child(node); }

    if (Declaration* d = Cast<Declaration>(node))
    {
      this->invalid_prop_parent(this->parent, node);
      this->invalid_value_child(d->value());
    }

    if (Cast<Declaration>(this->parent))
    { this->invalid_prop_child(node); }

    if (Cast<Return>(node))
    { this->invalid_return_parent(this->parent, node); }

    return true;
  }

  void CheckNesting::invalid_content_parent(Statement* parent, AST_Node* node)
  {
    if (!this->current_mixin_definition) {
      error(node, traces, "@content may only be used within a mixin.");
    }
  }

  void CheckNesting::invalid_charset_parent(Statement* parent, AST_Node* node)
  {
    if (!(
        is_root_node(parent)
    )) {
      error(node, traces, "@charset may only be used at the root of a document.");
    }
  }

  void CheckNesting::invalid_extend_parent(Statement* parent, AST_Node* node)
  {
    if (!(
        Cast<StyleRule>(parent) ||
        Cast<Mixin_Call>(parent) ||
        is_mixin(parent)
    )) {
      error(node, traces, "Extend directives may only be used within rules.");
    }
  }

  // void CheckNesting::invalid_import_parent(Statement* parent, AST_Node* node)
  // {
  //   for (auto pp : this->parents) {
  //     if (
  //         Cast<EachRule>(pp) ||
  //         Cast<ForRule>(pp) ||
  //         Cast<If>(pp) ||
  //         Cast<WhileRule>(pp) ||
  //         Cast<Trace>(pp) ||
  //         Cast<Mixin_Call>(pp) ||
  //         is_mixin(pp)
  //     ) {
  //       error(node, traces, "Import directives may not be defined within control directives or other mixins.");
  //     }
  //   }

  //   if (this->is_root_node(parent)) {
  //     return;
  //   }

  //   if (false/*n.css_import?*/) {
  //     error(node, traces, "CSS import directives may only be used at the root of a document.");
  //   }
  // }

  void CheckNesting::invalid_mixin_definition_parent(Statement* parent, AST_Node* node)
  {
    for (Statement* pp : this->parents) {
      if (
          Cast<EachRule>(pp) ||
          Cast<ForRule>(pp) ||
          Cast<If>(pp) ||
          Cast<WhileRule>(pp) ||
          Cast<Trace>(pp) ||
          Cast<Mixin_Call>(pp) ||
          is_mixin(pp)
      ) {
        error(node, traces, "Mixins may not be defined within control directives or other mixins.");
      }
    }
  }

  void CheckNesting::invalid_function_parent(Statement* parent, AST_Node* node)
  {
    for (Statement* pp : this->parents) {
      if (
          Cast<EachRule>(pp) ||
          Cast<ForRule>(pp) ||
          Cast<If>(pp) ||
          Cast<WhileRule>(pp) ||
          Cast<Trace>(pp) ||
          Cast<Mixin_Call>(pp) ||
          is_mixin(pp)
      ) {
        error(node, traces, "Functions may not be defined within control directives or other mixins.");
      }
    }
  }

  void CheckNesting::invalid_function_child(Statement* child)
  {
    if (!(
        Cast<EachRule>(child) ||
        Cast<ForRule>(child) ||
        Cast<If>(child) ||
        Cast<WhileRule>(child) ||
        Cast<Trace>(child) ||
        Cast<Comment>(child) ||
        Cast<DebugRule>(child) ||
        Cast<Return>(child) ||
        Cast<Variable>(child) ||
        // Ruby Sass doesn't distinguish variables and assignments
        Cast<Assignment>(child) ||
        Cast<WarningRule>(child) ||
        Cast<ErrorRule>(child)
    )) {
      error(child, traces, "Functions can only contain variable declarations and control directives.");
    }
  }

  void CheckNesting::invalid_prop_child(Statement* child)
  {
    if (!(
        Cast<EachRule>(child) ||
        Cast<ForRule>(child) ||
        Cast<If>(child) ||
        Cast<WhileRule>(child) ||
        Cast<Trace>(child) ||
        Cast<Comment>(child) ||
        Cast<Declaration>(child) ||
        Cast<Mixin_Call>(child)
    )) {
      error(child, traces, "Illegal nesting: Only properties may be nested beneath properties.");
    }
  }

  void CheckNesting::invalid_prop_parent(Statement* parent, AST_Node* node)
  {
    if (!(
        is_mixin(parent) ||
        is_directive_node(parent) ||
        Cast<StyleRule>(parent) ||
        Cast<Keyframe_Rule>(parent) ||
        Cast<Declaration>(parent) ||
        Cast<Mixin_Call>(parent)
    )) {
      error(node, traces, "Properties are only allowed within rules, directives, mixin includes, or other properties.");
    }
  }

  void CheckNesting::invalid_value_child(AST_Node* d)
  {
    if (Map* m = Cast<Map>(d)) {
      traces.push_back(Backtrace(m->pstate()));
      throw Exception::InvalidValue(traces, *m);
    }
    if (Number* n = Cast<Number>(d)) {
      if (!n->is_valid_css_unit()) {
        traces.push_back(Backtrace(n->pstate()));
        throw Exception::InvalidValue(traces, *n);
      }
    }

    // error(dbg + " isn't a valid CSS value.", m->pstate(),);

  }

  void CheckNesting::invalid_return_parent(Statement* parent, AST_Node* node)
  {
    if (!this->is_function(parent)) {
      error(node, traces, "@return may only be used within a function.");
    }
  }

  bool CheckNesting::is_transparent_parent(Statement* parent, Statement* grandparent)
  {
    bool parent_bubbles = parent && parent->bubbles();

    bool valid_bubble_node = parent_bubbles &&
                             !is_root_node(grandparent) &&
                             !is_at_root_node(grandparent);

    return Cast<Import>(parent) ||
           Cast<EachRule>(parent) ||
           Cast<ForRule>(parent) ||
           Cast<If>(parent) ||
           Cast<WhileRule>(parent) ||
           Cast<Trace>(parent) ||
           valid_bubble_node;
  }

  bool CheckNesting::is_charset(Statement* n)
  {
    AtRule* d = Cast<AtRule>(n);
    return d && d->keyword() == "charset";
  }

  bool CheckNesting::is_mixin(Statement* n)
  {
    Definition* def = Cast<Definition>(n);
    return def && def->type() == Definition::MIXIN;
  }

  bool CheckNesting::is_function(Statement* n)
  {
    Definition* def = Cast<Definition>(n);
    return def && def->type() == Definition::FUNCTION;
  }

  bool CheckNesting::is_root_node(Statement* n)
  {
    if (Cast<StyleRule>(n)) return false;

    Block* b = Cast<Block>(n);
    return b && b->is_root();
  }

  bool CheckNesting::is_at_root_node(Statement* n)
  {
    return Cast<AtRootRule>(n) != NULL;
  }

  bool CheckNesting::is_directive_node(Statement* n)
  {
    return Cast<AtRule>(n) ||
           Cast<Import>(n) ||
      Cast<MediaRule>(n) ||
      Cast<CssMediaRule>(n) ||
      Cast<SupportsRule>(n);
  }
}
