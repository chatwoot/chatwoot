#include "prism/prism.h"

// ScopeNodes are helper nodes, and will never be part of the AST. We manually
// declare them here to avoid generating them.
typedef struct pm_scope_node {
    pm_node_t base;
    struct pm_scope_node *previous;
    pm_node_t *ast_node;
    pm_node_t *parameters;
    pm_node_t *body;
    pm_constant_id_list_t locals;
    pm_parser_t *parser;

    // The size of the local table
    // on the iseq which includes
    // locals and hidden variables
    int local_table_for_iseq_size;

    ID *constants;
    st_table *index_lookup_table;

    // Some locals are defined at higher scopes than they are used. We can use
    // this offset to control which parent scopes local table we should be
    // referencing from the current scope.
    unsigned int local_depth_offset;
} pm_scope_node_t;

void pm_scope_node_init(const pm_node_t *node, pm_scope_node_t *scope, pm_scope_node_t *previous, pm_parser_t *parser);
bool *rb_ruby_prism_ptr(void);
