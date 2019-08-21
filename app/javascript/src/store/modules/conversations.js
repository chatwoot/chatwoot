/* eslint no-console: 0 */
/* eslint no-param-reassign: 0 */
import Vue from 'vue';
import * as types from '../mutation-types';
import ChatList from '../../api/inbox';
import ConversationApi from '../../api/inbox/conversation';
import messageApi from '../../api/inbox/message';
import authAPI from '../../api/auth';
import wootConstants from '../../constants';

// const chatType = 'all';
// initial state
const state = {
  allConversations: [],
  convTabStats: {
    mineCount: 0,
    unAssignedCount: 0,
    allCount: 0,
  },
  selectedChat: {
    id: null,
    meta: {},
    status: null,
    seen: false,
    agentTyping: 'off',
    dataFetched: false,
  },
  listLoadingStatus: true,
  chatStatusFilter: wootConstants.ASSIGNEE_TYPE_SLUG.OPEN,
  currentInbox: null,
};

// getters
const getters = {
  getAllConversations(_state) {
    return _state.allConversations;
  },
  getSelectedChat(_state) {
    return _state.selectedChat;
  },
  getMineChats(_state) {
    const currentUserID = authAPI.getCurrentUser().id;
    return _state.allConversations.filter(chat =>
      chat.meta.assignee === null
        ? false
        : chat.status === _state.chatStatusFilter &&
          chat.meta.assignee.id === currentUserID
    );
  },
  getUnAssignedChats(_state) {
    return _state.allConversations.filter(
      chat =>
        chat.meta.assignee === null && chat.status === _state.chatStatusFilter
    );
  },
  getAllStatusChats(_state) {
    return _state.allConversations.filter(
      chat => chat.status === _state.chatStatusFilter
    );
  },
  getChatListLoadingStatus(_state) {
    return _state.listLoadingStatus;
  },
  getAllMessagesLoaded(_state) {
    const [chat] = _state.allConversations.filter(
      c => c.id === _state.selectedChat.id
    );
    return chat.allMessagesLoaded === undefined
      ? false
      : chat.allMessagesLoaded;
  },
  getUnreadCount(_state) {
    const [chat] = _state.allConversations.filter(
      c => c.id === _state.selectedChat.id
    );
    return chat.messages.filter(
      chatMessage =>
        chatMessage.created_at * 1000 > chat.agent_last_seen_at * 1000 &&
        (chatMessage.message_type === 0 && chatMessage.private !== true)
    ).length;
  },
  getChatStatusFilter(_state) {
    return _state.chatStatusFilter;
  },
  getSelectedInbox(_state) {
    return _state.currentInbox;
  },
};

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

  // toggleStatusPusher({ commit }, data) {
  //   commit(types.default.RESOLVE_CONVERSATION, response.data.payload.current_status);
  // },

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

