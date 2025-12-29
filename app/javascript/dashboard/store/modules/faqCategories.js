import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import FaqCategoriesAPI from '../../api/faqCategories';

export const state = {
  records: [],
  tree: [],
  meta: {
    current_page: 1,
    total_pages: 1,
    total_count: 0,
  },
  uiFlags: {
    isFetching: false,
    isFetchingTree: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

export const getters = {
  getUIFlags: _state => _state.uiFlags,
  getCategories: _state => _state.records,
  getTree: _state => _state.tree,
  getMeta: _state => _state.meta,
  getCategory: _state => categoryId =>
    _state.records.find(record => record.id === categoryId),
  getRootCategories: _state =>
    _state.records.filter(record => record.parent_id === null),
};

export const actions = {
  get: async function getCategories({ commit }) {
    commit(types.SET_FAQ_CATEGORY_UI_FLAG, { isFetching: true });
    try {
      const response = await FaqCategoriesAPI.get();
      commit(types.SET_FAQ_CATEGORIES, response.data.data);
    } catch (error) {
      // Handle error
    } finally {
      commit(types.SET_FAQ_CATEGORY_UI_FLAG, { isFetching: false });
    }
  },

  getTree: async function getCategoryTree(
    { commit },
    { page = 1, per_page = 50, q = undefined } = {}
  ) {
    commit(types.SET_FAQ_CATEGORY_UI_FLAG, { isFetchingTree: true });
    try {
      const response = await FaqCategoriesAPI.getTree({ page, per_page, q });
      commit(types.SET_FAQ_CATEGORY_TREE, response.data.data);
      commit(types.SET_FAQ_CATEGORIES_META, response.data.meta);
      return response.data.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_FAQ_CATEGORY_UI_FLAG, { isFetchingTree: false });
    }
  },

  fetchTree: async function fetchCategoryTree({ dispatch }, params = {}) {
    return dispatch('getTree', params);
  },

  show: async function showCategory({ commit }, categoryId) {
    commit(types.SET_FAQ_CATEGORY_UI_FLAG, { isFetching: true });
    try {
      const response = await FaqCategoriesAPI.show(categoryId);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_FAQ_CATEGORY_UI_FLAG, { isFetching: false });
    }
  },

  create: async function createCategory({ commit }, categoryObj) {
    commit(types.SET_FAQ_CATEGORY_UI_FLAG, { isCreating: true });
    try {
      const response = await FaqCategoriesAPI.create(categoryObj);
      commit(types.ADD_FAQ_CATEGORY, response.data);
      return response.data;
    } catch (error) {
      if (error.response?.status === 429) {
        const retryAfter = error.response?.data?.retry_after || 5;
        const rateLimitError = new Error('Rate limited');
        rateLimitError.isRateLimited = true;
        rateLimitError.retryAfter = retryAfter;
        throw rateLimitError;
      }
      throw error;
    } finally {
      commit(types.SET_FAQ_CATEGORY_UI_FLAG, { isCreating: false });
    }
  },

  update: async ({ commit }, { id, ...updateObj }) => {
    commit(types.SET_FAQ_CATEGORY_UI_FLAG, { isUpdating: true });
    try {
      const response = await FaqCategoriesAPI.update(id, updateObj);
      commit(types.EDIT_FAQ_CATEGORY, response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_FAQ_CATEGORY_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async ({ commit }, categoryId) => {
    commit(types.SET_FAQ_CATEGORY_UI_FLAG, { isDeleting: true });
    try {
      await FaqCategoriesAPI.delete(categoryId);
      commit(types.DELETE_FAQ_CATEGORY, categoryId);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_FAQ_CATEGORY_UI_FLAG, { isDeleting: false });
    }
  },

  toggleVisibility: async ({ commit }, categoryId) => {
    commit(types.SET_FAQ_CATEGORY_UI_FLAG, { isUpdating: true });
    try {
      const response = await FaqCategoriesAPI.toggleVisibility(categoryId);
      commit(types.EDIT_FAQ_CATEGORY, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_FAQ_CATEGORY_UI_FLAG, { isUpdating: false });
    }
  },

  move: async ({ commit }, { id, parentId, position }) => {
    commit(types.SET_FAQ_CATEGORY_UI_FLAG, { isUpdating: true });
    try {
      const response = await FaqCategoriesAPI.move(id, { parentId, position });
      commit(types.EDIT_FAQ_CATEGORY, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_FAQ_CATEGORY_UI_FLAG, { isUpdating: false });
    }
  },
};

export const mutations = {
  [types.SET_FAQ_CATEGORY_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_FAQ_CATEGORY_TREE](_state, tree) {
    _state.tree = tree;
  },

  [types.SET_FAQ_CATEGORIES_META](_state, meta) {
    _state.meta = meta;
  },

  [types.SET_FAQ_CATEGORIES]: MutationHelpers.set,
  [types.ADD_FAQ_CATEGORY]: MutationHelpers.create,
  [types.EDIT_FAQ_CATEGORY]: MutationHelpers.update,
  [types.DELETE_FAQ_CATEGORY]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
