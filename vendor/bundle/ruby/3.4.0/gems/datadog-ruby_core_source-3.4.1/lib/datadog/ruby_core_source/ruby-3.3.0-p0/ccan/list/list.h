/* Licensed under BSD-MIT - see ccan/licenses/BSD-MIT file for details */
#ifndef CCAN_LIST_H
#define CCAN_LIST_H
#include <assert.h>
#include "ccan/str/str.h"
#include "ccan/container_of/container_of.h"
#include "ccan/check_type/check_type.h"

/**
 * struct ccan_list_node - an entry in a doubly-linked list
 * @next: next entry (self if empty)
 * @prev: previous entry (self if empty)
 *
 * This is used as an entry in a linked list.
 * Example:
 *	struct child {
 *		const char *name;
 *		// Linked list of all us children.
 *		struct ccan_list_node list;
 *	};
 */
struct ccan_list_node
{
	struct ccan_list_node *next, *prev;
};

/**
 * struct ccan_list_head - the head of a doubly-linked list
 * @h: the ccan_list_head (containing next and prev pointers)
 *
 * This is used as the head of a linked list.
 * Example:
 *	struct parent {
 *		const char *name;
 *		struct ccan_list_head children;
 *		unsigned int num_children;
 *	};
 */
struct ccan_list_head
{
	struct ccan_list_node n;
};

#define CCAN_LIST_LOC __FILE__  ":" ccan_stringify(__LINE__)
#define ccan_list_debug(h, loc) ((void)loc, h)
#define ccan_list_debug_node(n, loc) ((void)loc, n)

/**
 * CCAN_LIST_HEAD_INIT - initializer for an empty ccan_list_head
 * @name: the name of the list.
 *
 * Explicit initializer for an empty list.
 *
 * See also:
 *	CCAN_LIST_HEAD, ccan_list_head_init()
 *
 * Example:
 *	static struct ccan_list_head my_list = CCAN_LIST_HEAD_INIT(my_list);
 */
#define CCAN_LIST_HEAD_INIT(name) { { &(name).n, &(name).n } }

/**
 * CCAN_LIST_HEAD - define and initialize an empty ccan_list_head
 * @name: the name of the list.
 *
 * The CCAN_LIST_HEAD macro defines a ccan_list_head and initializes it to an empty
 * list.  It can be prepended by "static" to define a static ccan_list_head.
 *
 * See also:
 *	CCAN_LIST_HEAD_INIT, ccan_list_head_init()
 *
 * Example:
 *	static CCAN_LIST_HEAD(my_global_list);
 */
#define CCAN_LIST_HEAD(name) \
	struct ccan_list_head name = CCAN_LIST_HEAD_INIT(name)

/**
 * ccan_list_head_init - initialize a ccan_list_head
 * @h: the ccan_list_head to set to the empty list
 *
 * Example:
 *	...
 *	struct parent *parent = malloc(sizeof(*parent));
 *
 *	ccan_list_head_init(&parent->children);
 *	parent->num_children = 0;
 */
static inline void ccan_list_head_init(struct ccan_list_head *h)
{
	h->n.next = h->n.prev = &h->n;
}

/**
 * ccan_list_node_init - initialize a ccan_list_node
 * @n: the ccan_list_node to link to itself.
 *
 * You don't need to use this normally!  But it lets you ccan_list_del(@n)
 * safely.
 */
static inline void ccan_list_node_init(struct ccan_list_node *n)
{
	n->next = n->prev = n;
}

/**
 * ccan_list_add_after - add an entry after an existing node in a linked list
 * @h: the ccan_list_head to add the node to (for debugging)
 * @p: the existing ccan_list_node to add the node after
 * @n: the new ccan_list_node to add to the list.
 *
 * The existing ccan_list_node must already be a member of the list.
 * The new ccan_list_node does not need to be initialized; it will be overwritten.
 *
 * Example:
 *	struct child c1, c2, c3;
 *	CCAN_LIST_HEAD(h);
 *
 *	ccan_list_add_tail(&h, &c1.list);
 *	ccan_list_add_tail(&h, &c3.list);
 *	ccan_list_add_after(&h, &c1.list, &c2.list);
 */
