export const getters = {
  uiFlagsIn: state => portalId => {
    const uiFlags = state.portals.uiFlags.byId[portalId];
    if (uiFlags) return uiFlags;
    return { isFetching: false, isUpdating: false, isDeleting: false };
  },

  isFetchingPortals: state => state.uiFlags.isFetching,
  portalBySlug: (...getterArguments) => portalId => {
    const [state] = getterArguments;
    return state.portals.byId[portalId];
  },
  allPortals: (...getterArguments) => {
    const [state, _getters] = getterArguments;
    return state.portals.allIds.map(id => {
      return _getters.portalBySlug(id);
    });
  },
  count: state => state.portals.allIds.length || 0,
  getMeta: state => {
    return state.meta;
  },
};
