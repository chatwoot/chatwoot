import Vue from 'vue';
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';

const state = {
  botFiles: [],
  botText: '',
  botUrls: [],
};

const getters = {
  getBotFiles: state => state.botFiles,
  getBotText: state => state.botText,
  getBotUrls: state => state.botUrls,
  getChatbotNames: state => state.chatbotNames,
};

const actions = {
  addBotUrl({ commit }, url) {
    commit(types.ADD_BOT_URL, url);
  },
  setBotText({ commit }, text) {
    commit(types.SET_BOT_TEXT, text);
  },
  addBotFiles({ commit }, files) {
    commit(types.ADD_BOT_FILES, files);
  },
  deleteBotFile({ commit }, index) {
    commit(types.DELETE_BOT_FILE, index);
  },
  deleteBotUrl({ commit }, index) {
    commit(types.DELETE_BOT_URL, index);
  },
};

const mutations = {
  [types.ADD_BOT_URL](state, url) {
    state.botUrls.push(url);
  },
  [types.SET_BOT_TEXT](state, text) {
    state.botText = text;
  },
  [types.ADD_BOT_FILES](state, files) {
    state.botFiles = [...state.botFiles, ...files];
  },
  [types.DELETE_BOT_FILE](state, index) {
    state.botFiles.splice(index, 1);
  },
  [types.DELETE_BOT_URL](state, index) {
    state.botUrls.splice(index, 1);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
