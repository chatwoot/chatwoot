import types from '../mutation-types';

const state = {
  botFiles: [],
  botText: '',
  botUrls: [],
};

export const getters = {
  getBotFiles($state) {
    return $state.botFiles || [];
  },
  getBotText($state) {
    return $state.botText;
  },
  getBotUrls($state) {
    return $state.botUrls || [];
  },
};

export const actions = {
  addBotFiles({ commit }, files) {
    commit(types.ADD_BOT_FILES, files);
  },
  deleteBotFiles({ commit }, index) {
    commit(types.DELETE_BOT_FILES, index);
  },
  setBotText({ commit }, text) {
    commit(types.SET_BOT_TEXT, text);
  },
  addBotUrls({ commit }, urls) {
    commit(types.ADD_BOT_URLS, urls);
  },
  deleteBotUrls({ commit }, index) {
    commit(types.DELETE_BOT_URLS, index);
  },
};

export const mutations = {
  [types.ADD_BOT_FILES]($state, files) {
    $state.botFiles.push(...files);
  },
  [types.DELETE_BOT_FILES]($state, index) {
    $state.botFiles.splice(index, 1);
  },
  [types.SET_BOT_TEXT]($state, text) {
    $state.botText = text;
  },
  [types.ADD_BOT_URLS]($state, urls) {
    $state.botUrls.push(urls);
  },
  [types.DELETE_BOT_URLS]($state, index) {
    $state.botUrls.splice(index, 1);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
