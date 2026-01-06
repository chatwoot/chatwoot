import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import ProductsAPI from '../../api/products';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

export const getters = {
  getProducts(_state) {
    return _state.records;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getProductById: _state => id => {
    return _state.records.find(record => record.id === Number(id));
  },
};

export const actions = {
  get: async function getProducts({ commit }) {
    commit(types.SET_PRODUCT_UI_FLAG, { isFetching: true });
    try {
      const response = await ProductsAPI.get();
      commit(types.SET_PRODUCTS, response.data.payload);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_PRODUCT_UI_FLAG, { isFetching: false });
    }
  },

  create: async function createProduct({ commit }, productData) {
    commit(types.SET_PRODUCT_UI_FLAG, { isCreating: true });
    try {
      const response = await ProductsAPI.create(productData);
      commit(types.ADD_PRODUCT, response.data);
      return response.data;
    } catch (error) {
      const errorMessage = error?.response?.data?.message;
      throw new Error(errorMessage);
    } finally {
      commit(types.SET_PRODUCT_UI_FLAG, { isCreating: false });
    }
  },

  update: async function updateProduct({ commit }, { id, ...updateObj }) {
    commit(types.SET_PRODUCT_UI_FLAG, { isUpdating: true });
    try {
      const response = await ProductsAPI.update(id, updateObj);
      commit(types.EDIT_PRODUCT, response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_PRODUCT_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async function deleteProduct({ commit }, id) {
    commit(types.SET_PRODUCT_UI_FLAG, { isDeleting: true });
    try {
      await ProductsAPI.delete(id);
      commit(types.DELETE_PRODUCT, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_PRODUCT_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_PRODUCT_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },
  [types.SET_PRODUCTS]: MutationHelpers.set,
  [types.ADD_PRODUCT]: MutationHelpers.create,
  [types.EDIT_PRODUCT]: MutationHelpers.update,
  [types.DELETE_PRODUCT]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
