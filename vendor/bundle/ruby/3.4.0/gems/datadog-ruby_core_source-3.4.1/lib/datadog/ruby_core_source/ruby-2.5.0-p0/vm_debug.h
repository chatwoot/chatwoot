/**********************************************************************

  vm_debug.h - YARV Debug function interface

  $Author: nobu $
  created at: 04/08/25 02:33:49 JST

  Copyright (C) 2004-2007 Koichi Sasada

**********************************************************************/

#ifndef RUBY_DEBUG_H
#define RUBY_DEBUG_H

#include "ruby/ruby.h"
#include "node.h"

RUBY_SYMBOL_EXPORT_BEGIN

#define dpv(h,v) ruby_debug_print_value(-1, 0, (h), (v))
#define dp(v)    ruby_debug_print_value(-1, 0, "", (v))
#define dpi(i)   ruby_debug_print_id(-1, 0, "", (i))
#define dpn(n)   ruby_debug_print_node(-1, 0, "", (n))

#define bp()     ruby_debug_breakpoint()

VALUE ruby_debug_print_value(int level, int debug_level, const char *header, VALUE v);
ID    ruby_debug_print_id(int level, int debug_level, const char *header, ID id);
NODE *ruby_debug_print_node(int level, int debug_level, const char *header, const NODE *node);
int   ruby_debug_print_indent(int level, int debug_level, int indent_level);
void  ruby_debug_breakpoint(void);
void  ruby_debug_gc_check_func(void);
void ruby_set_debug_option(const char *str);

RUBY_SYMBOL_EXPORT_END

#endif /* RUBY_DEBUG_H */
