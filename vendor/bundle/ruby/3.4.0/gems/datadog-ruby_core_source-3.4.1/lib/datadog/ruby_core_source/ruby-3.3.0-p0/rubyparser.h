#ifndef RUBY_RUBYPARSER_H
#define RUBY_RUBYPARSER_H 1
/*
 * This is a header file for librubyparser interface
 */

#include <stdarg.h> /* for va_list */
#include <assert.h>

#ifdef UNIVERSAL_PARSER

#define rb_encoding void
#define OnigCodePoint unsigned int
#include "parser_st.h"
#ifndef RUBY_RUBY_H
#include "parser_value.h"
#endif

#else

#include "ruby/encoding.h"

#endif

/*
 * AST Node
 */
enum node_type {
    NODE_SCOPE,
    NODE_BLOCK,
    NODE_IF,
    NODE_UNLESS,
    NODE_CASE,
    NODE_CASE2,
    NODE_CASE3,
    NODE_WHEN,
    NODE_IN,
    NODE_WHILE,
    NODE_UNTIL,
    NODE_ITER,
    NODE_FOR,
    NODE_FOR_MASGN,
    NODE_BREAK,
    NODE_NEXT,
    NODE_REDO,
    NODE_RETRY,
    NODE_BEGIN,
    NODE_RESCUE,
    NODE_RESBODY,
    NODE_ENSURE,
    NODE_AND,
    NODE_OR,
    NODE_MASGN,
    NODE_LASGN,
    NODE_DASGN,
    NODE_GASGN,
    NODE_IASGN,
    NODE_CDECL,
    NODE_CVASGN,
    NODE_OP_ASGN1,
    NODE_OP_ASGN2,
    NODE_OP_ASGN_AND,
    NODE_OP_ASGN_OR,
    NODE_OP_CDECL,
    NODE_CALL,
    NODE_OPCALL,
    NODE_FCALL,
    NODE_VCALL,
    NODE_QCALL,
    NODE_SUPER,
    NODE_ZSUPER,
    NODE_LIST,
    NODE_ZLIST,
    NODE_HASH,
    NODE_RETURN,
    NODE_YIELD,
    NODE_LVAR,
    NODE_DVAR,
    NODE_GVAR,
    NODE_IVAR,
    NODE_CONST,
    NODE_CVAR,
    NODE_NTH_REF,
    NODE_BACK_REF,
    NODE_MATCH,
    NODE_MATCH2,
    NODE_MATCH3,
    NODE_LIT,
    NODE_STR,
    NODE_DSTR,
    NODE_XSTR,
    NODE_DXSTR,
    NODE_EVSTR,
    NODE_DREGX,
    NODE_ONCE,
    NODE_ARGS,
    NODE_ARGS_AUX,
    NODE_OPT_ARG,
    NODE_KW_ARG,
    NODE_POSTARG,
    NODE_ARGSCAT,
    NODE_ARGSPUSH,
    NODE_SPLAT,
    NODE_BLOCK_PASS,
    NODE_DEFN,
    NODE_DEFS,
    NODE_ALIAS,
    NODE_VALIAS,
    NODE_UNDEF,
    NODE_CLASS,
    NODE_MODULE,
    NODE_SCLASS,
    NODE_COLON2,
    NODE_COLON3,
    NODE_DOT2,
    NODE_DOT3,
    NODE_FLIP2,
    NODE_FLIP3,
    NODE_SELF,
    NODE_NIL,
    NODE_TRUE,
    NODE_FALSE,
    NODE_ERRINFO,
    NODE_DEFINED,
    NODE_POSTEXE,
    NODE_DSYM,
    NODE_ATTRASGN,
    NODE_LAMBDA,
    NODE_ARYPTN,
    NODE_HSHPTN,
    NODE_FNDPTN,
    NODE_ERROR,
    NODE_RIPPER,
    NODE_RIPPER_VALUES,
    NODE_LAST
};

#ifndef FLEX_ARY_LEN
/* From internal/compilers.h */
/* A macro for defining a flexible array, like: VALUE ary[FLEX_ARY_LEN]; */
#if defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 199901L)
# define FLEX_ARY_LEN   /* VALUE ary[]; */
#elif defined(__GNUC__) && !defined(__STRICT_ANSI__)
# define FLEX_ARY_LEN 0 /* VALUE ary[0]; */
#else
# define FLEX_ARY_LEN 1 /* VALUE ary[1]; */
#endif
#endif

typedef struct rb_ast_id_table {
    int size;
    ID ids[FLEX_ARY_LEN];
} rb_ast_id_table_t;

typedef struct rb_code_position_struct {
    int lineno;
    int column;
} rb_code_position_t;

typedef struct rb_code_location_struct {
    rb_code_position_t beg_pos;
    rb_code_position_t end_pos;
} rb_code_location_t;

/* Header part of AST Node */
typedef struct RNode {
    VALUE flags;
    rb_code_location_t nd_loc;
    int node_id;
} NODE;

typedef struct RNode_SCOPE {
    NODE node;

    rb_ast_id_table_t *nd_tbl;
    struct RNode *nd_body;
    struct RNode_ARGS *nd_args;
} rb_node_scope_t;

typedef struct RNode_BLOCK {
    NODE node;

    struct RNode *nd_head;
    struct RNode *nd_end;
    struct RNode *nd_next;
} rb_node_block_t;

typedef struct RNode_IF {
    NODE node;

    struct RNode *nd_cond;
    struct RNode *nd_body;
    struct RNode *nd_else;
} rb_node_if_t;

typedef struct RNode_UNLESS {
    NODE node;

    struct RNode *nd_cond;
    struct RNode *nd_body;
    struct RNode *nd_else;
} rb_node_unless_t;

typedef struct RNode_CASE {
    NODE node;

    struct RNode *nd_head;
    struct RNode *nd_body;
} rb_node_case_t;

typedef struct RNode_CASE2 {
    NODE node;

    struct RNode *nd_head;
    struct RNode *nd_body;
} rb_node_case2_t;

