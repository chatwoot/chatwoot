# WootQL

WootQL is Apropos's read-only query language. Scheme remains the programming
environment for functions, reasoning, delegation, and actions.

```text
conversations
| where status = "open"
| where created_at >= now() - 7d
| summarize count() by inbox.id, inbox.name
| sort count desc
| take 10
```

## Pipeline

The lexer/parser produce an ordered AST, without resolving names or permissions.
The resolver checks names and types against the catalog and creates scans from
`DataAccess.scope`. Every scan, including joined resources, retains its trusted
account scope. Those scopes are not WootQL predicates and cannot be removed by
the query. Current access remains administrator-only with Captain enabled.

The resolver-created plan is compiled into SQL. Values are separate Rails bind
parameters; identifiers are resolved fields or parsed aliases and adapter-quoted.
The agent cannot submit SQL, a serialized plan, or an `AuthorizedScan` object.
There are no raw expressions, arbitrary function calls, CTEs, or SQL subqueries.

Each stage wraps its input. `take 10 | where ...` filters ten rows;
`where ... | take 10` selects ten matching rows. Joins are equality joins, not
arbitrary SQL conditions. Both sides must be exposed, scoped resources.

## Syntax

Available resources currently include contacts, conversations, messages, inboxes,
teams, labels, agents, published articles, and approved FAQs. This is an explicit
logical catalog, not access to every database table. Inspect `(describe "resources")`
or the playground's resource browser for the current fields and relationships.
For example, `labels | take 5` lists account labels; their name field is `title`.
Conversations also expose a `labels` string list. Use
`conversations | where labels contains "refund"` for exact label membership.
On text fields, `contains` remains a case-insensitive substring search.

| Stage | Example |
| --- | --- |
| Filter | `where status = "open" and (priority = "urgent" or assignee_id is null)` |
| Project/rename | `project id, display_id, inbox.name as inbox_name` |
| Inner join | `join contacts as contact on contact_id = contact.id` |
| Left join | `join left contacts as contact on contact_id = contact.id` |
| Aggregate | `summarize count() as total, count_distinct(contact_id) as customers by inbox_id` |
| Order | `sort total desc, inbox_id asc` |
| Limit | `take 5` |

Filters support `=`, `!=`, `>`, `>=`, `<`, `<=`, `contains`, `in (value, ...)`,
`is null`, `is not null`, `is empty`, `is not empty`, and `and`/`or`/`not` with parentheses. `not` binds more
tightly than `and`, which binds more tightly than `or`. Null follows SQL's
three-valued comparison semantics; use explicit null tests, not `= null`.

### Null versus empty

`is null` tests absence on any field type. `is empty` tests zero length on text
or lists only. Numbers, booleans, dates, and JSON reject empty tests. Whitespace
is not empty; neither are lists containing an empty string or null element.

| Value | is null | is not null | is empty | is not empty |
| --- | --- | --- | --- | --- |
| null | true | false | unknown | unknown |
| `[]` or `""` | false | true | true | false |
| Nonempty list or text (including whitespace) | false | true | false | true |

