import Vue from 'vue';
import * as types from '../../mutation-types';

import ChatList from '../../../api/inbox';
import ConversationApi from '../../../api/inbox/conversation';
import messageApi from '../../../api/inbox/message';

// actions
const actions = {
  fetchAllConversations({ commit }, fetchParams) {
    commit(types.default.SET_LIST_LOADING_STATUS);
    ChatList.fetchAllConversations(fetchParams, response => {
      commit(types.default.SET_ALL_CONVERSATION, {
        chats: response.data.data.payload,
      });
      commit(types.default.SET_CONV_TAB_META, {
        meta: response.data.data.meta,
      });
      commit(types.default.CLEAR_LIST_LOADING_STATUS);
    });
  },

  emptyAllConversations({ commit }) {
    commit(types.default.EMPTY_ALL_CONVERSATION);
  },

  clearSelectedState({ commit }) {
    commit(types.default.CLEAR_CURRENT_CHAT_WINDOW);
  },

  fetchPreviousMessages({ commit }, data) {
    const donePromise = new Promise(resolve => {
      messageApi
        .fetchPreviousMessages(data)
        .then(response => {
          commit(types.default.SET_PREVIOUS_CONVERSATIONS, {
            id: data.id,
            data: response.data.payload,
          });
          if (response.data.payload.length < 20) {
            commit(types.default.SET_ALL_MESSAGES_LOADED);
          }
          resolve();
        })
        .catch(error => {
          console.log(error);
        });
    });
    return donePromise;
  },

  setActiveChat(store, data) {
    const { commit } = store;
    const localDispatch = store.dispatch;
    let donePromise = null;

    commit(types.default.CURRENT_CHAT_WINDOW, data);
    commit(types.default.CLEAR_ALL_MESSAGES_LOADED);

    if (data.dataFetched === undefined) {
      donePromise = new Promise(resolve => {
        localDispatch('fetchPreviousMessages', {
          id: data.id,
          before: data.messages[0].id,
        })
          .then(() => {
            Vue.set(data, 'dataFetched', true);
            resolve();
          })
          .catch(error => {
            console.log(error);
          });
      });
    } else {
      donePromise = new Promise(resolve => {
        commit(types.default.SET_CHAT_META, { id: data.id });
        resolve();
      });
    }
    return donePromise;
  },

  assignAgent({ commit }, data) {
    return new Promise(resolve => {
      ConversationApi.assignAgent(data).then(response => {
        commit(types.default.ASSIGN_AGENT, response.data);
        resolve(response.data);
      });
    });
  },

  toggleStatus({ commit }, data) {
    return new Promise(resolve => {
      ConversationApi.toggleStatus(data).then(response => {
        commit(
          types.default.RESOLVE_CONVERSATION,
          response.data.payload.current_status
        );
        resolve(response.data);
      });
    });
  },

  sendMessage({ commit }, data) {
    return new Promise(resolve => {
      messageApi
        .sendMessage(data)
        .then(response => {
          commit(types.default.SEND_MESSAGE, response);
          resolve();
        })
        .catch();
    });
  },

  addPrivateNote({ commit }, data) {
    return new Promise(resolve => {
      messageApi
        .addPrivateNote(data)
        .then(response => {
          commit(types.default.SEND_MESSAGE, response);
          resolve();
        })
        .catch();
    });
  },

  addMessage({ commit }, message) {
    commit(types.default.ADD_MESSAGE, message);
  },

  addConversation({ commit }, conversation) {
    commit(types.default.ADD_CONVERSATION, conversation);
  },

  toggleTyping({ commit }, data) {
    return new Promise(resolve => {
      ConversationApi.fbTyping(data)
        .then(() => {
          commit(types.default.FB_TYPING, data);
          resolve();
        })
        .catch();
    });
  },

  markSeen({ commit }, data) {
    return new Promise(resolve => {
      ConversationApi.markSeen(data)
        .then(response => {
          commit(types.default.MARK_SEEN, response);
          resolve();
        })
        .catch();
    });
  },

  markMessagesRead({ commit }, data) {
    setTimeout(() => {
      commit(types.default.MARK_MESSAGE_READ, data);
    }, 4000);
    return new Promise(resolve => {
      ConversationApi.markMessageRead(data)
        .then(() => {
          resolve();
        })
        .catch();
    });
  },

  setChatFilter({ commit }, data) {
    commit(types.default.CHANGE_CHAT_STATUS_FILTER, data);
  },

  updateAssignee({ commit }, data) {
    commit(types.default.UPDATE_ASSIGNEE, data);
  },

  setActiveInbox({ commit }, inboxId) {
    commit(types.default.SET_ACTIVE_INBOX, inboxId);
  },
};

export default actions;
