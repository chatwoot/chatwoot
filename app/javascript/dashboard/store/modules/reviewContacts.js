import Vue from 'vue';
import BootstrapAPI from '../../api/bootstrap';

const state = {
  contacts: {},
};

const MUTATIONS = {
  SET_CONTACTS: 'SET_CONTACTS',
};

export const getters = {
  get: $state => id => $state.contacts[id],
};

export const actions = {
  async bootstrap({ commit }) {
    const { data } = await BootstrapAPI.contacts();
    console.log(data);
    commit(MUTATIONS.SET_CONTACTS, data);
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
