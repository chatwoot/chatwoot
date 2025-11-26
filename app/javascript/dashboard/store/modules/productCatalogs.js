import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import ProductCatalogAPI from '../../api/productCatalog';

export const state = {
  records: [],
  meta: {
    current_page: 1,
    total_pages: 1,
    total_count: 0,
    per_page: 50,
  },
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
    isUploading: false,
  },
};

export const getters = {
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getProductCatalogs: _state => _state.records,
  getProductCatalog: _state => productCatalogId =>
    _state.records.find(record => record.id === productCatalogId),
  getMeta: _state => _state.meta,
};

export const actions = {
  get: async function getProductCatalogs({ commit }, { page = 1, per_page = 50, q = undefined } = {}) {
    commit(types.SET_PRODUCT_CATALOG_UI_FLAG, { isFetching: true });
    try {
      const response = await ProductCatalogAPI.get({ page, per_page, q });
      // Response now has { data: [], meta: {} } structure
      commit(types.SET_PRODUCT_CATALOGS, response.data.data);
      commit(types.SET_PRODUCT_CATALOG_META, response.data.meta);
    } catch (error) {
      // Handle error
    } finally {
      commit(types.SET_PRODUCT_CATALOG_UI_FLAG, { isFetching: false });
    }
  },

  show: async function showProductCatalog({ commit }, productCatalogId) {
    commit(types.SET_PRODUCT_CATALOG_UI_FLAG, { isFetching: true });
    try {
      const response = await ProductCatalogAPI.show(productCatalogId);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_PRODUCT_CATALOG_UI_FLAG, { isFetching: false });
    }
  },

  create: async function createProductCatalog({ commit }, productCatalogObj) {
    commit(types.SET_PRODUCT_CATALOG_UI_FLAG, { isCreating: true });
    try {
      const response = await ProductCatalogAPI.create(productCatalogObj);
      commit(types.ADD_PRODUCT_CATALOG, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_PRODUCT_CATALOG_UI_FLAG, { isCreating: false });
    }
  },

  update: async ({ commit }, { id, ...updateObj }) => {
    commit(types.SET_PRODUCT_CATALOG_UI_FLAG, { isUpdating: true });
    try {
      const response = await ProductCatalogAPI.update(id, updateObj);
      commit(types.EDIT_PRODUCT_CATALOG, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_PRODUCT_CATALOG_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async ({ commit }, productCatalogId) => {
    commit(types.SET_PRODUCT_CATALOG_UI_FLAG, { isDeleting: true });
    try {
      await ProductCatalogAPI.delete(productCatalogId);
      commit(types.DELETE_PRODUCT_CATALOG, productCatalogId);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_PRODUCT_CATALOG_UI_FLAG, { isDeleting: false });
    }
  },

  bulkDelete: async ({ commit }, productCatalogIds) => {
    commit(types.SET_PRODUCT_CATALOG_UI_FLAG, { isDeleting: true });
    try {
      await ProductCatalogAPI.bulkDelete(productCatalogIds);
      // Remove each deleted product from state
      productCatalogIds.forEach(id => {
        commit(types.DELETE_PRODUCT_CATALOG, id);
      });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_PRODUCT_CATALOG_UI_FLAG, { isDeleting: false });
    }
  },

  bulkUpload: async ({ commit }, file) => {
    commit(types.SET_PRODUCT_CATALOG_UI_FLAG, { isUploading: true });
    try {
      const response = await ProductCatalogAPI.bulkUpload(file);
      return response.data;
    } catch (error) {
      // Handle rate limit error (429)
      if (error.response?.status === 429) {
        const retryAfter = error.response?.data?.retry_after || 15;
        const rateLimitError = new Error(`RATE_LIMITED:${retryAfter}`);
        rateLimitError.isRateLimited = true;
        rateLimitError.retryAfter = retryAfter;
        throw rateLimitError;
      }
      // Extract error message from response if available
      const errorMessage = error.response?.data?.error || error.message || 'Upload failed';
      throw new Error(errorMessage);
    } finally {
      commit(types.SET_PRODUCT_CATALOG_UI_FLAG, { isUploading: false });
    }
  },

  toggleVisibility: async ({ commit }, productCatalogId) => {
    commit(types.SET_PRODUCT_CATALOG_UI_FLAG, { isUpdating: true });
    try {
      const response = await ProductCatalogAPI.toggleVisibility(productCatalogId);
      commit(types.EDIT_PRODUCT_CATALOG, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_PRODUCT_CATALOG_UI_FLAG, { isUpdating: false });
    }
  },

  exportAll: async ({ commit }) => {
    commit(types.SET_PRODUCT_CATALOG_UI_FLAG, { isExporting: true });
    try {
      const response = await ProductCatalogAPI.exportAll();
      return response.data;
    } catch (error) {
      // Handle rate limit error (429)
      if (error.response?.status === 429) {
        const retryAfter = error.response?.data?.retry_after || 15;
        const rateLimitError = new Error(`RATE_LIMITED:${retryAfter}`);
        rateLimitError.isRateLimited = true;
        rateLimitError.retryAfter = retryAfter;
        throw rateLimitError;
      }
      const errorMessage = error.response?.data?.error || error.message || 'Export failed';
      throw new Error(errorMessage);
    } finally {
      commit(types.SET_PRODUCT_CATALOG_UI_FLAG, { isExporting: false });
    }
  },

  downloadExport: async (_, bulkRequestId) => {
    try {
      const response = await ProductCatalogAPI.downloadExport(bulkRequestId);
      return response.data;
    } catch (error) {
      throw new Error(error);
    }
  },
};

export const mutations = {
  [types.SET_PRODUCT_CATALOG_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_PRODUCT_CATALOG_META](_state, meta) {
    _state.meta = meta;
  },

  [types.SET_PRODUCT_CATALOGS]: MutationHelpers.set,
  [types.ADD_PRODUCT_CATALOG]: MutationHelpers.create,
  [types.EDIT_PRODUCT_CATALOG]: MutationHelpers.update,
  [types.DELETE_PRODUCT_CATALOG]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
