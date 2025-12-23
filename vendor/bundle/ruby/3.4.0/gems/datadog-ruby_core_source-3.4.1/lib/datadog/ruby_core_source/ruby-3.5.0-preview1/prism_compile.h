#include "prism/prism.h"
#include "ruby/encoding.h"

/**
 * the getlocal and setlocal instructions require two parameters. level is how
 * many hops up the iseq stack one needs to go before finding the correct local
 * table. The index is the index in that table where our variable is.
 *
 * Because these are always calculated and used together, we'll bind them
 * together as a tuple.
 */
typedef struct pm_local_index_struct {
    int index, level;
} pm_local_index_t;

// A declaration for the struct that lives in compile.c.
struct iseq_link_anchor;

// ScopeNodes are helper nodes, and will never be part of the AST. We manually
// declare them here to avoid generating them.
typedef struct pm_scope_node {
    pm_node_t base;
    struct pm_scope_node *previous;
    pm_node_t *ast_node;
    pm_node_t *parameters;
    pm_node_t *body;
    pm_constant_id_list_t locals;

    const pm_parser_t *parser;
    rb_encoding *encoding;

    /**
     * This is a pointer to the list of script lines for the ISEQs that will be
     * associated with this scope node. It is only set if
     * RubyVM.keep_script_lines is true. If it is set, it will be set to a
     * pointer to an array that is always stack allocated (so no GC marking is
     * needed by this struct). If it is not set, it will be NULL. It is
     * inherited by all child scopes.
     */
    VALUE *script_lines;

    /**
     * This is the encoding of the actual filepath object that will be used when
     * a __FILE__ node is compiled or when the path has to be set on a syntax
     * error.
     */
    rb_encoding *filepath_encoding;

    // The size of the local table on the iseq which includes locals and hidden
    // variables.
    int local_table_for_iseq_size;

    ID *constants;
    st_table *index_lookup_table;

    // The current coverage setting, passed down through the various scopes.
    int coverage_enabled;

    /**
     * This will only be set on the top-level scope node. It will contain all of
     * the instructions pertaining to BEGIN{} nodes.
     */
    struct iseq_link_anchor *pre_execution_anchor;
} pm_scope_node_t;

void pm_scope_node_init(const pm_node_t *node, pm_scope_node_t *scope, pm_scope_node_t *previous);
void pm_scope_node_destroy(pm_scope_node_t *scope_node);

typedef struct {
    /** The parser that will do the actual parsing. */
    pm_parser_t parser;

    /** The options that will be passed to the parser. */
    pm_options_t options;

    /** The input that represents the source to be parsed. */
    pm_string_t input;

    /** The resulting scope node that will hold the generated AST. */
    pm_scope_node_t node;

    /** Whether or not this parse result has performed its parsing yet. */
    bool parsed;
} pm_parse_result_t;

#define PM_SPECIAL_CONSTANT_FLAG ((pm_constant_id_t)(1 << 31))
#define PM_CONSTANT_AND ((pm_constant_id_t)(idAnd | PM_SPECIAL_CONSTANT_FLAG))
#define PM_CONSTANT_DOT3 ((pm_constant_id_t)(idDot3 | PM_SPECIAL_CONSTANT_FLAG))
#define PM_CONSTANT_MULT ((pm_constant_id_t)(idMULT | PM_SPECIAL_CONSTANT_FLAG))
#define PM_CONSTANT_POW ((pm_constant_id_t)(idPow | PM_SPECIAL_CONSTANT_FLAG))

VALUE pm_load_file(pm_parse_result_t *result, VALUE filepath, bool load_error);
VALUE pm_parse_file(pm_parse_result_t *result, VALUE filepath, VALUE *script_lines);
VALUE pm_load_parse_file(pm_parse_result_t *result, VALUE filepath, VALUE *script_lines);
VALUE pm_parse_string(pm_parse_result_t *result, VALUE source, VALUE filepath, VALUE *script_lines);
VALUE pm_parse_stdin(pm_parse_result_t *result);
void pm_parse_result_free(pm_parse_result_t *result);

rb_iseq_t *pm_iseq_new(pm_scope_node_t *node, VALUE name, VALUE path, VALUE realpath, const rb_iseq_t *parent, enum rb_iseq_type, int *error_state);
rb_iseq_t *pm_iseq_new_top(pm_scope_node_t *node, VALUE name, VALUE path, VALUE realpath, const rb_iseq_t *parent, int *error_state);
rb_iseq_t *pm_iseq_new_main(pm_scope_node_t *node, VALUE path, VALUE realpath, const rb_iseq_t *parent, int opt, int *error_state);
rb_iseq_t *pm_iseq_new_eval(pm_scope_node_t *node, VALUE name, VALUE path, VALUE realpath, int first_lineno, const rb_iseq_t *parent, int isolated_depth, int *error_state);
rb_iseq_t *pm_iseq_new_with_opt(pm_scope_node_t *node, VALUE name, VALUE path, VALUE realpath, int first_lineno, const rb_iseq_t *parent, int isolated_depth, enum rb_iseq_type, const rb_compile_option_t *option, int *error_state);

VALUE pm_iseq_compile_node(rb_iseq_t *iseq, pm_scope_node_t *node);
