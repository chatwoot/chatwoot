/* eslint no-param-reassign: 0 */
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import * as types from '../mutation-types';
import IntegrationsAPI from '../../api/integrations';

const state = {
  records: [],
  uiFlags: {
    isCreating: false,
    isFetching: false,
    isFetchingItem: false,
    isUpdating: false,
    isCreatingHook: false,
    isDeletingHook: false,
  },
};

export const getters = {
  getAppIntegrations($state) {
    return $state.records;
  },
  getIntegration:
    $state =>
    (integrationId, defaultValue = {}) => {
      const [integration] = $state.records.filter(
        record => record.id === integrationId
      );
      return integration || defaultValue;
    },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  get: async ({ commit }) => {
    commit(types.default.SET_INTEGRATIONS_UI_FLAG, { isFetching: true });
    try {
      const response = await IntegrationsAPI.get();
      commit(types.default.SET_INTEGRATIONS, response.data.payload);
      commit(types.default.SET_INTEGRATIONS_UI_FLAG, { isFetching: false });
    } catch (error) {
      commit(types.default.SET_INTEGRATIONS_UI_FLAG, { isFetching: false });
    }
  },

  deleteIntegration: async ({ commit }, integrationId) => {
    commit(types.default.SET_INTEGRATIONS_UI_FLAG, { isDeleting: true });
    try {
      await IntegrationsAPI.delete(integrationId);
      commit(types.default.DELETE_INTEGRATION, {
        id: integrationId,
        enabled: false,
      });
      commit(types.default.SET_INTEGRATIONS_UI_FLAG, { isDeleting: false });
    } catch (error) {
      commit(types.default.SET_INTEGRATIONS_UI_FLAG, { isDeleting: false });
    }
  },
  showHook: async ({ commit }, hookId) => {
    commit(types.default.SET_INTEGRATIONS_UI_FLAG, { isFetchingItem: true });
    try {
      const response = await IntegrationsAPI.showHook(hookId);
      commit(types.default.ADD_INTEGRATION_HOOKS, response.data);
      commit(types.default.SET_INTEGRATIONS_UI_FLAG, { isFetchingItem: false });
    } catch (error) {
      commit(types.default.SET_INTEGRATIONS_UI_FLAG, { isFetchingItem: false });
      throw error;
    }
  },
  createHook: async ({ commit }, hookData) => {
    commit(types.default.SET_INTEGRATIONS_UI_FLAG, { isCreatingHook: true });
    try {
      const response = await IntegrationsAPI.createHook(hookData);
      commit(types.default.ADD_INTEGRATION_HOOKS, response.data);
      commit(types.default.SET_INTEGRATIONS_UI_FLAG, { isCreatingHook: false });
    } catch (error) {
      commit(types.default.SET_INTEGRATIONS_UI_FLAG, { isCreatingHook: false });
      throw error;
    }
  },
  deleteHook: async ({ commit }, { appId, hookId }) => {
    commit(types.default.SET_INTEGRATIONS_UI_FLAG, { isDeletingHook: true });
    try {
      await IntegrationsAPI.deleteHook(hookId);
      commit(types.default.DELETE_INTEGRATION_HOOKS, { appId, hookId });
      commit(types.default.SET_INTEGRATIONS_UI_FLAG, { isDeletingHook: false });
    } catch (error) {
      commit(types.default.SET_INTEGRATIONS_UI_FLAG, { isDeletingHook: false });
      throw error;
    }
  },
};

export const mutations = {
  [types.default.SET_INTEGRATIONS_UI_FLAG]($state, uiFlag) {
    $state.uiFlags = { ...$state.uiFlags, ...uiFlag };
  },
  [types.default.SET_INTEGRATIONS]: MutationHelpers.set,
  [types.default.ADD_INTEGRATION]: MutationHelpers.updateAttributes,
  [types.default.DELETE_INTEGRATION]: MutationHelpers.updateAttributes,
  [types.default.ADD_INTEGRATION_HOOKS]: ($state, data) => {
    $state.records = $state.records.map(record => {
      if (record.id === data.app_id) {
        return {
          ...record,
          hooks: [...record.hooks, data],
        };
      }
      return record;
    });
  },
  [types.default.DELETE_INTEGRATION_HOOKS]: ($state, { appId, hookId }) => {
    $state.records = $state.records.map(record => {
      if (record.id === appId) {
        return {
          ...record,
          hooks: record.hooks.filter(hook => hook.id !== hookId),
        };
      }
      return record;
    });
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
