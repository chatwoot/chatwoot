import Vue from 'vue';
import types from '../mutation-types';
import ProductAPI from '../../api/products';

export const state = {
  meta: {
    count: 0,
    currentPage: 1,
  },
  records: {},
  uiFlags: {
    isFetching: false,
    isFetchingItem: false,
    isUpdating: false,
    isDeleting: false,
  },
  sortOrder: [],
};

export const getters = {
  getProducts($state) {
    return $state.sortOrder.map(productId => $state.records[productId]);
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getProduct: $state => id => {
    const product = $state.records[id];
    return product || {};
  },
  getMeta: $state => {
    return $state.meta;
  },
};

const buildProductFormData = productParams => {
  const formData = new FormData();
  const { ...productProperties } = productParams;
  Object.keys(productProperties).forEach(key => {
    if (productProperties[key]) {
      formData.append(key, productProperties[key]);
    }
  });
  return formData;
};

export const actions = {
  search: async ({ commit }, { search, page, sortAttr }) => {
    commit(types.SET_PRODUCT_UI_FLAG, { isFetching: true });
    try {
      const {
        data: { payload, meta },
      } = await ProductAPI.search(search, page, sortAttr);
      commit(types.CLEAR_PRODUCTS);
      commit(types.SET_PRODUCTS, payload);
      commit(types.SET_PRODUCT_META, meta);
      commit(types.SET_PRODUCT_UI_FLAG, { isFetching: false });
    } catch (error) {
      commit(types.SET_PRODUCT_UI_FLAG, { isFetching: false });
    }
  },

  get: async ({ commit }, { page = 1, sortAttr } = {}) => {
    commit(types.SET_PRODUCT_UI_FLAG, { isFetching: true });
    try {
      const {
        data: { payload, meta },
      } = await ProductAPI.get(page, sortAttr);

      commit(types.CLEAR_PRODUCTS);
      commit(types.SET_PRODUCTS, payload);
      commit(types.SET_PRODUCT_META, meta);
      commit(types.SET_PRODUCT_UI_FLAG, { isFetching: false });
    } catch (error) {
      commit(types.SET_PRODUCT_UI_FLAG, { isFetching: false });
    }
  },

  show: async ({ commit }, { id }) => {
    commit(types.SET_PRODUCT_UI_FLAG, { isFetchingItem: true });
    try {
      const response = await ProductAPI.show(id);
      commit(types.SET_PRODUCT_ITEM, response.data.payload);
      commit(types.SET_PRODUCT_UI_FLAG, {
        isFetchingItem: false,
      });
    } catch (error) {
      commit(types.SET_PRODUCT_UI_FLAG, {
        isFetchingItem: false,
      });
    }
  },

  update: async ({ commit }, { id, isFormData = false, ...productParams }) => {
    commit(types.SET_PRODUCT_UI_FLAG, { isUpdating: true });
    try {
      const response = await ProductAPI.update(
        id,
        isFormData ? buildProductFormData(productParams) : productParams
      );
      commit(types.EDIT_PRODUCT, response.data.payload);
      commit(types.SET_PRODUCT_UI_FLAG, { isUpdating: false });
    } catch (error) {
      commit(types.SET_PRODUCT_UI_FLAG, { isUpdating: false });
    }
  },

  create: async ({ commit }, { isFormData = false, ...productParams }) => {
    commit(types.SET_PRODUCT_UI_FLAG, { isCreating: true });
    try {
      const response = await ProductAPI.create(
        isFormData ? buildProductFormData(productParams) : productParams
      );

      commit(types.SET_PRODUCT_ITEM, response.data.payload.product);
      commit(types.SET_PRODUCT_UI_FLAG, { isCreating: false });
      return response.data.payload.product;
    } catch (error) {
      commit(types.SET_PRODUCT_UI_FLAG, { isCreating: false });
      throw error;
    }
  },

  delete: async ({ commit }, id) => {
    commit(types.SET_PRODUCT_UI_FLAG, { isDeleting: true });
    try {
      await ProductAPI.delete(id);
      commit(types.SET_PRODUCT_UI_FLAG, { isDeleting: false });
    } catch (error) {
      commit(types.SET_PRODUCT_UI_FLAG, { isDeleting: false });
      if (error.response?.data?.message) {
        throw new Error(error.response.data.message);
      } else {
        throw new Error(error);
      }
    }
  },

  setProduct({ commit }, data) {
    commit(types.SET_PRODUCT_ITEM, data);
  },

  updateProduct: async ({ commit }, updateObj) => {
    commit(types.SET_PRODUCT_UI_FLAG, { isUpdating: true });
    try {
      commit(types.EDIT_PRODUCT, updateObj);
      commit(types.SET_PRODUCT_UI_FLAG, { isUpdating: false });
    } catch (error) {
      commit(types.SET_PRODUCT_UI_FLAG, { isUpdating: false });
    }
  },
};

export const mutations = {
  [types.SET_PRODUCT_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },

  [types.CLEAR_PRODUCTS]: $state => {
    Vue.set($state, 'records', {});
    Vue.set($state, 'sortOrder', []);
  },

  [types.SET_PRODUCT_META]: ($state, data) => {
    const { count, current_page: currentPage } = data;
    Vue.set($state.meta, 'count', count);
    Vue.set($state.meta, 'currentPage', currentPage);
  },

  [types.SET_PRODUCTS]: ($state, data) => {
    const sortOrder = data.map(product => {
      Vue.set($state.records, product.id, {
        ...($state.records[product.id] || {}),
        ...product,
      });
      return product.id;
    });
    $state.sortOrder = sortOrder;
  },

  [types.SET_PRODUCT_ITEM]: ($state, data) => {
    Vue.set($state.records, data.id, {
      ...($state.records[data.id] || {}),
      ...data,
    });

    if (!$state.sortOrder.includes(data.id)) {
      $state.sortOrder.push(data.id);
    }
  },

  [types.EDIT_PRODUCT]: ($state, data) => {
    Vue.set($state.records, data.id, data);
  },

  [types.DELETE_PRODUCT]: ($state, id) => {
    const index = $state.sortOrder.findIndex(item => item === id);
    Vue.delete($state.sortOrder, index);
    Vue.delete($state.records, id);
  },
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
