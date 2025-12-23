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
    const models = feature?.models || [];

    const providerOrder = { openai: 0, anthropic: 1, gemini: 2 };

    return [...models].sort((a, b) => {
      // Move coming_soon items to the end
      if (a.coming_soon && !b.coming_soon) return 1;
      if (!a.coming_soon && b.coming_soon) return -1;

      // Sort by provider
      const providerA = providerOrder[a.provider] ?? 999;
      const providerB = providerOrder[b.provider] ?? 999;
      if (providerA !== providerB) return providerA - providerB;

      // Sort by credit_multiplier (highest first)
      return (b.credit_multiplier || 0) - (a.credit_multiplier || 0);
    });
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
