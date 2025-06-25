import Vue from 'vue';
import * as types from '../mutation-types';
import ContactAPI from '../../api/contacts';
import ConversationApi from '../../api/conversations';

const state = {
  records: {},
  uiFlags: {
    isFetching: false,
  },
};

export const getters = {
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getContactConversation: $state => id => {
    return $state.records[Number(id)] || [];
  },
};

export const actions = {
  create: async ({ commit }, params) => {
    commit(types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG, {
      isCreating: true,
    });
    const {
      inboxId,
      message,
      contactId,
      sourceId,
      mailSubject,
      assigneeId,
    } = params;
    try {
      const { data } = await ConversationApi.create({
        inbox_id: inboxId,
        contact_id: contactId,
        source_id: sourceId,
        additional_attributes: {
          mail_subject: mailSubject,
        },
        message,
        assignee_id: assigneeId,
      });
      commit(types.default.ADD_CONTACT_CONVERSATION, {
        id: contactId,
        data,
      });
      return data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG, {
        isCreating: false,
      });
    }
  },
  get: async ({ commit }, contactId) => {
    commit(types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG, {
      isFetching: true,
    });
    try {
      const response = await ContactAPI.getConversations(contactId);
      commit(types.default.SET_CONTACT_CONVERSATIONS, {
        id: contactId,
        data: response.data.payload,
      });
      commit(types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG, {
        isFetching: false,
      });
    } catch (error) {
      commit(types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG, {
        isFetching: false,
      });
    }
  },
};

export const mutations = {
  [types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.default.SET_CONTACT_CONVERSATIONS]: ($state, { id, data }) => {
    Vue.set($state.records, id, data);
  },
  [types.default.ADD_CONTACT_CONVERSATION]: ($state, { id, data }) => {
    const conversations = $state.records[id] || [];

    const updatedConversations = [...conversations];
    const index = conversations.findIndex(
      conversation => conversation.id === data.id
    );

    if (index !== -1) {
      updatedConversations[index] = { ...conversations[index], ...data };
    } else {
      updatedConversations.push(data);
    }

    Vue.set($state.records, id, updatedConversations);
  },
  [types.default.DELETE_CONTACT_CONVERSATION]: ($state, id) => {
    Vue.delete($state.records, id);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
