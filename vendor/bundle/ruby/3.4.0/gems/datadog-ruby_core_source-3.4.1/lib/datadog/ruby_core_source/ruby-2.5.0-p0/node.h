/**********************************************************************

  node.h -

  $Author: mame $
  created at: Fri May 28 15:14:02 JST 1993

  Copyright (C) 1993-2007 Yukihiro Matsumoto

**********************************************************************/

#ifndef RUBY_NODE_H
#define RUBY_NODE_H 1

#if defined(__cplusplus)
extern "C" {
#if 0
} /* satisfy cc-mode */
#endif
#endif

enum node_type {
    NODE_SCOPE,
#define NODE_SCOPE       NODE_SCOPE
    NODE_BLOCK,
#define NODE_BLOCK       NODE_BLOCK
    NODE_IF,
#define NODE_IF          NODE_IF
    NODE_UNLESS,
#define NODE_UNLESS      NODE_UNLESS
    NODE_CASE,
#define NODE_CASE        NODE_CASE
    NODE_CASE2,
#define NODE_CASE2       NODE_CASE2
    NODE_WHEN,
#define NODE_WHEN        NODE_WHEN
    NODE_WHILE,
#define NODE_WHILE       NODE_WHILE
    NODE_UNTIL,
#define NODE_UNTIL       NODE_UNTIL
    NODE_ITER,
#define NODE_ITER        NODE_ITER
    NODE_FOR,
#define NODE_FOR         NODE_FOR
    NODE_BREAK,
#define NODE_BREAK       NODE_BREAK
    NODE_NEXT,
#define NODE_NEXT        NODE_NEXT
    NODE_REDO,
#define NODE_REDO        NODE_REDO
    NODE_RETRY,
#define NODE_RETRY       NODE_RETRY
    NODE_BEGIN,
#define NODE_BEGIN       NODE_BEGIN
    NODE_RESCUE,
#define NODE_RESCUE      NODE_RESCUE
    NODE_RESBODY,
#define NODE_RESBODY     NODE_RESBODY
    NODE_ENSURE,
#define NODE_ENSURE      NODE_ENSURE
    NODE_AND,
#define NODE_AND         NODE_AND
    NODE_OR,
#define NODE_OR          NODE_OR
    NODE_MASGN,
#define NODE_MASGN       NODE_MASGN
    NODE_LASGN,
#define NODE_LASGN       NODE_LASGN
    NODE_DASGN,
#define NODE_DASGN       NODE_DASGN
    NODE_DASGN_CURR,
#define NODE_DASGN_CURR  NODE_DASGN_CURR
    NODE_GASGN,
#define NODE_GASGN       NODE_GASGN
    NODE_IASGN,
#define NODE_IASGN       NODE_IASGN
    NODE_CDECL,
#define NODE_CDECL       NODE_CDECL
    NODE_CVASGN,
#define NODE_CVASGN      NODE_CVASGN
    NODE_OP_ASGN1,
#define NODE_OP_ASGN1    NODE_OP_ASGN1
    NODE_OP_ASGN2,
#define NODE_OP_ASGN2    NODE_OP_ASGN2
    NODE_OP_ASGN_AND,
#define NODE_OP_ASGN_AND NODE_OP_ASGN_AND
    NODE_OP_ASGN_OR,
#define NODE_OP_ASGN_OR  NODE_OP_ASGN_OR
    NODE_OP_CDECL,
#define NODE_OP_CDECL    NODE_OP_CDECL
    NODE_CALL,
#define NODE_CALL        NODE_CALL
    NODE_OPCALL,
#define NODE_OPCALL      NODE_OPCALL
    NODE_FCALL,
#define NODE_FCALL       NODE_FCALL
    NODE_VCALL,
#define NODE_VCALL       NODE_VCALL
    NODE_QCALL,
#define NODE_QCALL       NODE_QCALL
    NODE_SUPER,
#define NODE_SUPER       NODE_SUPER
    NODE_ZSUPER,
#define NODE_ZSUPER      NODE_ZSUPER
    NODE_ARRAY,
#define NODE_ARRAY       NODE_ARRAY
    NODE_ZARRAY,
#define NODE_ZARRAY      NODE_ZARRAY
    NODE_VALUES,
#define NODE_VALUES      NODE_VALUES
    NODE_HASH,
#define NODE_HASH        NODE_HASH
    NODE_RETURN,
#define NODE_RETURN      NODE_RETURN
    NODE_YIELD,
#define NODE_YIELD       NODE_YIELD
    NODE_LVAR,
#define NODE_LVAR        NODE_LVAR
    NODE_DVAR,
#define NODE_DVAR        NODE_DVAR
    NODE_GVAR,
#define NODE_GVAR        NODE_GVAR
    NODE_IVAR,
#define NODE_IVAR        NODE_IVAR
    NODE_CONST,
#define NODE_CONST       NODE_CONST
    NODE_CVAR,
#define NODE_CVAR        NODE_CVAR
    NODE_NTH_REF,
#define NODE_NTH_REF     NODE_NTH_REF
    NODE_BACK_REF,
#define NODE_BACK_REF    NODE_BACK_REF
    NODE_MATCH,
#define NODE_MATCH       NODE_MATCH
    NODE_MATCH2,
#define NODE_MATCH2      NODE_MATCH2
    NODE_MATCH3,
#define NODE_MATCH3      NODE_MATCH3
    NODE_LIT,
#define NODE_LIT         NODE_LIT
    NODE_STR,
#define NODE_STR         NODE_STR
    NODE_DSTR,
#define NODE_DSTR        NODE_DSTR
    NODE_XSTR,
#define NODE_XSTR        NODE_XSTR
    NODE_DXSTR,
#define NODE_DXSTR       NODE_DXSTR
    NODE_EVSTR,
#define NODE_EVSTR       NODE_EVSTR
    NODE_DREGX,
#define NODE_DREGX       NODE_DREGX
    NODE_ARGS,
#define NODE_ARGS        NODE_ARGS
    NODE_ARGS_AUX,
#define NODE_ARGS_AUX    NODE_ARGS_AUX
    NODE_OPT_ARG,
#define NODE_OPT_ARG     NODE_OPT_ARG
    NODE_KW_ARG,
#define NODE_KW_ARG	 NODE_KW_ARG
    NODE_POSTARG,
#define NODE_POSTARG     NODE_POSTARG
    NODE_ARGSCAT,
#define NODE_ARGSCAT     NODE_ARGSCAT
    NODE_ARGSPUSH,
#define NODE_ARGSPUSH    NODE_ARGSPUSH
    NODE_SPLAT,
#define NODE_SPLAT       NODE_SPLAT
    NODE_BLOCK_PASS,
#define NODE_BLOCK_PASS  NODE_BLOCK_PASS
    NODE_DEFN,
#define NODE_DEFN        NODE_DEFN
    NODE_DEFS,
#define NODE_DEFS        NODE_DEFS
    NODE_ALIAS,
#define NODE_ALIAS       NODE_ALIAS
    NODE_VALIAS,
#define NODE_VALIAS      NODE_VALIAS
    NODE_UNDEF,
#define NODE_UNDEF       NODE_UNDEF
    NODE_CLASS,
#define NODE_CLASS       NODE_CLASS
    NODE_MODULE,
#define NODE_MODULE      NODE_MODULE
    NODE_SCLASS,
#define NODE_SCLASS      NODE_SCLASS
    NODE_COLON2,
#define NODE_COLON2      NODE_COLON2
    NODE_COLON3,
#define NODE_COLON3      NODE_COLON3
    NODE_DOT2,
#define NODE_DOT2        NODE_DOT2
    NODE_DOT3,
#define NODE_DOT3        NODE_DOT3
    NODE_FLIP2,
#define NODE_FLIP2       NODE_FLIP2
    NODE_FLIP3,
#define NODE_FLIP3       NODE_FLIP3
    NODE_SELF,
#define NODE_SELF        NODE_SELF
    NODE_NIL,
#define NODE_NIL         NODE_NIL
    NODE_TRUE,
#define NODE_TRUE        NODE_TRUE
    NODE_FALSE,
#define NODE_FALSE       NODE_FALSE
    NODE_ERRINFO,
#define NODE_ERRINFO     NODE_ERRINFO
    NODE_DEFINED,
#define NODE_DEFINED     NODE_DEFINED
    NODE_POSTEXE,
#define NODE_POSTEXE     NODE_POSTEXE
    NODE_DSYM,
#define NODE_DSYM        NODE_DSYM
    NODE_ATTRASGN,
#define NODE_ATTRASGN    NODE_ATTRASGN
    NODE_PRELUDE,
#define NODE_PRELUDE     NODE_PRELUDE
    NODE_LAMBDA,
#define NODE_LAMBDA      NODE_LAMBDA
    NODE_LAST
#define NODE_LAST        NODE_LAST
};

