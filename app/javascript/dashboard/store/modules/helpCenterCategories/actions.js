import categoriesAPI from 'dashboard/api/helpCenter/categories.js';
import { throwErrorMessage } from 'dashboard/store/utils/api';
import types from '../../mutation-types';
export const actions = {
  index: async ({ commit }, { portalSlug, locale }) => {
    try {
      commit(types.SET_UI_FLAG, { isFetching: true });
      if (portalSlug) {
        const {
          data: { payload },
        } = await categoriesAPI.get({ portalSlug, locale });
        commit(types.CLEAR_CATEGORIES);
        const categoryIds = payload.map(category => category.id);
        commit(types.ADD_MANY_CATEGORIES, payload);
        commit(types.ADD_MANY_CATEGORIES_ID, categoryIds);
        return categoryIds;
      }
      return '';
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(types.SET_UI_FLAG, { isFetching: false });
    }
  },

  create: async ({ commit }, { portalSlug, categoryObj }) => {
    commit(types.SET_UI_FLAG, { isCreating: true });
    try {
      const {
        data: { payload },
      } = await categoriesAPI.create({ portalSlug, categoryObj });
      const { id: categoryId } = payload;
      commit(types.ADD_CATEGORY, payload);
      commit(types.ADD_CATEGORY_ID, categoryId);
      return categoryId;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(types.SET_UI_FLAG, { isCreating: false });
    }
  },

  update: async ({ commit }, { portalSlug, categoryId, categoryObj }) => {
    commit(types.ADD_CATEGORY_FLAG, {
      uiFlags: {
        isUpdating: true,
      },
      categoryId,
    });
    try {
      const {
        data: { payload },
      } = await categoriesAPI.update({
        portalSlug,
        categoryId,
        categoryObj,
      });
      commit(types.UPDATE_CATEGORY, payload);
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

  delete: async ({ commit }, { portalSlug, categoryId }) => {
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

  reorder: async ({ commit, state }, { portalSlug, reorderedGroup }) => {
    // Save old positions so we can rollback on failure
    const oldPositions = Object.keys(reorderedGroup).reduce((map, id) => {
      map[id] = state.categories.byId[id]?.position;
      return map;
    }, {});
    // Update positions in the store immediately so subsequent mutations preserve correct positions
    commit(types.SET_CATEGORY_POSITIONS, reorderedGroup);
    try {
      await categoriesAPI.reorder({
        portalSlug,
        reorderedGroup,
      });
    } catch (error) {
      commit(types.SET_CATEGORY_POSITIONS, oldPositions);
      throw error;
    }
  },
};
