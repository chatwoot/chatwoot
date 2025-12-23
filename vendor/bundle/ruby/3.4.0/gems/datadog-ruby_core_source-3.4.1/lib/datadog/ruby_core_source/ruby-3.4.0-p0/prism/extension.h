#ifndef PRISM_EXT_NODE_H
#define PRISM_EXT_NODE_H

#define EXPECTED_PRISM_VERSION "1.2.0"

#include <ruby.h>
#include <ruby/encoding.h>
#include "prism.h"

VALUE pm_source_new(const pm_parser_t *parser, rb_encoding *encoding);
VALUE pm_token_new(const pm_parser_t *parser, const pm_token_t *token, rb_encoding *encoding, VALUE source);
VALUE pm_ast_new(const pm_parser_t *parser, const pm_node_t *node, rb_encoding *encoding, VALUE source);
VALUE pm_integer_new(const pm_integer_t *integer);

void Init_prism_api_node(void);
void Init_prism_pack(void);
RUBY_FUNC_EXPORTED void Init_prism(void);

#endif
