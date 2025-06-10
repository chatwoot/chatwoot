import { getMostReadArticles } from 'widget/api/article';
import { getFromCache, setCache } from 'shared/helpers/cache';

const CACHE_KEY_PREFIX = 'chatwoot_most_read_articles_';

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
      const cachedData = getFromCache(`${CACHE_KEY_PREFIX}${slug}_${locale}`);
      if (cachedData) {
        commit('setArticles', cachedData);
        return;
      }

      const { data } = await getMostReadArticles(slug, locale);
      const { payload = [] } = data;

      setCache(`${CACHE_KEY_PREFIX}${slug}_${locale}`, payload);
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
