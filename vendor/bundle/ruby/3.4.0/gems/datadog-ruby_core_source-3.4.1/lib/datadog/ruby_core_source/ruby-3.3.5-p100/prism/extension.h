#ifndef PRISM_EXT_NODE_H
#define PRISM_EXT_NODE_H

#define EXPECTED_PRISM_VERSION "0.19.0"

#include <ruby.h>
#include <ruby/encoding.h>
#include "prism.h"

VALUE pm_source_new(pm_parser_t *parser, rb_encoding *encoding);
VALUE pm_token_new(pm_parser_t *parser, pm_token_t *token, rb_encoding *encoding, VALUE source);
VALUE pm_ast_new(pm_parser_t *parser, pm_node_t *node, rb_encoding *encoding);

void Init_prism_api_node(void);
void Init_prism_pack(void);
PRISM_EXPORTED_FUNCTION void Init_prism(void);

#endif
