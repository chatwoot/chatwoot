import portalAPI from 'dashboard/api/helpCenter/portals';
import articlesAPI from 'dashboard/api/helpCenter/articles';
import { throwErrorMessage } from 'dashboard/store/utils/api';
import types from '../../mutation-types';
export const actions = {
  index: async ({ commit }, { pageNumber, portalSlug, locale }) => {
    try {
      commit(types.SET_UI_FLAG, { isFetching: true });
      const {
        data: { payload, meta },
      } = await portalAPI.getArticles({
        pageNumber,
        portalSlug,
        locale,
      });
      const articleIds = payload.map(article => article.id);
      commit(types.CLEAR_ARTICLES);
      commit(types.ADD_MANY_ARTICLES, payload);
      commit(types.SET_ARTICLES_META, meta);
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

  show: async ({ commit }, { id, portalSlug }) => {
    commit(types.SET_UI_FLAG, { isFetching: true });
    try {
      const response = await portalAPI.getArticle({ id, portalSlug });
      const {
        data: { payload },
      } = response;
      const { id: articleId } = payload;
      commit(types.ADD_ARTICLE, payload);
      commit(types.ADD_ARTICLE_ID, articleId);
      commit(types.SET_UI_FLAG, { isFetching: false });
    } catch (error) {
      commit(types.SET_UI_FLAG, { isFetching: false });
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
