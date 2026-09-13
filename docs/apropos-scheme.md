# Apropos Scheme

The runtime is a Scheme subset, with account-scoped Chatwoot primitives.
It is not a complete R7RS implementation. Binding and branching semantics are
based on [R7RS sections 4.2 and 5.3](https://standards.scheme.org/official/r7rs.pdf).

## Language

- Global and local `define`, including `(define (name args) body)`.
- Lexical closures, `lambda`, `let`, named `let`, `let*`, and `letrec`.
- `if`, short-circuit `and` / `or`, `begin`, `quote`, and basic `cond`.
- Tail calls between Scheme functions do not grow the Ruby call stack.
- Lists, hashes, `map`, `filter`, `fold`, and arithmetic.
- `(count-by items key-function)` returns `{key, count}` rows in first-seen order.
- `(sort-by items "field" "desc")` sorts by a field, preserving input order on ties.
  Direction defaults to `"asc"`; field values must be comparable.
- `(take items n)` returns at most n items.

Only `#f` is false. An empty list, zero, and an empty string are truthy.
Search and relationship pages end with `next_cursor = #f`, not zero or an empty list.

Use `describe("collections")` to get all collection signatures, or describe an
individual primitive. `map` and `filter` take the function first; `count-by`
takes records first. `sort-by` accepts a field-name string, not a function.
Primitive failures return the failing name and its contract to the agent.
Repair only the failing expression and inspect receipts before retrying writes.

Keep full collections in bindings and return counts or compact findings from
`execute`. This is agent guidance, not result truncation: results remain intact.
There is no implicit `__last_result` variable.

See [the top-contacts example](../script/apropos/top_contacts.scm) for pagination,
counting, ranking, and fetching the five resulting contacts. It counts contacts
with conversations and runs entirely deterministically, without per-record LLM calls.

## Saved sessions

Global bindings and reachable lexical environments persist across chat turns,
including recursive closures. Locally defined names do not leak into globals.
Old saved closures remain readable. Saved programs are never replayed on load.

Previously generated helpers are not automatically rewritten. If a helper used
the wrong pagination sentinel, inspect and redefine it, or start a new chat.

## Limits

No macros, `set!`, host-language eval, file access, variadic Scheme lambdas,
or `cond =>` clauses. Programs retain the existing 32 KB source, 100,000
evaluation-step, and non-tail nesting limits. Tail loops still consume that
evaluation budget. Host operations retain their account and permission checks.
