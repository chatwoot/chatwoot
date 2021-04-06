/* eslint no-param-reassign: 0 */
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import * as types from '../mutation-types';
import IntegrationsAPI from '../../api/integrations';

const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isFetchingItem: false,
    isUpdating: false,
  },
};

export const getters = {
  getIntegrations($state) {
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
    commit(types.default.SET_INTEGRATIONS_UI_FLAG, { isUpdating: true });
    try {
      const response = await IntegrationsAPI.connectSlack(code);
      commit(types.default.ADD_INTEGRATION, response.data);
      commit(types.default.SET_INTEGRATIONS_UI_FLAG, { isUpdating: false });
    } catch (error) {
      commit(types.default.SET_INTEGRATIONS_UI_FLAG, { isUpdating: false });
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
};

export const mutations = {
  [types.default.SET_INTEGRATIONS_UI_FLAG]($state, uiFlag) {
    $state.uiFlags = { ...$state.uiFlags, ...uiFlag };
  },
  [types.default.SET_INTEGRATIONS]: MutationHelpers.set,
  [types.default.ADD_INTEGRATION]: MutationHelpers.updateAttributes,
  [types.default.DELETE_INTEGRATION]: MutationHelpers.updateAttributes,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
