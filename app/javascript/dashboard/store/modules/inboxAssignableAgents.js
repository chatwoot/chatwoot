import Vue from 'vue';

import AssignableAgentsAPI from '../../api/assignableAgents';

// Assignable Agents work on inboxId and the conversationId
// We should show all the agent have access to the inbox and the team which the conversation is part of
// To store this complex model, we store unique key  as a combination of
// requested conversation and inbox as follows
// Consider conversationId = 2 and inboxId = 3
// The key to access the list of agents is i-1-c-2

const state = {
  records: {},
  uiFlags: {
    isFetching: false,
  },
};

const getUniqueRecordId = ({ inboxIds = [], conversationIds = [] }) => {
  const sortedInboxIds = inboxIds.sort((i1, i2) => i1 - i2);
  const sortedConversationIds = conversationIds.sort((i1, i2) => i1 - i2);
  return (
    'i-' + sortedInboxIds.join('-') + '-c-' + sortedConversationIds.join('-')
  );
};

export const types = {
  SET_INBOX_ASSIGNABLE_AGENTS_UI_FLAG: 'SET_INBOX_ASSIGNABLE_AGENTS_UI_FLAG',
  SET_INBOX_ASSIGNABLE_AGENTS: 'SET_INBOX_ASSIGNABLE_AGENTS',
};

export const getters = {
  getAssignableAgents: $state => ({ conversationIds, inboxIds }) => {
    const allAgents =
      $state.records[getUniqueRecordId({ conversationIds, inboxIds })] || [];
    const verifiedAgents = allAgents.filter(record => record.confirmed);
    return verifiedAgents;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  async fetch({ commit }, { conversationIds = [], inboxIds = [] }) {
    commit(types.SET_INBOX_ASSIGNABLE_AGENTS_UI_FLAG, { isFetching: true });
    try {
      const {
        data: { payload },
      } = await AssignableAgentsAPI.get({ conversationIds, inboxIds });
      commit(types.SET_INBOX_ASSIGNABLE_AGENTS, {
        uniqueRecordId: getUniqueRecordId({ conversationIds, inboxIds }),
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
  [types.SET_INBOX_ASSIGNABLE_AGENTS]: (
    $state,
    { uniqueRecordId, members }
  ) => {
    Vue.set($state.records, uniqueRecordId, members);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