#define ccan_list_add_after(h, p, n) ccan_list_add_after_(h, p, n, CCAN_LIST_LOC)
static inline void ccan_list_add_after_(struct ccan_list_head *h,
				   struct ccan_list_node *p,
				   struct ccan_list_node *n,
				   const char *abortstr)
{
	n->next = p->next;
	n->prev = p;
	p->next->prev = n;
	p->next = n;
	(void)ccan_list_debug(h, abortstr);
}

/**
 * ccan_list_add - add an entry at the start of a linked list.
 * @h: the ccan_list_head to add the node to
 * @n: the ccan_list_node to add to the list.
 *
 * The ccan_list_node does not need to be initialized; it will be overwritten.
 * Example:
 *	struct child *child = malloc(sizeof(*child));
 *
 *	child->name = "marvin";
 *	ccan_list_add(&parent->children, &child->list);
 *	parent->num_children++;
 */
#define ccan_list_add(h, n) ccan_list_add_(h, n, CCAN_LIST_LOC)
static inline void ccan_list_add_(struct ccan_list_head *h,
			     struct ccan_list_node *n,
			     const char *abortstr)
{
	ccan_list_add_after_(h, &h->n, n, abortstr);
}

/**
 * ccan_list_add_before - add an entry before an existing node in a linked list
 * @h: the ccan_list_head to add the node to (for debugging)
 * @p: the existing ccan_list_node to add the node before
 * @n: the new ccan_list_node to add to the list.
 *
 * The existing ccan_list_node must already be a member of the list.
 * The new ccan_list_node does not need to be initialized; it will be overwritten.
 *
 * Example:
 *	ccan_list_head_init(&h);
 *	ccan_list_add_tail(&h, &c1.list);
 *	ccan_list_add_tail(&h, &c3.list);
 *	ccan_list_add_before(&h, &c3.list, &c2.list);
 */
#define ccan_list_add_before(h, p, n) ccan_list_add_before_(h, p, n, CCAN_LIST_LOC)
static inline void ccan_list_add_before_(struct ccan_list_head *h,
				    struct ccan_list_node *p,
				    struct ccan_list_node *n,
				    const char *abortstr)
{
	n->next = p;
	n->prev = p->prev;
	p->prev->next = n;
	p->prev = n;
	(void)ccan_list_debug(h, abortstr);
}

/**
 * ccan_list_add_tail - add an entry at the end of a linked list.
 * @h: the ccan_list_head to add the node to
 * @n: the ccan_list_node to add to the list.
 *
 * The ccan_list_node does not need to be initialized; it will be overwritten.
 * Example:
 *	ccan_list_add_tail(&parent->children, &child->list);
 *	parent->num_children++;
 */
#define ccan_list_add_tail(h, n) ccan_list_add_tail_(h, n, CCAN_LIST_LOC)
static inline void ccan_list_add_tail_(struct ccan_list_head *h,
				  struct ccan_list_node *n,
				  const char *abortstr)
{
	ccan_list_add_before_(h, &h->n, n, abortstr);
}

/**
 * ccan_list_empty - is a list empty?
 * @h: the ccan_list_head
 *
 * If the list is empty, returns true.
 *
 * Example:
 *	assert(ccan_list_empty(&parent->children) == (parent->num_children == 0));
 */
#define ccan_list_empty(h) ccan_list_empty_(h, CCAN_LIST_LOC)
static inline int ccan_list_empty_(const struct ccan_list_head *h, const char* abortstr)
{
	(void)ccan_list_debug(h, abortstr);
	return h->n.next == &h->n;
}

/**
 * ccan_list_empty_nodebug - is a list empty (and don't perform debug checks)?
 * @h: the ccan_list_head
 *
 * If the list is empty, returns true.
 * This differs from list_empty() in that if CCAN_LIST_DEBUG is set it
 * will NOT perform debug checks. Only use this function if you REALLY
 * know what you're doing.
 *
 * Example:
 *	assert(ccan_list_empty_nodebug(&parent->children) == (parent->num_children == 0));
 */
