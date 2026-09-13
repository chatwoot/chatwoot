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
Keep the original target set and eligibility conditions when repairing a program.
Database null is distinct from Scheme `#f` and the empty list: use
`(nil? (get conversation "assignee_id"))` to test for an unassigned conversation.
Use `null?` only for empty lists. Successful action receipts contain `operation`,
`target`, `status`, `result`, `effect`, and `at`, not an `id` field.

Keep full collections in bindings and return counts or compact findings from
`execute`. Model-facing tool replies have an 8,000-byte limit. Larger values
remain intact under a saved workspace reference; the reply contains a labeled
preview, size, and reference. There is no implicit `__last_result` variable.

```scheme
; Use the actual reference returned by the tool.
(define records (recall "workspace-reference"))
(length records)
(slice records 0 10)
; Hash results can be explored with keys and get.
(slice (keys (recall "workspace-reference")) 0 10)
```

`apropos` returns concise matches without saved values or captured environments.
`describe` exposes a single contract or binding metadata; saved function bodies
remain inspectable without dumping their captured data.

Workers return compact results plus `input_ref`, `receipts_ref`, and
`receipt_count`. Recall these references in the parent workspace when needed.
Large worker inputs are saved in the worker's workspace and passed by reference.
Tool-free `reason` rejects inputs over 16,000 bytes so callers must batch data,
not silently reason from a preview.

Model-visible prior history is bounded to 24,000 bytes, with oversized messages
available by reference. A per-chat guard checks the serialized messages, tools,
and response schema before each model request, including recursive tool rounds.
It stops at 120,000 bytes with a resumable error; it does not automatically replay
actions or retry. This is a conservative byte budget, not tokenizer-based
accounting or a guarantee for models with smaller context windows.

Use [WootQL](wootql.md) for structured filtering, joins, grouping, and ranking
without loading every record into Scheme. See [the top-contacts example](../script/apropos/top_contacts.scm).
`query-run` returns rows and a `next_offset`, distinct from `search`'s keyset cursor.
For ad hoc English requests, `(query-data "retrieval request")` invokes the
read-only WootQL specialist. Recall its `result_ref` for full rows and call
`(query-next next_cursor)` for remaining pages without another LLM call. The
specialist has its own query-focused prompt, not the general Apropos prompt.

## Function library

```scheme
(save-function "top-contacts" "Contacts ranked by conversation count"
  '(lambda (n)
     (query-run
       "conversations | summarize count() by contact_id | sort count desc, contact_id asc | take $n"
       (hash "n" n))))

(top-contacts 5)
```

Save a **quoted lambda**, not a closure. Only code and its description persist,
not the current workspace or captured lexical environment. Pass changing data
as arguments; do not embed customer records, credentials, or task-specific IDs.
Saving does not execute the function body. Functions may call one another and
use the existing Scheme primitives, with the same execution and token budgets.

The library is scoped to the current user and account, available in new chats
and workers. `apropos` discovers descriptions and signatures; `describe` includes
the body without captured data. Same-name saves replace the library version;
already-running runtimes retain their loaded version until the next turn.
Session bindings can shadow library names, so avoid reusing those names in
`define`. Built-in catalog names cannot be overwritten by library saves.
Each user/account can save 100 functions of at most 16 KB encoded code each.

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
