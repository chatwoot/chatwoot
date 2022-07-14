export const getters = {
  uiFlagsIn: _state => helpCenterId => {
    const uiFlags = _state.helpCenters.uiFlags.byId[helpCenterId];
    if (uiFlags) return uiFlags;
    return { isFetching: false, isUpdating: false, isDeleting: false };
  },

  isFetchingHelpCenters: _state => _state.uiFlags.isFetching,
  helpCenterById: (...getterArguments) => helpCenterId => {
    const [_state, , , _rootGetters] = getterArguments;
    const helpCenter = _state.helpCenters.byId[helpCenterId];
    if (!helpCenter) return undefined;

    const { localeIds } = helpCenter;
    const localesInConversation = localeIds.map(localeId => {
      const locale = _rootGetters['locales/localeById'](localeId);
      return locale;
    });
    return {
      ...helpCenter,
      locales: localesInConversation,
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
  allLocalesCountIn: _state => helpCenterId => {
    const helpCenter = _state.helpCenters.byId[helpCenterId];
    return helpCenter ? helpCenter.localeIds.length : 0;
  },
};
