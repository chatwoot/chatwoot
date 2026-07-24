# Report Panels (InboxHub)

Saved dashboards under **Reports → Panels**: metrics, charts, and tables with optional filters and date presets.

## Excel mapping (tabla dinámica)

| Excel | Panel widget |
|-------|----------------|
| **Filtros** | Panel filters (outer AND / slicers) |
| **Filas** | Table type: agent / inbox / team / label summary |
| **Columnas** | Pivot field: one conversation list/text custom attribute |
| **Valores** | Measures: `conversations_count`, `resolved_conversations_count`, `ca:*__sum` / `__count`, etc. |

### Editor UX (pivot builder)

Summary tables use a **Campos → Filas / Columnas / Valores** builder (`PanelTablePivotBuilder.vue`), not a mile-long checkbox list of `Count(attr)` / `Sum(attr)`:

- **Campos**: searchable list — each attribute appears once (system metrics + conversation/contact CAs). Drag with `vuedraggable`, or hover shortcuts → Cols / Vals.
- **Filas**: read-only chip from table type (change via Filas select).
- **Columnas**: one pivot CA (dropdown or drop zone) + optional value chips + row totals.
- **Valores**: compact measure rows — pick aggregation (Count/Sum/…) per attribute after adding. The same custom attribute may appear more than once when the measure ops differ (e.g. `ca:ventas__count` + `ca:ventas__sum`); uniqueness is by full column key, not by attribute alone. System metrics (`conversations_count`, …) stay unique.
- **Sugerencias**: one-click chips (max ~5) ranked from available attributes — column dimension if unset, then Sum of currency/number, then Count of list/text, then missing Conversations / Resolved. Already-applied items are hidden.

Detail tables (`conversations` / `contacts`) keep a searchable grouped column picker.

With a pivot field set, each value measure expands once per attribute value:

`conversations_count__pv__venta`, `ca:ventas__sum__pv__venta`, …

Optional **row totals** keep the plain measure keys (`conversations_count`) as the sum across segments.

Panel filters remain the report-wide context; they do **not** replace the pivot column dimension.

### Smart suggestions

While editing a summary table, the builder shows a compact **Sugerencias / Suggestions** chip strip when useful fields are still unused:

| Priority | When | Chip action |
|----------|------|-------------|
| 1 | No pivot Columnas set | Use best list/text CA (few options preferred) as column dimension |
| 2 | Currency / number / percent CA missing that Sum measure | Add `Sum(name)` (even if Count of the same attr is already in Valores) |
| 3 | List/text (then other) CA missing that Count measure | Add `Count(name)` — top 2 |
| 4 | System metric missing | Add Conversations / Resolved |

Max 3–5 chips; applied suggestions disappear. Demo seed (`tmp/seed_report_panels_demo.rb`) creates attrs `producto` (list), `ventas` (currency), and a configured pivot plus a second empty-ish table to exercise chips.

### v1 limits

- One column-dimension field (not multi-level column hierarchy).
- Select which attribute values to show (all or subset, max 12).
- No arbitrary DAX / calculated ratios.
- Time averages / CSAT / message counts are not expanded in pivot mode (omit from Valores or use flat summary).
- Drag-drop clones from Campos; reorder within Valores is supported. Nested multi-field column hierarchy is not.

## Custom attributes (detail + flat summary)

### Detail tables

| Table type | Custom columns |
|------------|----------------|
| Filtered conversations | All conversation custom attrs as `ca:<key>` |
| Unique contacts | All contact custom attrs as `ca:<key>` |

### Flat summary (no pivot)

| Column id | Meaning |
|-----------|---------|
| `ca:ventas__count` | Count where `ventas` is set |
| `ca:ventas__sum` | Sum of numeric `ventas` |
| `contact_ca:…` | Contact attrs (deduped per contact) |

Legacy `ca:key__count__eq__value` is still parsed if present; prefer **pivot** for Excel-style breakdowns.

## Example: agents × estado (pivot)

1. Conversation list attr `estado` with values `venta`, `soporte`, `seguimiento`.
2. Table → **Filas** = Agent summary.
3. In the builder, drag `estado` to **Columnas** (or pick it in the dropdown).
4. Add **Valores**: Conversations + Ventas with Sum.
5. Leave panel **Filtros** empty (or only inbox/team context).
6. Result: each agent row shows Conversations and Sum under venta | soporte | seguimiento (+ totals).

## Currency / number parsing

- Locale strings (`1000,00`, `1.000,50`) via `CustomAttributes::NumericParser`
  (panel runner + formula recompute share the same helper).
- Unparseable values are skipped in Sum/Avg/Min/Max (not coerced to `0`).
- Count = attribute present (non-blank), not “parseable as number”.
- UI formats `currency` with `$`; count cells as integers.
- Click column headers to sort.

## Scan limits

| Path | Behavior |
|------|----------|
| Aggregation metrics / charts | Full range (`in_batches`) |
| Flat summary `ca:*` / `contact_ca:*` measures | Full range (`in_batches`) |
| Pivot summary | Full range (`in_batches`) |
| Detail tables (`conversations` / `contacts`) | Preview caps (`DETAIL_CONVERSATIONS_LIMIT` / `DETAIL_CONTACTS_LIMIT`); response includes `truncated` + `total_count` |

## Date axis

- Default: filter conversations by `created_at` in the panel preset/custom range.
- Optional panel `date_attribute` = `ca:<key>` (conversation date/datetime CA):
  the range applies to that attribute instead of `created_at` (filters still apply).

## Contact formulas vs period measures

- Contact attribute **formulas** persist a lifetime aggregate over conversations.
- Panel `contact_ca:*` measures read that stored value (deduped per contact in range).
- For period totals prefer conversation measures (`ca:ventas__sum`), not formula contact attrs.

## Filters

- Conversation filters and contact filters are split and combined with **AND** across groups.
- OR only applies within the same filter group (conversation vs contact).

## Follow-ups

- Multi-level column hierarchy (attr A then attr B).
- Pivot on contact attributes.
- Matrix export with grouped Excel headers.
