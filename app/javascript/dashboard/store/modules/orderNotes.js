import types from '../mutation-types';
import OrderNotesAPI from '../../api/orderNotes';

export const state = {
  records: {},
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isDeleting: false,
  },
};

export const getters = {
  getNotesByOrderId: _state => orderId => {
    const records = _state.records[orderId] || [];
    return records.sort((r1, r2) => r2.id - r1.id);
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

export const actions = {
  async get({ commit, rootGetters }, { orderId }) {
    commit(types.SET_ORDER_NOTES_UI_FLAG, { isFetching: true });
    try {
      const accountId = rootGetters.getCurrentAccountId;
      const { data } = await OrderNotesAPI.getAll(accountId, orderId);
      commit(types.SET_ORDER_NOTES, { orderId, data });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_ORDER_NOTES_UI_FLAG, { isFetching: false });
    }
  },

  async create({ commit, rootGetters }, { orderId, content }) {
    commit(types.SET_ORDER_NOTES_UI_FLAG, { isCreating: true });
    try {
      const accountId = rootGetters.getCurrentAccountId;
      const { data } = await OrderNotesAPI.create(accountId, orderId, content);
      commit(types.ADD_ORDER_NOTE, { orderId, data });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_ORDER_NOTES_UI_FLAG, { isCreating: false });
    }
  },

  async delete({ commit, rootGetters }, { noteId, orderId }) {
    commit(types.SET_ORDER_NOTES_UI_FLAG, { isDeleting: true });
    try {
      const accountId = rootGetters.getCurrentAccountId;
      await OrderNotesAPI.destroy(accountId, orderId, noteId);
      commit(types.DELETE_ORDER_NOTE, { orderId, noteId });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_ORDER_NOTES_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_ORDER_NOTES_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_ORDER_NOTES]($state, { data, orderId }) {
    $state.records = {
      ...$state.records,
      [orderId]: data,
    };
  },
  [types.ADD_ORDER_NOTE]($state, { data, orderId }) {
    const orderNotes = $state.records[orderId] || [];
    $state.records[orderId] = [...orderNotes, data];
  },
  [types.DELETE_ORDER_NOTE]($state, { noteId, orderId }) {
    const orderNotes = $state.records[orderId] || [];
    $state.records[orderId] = orderNotes.filter(note => note.id !== noteId);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
