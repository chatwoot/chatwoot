#ifndef SASS_CHECK_NESTING_H
#define SASS_CHECK_NESTING_H

// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"
#include "ast.hpp"
#include "operation.hpp"
#include <vector>

namespace Sass {

  class CheckNesting : public Operation_CRTP<Statement*, CheckNesting> {

    sass::vector<Statement*>  parents;
    Backtraces                  traces;
    Statement*               parent;
    Definition*              current_mixin_definition;

    Statement* before(Statement*);
    Statement* visit_children(Statement*);

  public:
    CheckNesting();
    ~CheckNesting() { }

    Statement* operator()(Block*);
    Statement* operator()(Definition*);
    Statement* operator()(If*);

    template <typename U>
    Statement* fallback(U x) {
      Statement* s = Cast<Statement>(x);
      if (s && this->should_visit(s)) {
        Block* b1 = Cast<Block>(s);
        ParentStatement* b2 = Cast<ParentStatement>(s);
        if (b1 || b2) return visit_children(s);
      }
      return s;
    }

  private:
    void invalid_content_parent(Statement*, AST_Node*);
    void invalid_charset_parent(Statement*, AST_Node*);
    void invalid_extend_parent(Statement*, AST_Node*);
    // void invalid_import_parent(Statement*);
    void invalid_mixin_definition_parent(Statement*, AST_Node*);
    void invalid_function_parent(Statement*, AST_Node*);

    void invalid_function_child(Statement*);
    void invalid_prop_child(Statement*);
    void invalid_prop_parent(Statement*, AST_Node*);
    void invalid_return_parent(Statement*, AST_Node*);
    void invalid_value_child(AST_Node*);

    bool is_transparent_parent(Statement*, Statement*);

    bool should_visit(Statement*);

    bool is_charset(Statement*);
    bool is_mixin(Statement*);
    bool is_function(Statement*);
    bool is_root_node(Statement*);
    bool is_at_root_node(Statement*);
    bool is_directive_node(Statement*);
  };

}

#endif
