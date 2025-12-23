/* CC0 (Public domain) - see ccan/licenses/CC0 file for details */
#ifndef CCAN_CHECK_TYPE_H
#define CCAN_CHECK_TYPE_H

/**
 * ccan_check_type - issue a warning or build failure if type is not correct.
 * @expr: the expression whose type we should check (not evaluated).
 * @type: the exact type we expect the expression to be.
 *
 * This macro is usually used within other macros to try to ensure that a macro
 * argument is of the expected type.  No type promotion of the expression is
 * done: an unsigned int is not the same as an int!
 *
 * ccan_check_type() always evaluates to 0.
 *
 * If your compiler does not support typeof, then the best we can do is fail
 * to compile if the sizes of the types are unequal (a less complete check).
 *
 * Example:
 *	// They should always pass a 64-bit value to _set_some_value!
 *	#define set_some_value(expr)			\
 *		_set_some_value((ccan_check_type((expr), uint64_t), (expr)))
 */

/**
 * ccan_check_types_match - issue a warning or build failure if types are not same.
 * @expr1: the first expression (not evaluated).
 * @expr2: the second expression (not evaluated).
 *
 * This macro is usually used within other macros to try to ensure that
 * arguments are of identical types.  No type promotion of the expressions is
 * done: an unsigned int is not the same as an int!
 *
 * ccan_check_types_match() always evaluates to 0.
 *
 * If your compiler does not support typeof, then the best we can do is fail
 * to compile if the sizes of the types are unequal (a less complete check).
 *
 * Example:
 *	// Do subtraction to get to enclosing type, but make sure that
 *	// pointer is of correct type for that member.
 *	#define ccan_container_of(mbr_ptr, encl_type, mbr)			\
 *		(ccan_check_types_match((mbr_ptr), &((encl_type *)0)->mbr),	\
 *		 ((encl_type *)						\
 *		  ((char *)(mbr_ptr) - offsetof(enclosing_type, mbr))))
 */
#if defined(HAVE_TYPEOF) && HAVE_TYPEOF
#define ccan_check_type(expr, type)			\
	((typeof(expr) *)0 != (type *)0)

#define ccan_check_types_match(expr1, expr2)		\
	((typeof(expr1) *)0 != (typeof(expr2) *)0)
#else
#include "ccan/build_assert/build_assert.h"
/* Without typeof, we can only test the sizes. */
#define ccan_check_type(expr, type)					\
	CCAN_BUILD_ASSERT_OR_ZERO(sizeof(expr) == sizeof(type))

#define ccan_check_types_match(expr1, expr2)				\
	CCAN_BUILD_ASSERT_OR_ZERO(sizeof(expr1) == sizeof(expr2))
#endif /* HAVE_TYPEOF */

#endif /* CCAN_CHECK_TYPE_H */
