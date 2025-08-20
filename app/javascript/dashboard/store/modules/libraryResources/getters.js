export const getters = {
  getLibraryResources(_state) {
    return _state.sortOrder.map(id => _state.records[id]).filter(Boolean);
  },
  getLibraryResource: _state => id => {
    return _state.records[id];
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getMeta(_state) {
    return _state.meta;
  },
  getLibraryResourcesCount(_state) {
    return _state.meta.count;
  },
};
