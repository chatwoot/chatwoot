import CaptainToolCatalog from 'dashboard/api/captain/toolCatalog';
import { throwErrorMessage } from 'dashboard/store/utils/api';

const state = {
  providers: [],
  providerDetails: {},
  capacity: { used: 0, limit: 15 },
  uiFlags: {
    fetchingCatalog: false,
    fetchingProvider: false,
    mutatingInstallation: false,
  },
};

const getters = {
  getProviders: currentState => currentState.providers,
  getProvider: currentState => providerKey =>
    currentState.providerDetails[providerKey] || null,
  getCapacity: currentState => currentState.capacity,
  getUIFlags: currentState => currentState.uiFlags,
};

const mutations = {
  SET_PROVIDERS(currentState, providers) {
    currentState.providers = providers;
  },
  SET_PROVIDER(currentState, provider) {
    currentState.providerDetails = {
      ...currentState.providerDetails,
      [provider.key]: provider,
    };
  },
  SET_CAPACITY(currentState, capacity) {
    currentState.capacity = capacity;
  },
  SET_UI_FLAG(currentState, value) {
    currentState.uiFlags = { ...currentState.uiFlags, ...value };
  },
};

const actions = {
  async get({ commit }) {
    commit('SET_UI_FLAG', { fetchingCatalog: true });
    try {
      const { data } = await CaptainToolCatalog.get();
      commit('SET_PROVIDERS', data.payload);
      commit('SET_CAPACITY', data.meta.capacity);
      return data;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit('SET_UI_FLAG', { fetchingCatalog: false });
    }
  },

  async show({ commit }, providerKey) {
    commit('SET_UI_FLAG', { fetchingProvider: true });
    try {
      const { data } = await CaptainToolCatalog.show(providerKey);
      commit('SET_PROVIDER', data.payload);
      commit('SET_CAPACITY', data.meta.capacity);
      return data;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit('SET_UI_FLAG', { fetchingProvider: false });
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
