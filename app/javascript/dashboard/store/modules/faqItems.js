import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import FaqItemsAPI from '../../api/faqItems';

export const state = {
  records: [],
  meta: {
    current_page: 1,
    total_pages: 1,
    total_count: 0,
  },
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

export const getters = {
  getUIFlags: _state => _state.uiFlags,
  getFaqItems: _state => _state.records,
  getFaqItem: _state => itemId =>
    _state.records.find(record => record.id === itemId),
  getMeta: _state => _state.meta,
  getItemsByCategory: _state => categoryId =>
    _state.records.filter(record => record.faq_category_id === categoryId),
};

export const actions = {
  get: async function getFaqItems(
    { commit },
    { page = 1, per_page = 50, q = undefined, category_id = undefined } = {}
  ) {
    commit(types.SET_FAQ_ITEM_UI_FLAG, { isFetching: true });
    try {
      const response = await FaqItemsAPI.get({ page, per_page, q, category_id });
      commit(types.SET_FAQ_ITEMS, response.data.data);
      commit(types.SET_FAQ_ITEMS_META, response.data.meta);
    } catch (error) {
      // Handle error
    } finally {
      commit(types.SET_FAQ_ITEM_UI_FLAG, { isFetching: false });
    }
  },

  show: async function showFaqItem({ commit }, itemId) {
    commit(types.SET_FAQ_ITEM_UI_FLAG, { isFetching: true });
    try {
      const response = await FaqItemsAPI.show(itemId);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_FAQ_ITEM_UI_FLAG, { isFetching: false });
    }
  },

  create: async function createFaqItem({ commit }, itemObj) {
    commit(types.SET_FAQ_ITEM_UI_FLAG, { isCreating: true });
    try {
      const response = await FaqItemsAPI.create(itemObj);
      commit(types.ADD_FAQ_ITEM, response.data);
      return response.data;
    } catch (error) {
      if (error.response?.status === 429) {
        const retryAfter = error.response?.data?.retry_after || 3;
        const rateLimitError = new Error('Rate limited');
        rateLimitError.isRateLimited = true;
        rateLimitError.retryAfter = retryAfter;
        throw rateLimitError;
      }
      throw error;
    } finally {
      commit(types.SET_FAQ_ITEM_UI_FLAG, { isCreating: false });
    }
  },

  update: async ({ commit }, { id, ...updateObj }) => {
    commit(types.SET_FAQ_ITEM_UI_FLAG, { isUpdating: true });
    try {
      const response = await FaqItemsAPI.update(id, updateObj);
      commit(types.EDIT_FAQ_ITEM, response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_FAQ_ITEM_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async ({ commit }, itemId) => {
    commit(types.SET_FAQ_ITEM_UI_FLAG, { isDeleting: true });
    try {
      await FaqItemsAPI.delete(itemId);
      commit(types.DELETE_FAQ_ITEM, itemId);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_FAQ_ITEM_UI_FLAG, { isDeleting: false });
    }
  },

  bulkDelete: async ({ commit }, itemIds) => {
    commit(types.SET_FAQ_ITEM_UI_FLAG, { isDeleting: true });
    try {
      await FaqItemsAPI.bulkDelete(itemIds);
      itemIds.forEach(id => {
        commit(types.DELETE_FAQ_ITEM, id);
      });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_FAQ_ITEM_UI_FLAG, { isDeleting: false });
    }
  },

  toggleVisibility: async ({ commit }, itemId) => {
    commit(types.SET_FAQ_ITEM_UI_FLAG, { isUpdating: true });
    try {
      const response = await FaqItemsAPI.toggleVisibility(itemId);
      commit(types.EDIT_FAQ_ITEM, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_FAQ_ITEM_UI_FLAG, { isUpdating: false });
    }
  },

  move: async ({ commit }, { itemId, direction }) => {
    commit(types.SET_FAQ_ITEM_UI_FLAG, { isUpdating: true });
    try {
      const response = await FaqItemsAPI.move(itemId, direction);
      // Update both swapped items to avoid page refresh
      if (response.data.items) {
        response.data.items.forEach(item => {
          commit(types.EDIT_FAQ_ITEM, item);
        });
      }
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_FAQ_ITEM_UI_FLAG, { isUpdating: false });
    }
  },
};

export const mutations = {
  [types.SET_FAQ_ITEM_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_FAQ_ITEMS_META](_state, meta) {
    _state.meta = meta;
  },

  [types.SET_FAQ_ITEMS]: MutationHelpers.set,
  [types.ADD_FAQ_ITEM]: MutationHelpers.create,
  [types.EDIT_FAQ_ITEM]: MutationHelpers.update,
  [types.DELETE_FAQ_ITEM]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
