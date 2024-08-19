import SmartActionApi from '../../../../api/inbox/smart_action';
import types from '../../../mutation-types';

export default {
  getSmartActions: async ({ commit }, conversationId) => {
    const {
      data: { payload },
    } = await SmartActionApi.getSmartActions(conversationId);
    commit(types.SET_SMART_ACTIONS, payload);
  },

  addSmartAction: async({ commit}, data) => {
    commit(types.ADD_SMART_ACTION, data);
  },

  showSmartActions: ({ commit }, value) => {
    commit(types.DISPLAY_SMART_ACTIONS, value);
  },

  setSmartActionsContext: ({ commit }, { conversationId, messageId }) => {
    commit(types.SET_SMART_ACTIONS_CONTEXT, { conversationId, messageId });
  },

  askCopilot: async (_, { conversationId }) => {
    return SmartActionApi.askCopilot(conversationId);
  },

  cancelBooking: async (_, link) => {
    SmartActionApi.cancelBooking(link);
    return true;
  },

  takeOverConversation: async (_, conversationId) => {
    return SmartActionApi.takeOverConversation(conversationId);
  },
}