typedef struct rb_code_location_struct {
    int lineno;
    int column;
} rb_code_location_t;

typedef struct rb_code_range_struct {
    rb_code_location_t first_loc;
    rb_code_location_t last_loc;
} rb_code_range_t;

typedef struct RNode {
    VALUE flags;
    union {
	struct RNode *node;
	ID id;
	VALUE value;
	VALUE (*cfunc)(ANYARGS);
	ID *tbl;
    } u1;
    union {
	struct RNode *node;
	ID id;
	long argc;
	VALUE value;
    } u2;
    union {
	struct RNode *node;
	ID id;
	long state;
	struct rb_global_entry *entry;
	struct rb_args_info *args;
	long cnt;
	VALUE value;
    } u3;
    rb_code_range_t nd_loc;
} NODE;

#define RNODE(obj)  (R_CAST(RNode)(obj))

/* FL     : 0..4: T_TYPES, 5: KEEP_WB, 6: PROMOTED, 7: FINALIZE, 8: TAINT, 9: UNTRUSTED, 10: EXIVAR, 11: FREEZE */
/* NODE_FL: 0..4: T_TYPES, 5: KEEP_WB, 6: PROMOTED, 7: NODE_FL_NEWLINE,
 *          8..14: nd_type,
 *          15..: nd_line
 */
