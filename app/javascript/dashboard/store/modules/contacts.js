/* eslint no-param-reassign: 0 */
import * as types from '../mutation-types';
import ContactAPI from '../../api/contacts';

const state = {
  records: [],
  selectedRecord: {},
  uiFlags: {
    fetchingList: false,
    fetchingItem: false,
    creatingItem: false,
    updatingItem: false,
    deletingItem: false,
  },
};

const getters = {
  getContacts(_state) {
    return _state.records;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getSelectedRecord(_state) {
    return _state.selectedRecord;
  },
};

const actions = {
  getContact: async function getContact({ commit }, { id, setSelectedRecord }) {
    commit(types.default.SET_CONTACT_UI_FLAG, { fetchingList: true });
    try {
      const response = await ContactAPI.show({ id });
      if (setSelectedRecord) {
        commit(types.default.SET_SELECTED_CONTACT, response.data);
      }
      commit(types.default.SET_CONTACT, response.data);
      commit(types.default.SET_CONTACT_UI_FLAG, { fetchingList: false });
    } catch (error) {
      commit(types.default.SET_CONTACT_UI_FLAG, { fetchingList: false });
    }
  },

  createContact: async function createContact({ commit }, CONTACTObj) {
    commit(types.default.SET_CONTACT_UI_FLAG, { creatingItem: true });
    try {
      const response = await ContactAPI.create(CONTACTObj);
      commit(types.default.ADD_CONTACT, response.data);
      commit(types.default.SET_CONTACT_UI_FLAG, { creatingItem: false });
    } catch (error) {
      commit(types.default.SET_CONTACT_UI_FLAG, { creatingItem: false });
    }
  },

  updateContact: async function updateContact(
    { commit },
    { id, ...updateObj }
  ) {
    commit(types.default.SET_CONTACT_UI_FLAG, { updatingItem: true });
    try {
      const response = await ContactAPI.update(id, updateObj);
      commit(types.default.EDIT_CONTACT, response.data);
      commit(types.default.SET_CONTACT_UI_FLAG, { updatingItem: false });
    } catch (error) {
      commit(types.default.SET_CONTACT_UI_FLAG, { updatingItem: false });
    }
  },

  deleteContact: async function deleteContact({ commit }, id) {
    commit(types.default.SET_CONTACT_UI_FLAG, { deletingItem: true });
    try {
      await ContactAPI.delete(id);
      commit(types.default.DELETE_CONTACT, id);
      commit(types.default.SET_CONTACT_UI_FLAG, { deletingItem: true });
    } catch (error) {
      commit(types.default.SET_CONTACT_UI_FLAG, { deletingItem: true });
    }
  },
};

const mutations = {
  [types.default.SET_CONTACT_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.default.SET_CONTACT](_state, data) {
    _state.records = data;
  },

  [types.default.ADD_CONTACT](_state, data) {
    _state.records.push(data);
  },

  [types.default.EDIT_CONTACT](_state, data) {
    _state.records.forEach((element, index) => {
      if (element.id === data.id) {
        _state.records[index] = data;
      }
    });
  },

  [types.default.DELETE_CONTACT](_state, id) {
    _state.records = _state.records.filter(
      CONTACTResponse => CONTACTResponse.id !== id
    );
  },

  [types.default.SET_SELECTED_CONTACT](_state, record) {
    _state.selectedRecord = record;
  },
};

export default {
  state,
  getters,
  actions,
  mutations,
};
