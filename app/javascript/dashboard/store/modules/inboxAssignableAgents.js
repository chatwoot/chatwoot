import Vue from 'vue';

import AssignableAgentsAPI from '../../api/assignableAgents';

const state = {
  records: {},
  uiFlags: {
    isFetching: false,
  },
};

export const types = {
  SET_INBOX_ASSIGNABLE_AGENTS_UI_FLAG: 'SET_INBOX_ASSIGNABLE_AGENTS_UI_FLAG',
  SET_INBOX_ASSIGNABLE_AGENTS: 'SET_INBOX_ASSIGNABLE_AGENTS',
};

export const getters = {
  getAssignableAgents: $state => inboxId => {
    const allAgents = $state.records[inboxId] || [];
    const verifiedAgents = allAgents.filter(record => record.confirmed);
    return verifiedAgents;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  async fetch({ commit }, inboxIds) {
    commit(types.SET_INBOX_ASSIGNABLE_AGENTS_UI_FLAG, { isFetching: true });
    try {
      const {
        data: { payload },
      } = await AssignableAgentsAPI.get(inboxIds);
      commit(types.SET_INBOX_ASSIGNABLE_AGENTS, {
        inboxId: inboxIds.join(','),
        members: payload,
      });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_INBOX_ASSIGNABLE_AGENTS_UI_FLAG, { isFetching: false });
    }
  },
};

export const mutations = {
  [types.SET_INBOX_ASSIGNABLE_AGENTS_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.SET_INBOX_ASSIGNABLE_AGENTS]: ($state, { inboxId, members }) => {
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
