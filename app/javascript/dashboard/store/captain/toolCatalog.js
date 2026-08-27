import CaptainToolCatalog from 'dashboard/api/captain/toolCatalog';
import { throwErrorMessage } from 'dashboard/store/utils/api';

const state = {
  providers: [],
  providerDetails: {},
  capacity: { used: 0, limit: 15 },
  currentInstallation: null,
  uiFlags: {
    fetchingCatalog: false,
    fetchingProvider: false,
    fetchingSetup: false,
    mutatingInstallation: false,
  },
};

const getters = {
  getProviders: currentState => currentState.providers,
  getProvider: currentState => providerKey =>
    currentState.providerDetails[providerKey] || null,
  getCapacity: currentState => currentState.capacity,
  getCurrentInstallation: currentState => currentState.currentInstallation,
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
  SET_INSTALLATION(currentState, installation) {
    currentState.currentInstallation = installation;
  },
  SET_UI_FLAG(currentState, value) {
    currentState.uiFlags = { ...currentState.uiFlags, ...value };
  },
};

const mutateInstallation = async (commit, request) => {
  commit('SET_UI_FLAG', { mutatingInstallation: true });
  try {
    const { data } = await request();
    commit('SET_INSTALLATION', data.payload);
    return data.payload;
  } catch (error) {
    const code = error.response?.data?.error?.code;
    if (code) throw new Error(code);
    return throwErrorMessage(error);
  } finally {
    commit('SET_UI_FLAG', { mutatingInstallation: false });
  }
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

  async prepareConnection({ commit }, data) {
    return mutateInstallation(commit, () =>
      CaptainToolCatalog.prepareConnection(data)
    );
  },

  async install({ commit }, data) {
    return mutateInstallation(commit, () => CaptainToolCatalog.install(data));
  },

  async showInstallation({ commit }, id) {
    return mutateInstallation(commit, () =>
      CaptainToolCatalog.showInstallation(id)
    );
  },

  async reconnect({ commit }, { providerKey, data = {} }) {
    return mutateInstallation(commit, () =>
      CaptainToolCatalog.reconnect(providerKey, data)
    );
  },

  async disconnect({ commit }, providerKey) {
    commit('SET_UI_FLAG', { mutatingInstallation: true });
    try {
      await CaptainToolCatalog.disconnect(providerKey);
      commit('SET_INSTALLATION', null);
      return true;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit('SET_UI_FLAG', { mutatingInstallation: false });
    }
  },

  async update({ commit }, { providerKey, templates }) {
    return mutateInstallation(commit, () =>
      CaptainToolCatalog.update(providerKey, templates)
    );
  },
  async setup({ commit }, { providerKey, operationKey, arguments: args = {} }) {
    commit('SET_UI_FLAG', { fetchingSetup: true });
    try {
      const { data } = await CaptainToolCatalog.setup(
        providerKey,
        operationKey,
        args
      );
      return data.payload;
    } catch (error) {
      const code = error.response?.data?.error?.code;
      if (code) throw new Error(code);
      return throwErrorMessage(error);
    } finally {
      commit('SET_UI_FLAG', { fetchingSetup: false });
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