`where` retains only true. Negating unknown still yields unknown, so neither
empty test includes null. Use `field is null or field is empty` to include both.
List emptiness compiles to PostgreSQL `CARDINALITY(field) = 0`; text emptiness
uses `CHAR_LENGTH(field) = 0`. Nonempty uses `> 0`, without null coercion.
See [PostgreSQL array functions](https://www.postgresql.org/docs/current/functions-array.html).

Conversation `labels` is a **non-null list**, decoded into a real array for
Scheme and JSON. No labels is `[]`, never null or the string `"{}"`.
`labels is null` therefore matches no base conversations; `labels is not null`
matches all of them. A missing conversation on the right of a left join yields
null for its fields, including labels; that does not represent an unlabeled conversation.

```text
conversations
| where status = "open" and created_at >= now() - 15d
| where labels is empty
| project id, display_id, labels
```

Values are double-quoted strings, numbers, booleans, named `$parameters`,
`now()`, or `now() - 7d` (units: ms, s, m, h, d, w). Relative durations are
bounded to 100 years. Timestamp strings must be ISO 8601. Enums use their names,
such as `"open"`; enum sorting is lexical, not an implicit business ranking.

Aggregates are `count`, `count_distinct`, `sum`, `avg`, `min`, and `max`.
Only `count()` may omit its field. Without `by`, aggregation covers all rows.
Default aggregate names are `count`, `sum_id`, etc.; use `as` for clarity.

Declared to-one paths such as `inbox.name` become scoped left joins. To-many
relationships require an explicit join so row multiplication is visible.
After projection/aggregation, only retained fields exist. Resolve relationship
paths before those stages, or explicitly join using retained IDs afterwards.

## Scheme and limits

Captain Ask calls `(query-data "request")` inside Scheme for English retrieval requests.
The primary agent has discovery tools and `execute`, not a separate query tool;
Scheme is the common execution path for queries, reasoning, and actions.
It runs a fresh RubyLLM chat with the WootQL reference and current typed resource
schema. Its only tool is `submit_query(source)`, which uses this same query engine.
The specialist cannot access the parent chat, read workspace bindings, delegate,
or perform actions. Validation errors allow repair, with at most four model
requests under the existing context-byte cap. Each specialist call consumes the
shared agent-call budget; every query attempt/page consumes the shared query budget.

The first successful submission halts the specialist. Results come from the
engine, not model-authored JSON. It returns `source`, `result_ref`, `count`,
`offset`, `next_cursor`, `query_exhausted`, and a bounded `preview` to the primary.
Full rows stay in the workspace. `count` is this page's row count, not a total.
`query_exhausted` means this query has no further pages, not that the user's task
has been completed. The primary still checks scope and interprets the evidence.

```scheme
(define page (query-data "Get incoming customer messages for all open conversations"))
(define messages (recall (get page "result_ref")))
; When next_cursor is not #f, fetch more without another model call:
(define next-page (query-next (get page "next_cursor")))
```

Each page contains at most 200 rows. Call `query-next` only when its cursor is not
`#f`; each returned page has a separate result reference. Cursors persist with the
session and retain the query and offset. Pagination reads live data, not a snapshot.
The caller must follow all pages before claiming account-wide coverage.
Use `(query-map function first-page)` to process pages without writing pagination
loops. It invokes the supplied Scheme function with each nonempty page's full
rows. Page findings stay in the workspace as `result_refs`, with coverage counts
and a `progress_ref`. Use `(batches rows 50)` inside the callback to split reasoning
inputs by both row count and the 16 KB input limit. These helpers do not reset any
Scheme, query, or model-call budgets.

The specialist must report unsupported requirements, including latest N per group
or nested related records, rather than executing a partial query. Scheme can
request ordered flat rows and compose `group-by` with `take`. Group boundaries
can cross pages, so grouping each page separately does not give global top N.
The specialist submission tool uses literal values, which the compiler binds;
direct `query-run` still supports scalar named parameters for reusable functions.

The integration uses RubyLLM's [tools and halting](https://rubyllm.com/tools/#halting-execution),
verified against the installed 1.15 API. No database rows are sent back through
the specialist model after successful execution.

```scheme
(query-run
  "conversations | where contact_id = $contact | project id, status"
  (hash "contact" contact-id)
  0)
```

Parameters and offset are optional. Parameters supply values, never names or
syntax. Results are `{items, next_offset}` with at most 200 rows per page and
`#f` at the end. Keep the source and parameters unchanged when paging. Pagination
is over live data, not a snapshot. Retain unique ordering keys when projecting.
Query rows have selected fields, not implicit `ref` objects; build refs from
known entity names and database IDs when fetching records or performing actions.

Limits: 32 KB source, 4096 tokens, 32 stages, 64 predicate terms, 16-level
predicate/path nesting, 8 joins, 100 output columns, 32 KB parameters,
100000 maximum offset/take, 5 seconds per query, and 100 query executions per
turn shared with delegated workers. Existing model-output/context caps still
apply, so large query results remain in the workspace with bounded previews.

## Development playground

In development, **Developers > WootQL** provides an editor, examples, result
pages, generated SQL, and bind values. It runs the same parser/resolver/compiler.
The UI route/menu are excluded from production builds, and the HTTP endpoint
is registered only in Rails development with an additional environment check.
It retains the same administrator/Captain access checks as Apropos.

Relevant implementation APIs: [Rails select_all and bind parameters](https://api.rubyonrails.org/v7.2.3/classes/ActiveRecord/ConnectionAdapters/DatabaseStatements.html#method-i-select_all),
[PostgreSQL transaction-local settings](https://www.postgresql.org/docs/current/sql-set.html),
[exact array membership](https://www.postgresql.org/docs/current/functions-comparisons.html#FUNCTIONS-COMPARISONS-ANY-SOME),
and [Vite development constants](https://vite.dev/guide/env-and-mode#built-in-constants).