#define NODE_FL_NEWLINE              (((VALUE)1)<<7)

#define NODE_TYPESHIFT 8
#define NODE_TYPEMASK  (((VALUE)0x7f)<<NODE_TYPESHIFT)

#define nd_type(n) ((int) (((n)->flags & NODE_TYPEMASK)>>NODE_TYPESHIFT))
#define nd_set_type(n,t) \
    (n)->flags=(((n)->flags&~NODE_TYPEMASK)|((((unsigned long)(t))<<NODE_TYPESHIFT)&NODE_TYPEMASK))

#define NODE_LSHIFT (NODE_TYPESHIFT+7)
#define NODE_LMASK  (((SIGNED_VALUE)1<<(sizeof(VALUE)*CHAR_BIT-NODE_LSHIFT))-1)
#define nd_line(n) (int)(((SIGNED_VALUE)(n)->flags)>>NODE_LSHIFT)
#define nd_set_line(n,l) \
    (n)->flags=(((n)->flags&~((VALUE)(-1)<<NODE_LSHIFT))|((VALUE)((l)&NODE_LMASK)<<NODE_LSHIFT))

#define nd_first_column(n) ((int)((n)->nd_loc.first_loc.column))
#define nd_set_first_column(n, v) ((n)->nd_loc.first_loc.column = (v))
#define nd_first_lineno(n) ((int)((n)->nd_loc.first_loc.lineno))
#define nd_set_first_lineno(n, v) ((n)->nd_loc.first_loc.lineno = (v))

