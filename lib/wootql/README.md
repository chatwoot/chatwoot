# WootQL

The read-only WootQL engine used by Captain Ask and the developer playground.
This library targets PostgreSQL and uses Chatwoot's existing resource catalog.
Loading the library does not boot Rails; executing queries requires the app's
catalog and authorized data access.

## Core syntax

```text
messages
| where conversation_id in $ids
| where created_at > updated_at
| return id, conversation_id, content
| sort id asc
```

Stages are `where`, `return`, `join`, `summarize`, `sort`, and `take`.
`return` keeps or renames columns, like SQL's `SELECT`. Later stages can only
use retained fields. Pipeline order matters: `take 10 | where ...` filters the
first ten rows, while `where ... | take 10` takes ten matching rows.
`return` does not terminate the pipeline. `project` is not supported.

- `in $ids` requires an array. Each member is validated against the field type
  and individually bound. An empty array matches no rows.
- `in (1, $id)` accepts individual scalar values, not arrays to flatten.
- Comparisons accept compatible field references on the right, including
  declared to-one paths. Quoted strings are always values, never field names.
- `contains` accepts a scalar string: substring matching for text and exact
  membership for string-list fields.
- `is null` means absent; `is empty` means zero characters or list elements.
  Empty tests do not treat null as empty. SQL's three-valued logic is retained.
- To-one paths use authorized left joins. To-many relationships require an
  explicit equality join. Scoped and polymorphic relationships are not field paths.

## Host integration

The catalog is built in through `Captain::Apropos::ResourceCatalog`, shared with
Chatwoot's existing discovery system. There is no caller-supplied catalog, schema,
or computed-expression configuration. The server supplies `data.scope(resource)`
to return authorized ActiveRecord relations. A resource name is not a table name.

```ruby
require_relative 'lib/wootql'

engine = Wootql::Query.new(data: authorized_data_access,
                           database: ApplicationRecord, budget: { queries: 0 })

prepared = engine.prepare(
  'messages | where conversation_id in $ids | return id, content | sort id asc',
  { 'ids' => [12, 34] }
)
page = prepared.page
next_page = prepared.page(page.fetch('next_offset')) unless page.fetch('next_offset') == false
```

`Wootql::Schema.new.describe(data)` exposes field types, enum names and queryable
relationships. Types come from Rails models, with the existing catalog's field
exclusions preserved. Conversation labels use a trusted membership
expression. Neither the catalog nor computed SQL expressions are agent inputs.

For a single page, `engine.run(source, parameters = {}, offset = 0, debug: false)`
is a convenience method. Use `prepare` once and `prepared.page(offset)` for
multi-page retrieval. Preparing captures `now()` once and copies parameter
values so later pages do not silently change their filters. Preparing does not
execute SQL; each page consumes the shared execution budget.

Pages contain `items` and `next_offset` (`false` at the end). `debug: true` adds
SQL, bind values and column names. Debug output may contain sensitive data and
must stay within the host's authorized execution context.

Offset pagination still reads live data, not a database snapshot. Inserts,
deletes and sort-key changes can move rows between pages. Retain unique sorting
keys in projections. Preparing freezes query boundaries, not database contents.
Prepared objects are in-process and bound to the authorization context in which
they were created; do not share them between users or accounts.

## Read-only and security boundaries

- The grammar allowlists read stages. No update, insert, delete, DDL, raw SQL,
  arbitrary function calls, caller-supplied ASTs, or caller-supplied plans.
- The resolver checks fields, relationships, types and output names. Every
  base and joined resource starts from the host's authorized scope.
- The compiler quotes resolved identifiers and binds values separately.
  Values never become SQL syntax, including array members and quoted literals.
- Every execution enables PostgreSQL `transaction_read_only` and a five-second
  statement timeout inside a rollback-isolated transaction/savepoint. Failure
  to enable read-only mode aborts the query. Settings are restored afterward.

PostgreSQL read-only mode blocks writes to persistent tables and DDL; it is not
a general sandbox for arbitrary server functions and permits some temporary-table
writes. The grammar and trusted catalog remain essential. See the official
[transaction modes](https://www.postgresql.org/docs/current/sql-set-transaction.html)
and [savepoint behavior of SET LOCAL](https://www.postgresql.org/docs/current/sql-set.html).

Existing limits are retained: 32 KB source and parameters, 4096 tokens, 32 stages,
64 predicates, 16 levels of predicate/path nesting, 8 joins, 100 output fields,
200 rows per page, maximum offset/take of 100000, and 100 page executions per
shared budget. Larger joins, per-group top N, computed projections, JSON-path
queries and calendar/timezone helpers are out of scope for this first pass.

## Tests

```sh
bundle exec rspec spec/lib/wootql
```

Parser, resolver, compiler and execution-boundary tests run without a database.
SQL injection tests verify that rejected source never reaches the query connection
and malicious-looking literal/parameter values remain bound data.

The PostgreSQL tests are opt-in. Point them only at a disposable test database:

```sh
WOOTQL_TEST_DATABASE_URL='postgresql://localhost/wootql_test' \
  bundle exec rspec spec/lib/wootql/postgres_spec.rb
```

Each integration example creates a unique schema and rolls back its tables and
test rows. It checks real SQL results, account boundaries, pagination, injection
payloads, and read-only/timeout settings without using application records.