#ifndef CCAN_LIST_DEBUG
#define ccan_list_empty_nodebug(h) ccan_list_empty(h)
#else
static inline int ccan_list_empty_nodebug(const struct ccan_list_head *h)
{
	return h->n.next == &h->n;
}
#endif

/**
 * ccan_list_empty_nocheck - is a list empty?
 * @h: the ccan_list_head
 *
 * If the list is empty, returns true. This doesn't perform any
 * debug check for list consistency, so it can be called without
 * locks, racing with the list being modified. This is ok for
 * checks where an incorrect result is not an issue (optimized
 * bail out path for example).
 */
static inline bool ccan_list_empty_nocheck(const struct ccan_list_head *h)
{
	return h->n.next == &h->n;
}

/**
 * ccan_list_del - delete an entry from an (unknown) linked list.
 * @n: the ccan_list_node to delete from the list.
 *
 * Note that this leaves @n in an undefined state; it can be added to
 * another list, but not deleted again.
 *
 * See also:
 *	ccan_list_del_from(), ccan_list_del_init()
 *
 * Example:
 *	ccan_list_del(&child->list);
 *	parent->num_children--;
 */
#define ccan_list_del(n) ccan_list_del_(n, CCAN_LIST_LOC)
static inline void ccan_list_del_(struct ccan_list_node *n, const char* abortstr)
{
	(void)ccan_list_debug_node(n, abortstr);
	n->next->prev = n->prev;
	n->prev->next = n->next;
#ifdef CCAN_LIST_DEBUG
	/* Catch use-after-del. */
	n->next = n->prev = NULL;
#endif
}

/**
 * ccan_list_del_init - delete a node, and reset it so it can be deleted again.
 * @n: the ccan_list_node to be deleted.
 *
 * ccan_list_del(@n) or ccan_list_del_init() again after this will be safe,
 * which can be useful in some cases.
 *
 * See also:
 *	ccan_list_del_from(), ccan_list_del()
 *
 * Example:
 *	ccan_list_del_init(&child->list);
 *	parent->num_children--;
 */
#define ccan_list_del_init(n) ccan_list_del_init_(n, CCAN_LIST_LOC)
static inline void ccan_list_del_init_(struct ccan_list_node *n, const char *abortstr)
{
	ccan_list_del_(n, abortstr);
	ccan_list_node_init(n);
}

/**
 * ccan_list_del_from - delete an entry from a known linked list.
 * @h: the ccan_list_head the node is in.
 * @n: the ccan_list_node to delete from the list.
 *
 * This explicitly indicates which list a node is expected to be in,
 * which is better documentation and can catch more bugs.
 *
 * See also: ccan_list_del()
 *
 * Example:
 *	ccan_list_del_from(&parent->children, &child->list);
 *	parent->num_children--;
 */
static inline void ccan_list_del_from(struct ccan_list_head *h, struct ccan_list_node *n)
{
#ifdef CCAN_LIST_DEBUG
	{
		/* Thorough check: make sure it was in list! */
		struct ccan_list_node *i;
		for (i = h->n.next; i != n; i = i->next)
			assert(i != &h->n);
	}
#endif /* CCAN_LIST_DEBUG */

	/* Quick test that catches a surprising number of bugs. */
	assert(!ccan_list_empty(h));
	ccan_list_del(n);
}

/**
 * ccan_list_swap - swap out an entry from an (unknown) linked list for a new one.
 * @o: the ccan_list_node to replace from the list.
 * @n: the ccan_list_node to insert in place of the old one.
 *
 * Note that this leaves @o in an undefined state; it can be added to
 * another list, but not deleted/swapped again.
 *
 * See also:
 *	ccan_list_del()
 *
 * Example:
 *	struct child x1, x2;
 *	CCAN_LIST_HEAD(xh);
 *
 *	ccan_list_add(&xh, &x1.list);
 *	ccan_list_swap(&x1.list, &x2.list);
 */
