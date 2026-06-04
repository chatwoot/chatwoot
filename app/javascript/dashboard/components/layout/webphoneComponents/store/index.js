// src/store.js

import Vue from 'vue';
import Vuex from 'vuex';

Vue.use(Vuex);

const store = new Vuex.Store({
  state: {
    message: 'Hello, World!',
  },
  mutations: {
    setMessage(state, payload) {
      state.message = payload;
    },
  },
  actions: {
    updateMessage({ commit }, newMessage) {
      commit('setMessage', newMessage);
    },
  },
  getters: {
    getMessage: state => state.message,
  },
});

export default store;
