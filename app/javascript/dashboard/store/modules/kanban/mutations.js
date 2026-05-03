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

  REMOVE_CARD(state, { cardId, columnId }) {
    state.cards = {
      ...state.cards,
      [columnId]: (state.cards[columnId] || []).filter(c => c.id !== cardId),
    };
  },

  MOVE_CARD_OPTIMISTIC(state, { card, targetColumnId, newPosition }) {
    const sourceColumnId = card.kanban_column_id;
    const updatedCard = {
      ...card,
      kanban_column_id: targetColumnId,
      position: newPosition,
    };

    if (String(sourceColumnId) === String(targetColumnId)) {
      state.cards = {
        ...state.cards,
        [targetColumnId]: (state.cards[targetColumnId] || []).map(c =>
          c.id === card.id ? updatedCard : c
        ),
      };
    } else {
      const targetCards = [
        ...(state.cards[targetColumnId] || []).filter(c => c.id !== card.id),
        updatedCard,
      ].sort((a, b) => a.position - b.position);
      state.cards = {
        ...state.cards,
        [sourceColumnId]: (state.cards[sourceColumnId] || []).filter(
          c => c.id !== card.id
        ),
        [targetColumnId]: targetCards,
      };
    }
  },

  REVERT_CARD_MOVE(state, { card, originalColumnId, originalCards }) {
    const newCards = { ...state.cards, [originalColumnId]: originalCards };
    const otherColId = Object.keys(state.cards).find(
      colId =>
        String(colId) !== String(originalColumnId) &&
        (state.cards[colId] || []).some(c => c.id === card.id)
    );
    if (otherColId) {
      newCards[otherColId] = state.cards[otherColId].filter(
        c => c.id !== card.id
      );
    }
    state.cards = newCards;
  },

  SET_SELECTED_CARD(state, card) {
    state.selectedCard = card;
  },

  SET_UI_FLAG(state, flags) {
    state.uiFlags = { ...state.uiFlags, ...flags };
  },
};
