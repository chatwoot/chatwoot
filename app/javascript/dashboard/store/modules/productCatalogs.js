import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import ProductCatalogAPI from '../../api/productCatalog';

export const state = {
  records: [],
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
};

export const actions = {
  get: async function getProductCatalogs({ commit }) {
    commit(types.SET_PRODUCT_CATALOG_UI_FLAG, { isFetching: true });
    try {
      const response = await ProductCatalogAPI.get();
      commit(types.SET_PRODUCT_CATALOGS, response.data);
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
      throw new Error(error);
    } finally {
      commit(types.SET_PRODUCT_CATALOG_UI_FLAG, { isUploading: false });
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
