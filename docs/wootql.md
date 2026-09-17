# WootQL in Captain Ask

WootQL is the read-only query language implemented in `lib/wootql`.
The primary agent writes queries itself. Scheme remains the execution backbone
for queries, transformations, reasoning calls, workers, and actions. There is no
English-to-WootQL specialist or second query-generation model.

```text
conversations
| where status = "open"
| where labels contains "refund"
| sort created_at desc, id desc
| take 10
| return id, display_id, status, contact.name as customer
```

## Discovery and execution

Inspect `describe("wootql")` for syntax and `describe("resources")` or an
individual resource for fields, types, enum names and relationships. Both use
the same built-in Chatwoot catalog as execution. Not every Rails relationship
is a WootQL join: to-one field paths are supported, to-many requires an explicit
join, and scoped/polymorphic relationships use the separate traversal tools.

```scheme
(define page
  (query-run
    "conversations | where contact_id in $ids | return id, status | sort id"
    (hash "ids" (list 12 34))))
(define outcomes
  (query-map (lambda (rows)
               (map (lambda (row) (get row "id")) rows))
             page))
```

The stages are `where`, `return`, `join`, `summarize`, `sort` and `take`.
`return` selects/renames fields, does not end the pipeline, and removes
unselected fields from subsequent stages. Keep identity and ordering keys.
`take 10 | where ...` filters ten rows; `where ... | take 10` takes ten matches.

Comparisons accept compatible fields or values. `in $ids` takes an array,
`in (1, $id)` takes scalars, and an empty array matches nothing. Values are
bound parameters, never SQL syntax. Double-quoted strings are literals.
Relative time supports `now() - 7d` with ms/s/m/h/d/w units.

`is null` tests absence. `is empty` tests zero length of text/lists only.
Neither empty test includes null; whitespace is not empty. Conversation labels
are non-null lists: no labels is an empty list, not null. `contains` means exact
membership for labels and case-insensitive substring matching for text.
A missing right-side record in a left join can have null fields.

Aggregates are count, count_distinct, sum, avg, min and max.
Only count() omits its field. After summarize only grouping keys and aggregate
outputs remain. Equality joins operate on authorized resources, not raw tables.

## Result contracts

- A query page has `kind: page`, `items` (list), `item_count` (integer),
  `has_more` (boolean), `query_ref`, `offset` and `next_offset`.
  The count is this page's size, not the total matching or analyzed records.
- `query-next` accepts that page and returns another page or `#f`.
  A query handle retains the prepared plan, parameters and time anchor for the
  current turn. Saved items persist across turns; the live handle does not.
- `query-map` calls a procedure with every nonempty page's full item list.
  It returns `kind: processing_result`, status, `processed_item_count`,
  `processed_page_count`, `results`, `progress_ref`, and `query_exhausted`.
  Each result is `{kind: stored_value, ref, value_info}`; use recall on its ref.
- On failure, progress retains completed results, the current page and
  `page_processed`. Callbacks are not retried automatically. Inspect receipts
  before deciding whether to retry a callback that may have performed actions.
- Oversized model output becomes `{kind: preview, complete: false, ref,
  value_info, preview, ...}`. The full value remains in Scheme. The preview
  is not evidence that every item was read or analyzed.
- Counts describe retrieval or completed callbacks, not whether the callback
  used an LLM or fulfilled the user's semantic task.

Use `batches` inside callbacks to respect reasoning-input limits. Group boundaries
can cross pages. Live offset pagination is not a snapshot: concurrent changes
can shift rows even though the query's relative-time boundary stays fixed.

## Boundaries and limits

Every scan starts from the server's authorized account scope, including joins.
The parser accepts read stages only. The compiler resolves/quotes names and
binds values. Execution enables PostgreSQL read-only mode and a five-second
statement timeout in a rollback-isolated transaction. Query/model budgets
are shared across workers, not reset for each callback.

Limits include 32 KB source and parameters, 32 stages, 8 joins, 100 output
columns, 200 rows per page, maximum offset/take 100000, and 100 query executions
per turn. Existing context limits still apply.

No subqueries, window functions, per-group top N, JSON-path expressions or
calendar/timezone helpers. Retrieve the exact necessary evidence and compose
with Scheme; do not silently substitute a simpler dataset.

## Development playground

Developers > WootQL uses the same engine and return syntax. It shows rows,
generated SQL and bind values. The development-only controller retains
administrator/Captain access checks. Its HTTP pagination response keeps
`items` and `next_offset`; Ask adds its turn-local query handles.

See [the library README](../lib/wootql/README.md) for the implementation API,
security limitations and tests.
