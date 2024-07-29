import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import ChatbotAPI from '../../api/chatbots';
import { throwErrorMessage } from '../utils/api';

const state = {
  files: [],
  text: '',
  urls: [],
  records: [],
  uiFlags: {
    isFetchingItem: false,
    isFetching: false,
    isCreating: false,
    isDeleting: false,
    isUpdating: false,
  },
};

export const getters = {
  getFiles($state) {
    return $state.files || [];
  },
  getText($state) {
    return $state.text;
  },
  getUrls($state) {
    return $state.urls || [];
  },
  getChatbots($state) {
    return $state.records;
  },
  getChatbot: $state => id => {
    return $state.records.find(record => record.id === Number(id));
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  addFiles({ commit }, files) {
    commit(types.ADD_FILES, files);
  },
  deleteFiles({ commit }, index) {
    commit(types.DELETE_FILES, index);
  },
  setText({ commit }, text) {
    commit(types.SET_TEXT, text);
  },
  addUrls({ commit }, urls) {
    commit(types.ADD_URLS, urls);
  },
  deleteUrls({ commit }, index) {
    commit(types.DELETE_URLS, index);
  },
  get: async function getChatbots({ commit }) {
    commit(types.SET_CHATBOTS_UI_FLAG, { isFetching: true });
    try {
      const response = await ChatbotAPI.get();
      commit(types.SET_CHATBOTS, response.data.payload);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_CHATBOTS_UI_FLAG, { isFetching: false });
    }
  },
  getSingleChatbot: async function getChatbotById({ commit }, chatbotId) {
    commit(types.SET_CHATBOTS_UI_FLAG, { isFetchingItem: true });
    try {
      const response = await ChatbotAPI.show(chatbotId);
      commit(types.ADD_CHATBOT, response.data.payload);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_CHATBOTS_UI_FLAG, { isFetchingItem: false });
    }
  },
  create: async function createChatbot({ commit }, chatbotObj) {
    commit(types.SET_CHATBOTS_UI_FLAG, { isCreating: true });
    try {
      const response = await ChatbotAPI.createChatbot(chatbotObj);
      commit(types.ADD_CHATBOT, response.data.payload);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_CHATBOTS_UI_FLAG, { isCreating: false });
    }
  },
  update: async ({ commit }, { id, ...updateObj }) => {
    commit(types.SET_CHATBOTS_UI_FLAG, { isUpdating: true });
    try {
      const response = await ChatbotAPI.update(id, updateObj);
      commit(types.EDIT_CHATBOT, response.data.payload);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_CHATBOTS_UI_FLAG, { isUpdating: false });
    }
  },
  delete: async ({ commit }, id) => {
    commit(types.SET_CHATBOTS_UI_FLAG, { isDeleting: true });
    try {
      await ChatbotAPI.deleteChatbot(id);
      commit(types.DELETE_CHATBOT, id);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_CHATBOTS_UI_FLAG, { isDeleting: false });
    }
  },
  retrain: async function retrainChatbot({ commit }, chatbotObj) {
    commit(types.SET_CHATBOTS_UI_FLAG, { isUpdating: true });
    try {
      const response = await ChatbotAPI.retrainChatbot(chatbotObj);
      commit(types.EDIT_CHATBOT, response.data.payload);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_CHATBOTS_UI_FLAG, { isUpdating: false });
    }
  },
};

export const mutations = {
  [types.ADD_FILES]($state, files) {
    $state.files.push(...files);
  },
  [types.DELETE_FILES]($state, index) {
    $state.files.splice(index, 1);
  },
  [types.SET_TEXT]($state, text) {
    $state.text = text;
  },
  [types.ADD_URLS]($state, urls) {
    $state.urls.push(urls);
  },
  [types.DELETE_URLS]($state, index) {
    $state.urls.splice(index, 1);
  },
  [types.SET_CHATBOTS_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.ADD_CHATBOT]: MutationHelpers.setSingleRecord,
  [types.SET_CHATBOTS]: MutationHelpers.set,
  [types.EDIT_CHATBOT]: MutationHelpers.update,
  [types.DELETE_CHATBOT]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
