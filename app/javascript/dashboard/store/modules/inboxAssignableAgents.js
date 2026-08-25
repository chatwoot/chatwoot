import AssignableAgentsAPI from '../../api/assignableAgents';

const state = {
  records: {},
  uiFlags: {
    isFetching: false,
  },
};

const recordKey = (inboxId, { includeAgentBots = false } = {}) =>
  includeAgentBots ? `${inboxId}:with_agent_bots` : inboxId;

export const types = {
  SET_INBOX_ASSIGNABLE_AGENTS_UI_FLAG: 'SET_INBOX_ASSIGNABLE_AGENTS_UI_FLAG',
  SET_INBOX_ASSIGNABLE_AGENTS: 'SET_INBOX_ASSIGNABLE_AGENTS',
};

export const getters = {
  getAssignableAgents:
    $state =>
    (inboxId, options = {}) => {
      const includeAgentBots = options.includeAgentBots || false;
      const allAgents = $state.records[recordKey(inboxId, options)] || [];
      const verifiedAgents = allAgents.filter(
        record =>
          record.confirmed ||
          (includeAgentBots && record.assignee_type === 'AgentBot')
      );
      return verifiedAgents;
    },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  async fetch({ commit }, actionPayload) {
    const inboxIds = Array.isArray(actionPayload)
      ? actionPayload
      : actionPayload.inboxIds;
    const includeAgentBots =
      !Array.isArray(actionPayload) && actionPayload.includeAgentBots;
    commit(types.SET_INBOX_ASSIGNABLE_AGENTS_UI_FLAG, { isFetching: true });
    try {
      const {
        data: { payload },
      } = await AssignableAgentsAPI.get(inboxIds, { includeAgentBots });
      if (includeAgentBots) {
        commit(types.SET_INBOX_ASSIGNABLE_AGENTS, {
          inboxId: inboxIds.join(','),
          members: payload,
        });
      }
      commit(types.SET_INBOX_ASSIGNABLE_AGENTS, {
        inboxId: recordKey(inboxIds.join(','), { includeAgentBots }),
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
    $state.records = {
      ...$state.records,
      [inboxId]: members,
    };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
