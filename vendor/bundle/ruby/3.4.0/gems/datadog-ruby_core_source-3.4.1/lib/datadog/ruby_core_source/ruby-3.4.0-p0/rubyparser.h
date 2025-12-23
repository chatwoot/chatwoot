#ifndef RUBY_RUBYPARSER_H
#define RUBY_RUBYPARSER_H 1
/*
 * This is a header file for librubyparser interface
 */

#include <stdarg.h> /* for va_list */
#include <assert.h>

#ifdef UNIVERSAL_PARSER

#define rb_encoding const void
#define OnigCodePoint unsigned int
#include "parser_st.h"
#ifndef RUBY_RUBY_H
#include "parser_value.h"
#endif

#else

#include "ruby/encoding.h"

#endif

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

#if defined(__GNUC__)
# if defined(__MINGW_PRINTF_FORMAT)
#   define RUBYPARSER_ATTRIBUTE_FORMAT(string_index, argument_index) __attribute__((format(__MINGW_PRINTF_FORMAT, string_index, argument_index)))
# else
#   define RUBYPARSER_ATTRIBUTE_FORMAT(string_index, argument_index) __attribute__((format(printf, string_index, argument_index)))
# endif
#elif defined(__clang__)
# define RUBYPARSER_ATTRIBUTE_FORMAT(string_index, argument_index) __attribute__((__format__(__printf__, string_index, argument_index)))
#else
# define RUBYPARSER_ATTRIBUTE_FORMAT(string_index, argument_index)
#endif

/*
 * Parser String
 */
enum rb_parser_string_coderange_type {
    /** The object's coderange is unclear yet. */
    RB_PARSER_ENC_CODERANGE_UNKNOWN  = 0,
    RB_PARSER_ENC_CODERANGE_7BIT     = 1,
    RB_PARSER_ENC_CODERANGE_VALID    = 2,
    RB_PARSER_ENC_CODERANGE_BROKEN   = 3
};

typedef struct rb_parser_string {
    enum rb_parser_string_coderange_type coderange;
    rb_encoding *enc;
    /* Length of the string, not including terminating NUL character. */
    long len;
    /* Pointer to the contents of the string. */
    char *ptr;
} rb_parser_string_t;

enum rb_parser_shareability {
    rb_parser_shareable_none,
    rb_parser_shareable_literal,
    rb_parser_shareable_copy,
    rb_parser_shareable_everything,
};

typedef void* rb_parser_input_data;

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
    NODE_INTEGER,
    NODE_FLOAT,
    NODE_RATIONAL,
    NODE_IMAGINARY,
    NODE_STR,
    NODE_DSTR,
    NODE_XSTR,
    NODE_DXSTR,
    NODE_EVSTR,
    NODE_REGX,
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
    NODE_SYM,
    NODE_DSYM,
    NODE_ATTRASGN,
    NODE_LAMBDA,
    NODE_ARYPTN,
    NODE_HSHPTN,
    NODE_FNDPTN,
    NODE_ERROR,
    NODE_LINE,
    NODE_FILE,
    NODE_ENCODING,
    NODE_LAST
};

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
#define YYLTYPE rb_code_location_t
#define YYLTYPE_IS_DECLARED 1

typedef struct rb_parser_ast_token {
    int id;
    const char *type_name;
    rb_parser_string_t *str;
    rb_code_location_t loc;
} rb_parser_ast_token_t;

/*
 * Array-like object for parser
 */
typedef void* rb_parser_ary_data;

enum rb_parser_ary_data_type {
    PARSER_ARY_DATA_AST_TOKEN = 1,
    PARSER_ARY_DATA_SCRIPT_LINE,
    PARSER_ARY_DATA_NODE
};

typedef struct rb_parser_ary {
    enum rb_parser_ary_data_type data_type;
    rb_parser_ary_data *data;
    long len;  // current size
    long capa; // capacity
} rb_parser_ary_t;

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
    rb_code_location_t keyword_loc;
    rb_code_location_t then_keyword_loc;
    rb_code_location_t end_keyword_loc;
} rb_node_unless_t;

typedef struct RNode_CASE {
    NODE node;

    struct RNode *nd_head;
    struct RNode *nd_body;
    rb_code_location_t case_keyword_loc;
    rb_code_location_t end_keyword_loc;
} rb_node_case_t;

