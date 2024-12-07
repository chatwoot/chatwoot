import { getMostReadArticles } from 'widget/api/article';

const state = {
  records: [],
  uiFlags: {
    isError: false,
    hasFetched: false,
    isFetching: false,
  },
};

export const getters = {
  uiFlags: $state => $state.uiFlags,
  popularArticles: $state => $state.records,
};

export const actions = {
  fetch: async ({ commit }, { slug, locale }) => {
    commit('setIsFetching', true);
    commit('setError', false);

    try {
      const { data } = await getMostReadArticles(slug, locale);
      const { payload = [] } = data;

      if (payload.length) {
        commit('setArticles', payload);
      }
    } catch (error) {
      commit('setError', true);
    } finally {
      commit('setIsFetching', false);
    }
  },
};

export const mutations = {
  setArticles($state, data) {
    $state.records = data;
  },
  setError($state, value) {
    $state.uiFlags.isError = value;
  },
  setIsFetching($state, value) {
    $state.uiFlags.isFetching = value;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
