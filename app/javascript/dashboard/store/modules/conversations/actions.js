import Vue from 'vue';
import * as types from '../../mutation-types';
import ConversationApi from '../../../api/inbox/conversation';
import MessageApi from '../../../api/inbox/message';
import { MESSAGE_TYPE } from 'widget/helpers/constants';

// actions
const actions = {
  getConversation: async ({ commit }, conversationId) => {
    try {
      const response = await ConversationApi.show(conversationId);
      commit(types.default.UPDATE_CONVERSATION, response.data);
      commit(
        `contacts/${types.default.SET_CONTACT_ITEM}`,
        response.data.meta.sender
      );
    } catch (error) {
      // Ignore error
    }
  },

  fetchAllConversations: async ({ commit, dispatch }, params) => {
    commit(types.default.SET_LIST_LOADING_STATUS);
    try {
      const response = await ConversationApi.get(params);
      const { data } = response.data;
      const { payload: chatList, meta: metaData } = data;
      commit(types.default.SET_ALL_CONVERSATION, chatList);
      dispatch('conversationStats/set', metaData);
      dispatch('conversationLabels/setBulkConversationLabels', chatList);
      commit(types.default.CLEAR_LIST_LOADING_STATUS);
      commit(
        `contacts/${types.default.SET_CONTACTS}`,
        chatList.map(chat => chat.meta.sender)
      );
      dispatch(
        'conversationPage/setCurrentPage',
        {
          filter: params.assigneeType,
          page: params.page,
        },
        { root: true }
      );
      if (!chatList.length) {
        dispatch(
          'conversationPage/setEndReached',
          { filter: params.assigneeType },
          { root: true }
        );
      }
    } catch (error) {
      // Handle error
    }
  },

  emptyAllConversations({ commit }) {
    commit(types.default.EMPTY_ALL_CONVERSATION);
  },

  clearSelectedState({ commit }) {
    commit(types.default.CLEAR_CURRENT_CHAT_WINDOW);
  },

  fetchPreviousMessages: async ({ commit }, data) => {
    try {
      const {
        data: { meta, payload },
      } = await MessageApi.getPreviousMessages(data);
      commit(
        `conversationMetadata/${types.default.SET_CONVERSATION_METADATA}`,
        {
          id: data.conversationId,
          data: meta,
        }
      );
      commit(types.default.SET_PREVIOUS_CONVERSATIONS, {
        id: data.conversationId,
        data: payload,
      });
      if (payload.length < 20) {
        commit(types.default.SET_ALL_MESSAGES_LOADED);
      }
    } catch (error) {
      // Handle error
    }
  },

  async setActiveChat({ commit, dispatch }, data) {
    commit(types.default.SET_CURRENT_CHAT_WINDOW, data);
    commit(types.default.CLEAR_ALL_MESSAGES_LOADED);

    if (data.dataFetched === undefined) {
      try {
        await dispatch('fetchPreviousMessages', {
          conversationId: data.id,
          before: data.messages[0].id,
        });
        Vue.set(data, 'dataFetched', true);
      } catch (error) {
        // Ignore error
      }
    }
  },

  assignAgent: async ({ commit }, { conversationId, agentId }) => {
    try {
      const response = await ConversationApi.assignAgent({
        conversationId,
        agentId,
      });
      commit(types.default.ASSIGN_AGENT, response.data);
    } catch (error) {
      // Handle error
    }
  },

  toggleStatus: async ({ commit }, data) => {
    try {
      const response = await ConversationApi.toggleStatus(data);
      commit(
        types.default.RESOLVE_CONVERSATION,
        response.data.payload.current_status
      );
    } catch (error) {
      // Handle error
    }
  },

  sendMessage: async ({ commit }, data) => {
    try {
      const response = await MessageApi.create(data);
      commit(types.default.SEND_MESSAGE, response.data);
    } catch (error) {
      // Handle error
    }
  },

  addMessage({ commit }, message) {
    commit(types.default.ADD_MESSAGE, message);
    if (message.message_type === MESSAGE_TYPE.INCOMING) {
      commit(types.default.SET_CONVERSATION_CAN_REPLY, {
        conversationId: message.conversation_id,
        canReply: true,
      });
    }
  },

  updateMessage({ commit }, message) {
    commit(types.default.ADD_MESSAGE, message);
  },

  addConversation({ commit, state, dispatch }, conversation) {
    const { currentInbox } = state;
    const {
      inbox_id: inboxId,
      meta: { sender },
    } = conversation;
    if (!currentInbox || Number(currentInbox) === inboxId) {
      commit(types.default.ADD_CONVERSATION, conversation);
      dispatch('contacts/setContact', sender);
    }
  },

  updateConversation({ commit, dispatch }, conversation) {
    const {
      meta: { sender },
    } = conversation;
    commit(types.default.UPDATE_CONVERSATION, conversation);
    dispatch('contacts/setContact', sender);
  },

  markMessagesRead: async ({ commit }, data) => {
    setTimeout(() => {
      commit(types.default.MARK_MESSAGE_READ, data);
    }, 4000);
    try {
      await ConversationApi.markMessageRead(data);
    } catch (error) {
      // Handle error
    }
  },

  setChatFilter({ commit }, data) {
    commit(types.default.CHANGE_CHAT_STATUS_FILTER, data);
  },

  updateAssignee({ commit }, data) {
    commit(types.default.UPDATE_ASSIGNEE, data);
  },

  updateConversationContact({ commit }, data) {
    if (data.id) {
      commit(`contacts/${types.default.SET_CONTACT_ITEM}`, data);
    }
    commit(types.default.UPDATE_CONVERSATION_CONTACT, data);
  },

  setActiveInbox({ commit }, inboxId) {
    commit(types.default.SET_ACTIVE_INBOX, inboxId);
  },

  sendAttachment: async ({ commit }, data) => {
    try {
      const response = await MessageApi.sendAttachment(data);
      commit(types.default.SEND_MESSAGE, response.data);
    } catch (error) {
      // Handle error
    }
  },

  muteConversation: async ({ commit }, conversationId) => {
    try {
      await ConversationApi.mute(conversationId);
      commit(types.default.MUTE_CONVERSATION);
    } catch (error) {
      //
    }
  },
};

export default actions;
