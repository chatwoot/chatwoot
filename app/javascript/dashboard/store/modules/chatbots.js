import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import ChatbotAPI from '../../api/chatbots';
import { throwErrorMessage } from '../utils/api';

const state = {
  char: 0,
  files: [],
  text: '',
  links: [],
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
  getChar($state) {
    return $state.char;
  },
  getFiles($state) {
    return $state.files || [];
  },
  getText($state) {
    return $state.text;
  },
  getLinks($state) {
    return $state.links || [];
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
  incChar({ commit }, count) {
    commit(types.INC_CHAR, count);
  },
  decChar({ commit }, count) {
    commit(types.DEC_CHAR, count);
  },
  addFiles({ commit }, files) {
    files.forEach(file => {
      commit(types.ADD_FILES, file);
      commit(types.INC_CHAR, file.char_count);
    });
  },
  deleteFile({ commit }, index) {
    commit(types.DELETE_FILE, index);
  },
  setText({ commit }, text) {
    commit(types.SET_TEXT, text);
  },
  addLink({ commit }, links) {
    links.forEach(link => {
      commit(types.ADD_LINK, link);
      commit(types.INC_CHAR, link.char_count);
    });
  },
  deleteLink({ commit }, index) {
    commit(types.DELETE_LINK, index);
  },
  deleteLinks({ commit }) {
    commit(types.DELETE_ALL_LINKS);
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
      commit(types.SET_CHATBOTS, response.data.payload);
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
  getSavedData: async function getSavedData({ commit }, chatbotId) {
    commit(types.SET_CHATBOTS_UI_FLAG, { isUpdating: true });
    try {
      const response = await ChatbotAPI.getSavedData(chatbotId);
      const data = response.data;
      if (data.urls) {
        data.urls.forEach(savedLink => {
          if (
            !state.links.some(
              existingLink => existingLink.link === savedLink.link
            )
          ) {
            commit(types.ADD_LINK, savedLink);
            commit(types.INC_CHAR, savedLink.char_count);
          }
        });
      }
      if (data.text) {
        if (!state.text.includes(data.text)) {
          commit(types.SET_TEXT, data.text);
          const textLength = data.text.length;
          commit(types.INC_CHAR, textLength);
        }
      }

      if (data.files) {
        return data.files;
      }
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_CHATBOTS_UI_FLAG, { isUpdating: false });
    }
    return null;
  },
  destroyAttachment: async ({ commit }, data) => {
    commit(types.SET_CHATBOTS_UI_FLAG, { isDeleting: true });
    try {
      const response = await ChatbotAPI.destroyAttachment(data);
      return response;
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_CHATBOTS_UI_FLAG, { isDeleting: false });
    }
    return null;
  },
};

export const mutations = {
  [types.INC_CHAR]($state, count) {
    $state.char += count;
  },
  [types.DEC_CHAR]($state, count) {
    $state.char -= count;
  },
  [types.ADD_FILES]($state, files) {
    $state.files.push(files);
  },
  [types.DELETE_FILE]($state, index) {
    $state.files.splice(index, 1);
  },
  [types.SET_TEXT]($state, text) {
    $state.text = text;
  },
  [types.ADD_LINK]($state, link) {
    $state.links.push(link);
  },
  [types.DELETE_LINK]($state, index) {
    $state.links.splice(index, 1);
  },
  [types.DELETE_ALL_LINKS]($state) {
    $state.links = [];
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