typedef struct RNode_CASE3 {
    NODE node;

    struct RNode *nd_head;
    struct RNode *nd_body;
} rb_node_case3_t;

typedef struct RNode_WHEN {
    NODE node;

    struct RNode *nd_head;
    struct RNode *nd_body;
    struct RNode *nd_next;
} rb_node_when_t;

typedef struct RNode_IN {
    NODE node;

    struct RNode *nd_head;
    struct RNode *nd_body;
    struct RNode *nd_next;
} rb_node_in_t;

/* RNode_WHILE and RNode_UNTIL should be same structure */
typedef struct RNode_WHILE {
    NODE node;

    struct RNode *nd_cond;
    struct RNode *nd_body;
    long nd_state;
} rb_node_while_t;

typedef struct RNode_UNTIL {
    NODE node;

    struct RNode *nd_cond;
    struct RNode *nd_body;
    long nd_state;
} rb_node_until_t;

/* RNode_ITER and RNode_FOR should be same structure */
typedef struct RNode_ITER {
    NODE node;

    struct RNode *nd_body;
    struct RNode *nd_iter;
} rb_node_iter_t;

typedef struct RNode_FOR {
    NODE node;

    struct RNode *nd_body;
    struct RNode *nd_iter;
} rb_node_for_t;

typedef struct RNode_FOR_MASGN {
    NODE node;

    struct RNode *nd_var;
} rb_node_for_masgn_t;

/* RNode_BREAK, RNode_NEXT and RNode_REDO should be same structure */
typedef struct RNode_BREAK {
    NODE node;

    struct RNode *nd_chain;
    struct RNode *nd_stts;
} rb_node_break_t;

typedef struct RNode_NEXT {
    NODE node;

    struct RNode *nd_chain;
    struct RNode *nd_stts;
} rb_node_next_t;

typedef struct RNode_REDO {
    NODE node;

    struct RNode *nd_chain;
} rb_node_redo_t;

typedef struct RNode_RETRY {
    NODE node;
} rb_node_retry_t;

typedef struct RNode_BEGIN {
    NODE node;

    struct RNode *nd_body;
} rb_node_begin_t;

typedef struct RNode_RESCUE {
    NODE node;

    struct RNode *nd_head;
    struct RNode *nd_resq;
    struct RNode *nd_else;
} rb_node_rescue_t;

typedef struct RNode_RESBODY {
    NODE node;

    struct RNode *nd_head;
    struct RNode *nd_body;
    struct RNode *nd_args;
} rb_node_resbody_t;

typedef struct RNode_ENSURE {
    NODE node;

    struct RNode *nd_head;
    struct RNode *nd_resq; /* Maybe not used other than reduce_nodes */
    struct RNode *nd_ensr;
} rb_node_ensure_t;

/* RNode_AND and RNode_OR should be same structure */
typedef struct RNode_AND {
    NODE node;

    struct RNode *nd_1st;
    struct RNode *nd_2nd;
} rb_node_and_t;

typedef struct RNode_OR {
    NODE node;

    struct RNode *nd_1st;
    struct RNode *nd_2nd;
} rb_node_or_t;

typedef struct RNode_MASGN {
    NODE node;

    struct RNode *nd_head;
    struct RNode *nd_value;
    struct RNode *nd_args;
} rb_node_masgn_t;

typedef struct RNode_LASGN {
    NODE node;

    ID nd_vid;
    struct RNode *nd_value;
} rb_node_lasgn_t;

typedef struct RNode_DASGN {
    NODE node;

    ID nd_vid;
    struct RNode *nd_value;
} rb_node_dasgn_t;

typedef struct RNode_GASGN {
    NODE node;

    ID nd_vid;
    struct RNode *nd_value;
} rb_node_gasgn_t;

typedef struct RNode_IASGN {
    NODE node;

    ID nd_vid;
    struct RNode *nd_value;
} rb_node_iasgn_t;

typedef struct RNode_CDECL {
    NODE node;

    ID nd_vid;
    struct RNode *nd_value;
    struct RNode *nd_else;
} rb_node_cdecl_t;

typedef struct RNode_CVASGN {
    NODE node;

    ID nd_vid;
    struct RNode *nd_value;
} rb_node_cvasgn_t;

typedef struct RNode_OP_ASGN1 {
    NODE node;

    struct RNode *nd_recv;
    ID nd_mid;
    struct RNode *nd_index;
    struct RNode *nd_rvalue;
} rb_node_op_asgn1_t;

typedef struct RNode_OP_ASGN2 {
    NODE node;

    struct RNode *nd_recv;
    struct RNode *nd_value;
    ID nd_vid;
    ID nd_mid;
    bool nd_aid;
} rb_node_op_asgn2_t;

typedef struct RNode_OP_ASGN_AND {
    NODE node;

    struct RNode *nd_head;
    struct RNode *nd_value;
} rb_node_op_asgn_and_t;

typedef struct RNode_OP_ASGN_OR {
    NODE node;

    struct RNode *nd_head;
    struct RNode *nd_value;
} rb_node_op_asgn_or_t;

typedef struct RNode_OP_CDECL {
    NODE node;

    struct RNode *nd_head;
    struct RNode *nd_value;
    ID nd_aid;
} rb_node_op_cdecl_t;

typedef struct RNode_CALL {
    NODE node;

    struct RNode *nd_recv;
    ID nd_mid;
    struct RNode *nd_args;
} rb_node_call_t;

typedef struct RNode_OPCALL {
    NODE node;

    struct RNode *nd_recv;
    ID nd_mid;
    struct RNode *nd_args;
} rb_node_opcall_t;

typedef struct RNode_FCALL {
    NODE node;

    ID nd_mid;
    struct RNode *nd_args;
} rb_node_fcall_t;

typedef struct RNode_VCALL {
    NODE node;

    ID nd_mid;
} rb_node_vcall_t;

typedef struct RNode_QCALL {
    NODE node;

    struct RNode *nd_recv;
    ID nd_mid;
    struct RNode *nd_args;
} rb_node_qcall_t;

