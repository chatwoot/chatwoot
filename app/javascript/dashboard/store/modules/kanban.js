import camelcaseKeys from 'camelcase-keys';
import snakecaseKeys from 'snakecase-keys';
import types from '../mutation-types';
import KanbanBoardsAPI from '../../api/kanbanBoards';
import KanbanColumnsAPI from '../../api/kanbanColumns';
import KanbanCardsAPI from '../../api/kanbanCards';
import ConversationAPI from '../../api/inbox/conversation';
import { throwErrorMessage } from '../utils/api';

export const state = {
  boards: [],
  columns: [],
  cards: [],
  conversations: [],
  uiFlags: {
    isFetchingBoards: false,
    isFetchingColumns: false,
    isFetchingCards: false,
    isFetchingConversations: false,
    isCreatingBoard: false,
    isUpdatingBoard: false,
    isCreatingColumn: false,
    isUpdatingColumn: false,
    isCreatingCard: false,
    isMovingCard: false,
  },
};

const normalize = data => camelcaseKeys(data, { deep: true });
const wrap = (key, data) => ({ [key]: snakecaseKeys(data, { deep: true }) });

export const getters = {
  getBoards(_state) {
    return _state.boards;
  },
  getColumns(_state) {
    return _state.columns;
  },
  getCards(_state) {
    return _state.cards;
  },
  getConversations(_state) {
    return _state.conversations;
  },
  getCardsByColumn: _state => columnId => {
    return _state.cards
      .filter(card => card.kanbanColumnId === Number(columnId))
      .sort((a, b) => a.position - b.position || a.id - b.id);
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

export const actions = {
  getBoards: async function getBoards({ commit }) {
    commit(types.SET_KANBAN_UI_FLAG, { isFetchingBoards: true });
    try {
      const response = await KanbanBoardsAPI.get();
      commit(types.SET_KANBAN_BOARDS, normalize(response.data));
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit(types.SET_KANBAN_UI_FLAG, { isFetchingBoards: false });
    }
  },

  createBoard: async function createBoard({ commit }, board) {
    commit(types.SET_KANBAN_UI_FLAG, { isCreatingBoard: true });
    try {
      const response = await KanbanBoardsAPI.create(wrap('kanban_board', board));
      const normalizedBoard = normalize(response.data);
      commit(types.ADD_KANBAN_BOARD, normalizedBoard);
      return normalizedBoard;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit(types.SET_KANBAN_UI_FLAG, { isCreatingBoard: false });
    }
  },

  updateBoard: async function updateBoard({ commit }, { id, ...board }) {
    commit(types.SET_KANBAN_UI_FLAG, { isUpdatingBoard: true });
    try {
      const response = await KanbanBoardsAPI.update(
        id,
        wrap('kanban_board', board)
      );
      const normalizedBoard = normalize(response.data);
      commit(types.UPDATE_KANBAN_BOARD, normalizedBoard);
      return normalizedBoard;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit(types.SET_KANBAN_UI_FLAG, { isUpdatingBoard: false });
    }
  },

  deleteBoard: async function deleteBoard({ commit }, boardId) {
    try {
      await KanbanBoardsAPI.delete(boardId);
      commit(types.DELETE_KANBAN_BOARD, boardId);
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    }
  },

  getColumns: async function getColumns({ commit }, boardId) {
    commit(types.SET_KANBAN_UI_FLAG, { isFetchingColumns: true });
    try {
      const response = await KanbanColumnsAPI.get({ boardId });
      commit(types.SET_KANBAN_COLUMNS, normalize(response.data));
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit(types.SET_KANBAN_UI_FLAG, { isFetchingColumns: false });
    }
  },

  createColumn: async function createColumn({ commit }, { boardId, column }) {
    commit(types.SET_KANBAN_UI_FLAG, { isCreatingColumn: true });
    try {
      const response = await KanbanColumnsAPI.create({
        boardId,
        column: wrap('kanban_column', column),
      });
      commit(types.ADD_KANBAN_COLUMN, normalize(response.data));
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit(types.SET_KANBAN_UI_FLAG, { isCreatingColumn: false });
    }
  },

  updateColumn: async function updateColumn(
    { commit },
    { boardId, columnId, column }
  ) {
    commit(types.SET_KANBAN_UI_FLAG, { isUpdatingColumn: true });
    try {
      const response = await KanbanColumnsAPI.update({
        boardId,
        columnId,
        column: wrap('kanban_column', column),
      });
      const normalizedColumn = normalize(response.data);
      commit(types.UPDATE_KANBAN_COLUMN, normalizedColumn);
      return normalizedColumn;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit(types.SET_KANBAN_UI_FLAG, { isUpdatingColumn: false });
    }
  },

  deleteColumn: async function deleteColumn({ commit }, { boardId, columnId }) {
    try {
      await KanbanColumnsAPI.delete({ boardId, columnId });
      commit(types.DELETE_KANBAN_COLUMN, columnId);
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    }
  },

  getCards: async function getCards({ commit }, boardId) {
    commit(types.SET_KANBAN_UI_FLAG, { isFetchingCards: true });
    try {
      const response = await KanbanCardsAPI.get({ boardId });
      commit(types.SET_KANBAN_CARDS, normalize(response.data));
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit(types.SET_KANBAN_UI_FLAG, { isFetchingCards: false });
    }
  },

  getConversations: async function getConversations({ commit }) {
    commit(types.SET_KANBAN_UI_FLAG, { isFetchingConversations: true });
    try {
      const response = await ConversationAPI.get({ page: 1 });
      commit(
        types.SET_KANBAN_CONVERSATIONS,
        normalize(response.data?.data?.payload || [])
      );
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit(types.SET_KANBAN_UI_FLAG, { isFetchingConversations: false });
    }
  },

  createCard: async function createCard({ commit }, { boardId, card }) {
    commit(types.SET_KANBAN_UI_FLAG, { isCreatingCard: true });
    try {
      const response = await KanbanCardsAPI.create({
        boardId,
        card: wrap('kanban_card', card),
      });
      commit(types.ADD_KANBAN_CARD, normalize(response.data));
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit(types.SET_KANBAN_UI_FLAG, { isCreatingCard: false });
    }
  },

  reorderColumn({ commit }, { columnId, orderedCardIds }) {
    commit(types.REORDER_KANBAN_CARDS, { columnId, orderedCardIds });
  },

  moveCard: async function moveCard(
    { commit },
    { boardId, cardId, columnId, position, orderedCardIds }
  ) {
    commit(types.SET_KANBAN_UI_FLAG, { isMovingCard: true });
    commit(types.MOVE_KANBAN_CARD, { cardId, columnId, position });
    commit(types.REORDER_KANBAN_CARDS, { columnId, orderedCardIds });
    try {
      const response = await KanbanCardsAPI.move({
        boardId,
        cardId,
        card: wrap('kanban_card', {
          kanbanColumnId: columnId,
          position,
          orderedCardIds,
        }),
      });
      commit(types.UPDATE_KANBAN_CARD, normalize(response.data));
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit(types.SET_KANBAN_UI_FLAG, { isMovingCard: false });
    }
  },

  deleteCard: async function deleteCard({ commit }, { boardId, cardId }) {
    try {
      await KanbanCardsAPI.delete({ boardId, cardId });
      commit(types.DELETE_KANBAN_CARD, cardId);
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    }
  },
};

export const mutations = {
  [types.SET_KANBAN_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },
  [types.SET_KANBAN_BOARDS](_state, boards) {
    _state.boards = boards;
  },
  [types.ADD_KANBAN_BOARD](_state, board) {
    _state.boards.push(board);
  },
  [types.UPDATE_KANBAN_BOARD](_state, board) {
    const index = _state.boards.findIndex(record => record.id === board.id);
    if (index >= 0) {
      _state.boards.splice(index, 1, { ..._state.boards[index], ...board });
    }
  },
  [types.DELETE_KANBAN_BOARD](_state, boardId) {
    _state.boards = _state.boards.filter(board => board.id !== Number(boardId));
    _state.columns = [];
    _state.cards = [];
  },
  [types.SET_KANBAN_COLUMNS](_state, columns) {
    _state.columns = columns;
  },
  [types.ADD_KANBAN_COLUMN](_state, column) {
    _state.columns.push(column);
  },
  [types.UPDATE_KANBAN_COLUMN](_state, column) {
    const index = _state.columns.findIndex(record => record.id === column.id);
    if (index >= 0) {
      _state.columns.splice(index, 1, { ..._state.columns[index], ...column });
    }

    const board = _state.boards.find(
      record => record.id === column.kanbanBoardId
    );
    const boardColumnIndex = board?.columns?.findIndex(
      record => record.id === column.id
    );
    if (boardColumnIndex >= 0) {
      board.columns.splice(boardColumnIndex, 1, {
        ...board.columns[boardColumnIndex],
        ...column,
      });
    }
  },
  [types.DELETE_KANBAN_COLUMN](_state, columnId) {
    const id = Number(columnId);
    _state.columns = _state.columns.filter(column => column.id !== id);
    _state.cards = _state.cards.filter(card => card.kanbanColumnId !== id);
  },
  [types.SET_KANBAN_CARDS](_state, cards) {
    _state.cards = cards;
  },
  [types.SET_KANBAN_CONVERSATIONS](_state, conversations) {
    _state.conversations = conversations;
  },
  [types.ADD_KANBAN_CARD](_state, card) {
    _state.cards.push(card);
  },
  [types.UPDATE_KANBAN_CARD](_state, card) {
    const index = _state.cards.findIndex(record => record.id === card.id);
    if (index >= 0) _state.cards.splice(index, 1, card);
  },
  [types.MOVE_KANBAN_CARD](_state, { cardId, columnId, position }) {
    const card = _state.cards.find(record => record.id === cardId);
    if (!card) return;

    card.kanbanColumnId = Number(columnId);
    card.position = position;
  },
  [types.REORDER_KANBAN_CARDS](_state, { columnId, orderedCardIds = [] }) {
    orderedCardIds.forEach((cardId, index) => {
      const card = _state.cards.find(record => record.id === cardId);
      if (card) {
        card.kanbanColumnId = Number(columnId);
        card.position = (index + 1) * 10;
      }
    });
  },
  [types.DELETE_KANBAN_CARD](_state, cardId) {
    _state.cards = _state.cards.filter(card => card.id !== Number(cardId));
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
