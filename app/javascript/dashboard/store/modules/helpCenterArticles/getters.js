export const getters = {
  uiFlagsIn: _state => helpCenterId => {
    const uiFlags = _state.articles.uiFlags.byId[helpCenterId];
    if (uiFlags) return uiFlags;
    return { isFetching: false, isUpdating: false, isDeleting: false };
  },
  isFetchingHelpCenterArticles: _state => _state.uiFlags.isFetching,
  helpCenterArticleById: (...getterArguments) => articleId => {
    const [_state] = getterArguments;
    const article = _state.articles.byId[articleId];

    // const { author_id } = article;
    // const author = _rootGetters['authors/authorById'](author_id);

    if (!article) return undefined;

    return {
      ...article,
      // author,
    };
  },
  allHelpCenterArticles: (...getterArguments) => {
    const [_state, _getters] = getterArguments;
    const articles = _state.articles.allIds.map(id => {
      return _getters.helpCenterArticleById(id);
    });
    return articles;
  },
};
