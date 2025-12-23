/* CC0 (Public domain) - see ccan/licenses/CC0 file for details */
#ifndef CCAN_STR_H
#define CCAN_STR_H
/**
 * stringify - Turn expression into a string literal
 * @expr: any C expression
 *
 * Example:
 *	#define PRINT_COND_IF_FALSE(cond) \
 *		((cond) || printf("%s is false!", stringify(cond)))
 */
#define stringify(expr)		stringify_1(expr)
/* Double-indirection required to stringify expansions */
#define stringify_1(expr)	#expr

#endif /* CCAN_STR_H */
