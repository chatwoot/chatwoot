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

Numeric custom attributes can be added as columns and **rolled up per dimension**:

| Column prefix | Source | Roll-up |
|---------------|--------|---------|
| `ca:<key>` | Conversation `custom_attributes` | Sum/avg/min/max/count across conversations in the period (grouped by assignee / inbox / team / label) |
| `contact_ca:<key>` | Contact `custom_attributes` | Same ops, **deduped per contact** within each dimension (avoids double-counting multi-convo contacts) |

- Default op when enabling a summary CA column: **sum** (also used for the footer unless changed).
- The column aggregation dropdown sets **both** the per-row roll-up and the footer.
- Non-numeric types (text, list, checkbox, date, …) are **not** offered on summary tables in v1 (they remain available on detail tables).

### Metric / chart aggregations

Unchanged: metric/chart widgets with source `aggregation` can sum/avg a `ca:` field over conversations or contacts, optionally grouped by a date/datetime custom attribute.

## Example: agents × sales

1. Create a conversation (or contact) custom attribute type **number** or **currency**, e.g. key `ventas`.
2. New panel → add **table** → type **Agent summary**.
3. Enable column **Conversation: Ventas** (or **Contact: Ventas**).
4. Leave aggregation on **Sum**.
5. Save and open the panel — each agent row shows the rolled-up sales for the selected period.

## Currency / number parsing

- Backend roll-ups and footer aggregations parse locale strings (`1000,00`, `1.000,50`, `1,000.50`) via `numeric_table_cell` (Ruby-only path — no PG `::float` on raw JSON text).
- UI formats `currency` with a `$` prefix and 2 decimals; `percent` with `%`; `number` with locale grouping.
- Panel tables: click a column header to sort asc/desc (client-side on returned rows). Icons match Contacts table (`arrow-up-down` / up / down).

## Limits / follow-ups (Power BI-like)

- Summary CA roll-up scans filtered conversations in Ruby (row ceiling for large periods).
- No pivot by text/list custom attribute as a dimension yet (group-by enum).
- No cross-entity joins beyond conversation↔contact for the period.
- No calculated columns / measures beyond sum/avg/min/max/count.
