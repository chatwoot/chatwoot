# Report Panels (InboxHub)

Saved dashboards under **Reports → Panels**: metrics, charts, and tables with optional filters and date presets.

## Excel mapping (tabla dinámica)

| Excel | Panel widget |
|-------|----------------|
| **Filtros** | Panel filters (outer AND / slicers) |
| **Filas** | Table type: agent / inbox / team / label summary |
| **Columnas** | Pivot field: one conversation list/text custom attribute |
| **Valores** | Measures: `conversations_count`, `resolved_conversations_count`, `ca:*__sum` / `__count`, etc. |

With a pivot field set, each value measure expands once per attribute value:

`conversations_count__pv__venta`, `ca:ventas__sum__pv__venta`, …

Optional **row totals** keep the plain measure keys (`conversations_count`) as the sum across segments.

Panel filters remain the report-wide context; they do **not** replace the pivot column dimension.

### v1 limits

- One column-dimension field (not multi-level column hierarchy).
- Select which attribute values to show (all or subset, max 12).
- No arbitrary DAX / calculated ratios.
- Time averages / CSAT / message counts are not expanded in pivot mode (omit from Valores or use flat summary).

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
3. **Columnas** = `estado`; keep the values you want as columns.
4. **Valores** = Conversations + Sum(Ventas) (optional).
5. Leave panel **Filtros** empty (or only inbox/team context).
6. Result: each agent row shows Conversations and Sum under venta | soporte | seguimiento (+ totals).

## Currency / number parsing

- Locale strings (`1000,00`, `1.000,50`) via `numeric_table_cell`.
- UI formats `currency` with `$`; count cells as integers.
- Click column headers to sort.

## Follow-ups

- Multi-level column hierarchy (attr A then attr B).
- Pivot on contact attributes.
- Matrix export with grouped Excel headers.
