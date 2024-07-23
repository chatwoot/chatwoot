/* eslint no-param-reassign: 0 */
import Vue from 'vue';
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import * as types from '../mutation-types';
import IntegrationsAPI from '../../api/integrations';
import { throwErrorMessage } from 'dashboard/store/utils/api';

const state = {
  records: [],
  uiFlags: {
    isCreating: false,
    isFetching: false,
    isFetchingItem: false,
    isUpdating: false,
    isCreatingHook: false,
    isDeletingHook: false,
    isCreatingSlack: false,
    isUpdatingSlack: false,
    isFetchingSlackChannels: false,
  },
};

export const getters = {
  getAppIntegrations($state) {
    return $state.records;
  },
  getIntegration: $state => integrationId => {
    const [integration] = $state.records.filter(
      record => record.id === integrationId
    );
    return integration || {};
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

  connectSlack: async ({ commit }, code) => {
    commit(types.default.SET_INTEGRATIONS_UI_FLAG, { isCreatingSlack: true });
    try {
      const response = await IntegrationsAPI.connectSlack(code);
      commit(types.default.ADD_INTEGRATION, response.data);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.default.SET_INTEGRATIONS_UI_FLAG, {
        isCreatingSlack: false,
      });
    }
  },
  updateSlack: async ({ commit }, slackObj) => {
    commit(types.default.SET_INTEGRATIONS_UI_FLAG, { isUpdatingSlack: true });
    try {
      const response = await IntegrationsAPI.updateSlack(slackObj);
      commit(types.default.ADD_INTEGRATION, response.data);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.default.SET_INTEGRATIONS_UI_FLAG, {
        isUpdatingSlack: false,
      });
    }
  },
  listAllSlackChannels: async ({ commit }) => {
    commit(types.default.SET_INTEGRATIONS_UI_FLAG, {
      isFetchingSlackChannels: true,
    });
    try {
      const response = await IntegrationsAPI.listAllSlackChannels();
      return response.data;
    } catch (error) {
      commit(types.default.SET_INTEGRATIONS_UI_FLAG, {
        isFetchingSlackChannels: false,
      });
    }
    return null;
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
      throw new Error(error);
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
      throw new Error(error);
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
      throw new Error(error);
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
    $state.records.forEach((element, index) => {
      if (element.id === data.app_id) {
        const record = $state.records[index];
        Vue.set(record, 'hooks', [...record.hooks, data]);
      }
    });
  },
  [types.default.DELETE_INTEGRATION_HOOKS]: ($state, { appId, hookId }) => {
    $state.records.forEach((element, index) => {
      if (element.id === appId) {
        const record = $state.records[index];
        const hooksWithoutDeletedHook = record.hooks.filter(
          hook => hook.id !== hookId
        );
        Vue.set(record, 'hooks', hooksWithoutDeletedHook);
      }
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
