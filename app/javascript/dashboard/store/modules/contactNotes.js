import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import * as types from '../mutation-types';
import ContactNotesAPI from '../../api/contactNotes';

const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isDeleting: false,
  },
};

const getters = {
  getAllNotes(_state) {
    return _state.records;
  },
  getNotesUIFlags(_state) {
    return _state.uiFlags;
  },
};

const actions = {
  async get({ commit }) {
    commit(types.default.SET_CONTACT_NOTES_UI_FLAG, { isFetching: true });
    try {
      const response = await ContactNotesAPI.get();
      commit(types.default.SET_CONTACT_NOTES, response.data);
      commit(types.default.SET_CONTACT_NOTES_UI_FLAG, { isFetching: false });
    } catch (error) {
      commit(types.default.SET_CONTACT_NOTES_UI_FLAG, { isFetching: false });
    }
  },

  async create({ commit }, newNote) {
    commit(types.default.SET_CONTACT_NOTES_UI_FLAG, { isCreating: true });
    try {
      const response = await ContactNotesAPI.create(newNote);
      commit(types.default.ADD_CONTACT_NOTES, response.data);
      commit(types.default.SET_CONTACT_NOTES_UI_FLAG, { isCreating: false });
    } catch (error) {
      commit(types.default.SET_CONTACT_NOTES_UI_FLAG, { isCreating: false });
    }
  },

  async update({ commit }, { id, ...updateObj }) {
    commit(types.default.SET_CONTACT_NOTES_UI_FLAG, { updatingItem: true });
    try {
      const response = await ContactNotesAPI.update(id, updateObj);
      commit(types.default.EDIT_CONTACT_NOTES, response.data);
      commit(types.default.SET_CONTACT_NOTES_UI_FLAG, { updatingItem: false });
    } catch (error) {
      commit(types.default.SET_CONTACT_NOTES_UI_FLAG, { updatingItem: false });
    }
  },

  async delete({ commit }, id) {
    commit(types.default.SET_CONTACT_NOTES_UI_FLAG, { deletingItem: true });
    try {
      await ContactNotesAPI.delete(id);
      commit(types.default.DELETE_CONTACT_NOTES, id);
      commit(types.default.SET_CONTACT_NOTES_UI_FLAG, { deletingItem: true });
    } catch (error) {
      commit(types.default.SET_CONTACT_NOTES_UI_FLAG, { deletingItem: true });
    }
  },
};

const mutations = {
  [types.default.SET_CONTACT_NOTES_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.default.SET_CONTACT_NOTES]: MutationHelpers.set,
  [types.default.ADD_CONTACT_NOTES]: MutationHelpers.create,
  [types.default.EDIT_CONTACT_NOTES]: MutationHelpers.update,
  [types.default.DELETE_CONTACT_NOTES]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