#define nd_last_column(n) ((int)((n)->nd_loc.last_loc.column))
#define nd_set_last_column(n, v) ((n)->nd_loc.last_loc.column = (v))
#define nd_last_lineno(n) ((int)((n)->nd_loc.last_loc.lineno))
#define nd_set_last_lineno(n, v) ((n)->nd_loc.last_loc.lineno = (v))
#define nd_last_loc(n) ((n)->nd_loc.last_loc)
#define nd_set_last_loc(n, v) (nd_last_loc(n) = (v))

#define nd_head  u1.node
#define nd_alen  u2.argc
#define nd_next  u3.node

#define nd_cond  u1.node
#define nd_body  u2.node
#define nd_else  u3.node

#define nd_resq  u2.node
#define nd_ensr  u3.node

#define nd_1st   u1.node
#define nd_2nd   u2.node

#define nd_stts  u1.node

#define nd_entry u3.entry
#define nd_vid   u1.id
#define nd_cflag u2.id
#define nd_cval  u3.value

#define nd_oid   u1.id
#define nd_cnt   u3.cnt
#define nd_tbl   u1.tbl

#define nd_var   u1.node
#define nd_iter  u3.node

#define nd_value u2.node
#define nd_aid   u3.id

#define nd_lit   u1.value

#define nd_frml  u2.argc
#define nd_rest  u1.id
#define nd_opt   u1.node
#define nd_pid   u1.id
#define nd_plen  u2.argc

#define nd_recv  u1.node
#define nd_mid   u2.id
#define nd_args  u3.node
#define nd_ainfo u3.args

#define nd_noex  u3.id
#define nd_defn  u3.node

#define nd_cfnc  u1.cfunc
#define nd_argc  u2.argc

#define nd_cpath u1.node
#define nd_super u3.node

#define nd_beg   u1.node
#define nd_end   u2.node
#define nd_state u3.state
#define nd_rval  u2.value

#define nd_nth   u2.argc

#define nd_tag   u1.id

#define nd_alias  u1.id
#define nd_orig   u2.id
#define nd_undef  u2.node

#define nd_compile_option  u3.value

#define NEW_NODE(t,a0,a1,a2) rb_node_newnode((t),(VALUE)(a0),(VALUE)(a1),(VALUE)(a2))

