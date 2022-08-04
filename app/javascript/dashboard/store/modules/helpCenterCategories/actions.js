import categoriesAPI from 'dashboard/api/helpCenter/categories.js';
import { throwErrorMessage } from 'dashboard/store/utils/api';
import types from '../../mutation-types';
export const actions = {
  index: async ({ commit }, { portalSlug }) => {
    try {
      commit(types.SET_UI_FLAG, { isFetching: true });
      const {
        data: { payload },
      } = await categoriesAPI.get({ portalSlug });
      const categoryIds = payload.map(category => category.id);
      commit(types.ADD_MANY_CATEGORIES, payload);
      commit(types.ADD_MANY_CATEGORIES_ID, categoryIds);
      return categoryIds;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(types.SET_UI_FLAG, { isFetching: false });
    }
  },

  create: async ({ commit }, portalSlug, categoryObj) => {
    commit(types.SET_UI_FLAG, { isCreating: true });
    try {
      const { data } = await categoriesAPI.create({ portalSlug, categoryObj });
      const { id: categoryId } = data;
      commit(types.ADD_CATEGORY, data);
      commit(types.ADD_CATEGORY_ID, categoryId);
      return categoryId;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(types.SET_UI_FLAG, { isCreating: false });
    }
  },

  update: async ({ commit }, portalSlug, categoryObj) => {
    const categoryId = categoryObj.id;
    commit(types.ADD_CATEGORY_FLAG, {
      uiFlags: {
        isUpdating: true,
      },
      categoryId,
    });
    try {
      const { data } = await categoriesAPI.update({ portalSlug, categoryObj });
      commit(types.UPDATE_CATEGORY, data);
      return categoryId;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(types.ADD_CATEGORY_FLAG, {
        uiFlags: {
          isUpdating: false,
        },
        categoryId,
      });
    }
  },

  delete: async ({ commit }, portalSlug, categoryId) => {
    commit(types.ADD_CATEGORY_FLAG, {
      uiFlags: {
        isDeleting: true,
      },
      categoryId,
    });
    try {
      await categoriesAPI.delete({ portalSlug, categoryId });
      commit(types.REMOVE_CATEGORY, categoryId);
      commit(types.REMOVE_CATEGORY_ID, categoryId);
      return categoryId;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(types.ADD_CATEGORY_FLAG, {
        uiFlags: {
          isDeleting: false,
        },
        categoryId,
      });
    }
  },
};
