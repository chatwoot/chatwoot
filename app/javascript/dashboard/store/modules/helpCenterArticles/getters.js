export const getters = {
  uiFlagsIn: state => helpCenterId => {
    const uiFlags = state.articles.uiFlags.byId[helpCenterId];
    if (uiFlags) return uiFlags;
    return { isFetching: false, isUpdating: false, isDeleting: false };
  },
  isFetchingHelpCenterArticles: state => state.uiFlags.isFetching,
  articleById: (...getterArguments) => articleId => {
    const [state] = getterArguments;
    const article = state.articles.byId[articleId];

    if (!article) return undefined;

    return article;
  },
  allArticles: (...getterArguments) => {
    const [state, _getters] = getterArguments;
    const articles = state.articles.allIds.map(id => {
      return _getters.articleById(id);
    });
    return articles;
  },
};
