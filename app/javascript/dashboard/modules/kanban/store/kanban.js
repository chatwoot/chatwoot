// Vuex module — drop into app/javascript/dashboard/store/modules/kanban.js
// and register in store/index.js (one-line addition).
import {
  KanbanBoards,
  KanbanColumns,
  KanbanCards,
  KanbanLabels,
} from '../api/KanbanAPI';
import { subscribeToBoard } from '../helpers/KanbanCable';

export const types = {
  SET_BOARDS:          'SET_KANBAN_BOARDS',
  SET_CURRENT_BOARD:   'SET_KANBAN_CURRENT_BOARD',
  UPSERT_COLUMN:       'UPSERT_KANBAN_COLUMN',
  REMOVE_COLUMN:       'REMOVE_KANBAN_COLUMN',
  UPSERT_CARD:         'UPSERT_KANBAN_CARD',
  REMOVE_CARD:         'REMOVE_KANBAN_CARD',
  MOVE_CARD_LOCAL:     'MOVE_KANBAN_CARD_LOCAL',
  SET_LOADING:         'SET_KANBAN_LOADING',
  SET_LABELS:          'SET_KANBAN_LABELS',
  SET_FILTERS:         'SET_KANBAN_FILTERS',
};

const state = {
  boards: [],
  currentBoard: null,
  labels: [],
  loading: false,
  filters: { q: '', assignee_id: null, priority: null, label_ids: [], include_archived: false },
  _unsubscribe: null,
};

const getters = {
  boards:       s => s.boards,
  currentBoard: s => s.currentBoard,
  labels:       s => s.labels,
  filters:      s => s.filters,
  columns:      s => s.currentBoard?.columns || [],
  isLoading:    s => s.loading,
};

const findCardLocation = (board, cardId) => {
  if (!board) return null;
  for (const col of board.columns) {
    const idx = (col.cards || []).findIndex(c => c.id === cardId);
    if (idx >= 0) return { col, idx };
  }
  return null;
};

const actions = {
  async fetchBoards({ commit }) {
    commit(types.SET_LOADING, true);
    try {
      const { data } = await KanbanBoards.get();
      commit(types.SET_BOARDS, data.data || []);
    } finally { commit(types.SET_LOADING, false); }
  },

  async fetchBoard({ commit, dispatch, state: s }, boardId) {
    if (s._unsubscribe) { s._unsubscribe(); s._unsubscribe = null; }
    commit(types.SET_LOADING, true);
    try {
      const { data } = await KanbanBoards.show(boardId);
      commit(types.SET_CURRENT_BOARD, data.data);
      await dispatch('fetchLabels');
      s._unsubscribe = subscribeToBoard(boardId, msg => dispatch('handleCableMessage', msg));
    } finally { commit(types.SET_LOADING, false); }
  },

  async fetchLabels({ commit }) {
    const { data } = await KanbanLabels.get();
    commit(types.SET_LABELS, data.data || []);
  },

  setFilters({ commit }, filters) { commit(types.SET_FILTERS, filters); },

  async createBoard({ dispatch }, payload) {
    await KanbanBoards.create({ board: payload });
    await dispatch('fetchBoards');
  },

  async createColumn({ commit, state: s }, payload) {
    const { data } = await KanbanColumns.create(s.currentBoard.id, payload);
    commit(types.UPSERT_COLUMN, { ...data.data, cards: [] });
  },

  async deleteColumn({ commit, state: s }, columnId) {
    await KanbanColumns.destroy(s.currentBoard.id, columnId);
    commit(types.REMOVE_COLUMN, columnId);
  },

  async reorderColumns({ commit, state: s }, orderedIds) {
    await KanbanColumns.reorder(s.currentBoard.id, orderedIds);
    const { data } = await KanbanBoards.show(s.currentBoard.id);
    commit(types.SET_CURRENT_BOARD, data.data);
  },

  async createCard({ commit, state: s }, payload) {
    const { data } = await KanbanCards.create(s.currentBoard.id, payload);
    commit(types.UPSERT_CARD, data.data);
  },

  async updateCard({ commit, state: s }, { id, ...payload }) {
    const { data } = await KanbanCards.update(s.currentBoard.id, id, payload);
    commit(types.UPSERT_CARD, data.data);
  },

  async deleteCard({ commit, state: s }, { cardId, hard = false }) {
    await KanbanCards.destroy(s.currentBoard.id, cardId, { hard });
    commit(types.REMOVE_CARD, cardId);
  },

  async moveCard({ commit, state: s, dispatch }, { cardId, toColumnId, position }) {
    commit(types.MOVE_CARD_LOCAL, { cardId, toColumnId, position });
    try {
      await KanbanCards.move(s.currentBoard.id, { cardId, toColumnId, position });
    } catch (err) {
      await dispatch('fetchBoard', s.currentBoard.id);
      throw err;
    }
  },

  // ------- Cable -------
  async handleCableMessage({ commit, state: s, dispatch }, msg) {
    if (!msg || !s.currentBoard) return;
    switch (msg.event) {
      case 'card_created':
      case 'card_updated':
      case 'card_moved':
      case 'card_deleted':
      case 'column_created':
      case 'column_updated':
      case 'column_deleted':
      case 'columns_reordered':
      case 'comment_created':
      case 'comment_deleted':
      case 'checklist_item_created':
      case 'checklist_item_updated':
      case 'checklist_item_deleted':
      case 'checklist_item_toggled':
        // Cheapest correct strategy: re-fetch the board. Avoids state drift.
        await dispatch('fetchBoard', s.currentBoard.id);
        break;
      default:
        break;
    }
  },

  async addComment({ state: s }, { cardId, content }) {
    return KanbanCards.addComment(s.currentBoard.id, cardId, content);
  },
  async fetchComments({ state: s }, cardId) {
    const { data } = await KanbanCards.comments(s.currentBoard.id, cardId);
    return data.data;
  },
  async addChecklistItem({ state: s }, { cardId, title }) {
    return KanbanCards.addChecklistItem(s.currentBoard.id, cardId, title);
  },
  async toggleChecklistItem({ state: s }, { cardId, itemId }) {
    return KanbanCards.toggleChecklistItem(s.currentBoard.id, cardId, itemId);
  },
  async assignLabel({ state: s }, { cardId, labelId }) {
    return KanbanCards.assignLabel(s.currentBoard.id, cardId, labelId);
  },
  async unassignLabel({ state: s }, { cardId, labelId }) {
    return KanbanCards.unassignLabel(s.currentBoard.id, cardId, labelId);
  },
};

