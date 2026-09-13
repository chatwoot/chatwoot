const TABLE_PLACEHOLDER =
  /\{\{\s*show-table\s+table_id\s*=\s*["“]([^"”]+)["”]\s*\}\}/g;

export function presentationText(content, tables) {
  const displayedIds = new Set(tables.map(table => table.table_id));
  return content
    .replace(TABLE_PLACEHOLDER, (placeholder, id) =>
      displayedIds.has(id) ? '' : placeholder
    )
    .trim();
}
