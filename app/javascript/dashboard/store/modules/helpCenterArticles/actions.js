import helpCenterArticlesAPI from 'dashboard/api/helpcenter/article.js';
import types from '../../mutation-types';
export const actions = {
  get: async ({ commit }) => {
    try {
      commit(types.SET_UI_FLAG, { isFetching: true });
      const { data } = await helpCenterArticlesAPI.get();

      data.payload.forEach(article => {
        const { id: articleId } = article;

        commit(types.ADD_HELP_CENTER_ARTICLE, article);
        commit(types.ADD_HELP_CENTER_ARTICLE_ID, articleId);
        commit(types.ADD_HELP_CENTER_ARTICLE_FLAG, {
          uiFlags: {},
          articleId,
        });
      });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_UI_FLAG, { isFetching: false });
    }
  },

  create: async ({ commit }, params) => {
    commit(types.SET_UI_FLAG, { isCreating: true });
    try {
      const { data } = await helpCenterArticlesAPI.create(params);
      const { id: articleId } = data;
      commit(types.ADD_HELP_CENTER_ARTICLE, data);
      commit(types.ADD_HELP_CENTER_ARTICLE_ID, articleId);
      return articleId;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_UI_FLAG, { isCreating: false });
    }
  },
  update: async ({ commit }, params) => {
    const articleId = params.id;
    commit(types.SET_UI_FLAG, {
      uiFlags: {
        isUpdating: true,
      },
      articleId,
    });
    try {
      const { data } = await helpCenterArticlesAPI.update(params);

      commit(types.UPDATE_HELP_CENTER_ARTICLE, data);

      return articleId;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_UI_FLAG, {
        uiFlags: {
          isUpdating: false,
        },
        articleId,
      });
    }
  },
  delete: async ({ commit }, articleId) => {
    commit(types.SET_UI_FLAG, {
      uiFlags: {
        isDeleting: true,
      },
      articleId,
    });
    try {
      await helpCenterArticlesAPI.delete(articleId);

      commit(types.REMOVE_HELP_CENTER_ARTICLE, articleId);
      commit(types.REMOVE_HELP_CENTER_ARTICLE_ID, articleId);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_UI_FLAG, {
        uiFlags: {
          isDeleting: false,
        },
        articleId,
      });
    }
  },
};