typedef struct RNode_SUPER {
    NODE node;

    struct RNode *nd_args;
} rb_node_super_t;

typedef struct RNode_ZSUPER {
    NODE node;
} rb_node_zsuper_t;

/*

  Structure of LIST:

  LIST                     +--> LIST
   * head --> element      |     * head
   * alen (length of list) |     * nd_end (point to the last LIST)
   * next -----------------+     * next


  RNode_LIST and RNode_VALUES should be same structure
*/
typedef struct RNode_LIST {
    NODE node;

    struct RNode *nd_head; /* element */
    union {
        long nd_alen;
        struct RNode *nd_end; /* Second list node has this structure */
    } as;
    struct RNode *nd_next; /* next list node */
} rb_node_list_t;

typedef struct RNode_ZLIST {
    NODE node;
} rb_node_zlist_t;

typedef struct RNode_VALUES {
    NODE node;

    struct RNode *nd_head;
    long nd_alen;
    struct RNode *nd_next;
} rb_node_values_t;

typedef struct RNode_HASH {
    NODE node;

    struct RNode *nd_head;
    long nd_brace;
} rb_node_hash_t;

typedef struct RNode_RETURN {
    NODE node;

    struct RNode *nd_stts;
} rb_node_return_t;

typedef struct RNode_YIELD {
    NODE node;

    struct RNode *nd_head;
} rb_node_yield_t;

typedef struct RNode_LVAR {
    NODE node;

    ID nd_vid;
} rb_node_lvar_t;

typedef struct RNode_DVAR {
    NODE node;

    ID nd_vid;
} rb_node_dvar_t;

typedef struct RNode_GVAR {
    NODE node;

    ID nd_vid;
} rb_node_gvar_t;

typedef struct RNode_IVAR {
    NODE node;

    ID nd_vid;
} rb_node_ivar_t;

typedef struct RNode_CONST {
    NODE node;

    ID nd_vid;
} rb_node_const_t;

typedef struct RNode_CVAR {
    NODE node;

    ID nd_vid;
} rb_node_cvar_t;

typedef struct RNode_NTH_REF {
    NODE node;

    long nd_nth;
} rb_node_nth_ref_t;

typedef struct RNode_BACK_REF {
    NODE node;

    long nd_nth;
} rb_node_back_ref_t;

/* RNode_MATCH, RNode_LIT, RNode_STR and RNode_XSTR should be same structure */
typedef struct RNode_MATCH {
    NODE node;

    VALUE nd_lit;
} rb_node_match_t;

typedef struct RNode_MATCH2 {
    NODE node;

    struct RNode *nd_recv;
    struct RNode *nd_value;
    struct RNode *nd_args;
} rb_node_match2_t;

typedef struct RNode_MATCH3 {
    NODE node;

    struct RNode *nd_recv;
    struct RNode *nd_value;
} rb_node_match3_t;

typedef struct RNode_LIT {
    NODE node;

    VALUE nd_lit;
} rb_node_lit_t;

typedef struct RNode_STR {
    NODE node;

    VALUE nd_lit;
} rb_node_str_t;

/* RNode_DSTR, RNode_DXSTR and RNode_DSYM should be same structure */
typedef struct RNode_DSTR {
    NODE node;

    VALUE nd_lit;
    union {
        long nd_alen;
        struct RNode *nd_end; /* Second dstr node has this structure. See also RNode_LIST */
    } as;
    struct RNode_LIST *nd_next;
} rb_node_dstr_t;

typedef struct RNode_XSTR {
    NODE node;

    VALUE nd_lit;
} rb_node_xstr_t;

typedef struct RNode_DXSTR {
    NODE node;

    VALUE nd_lit;
    long nd_alen;
    struct RNode_LIST *nd_next;
} rb_node_dxstr_t;

typedef struct RNode_EVSTR {
    NODE node;

    struct RNode *nd_body;
} rb_node_evstr_t;

typedef struct RNode_DREGX {
    NODE node;

    VALUE nd_lit;
    ID nd_cflag;
    struct RNode_LIST *nd_next;
} rb_node_dregx_t;

typedef struct RNode_ONCE {
    NODE node;

    struct RNode *nd_body;
} rb_node_once_t;

struct rb_args_info {
    NODE *pre_init;
    NODE *post_init;

    int pre_args_num;  /* count of mandatory pre-arguments */
    int post_args_num; /* count of mandatory post-arguments */

    ID first_post_arg;

    ID rest_arg;
    ID block_arg;

    struct RNode_KW_ARG *kw_args;
    NODE *kw_rest_arg;

    struct RNode_OPT_ARG *opt_args;
    unsigned int no_kwarg: 1;
    unsigned int ruby2_keywords: 1;
    unsigned int forwarding: 1;
};

typedef struct RNode_ARGS {
    NODE node;

    struct rb_args_info nd_ainfo;
} rb_node_args_t;

typedef struct RNode_ARGS_AUX {
    NODE node;

    ID nd_pid;
    long nd_plen;
    struct RNode *nd_next;
} rb_node_args_aux_t;

typedef struct RNode_OPT_ARG {
    NODE node;

    struct RNode *nd_body;
    struct RNode_OPT_ARG *nd_next;
} rb_node_opt_arg_t;

typedef struct RNode_KW_ARG {
    NODE node;

    struct RNode *nd_body;
    struct RNode_KW_ARG *nd_next;
} rb_node_kw_arg_t;

typedef struct RNode_POSTARG {
    NODE node;

    struct RNode *nd_1st;
    struct RNode *nd_2nd;
} rb_node_postarg_t;

typedef struct RNode_ARGSCAT {
    NODE node;

    struct RNode *nd_head;
    struct RNode *nd_body;
} rb_node_argscat_t;

typedef struct RNode_ARGSPUSH {
    NODE node;

    struct RNode *nd_head;
    struct RNode *nd_body;
} rb_node_argspush_t;

typedef struct RNode_SPLAT {
    NODE node;

    struct RNode *nd_head;
} rb_node_splat_t;

