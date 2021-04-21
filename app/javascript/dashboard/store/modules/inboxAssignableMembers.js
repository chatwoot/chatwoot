import Vue from 'vue';

import InboxesAPI from 'dashboard/api/inboxes.js';

const state = {
  records: {},
  uiFlags: {
    isFetching: false,
  },
};

export const types = {
  SET_INBOX_ASSIGNABLE_MEMBERS_UI_FLAG: 'SET_INBOX_ASSIGNABLE_MEMBERS_UI_FLAG',
  SET_INBOX_ASSIGNABLE_MEMBERS: 'SET_INBOX_ASSIGNABLE_MEMBERS',
};

export const getters = {
  getAssignableMembers: $state => inboxId => {
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
    commit(types.SET_INBOX_ASSIGNABLE_MEMBERS_UI_FLAG, { isFetching: true });
    try {
      const {
        data: { payload },
      } = await InboxesAPI.getAssignableMembers(inboxId);
      commit(types.SET_INBOX_ASSIGNABLE_MEMBERS, { inboxId, members: payload });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_INBOX_ASSIGNABLE_MEMBERS_UI_FLAG, { isFetching: false });
    }
  },
};

export const mutations = {
  [types.SET_INBOX_ASSIGNABLE_MEMBERS_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.SET_INBOX_ASSIGNABLE_MEMBERS]: ($state, { inboxId, members }) => {
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
