import articlesAPI from 'dashboard/api/helpCenter/articles';
import { uploadExternalImage, uploadFile } from 'dashboard/helper/uploadHelper';
import { throwErrorMessage } from 'dashboard/store/utils/api';
import camelcaseKeys from 'camelcase-keys';

import types from '../../mutation-types';
export const actions = {
  index: async (
    { commit },
    { pageNumber, portalSlug, locale, status, authorId, categorySlug }
  ) => {
    try {
      commit(types.SET_UI_FLAG, { isFetching: true });
      const { data } = await articlesAPI.getArticles({
        pageNumber,
        portalSlug,
        locale,
        status,
        authorId,
        categorySlug,
      });
      const payload = camelcaseKeys(data.payload);
      const meta = camelcaseKeys(data.meta);
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

  create: async ({ commit, dispatch }, { portalSlug, ...articleObj }) => {
    commit(types.SET_UI_FLAG, { isCreating: true });
    try {
      const { data } = await articlesAPI.createArticle({
        portalSlug,
        articleObj,
      });
      const payload = camelcaseKeys(data.payload);
      const { id: articleId } = payload;
      commit(types.ADD_ARTICLE, payload);
      commit(types.ADD_ARTICLE_ID, articleId);
      commit(types.ADD_ARTICLE_FLAG, articleId);
      dispatch('portals/updatePortal', portalSlug, { root: true });
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
      const { data } = await articlesAPI.getArticle({ id, portalSlug });
      const payload = camelcaseKeys(data.payload);
      const { id: articleId } = payload;
      commit(types.ADD_ARTICLE, payload);
      commit(types.ADD_ARTICLE_ID, articleId);
      commit(types.SET_UI_FLAG, { isFetching: false });
    } catch (error) {
      commit(types.SET_UI_FLAG, { isFetching: false });
    }
  },

  updateAsync: async ({ commit }, { portalSlug, articleId, ...articleObj }) => {
    commit(types.UPDATE_ARTICLE_FLAG, {
      uiFlags: { isUpdating: true },
      articleId,
    });

    try {
      await articlesAPI.updateArticle({ portalSlug, articleId, articleObj });
      return articleId;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(types.UPDATE_ARTICLE_FLAG, {
        uiFlags: { isUpdating: false },
        articleId,
      });
    }
  },

  update: async ({ commit }, { portalSlug, articleId, ...articleObj }) => {
    commit(types.UPDATE_ARTICLE_FLAG, {
      uiFlags: {
        isUpdating: true,
      },
      articleId,
    });

    try {
      const { data } = await articlesAPI.updateArticle({
        portalSlug,
        articleId,
        articleObj,
      });
      const payload = camelcaseKeys(data.payload);
      commit(types.UPDATE_ARTICLE, payload);

      return articleId;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(types.UPDATE_ARTICLE_FLAG, {
        uiFlags: {
          isUpdating: false,
        },
        articleId,
      });
    }
  },

  delete: async ({ commit }, { portalSlug, articleId }) => {
    commit(types.UPDATE_ARTICLE_FLAG, {
      uiFlags: {
        isDeleting: true,
      },
      articleId,
    });
    try {
      await articlesAPI.deleteArticle({ portalSlug, articleId });
      commit(types.REMOVE_ARTICLE, articleId);
      commit(types.REMOVE_ARTICLE_ID, articleId);
      return articleId;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(types.UPDATE_ARTICLE_FLAG, {
        uiFlags: {
          isDeleting: false,
        },
        articleId,
      });
    }
  },

  attachImage: async (_, { file }) => {
    const { fileUrl } = await uploadFile(file);
    return fileUrl;
  },

  uploadExternalImage: async (_, { url }) => {
    const { fileUrl } = await uploadExternalImage(url);
    return fileUrl;
  },

  reorder: async (_, { portalSlug, categorySlug, reorderedGroup }) => {
    try {
      await articlesAPI.reorderArticles({
        portalSlug,
        reorderedGroup,
        categorySlug,
      });
    } catch (error) {
      throwErrorMessage(error);
    }

    return '';
  },
};