typedef struct RNode_BLOCK_PASS {
    NODE node;

    struct RNode *nd_head;
    struct RNode *nd_body;
} rb_node_block_pass_t;

typedef struct RNode_DEFN {
    NODE node;

    ID nd_mid;
    struct RNode *nd_defn;
} rb_node_defn_t;

typedef struct RNode_DEFS {
    NODE node;

    struct RNode *nd_recv;
    ID nd_mid;
    struct RNode *nd_defn;
} rb_node_defs_t;

typedef struct RNode_ALIAS {
    NODE node;

    struct RNode *nd_1st;
    struct RNode *nd_2nd;
} rb_node_alias_t;

typedef struct RNode_VALIAS {
    NODE node;

    ID nd_alias;
    ID nd_orig;
} rb_node_valias_t;

typedef struct RNode_UNDEF {
    NODE node;

    struct RNode *nd_undef;
} rb_node_undef_t;

typedef struct RNode_CLASS {
    NODE node;

    struct RNode *nd_cpath;
    struct RNode *nd_body;
    struct RNode *nd_super;
} rb_node_class_t;

typedef struct RNode_MODULE {
    NODE node;

    struct RNode *nd_cpath;
    struct RNode *nd_body;
} rb_node_module_t;

typedef struct RNode_SCLASS {
    NODE node;

    struct RNode *nd_recv;
    struct RNode *nd_body;
} rb_node_sclass_t;

typedef struct RNode_COLON2 {
    NODE node;

    struct RNode *nd_head;
    ID nd_mid;
} rb_node_colon2_t;

typedef struct RNode_COLON3 {
    NODE node;

    ID nd_mid;
} rb_node_colon3_t;

/* RNode_DOT2, RNode_DOT3, RNode_FLIP2 and RNode_FLIP3 should be same structure */
typedef struct RNode_DOT2 {
    NODE node;

    struct RNode *nd_beg;
    struct RNode *nd_end;
} rb_node_dot2_t;

typedef struct RNode_DOT3 {
    NODE node;

    struct RNode *nd_beg;
    struct RNode *nd_end;
} rb_node_dot3_t;

typedef struct RNode_FLIP2 {
    NODE node;

    struct RNode *nd_beg;
    struct RNode *nd_end;
} rb_node_flip2_t;

typedef struct RNode_FLIP3 {
    NODE node;

    struct RNode *nd_beg;
    struct RNode *nd_end;
} rb_node_flip3_t;

typedef struct RNode_SELF {
    NODE node;

    long nd_state; /* Default 1. See NEW_SELF. */
} rb_node_self_t;

typedef struct RNode_NIL {
    NODE node;
} rb_node_nil_t;

typedef struct RNode_TRUE {
    NODE node;
} rb_node_true_t;

typedef struct RNode_FALSE {
    NODE node;
} rb_node_false_t;

typedef struct RNode_ERRINFO {
    NODE node;
} rb_node_errinfo_t;

typedef struct RNode_DEFINED {
    NODE node;

    struct RNode *nd_head;
} rb_node_defined_t;

typedef struct RNode_POSTEXE {
    NODE node;

    struct RNode *nd_body;
} rb_node_postexe_t;

typedef struct RNode_DSYM {
    NODE node;

    VALUE nd_lit;
    long nd_alen;
    struct RNode_LIST *nd_next;
} rb_node_dsym_t;

typedef struct RNode_ATTRASGN {
    NODE node;

    struct RNode *nd_recv;
    ID nd_mid;
    struct RNode *nd_args;
} rb_node_attrasgn_t;

typedef struct RNode_LAMBDA {
    NODE node;

    struct RNode *nd_body;
} rb_node_lambda_t;

typedef struct RNode_ARYPTN {
    NODE node;

    struct RNode *nd_pconst;
    NODE *pre_args;
    NODE *rest_arg;
    NODE *post_args;
} rb_node_aryptn_t;

typedef struct RNode_HSHPTN {
    NODE node;

    struct RNode *nd_pconst;
    struct RNode *nd_pkwargs;
    struct RNode *nd_pkwrestarg;
} rb_node_hshptn_t;

typedef struct RNode_FNDPTN {
    NODE node;

    struct RNode *nd_pconst;
    NODE *pre_rest_arg;
    NODE *args;
    NODE *post_rest_arg;
} rb_node_fndptn_t;

typedef struct RNode_ERROR {
    NODE node;
} rb_node_error_t;

#define RNODE(obj)  ((struct RNode *)(obj))

