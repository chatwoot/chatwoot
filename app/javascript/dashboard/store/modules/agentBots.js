import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import AgentBotsAPI from '../../api/agentBots';
import InboxesAPI from '../../api/inboxes';
import { throwErrorMessage } from '../utils/api';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isFetchingItem: false,
    isCreating: false,
    isDeleting: false,
    isUpdating: false,
    isFetchingAgentBot: false,
    isSettingAgentBot: false,
    isDisconnecting: false,
  },
  agentBotInbox: {},
};

export const getters = {
  getBots($state) {
    return $state.records;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getBot: $state => botId => {
    const [bot] = $state.records.filter(record => record.id === Number(botId));
    return bot || {};
  },
  getActiveAgentBot: $state => inboxId => {
    const associatedAgentBotId = $state.agentBotInbox[Number(inboxId)];
    return getters.getBot($state)(associatedAgentBotId);
  },
};

export const actions = {
  get: async ({ commit }) => {
    commit(types.SET_AGENT_BOT_UI_FLAG, { isFetching: true });
    try {
      const response = await AgentBotsAPI.get();
      commit(types.SET_AGENT_BOTS, response.data);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_AGENT_BOT_UI_FLAG, { isFetching: false });
    }
  },
  create: async ({ commit }, agentBotObj) => {
    commit(types.SET_AGENT_BOT_UI_FLAG, { isCreating: true });
    try {
      const response = await AgentBotsAPI.create(agentBotObj);
      commit(types.ADD_AGENT_BOT, response.data);
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_AGENT_BOT_UI_FLAG, { isCreating: false });
    }
    return null;
  },
  update: async ({ commit }, { id, ...agentBotObj }) => {
    commit(types.SET_AGENT_BOT_UI_FLAG, { isUpdating: true });
    try {
      const response = await AgentBotsAPI.update(id, agentBotObj);
      commit(types.EDIT_AGENT_BOT, response.data);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_AGENT_BOT_UI_FLAG, { isUpdating: false });
    }
  },
  delete: async ({ commit }, id) => {
    commit(types.SET_AGENT_BOT_UI_FLAG, { isDeleting: true });
    try {
      await AgentBotsAPI.delete(id);
      commit(types.DELETE_AGENT_BOT, id);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_AGENT_BOT_UI_FLAG, { isDeleting: false });
    }
  },
  show: async ({ commit }, id) => {
    commit(types.SET_AGENT_BOT_UI_FLAG, { isFetchingItem: true });
    try {
      const { data } = await AgentBotsAPI.show(id);
      commit(types.ADD_AGENT_BOT, data);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_AGENT_BOT_UI_FLAG, { isFetchingItem: false });
    }
  },

  fetchAgentBotInbox: async ({ commit }, inboxId) => {
    commit(types.SET_AGENT_BOT_UI_FLAG, { isFetchingAgentBot: true });
    try {
      const { data } = await InboxesAPI.getAgentBot(inboxId);
      const { agent_bot: agentBot = {} } = data || {};
      commit(types.SET_AGENT_BOT_INBOX, { agentBotId: agentBot.id, inboxId });
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_AGENT_BOT_UI_FLAG, { isFetchingAgentBot: false });
    }
  },

  setAgentBotInbox: async ({ commit }, { inboxId, botId }) => {
    commit(types.SET_AGENT_BOT_UI_FLAG, { isSettingAgentBot: true });
    try {
      await InboxesAPI.setAgentBot(inboxId, botId);
      commit(types.SET_AGENT_BOT_INBOX, { agentBotId: botId, inboxId });
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_AGENT_BOT_UI_FLAG, { isSettingAgentBot: false });
    }
  },

  disconnectBot: async ({ commit }, { inboxId }) => {
    commit(types.SET_AGENT_BOT_UI_FLAG, { isDisconnecting: true });
    try {
      await InboxesAPI.setAgentBot(inboxId, null);
      commit(types.SET_AGENT_BOT_INBOX, { agentBotId: '', inboxId });
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_AGENT_BOT_UI_FLAG, { isDisconnecting: false });
    }
  },
};

export const mutations = {
  [types.SET_AGENT_BOT_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.ADD_AGENT_BOT]: MutationHelpers.setSingleRecord,
  [types.SET_AGENT_BOTS]: MutationHelpers.set,
  [types.EDIT_AGENT_BOT]: MutationHelpers.update,
  [types.DELETE_AGENT_BOT]: MutationHelpers.destroy,
  [types.SET_AGENT_BOT_INBOX]($state, { agentBotId, inboxId }) {
    $state.agentBotInbox = {
      ...$state.agentBotInbox,
      [inboxId]: agentBotId,
    };
  },
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