#define NEW_DEFN(i,a,d,p) NEW_NODE(NODE_DEFN,0,i,NEW_SCOPE(a,d))
#define NEW_DEFS(r,i,a,d) NEW_NODE(NODE_DEFS,r,i,NEW_SCOPE(a,d))
#define NEW_SCOPE(a,b) NEW_NODE(NODE_SCOPE,local_tbl(),b,a)
#define NEW_BLOCK(a) NEW_NODE(NODE_BLOCK,a,0,0)
#define NEW_IF(c,t,e) NEW_NODE(NODE_IF,c,t,e)
#define NEW_UNLESS(c,t,e) NEW_NODE(NODE_UNLESS,c,t,e)
#define NEW_CASE(h,b) NEW_NODE(NODE_CASE,h,b,0)
#define NEW_CASE2(b) NEW_NODE(NODE_CASE2,0,b,0)
#define NEW_WHEN(c,t,e) NEW_NODE(NODE_WHEN,c,t,e)
#define NEW_WHILE(c,b,n) NEW_NODE(NODE_WHILE,c,b,n)
#define NEW_UNTIL(c,b,n) NEW_NODE(NODE_UNTIL,c,b,n)
#define NEW_FOR(v,i,b) NEW_NODE(NODE_FOR,v,b,i)
#define NEW_ITER(a,b) NEW_NODE(NODE_ITER,0,NEW_SCOPE(a,b),0)
#define NEW_LAMBDA(a,b) NEW_NODE(NODE_LAMBDA,0,NEW_SCOPE(a,b),0)
#define NEW_BREAK(s) NEW_NODE(NODE_BREAK,s,0,0)
#define NEW_NEXT(s) NEW_NODE(NODE_NEXT,s,0,0)
#define NEW_REDO() NEW_NODE(NODE_REDO,0,0,0)
#define NEW_RETRY() NEW_NODE(NODE_RETRY,0,0,0)
#define NEW_BEGIN(b) NEW_NODE(NODE_BEGIN,0,b,0)
#define NEW_RESCUE(b,res,e) NEW_NODE(NODE_RESCUE,b,res,e)
#define NEW_RESBODY(a,ex,n) NEW_NODE(NODE_RESBODY,n,ex,a)
#define NEW_ENSURE(b,en) NEW_NODE(NODE_ENSURE,b,0,en)
#define NEW_RETURN(s) NEW_NODE(NODE_RETURN,s,0,0)
#define NEW_YIELD(a) NEW_NODE(NODE_YIELD,a,0,0)
#define NEW_LIST(a)  NEW_ARRAY(a)
#define NEW_ARRAY(a) NEW_NODE(NODE_ARRAY,a,1,0)
#define NEW_ZARRAY() NEW_NODE(NODE_ZARRAY,0,0,0)
#define NEW_HASH(a)  NEW_NODE(NODE_HASH,a,0,0)
#define NEW_MASGN(l,r)   NEW_NODE(NODE_MASGN,l,0,r)
#define NEW_GASGN(v,val) NEW_NODE(NODE_GASGN,v,val,rb_global_entry(v))
#define NEW_LASGN(v,val) NEW_NODE(NODE_LASGN,v,val,0)
#define NEW_DASGN(v,val) NEW_NODE(NODE_DASGN,v,val,0)
#define NEW_DASGN_CURR(v,val) NEW_NODE(NODE_DASGN_CURR,v,val,0)
#define NEW_IASGN(v,val) NEW_NODE(NODE_IASGN,v,val,0)
#define NEW_CDECL(v,val,path) NEW_NODE(NODE_CDECL,v,val,path)
#define NEW_CVASGN(v,val) NEW_NODE(NODE_CVASGN,v,val,0)
#define NEW_OP_ASGN1(p,id,a) NEW_NODE(NODE_OP_ASGN1,p,id,a)
#define NEW_OP_ASGN2(r,t,i,o,val) NEW_NODE(NODE_OP_ASGN2,r,val,NEW_OP_ASGN22(i,o,t))
#define NEW_OP_ASGN22(i,o,t) NEW_NODE(NODE_OP_ASGN2,i,o,t)
#define NEW_OP_ASGN_OR(i,val) NEW_NODE(NODE_OP_ASGN_OR,i,val,0)
#define NEW_OP_ASGN_AND(i,val) NEW_NODE(NODE_OP_ASGN_AND,i,val,0)
#define NEW_OP_CDECL(v,op,val) NEW_NODE(NODE_OP_CDECL,v,val,op)
#define NEW_GVAR(v) NEW_NODE(NODE_GVAR,v,0,rb_global_entry(v))
#define NEW_LVAR(v) NEW_NODE(NODE_LVAR,v,0,0)
#define NEW_DVAR(v) NEW_NODE(NODE_DVAR,v,0,0)
#define NEW_IVAR(v) NEW_NODE(NODE_IVAR,v,0,0)
#define NEW_CONST(v) NEW_NODE(NODE_CONST,v,0,0)
#define NEW_CVAR(v) NEW_NODE(NODE_CVAR,v,0,0)
#define NEW_NTH_REF(n)  NEW_NODE(NODE_NTH_REF,0,n,0)
#define NEW_BACK_REF(n) NEW_NODE(NODE_BACK_REF,0,n,0)
#define NEW_MATCH(c) NEW_NODE(NODE_MATCH,c,0,0)
#define NEW_MATCH2(n1,n2) NEW_NODE(NODE_MATCH2,n1,n2,0)
#define NEW_MATCH3(r,n2) NEW_NODE(NODE_MATCH3,r,n2,0)
#define NEW_LIT(l) NEW_NODE(NODE_LIT,l,0,0)
#define NEW_STR(s) NEW_NODE(NODE_STR,s,0,0)
#define NEW_DSTR(s) NEW_NODE(NODE_DSTR,s,1,0)
#define NEW_XSTR(s) NEW_NODE(NODE_XSTR,s,0,0)
#define NEW_DXSTR(s) NEW_NODE(NODE_DXSTR,s,0,0)
#define NEW_DSYM(s) NEW_NODE(NODE_DSYM,s,0,0)
#define NEW_EVSTR(n) NEW_NODE(NODE_EVSTR,0,(n),0)
#define NEW_CALL(r,m,a) NEW_NODE(NODE_CALL,r,m,a)
#define NEW_OPCALL(r,m,a) NEW_NODE(NODE_OPCALL,r,m,a)
#define NEW_FCALL(m,a) NEW_NODE(NODE_FCALL,0,m,a)
#define NEW_VCALL(m) NEW_NODE(NODE_VCALL,0,m,0)
#define NEW_SUPER(a) NEW_NODE(NODE_SUPER,0,0,a)
#define NEW_ZSUPER() NEW_NODE(NODE_ZSUPER,0,0,0)
#define NEW_ARGS_AUX(r,b) NEW_NODE(NODE_ARGS_AUX,r,b,0)
#define NEW_OPT_ARG(i,v) NEW_NODE(NODE_OPT_ARG,i,v,0)
#define NEW_KW_ARG(i,v) NEW_NODE(NODE_KW_ARG,i,v,0)
#define NEW_POSTARG(i,v) NEW_NODE(NODE_POSTARG,i,v,0)
#define NEW_ARGSCAT(a,b) NEW_NODE(NODE_ARGSCAT,a,b,0)
#define NEW_ARGSPUSH(a,b) NEW_NODE(NODE_ARGSPUSH,a,b,0)
#define NEW_SPLAT(a) NEW_NODE(NODE_SPLAT,a,0,0)
#define NEW_BLOCK_PASS(b) NEW_NODE(NODE_BLOCK_PASS,0,b,0)
#define NEW_ALIAS(n,o) NEW_NODE(NODE_ALIAS,n,o,0)
#define NEW_VALIAS(n,o) NEW_NODE(NODE_VALIAS,n,o,0)
#define NEW_UNDEF(i) NEW_NODE(NODE_UNDEF,0,i,0)
#define NEW_CLASS(n,b,s) NEW_NODE(NODE_CLASS,n,NEW_SCOPE(0,b),(s))
#define NEW_SCLASS(r,b) NEW_NODE(NODE_SCLASS,r,NEW_SCOPE(0,b),0)
#define NEW_MODULE(n,b) NEW_NODE(NODE_MODULE,n,NEW_SCOPE(0,b),0)
#define NEW_COLON2(c,i) NEW_NODE(NODE_COLON2,c,i,0)
#define NEW_COLON3(i) NEW_NODE(NODE_COLON3,0,i,0)
#define NEW_DOT2(b,e) NEW_NODE(NODE_DOT2,b,e,0)
#define NEW_DOT3(b,e) NEW_NODE(NODE_DOT3,b,e,0)
#define NEW_SELF() NEW_NODE(NODE_SELF,0,0,0)
#define NEW_NIL() NEW_NODE(NODE_NIL,0,0,0)
#define NEW_TRUE() NEW_NODE(NODE_TRUE,0,0,0)
#define NEW_FALSE() NEW_NODE(NODE_FALSE,0,0,0)
#define NEW_ERRINFO() NEW_NODE(NODE_ERRINFO,0,0,0)
#define NEW_DEFINED(e) NEW_NODE(NODE_DEFINED,e,0,0)
#define NEW_PREEXE(b) NEW_SCOPE(b)
#define NEW_POSTEXE(b) NEW_NODE(NODE_POSTEXE,0,b,0)
#define NEW_ATTRASGN(r,m,a) NEW_NODE(NODE_ATTRASGN,r,m,a)
#define NEW_PRELUDE(p,b,o) NEW_NODE(NODE_PRELUDE,p,b,o)