#define RNODE_SCOPE(node) ((struct RNode_SCOPE *)(node))
#define RNODE_BLOCK(node) ((struct RNode_BLOCK *)(node))
#define RNODE_IF(node) ((struct RNode_IF *)(node))
#define RNODE_UNLESS(node) ((struct RNode_UNLESS *)(node))
#define RNODE_CASE(node) ((struct RNode_CASE *)(node))
#define RNODE_CASE2(node) ((struct RNode_CASE2 *)(node))
#define RNODE_CASE3(node) ((struct RNode_CASE3 *)(node))
#define RNODE_WHEN(node) ((struct RNode_WHEN *)(node))
#define RNODE_IN(node) ((struct RNode_IN *)(node))
#define RNODE_WHILE(node) ((struct RNode_WHILE *)(node))
#define RNODE_UNTIL(node) ((struct RNode_UNTIL *)(node))
#define RNODE_ITER(node) ((struct RNode_ITER *)(node))
#define RNODE_FOR(node) ((struct RNode_FOR *)(node))
#define RNODE_FOR_MASGN(node) ((struct RNode_FOR_MASGN *)(node))
#define RNODE_BREAK(node) ((struct RNode_BREAK *)(node))
#define RNODE_NEXT(node) ((struct RNode_NEXT *)(node))
#define RNODE_REDO(node) ((struct RNode_REDO *)(node))
#define RNODE_RETRY(node) ((struct RNode_RETRY *)(node))
#define RNODE_BEGIN(node) ((struct RNode_BEGIN *)(node))
#define RNODE_RESCUE(node) ((struct RNode_RESCUE *)(node))
#define RNODE_RESBODY(node) ((struct RNode_RESBODY *)(node))
#define RNODE_ENSURE(node) ((struct RNode_ENSURE *)(node))
#define RNODE_AND(node) ((struct RNode_AND *)(node))
#define RNODE_OR(node) ((struct RNode_OR *)(node))
#define RNODE_MASGN(node) ((struct RNode_MASGN *)(node))
#define RNODE_LASGN(node) ((struct RNode_LASGN *)(node))
#define RNODE_DASGN(node) ((struct RNode_DASGN *)(node))
#define RNODE_GASGN(node) ((struct RNode_GASGN *)(node))
#define RNODE_IASGN(node) ((struct RNode_IASGN *)(node))
#define RNODE_CDECL(node) ((struct RNode_CDECL *)(node))
#define RNODE_CVASGN(node) ((struct RNode_CVASGN *)(node))
#define RNODE_OP_ASGN1(node) ((struct RNode_OP_ASGN1 *)(node))
#define RNODE_OP_ASGN2(node) ((struct RNode_OP_ASGN2 *)(node))
#define RNODE_OP_ASGN_AND(node) ((struct RNode_OP_ASGN_AND *)(node))
#define RNODE_OP_ASGN_OR(node) ((struct RNode_OP_ASGN_OR *)(node))
#define RNODE_OP_CDECL(node) ((struct RNode_OP_CDECL *)(node))
#define RNODE_CALL(node) ((struct RNode_CALL *)(node))
#define RNODE_OPCALL(node) ((struct RNode_OPCALL *)(node))
#define RNODE_FCALL(node) ((struct RNode_FCALL *)(node))
#define RNODE_VCALL(node) ((struct RNode_VCALL *)(node))
#define RNODE_QCALL(node) ((struct RNode_QCALL *)(node))
#define RNODE_SUPER(node) ((struct RNode_SUPER *)(node))
#define RNODE_ZSUPER(node) ((struct RNode_ZSUPER *)(node))
#define RNODE_LIST(node) ((struct RNode_LIST *)(node))
#define RNODE_ZLIST(node) ((struct RNode_ZLIST *)(node))
#define RNODE_HASH(node) ((struct RNode_HASH *)(node))
#define RNODE_RETURN(node) ((struct RNode_RETURN *)(node))
#define RNODE_YIELD(node) ((struct RNode_YIELD *)(node))
#define RNODE_LVAR(node) ((struct RNode_LVAR *)(node))
#define RNODE_DVAR(node) ((struct RNode_DVAR *)(node))
#define RNODE_GVAR(node) ((struct RNode_GVAR *)(node))
#define RNODE_IVAR(node) ((struct RNode_IVAR *)(node))
#define RNODE_CONST(node) ((struct RNode_CONST *)(node))
#define RNODE_CVAR(node) ((struct RNode_CVAR *)(node))
#define RNODE_NTH_REF(node) ((struct RNode_NTH_REF *)(node))
#define RNODE_BACK_REF(node) ((struct RNode_BACK_REF *)(node))
#define RNODE_MATCH(node) ((struct RNode_MATCH *)(node))
#define RNODE_MATCH2(node) ((struct RNode_MATCH2 *)(node))
#define RNODE_MATCH3(node) ((struct RNode_MATCH3 *)(node))
#define RNODE_LIT(node) ((struct RNode_LIT *)(node))
#define RNODE_STR(node) ((struct RNode_STR *)(node))
#define RNODE_DSTR(node) ((struct RNode_DSTR *)(node))
#define RNODE_XSTR(node) ((struct RNode_XSTR *)(node))
#define RNODE_DXSTR(node) ((struct RNode_DXSTR *)(node))
#define RNODE_EVSTR(node) ((struct RNode_EVSTR *)(node))
#define RNODE_DREGX(node) ((struct RNode_DREGX *)(node))
#define RNODE_ONCE(node) ((struct RNode_ONCE *)(node))
#define RNODE_ARGS(node) ((struct RNode_ARGS *)(node))
#define RNODE_ARGS_AUX(node) ((struct RNode_ARGS_AUX *)(node))
#define RNODE_OPT_ARG(node) ((struct RNode_OPT_ARG *)(node))
#define RNODE_KW_ARG(node) ((struct RNode_KW_ARG *)(node))
#define RNODE_POSTARG(node) ((struct RNode_POSTARG *)(node))
#define RNODE_ARGSCAT(node) ((struct RNode_ARGSCAT *)(node))
#define RNODE_ARGSPUSH(node) ((struct RNode_ARGSPUSH *)(node))
#define RNODE_SPLAT(node) ((struct RNode_SPLAT *)(node))
#define RNODE_BLOCK_PASS(node) ((struct RNode_BLOCK_PASS *)(node))
#define RNODE_DEFN(node) ((struct RNode_DEFN *)(node))
#define RNODE_DEFS(node) ((struct RNode_DEFS *)(node))
#define RNODE_ALIAS(node) ((struct RNode_ALIAS *)(node))
#define RNODE_VALIAS(node) ((struct RNode_VALIAS *)(node))
#define RNODE_UNDEF(node) ((struct RNode_UNDEF *)(node))
#define RNODE_CLASS(node) ((struct RNode_CLASS *)(node))
#define RNODE_MODULE(node) ((struct RNode_MODULE *)(node))
#define RNODE_SCLASS(node) ((struct RNode_SCLASS *)(node))
#define RNODE_COLON2(node) ((struct RNode_COLON2 *)(node))
#define RNODE_COLON3(node) ((struct RNode_COLON3 *)(node))
#define RNODE_DOT2(node) ((struct RNode_DOT2 *)(node))
#define RNODE_DOT3(node) ((struct RNode_DOT3 *)(node))
#define RNODE_FLIP2(node) ((struct RNode_FLIP2 *)(node))
#define RNODE_FLIP3(node) ((struct RNode_FLIP3 *)(node))
#define RNODE_SELF(node) ((struct RNode_SELF *)(node))
#define RNODE_NIL(node) ((struct RNode_NIL *)(node))
#define RNODE_TRUE(node) ((struct RNode_TRUE *)(node))
#define RNODE_FALSE(node) ((struct RNode_FALSE *)(node))
#define RNODE_ERRINFO(node) ((struct RNode_ERRINFO *)(node))
#define RNODE_DEFINED(node) ((struct RNode_DEFINED *)(node))
#define RNODE_POSTEXE(node) ((struct RNode_POSTEXE *)(node))
#define RNODE_DSYM(node) ((struct RNode_DSYM *)(node))
#define RNODE_ATTRASGN(node) ((struct RNode_ATTRASGN *)(node))
#define RNODE_LAMBDA(node) ((struct RNode_LAMBDA *)(node))
#define RNODE_ARYPTN(node) ((struct RNode_ARYPTN *)(node))
#define RNODE_HSHPTN(node) ((struct RNode_HSHPTN *)(node))
#define RNODE_FNDPTN(node) ((struct RNode_FNDPTN *)(node))

