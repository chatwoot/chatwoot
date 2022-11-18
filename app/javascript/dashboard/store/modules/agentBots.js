import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import AgentBotsAPI from '../../api/agentBots';
import { throwErrorMessage } from '../utils/api';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isFetchingItem: false,
    isCreating: false,
    isDeleting: false,
    isUpdating: false,
  },
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
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
