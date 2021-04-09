import Vue from 'vue';

import InboxMembersAPI from '../../api/inboxMembers';

const state = {
  records: {},
  uiFlags: {
    isFetching: false,
  },
};

export const types = {
  SET_INBOX_MEMBERS_UI_FLAG: 'SET_INBOX_MEMBERS_UI_FLAG',
  SET_INBOX_MEMBERS: 'SET_INBOX_MEMBERS',
};

export const getters = {
  getMembersByInbox: $state => inboxId => {
    const allAgents = $state.records[inboxId] || [];
    const verifiedAgents = allAgents.filter(record => record.confirmed);
    return verifiedAgents;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  async fetch({ commit }, { inboxId }) {
    commit(types.SET_INBOX_MEMBERS_UI_FLAG, { isFetching: true });
    try {
      const {
        data: { payload },
      } = await InboxMembersAPI.show(inboxId);
      commit(types.SET_INBOX_MEMBERS, { inboxId, members: payload });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_INBOX_MEMBERS_UI_FLAG, { isFetching: false });
    }
  },
  get(_, { inboxId }) {
    return InboxMembersAPI.show(inboxId);
  },
  create(_, { inboxId, agentList }) {
    return InboxMembersAPI.create({ inboxId, agentList });
  },
};

export const mutations = {
  [types.SET_INBOX_MEMBERS_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.SET_INBOX_MEMBERS]: ($state, { inboxId, members }) => {
    Vue.set($state.records, inboxId, members);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