#define NODE_SPECIAL_REQUIRED_KEYWORD ((NODE *)-1)
#define NODE_SPECIAL_NO_NAME_REST     ((NODE *)-1)

RUBY_SYMBOL_EXPORT_BEGIN

typedef struct node_buffer_struct node_buffer_t;
/* T_IMEMO/ast */
typedef struct rb_ast_struct {
    VALUE flags;
    VALUE reserved1;
    NODE *root;
    node_buffer_t *node_buffer;
    VALUE mark_ary;
} rb_ast_t;
rb_ast_t *rb_ast_new();
void rb_ast_mark(rb_ast_t*);
void rb_ast_dispose(rb_ast_t*);
void rb_ast_free(rb_ast_t*);
void rb_ast_add_mark_object(rb_ast_t*, VALUE);
void rb_ast_delete_mark_object(rb_ast_t*, VALUE);
NODE *rb_ast_newnode(rb_ast_t*);
void rb_ast_delete_node(rb_ast_t*, NODE *n);

VALUE rb_parser_new(void);
VALUE rb_parser_end_seen_p(VALUE);
VALUE rb_parser_encoding(VALUE);
VALUE rb_parser_get_yydebug(VALUE);
VALUE rb_parser_set_yydebug(VALUE, VALUE);
VALUE rb_parser_dump_tree(NODE *node, int comment);
void rb_parser_set_options(VALUE, int, int, int, int);

