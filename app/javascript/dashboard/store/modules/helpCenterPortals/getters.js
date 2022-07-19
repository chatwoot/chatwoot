export const getters = {
  uiFlagsIn: _state => helpCenterId => {
    const uiFlags = _state.helpCenters.uiFlags.byId[helpCenterId];
    if (uiFlags) return uiFlags;
    return { isFetching: false, isUpdating: false, isDeleting: false };
  },

  isFetchingHelpCenters: _state => _state.uiFlags.isFetching,
  helpCenterById: (...getterArguments) => helpCenterId => {
    const [_state] = getterArguments;
    const helpCenter = _state.helpCenters.byId[helpCenterId];
    if (!helpCenter) return undefined;

    return {
      ...helpCenter,
    };
  },
  allHelpCenters: (...getterArguments) => {
    const [_state, _getters] = getterArguments;

    const helpCenters = _state.helpCenters.allIds.map(id => {
      return _getters.helpCenterById(id);
    });
    return helpCenters;
  },
  totalHelpCentersCount: _state => _state.helpCenters.allIds.length || 0,
};
