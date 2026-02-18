import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import * as types from '../mutation-types';
import CrmFlowsAPI from '../../api/crmFlows';
import { throwErrorMessage } from 'dashboard/store/utils/api';

const state = {
  records: [],
  executions: [],
  conversationExecutions: {},
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
    isFetchingExecutions: false,
  },
};

export const getters = {
  getCrmFlows: $state => $state.records,
  getExecutions: $state => $state.executions,
  getConversationExecutions: $state => conversationId =>
    $state.conversationExecutions[conversationId] || [],
  getUIFlags: $state => $state.uiFlags,
};

export const actions = {
  get: async ({ commit }) => {
    commit(types.default.SET_CRM_FLOWS_UI_FLAG, { isFetching: true });
    try {
      const response = await CrmFlowsAPI.get();
      commit(types.default.SET_CRM_FLOWS, response.data.flows);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.default.SET_CRM_FLOWS_UI_FLAG, { isFetching: false });
    }
  },

  create: async ({ commit }, payload) => {
    commit(types.default.SET_CRM_FLOWS_UI_FLAG, { isCreating: true });
    try {
      const response = await CrmFlowsAPI.create({ crm_flow: payload });
      commit(types.default.ADD_CRM_FLOW, response.data);
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.default.SET_CRM_FLOWS_UI_FLAG, { isCreating: false });
    }
  },

  update: async ({ commit }, { id, ...payload }) => {
    commit(types.default.SET_CRM_FLOWS_UI_FLAG, { isUpdating: true });
    try {
      const response = await CrmFlowsAPI.update(id, { crm_flow: payload });
      commit(types.default.EDIT_CRM_FLOW, response.data);
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.default.SET_CRM_FLOWS_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async ({ commit }, id) => {
    commit(types.default.SET_CRM_FLOWS_UI_FLAG, { isDeleting: true });
    try {
      await CrmFlowsAPI.delete(id);
      commit(types.default.DELETE_CRM_FLOW, id);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.default.SET_CRM_FLOWS_UI_FLAG, { isDeleting: false });
    }
  },

  getExecutions: async ({ commit }, flowId) => {
    commit(types.default.SET_CRM_FLOWS_UI_FLAG, { isFetchingExecutions: true });
    try {
      const response = await CrmFlowsAPI.executions(flowId);
      commit(types.default.SET_CRM_FLOW_EXECUTIONS, response.data.executions);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.default.SET_CRM_FLOWS_UI_FLAG, {
        isFetchingExecutions: false,
      });
    }
  },

  getConversationExecutions: async ({ commit }, conversationId) => {
    try {
      const response =
        await CrmFlowsAPI.executionsByConversation(conversationId);
      commit(types.default.SET_CRM_FLOW_CONVERSATION_EXECUTIONS, {
        conversationId,
        executions: response.data.executions,
      });
    } catch {
      // silent — panel permanece vacío
    }
  },
};

export const mutations = {
  [types.default.SET_CRM_FLOWS_UI_FLAG]($state, uiFlag) {
    $state.uiFlags = { ...$state.uiFlags, ...uiFlag };
  },
  [types.default.SET_CRM_FLOWS]: MutationHelpers.set,
  [types.default.ADD_CRM_FLOW]: MutationHelpers.create,
  [types.default.EDIT_CRM_FLOW]: MutationHelpers.update,
  [types.default.DELETE_CRM_FLOW]: MutationHelpers.destroy,
  [types.default.SET_CRM_FLOW_EXECUTIONS]($state, executions) {
    $state.executions = executions;
  },
  [types.default.SET_CRM_FLOW_CONVERSATION_EXECUTIONS](
    $state,
    { conversationId, executions }
  ) {
    $state.conversationExecutions = {
      ...$state.conversationExecutions,
      [conversationId]: executions,
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