rb_ast_t *rb_parser_compile_cstr(VALUE, const char*, const char*, int, int);
rb_ast_t *rb_parser_compile_string(VALUE, const char*, VALUE, int);
rb_ast_t *rb_parser_compile_file(VALUE, const char*, VALUE, int);
rb_ast_t *rb_parser_compile_string_path(VALUE vparser, VALUE fname, VALUE src, int line);
rb_ast_t *rb_parser_compile_file_path(VALUE vparser, VALUE fname, VALUE input, int line);

rb_ast_t *rb_compile_cstr(const char*, const char*, int, int);
rb_ast_t *rb_compile_string(const char*, VALUE, int);
rb_ast_t *rb_compile_file(const char*, VALUE, int);

void rb_node_init(NODE *n, enum node_type type, VALUE a0, VALUE a1, VALUE a2);

const struct kwtable *rb_reserved_word(const char *, unsigned int);

struct rb_args_info {
    NODE *pre_init;
    NODE *post_init;

    int pre_args_num;  /* count of mandatory pre-arguments */
    int post_args_num; /* count of mandatory post-arguments */

    ID first_post_arg;

    ID rest_arg;
    ID block_arg;

    NODE *kw_args;
    NODE *kw_rest_arg;

    NODE *opt_args;
};

struct parser_params;
void *rb_parser_malloc(struct parser_params *, size_t);
void *rb_parser_realloc(struct parser_params *, void *, size_t);
void *rb_parser_calloc(struct parser_params *, size_t, size_t);
void rb_parser_free(struct parser_params *, void *);
void rb_parser_printf(struct parser_params *parser, const char *fmt, ...);

RUBY_SYMBOL_EXPORT_END

#if defined(__cplusplus)
#if 0
{ /* satisfy cc-mode */
#endif
}  /* extern "C" { */
#endif

#endif /* RUBY_NODE_H */
