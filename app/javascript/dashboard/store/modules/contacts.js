/* eslint no-param-reassign: 0 */
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import * as types from '../mutation-types';
import ContactAPI from '../../api/contacts';

const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isFetchingItem: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

const getters = {
  getContacts($state) {
    return $state.records;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getContact: $state => id => {
    const [contact = {}] = $state.records.filter(
      record => record.id === Number(id)
    );
    return contact;
  },
};

const actions = {
  get: async ({ commit }) => {
    commit(types.default.SET_CONTACT_UI_FLAG, { isFetching: true });
    try {
      const response = await ContactAPI.get();
      commit(types.default.SET_SELECTED_CONTACT, response.data);
      commit(types.default.SET_CONTACTS, response.data);
      commit(types.default.SET_CONTACT_UI_FLAG, { isFetching: false });
    } catch (error) {
      commit(types.default.SET_CONTACT_UI_FLAG, { isFetching: false });
    }
  },

  show: async ({ commit }, { id }) => {
    commit(types.default.SET_CONTACT_UI_FLAG, { isFetchingItem: true });
    try {
      const response = await ContactAPI.show({ id });
      commit(types.default.SET_CONTACT_ITEM, response.data);
      commit(types.default.SET_CONTACT_UI_FLAG, { isFetchingItem: false });
    } catch (error) {
      commit(types.default.SET_CONTACT_UI_FLAG, { isFetchingItem: false });
    }
  },

  create: async ({ commit }, CONTACTObj) => {
    commit(types.default.SET_CONTACT_UI_FLAG, { isCreating: true });
    try {
      const response = await ContactAPI.create(CONTACTObj);
      commit(types.default.ADD_CONTACT, response.data);
      commit(types.default.SET_CONTACT_UI_FLAG, { isCreating: false });
    } catch (error) {
      commit(types.default.SET_CONTACT_UI_FLAG, { isCreating: false });
    }
  },

  update: async ({ commit }, { id, ...updateObj }) => {
    commit(types.default.SET_CONTACT_UI_FLAG, { isUpdating: true });
    try {
      const response = await ContactAPI.update(id, updateObj);
      commit(types.default.EDIT_CONTACT, response.data);
      commit(types.default.SET_CONTACT_UI_FLAG, { isUpdating: false });
    } catch (error) {
      commit(types.default.SET_CONTACT_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async ({ commit }, id) => {
    commit(types.default.SET_CONTACT_UI_FLAG, { isDeleting: true });
    try {
      await ContactAPI.delete(id);
      commit(types.default.DELETE_CONTACT, id);
      commit(types.default.SET_CONTACT_UI_FLAG, { isDeleting: true });
    } catch (error) {
      commit(types.default.SET_CONTACT_UI_FLAG, { isDeleting: true });
    }
  },
};

const mutations = {
  [types.default.SET_CONTACT_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },

  [types.default.SET_CONTACTS]: MutationHelpers.set,
  [types.default.SET_CONTACT_ITEM]: MutationHelpers.setSingleRecord,
  [types.default.ADD_CONTACT]: MutationHelpers.create,
  [types.default.EDIT_CONTACT]: MutationHelpers.update,
  [types.default.DELETE_CONTACT]: MutationHelpers.destroy,
};

export default {
  state,
  getters,
  actions,
  mutations,
};