typedef struct RNode_CASE2 {
    NODE node;

    struct RNode *nd_head;
    struct RNode *nd_body;
    rb_code_location_t case_keyword_loc;
    rb_code_location_t end_keyword_loc;
} rb_node_case2_t;

typedef struct RNode_CASE3 {
    NODE node;

    struct RNode *nd_head;
    struct RNode *nd_body;
    rb_code_location_t case_keyword_loc;
    rb_code_location_t end_keyword_loc;
} rb_node_case3_t;

typedef struct RNode_WHEN {
    NODE node;

    struct RNode *nd_head;
    struct RNode *nd_body;
    struct RNode *nd_next;
    rb_code_location_t keyword_loc;
    rb_code_location_t then_keyword_loc;
} rb_node_when_t;

typedef struct RNode_IN {
    NODE node;

    struct RNode *nd_head;
    struct RNode *nd_body;
    struct RNode *nd_next;
} rb_node_in_t;

typedef struct RNode_LOOP {
    NODE node;

    struct RNode *nd_cond;
    struct RNode *nd_body;
    long nd_state;
    rb_code_location_t keyword_loc;
    rb_code_location_t closing_loc;
} rb_node_while_t, rb_node_until_t;

typedef struct RNode_ITER {
    NODE node;

    struct RNode *nd_body;
    struct RNode *nd_iter;
} rb_node_iter_t, rb_node_for_t;

typedef struct RNode_FOR_MASGN {
    NODE node;

    struct RNode *nd_var;
} rb_node_for_masgn_t;

typedef struct RNode_EXITS {
    NODE node;

    struct RNode *nd_chain;
    struct RNode *nd_stts;
    rb_code_location_t keyword_loc;
} rb_node_exits_t, rb_node_break_t, rb_node_next_t, rb_node_redo_t;

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

    struct RNode *nd_args;
    struct RNode *nd_exc_var;
    struct RNode *nd_body;
    struct RNode *nd_next;
} rb_node_resbody_t;

typedef struct RNode_ENSURE {
    NODE node;

    struct RNode *nd_head;
    struct RNode *nd_ensr;
} rb_node_ensure_t;

typedef struct {
    NODE node;

    struct RNode *nd_1st;
    struct RNode *nd_2nd;
    rb_code_location_t operator_loc;
} rb_node_and_t, rb_node_or_t;

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
    enum rb_parser_shareability shareability;
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
    rb_code_location_t call_operator_loc;
    rb_code_location_t opening_loc;
    rb_code_location_t closing_loc;
    rb_code_location_t binary_operator_loc;
} rb_node_op_asgn1_t;

