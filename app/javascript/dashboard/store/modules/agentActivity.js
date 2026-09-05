import types from '../mutation-types';
import AgentActivityAPI from '../../api/agentActivity';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
  },
};

export const getters = {
  getAgentActivity($state) {
    return $state.records;
  },

  getVisibleAgentActivity($state) {
    return $state.records;
  },

  getUIFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  get: async (
    { commit },
    {
      since,
      until,
      teamIds = [],
      userIds = [],
      inboxIds = [],
      hideInactive = false,
      timezoneOffset = 0,
    }
  ) => {
    commit(types.SET_AGENT_ACTIVITY_FETCHING_STATUS, true);

    try {
      const response = await AgentActivityAPI.getSummary({
        since,
        until,
        teamIds,
        userIds,
        inboxIds,
        hideInactive,
        timezoneOffset,
      });

      commit(types.SET_AGENT_ACTIVITY, response.data);
    } finally {
      commit(types.SET_AGENT_ACTIVITY_FETCHING_STATUS, false);
    }
  },
};

export const mutations = {
  [types.SET_AGENT_ACTIVITY_FETCHING_STATUS]($state, status) {
    $state.uiFlags.isFetching = status;
  },

  [types.SET_AGENT_ACTIVITY]($state, agents) {
    $state.records = agents;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
