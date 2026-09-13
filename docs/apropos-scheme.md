# Apropos Scheme

The runtime is a Scheme subset, with account-scoped Chatwoot primitives.
It is not a complete R7RS implementation. Binding and branching semantics are
based on [R7RS sections 4.2 and 5.3](https://standards.scheme.org/official/r7rs.pdf).

Scheme is the execution backbone. The main agent discovers capabilities and
writes programs through `execute`; data queries, reasoning workers, and actions
are functions inside those programs. WootQL is the retrieval facility, not a
second orchestrator. The existing interpreter and account boundaries remain.

## Language

- Global and local `define`, including `(define (name args) body)`.
- Lexical closures, `lambda`, `let`, named `let`, `let*`, and `letrec`.
- `if`, short-circuit `and` / `or`, `begin`, `quote`, and basic `cond`.
- Tail calls between Scheme functions do not grow the Ruby call stack.
- Lists, hashes, `map`, `filter`, `fold`, and arithmetic.
- `cons` (proper lists only), `reverse`, and `apply` with a final argument list.
- `(group-by items key-function)` returns `{key, items}` groups in first-seen
  order, preserving item order within each group.
- `(count-by items key-function)` returns `{key, count}` rows in first-seen order.
- `(sort-by items "field" "desc")` sorts by a field, preserving input order on ties.
  Direction defaults to `"asc"`; field values must be comparable.
- `(take items n)` returns at most n items.
- `(batches items n)` partitions in order, with at most n items and 16,000 JSON
  bytes per batch. Nothing is dropped or truncated. A single item over the byte
  limit raises; project smaller fields or delegate that item by reference.

Only `#f` is false. An empty list, zero, and an empty string are truthy.
Search and relationship pages end with `next_cursor = #f`, not zero or an empty list.

Use `describe("collections")` to get all collection signatures, or describe an
individual primitive. `map` and `filter` take the function first; `count-by`
and `group-by` take records first. `fold` calls its callback with the accumulator
first and item second. Existing signatures are unchanged so saved functions keep
working. `sort-by` accepts a field-name string, not a function.
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

## Page processing

`query-map` runs a Scheme function for each nonempty page, following query cursors
without further query-generation calls. It stores each successful page result
and returns `result_refs`, `processed_rows`, `processed_pages`, `progress_ref`,
`status`, and `query_exhausted`. The latter describes query coverage, not whether
the function fulfilled the user's request.

```scheme
(define first-page
  (query-data "Get all incoming non-private messages for open conversations, with id, conversation_id, content, ordered by id"))

(define summarize-page
  (lambda (rows)
    (map
      (lambda (batch)
        (reason batch
          "Extract compact customer needs with conversation IDs. Do not invent missing context."
          (hash "findings" "string_list")))
      (batches rows 50))))

(define processed (query-map summarize-page first-page))
(define page-findings (map recall (get processed "result_refs")))
; Merge findings by conversation ID before counting customers or requests.
; Use batches again if the findings exceed the reason-input limit.
(get processed "processed_rows")
```

The agent can write and save a different processing function without changing
the runtime. `query-map` does not choose an analysis or take actions on its own.
Its callback uses the normal Scheme execution budget and shared tool budgets.
Pages can split conversations, so page-local groups must not be treated as
complete conversations. For global top N, combine ordered rows before grouping
or explicitly carry group state across pages in a Scheme binding.

On failure, the error includes a saved `progress_ref`. Recall it to inspect
`result_refs`, `page`, and `page_processed`. If `page_processed` is true, that
callback completed and the error occurred while fetching the next page. Continue
from its `next_cursor`; do not replay the completed callback. If false, inspect
receipts and existing bindings before retrying: the failing callback may have
partially performed actions. No callback is automatically retried. Results of
earlier batches within a failing callback require explicit Scheme bindings to
survive; only fully completed page results are retained by `query-map` itself.

Progress uses the existing session workspace and is saved when the turn finishes,
including handled failures. This is not a crash-durable job queue or an exactly-once
execution guarantee. No schedules, background continuations, or new permissions
are introduced.

## Function library

Before assigning conversations, traverse their inbox's eligible agent pool:

```scheme
(define inbox-page (related conversation-ref "inbox"))
(define inbox-ref (get (car (get inbox-page "items")) "ref"))
(define eligible-page (related inbox-ref "assignable_agents"))
```

Follow `next_cursor` until `#f`. `assignable_agents` calls the same inbox
eligibility method used by `assign-agent`, including eligible administrators,
and intersects its results with account-scoped agents. This is a scoped
relationship available through `related`, not a WootQL join. Intersect the
returned agent IDs with any user-selected pool before planning assignments.
The write still rechecks eligibility because membership can change.

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

## Composable reasoning and recovery

Core string, object, and predicate implementations share a registry with their
discoverable contracts. Inspect `strings`, `objects`, or `predicates` with
`describe`. Use `string-append`, `string-join`, and `number->string`; there is no
generic `string` function. This remains a documented Scheme subset, not a full
Scheme implementation.

Declare result shapes before fetching data:

```scheme
(define findings-schema
  (schema-check
    (hash "items"
      (list (hash "conversation_id" "integer"
                  "need" "string"
                  "category" (list "billing" "technical" "unclear"))))))
; Fetch and save inputs in a separate execute call, then:
(define findings (reason saved-input "Identify each customer's need" findings-schema))
```

The compact schema accepts primitive types (`string`, `boolean`, `integer`,
`number`), primitive arrays (`string_list`, etc.), string enums, nested hashes,
and one-element lists of hashes for arrays of objects. All fields are required;
extra fields are rejected. Limits are 12 fields per object, 64 fields total,
16 KB schema, 64 KB result, and 200 items per result array. Nesting depth is at
most four edges from the root, counting object fields and array elements.

`schema-check` validates without calling a model. Literal schemas in programs
are checked before execution, including those inside function bodies and dead
branches. Preflight skips quoted code and conservatively skips shadowed or
dynamic expressions. It is not a type checker: explicitly check dynamic schemas
before retrieval. The compiled JSON Schema passes through the existing SDK's
`with_schema` integration and is validated locally with JSONSchemer.

Tool-free `reason` receives a focused extraction/aggregation prompt, not the
coordinator's orchestration prompt. Invalid results report field paths and save
the rejected output in the workspace for inspection. Shape validation does not
prove factual correctness or that every input record was covered.

For string arrays use `"string_list"`, not `(list "string")`. The latter is a
valid enum whose only allowed value is the literal `"string"`. If an incorrect
contract forced meaningless findings, correct the schema and rerun reasoning
on the saved original inputs, then recompute dependent summaries. Changing
those findings from strings to lists does not repair their meaning.

Execution errors report `completed_bindings`, `failed_binding`, and
`available_bindings`, without dumping their data. Reuse saved inputs to repair
the failed stage. A failed reassignment retains the old value, so do not treat
that binding as a successful new result. Only completed global assignments are
preserved, not unfinished local computations. No actions are automatically
retried, and prior actions are not rolled back. Query, token, and evaluation
budgets remain in force across repairs as applicable.

## Session persistence

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
