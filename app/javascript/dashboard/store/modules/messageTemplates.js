import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import MessageTemplatesAPI from '../../api/messageTemplates';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isSyncing: false,
    isDeleting: false,
  },
};

export const getters = {
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getMessageTemplates: _state => _state.records,
  getTemplateById: _state => id =>
    _state.records.find(t => t.id === Number(id)),
  getTemplatesByStatus: _state => status =>
    _state.records.filter(t => t.status === status),
  getTemplatesByInbox: _state => inboxId =>
    _state.records.filter(t => t.inbox_id === inboxId),
};

export const actions = {
  get: async ({ commit }, params = {}) => {
    commit(types.SET_MESSAGE_TEMPLATE_UI_FLAG, { isFetching: true });
    try {
      const response = await MessageTemplatesAPI.get(params);
      commit(types.SET_MESSAGE_TEMPLATES, response.data);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_MESSAGE_TEMPLATE_UI_FLAG, { isFetching: false });
    }
  },
  create: async ({ commit }, templateObj) => {
    commit(types.SET_MESSAGE_TEMPLATE_UI_FLAG, { isCreating: true });
    try {
      const response = await MessageTemplatesAPI.create(templateObj);
      commit(types.ADD_MESSAGE_TEMPLATE, response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_MESSAGE_TEMPLATE_UI_FLAG, { isCreating: false });
    }
  },
  update: async ({ commit }, { id, ...updateObj }) => {
    commit(types.SET_MESSAGE_TEMPLATE_UI_FLAG, { isUpdating: true });
    try {
      const response = await MessageTemplatesAPI.update(id, updateObj);
      commit(types.EDIT_MESSAGE_TEMPLATE, response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_MESSAGE_TEMPLATE_UI_FLAG, { isUpdating: false });
    }
  },
  delete: async ({ commit }, id) => {
    commit(types.SET_MESSAGE_TEMPLATE_UI_FLAG, { isDeleting: true });
    try {
      await MessageTemplatesAPI.delete(id);
      commit(types.DELETE_MESSAGE_TEMPLATE, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_MESSAGE_TEMPLATE_UI_FLAG, { isDeleting: false });
    }
  },
  sync: async ({ commit }, inboxId) => {
    commit(types.SET_MESSAGE_TEMPLATE_UI_FLAG, { isSyncing: true });
    try {
      const response = await MessageTemplatesAPI.sync(inboxId);
      commit(types.SET_MESSAGE_TEMPLATES, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_MESSAGE_TEMPLATE_UI_FLAG, { isSyncing: false });
    }
  },
};

export const mutations = {
  [types.SET_MESSAGE_TEMPLATE_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },
  [types.SET_MESSAGE_TEMPLATES]: MutationHelpers.set,
  [types.ADD_MESSAGE_TEMPLATE]: MutationHelpers.create,
  [types.EDIT_MESSAGE_TEMPLATE]: MutationHelpers.updateAttributes,
  [types.DELETE_MESSAGE_TEMPLATE]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
