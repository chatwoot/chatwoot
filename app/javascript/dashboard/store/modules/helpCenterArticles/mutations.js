import types from '../../mutation-types';
import Vue from 'vue';

export const mutations = {
  [types.SET_UI_FLAG](_state, uiFlags) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...uiFlags,
    };
  },

  [types.ADD_HELP_CENTER_ARTICLE]: ($state, article) => {
    if (!article.id) return;

    Vue.set($state.articles.byId, article.id, {
      ...article,
    });
  },
  [types.ADD_HELP_CENTER_ARTICLE_ID]: ($state, articleId) => {
    if (!articleId) return;
    $state.articles.allIds.push(articleId);
  },
  [types.ADD_HELP_CENTER_ARTICLE_FLAG]: ($state, { articleId, uiFlags }) => {
    const flags = $state.articles.uiFlags.byId[articleId];
    Vue.set($state.articles.uiFlags.byId, articleId, {
      ...{
        isFetching: false,
        isUpdating: false,
        isDeleting: false,
      },
      ...flags,
      ...uiFlags,
    });
  },
  [types.UPDATE_HELP_CENTER_ARTICLE]($state, article) {
    const articleId = article.id;
    if (!articleId) return;
    if (!$state.articles.allIds.includes(articleId)) return;

    Vue.set($state.articles.byId, articleId, {
      ...article,
    });
  },
  [types.REMOVE_HELP_CENTER_ARTICLE]($state, articleId) {
    if (!articleId) return;

    const { [articleId]: toBeRemoved, ...newById } = $state.articles.byId;
    Vue.set($state.articles, 'byId', newById);
  },
  [types.REMOVE_HELP_CENTER_ARTICLE_ID]($state, articleId) {
    $state.articles.allIds = $state.articles.allIds.filter(
      id => id !== articleId
    );
  },
};
