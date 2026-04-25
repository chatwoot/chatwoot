export default {
  SET_BOARD(state, board) {
    state.board = board;
    state.columns = board.columns || [];
    const cards = {};
    (board.columns || []).forEach(col => {
      cards[col.id] = col.cards || [];
    });
    state.cards = cards;
  },

  SET_COLUMNS(state, columns) {
    state.columns = columns;
  },

  ADD_COLUMN(state, column) {
    state.columns.push(column);
    state.cards[column.id] = [];
  },

  UPDATE_COLUMN(state, column) {
    const idx = state.columns.findIndex(c => c.id === column.id);
    if (idx !== -1) state.columns.splice(idx, 1, column);
  },

  REMOVE_COLUMN(state, columnId) {
    state.columns = state.columns.filter(c => c.id !== columnId);
    delete state.cards[columnId];
  },

  SET_CARDS(state, { columnId, cards }) {
    state.cards = { ...state.cards, [columnId]: cards };
  },

  ADD_CARD(state, card) {
    const columnCards = state.cards[card.kanban_column_id] || [];
    state.cards = {
      ...state.cards,
      [card.kanban_column_id]: [...columnCards, card],
    };
  },

  UPDATE_CARD(state, card) {
    const columnCards = state.cards[card.kanban_column_id] || [];
    const idx = columnCards.findIndex(c => c.id === card.id);
    if (idx !== -1) {
      const updated = [...columnCards];
      updated.splice(idx, 1, card);
      state.cards = { ...state.cards, [card.kanban_column_id]: updated };
    }
  },

  MOVE_CARD_OPTIMISTIC(state, { card, targetColumnId, newPosition }) {
    const fromColumnId = card.kanban_column_id;

    // Remove from source column
    const fromCards = (state.cards[fromColumnId] || []).filter(
      c => c.id !== card.id
    );
    // Add to target column with new position
    const updatedCard = {
      ...card,
      kanban_column_id: targetColumnId,
      position: newPosition,
    };
    const toCards = [...(state.cards[targetColumnId] || []), updatedCard].sort(
      (a, b) => a.position - b.position
    );

    state.cards = {
      ...state.cards,
      [fromColumnId]: fromCards,
      [targetColumnId]: toCards,
    };
  },

  REVERT_CARD_MOVE(state, { card, originalColumnId, originalCards }) {
    state.cards = {
      ...state.cards,
      [originalColumnId]: originalCards,
      [card.kanban_column_id]: (
        state.cards[card.kanban_column_id] || []
      ).filter(c => c.id !== card.id),
    };
  },

  REMOVE_CARD(state, { cardId, columnId }) {
    state.cards = {
      ...state.cards,
      [columnId]: (state.cards[columnId] || []).filter(c => c.id !== cardId),
    };
  },

  SET_UI_FLAG(state, flags) {
    state.uiFlags = { ...state.uiFlags, ...flags };
  },
};
