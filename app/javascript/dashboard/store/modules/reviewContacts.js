import Vue from 'vue';
import BootstrapAPI from '../../api/bootstrap';
import db from '../../database';

const state = {
  contacts: {},
};

const MUTATIONS = {
  SET_CONTACTS: 'SET_CONTACTS',
};

export const getters = {
  getAll: $state => $state.contacts,
  getProcessedAll: $state =>
    Object.keys($state.contacts)
      .sort((c1, c2) => c1 - c2)
      .map(conversationId => ({
        ...$state.contacts[conversationId],
      })),
  getOne: $state => id => $state.contacts[id],
};

export const actions = {
  async bootstrap({ commit }) {
    const oldContacts = await db.contacts.toArray();
    commit(MUTATIONS.SET_CONTACTS, oldContacts);
    // const { data } = await BootstrapAPI.contacts();
    // await db.contacts.bulkPut(data);
    // commit(MUTATIONS.SET_CONTACTS, data);
  },
};

export const mutations = {
  [MUTATIONS.SET_CONTACTS]($state, contacts) {
    contacts.forEach(contact => {
      Vue.set($state.contacts, contact.id, contact);
    });
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
