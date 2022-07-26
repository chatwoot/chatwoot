import articlesAPI from 'dashboard/api/helpCenter/articles.js';
import { throwErrorMessage } from 'dashboard/store/utils/api';
import types from '../../mutation-types';
export const actions = {
  index: async ({ commit }) => {
    try {
      commit(types.SET_UI_FLAG, { isFetching: true });
      const { data } = await articlesAPI.get();
      const articleIds = data.map(article => article.id);
      commit(types.ADD_MANY_ARTICLES, data);
      commit(types.ADD_MANY_ARTICLES_ID, articleIds);
      return articleIds;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(types.SET_UI_FLAG, { isFetching: false });
    }
  },

  create: async ({ commit }, params) => {
    commit(types.SET_UI_FLAG, { isCreating: true });
    try {
      const { data } = await articlesAPI.create(params);
      const { id: articleId } = data;
      commit(types.ADD_ARTICLE, data);
      commit(types.ADD_ARTICLE_ID, articleId);
      return articleId;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(types.SET_UI_FLAG, { isCreating: false });
    }
  },
  update: async ({ commit }, params) => {
    const articleId = params.id;
    commit(types.ADD_ARTICLE_FLAG, {
      uiFlags: {
        isUpdating: true,
      },
      articleId,
    });
    try {
      const { data } = await articlesAPI.update(params);

      commit(types.UPDATE_ARTICLE, data);

      return articleId;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(types.ADD_ARTICLE_FLAG, {
        uiFlags: {
          isUpdating: false,
        },
        articleId,
      });
    }
  },
  delete: async ({ commit }, articleId) => {
    commit(types.ADD_ARTICLE_FLAG, {
      uiFlags: {
        isDeleting: true,
      },
      articleId,
    });
    try {
      await articlesAPI.delete(articleId);

      commit(types.REMOVE_ARTICLE, articleId);
      commit(types.REMOVE_ARTICLE_ID, articleId);
      return articleId;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(types.ADD_ARTICLE_FLAG, {
        uiFlags: {
          isDeleting: false,
        },
        articleId,
      });
    }
  },
};
