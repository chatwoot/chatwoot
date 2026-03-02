export const getters = {
  getInfluencers($state) {
    return $state.sortOrder.map(id => $state.records[id]).filter(Boolean);
  },
  getInfluencer: $state => id => {
    return $state.records[id] || {};
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getMeta($state) {
    return $state.meta;
  },
  getSearchResults($state) {
    return $state.searchResults;
  },
  getSearchMeta($state) {
    return $state.searchMeta;
  },
  getLastSearchParams($state) {
    return $state.lastSearchParams;
  },
};
