#ifndef RUBY_NODE_H
#define RUBY_NODE_H 1
/**********************************************************************

  node.h -

  $Author$
  created at: Fri May 28 15:14:02 JST 1993

  Copyright (C) 1993-2007 Yukihiro Matsumoto

**********************************************************************/

#include <stdbool.h>
#include "rubyparser.h"
#include "ruby/backward/2/attributes.h"

typedef void (*bug_report_func)(const char *fmt, ...);

typedef struct node_buffer_elem_struct {
    struct node_buffer_elem_struct *next;
    long len; /* Length of nodes */
    size_t allocated; /* Total memory size of allocated buf */
    size_t used; /* Current usage of buf */
    NODE **nodes; /* Array of node pointers */
    NODE *buf[FLEX_ARY_LEN];
} node_buffer_elem_t;

typedef struct {
    node_buffer_elem_t *head;
    node_buffer_elem_t *last;
} node_buffer_list_t;

struct node_buffer_struct {
    node_buffer_list_t unmarkable;
    node_buffer_list_t markable;
    struct rb_ast_local_table_link *local_tables;
    VALUE mark_hash;
    // - id (sequence number)
    // - token_type
    // - text of token
    // - location info
    // Array, whose entry is array
    VALUE tokens;
#ifdef UNIVERSAL_PARSER
    rb_parser_config_t *config;
#endif
};

RUBY_SYMBOL_EXPORT_BEGIN

#ifdef UNIVERSAL_PARSER
rb_ast_t *rb_ast_new(rb_parser_config_t *config);
#else
rb_ast_t *rb_ast_new(void);
#endif
size_t rb_ast_memsize(const rb_ast_t*);
void rb_ast_dispose(rb_ast_t*);
VALUE rb_ast_tokens(rb_ast_t *ast);
#if RUBY_DEBUG
void rb_ast_node_type_change(NODE *n, enum node_type type);
#endif
const char *ruby_node_name(int node);
void rb_node_init(NODE *n, enum node_type type);

void rb_ast_mark(rb_ast_t*);
void rb_ast_update_references(rb_ast_t*);
void rb_ast_free(rb_ast_t*);
void rb_ast_add_mark_object(rb_ast_t*, VALUE);
void rb_ast_delete_mark_object(rb_ast_t*, VALUE);
void rb_ast_set_tokens(rb_ast_t*, VALUE);
NODE *rb_ast_newnode(rb_ast_t*, enum node_type type, size_t size, size_t alignment);
void rb_ast_delete_node(rb_ast_t*, NODE *n);
rb_ast_id_table_t *rb_ast_new_local_table(rb_ast_t*, int);
rb_ast_id_table_t *rb_ast_resize_latest_local_table(rb_ast_t*, int);

VALUE rb_parser_dump_tree(const NODE *node, int comment);

const struct kwtable *rb_reserved_word(const char *, unsigned int);

struct parser_params;
void *rb_parser_malloc(struct parser_params *, size_t);
void *rb_parser_realloc(struct parser_params *, void *, size_t);
void *rb_parser_calloc(struct parser_params *, size_t, size_t);
void rb_parser_free(struct parser_params *, void *);
PRINTF_ARGS(void rb_parser_printf(struct parser_params *parser, const char *fmt, ...), 2, 3);
VALUE rb_node_set_type(NODE *n, enum node_type t);

RUBY_SYMBOL_EXPORT_END

#define NODE_LSHIFT (NODE_TYPESHIFT+7)
#define NODE_LMASK  (((SIGNED_VALUE)1<<(sizeof(VALUE)*CHAR_BIT-NODE_LSHIFT))-1)

#define nd_line(n) (int)(((SIGNED_VALUE)(n)->flags)>>NODE_LSHIFT)
#define nd_set_line(n,l) \
    (n)->flags=(((n)->flags&~((VALUE)(-1)<<NODE_LSHIFT))|((VALUE)((l)&NODE_LMASK)<<NODE_LSHIFT))


#define NODE_SPECIAL_REQUIRED_KEYWORD ((NODE *)-1)
#define NODE_REQUIRED_KEYWORD_P(node) ((node) == NODE_SPECIAL_REQUIRED_KEYWORD)
#define NODE_SPECIAL_NO_NAME_REST     ((NODE *)-1)
#define NODE_NAMED_REST_P(node) ((node) != NODE_SPECIAL_NO_NAME_REST)
#define NODE_SPECIAL_EXCESSIVE_COMMA   ((ID)1)
#define NODE_SPECIAL_NO_REST_KEYWORD   ((NODE *)-1)

#define nd_first_column(n) ((int)(RNODE(n)->nd_loc.beg_pos.column))
#define nd_set_first_column(n, v) (RNODE(n)->nd_loc.beg_pos.column = (v))
#define nd_first_lineno(n) ((int)(RNODE(n)->nd_loc.beg_pos.lineno))
#define nd_set_first_lineno(n, v) (RNODE(n)->nd_loc.beg_pos.lineno = (v))
#define nd_first_loc(n) (RNODE(n)->nd_loc.beg_pos)
#define nd_set_first_loc(n, v) (nd_first_loc(n) = (v))

#define nd_last_column(n) ((int)(RNODE(n)->nd_loc.end_pos.column))
#define nd_set_last_column(n, v) (RNODE(n)->nd_loc.end_pos.column = (v))
#define nd_last_lineno(n) ((int)(RNODE(n)->nd_loc.end_pos.lineno))
#define nd_set_last_lineno(n, v) (RNODE(n)->nd_loc.end_pos.lineno = (v))
#define nd_last_loc(n) (RNODE(n)->nd_loc.end_pos)
#define nd_set_last_loc(n, v) (nd_last_loc(n) = (v))
#define nd_node_id(n) (RNODE(n)->node_id)
#define nd_set_node_id(n,id) (RNODE(n)->node_id = (id))

static inline bool
nd_type_p(const NODE *n, enum node_type t)
{
    return (enum node_type)nd_type(n) == t;
}

#endif /* RUBY_NODE_H */
