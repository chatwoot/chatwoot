/*
 * Written by Solar Designer <solar at openwall.com> in 1998-2010.
 * No copyright is claimed, and the software is hereby placed in the public
 * domain.  In case this attempt to disclaim copyright and place the software
 * in the public domain is deemed null and void, then the software is
 * Copyright (c) 1998-2010 Solar Designer and it is hereby released to the
 * general public under the following terms:
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted.
 *
 * There's ABSOLUTELY NO WARRANTY, express or implied.
 *
 * See crypt_blowfish.c for more information.
 */

#ifdef __i386__

#if defined(__OpenBSD__) && !defined(__ELF__)
#define UNDERSCORES
#define ALIGN_LOG
#endif

#if defined(__CYGWIN32__) || defined(__MINGW32__)
#define UNDERSCORES
#endif

#ifdef __DJGPP__
#define UNDERSCORES
#define ALIGN_LOG
#endif

#ifdef UNDERSCORES
#define _BF_body_r			__BF_body_r
#endif

#ifdef ALIGN_LOG
#define DO_ALIGN(log)			.align (log)
#elif defined(DUMBAS)
#define DO_ALIGN(log)			.align 1 << log
#else
#define DO_ALIGN(log)			.align (1 << (log))
#endif

#define BF_FRAME			0x200
#define ctx				%esp

#define BF_ptr				(ctx)

#define S(N, r)				N+BF_FRAME(ctx,r,4)
#ifdef DUMBAS
#define P(N)				0x1000+N+N+N+N+BF_FRAME(ctx)
#else
#define P(N)				0x1000+4*N+BF_FRAME(ctx)
#endif

/*
 * This version of the assembly code is optimized primarily for the original
 * Intel Pentium but is also careful to avoid partial register stalls on the
 * Pentium Pro family of processors (tested up to Pentium III Coppermine).
 *
 * It is possible to do 15% faster on the Pentium Pro family and probably on
 * many non-Intel x86 processors, but, unfortunately, that would make things
 * twice slower for the original Pentium.
 *
 * An additional 2% speedup may be achieved with non-reentrant code.
 */

#define L				%esi
#define R				%edi
#define tmp1				%eax
#define tmp1_lo				%al
#define tmp2				%ecx
#define tmp2_hi				%ch
#define tmp3				%edx
#define tmp3_lo				%dl
#define tmp4				%ebx
#define tmp4_hi				%bh
#define tmp5				%ebp

.text

#define BF_ROUND(L, R, N) \
	xorl L,tmp2; \
	xorl tmp1,tmp1; \
	movl tmp2,L; \
	shrl $16,tmp2; \
	movl L,tmp4; \
	movb tmp2_hi,tmp1_lo; \
	andl $0xFF,tmp2; \
	movb tmp4_hi,tmp3_lo; \
	andl $0xFF,tmp4; \
	movl S(0,tmp1),tmp1; \
	movl S(0x400,tmp2),tmp5; \
	addl tmp5,tmp1; \
	movl S(0x800,tmp3),tmp5; \
	xorl tmp5,tmp1; \
	movl S(0xC00,tmp4),tmp5; \
	addl tmp1,tmp5; \
	movl 4+P(N),tmp2; \
	xorl tmp5,R

#define BF_ENCRYPT_START \
	BF_ROUND(L, R, 0); \
	BF_ROUND(R, L, 1); \
	BF_ROUND(L, R, 2); \
	BF_ROUND(R, L, 3); \
	BF_ROUND(L, R, 4); \
	BF_ROUND(R, L, 5); \
	BF_ROUND(L, R, 6); \
	BF_ROUND(R, L, 7); \
	BF_ROUND(L, R, 8); \
	BF_ROUND(R, L, 9); \
	BF_ROUND(L, R, 10); \
	BF_ROUND(R, L, 11); \
	BF_ROUND(L, R, 12); \
	BF_ROUND(R, L, 13); \
	BF_ROUND(L, R, 14); \
	BF_ROUND(R, L, 15); \
	movl BF_ptr,tmp5; \
	xorl L,tmp2; \
	movl P(17),L

#define BF_ENCRYPT_END \
	xorl R,L; \
	movl tmp2,R

DO_ALIGN(5)
.globl _BF_body_r
_BF_body_r:
	movl 4(%esp),%eax
	pushl %ebp
	pushl %ebx
	pushl %esi
	pushl %edi
	subl $BF_FRAME-8,%eax
	xorl L,L
	cmpl %esp,%eax
	ja BF_die
	xchgl %eax,%esp
	xorl R,R
	pushl %eax
	leal 0x1000+BF_FRAME-4(ctx),%eax
	movl 0x1000+BF_FRAME-4(ctx),tmp2
	pushl %eax
	xorl tmp3,tmp3
BF_loop_P:
	BF_ENCRYPT_START
	addl $8,tmp5
	BF_ENCRYPT_END
	leal 0x1000+18*4+BF_FRAME(ctx),tmp1
	movl tmp5,BF_ptr
	cmpl tmp5,tmp1
	movl L,-8(tmp5)
	movl R,-4(tmp5)
	movl P(0),tmp2
	ja BF_loop_P
	leal BF_FRAME(ctx),tmp5
	xorl tmp3,tmp3
	movl tmp5,BF_ptr
BF_loop_S:
	BF_ENCRYPT_START
	BF_ENCRYPT_END
	movl P(0),tmp2
	movl L,(tmp5)
	movl R,4(tmp5)
	BF_ENCRYPT_START
	BF_ENCRYPT_END
	movl P(0),tmp2
	movl L,8(tmp5)
	movl R,12(tmp5)
	BF_ENCRYPT_START
	BF_ENCRYPT_END
	movl P(0),tmp2
	movl L,16(tmp5)
	movl R,20(tmp5)
	BF_ENCRYPT_START
	addl $32,tmp5
	BF_ENCRYPT_END
	leal 0x1000+BF_FRAME(ctx),tmp1
	movl tmp5,BF_ptr
	cmpl tmp5,tmp1
	movl P(0),tmp2
	movl L,-8(tmp5)
	movl R,-4(tmp5)
	ja BF_loop_S
	movl 4(%esp),%esp
	popl %edi
	popl %esi
	popl %ebx
	popl %ebp
	ret

BF_die:
/* Oops, need to re-compile with a larger BF_FRAME. */
	hlt
	jmp BF_die

#endif

#if defined(__ELF__) && defined(__linux__)
.section .note.GNU-stack,"",%progbits
#endif
