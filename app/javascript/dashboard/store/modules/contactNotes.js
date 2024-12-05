import types from '../mutation-types';
import ContactNotesAPI from '../../api/contactNotes';
import camelcaseKeys from 'camelcase-keys';

export const state = {
  records: {},
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isDeleting: false,
  },
};

export const getters = {
  getAllNotesByContact: _state => contactId => {
    const records = _state.records[contactId] || [];
    return records.sort((r1, r2) => r2.id - r1.id);
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getAllNotesByContactId: _state => contactId => {
    const records = _state.records[contactId] || [];
    const contactNotes = records.sort((r1, r2) => r2.id - r1.id);
    return camelcaseKeys(contactNotes);
  },
};

export const actions = {
  async get({ commit }, { contactId }) {
    commit(types.SET_CONTACT_NOTES_UI_FLAG, { isFetching: true });
    try {
      const { data } = await ContactNotesAPI.get(contactId);
      commit(types.SET_CONTACT_NOTES, { contactId, data });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_CONTACT_NOTES_UI_FLAG, { isFetching: false });
    }
  },

  async create({ commit }, { contactId, content }) {
    commit(types.SET_CONTACT_NOTES_UI_FLAG, { isCreating: true });
    try {
      const { data } = await ContactNotesAPI.create(contactId, content);
      commit(types.ADD_CONTACT_NOTE, { contactId, data });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_CONTACT_NOTES_UI_FLAG, { isCreating: false });
    }
  },

  async delete({ commit }, { noteId, contactId }) {
    commit(types.SET_CONTACT_NOTES_UI_FLAG, { isDeleting: true });
    try {
      await ContactNotesAPI.delete(contactId, noteId);
      commit(types.DELETE_CONTACT_NOTE, { contactId, noteId });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_CONTACT_NOTES_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_CONTACT_NOTES_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_CONTACT_NOTES]($state, { data, contactId }) {
    $state.records = {
      ...$state.records,
      [contactId]: data,
    };
  },
  [types.ADD_CONTACT_NOTE]($state, { data, contactId }) {
    const contactNotes = $state.records[contactId] || [];
    $state.records[contactId] = [...contactNotes, data];
  },
  [types.DELETE_CONTACT_NOTE]($state, { noteId, contactId }) {
    const contactNotes = $state.records[contactId];
    const withoutDeletedNote = contactNotes.filter(note => note.id !== noteId);
    $state.records[contactId] = [...withoutDeletedNote];
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