// mutations
const mutations = {
  [types.default.SET_ALL_CONVERSATION](_state, data) {
    if (data) {
      _state.allConversations.push(...data.chats);
    }
  },

  [types.default.EMPTY_ALL_CONVERSATION](_state) {
    _state.allConversations = [];
    _state.selectedChat = {
      id: null,
      meta: {},
      status: null,
      seen: false,
      agentTyping: 'off',
      dataFetched: false,
    };
  },

  [types.default.SET_ALL_MESSAGES_LOADED](_state) {
    const [chat] = _state.allConversations.filter(
      c => c.id === _state.selectedChat.id
    );
    Vue.set(chat, 'allMessagesLoaded', true);
  },

  [types.default.CLEAR_ALL_MESSAGES_LOADED](_state) {
    const [chat] = _state.allConversations.filter(
      c => c.id === _state.selectedChat.id
    );
    Vue.set(chat, 'allMessagesLoaded', false);
  },

  [types.default.CLEAR_CURRENT_CHAT_WINDOW](_state) {
    _state.selectedChat.id = null;
    _state.selectedChat.agentTyping = 'off';
  },

  [types.default.SET_PREVIOUS_CONVERSATIONS](_state, { id, data }) {
    if (data.length) {
      const [chat] = _state.allConversations.filter(c => c.id === id);
      chat.messages.unshift(...data);
    }
  },

  [types.default.SET_CONV_TAB_META](_state, { meta }) {
    if (meta) {
      Vue.set(_state.convTabStats, 'overdueCount', meta.overdue_count);
      Vue.set(_state.convTabStats, 'allConvCount', meta.all_count);
      Vue.set(_state.convTabStats, 'openCount', meta.open_count);
    }
  },

  [types.default.CURRENT_CHAT_WINDOW](_state, activeChat) {
    if (activeChat) {
      Object.assign(_state.selectedChat, activeChat);
      Vue.set(_state.selectedChat.meta, 'assignee', activeChat.meta.assignee);
      Vue.set(_state.selectedChat.meta, 'status', activeChat.meta.status);
    }
  },

  [types.default.APPEND_MESSAGES](_state, { id, data }) {
    if (data.length) {
      const [chat] = _state.allConversations.filter(c => c.id === id);
      chat.messages = data;
      Vue.set(chat, 'dataFetched', true);
    }
  },

  [types.default.SET_CHAT_META](_state, { id, data }) {
    const [chat] = _state.allConversations.filter(c => c.id === id);
    if (data !== undefined) {
      Vue.set(chat, 'labels', data.labels);
    }
  },

  [types.default.ASSIGN_AGENT](_state, assignee) {
    const [chat] = _state.allConversations.filter(
      c => c.id === _state.selectedChat.id
    );
    chat.meta.assignee = assignee;
    if (assignee === null) {
      Object.assign(_state.selectedChat.meta.assignee, assignee);
    }
  },

  [types.default.RESOLVE_CONVERSATION](_state, status) {
    const [chat] = _state.allConversations.filter(
      c => c.id === _state.selectedChat.id
    );
    chat.status = status;
    _state.selectedChat.status = status;
  },

  [types.default.SEND_MESSAGE](_state, response) {
    const [chat] = _state.allConversations.filter(
      c => c.id === _state.selectedChat.id
    );
    const previousMessageIds = chat.messages.map(m => m.id);
    if (!previousMessageIds.includes(response.data.id)) {
      chat.messages.push(response.data);
    }
  },

  [types.default.ADD_MESSAGE](_state, message) {
    const [chat] = _state.allConversations.filter(
      c => c.id === message.conversation_id
    );
    if (!chat) return;
    const previousMessageIds = chat.messages.map(m => m.id);
    if (!previousMessageIds.includes(message.id)) {
      chat.messages.push(message);
      if (_state.selectedChat.id === message.conversation_id) {
        window.bus.$emit('scrollToMessage');
      }
    }
  },

  [types.default.ADD_CONVERSATION](_state, conversation) {
    _state.allConversations.push(conversation);
  },

  [types.default.MARK_SEEN](_state, response) {
    if (response.status === 200) {
      _state.selectedChat.seen = true;
    }
  },

  [types.default.FB_TYPING](_state, { flag }) {
    _state.selectedChat.agentTyping = flag;
  },

  [types.default.SET_LIST_LOADING_STATUS](_state) {
    _state.listLoadingStatus = true;
  },

  [types.default.CLEAR_LIST_LOADING_STATUS](_state) {
    _state.listLoadingStatus = false;
  },

  [types.default.MARK_MESSAGE_READ](_state, { id, lastSeen }) {
    const [chat] = _state.allConversations.filter(c => c.id === id);
    chat.agent_last_seen_at = lastSeen;
  },

  [types.default.CHANGE_CHAT_STATUS_FILTER](_state, data) {
    _state.chatStatusFilter = data;
  },

  // Update assignee on pusher message
  [types.default.UPDATE_ASSIGNEE](_state, payload) {
    const [chat] = _state.allConversations.filter(c => c.id === payload.id);
    chat.meta.assignee = payload.assignee;
  },

  [types.default.SET_ACTIVE_INBOX](_state, inboxId) {
    _state.currentInbox = inboxId;
  },
};

export default {
  state,
  getters,
  actions,
  mutations,
};
