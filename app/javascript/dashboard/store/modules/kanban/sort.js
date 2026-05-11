// FIFO ordering helpers shared between mutations.
//
// Server is the source of truth — these functions only handle optimistic
// inserts so the UI doesn't show a "snap" after a drop.

function sortKeyFor(card, column) {
  if (column && column.column_function === 'auto_receive') {
    const ts = card.conversation?.created_at || card.created_at;
    return ts ? new Date(ts).getTime() : 0;
  }
  const ts = card.entered_stage_at || card.created_at;
  return ts ? new Date(ts).getTime() : 0;
}

export function insertSortedByRule(cards, newCard, column) {
  const result = [...cards];
  const newKey = sortKeyFor(newCard, column);
  const idx = result.findIndex(c => {
    const k = sortKeyFor(c, column);
    return k > newKey || (k === newKey && c.id > newCard.id);
  });
  if (idx === -1) result.push(newCard);
  else result.splice(idx, 0, newCard);
  return result;
}
