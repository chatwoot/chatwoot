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

  async moveCard({ commit }, { card, targetColumnId }) {
    const originalColumnId = card.kanban_column_id;
    if (String(originalColumnId) === String(targetColumnId)) return;

    commit('MOVE_CARD_OPTIMISTIC', { card, targetColumnId });

    try {
      const { data } = await KanbanAPI.moveCard(card.id, {
        columnId: targetColumnId,
      });
      commit('UPDATE_CARD', data);
    } catch {
      commit('REVERT_CARD_MOVE', { card, originalColumnId });
    }
  },

  async deleteCard({ commit }, { cardId, columnId }) {
    await KanbanAPI.deleteCard(cardId);
    commit('REMOVE_CARD', { cardId, columnId });
  },

  async createSchedule(_, { cardId, params }) {
    const { data } = await KanbanAPI.createSchedule(cardId, params);
    return data;
  },

  async deleteSchedule(_, { cardId, scheduleId }) {
    await KanbanAPI.deleteSchedule(cardId, scheduleId);
  },
};
