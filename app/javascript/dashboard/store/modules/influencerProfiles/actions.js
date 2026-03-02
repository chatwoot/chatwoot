import types from '../../mutation-types';
import InfluencerProfilesAPI from '../../../api/influencerProfiles';

export const actions = {
  get: async ({ commit }, { page = 1, filters = {} } = {}) => {
    commit(types.SET_INFLUENCER_UI_FLAG, { isFetching: true });
    try {
      const {
        data: { payload, meta },
      } = await InfluencerProfilesAPI.get(page, filters);
      commit(types.CLEAR_INFLUENCERS);
      commit(types.SET_INFLUENCERS, payload);
      commit(types.SET_INFLUENCER_META, meta);
    } catch (error) {
      // handle silently
    } finally {
      commit(types.SET_INFLUENCER_UI_FLAG, { isFetching: false });
    }
  },

  show: async ({ commit }, { id }) => {
    commit(types.SET_INFLUENCER_UI_FLAG, { isFetchingItem: true });
    try {
      const { data } = await InfluencerProfilesAPI.show(id);
      commit(types.SET_INFLUENCER_ITEM, data.payload);
    } catch (error) {
      // handle silently
    } finally {
      commit(types.SET_INFLUENCER_UI_FLAG, { isFetchingItem: false });
    }
  },

  search: async ({ commit, state }, { filters, page = 1 } = {}) => {
    commit(types.SET_INFLUENCER_UI_FLAG, { isSearching: true });
    const searchFilters = filters || state.lastSearchParams || {};

    try {
      const { data } = await InfluencerProfilesAPI.search(searchFilters, page);
      commit(types.SET_INFLUENCER_LAST_SEARCH_PARAMS, searchFilters);
      commit(types.SET_INFLUENCER_SEARCH_RESULTS, {
        results: data.payload || [],
        total: data.meta?.total || 0,
        currentPage: data.meta?.current_page || page,
        perPage: data.meta?.per_page || 0,
        totalPages: data.meta?.total_pages || 0,
        loadedCount: data.meta?.loaded_count || 0,
        imported: data.meta?.imported || 0,
        cached: data.meta?.cached || false,
        creditsLeft: data.meta?.credits_left ?? null,
      });
    } finally {
      commit(types.SET_INFLUENCER_UI_FLAG, { isSearching: false });
    }
  },

  importProfile: async ({ commit }, { searchResult, targetMarket }) => {
    commit(types.SET_INFLUENCER_UI_FLAG, { isImporting: true });
    try {
      const { data } = await InfluencerProfilesAPI.importProfile(
        searchResult,
        targetMarket
      );
      commit(types.SET_INFLUENCER_ITEM, data.payload);
      return data.payload;
    } finally {
      commit(types.SET_INFLUENCER_UI_FLAG, { isImporting: false });
    }
  },

  bulkImport: async ({ commit }, { searchResults, targetMarket }) => {
    commit(types.SET_INFLUENCER_UI_FLAG, { isImporting: true });
    try {
      const { data } = await InfluencerProfilesAPI.bulkImport(
        searchResults,
        targetMarket
      );
      (data.payload || []).forEach(profile => {
        commit(types.SET_INFLUENCER_ITEM, profile);
      });
      return data;
    } finally {
      commit(types.SET_INFLUENCER_UI_FLAG, { isImporting: false });
    }
  },

  requestReport: async ({ commit }, { id }) => {
    const { data } = await InfluencerProfilesAPI.requestReport(id);
    commit(types.EDIT_INFLUENCER, data.payload);
  },

  bulkRequestReport: async (_, { profileIds }) => {
    await InfluencerProfilesAPI.bulkRequestReport(profileIds);
  },

  approve: async ({ commit }, { id }) => {
    commit(types.SET_INFLUENCER_UI_FLAG, { isApproving: true });
    try {
      const { data } = await InfluencerProfilesAPI.approve(id);
      commit(types.EDIT_INFLUENCER, data.payload);
    } finally {
      commit(types.SET_INFLUENCER_UI_FLAG, { isApproving: false });
    }
  },

  reject: async ({ commit }, { id, reason }) => {
    commit(types.SET_INFLUENCER_UI_FLAG, { isRejecting: true });
    try {
      const { data } = await InfluencerProfilesAPI.reject(id, reason);
      commit(types.EDIT_INFLUENCER, data.payload);
    } finally {
      commit(types.SET_INFLUENCER_UI_FLAG, { isRejecting: false });
    }
  },

  recalculate: async (_, { id }) => {
    await InfluencerProfilesAPI.recalculate(id);
  },

  clearSearchResults: ({ commit }) => {
    commit(types.CLEAR_INFLUENCER_SEARCH_RESULTS);
    commit(types.SET_INFLUENCER_LAST_SEARCH_PARAMS, null);
  },
};