#define ccan_list_swap(o, n) ccan_list_swap_(o, n, CCAN_LIST_LOC)
static inline void ccan_list_swap_(struct ccan_list_node *o,
			      struct ccan_list_node *n,
			      const char* abortstr)
{
	(void)ccan_list_debug_node(o, abortstr);
	*n = *o;
	n->next->prev = n;
	n->prev->next = n;
#ifdef CCAN_LIST_DEBUG
	/* Catch use-after-del. */
	o->next = o->prev = NULL;
#endif
}

/**
 * ccan_list_entry - convert a ccan_list_node back into the structure containing it.
 * @n: the ccan_list_node
 * @type: the type of the entry
 * @member: the ccan_list_node member of the type
 *
 * Example:
 *	// First list entry is children.next; convert back to child.
 *	child = ccan_list_entry(parent->children.n.next, struct child, list);
 *
 * See Also:
 *	ccan_list_top(), ccan_list_for_each()
 */
#define ccan_list_entry(n, type, member) ccan_container_of(n, type, member)

/**
 * ccan_list_top - get the first entry in a list
 * @h: the ccan_list_head
 * @type: the type of the entry
 * @member: the ccan_list_node member of the type
 *
 * If the list is empty, returns NULL.
 *
 * Example:
 *	struct child *first;
 *	first = ccan_list_top(&parent->children, struct child, list);
 *	if (!first)
 *		printf("Empty list!\n");
 */
#define ccan_list_top(h, type, member)					\
	((type *)ccan_list_top_((h), ccan_list_off_(type, member)))

static inline const void *ccan_list_top_(const struct ccan_list_head *h, size_t off)
{
	if (ccan_list_empty(h))
		return NULL;
	return (const char *)h->n.next - off;
}

/**
 * ccan_list_pop - remove the first entry in a list
 * @h: the ccan_list_head
 * @type: the type of the entry
 * @member: the ccan_list_node member of the type
 *
 * If the list is empty, returns NULL.
 *
 * Example:
 *	struct child *one;
 *	one = ccan_list_pop(&parent->children, struct child, list);
 *	if (!one)
 *		printf("Empty list!\n");
 */
#define ccan_list_pop(h, type, member)					\
	((type *)ccan_list_pop_((h), ccan_list_off_(type, member)))

static inline const void *ccan_list_pop_(const struct ccan_list_head *h, size_t off)
{
	struct ccan_list_node *n;

	if (ccan_list_empty(h))
		return NULL;
	n = h->n.next;
	ccan_list_del(n);
	return (const char *)n - off;
}

/**
 * ccan_list_tail - get the last entry in a list
 * @h: the ccan_list_head
 * @type: the type of the entry
 * @member: the ccan_list_node member of the type
 *
 * If the list is empty, returns NULL.
 *
 * Example:
 *	struct child *last;
 *	last = ccan_list_tail(&parent->children, struct child, list);
 *	if (!last)
 *		printf("Empty list!\n");
 */
#define ccan_list_tail(h, type, member) \
	((type *)ccan_list_tail_((h), ccan_list_off_(type, member)))

static inline const void *ccan_list_tail_(const struct ccan_list_head *h, size_t off)
{
	if (ccan_list_empty(h))
		return NULL;
	return (const char *)h->n.prev - off;
}

/**
 * ccan_list_for_each - iterate through a list.
 * @h: the ccan_list_head (warning: evaluated multiple times!)
 * @i: the structure containing the ccan_list_node
 * @member: the ccan_list_node member of the structure
 *
 * This is a convenient wrapper to iterate @i over the entire list.  It's
 * a for loop, so you can break and continue as normal.
 *
 * Example:
 *	ccan_list_for_each(&parent->children, child, list)
 *		printf("Name: %s\n", child->name);
 */
#define ccan_list_for_each(h, i, member)					\
	ccan_list_for_each_off(h, i, ccan_list_off_var_(i, member))

/**
 * ccan_list_for_each_rev - iterate through a list backwards.
 * @h: the ccan_list_head
 * @i: the structure containing the ccan_list_node
 * @member: the ccan_list_node member of the structure
 *
 * This is a convenient wrapper to iterate @i over the entire list.  It's
 * a for loop, so you can break and continue as normal.
 *
 * Example:
 *	ccan_list_for_each_rev(&parent->children, child, list)
 *		printf("Name: %s\n", child->name);
 */
