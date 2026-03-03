import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import WhatsappFlowsAPI from '../../api/whatsappFlows';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
    isPublishing: false,
  },
};

export const getters = {
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getWhatsappFlows: _state => _state.records,
  getFlowsByInbox: _state => inboxId =>
    _state.records.filter(f => f.inbox_id === inboxId),
  getFlowsByStatus: _state => status =>
    _state.records.filter(f => f.status === status),
  getFlowById: _state => id => _state.records.find(f => f.id === id),
};

export const actions = {
  get: async ({ commit }, params = {}) => {
    commit(types.SET_WHATSAPP_FLOW_UI_FLAG, { isFetching: true });
    try {
      const response = await WhatsappFlowsAPI.get(params);
      commit(types.SET_WHATSAPP_FLOWS, response.data);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_WHATSAPP_FLOW_UI_FLAG, { isFetching: false });
    }
  },
  create: async ({ commit }, flowObj) => {
    commit(types.SET_WHATSAPP_FLOW_UI_FLAG, { isCreating: true });
    try {
      const response = await WhatsappFlowsAPI.create(flowObj);
      commit(types.ADD_WHATSAPP_FLOW, response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_WHATSAPP_FLOW_UI_FLAG, { isCreating: false });
    }
  },
  update: async ({ commit }, { id, ...flowObj }) => {
    commit(types.SET_WHATSAPP_FLOW_UI_FLAG, { isUpdating: true });
    try {
      const response = await WhatsappFlowsAPI.update(id, flowObj);
      commit(types.EDIT_WHATSAPP_FLOW, response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_WHATSAPP_FLOW_UI_FLAG, { isUpdating: false });
    }
  },
  delete: async ({ commit }, id) => {
    commit(types.SET_WHATSAPP_FLOW_UI_FLAG, { isDeleting: true });
    try {
      await WhatsappFlowsAPI.delete(id);
      commit(types.DELETE_WHATSAPP_FLOW, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_WHATSAPP_FLOW_UI_FLAG, { isDeleting: false });
    }
  },
  publish: async ({ commit }, id) => {
    commit(types.SET_WHATSAPP_FLOW_UI_FLAG, { isPublishing: true });
    try {
      const response = await WhatsappFlowsAPI.publish(id);
      commit(types.EDIT_WHATSAPP_FLOW, response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_WHATSAPP_FLOW_UI_FLAG, { isPublishing: false });
    }
  },
};

export const mutations = {
  [types.SET_WHATSAPP_FLOW_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },
  [types.SET_WHATSAPP_FLOWS]: MutationHelpers.set,
  [types.ADD_WHATSAPP_FLOW]: MutationHelpers.create,
  [types.EDIT_WHATSAPP_FLOW]: MutationHelpers.updateAttributes,
  [types.DELETE_WHATSAPP_FLOW]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