typedef struct RNode_OP_ASGN2 {
    NODE node;

    struct RNode *nd_recv;
    struct RNode *nd_value;
    ID nd_vid;
    ID nd_mid;
    bool nd_aid;
    rb_code_location_t call_operator_loc;
    rb_code_location_t message_loc;
    rb_code_location_t binary_operator_loc;
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
    enum rb_parser_shareability shareability;
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

typedef struct RNode_HASH {
    NODE node;

    struct RNode *nd_head;
    long nd_brace;
} rb_node_hash_t;

typedef struct RNode_RETURN {
    NODE node;

    struct RNode *nd_stts;
    rb_code_location_t keyword_loc;
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

typedef struct RNode_INTEGER {
    NODE node;

    char *val;
    int minus;
    int base;
} rb_node_integer_t;

typedef struct RNode_FLOAT {
    NODE node;

    char *val;
    int minus;
} rb_node_float_t;

typedef struct RNode_RATIONAL {
    NODE node;

    char *val;
    int minus;
    int base;
    int seen_point;
} rb_node_rational_t;

enum rb_numeric_type {
    integer_literal,
    float_literal,
    rational_literal
};

typedef struct RNode_IMAGINARY {
    NODE node;

    char *val;
    int minus;
    int base;
    int seen_point;
    enum rb_numeric_type type;
} rb_node_imaginary_t;

typedef struct RNode_STR {
    NODE node;

    struct rb_parser_string *string;
} rb_node_str_t;

/* NODE_DSTR, NODE_DXSTR, NODE_DREGX, NODE_DSYM */
typedef struct RNode_DSTR {
    NODE node;

    struct rb_parser_string *string;
    union {
        long nd_alen;
        long nd_cflag;
        struct RNode *nd_end; /* Second dstr node has this structure. See also RNode_LIST */
    } as;
    struct RNode_LIST *nd_next;
} rb_node_dstr_t;

typedef rb_node_str_t rb_node_xstr_t;

typedef rb_node_dstr_t rb_node_dxstr_t;

typedef struct RNode_EVSTR {
    NODE node;

    struct RNode *nd_body;
} rb_node_evstr_t;

typedef struct RNode_REGX {     /* also RNode_MATCH */
    NODE node;

    struct rb_parser_string *string;
    int options;
} rb_node_regx_t, rb_node_match_t;

typedef rb_node_dstr_t rb_node_dregx_t;

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
    int nd_plen;
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
    rb_code_location_t operator_loc;
} rb_node_splat_t;

typedef struct RNode_BLOCK_PASS {
    NODE node;

    struct RNode *nd_head;
    struct RNode *nd_body;
    unsigned int forwarding: 1;
    rb_code_location_t operator_loc;
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
    rb_code_location_t keyword_loc;
} rb_node_alias_t;

typedef struct RNode_VALIAS {
    NODE node;

    ID nd_alias;
    ID nd_orig;
    rb_code_location_t keyword_loc;
} rb_node_valias_t;

typedef struct RNode_UNDEF {
    NODE node;

    rb_parser_ary_t *nd_undefs;
    rb_code_location_t keyword_loc;
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

/* NODE_DOT2, NODE_DOT3, NODE_FLIP2, NODE_FLIP3 */
typedef struct RNode_DOTS {
    NODE node;

    struct RNode *nd_beg;
    struct RNode *nd_end;
} rb_node_dot2_t, rb_node_dot3_t, rb_node_flip2_t, rb_node_flip3_t;

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

typedef struct RNode_SYM {
    NODE node;

    struct rb_parser_string *string;
} rb_node_sym_t;

typedef rb_node_dstr_t rb_node_dsym_t;

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

typedef struct RNode_LINE {
    NODE node;
} rb_node_line_t;

typedef struct RNode_FILE {
    NODE node;

    struct rb_parser_string *path;
} rb_node_file_t;

typedef struct RNode_ENCODING {
    NODE node;
    rb_encoding *enc;
} rb_node_encoding_t;

typedef struct RNode_ERROR {
    NODE node;
} rb_node_error_t;

#define RNODE(obj)  ((NODE *)(obj))

#define RNODE_SCOPE(node) ((rb_node_scope_t *)(node))
#define RNODE_BLOCK(node) ((rb_node_block_t *)(node))
#define RNODE_IF(node) ((rb_node_if_t *)(node))
#define RNODE_UNLESS(node) ((rb_node_unless_t *)(node))
#define RNODE_CASE(node) ((rb_node_case_t *)(node))
#define RNODE_CASE2(node) ((rb_node_case2_t *)(node))
#define RNODE_CASE3(node) ((rb_node_case3_t *)(node))
#define RNODE_WHEN(node) ((rb_node_when_t *)(node))
#define RNODE_IN(node) ((rb_node_in_t *)(node))
#define RNODE_WHILE(node) ((rb_node_while_t *)(node))
#define RNODE_UNTIL(node) ((rb_node_until_t *)(node))
#define RNODE_ITER(node) ((rb_node_iter_t *)(node))
#define RNODE_FOR(node) ((rb_node_for_t *)(node))
#define RNODE_FOR_MASGN(node) ((rb_node_for_masgn_t *)(node))
#define RNODE_BREAK(node) ((rb_node_break_t *)(node))
#define RNODE_NEXT(node) ((rb_node_next_t *)(node))
#define RNODE_REDO(node) ((rb_node_redo_t *)(node))
#define RNODE_RETRY(node) ((rb_node_retry_t *)(node))
#define RNODE_BEGIN(node) ((rb_node_begin_t *)(node))
#define RNODE_RESCUE(node) ((rb_node_rescue_t *)(node))
#define RNODE_RESBODY(node) ((rb_node_resbody_t *)(node))
#define RNODE_ENSURE(node) ((rb_node_ensure_t *)(node))
#define RNODE_AND(node) ((rb_node_and_t *)(node))
#define RNODE_OR(node) ((rb_node_or_t *)(node))
#define RNODE_MASGN(node) ((rb_node_masgn_t *)(node))
#define RNODE_LASGN(node) ((rb_node_lasgn_t *)(node))
#define RNODE_DASGN(node) ((rb_node_dasgn_t *)(node))
#define RNODE_GASGN(node) ((rb_node_gasgn_t *)(node))
#define RNODE_IASGN(node) ((rb_node_iasgn_t *)(node))
#define RNODE_CDECL(node) ((rb_node_cdecl_t *)(node))
#define RNODE_CVASGN(node) ((rb_node_cvasgn_t *)(node))
#define RNODE_OP_ASGN1(node) ((rb_node_op_asgn1_t *)(node))
#define RNODE_OP_ASGN2(node) ((rb_node_op_asgn2_t *)(node))
#define RNODE_OP_ASGN_AND(node) ((rb_node_op_asgn_and_t *)(node))
#define RNODE_OP_ASGN_OR(node) ((rb_node_op_asgn_or_t *)(node))
#define RNODE_OP_CDECL(node) ((rb_node_op_cdecl_t *)(node))
#define RNODE_CALL(node) ((rb_node_call_t *)(node))
#define RNODE_OPCALL(node) ((rb_node_opcall_t *)(node))
#define RNODE_FCALL(node) ((rb_node_fcall_t *)(node))
#define RNODE_VCALL(node) ((rb_node_vcall_t *)(node))
#define RNODE_QCALL(node) ((rb_node_qcall_t *)(node))
#define RNODE_SUPER(node) ((rb_node_super_t *)(node))
#define RNODE_ZSUPER(node) ((rb_node_zsuper_t *)(node))
#define RNODE_LIST(node) ((rb_node_list_t *)(node))
#define RNODE_ZLIST(node) ((rb_node_zlist_t *)(node))
#define RNODE_HASH(node) ((rb_node_hash_t *)(node))
#define RNODE_RETURN(node) ((rb_node_return_t *)(node))
#define RNODE_YIELD(node) ((rb_node_yield_t *)(node))
#define RNODE_LVAR(node) ((rb_node_lvar_t *)(node))
#define RNODE_DVAR(node) ((rb_node_dvar_t *)(node))
#define RNODE_GVAR(node) ((rb_node_gvar_t *)(node))
#define RNODE_IVAR(node) ((rb_node_ivar_t *)(node))
#define RNODE_CONST(node) ((rb_node_const_t *)(node))
#define RNODE_CVAR(node) ((rb_node_cvar_t *)(node))
#define RNODE_NTH_REF(node) ((rb_node_nth_ref_t *)(node))
#define RNODE_BACK_REF(node) ((rb_node_back_ref_t *)(node))
#define RNODE_MATCH(node) ((rb_node_match_t *)(node))
#define RNODE_MATCH2(node) ((rb_node_match2_t *)(node))
#define RNODE_MATCH3(node) ((rb_node_match3_t *)(node))
#define RNODE_INTEGER(node) ((rb_node_integer_t *)(node))
#define RNODE_FLOAT(node) ((rb_node_float_t *)(node))
#define RNODE_RATIONAL(node) ((rb_node_rational_t *)(node))
#define RNODE_IMAGINARY(node) ((rb_node_imaginary_t *)(node))
#define RNODE_STR(node) ((rb_node_str_t *)(node))
#define RNODE_DSTR(node) ((rb_node_dstr_t *)(node))
#define RNODE_XSTR(node) ((rb_node_xstr_t *)(node))
#define RNODE_DXSTR(node) ((rb_node_dxstr_t *)(node))
#define RNODE_EVSTR(node) ((rb_node_evstr_t *)(node))
#define RNODE_REGX(node) ((rb_node_regx_t *)(node))
#define RNODE_DREGX(node) ((rb_node_dregx_t *)(node))
#define RNODE_ONCE(node) ((rb_node_once_t *)(node))
#define RNODE_ARGS(node) ((rb_node_args_t *)(node))
#define RNODE_ARGS_AUX(node) ((rb_node_args_aux_t *)(node))
#define RNODE_OPT_ARG(node) ((rb_node_opt_arg_t *)(node))
#define RNODE_KW_ARG(node) ((rb_node_kw_arg_t *)(node))
#define RNODE_POSTARG(node) ((rb_node_postarg_t *)(node))
#define RNODE_ARGSCAT(node) ((rb_node_argscat_t *)(node))
#define RNODE_ARGSPUSH(node) ((rb_node_argspush_t *)(node))
#define RNODE_SPLAT(node) ((rb_node_splat_t *)(node))
#define RNODE_BLOCK_PASS(node) ((rb_node_block_pass_t *)(node))
#define RNODE_DEFN(node) ((rb_node_defn_t *)(node))
#define RNODE_DEFS(node) ((rb_node_defs_t *)(node))
#define RNODE_ALIAS(node) ((rb_node_alias_t *)(node))
#define RNODE_VALIAS(node) ((rb_node_valias_t *)(node))
#define RNODE_UNDEF(node) ((rb_node_undef_t *)(node))
#define RNODE_CLASS(node) ((rb_node_class_t *)(node))
#define RNODE_MODULE(node) ((rb_node_module_t *)(node))
#define RNODE_SCLASS(node) ((rb_node_sclass_t *)(node))
#define RNODE_COLON2(node) ((rb_node_colon2_t *)(node))
#define RNODE_COLON3(node) ((rb_node_colon3_t *)(node))
#define RNODE_DOT2(node) ((rb_node_dot2_t *)(node))
#define RNODE_DOT3(node) ((rb_node_dot3_t *)(node))
#define RNODE_FLIP2(node) ((rb_node_flip2_t *)(node))
#define RNODE_FLIP3(node) ((rb_node_flip3_t *)(node))
#define RNODE_SELF(node) ((rb_node_self_t *)(node))
#define RNODE_NIL(node) ((rb_node_nil_t *)(node))
#define RNODE_TRUE(node) ((rb_node_true_t *)(node))
#define RNODE_FALSE(node) ((rb_node_false_t *)(node))
#define RNODE_ERRINFO(node) ((rb_node_errinfo_t *)(node))
#define RNODE_DEFINED(node) ((rb_node_defined_t *)(node))
#define RNODE_POSTEXE(node) ((rb_node_postexe_t *)(node))
#define RNODE_SYM(node) ((rb_node_sym_t *)(node))
#define RNODE_DSYM(node) ((rb_node_dsym_t *)(node))
#define RNODE_ATTRASGN(node) ((rb_node_attrasgn_t *)(node))
#define RNODE_LAMBDA(node) ((rb_node_lambda_t *)(node))
#define RNODE_ARYPTN(node) ((rb_node_aryptn_t *)(node))
#define RNODE_HSHPTN(node) ((rb_node_hshptn_t *)(node))
#define RNODE_FNDPTN(node) ((rb_node_fndptn_t *)(node))
#define RNODE_LINE(node) ((rb_node_line_t *)(node))
#define RNODE_FILE(node) ((rb_node_file_t *)(node))
#define RNODE_ENCODING(node) ((rb_node_encoding_t *)(node))

/* FL     : 0..4: T_TYPES, 5: KEEP_WB, 6: PROMOTED, 7: FINALIZE, 8: UNUSED, 9: UNUSED, 10: EXIVAR, 11: FREEZE */
/* NODE_FL: 0..4: UNUSED,  5: UNUSED,  6: UNUSED,   7: NODE_FL_NEWLINE,
 *          8..14: nd_type,
 *          15..: nd_line
 */
#define NODE_FL_NEWLINE              (((VALUE)1)<<7)

#define NODE_TYPESHIFT 8
#define NODE_TYPEMASK  (((VALUE)0x7f)<<NODE_TYPESHIFT)

#define nd_fl_newline(n) ((n)->flags & NODE_FL_NEWLINE)
#define nd_set_fl_newline(n) ((n)->flags |= NODE_FL_NEWLINE)
#define nd_unset_fl_newline(n) ((n)->flags &= ~NODE_FL_NEWLINE)

#define nd_type(n) ((int) ((RNODE(n)->flags & NODE_TYPEMASK)>>NODE_TYPESHIFT))
#define nd_set_type(n,t) \
    rb_node_set_type(n, t)
#define nd_init_type(n,t) \
    (n)->flags=(((n)->flags&~NODE_TYPEMASK)|((((unsigned long)(t))<<NODE_TYPESHIFT)&NODE_TYPEMASK))

typedef struct node_buffer_struct node_buffer_t;

#ifdef UNIVERSAL_PARSER
typedef struct rb_parser_config_struct rb_parser_config_t;
#endif

typedef struct rb_ast_body_struct {
    const NODE *root;
    rb_parser_ary_t *script_lines;
    int line_count;
    signed int frozen_string_literal:2; /* -1: not specified, 0: false, 1: true */
    signed int coverage_enabled:2; /* -1: not specified, 0: false, 1: true */
} rb_ast_body_t;
typedef struct rb_ast_struct {
    node_buffer_t *node_buffer;
    rb_ast_body_t body;
#ifdef UNIVERSAL_PARSER
    const rb_parser_config_t *config;
#endif
} rb_ast_t;



/*
 * Parser Interface
 */


typedef struct parser_params rb_parser_t;
#ifndef INTERNAL_IMEMO_H
typedef struct rb_imemo_tmpbuf_struct rb_imemo_tmpbuf_t;
#endif

typedef NODE *(*rb_parser_assignable_func)(struct parser_params *p, ID id, NODE *val, const rb_code_location_t *loc);

#ifdef UNIVERSAL_PARSER
typedef struct rb_parser_config_struct {
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

    // VALUE rb_suppress_tracing(VALUE (*func)(VALUE), VALUE arg);
    VALUE (*compile_callback)(VALUE (*func)(VALUE), VALUE arg);
    NODE *(*reg_named_capture_assign)(struct parser_params* p, VALUE regexp, const rb_code_location_t *loc, rb_parser_assignable_func assignable);

    /* Variable */
    VALUE (*attr_get)(VALUE obj, ID id);

    /* Array */
    VALUE (*ary_push)(VALUE ary, VALUE elem);
    VALUE (*ary_new_from_args)(long n, ...);
    VALUE (*ary_unshift)(VALUE ary, VALUE item);

    /* Symbol */
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
    const char *(*id2name)(ID id);
    VALUE (*id2str)(ID id);
    VALUE (*id2sym)(ID x);
    ID (*sym2id)(VALUE sym);

    /* String */
    RBIMPL_ATTR_FORMAT(RBIMPL_PRINTF_FORMAT, 2, 3)
    VALUE (*str_catf)(VALUE str, const char *format, ...);
    VALUE (*str_cat_cstr)(VALUE str, const char *ptr);
    VALUE (*str_resize)(VALUE str, long len);
    VALUE (*str_new)(const char *ptr, long len);
    VALUE (*str_new_cstr)(const char *ptr);
    VALUE (*str_to_interned_str)(VALUE);
    VALUE (*enc_str_new)(const char *ptr, long len, rb_encoding *enc);
    RBIMPL_ATTR_FORMAT(RBIMPL_PRINTF_FORMAT, 2, 0)
    VALUE (*str_vcatf)(VALUE str, const char *fmt, va_list ap);
    RBIMPL_ATTR_FORMAT(RBIMPL_PRINTF_FORMAT, 1, 2)
    VALUE (*rb_sprintf)(const char *format, ...);
    char *(*rstring_ptr)(VALUE str);
    long (*rstring_len)(VALUE str);
    VALUE (*obj_as_string)(VALUE);

    /* Numeric */
    VALUE (*int2num)(int v);

    /* IO */
    int (*stderr_tty_p)(void);
    void (*write_error_str)(VALUE mesg);
    VALUE (*io_write)(VALUE io, VALUE str);
    VALUE (*io_flush)(VALUE io);
    VALUE (*io_puts)(int argc, const VALUE *argv, VALUE out);

    /* IO (Ractor) */
    VALUE (*debug_output_stdout)(void);
    VALUE (*debug_output_stderr)(void);

    /* Encoding */
    int (*is_usascii_enc)(rb_encoding *enc);
    int (*enc_isalnum)(OnigCodePoint c, rb_encoding *enc);
    int (*enc_precise_mbclen)(const char *p, const char *e, rb_encoding *enc);
    int (*mbclen_charfound_p)(int len);
    int (*mbclen_charfound_len)(int len);
    const char *(*enc_name)(rb_encoding *enc);
    char *(*enc_prev_char)(const char *s, const char *p, const char *e, rb_encoding *enc);
    rb_encoding* (*enc_get)(VALUE obj);
    int (*enc_asciicompat)(rb_encoding *enc);
    rb_encoding *(*utf8_encoding)(void);
    VALUE (*enc_associate)(VALUE obj, rb_encoding *enc);
    rb_encoding *(*ascii8bit_encoding)(void);
    int (*enc_codelen)(int c, rb_encoding *enc);
    int (*enc_mbcput)(unsigned int c, void *buf, rb_encoding *enc);
    int (*enc_find_index)(const char *name);
    rb_encoding *(*enc_from_index)(int idx);
    int (*enc_isspace)(OnigCodePoint c, rb_encoding *enc);
    rb_encoding *(*usascii_encoding)(void);
    int (*enc_mbminlen)(rb_encoding *enc);
    bool (*enc_isascii)(OnigCodePoint c, rb_encoding *enc);
    OnigCodePoint (*enc_mbc_to_codepoint)(const char *p, const char *e, rb_encoding *enc);

    /* Compile */
    // int rb_local_defined(ID id, const rb_iseq_t *iseq);
    int (*local_defined)(ID, const void*);
    // int rb_dvar_defined(ID id, const rb_iseq_t *iseq);
    int (*dvar_defined)(ID, const void*);

    /* Error (Exception) */
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
    void (*gc_guard)(VALUE);
    void (*gc_mark)(VALUE);

    /* Re */
    VALUE (*reg_compile)(VALUE str, int options, const char *sourcefile, int sourceline);
    VALUE (*reg_check_preprocess)(VALUE str);
    int (*memcicmp)(const void *x, const void *y, long len);

    /* Error */
    void (*compile_warn)(const char *file, int line, const char *fmt, ...) RUBYPARSER_ATTRIBUTE_FORMAT(3, 4);
    void (*compile_warning)(const char *file, int line, const char *fmt, ...) RUBYPARSER_ATTRIBUTE_FORMAT(3, 4);
    void (*bug)(const char *fmt, ...) RUBYPARSER_ATTRIBUTE_FORMAT(1, 2);
    void (*fatal)(const char *fmt, ...) RUBYPARSER_ATTRIBUTE_FORMAT(1, 2);
    VALUE (*verbose)(void);
    int *(*errno_ptr)(void);

    /* VM */
    VALUE (*make_backtrace)(void);

    /* Util */
    unsigned long (*scan_hex)(const char *start, size_t len, size_t *retlen);
    unsigned long (*scan_oct)(const char *start, size_t len, size_t *retlen);
    unsigned long (*scan_digits)(const char *str, ssize_t len, int base, size_t *retlen, int *overflow);
    double (*strtod)(const char *s00, char **se);

    /* Misc */
    int (*rtest)(VALUE obj);
    int (*nil_p)(VALUE obj);
    VALUE qnil;
    VALUE qfalse;
    VALUE (*eArgError)(void);
    int (*long2int)(long);

    /* For Ripper */
    int enc_coderange_7bit;
    int enc_coderange_unknown;
    VALUE (*static_id2sym)(ID id);
    long (*str_coderange_scan_restartable)(const char *s, const char *e, rb_encoding *enc, int *cr);
} rb_parser_config_t;

#undef rb_encoding
#undef OnigCodePoint
#endif /* UNIVERSAL_PARSER */

RUBY_SYMBOL_EXPORT_BEGIN
void rb_ruby_parser_free(void *ptr);

#ifdef UNIVERSAL_PARSER
rb_parser_t *rb_ruby_parser_allocate(const rb_parser_config_t *config);
rb_parser_t *rb_ruby_parser_new(const rb_parser_config_t *config);
#endif

RUBY_SYMBOL_EXPORT_END

#endif /* RUBY_RUBYPARSER_H */