#define ccan_list_for_each_rev(h, i, member)					\
	ccan_list_for_each_rev_off(h, i, ccan_list_off_var_(i, member))

/**
 * ccan_list_for_each_rev_safe - iterate through a list backwards,
 * maybe during deletion
 * @h: the ccan_list_head
 * @i: the structure containing the ccan_list_node
 * @nxt: the structure containing the ccan_list_node
 * @member: the ccan_list_node member of the structure
 *
 * This is a convenient wrapper to iterate @i over the entire list backwards.
 * It's a for loop, so you can break and continue as normal.  The extra
 * variable * @nxt is used to hold the next element, so you can delete @i
 * from the list.
 *
 * Example:
 *	struct child *next;
 *	ccan_list_for_each_rev_safe(&parent->children, child, next, list) {
 *		printf("Name: %s\n", child->name);
 *	}
 */
#define ccan_list_for_each_rev_safe(h, i, nxt, member)			\
	ccan_list_for_each_rev_safe_off(h, i, nxt, ccan_list_off_var_(i, member))

/**
 * ccan_list_for_each_safe - iterate through a list, maybe during deletion
 * @h: the ccan_list_head
 * @i: the structure containing the ccan_list_node
 * @nxt: the structure containing the ccan_list_node
 * @member: the ccan_list_node member of the structure
 *
 * This is a convenient wrapper to iterate @i over the entire list.  It's
 * a for loop, so you can break and continue as normal.  The extra variable
 * @nxt is used to hold the next element, so you can delete @i from the list.
 *
 * Example:
 *	ccan_list_for_each_safe(&parent->children, child, next, list) {
 *		ccan_list_del(&child->list);
 *		parent->num_children--;
 *	}
 */
#define ccan_list_for_each_safe(h, i, nxt, member)				\
	ccan_list_for_each_safe_off(h, i, nxt, ccan_list_off_var_(i, member))

/**
 * ccan_list_next - get the next entry in a list
 * @h: the ccan_list_head
 * @i: a pointer to an entry in the list.
 * @member: the ccan_list_node member of the structure
 *
 * If @i was the last entry in the list, returns NULL.
 *
 * Example:
 *	struct child *second;
 *	second = ccan_list_next(&parent->children, first, list);
 *	if (!second)
 *		printf("No second child!\n");
 */
#define ccan_list_next(h, i, member)						\
	((ccan_list_typeof(i))ccan_list_entry_or_null(ccan_list_debug(h,		\
					    __FILE__ ":" ccan_stringify(__LINE__)), \
					    (i)->member.next,		\
					    ccan_list_off_var_((i), member)))

/**
 * ccan_list_prev - get the previous entry in a list
 * @h: the ccan_list_head
 * @i: a pointer to an entry in the list.
 * @member: the ccan_list_node member of the structure
 *
 * If @i was the first entry in the list, returns NULL.
 *
 * Example:
 *	first = ccan_list_prev(&parent->children, second, list);
 *	if (!first)
 *		printf("Can't go back to first child?!\n");
 */
#define ccan_list_prev(h, i, member)						\
	((ccan_list_typeof(i))ccan_list_entry_or_null(ccan_list_debug(h,		\
					    __FILE__ ":" ccan_stringify(__LINE__)), \
					    (i)->member.prev,		\
					    ccan_list_off_var_((i), member)))

/**
 * ccan_list_append_list - empty one list onto the end of another.
 * @to: the list to append into
 * @from: the list to empty.
 *
 * This takes the entire contents of @from and moves it to the end of
 * @to.  After this @from will be empty.
 *
 * Example:
 *	struct ccan_list_head adopter;
 *
 *	ccan_list_append_list(&adopter, &parent->children);
 *	assert(ccan_list_empty(&parent->children));
 *	parent->num_children = 0;
 */
#define ccan_list_append_list(t, f) ccan_list_append_list_(t, f,			\
				   __FILE__ ":" ccan_stringify(__LINE__))