const mutations = {
  [types.SET_BOARDS]       (s, boards) { s.boards = boards; },
  [types.SET_CURRENT_BOARD](s, board)  { s.currentBoard = board; },
  [types.SET_LOADING]      (s, v)      { s.loading = v; },
  [types.SET_LABELS]       (s, labels) { s.labels = labels; },
  [types.SET_FILTERS]      (s, f)      { s.filters = { ...s.filters, ...f }; },

  [types.UPSERT_COLUMN](s, column) {
    if (!s.currentBoard) return;
    const idx = s.currentBoard.columns.findIndex(c => c.id === column.id);
    if (idx >= 0) s.currentBoard.columns.splice(idx, 1, { ...s.currentBoard.columns[idx], ...column });
    else s.currentBoard.columns.push(column);
  },

  [types.REMOVE_COLUMN](s, columnId) {
    if (!s.currentBoard) return;
    s.currentBoard.columns = s.currentBoard.columns.filter(c => c.id !== columnId);
  },

  [types.UPSERT_CARD](s, card) {
    if (!s.currentBoard) return;
    const col = s.currentBoard.columns.find(c => c.id === card.column_id);
    if (!col) return;
    col.cards = col.cards || [];
    const idx = col.cards.findIndex(c => c.id === card.id);
    if (idx >= 0) col.cards.splice(idx, 1, card); else col.cards.push(card);
  },

  [types.REMOVE_CARD](s, cardId) {
    if (!s.currentBoard) return;
    s.currentBoard.columns.forEach(col => {
      col.cards = (col.cards || []).filter(c => c.id !== cardId);
    });
  },

  [types.MOVE_CARD_LOCAL](s, { cardId, toColumnId, position }) {
    const found = findCardLocation(s.currentBoard, cardId);
    if (!found) return;
    const card = found.col.cards.splice(found.idx, 1)[0];
    card.column_id = toColumnId;
    const target = s.currentBoard.columns.find(c => c.id === toColumnId);
    if (!target) return;
    target.cards = target.cards || [];
    target.cards.splice(position, 0, card);
  },
};

export default { namespaced: true, state, getters, actions, mutations };
