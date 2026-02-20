import { defineStore } from 'pinia';
import CaptainPreferencesAPI from 'dashboard/api/captain/preferences';

export const useCaptainConfigStore = defineStore('captainConfig', {
  state: () => ({
    providers: {},
    models: {},
    features: {},
    uiFlags: {
      isFetching: false,
    },
  }),

  getters: {
    getProviders: state => state.providers,
    getModels: state => state.models,
    getFeatures: state => state.features,
    getUIFlags: state => state.uiFlags,
    getModelsForFeature: state => featureKey => {
      const feature = state.features[featureKey];
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
    getDefaultModelForFeature: state => featureKey => {
      const feature = state.features[featureKey];
      return feature?.default || null;
    },
    getSelectedModelForFeature: state => featureKey => {
      const feature = state.features[featureKey];
      return feature?.selected || feature?.default || null;
    },
  },

  actions: {
    async fetch() {
      this.uiFlags.isFetching = true;
      try {
        const response = await CaptainPreferencesAPI.get();
        this.providers = response.data.providers || {};
        this.models = response.data.models || {};
        this.features = response.data.features || {};
      } catch (error) {
        // Ignore error
      } finally {
        this.uiFlags.isFetching = false;
      }
    },

    async updatePreferences(data) {
      const response = await CaptainPreferencesAPI.updatePreferences(data);
      this.providers = response.data.providers || {};
      this.models = response.data.models || {};
      this.features = response.data.features || {};
    },
  },
});