static inline void ccan_list_append_list_(struct ccan_list_head *to,
				     struct ccan_list_head *from,
				     const char *abortstr)
{
	struct ccan_list_node *from_tail = ccan_list_debug(from, abortstr)->n.prev;
	struct ccan_list_node *to_tail = ccan_list_debug(to, abortstr)->n.prev;

	/* Sew in head and entire list. */
	to->n.prev = from_tail;
	from_tail->next = &to->n;
	to_tail->next = &from->n;
	from->n.prev = to_tail;

	/* Now remove head. */
	ccan_list_del(&from->n);
	ccan_list_head_init(from);
}

/**
 * ccan_list_prepend_list - empty one list into the start of another.
 * @to: the list to prepend into
 * @from: the list to empty.
 *
 * This takes the entire contents of @from and moves it to the start
 * of @to.  After this @from will be empty.
 *
 * Example:
 *	ccan_list_prepend_list(&adopter, &parent->children);
 *	assert(ccan_list_empty(&parent->children));
 *	parent->num_children = 0;
 */
#define ccan_list_prepend_list(t, f) ccan_list_prepend_list_(t, f, CCAN_LIST_LOC)
static inline void ccan_list_prepend_list_(struct ccan_list_head *to,
				      struct ccan_list_head *from,
				      const char *abortstr)
{
	struct ccan_list_node *from_tail = ccan_list_debug(from, abortstr)->n.prev;
	struct ccan_list_node *to_head = ccan_list_debug(to, abortstr)->n.next;

	/* Sew in head and entire list. */
	to->n.next = &from->n;
	from->n.prev = &to->n;
	to_head->prev = from_tail;
	from_tail->next = to_head;

	/* Now remove head. */
	ccan_list_del(&from->n);
	ccan_list_head_init(from);
}

/* internal macros, do not use directly */
#define ccan_list_for_each_off_dir_(h, i, off, dir)				\
	for (i = 0, \
	     i = ccan_list_node_to_off_(ccan_list_debug(h, CCAN_LIST_LOC)->n.dir, \
				   (off));				\
	ccan_list_node_from_off_((void *)i, (off)) != &(h)->n;		\
	i = ccan_list_node_to_off_(ccan_list_node_from_off_((void *)i, (off))->dir, \
			      (off)))

#define ccan_list_for_each_safe_off_dir_(h, i, nxt, off, dir)		\
	for (i = 0, \
	     i = ccan_list_node_to_off_(ccan_list_debug(h, CCAN_LIST_LOC)->n.dir, \
				   (off)),				\
	nxt = ccan_list_node_to_off_(ccan_list_node_from_off_(i, (off))->dir,	\
				(off));					\
	ccan_list_node_from_off_(i, (off)) != &(h)->n;			\
	i = nxt,							\
	nxt = ccan_list_node_to_off_(ccan_list_node_from_off_(i, (off))->dir,	\
				(off)))

/**
 * ccan_list_for_each_off - iterate through a list of memory regions.
 * @h: the ccan_list_head
 * @i: the pointer to a memory region which contains list node data.
 * @off: offset(relative to @i) at which list node data resides.
 *
 * This is a low-level wrapper to iterate @i over the entire list, used to
 * implement all other, more high-level, for-each constructs. It's a for loop,
 * so you can break and continue as normal.
 *
 * WARNING! Being the low-level macro that it is, this wrapper doesn't know
 * nor care about the type of @i. The only assumption made is that @i points
 * to a chunk of memory that at some @offset, relative to @i, contains a
 * properly filled `struct ccan_list_node' which in turn contains pointers to
 * memory chunks and it's turtles all the way down. With all that in mind
 * remember that given the wrong pointer/offset couple this macro will
 * happily churn all you memory until SEGFAULT stops it, in other words
 * caveat emptor.
 *
 * It is worth mentioning that one of legitimate use-cases for that wrapper
 * is operation on opaque types with known offset for `struct ccan_list_node'
 * member(preferably 0), because it allows you not to disclose the type of
 * @i.
 *
 * Example:
 *	ccan_list_for_each_off(&parent->children, child,
 *				offsetof(struct child, list))
 *		printf("Name: %s\n", child->name);
 */
#define ccan_list_for_each_off(h, i, off)                                    \
	ccan_list_for_each_off_dir_((h),(i),(off),next)

