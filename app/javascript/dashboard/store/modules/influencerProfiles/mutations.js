import types from '../../mutation-types';

export const mutations = {
  [types.SET_INFLUENCER_UI_FLAG]($state, data) {
    $state.uiFlags = { ...$state.uiFlags, ...data };
  },

  [types.SET_INFLUENCER_META]($state, data) {
    const { count, current_page: currentPage, has_more: hasMore } = data;
    $state.meta.count = count;
    $state.meta.currentPage = currentPage;
    if (hasMore !== undefined) {
      $state.meta.hasMore = hasMore;
    }
  },

  [types.SET_INFLUENCERS]($state, data) {
    const sortOrder = data.map(profile => {
      $state.records[profile.id] = {
        ...($state.records[profile.id] || {}),
        ...profile,
      };
      return profile.id;
    });
    $state.sortOrder = sortOrder;
  },

  [types.APPEND_INFLUENCERS]($state, data) {
    data.forEach(profile => {
      $state.records[profile.id] = {
        ...($state.records[profile.id] || {}),
        ...profile,
      };
      if (!$state.sortOrder.includes(profile.id)) {
        $state.sortOrder.push(profile.id);
      }
    });
  },

  [types.SET_INFLUENCER_ITEM]($state, data) {
    $state.records[data.id] = {
      ...($state.records[data.id] || {}),
      ...data,
    };
    if (!$state.sortOrder.includes(data.id)) {
      $state.sortOrder.push(data.id);
    }
  },

  [types.EDIT_INFLUENCER]($state, data) {
    $state.records[data.id] = data;
  },

  [types.CLEAR_INFLUENCERS]($state) {
    $state.records = {};
    $state.sortOrder = [];
  },

  [types.SET_INFLUENCER_SEARCH_RESULTS](
    $state,
    {
      results,
      total,
      currentPage,
      perPage,
      totalPages,
      loadedCount,
      imported,
      cached,
      creditsLeft,
    }
  ) {
    $state.searchResults = results;
    $state.searchMeta = {
      total,
      currentPage,
      perPage,
      totalPages,
      loadedCount,
      imported,
      cached,
      creditsLeft,
      hasSearched: true,
    };
  },

  [types.CLEAR_INFLUENCER_SEARCH_RESULTS]($state) {
    $state.searchResults = [];
    $state.searchMeta = {
      total: 0,
      currentPage: 1,
      perPage: 0,
      totalPages: 0,
      loadedCount: 0,
      imported: 0,
      cached: false,
      hasSearched: false,
      creditsLeft: null,
    };
  },

  [types.SET_INFLUENCER_LAST_SEARCH_PARAMS]($state, filters) {
    $state.lastSearchParams = filters;
  },
};
