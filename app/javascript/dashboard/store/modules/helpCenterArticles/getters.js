export const getters = {
  uiFlagsIn: _state => helpCenterId => {
    const uiFlags = _state.articles.uiFlags.byId[helpCenterId];
    if (uiFlags) return uiFlags;
    return { isFetching: false, isUpdating: false, isDeleting: false };
  },
  allHelpCenterArticles: (...getterArguments) => {
    const [_state, _getters] = getterArguments;

    const articles = _state.articles.allIds.map(id => {
      return _getters.helpCenterById(id);
    });
    return articles;
  },
};
