import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import AttributeAPI from '../../api/attributes';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
  dataSourceValues: [],
};

export const getters = {
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getAttributeByKey: $state => key => {
    return $state.records.find(x => x.attribute_key === key);
  },
  getAttributes: _state => {
    return _state.records;
  },
  getAttributesByModel: _state => attributeModel => {
    return _state.records.filter(
      record => record.attribute_model === attributeModel
    );
  },
  getAttributeValuesForDataSource: _state => {
    return _state.dataSourceValues;
  },
};

export const actions = {
  get: async function getAttributesByModel({ commit }) {
    commit(types.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isFetching: true });
    try {
      const response = await AttributeAPI.getAttributesByModel();
      commit(types.SET_CUSTOM_ATTRIBUTE, response.data);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isFetching: false });
    }
  },
  create: async function createAttribute({ commit }, attributeObj) {
    commit(types.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isCreating: true });
    try {
      const response = await AttributeAPI.create(attributeObj);
      commit(types.ADD_CUSTOM_ATTRIBUTE, response.data);
    } catch (error) {
      const errorMessage = error?.response?.data?.message;
      throw new Error(errorMessage);
    } finally {
      commit(types.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isCreating: false });
    }
  },
  update: async ({ commit }, { id, ...updateObj }) => {
    commit(types.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isUpdating: true });
    try {
      const response = await AttributeAPI.update(id, updateObj);
      commit(types.EDIT_CUSTOM_ATTRIBUTE, response.data);
    } catch (error) {
      const errorMessage = error?.response?.data?.message;
      throw new Error(errorMessage);
    } finally {
      commit(types.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isUpdating: false });
    }
  },
  delete: async ({ commit }, id) => {
    commit(types.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isDeleting: true });
    try {
      await AttributeAPI.delete(id);
      commit(types.DELETE_CUSTOM_ATTRIBUTE, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isDeleting: false });
    }
  },
  // To retrieve the attribute values for the attribute record with the key 'data-source'
  // and the model ':contact_attribute'.
  // This was used for the Conversion Report
  getDataSourceValues: async ({ commit }) => {
    commit(types.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isFetching: true });
    try {
      const response = await AttributeAPI.getDataSourceValues();
      commit(types.SET_DATA_SOURCE_VALUES, response.data);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_CUSTOM_ATTRIBUTE_UI_FLAG, { isFetching: false });
    }
  },
};

export const mutations = {
  [types.SET_CUSTOM_ATTRIBUTE_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.ADD_CUSTOM_ATTRIBUTE]: MutationHelpers.create,
  [types.SET_CUSTOM_ATTRIBUTE]: MutationHelpers.set,
  [types.EDIT_CUSTOM_ATTRIBUTE]: MutationHelpers.update,
  [types.DELETE_CUSTOM_ATTRIBUTE]: MutationHelpers.destroy,

  [types.SET_DATA_SOURCE_VALUES](_state, data) {
    _state.dataSourceValues = data;
  },
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
