import types from '../../mutation-types';

export const mutations = {
  [types.SET_INFLUENCER_UI_FLAG]($state, data) {
    $state.uiFlags = { ...$state.uiFlags, ...data };
  },

  [types.SET_INFLUENCER_META]($state, data) {
    const {
      count,
      current_page: currentPage,
      has_more: hasMore,
      per_status_counts: perStatusCounts,
    } = data;
    $state.meta.count = count;
    $state.meta.currentPage = currentPage;
    if (hasMore !== undefined) $state.meta.hasMore = hasMore;
    if (perStatusCounts) $state.meta.perStatusCounts = perStatusCounts;
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

  // Kanban mutations
  [types.SET_KANBAN_COLUMN]($state, { status, records, meta }) {
    $state.kanban[status] = {
      records,
      meta: {
        count: meta.count,
        currentPage: meta.current_page || meta.currentPage || 1,
        hasMore: meta.has_more ?? meta.hasMore ?? false,
      },
      loading: false,
    };
  },

  [types.APPEND_KANBAN_COLUMN]($state, { status, records, meta }) {
    const column = $state.kanban[status];
    column.records = [...column.records, ...records];
    column.meta = {
      count: meta.count,
      currentPage: meta.current_page || meta.currentPage || 1,
      hasMore: meta.has_more ?? meta.hasMore ?? false,
    };
    column.loading = false;
  },

  [types.SET_KANBAN_COLUMN_LOADING]($state, { status, loading }) {
    $state.kanban[status].loading = loading;
  },

  [types.CLEAR_KANBAN]($state) {
    const defaultCol = () => ({
      records: [],
      meta: { count: 0, currentPage: 1, hasMore: false },
      loading: false,
    });
    $state.kanban = {
      discovered: defaultCol(),
      enriched: defaultCol(),
      accepted: defaultCol(),
      rejected: defaultCol(),
    };
  },

  [types.REMOVE_KANBAN_ITEM]($state, { status, profileId }) {
    if ($state.kanban[status]) {
      $state.kanban[status].records = $state.kanban[status].records.filter(
        p => p.id !== profileId
      );
      $state.kanban[status].meta.count = Math.max(
        0,
        $state.kanban[status].meta.count - 1
      );
    }
  },

  [types.UPDATE_KANBAN_ITEM]($state, { oldStatus, newProfile }) {
    // Remove from old column
    if (oldStatus && $state.kanban[oldStatus]) {
      $state.kanban[oldStatus].records = $state.kanban[
        oldStatus
      ].records.filter(p => p.id !== newProfile.id);
      $state.kanban[oldStatus].meta.count = Math.max(
        0,
        $state.kanban[oldStatus].meta.count - 1
      );
    }
    // Add to new column
    const newStatus = newProfile.status;
    if ($state.kanban[newStatus]) {
      const exists = $state.kanban[newStatus].records.some(
        p => p.id === newProfile.id
      );
      if (!exists) {
        $state.kanban[newStatus].records.unshift(newProfile);
        $state.kanban[newStatus].meta.count += 1;
      }
    }
  },
};