/**
 * ccan_list_for_each_rev_off - iterate through a list of memory regions backwards
 * @h: the ccan_list_head
 * @i: the pointer to a memory region which contains list node data.
 * @off: offset(relative to @i) at which list node data resides.
 *
 * See ccan_list_for_each_off for details
 */
#define ccan_list_for_each_rev_off(h, i, off)                                    \
	ccan_list_for_each_off_dir_((h),(i),(off),prev)

/**
 * ccan_list_for_each_safe_off - iterate through a list of memory regions, maybe
 * during deletion
 * @h: the ccan_list_head
 * @i: the pointer to a memory region which contains list node data.
 * @nxt: the structure containing the ccan_list_node
 * @off: offset(relative to @i) at which list node data resides.
 *
 * For details see `ccan_list_for_each_off' and `ccan_list_for_each_safe'
 * descriptions.
 *
 * Example:
 *	ccan_list_for_each_safe_off(&parent->children, child,
 *		next, offsetof(struct child, list))
 *		printf("Name: %s\n", child->name);
 */
#define ccan_list_for_each_safe_off(h, i, nxt, off)                          \
	ccan_list_for_each_safe_off_dir_((h),(i),(nxt),(off),next)

/**
 * ccan_list_for_each_rev_safe_off - iterate backwards through a list of
 * memory regions, maybe during deletion
 * @h: the ccan_list_head
 * @i: the pointer to a memory region which contains list node data.
 * @nxt: the structure containing the ccan_list_node
 * @off: offset(relative to @i) at which list node data resides.
 *
 * For details see `ccan_list_for_each_rev_off' and `ccan_list_for_each_rev_safe'
 * descriptions.
 *
 * Example:
 *	ccan_list_for_each_rev_safe_off(&parent->children, child,
 *		next, offsetof(struct child, list))
 *		printf("Name: %s\n", child->name);
 */
#define ccan_list_for_each_rev_safe_off(h, i, nxt, off)                      \
	ccan_list_for_each_safe_off_dir_((h),(i),(nxt),(off),prev)

/* Other -off variants. */
#define ccan_list_entry_off(n, type, off)		\
	((type *)ccan_list_node_from_off_((n), (off)))

#define ccan_list_head_off(h, type, off)		\
	((type *)ccan_list_head_off((h), (off)))

#define ccan_list_tail_off(h, type, off)		\
	((type *)ccan_list_tail_((h), (off)))

#define ccan_list_add_off(h, n, off)                 \
	ccan_list_add((h), ccan_list_node_from_off_((n), (off)))

#define ccan_list_del_off(n, off)                    \
	ccan_list_del(ccan_list_node_from_off_((n), (off)))

#define ccan_list_del_from_off(h, n, off)			\
	ccan_list_del_from(h, ccan_list_node_from_off_((n), (off)))

/* Offset helper functions so we only single-evaluate. */
static inline void *ccan_list_node_to_off_(struct ccan_list_node *node, size_t off)
{
	return (void *)((char *)node - off);
}
static inline struct ccan_list_node *ccan_list_node_from_off_(void *ptr, size_t off)
{
	return (struct ccan_list_node *)((char *)ptr + off);
}

/* Get the offset of the member, but make sure it's a ccan_list_node. */
#define ccan_list_off_(type, member)					\
	(ccan_container_off(type, member) +				\
	 ccan_check_type(((type *)0)->member, struct ccan_list_node))

#define ccan_list_off_var_(var, member)			\
	(ccan_container_off_var(var, member) +		\
	 ccan_check_type(var->member, struct ccan_list_node))

#if defined(HAVE_TYPEOF) && HAVE_TYPEOF
#define ccan_list_typeof(var) typeof(var)
#else
#define ccan_list_typeof(var) void *
#endif

/* Returns member, or NULL if at end of list. */
static inline void *ccan_list_entry_or_null(const struct ccan_list_head *h,
				       const struct ccan_list_node *n,
				       size_t off)
{
	if (n == &h->n)
		return NULL;
	return (char *)n - off;
}

#endif /* CCAN_LIST_H */
