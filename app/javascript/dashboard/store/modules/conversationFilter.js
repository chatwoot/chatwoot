import * as types from '../mutation-types';
import wootConstants from '../../constants';

const state = {
  currentInboxId: null,
  currentConversationId: null,
  currentStatus: wootConstants.STATUS_TYPE.OPEN,
};

export const getters = {
  getConversationFilter: $state => $state,
};

export const actions = {
  setActiveInbox({ commit }, inboxId) {
    commit(types.default.SET_ACTIVE_INBOX, inboxId);
  },
};

export const mutations = {
  [types.default.SET_ACTIVE_INBOX]($state, inboxId) {
    $state.currentInbox = inboxId;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
