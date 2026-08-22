import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import CaptainAssistantAPI from '../../api/captain/assistant';
import InboxesAPI from '../../api/inboxes';
import { throwErrorMessage } from '../utils/api';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
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
      // In the Kira fork the bot that handles an inbox is a Captain assistant,
      // so the picker and list are populated from the Captain assistants API.
      const response = await CaptainAssistantAPI.get();
      commit(types.SET_AGENT_BOTS, response.data.payload);
      return response.data.payload;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(types.SET_AGENT_BOT_UI_FLAG, { isFetching: false });
    }
  },

  fetchAgentBotInbox: async ({ commit }, inboxId) => {
    commit(types.SET_AGENT_BOT_UI_FLAG, { isFetchingAgentBot: true });
    try {
      const { data } = await InboxesAPI.getCaptainBot(inboxId);
      const { captain_assistant: captainAssistant = {} } = data || {};
      commit(types.SET_AGENT_BOT_INBOX, {
        agentBotId: captainAssistant.id,
        inboxId,
      });
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_AGENT_BOT_UI_FLAG, { isFetchingAgentBot: false });
    }
  },

  setAgentBotInbox: async ({ commit }, { inboxId, botId }) => {
    commit(types.SET_AGENT_BOT_UI_FLAG, { isSettingAgentBot: true });
    try {
      await InboxesAPI.setCaptainBot(inboxId, botId);
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
      await InboxesAPI.setCaptainBot(inboxId, null);
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
  [types.SET_AGENT_BOTS]: MutationHelpers.set,
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
