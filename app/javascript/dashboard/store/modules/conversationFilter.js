import types from '../mutation-types';
import wootConstants from '../../constants';

const state = {
  currentInboxId: null,
  currentConversationId: null,
  currentStatus: wootConstants.STATUS_TYPE.OPEN,
  currentAssigneeType: wootConstants.ASSIGNEE_TYPE.ME,
};

export const getters = {
  getConversationFilter: $state => $state,
  getCurrentInboxId: $state => $state.currentInboxId,
  getCurrentConversationId: $state => $state.currentConversationId,
  getCurrentConversationStatus: $state => $state.currentStatus,
  getCurrentAssigneeType: $state => $state.currentAssigneeType,
};

export const actions = {
  setActiveInbox({ commit }, inboxId) {
    commit(types.SET_ACTIVE_INBOX, inboxId);
  },
  setActiveConversation({ commit }, conversationId) {
    commit(types.SET_ACTIVE_CONVERSATION, conversationId);
  },
  setActiveAssigneeType({ commit }, assigneeType) {
    commit(types.SET_ACTIVE_ASSIGNEE_TYPE, assigneeType);
  },
  setActiveConversationStatus({ commit }, conversationStatus) {
    commit(types.SET_ACTIVE_CONVERSATION_STATUS, conversationStatus);
  },
};

export const mutations = {
  [types.SET_ACTIVE_INBOX]($state, inboxId) {
    $state.currentInboxId = inboxId ? Number(inboxId) : null;
  },
  [types.SET_ACTIVE_CONVERSATION]($state, conversationId) {
    $state.currentConversationId = conversationId
      ? Number(conversationId)
      : null;
  },
  [types.SET_ACTIVE_ASSIGNEE_TYPE]($state, assigneeType) {
    $state.currentAssigneeType = assigneeType;
  },
  [types.SET_ACTIVE_CONVERSATION_STATUS]($state, status) {
    $state.currentStatus = status;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
