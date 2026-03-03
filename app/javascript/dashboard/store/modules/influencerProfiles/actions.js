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
    commit(types.UPDATE_KANBAN_ITEM, {
      oldStatus: 'discovered',
      newProfile: data.payload,
    });
  },

  bulkRequestReport: async (_, { profileIds }) => {
    await InfluencerProfilesAPI.bulkRequestReport(profileIds);
  },

  approve: async ({ commit }, { id }) => {
    commit(types.SET_INFLUENCER_UI_FLAG, { isApproving: true });
    try {
      const { data } = await InfluencerProfilesAPI.approve(id);
      commit(types.EDIT_INFLUENCER, data.payload);
      commit(types.UPDATE_KANBAN_ITEM, {
        oldStatus: 'enriched',
        newProfile: data.payload,
      });
    } finally {
      commit(types.SET_INFLUENCER_UI_FLAG, { isApproving: false });
    }
  },

  reject: async ({ commit }, { id, reason, previousStatus }) => {
    commit(types.SET_INFLUENCER_UI_FLAG, { isRejecting: true });
    try {
      const { data } = await InfluencerProfilesAPI.reject(id, reason);
      commit(types.EDIT_INFLUENCER, data.payload);
      commit(types.UPDATE_KANBAN_ITEM, {
        oldStatus: previousStatus,
        newProfile: data.payload,
      });
    } finally {
      commit(types.SET_INFLUENCER_UI_FLAG, { isRejecting: false });
    }
  },

  recalculate: async (_, { id }) => {
    await InfluencerProfilesAPI.recalculate(id);
  },

  retryApify: async ({ commit }, { id }) => {
    const { data } = await InfluencerProfilesAPI.retryApify(id);
    commit(types.EDIT_INFLUENCER, data.payload);
    // Update in kanban discovered column
    const col = 'discovered';
    commit(types.UPDATE_KANBAN_ITEM, {
      oldStatus: col,
      newProfile: data.payload,
    });
    // Re-add since UPDATE_KANBAN_ITEM removes+adds
  },

  getConversations: async (_, { profileId }) => {
    const { data } = await InfluencerProfilesAPI.getConversations(profileId);
    return { conversations: data.payload, channels: data.channels };
  },

  createOffer: async (_, { profileId, packages, rightsLevel, currency }) => {
    const { data } = await InfluencerProfilesAPI.createOffer(profileId, {
      packages,
      rightsLevel,
      currency,
    });
    return data;
  },

  getOffers: async (_, { profileId }) => {
    const { data } = await InfluencerProfilesAPI.getOffers(profileId);
    return data.payload;
  },

  updateEmail: async ({ commit }, { profileId, email }) => {
    const { data } = await InfluencerProfilesAPI.updateEmail(profileId, email);
    commit(types.EDIT_INFLUENCER, data.payload);
    return data.payload;
  },

  sendMessage: async (_, { profileId, inboxId, content }) => {
    const { data } = await InfluencerProfilesAPI.sendMessage(profileId, {
      inboxId,
      content,
    });
    return data;
  },

  addByHandle: async ({ commit, dispatch }, { handle }) => {
    commit(types.SET_INFLUENCER_UI_FLAG, { isAdding: true });
    try {
      const { data } = await InfluencerProfilesAPI.addByHandle(handle);
      commit(types.SET_INFLUENCER_ITEM, data.payload);
      commit(types.UPDATE_KANBAN_ITEM, {
        oldStatus: null,
        newProfile: data.payload,
      });
      // Apify runs in the background (~15s); refresh discovered column after a delay
      if (!data.existing) {
        setTimeout(
          () => dispatch('fetchKanbanColumn', { status: 'discovered' }),
          20000
        );
      }
      return data;
    } finally {
      commit(types.SET_INFLUENCER_UI_FLAG, { isAdding: false });
    }
  },

  deleteProfile: async ({ commit }, { id, status }) => {
    commit(types.SET_INFLUENCER_UI_FLAG, { isDeleting: true });
    try {
      await InfluencerProfilesAPI.delete(id);
      commit(types.REMOVE_KANBAN_ITEM, { status, profileId: id });
    } finally {
      commit(types.SET_INFLUENCER_UI_FLAG, { isDeleting: false });
    }
  },

  clearSearchResults: ({ commit }) => {
    commit(types.CLEAR_INFLUENCER_SEARCH_RESULTS);
    commit(types.SET_INFLUENCER_LAST_SEARCH_PARAMS, null);
  },

  // Kanban actions
  fetchKanbanColumn: async ({ commit }, { status, page = 1 }) => {
    commit(types.SET_KANBAN_COLUMN_LOADING, { status, loading: true });
    try {
      const {
        data: { payload, meta },
      } = await InfluencerProfilesAPI.get(page, { status });
      if (page === 1) {
        commit(types.SET_KANBAN_COLUMN, { status, records: payload, meta });
      } else {
        commit(types.APPEND_KANBAN_COLUMN, { status, records: payload, meta });
      }
    } catch (error) {
      commit(types.SET_KANBAN_COLUMN_LOADING, { status, loading: false });
    }
  },

  loadMoreKanban: async ({ commit, state }, { status }) => {
    const column = state.kanban[status];
    if (!column.meta.hasMore || column.loading) return;

    const nextPage = column.meta.currentPage + 1;
    commit(types.SET_KANBAN_COLUMN_LOADING, { status, loading: true });
    try {
      const {
        data: { payload, meta },
      } = await InfluencerProfilesAPI.get(nextPage, { status });
      commit(types.APPEND_KANBAN_COLUMN, { status, records: payload, meta });
    } catch (error) {
      commit(types.SET_KANBAN_COLUMN_LOADING, { status, loading: false });
    }
  },

  refreshAllKanbanColumns: async ({ dispatch }) => {
    const statuses = ['discovered', 'enriched', 'accepted', 'rejected'];
    await Promise.all(
      statuses.map(status => dispatch('fetchKanbanColumn', { status, page: 1 }))
    );
  },
};
