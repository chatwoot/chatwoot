# Report Panels (InboxHub)

Saved dashboards under **Reports → Panels**: metrics, charts, and tables with optional filters and date presets.

## Custom attributes (v1)

### Detail tables

| Table type | Custom columns |
|------------|----------------|
| Filtered conversations | All conversation custom attrs as `ca:<key>` |
| Unique contacts | All contact custom attrs as `ca:<key>` |

Footer aggregations (sum/avg/count/min/max) apply to numeric types: `number`, `currency`, `percent`.

### Summary tables (agent / inbox / team / label)

Custom attributes appear as **separate measure columns** (Power BI-style), not one rollup dropdown for the whole attribute:

| Column id | Meaning |
|-----------|---------|
| `ca:ventas__count` | Count of conversations where `ventas` is set (non-nil / non-empty) for that agent/inbox/… |
| `ca:ventas__sum` | Sum of numeric `ventas` values |
| `ca:ventas__avg` / `__min` / `__max` | Same for avg/min/max (numeric types only) |
| `contact_ca:ventas__count` / `__sum` / … | Same ops on **contact** custom attributes (deduped per contact within each dimension) |

- **Count** is offered for **all** attribute types (text, list, checkbox, date, …).
- **Sum / avg / min / max** are offered only for `number`, `currency`, `percent`.
- You can enable `Count(ventas)` and `Sum(ventas)` side by side on the same table.
- Legacy columns without a `__{op}` suffix (`ca:ventas` + `column_aggregations`) still work (default op: sum).

### Metric / chart aggregations

Metric/chart widgets with source `aggregation`:

- **Count** over conversations/contacts, optionally restricted to rows where a chosen attribute is set (any type).
- **Sum / avg / min / max** require a numeric custom attribute (`ca:<key>`).
- Optional group-by date/datetime custom attribute for charts.

## Example: agents × sales (Count + Sum)

1. Create a conversation (or contact) custom attribute type **number** or **currency**, e.g. key `ventas`.
2. New panel → add **table** → type **Agent summary**.
3. Enable **Count(Conversation: Ventas)** and **Sum(Conversation: Ventas)**.
4. Save and open the panel — each agent row shows both measures for the selected period.

## Currency / number parsing

- Backend roll-ups and footer aggregations parse locale strings (`1000,00`, `1.000,50`, `1,000.50`) via `numeric_table_cell` (Ruby-only path — no PG `::float` on raw JSON text).
- UI formats `currency` with a `$` prefix and 2 decimals; `percent` with `%`; `number` with locale grouping.
- Count measure cells always format as plain integers (not `$`).
- Panel tables: click a column header to sort asc/desc (client-side on returned rows). Icons match Contacts table (`arrow-up-down` / up / down).

## Limits / follow-ups

- Summary CA roll-up scans filtered conversations in Ruby (row ceiling for large periods).
- No pivot by text/list custom attribute as a dimension yet (group-by enum).
- No cross-entity joins beyond conversation↔contact for the period.
- No calculated columns beyond count/sum/avg/min/max measures.