#ifdef RIPPER
typedef struct RNode_RIPPER {
    NODE node;

    ID nd_vid;
    VALUE nd_rval;
    VALUE nd_cval;
} rb_node_ripper_t;

typedef struct RNode_RIPPER_VALUES {
    NODE node;

    VALUE nd_val1;
    VALUE nd_val2;
    VALUE nd_val3;
} rb_node_ripper_values_t;

#define RNODE_RIPPER(node) ((struct RNode_RIPPER *)(node))
#define RNODE_RIPPER_VALUES(node) ((struct RNode_RIPPER_VALUES *)(node))
#endif

/* FL     : 0..4: T_TYPES, 5: KEEP_WB, 6: PROMOTED, 7: FINALIZE, 8: UNUSED, 9: UNUSED, 10: EXIVAR, 11: FREEZE */
/* NODE_FL: 0..4: T_TYPES, 5: KEEP_WB, 6: PROMOTED, 7: NODE_FL_NEWLINE,
 *          8..14: nd_type,
 *          15..: nd_line
 */
#define NODE_FL_NEWLINE              (((VALUE)1)<<7)

#define NODE_TYPESHIFT 8
#define NODE_TYPEMASK  (((VALUE)0x7f)<<NODE_TYPESHIFT)

#define nd_fl_newline(n) (n)->flags & NODE_FL_NEWLINE
#define nd_set_fl_newline(n) (n)->flags |= NODE_FL_NEWLINE
#define nd_unset_fl_newline(n) (n)->flags &= ~NODE_FL_NEWLINE

#define nd_type(n) ((int) ((RNODE(n)->flags & NODE_TYPEMASK)>>NODE_TYPESHIFT))
#define nd_set_type(n,t) \
    rb_node_set_type(n, t)
#define nd_init_type(n,t) \
    (n)->flags=(((n)->flags&~NODE_TYPEMASK)|((((unsigned long)(t))<<NODE_TYPESHIFT)&NODE_TYPEMASK))

typedef struct node_buffer_struct node_buffer_t;
/* T_IMEMO/ast */
typedef struct rb_ast_body_struct {
    const NODE *root;
    VALUE script_lines;
    // script_lines is either:
    // - a Fixnum that represents the line count of the original source, or
    // - an Array that contains the lines of the original source
    signed int frozen_string_literal:2; /* -1: not specified, 0: false, 1: true */
    signed int coverage_enabled:2; /* -1: not specified, 0: false, 1: true */
} rb_ast_body_t;
typedef struct rb_ast_struct {
    VALUE flags;
    node_buffer_t *node_buffer;
    rb_ast_body_t body;
} rb_ast_t;



/*
 * Parser Interface
 */


typedef struct parser_params rb_parser_t;
#ifndef INTERNAL_IMEMO_H
typedef struct rb_imemo_tmpbuf_struct rb_imemo_tmpbuf_t;
#endif

