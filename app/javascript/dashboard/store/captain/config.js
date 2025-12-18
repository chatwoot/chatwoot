import CaptainConfigAPI from 'dashboard/api/captain/config';

const state = {
  providers: {},
  models: {},
  features: {},
  uiFlags: {
    isFetching: false,
  },
};

const getters = {
  getProviders: $state => $state.providers,
  getModels: $state => $state.models,
  getFeatures: $state => $state.features,
  getUIFlags: $state => $state.uiFlags,
  getModelsForFeature: $state => featureKey => {
    const feature = $state.features[featureKey];
    return feature?.models || [];
  },
  getDefaultModelForFeature: $state => featureKey => {
    const feature = $state.features[featureKey];
    return feature?.default || null;
  },
  getSelectedModelForFeature: $state => featureKey => {
    const feature = $state.features[featureKey];
    return feature?.selected || feature?.default || null;
  },
};

const mutations = {
  SET_UI_FLAG($state, data) {
    $state.uiFlags = { ...$state.uiFlags, ...data };
  },
  SET_CONFIG($state, { providers, models, features }) {
    $state.providers = providers || {};
    $state.models = models || {};
    $state.features = features || {};
  },
};

const actions = {
  async fetch({ commit }) {
    commit('SET_UI_FLAG', { isFetching: true });
    try {
      const response = await CaptainConfigAPI.get();
      commit('SET_CONFIG', response.data);
    } catch (error) {
      // Ignore error
    } finally {
      commit('SET_UI_FLAG', { isFetching: false });
    }
  },
};

export default {
  namespaced: true,
  state,
  getters,
  mutations,
  actions,
};
