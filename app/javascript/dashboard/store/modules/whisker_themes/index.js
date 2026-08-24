import ThemeApi from '../../api/themes';

const state = {
  installed: [],
  active: null,
  uiFlags: {
    isFetching: false,
    isInstalling: false,
  },
};

export const getters = {
  getInstalled: s => s.installed,
  getActive: s => s.active,
  getUIFlags: s => s.uiFlags,
};

export const actions = {
  fetchThemes: async ({ commit }) => {
    commit('setUIFlags', { isFetching: true });
    try {
      const { data } = await ThemeApi.getInstalled();
      commit('setInstalled', data.installed || []);
      commit('setActive', data.active || null);
    } finally {
      commit('setUIFlags', { isFetching: false });
    }
  },

  installTheme: async ({ commit }, theme) => {
    commit('setUIFlags', { isInstalling: true });
    try {
      const { data } = await ThemeApi.install(theme.id);
      commit('addInstalled', data);
      return data;
    } finally {
      commit('setUIFlags', { isInstalling: false });
    }
  },

  setActiveTheme: async ({ commit }, themeId) => {
    const { data } = await ThemeApi.setActive(themeId);
    commit('setActive', data);
  },

  removeTheme: async ({ commit }, themeId) => {
    await ThemeApi.remove(themeId);
    commit('removeInstalled', themeId);
  },
};

export const mutations = {
  setInstalled($state, themes) {
    $state.installed = themes;
  },
  addInstalled($state, theme) {
    $state.installed.push(theme);
  },
  removeInstalled($state, id) {
    $state.installed = $state.installed.filter(t => t.id !== id);
  },
  setActive($state, theme) {
    $state.active = theme;
  },
  setUIFlags($state, flags) {
    $state.uiFlags = { ...$state.uiFlags, ...flags };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
