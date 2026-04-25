import KanbanAPI from '../../../api/kanban';

export default {
  async fetchBoard({ commit }) {
    commit('SET_UI_FLAG', { isFetchingBoard: true });
    try {
      const { data } = await KanbanAPI.getBoard();
      commit('SET_BOARD', data);
    } finally {
      commit('SET_UI_FLAG', { isFetchingBoard: false });
    }
  },

  async createColumn({ commit }, params) {
    commit('SET_UI_FLAG', { isCreatingColumn: true });
    try {
      const { data } = await KanbanAPI.createColumn(params);
      commit('ADD_COLUMN', data);
      return data;
    } finally {
      commit('SET_UI_FLAG', { isCreatingColumn: false });
    }
  },

  async updateColumn({ commit }, { id, ...params }) {
    const { data } = await KanbanAPI.updateColumn(id, params);
    commit('UPDATE_COLUMN', data);
    return data;
  },

  async reorderColumns({ commit, state }, orderedColumns) {
    const positions = orderedColumns.map((col, idx) => ({
      id: col.id,
      position: idx + 1.0,
    }));
    // Optimistic update
    commit(
      'SET_COLUMNS',
      orderedColumns.map((col, idx) => ({ ...col, position: idx + 1.0 }))
    );
    try {
      await KanbanAPI.reorderColumns(positions);
    } catch {
      // Revert to original on failure
      commit('SET_COLUMNS', state.columns);
    }
  },

  async deleteColumn({ commit }, columnId) {
    commit('SET_UI_FLAG', { isDeletingColumn: true });
    try {
      await KanbanAPI.deleteColumn(columnId);
      commit('REMOVE_COLUMN', columnId);
    } finally {
      commit('SET_UI_FLAG', { isDeletingColumn: false });
    }
  },

  async createCard({ commit }, { columnId, params }) {
    commit('SET_UI_FLAG', { isCreatingCard: true });
    try {
      const { data } = await KanbanAPI.createCard(columnId, params);
      commit('ADD_CARD', data);
      return data;
    } finally {
      commit('SET_UI_FLAG', { isCreatingCard: false });
    }
  },

  async updateCard({ commit }, { id, ...params }) {
    const { data } = await KanbanAPI.updateCard(id, params);
    commit('UPDATE_CARD', data);
    return data;
  },

  async moveCard(
    { commit, state },
    { card, targetColumnId, beforePosition, afterPosition }
  ) {
    const originalColumnId = card.kanban_column_id;
    const originalCards = [...(state.cards[originalColumnId] || [])];

    // Calculate optimistic position
    let newPosition;
    if (beforePosition != null && afterPosition != null) {
      newPosition = (beforePosition + afterPosition) / 2;
    } else if (beforePosition != null) {
      newPosition = beforePosition + 1.0;
    } else if (afterPosition != null) {
      newPosition = afterPosition / 2.0;
    } else {
      newPosition = (state.cards[targetColumnId] || []).length + 1.0;
    }

    // Optimistic update
    commit('MOVE_CARD_OPTIMISTIC', { card, targetColumnId, newPosition });

    try {
      const { data } = await KanbanAPI.moveCard(card.id, {
        columnId: targetColumnId,
        beforePosition,
        afterPosition,
      });
      commit('UPDATE_CARD', data);
    } catch {
      commit('REVERT_CARD_MOVE', { card, originalColumnId, originalCards });
    }
  },

  async deleteCard({ commit }, { cardId, columnId }) {
    await KanbanAPI.deleteCard(cardId);
    commit('REMOVE_CARD', { cardId, columnId });
  },
};
