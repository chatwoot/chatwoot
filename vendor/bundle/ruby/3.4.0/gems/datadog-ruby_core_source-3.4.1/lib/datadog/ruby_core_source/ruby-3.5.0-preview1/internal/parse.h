#ifndef INTERNAL_PARSE_H                                 /*-*-C-*-vi:se ft=c:*/
#define INTERNAL_PARSE_H
/**
 * @author     Ruby developers <ruby-core@ruby-lang.org>
 * @copyright  This  file  is   a  part  of  the   programming  language  Ruby.
 *             Permission  is hereby  granted,  to  either redistribute  and/or
 *             modify this file, provided that  the conditions mentioned in the
 *             file COPYING are met.  Consult the file for details.
 * @brief      Internal header for the parser.
 */
#include <limits.h>
#include "rubyparser.h"
#include "internal/static_assert.h"

// The default parser to use for Ruby code.
typedef enum {
    RB_DEFAULT_PARSER_PARSE_Y,
    RB_DEFAULT_PARSER_PRISM,
} ruby_default_parser_enum;

ruby_default_parser_enum rb_ruby_default_parser(void);
void rb_ruby_default_parser_set(ruby_default_parser_enum parser);

#define rb_ruby_prism_p() (rb_ruby_default_parser() == RB_DEFAULT_PARSER_PRISM)

#ifdef UNIVERSAL_PARSER
#define rb_encoding const void
#endif

struct rb_iseq_struct;          /* in vm_core.h */

/* structs for managing terminator of string literal and heredocment */
typedef struct rb_strterm_literal_struct {
    long nest;
    int func;	    /* STR_FUNC_* (e.g., STR_FUNC_ESCAPE and STR_FUNC_EXPAND) */
    int paren;	    /* '(' of `%q(...)` */
    int term;	    /* ')' of `%q(...)` */
} rb_strterm_literal_t;

typedef struct rb_strterm_heredoc_struct {
    rb_parser_string_t *lastline;	/* the string of line that contains `<<"END"` */
    long offset;	/* the column of END in `<<"END"` */
    int sourceline;	/* lineno of the line that contains `<<"END"` */
    unsigned length;	/* the length of END in `<<"END"` */
    uint8_t quote;
    uint8_t func;
} rb_strterm_heredoc_t;

#define HERETERM_LENGTH_MAX UINT_MAX

typedef struct rb_strterm_struct {
    bool heredoc;
    union {
        rb_strterm_literal_t literal;
        rb_strterm_heredoc_t heredoc;
    } u;
} rb_strterm_t;

/* parse.y */
void rb_ruby_parser_mark(void *ptr);
size_t rb_ruby_parser_memsize(const void *ptr);

void rb_ruby_parser_set_options(rb_parser_t *p, int print, int loop, int chomp, int split);
rb_parser_t *rb_ruby_parser_set_context(rb_parser_t *p, const struct rb_iseq_struct *base, int main);
void rb_ruby_parser_set_script_lines(rb_parser_t *p);
void rb_ruby_parser_error_tolerant(rb_parser_t *p);
void rb_ruby_parser_keep_tokens(rb_parser_t *p);
typedef rb_parser_string_t*(rb_parser_lex_gets_func)(struct parser_params*, rb_parser_input_data, int);
rb_ast_t *rb_parser_compile(rb_parser_t *p, rb_parser_lex_gets_func *gets, VALUE fname, rb_parser_input_data input, int line);

RUBY_SYMBOL_EXPORT_BEGIN

rb_encoding *rb_ruby_parser_encoding(rb_parser_t *p);
int rb_ruby_parser_end_seen_p(rb_parser_t *p);
int rb_ruby_parser_set_yydebug(rb_parser_t *p, int flag);
rb_parser_string_t *rb_str_to_parser_string(rb_parser_t *p, VALUE str);
void rb_parser_string_free(rb_parser_t *p, rb_parser_string_t *str);

int rb_parser_dvar_defined_ref(struct parser_params*, ID, ID**);
ID rb_parser_internal_id(struct parser_params*);
typedef void (*rb_parser_reg_fragment_error_func)(struct parser_params *, VALUE);
int rb_parser_reg_fragment_check(struct parser_params*, rb_parser_string_t*, int, rb_parser_reg_fragment_error_func);
int rb_reg_named_capture_assign_iter_impl(struct parser_params *p, const char *s, long len, rb_encoding *enc, NODE **succ_block, const rb_code_location_t *loc, rb_parser_assignable_func assignable);
int rb_parser_local_defined(struct parser_params *p, ID id, const struct rb_iseq_struct *iseq);
NODE *rb_parser_assignable(struct parser_params *p, ID id, NODE *val, const YYLTYPE *loc);

RUBY_SYMBOL_EXPORT_END

#ifndef UNIVERSAL_PARSER
rb_parser_t *rb_ruby_parser_allocate(void);
rb_parser_t *rb_ruby_parser_new(void);
#endif

#ifdef RIPPER
void ripper_parser_mark(void *ptr);
void ripper_parser_free(void *ptr);
size_t ripper_parser_memsize(const void *ptr);
void ripper_error(struct parser_params *p);
VALUE ripper_value(struct parser_params *p);
int rb_ruby_parser_get_yydebug(rb_parser_t *p);
void rb_ruby_parser_set_value(rb_parser_t *p, VALUE value);
int rb_ruby_parser_error_p(rb_parser_t *p);
VALUE rb_ruby_parser_debug_output(rb_parser_t *p);
void rb_ruby_parser_set_debug_output(rb_parser_t *p, VALUE output);
VALUE rb_ruby_parser_parsing_thread(rb_parser_t *p);
void rb_ruby_parser_set_parsing_thread(rb_parser_t *p, VALUE parsing_thread);
void rb_ruby_parser_ripper_initialize(rb_parser_t *p, rb_parser_lex_gets_func *gets, rb_parser_input_data input, VALUE sourcefile_string, const char *sourcefile, int sourceline);
VALUE rb_ruby_parser_result(rb_parser_t *p);
rb_encoding *rb_ruby_parser_enc(rb_parser_t *p);
VALUE rb_ruby_parser_ruby_sourcefile_string(rb_parser_t *p);
int rb_ruby_parser_ruby_sourceline(rb_parser_t *p);
int rb_ruby_parser_lex_state(rb_parser_t *p);
void rb_ruby_ripper_parse0(rb_parser_t *p);
int rb_ruby_ripper_dedent_string(rb_parser_t *p, rb_parser_string_t *string, int width);
int rb_ruby_ripper_initialized_p(rb_parser_t *p);
void rb_ruby_ripper_parser_initialize(rb_parser_t *p);
long rb_ruby_ripper_column(rb_parser_t *p);
long rb_ruby_ripper_token_len(rb_parser_t *p);
rb_parser_string_t *rb_ruby_ripper_lex_lastline(rb_parser_t *p);
VALUE rb_ruby_ripper_lex_state_name(struct parser_params *p, int state);
#ifdef UNIVERSAL_PARSER
rb_parser_t *rb_ripper_parser_params_allocate(const rb_parser_config_t *config);
#endif
struct parser_params *rb_ruby_ripper_parser_allocate(void);
#endif

#ifdef UNIVERSAL_PARSER
#undef rb_encoding
#endif

#endif /* INTERNAL_PARSE_H */