#ifdef UNIVERSAL_PARSER
typedef struct rb_parser_config_struct {
    /*
     * Reference counter.
     *   This is needed because both parser and ast refer
     *   same config pointer.
     *   We can remove this, once decuple parser and ast from Ruby GC.
     */
    int counter;

    /* Memory */
    void *(*malloc)(size_t size);
    void *(*calloc)(size_t number, size_t size);
    void *(*realloc)(void *ptr, size_t newsiz);
    void (*free)(void *ptr);
    void *(*alloc_n)(size_t nelems, size_t elemsiz);
    void *(*alloc)(size_t elemsiz);
    void *(*realloc_n)(void *ptr, size_t newelems, size_t newsiz);
    void *(*zalloc)(size_t elemsiz);
    void *(*rb_memmove)(void *dest, const void *src, size_t t, size_t n);
    void *(*nonempty_memcpy)(void *dest, const void *src, size_t t, size_t n);
    void *(*xmalloc_mul_add)(size_t x, size_t y, size_t z);

    /* imemo */
    rb_imemo_tmpbuf_t *(*tmpbuf_parser_heap)(void *buf, rb_imemo_tmpbuf_t *old_heap, size_t cnt);
    rb_ast_t *(*ast_new)(VALUE nb);

    // VALUE rb_suppress_tracing(VALUE (*func)(VALUE), VALUE arg);
    VALUE (*compile_callback)(VALUE (*func)(VALUE), VALUE arg);
    NODE *(*reg_named_capture_assign)(struct parser_params* p, VALUE regexp, const rb_code_location_t *loc);

    /* Object */
    VALUE (*obj_freeze)(VALUE obj);
    VALUE (*obj_hide)(VALUE obj);
    int (*obj_frozen)(VALUE obj);
    int (*type_p)(VALUE, int);
    void (*obj_freeze_raw)(VALUE obj);

    int (*fixnum_p)(VALUE);
    int (*symbol_p)(VALUE);

    /* Variable */
    VALUE (*attr_get)(VALUE obj, ID id);

    /* Array */
    VALUE (*ary_new)(void);
    VALUE (*ary_push)(VALUE ary, VALUE elem);
    VALUE (*ary_new_from_args)(long n, ...);
    VALUE (*ary_pop)(VALUE ary);
    VALUE (*ary_last)(int argc, const VALUE *argv, VALUE ary);
    VALUE (*ary_unshift)(VALUE ary, VALUE item);
    VALUE (*ary_new2)(long capa); // ary_new_capa
    VALUE (*ary_entry)(VALUE ary, long offset);
    VALUE (*ary_join)(VALUE ary, VALUE sep);
    VALUE (*ary_reverse)(VALUE ary);
    VALUE (*ary_clear)(VALUE ary);
    long (*array_len)(VALUE a);
    VALUE (*array_aref)(VALUE, long);

    /* Symbol */
    VALUE (*sym_intern_ascii_cstr)(const char *ptr);
    ID (*make_temporary_id)(size_t n);
    int (*is_local_id)(ID);
    int (*is_attrset_id)(ID);
    int (*is_global_name_punct)(const int c);
    int (*id_type)(ID id);
    ID (*id_attrset)(ID);
    ID (*intern)(const char *name);
    ID (*intern2)(const char *name, long len);
    ID (*intern3)(const char *name, long len, rb_encoding *enc);
    ID (*intern_str)(VALUE str);
    int (*is_notop_id)(ID);
    int (*enc_symname_type)(const char *name, long len, rb_encoding *enc, unsigned int allowed_attrset);
    VALUE (*str_intern)(VALUE str);
    const char *(*id2name)(ID id);
    VALUE (*id2str)(ID id);
    VALUE (*id2sym)(ID x);
    ID (*sym2id)(VALUE sym);

    /* String */
    RBIMPL_ATTR_FORMAT(RBIMPL_PRINTF_FORMAT, 2, 3)
    VALUE (*str_catf)(VALUE str, const char *format, ...);
    VALUE (*str_cat_cstr)(VALUE str, const char *ptr);
    VALUE (*str_subseq)(VALUE str, long beg, long len);
    VALUE (*str_dup)(VALUE str);
    VALUE (*str_new_frozen)(VALUE orig);
    VALUE (*str_buf_new)(long capa);
    VALUE (*str_buf_cat)(VALUE, const char*, long);
    void (*str_modify)(VALUE str);
    void (*str_set_len)(VALUE str, long len);
    VALUE (*str_cat)(VALUE str, const char *ptr, long len);
    VALUE (*str_resize)(VALUE str, long len);
    VALUE (*str_new)(const char *ptr, long len);
    VALUE (*str_new_cstr)(const char *ptr);
    VALUE (*fstring)(VALUE);
    int (*is_ascii_string)(VALUE str);
    VALUE (*enc_str_new)(const char *ptr, long len, rb_encoding *enc);
    VALUE (*enc_str_buf_cat)(VALUE str, const char *ptr, long len, rb_encoding *enc);
    VALUE (*str_buf_append)(VALUE str, VALUE str2);
    RBIMPL_ATTR_FORMAT(RBIMPL_PRINTF_FORMAT, 2, 0)
    VALUE (*str_vcatf)(VALUE str, const char *fmt, va_list ap);
    char *(*string_value_cstr)(volatile VALUE *ptr);
    RBIMPL_ATTR_FORMAT(RBIMPL_PRINTF_FORMAT, 1, 2)
    VALUE (*rb_sprintf)(const char *format, ...);
    char *(*rstring_ptr)(VALUE str);
    char *(*rstring_end)(VALUE str);
    long (*rstring_len)(VALUE str);
    VALUE (*filesystem_str_new_cstr)(const char *ptr);
    VALUE (*obj_as_string)(VALUE);

    /* Hash */
    VALUE (*hash_clear)(VALUE hash);
    VALUE (*hash_new)(void);
    VALUE (*hash_aset)(VALUE hash, VALUE key, VALUE val);
    VALUE (*hash_delete)(VALUE hash, VALUE key);
    VALUE (*hash_lookup)(VALUE hash, VALUE key);
    VALUE (*ident_hash_new)(void);

    /* Fixnum */
    VALUE (*int2fix)(long i);

    /* Bignum */
    void (*bignum_negate)(VALUE b);
    VALUE (*big_norm)(VALUE x);
    VALUE (*cstr_to_inum)(const char *str, int base, int badcheck);

    /* Float */
    VALUE (*float_new)(double d);
    double (*float_value)(VALUE v);

    /* Numeric */
    int (*num2int)(VALUE val);
    VALUE (*int_positive_pow)(long x, unsigned long y);
    VALUE (*int2num)(int v);
    long (*fix2long)(VALUE val);

    /* Rational */
    VALUE (*rational_new)(VALUE x, VALUE y);
    VALUE (*rational_raw1)(VALUE x);
    void (*rational_set_num)(VALUE r, VALUE n);
    VALUE (*rational_get_num)(VALUE obj);

    /* Complex */
    VALUE (*complex_raw)(VALUE x, VALUE y);
    void (*rcomplex_set_real)(VALUE cmp, VALUE r);
    void (*rcomplex_set_imag)(VALUE cmp, VALUE i);
    VALUE (*rcomplex_get_real)(VALUE obj);
    VALUE (*rcomplex_get_imag)(VALUE obj);

    /* IO */
    int (*stderr_tty_p)(void);
    void (*write_error_str)(VALUE mesg);
    VALUE (*default_rs)(void);
    VALUE (*io_write)(VALUE io, VALUE str);
    VALUE (*io_flush)(VALUE io);
    VALUE (*io_puts)(int argc, const VALUE *argv, VALUE out);
    VALUE (*io_gets_internal)(VALUE io);

    /* IO (Ractor) */
    VALUE (*debug_output_stdout)(void);
    VALUE (*debug_output_stderr)(void);

    /* Encoding */
    int (*is_usascii_enc)(rb_encoding *enc);
    int (*enc_isalnum)(OnigCodePoint c, rb_encoding *enc);
    int (*enc_precise_mbclen)(const char *p, const char *e, rb_encoding *enc);
    int (*mbclen_charfound_p)(int len);
    const char *(*enc_name)(rb_encoding *enc);
    char *(*enc_prev_char)(const char *s, const char *p, const char *e, rb_encoding *enc);
    rb_encoding* (*enc_get)(VALUE obj);
    int (*enc_asciicompat)(rb_encoding *enc);
    rb_encoding *(*utf8_encoding)(void);
    VALUE (*enc_associate)(VALUE obj, rb_encoding *enc);
    rb_encoding *(*ascii8bit_encoding)(void);
    int (*enc_codelen)(int c, rb_encoding *enc);
    int (*enc_mbcput)(unsigned int c, void *buf, rb_encoding *enc);
    int (*char_to_option_kcode)(int c, int *option, int *kcode);
    int (*ascii8bit_encindex)(void);
    int (*enc_find_index)(const char *name);
    rb_encoding *(*enc_from_index)(int idx);
    VALUE (*enc_associate_index)(VALUE obj, int encindex);
    int (*enc_isspace)(OnigCodePoint c, rb_encoding *enc);
    int enc_coderange_7bit;
    int enc_coderange_unknown;
    rb_encoding *(*enc_compatible)(VALUE str1, VALUE str2);
    VALUE (*enc_from_encoding)(rb_encoding *enc);
    int (*encoding_get)(VALUE obj);
    void (*encoding_set)(VALUE obj, int encindex);
    int (*encoding_is_ascii8bit)(VALUE obj);
    rb_encoding *(*usascii_encoding)(void);

    /* Ractor */
    VALUE (*ractor_make_shareable)(VALUE obj);

    /* Compile */
    // int rb_local_defined(ID id, const rb_iseq_t *iseq);
    int (*local_defined)(ID, const void*);
    // int rb_dvar_defined(ID id, const rb_iseq_t *iseq);
    int (*dvar_defined)(ID, const void*);

    /* Compile (parse.y) */
    int (*literal_cmp)(VALUE val, VALUE lit);
    parser_st_index_t (*literal_hash)(VALUE a);

    /* Error (Exception) */
    const char *(*builtin_class_name)(VALUE x);
    RBIMPL_ATTR_FORMAT(RBIMPL_PRINTF_FORMAT, 6, 0)
    VALUE (*syntax_error_append)(VALUE, VALUE, int, int, rb_encoding*, const char*, va_list);
    RBIMPL_ATTR_FORMAT(RBIMPL_PRINTF_FORMAT, 2, 3)
    void (*raise)(VALUE exc, const char *fmt, ...);
    VALUE (*syntax_error_new)(void);

    /* Eval */
    VALUE (*errinfo)(void);
    void (*set_errinfo)(VALUE err);
    void (*exc_raise)(VALUE mesg);
    VALUE (*make_exception)(int argc, const VALUE *argv);

    /* GC */
    void (*sized_xfree)(void *x, size_t size);
    void *(*sized_realloc_n)(void *ptr, size_t new_count, size_t element_size, size_t old_count);
    VALUE (*obj_write)(VALUE, VALUE *, VALUE);
    VALUE (*obj_written)(VALUE, VALUE, VALUE);
    void (*gc_register_mark_object)(VALUE object);
    void (*gc_guard)(VALUE);
    void (*gc_mark)(VALUE);
    void (*gc_mark_movable)(VALUE ptr);
    VALUE (*gc_location)(VALUE value);

    /* Re */
    VALUE (*reg_compile)(VALUE str, int options, const char *sourcefile, int sourceline);
    VALUE (*reg_check_preprocess)(VALUE str);
    int (*memcicmp)(const void *x, const void *y, long len);

    /* Error */
    void (*compile_warn)(const char *file, int line, const char *fmt, ...);
    void (*compile_warning)(const char *file, int line, const char *fmt, ...);
    void (*bug)(const char *fmt, ...);
    void (*fatal)(const char *fmt, ...);
    VALUE (*verbose)(void);

    /* VM */
    VALUE (*make_backtrace)(void);

    /* Util */
    unsigned long (*scan_hex)(const char *start, size_t len, size_t *retlen);
    unsigned long (*scan_oct)(const char *start, size_t len, size_t *retlen);
    unsigned long (*scan_digits)(const char *str, ssize_t len, int base, size_t *retlen, int *overflow);
    double (*strtod)(const char *s00, char **se);

    /* Misc */
    VALUE (*rbool)(VALUE);
    int (*undef_p)(VALUE);
    int (*rtest)(VALUE obj);
    int (*nil_p)(VALUE obj);
    int (*flonum_p)(VALUE obj);
    VALUE qnil;
    VALUE qtrue;
    VALUE qfalse;
    VALUE qundef;
    VALUE eArgError;
    VALUE mRubyVMFrozenCore;
    int (*long2int)(long);
    int (*special_const_p)(VALUE);
    int (*builtin_type)(VALUE);

    VALUE (*node_case_when_optimizable_literal)(const NODE *const node);

    /* For Ripper */
    VALUE (*static_id2sym)(ID id);
    long (*str_coderange_scan_restartable)(const char *s, const char *e, rb_encoding *enc, int *cr);
} rb_parser_config_t;

#undef rb_encoding
#undef OnigCodePoint
#endif /* UNIVERSAL_PARSER */

RUBY_SYMBOL_EXPORT_BEGIN
void rb_ruby_parser_free(void *ptr);
rb_ast_t* rb_ruby_parser_compile_string(rb_parser_t *p, const char *f, VALUE s, int line);

#ifdef UNIVERSAL_PARSER
rb_parser_config_t *rb_ruby_parser_config_new(void *(*malloc)(size_t size));
void rb_ruby_parser_config_free(rb_parser_config_t *config);
rb_parser_t *rb_ruby_parser_allocate(rb_parser_config_t *config);
rb_parser_t *rb_ruby_parser_new(rb_parser_config_t *config);
#endif
RUBY_SYMBOL_EXPORT_END

#endif /* RUBY_RUBYPARSER_H */
