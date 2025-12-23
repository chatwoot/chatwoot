#ifndef RUBY_VM_OPTS_H/*-*-c-*-*/
#define RUBY_VM_OPTS_H
/**********************************************************************

  vm_opts.h - VM optimize option

  $Author$

  Copyright (C) 2004-2007 Koichi Sasada

**********************************************************************/

/* Compile options.
 * You can change these options at runtime by VM::CompileOption.
 * Following definitions are default values.
 */

#define OPT_TAILCALL_OPTIMIZATION       0
#define OPT_PEEPHOLE_OPTIMIZATION       1
#define OPT_SPECIALISED_INSTRUCTION     1
#define OPT_INLINE_CONST_CACHE          1
#define OPT_FROZEN_STRING_LITERAL       -1
#define OPT_DEBUG_FROZEN_STRING_LITERAL 0

/* Build Options.
 * You can't change these options at runtime.
 */

/* C compiler dependent */

/*
 * 0: direct (using labeled goto using GCC special)
 * 1: token (switch/case)
 * 2: call (function call for each insn dispatch)
 */
#ifndef OPT_THREADED_CODE
#define OPT_THREADED_CODE 0
#endif

#define OPT_DIRECT_THREADED_CODE (OPT_THREADED_CODE == 0)
#define OPT_TOKEN_THREADED_CODE  (OPT_THREADED_CODE == 1)
#define OPT_CALL_THREADED_CODE   (OPT_THREADED_CODE == 2)

/* VM running option */
#define OPT_CHECKED_RUN              1
#define OPT_INLINE_METHOD_CACHE      1
#define OPT_GLOBAL_METHOD_CACHE      1

#ifndef OPT_IC_FOR_IVAR
#define OPT_IC_FOR_IVAR 1
#endif

/* architecture independent, affects generated code */
#define OPT_OPERANDS_UNIFICATION     1
#define OPT_INSTRUCTIONS_UNIFICATION 0
#define OPT_UNIFY_ALL_COMBINATION    0

/* misc */
#ifndef OPT_SUPPORT_JOKE
#define OPT_SUPPORT_JOKE             0
#endif

#ifndef VM_COLLECT_USAGE_DETAILS
#define VM_COLLECT_USAGE_DETAILS     0
#endif

#endif /* RUBY_VM_OPTS_H */
