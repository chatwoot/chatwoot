import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import BulkProcessingRequestsAPI from '../../api/bulkProcessingRequests';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
  },
};

export const getters = {
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getBulkProcessingRequests: _state => _state.records,
  getBulkProcessingRequest: _state => requestId =>
    _state.records.find(record => record.id === requestId),
};

export const actions = {
  get: async function getBulkProcessingRequests({ commit }) {
    commit(types.SET_BULK_PROCESSING_REQUEST_UI_FLAG, { isFetching: true });
    try {
      const response = await BulkProcessingRequestsAPI.get();
      // Handle both old format (array) and new format (object with data and meta)
      const data = Array.isArray(response.data) ? response.data : response.data.data;
      commit(types.SET_BULK_PROCESSING_REQUESTS, data);
      return data;
    } catch (error) {
      // Handle error
      return [];
    } finally {
      commit(types.SET_BULK_PROCESSING_REQUEST_UI_FLAG, { isFetching: false });
    }
  },

  show: async function showBulkProcessingRequest({ commit }, requestId) {
    commit(types.SET_BULK_PROCESSING_REQUEST_UI_FLAG, { isFetching: true });
    try {
      const response = await BulkProcessingRequestsAPI.show(requestId);
      commit(types.UPDATE_BULK_PROCESSING_REQUEST, response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_BULK_PROCESSING_REQUEST_UI_FLAG, { isFetching: false });
    }
  },

  addRequest({ commit }, request) {
    commit(types.ADD_BULK_PROCESSING_REQUEST, request);
  },

  updateRequest({ commit }, request) {
    commit(types.UPDATE_BULK_PROCESSING_REQUEST, request);
  },

  cancel: async function cancelBulkProcessingRequest({ commit }, requestId) {
    commit(types.SET_BULK_PROCESSING_REQUEST_UI_FLAG, { isFetching: true });
    try {
      await BulkProcessingRequestsAPI.cancel(requestId);
      // Fetch updated request to get the new status
      const response = await BulkProcessingRequestsAPI.show(requestId);
      commit(types.UPDATE_BULK_PROCESSING_REQUEST, response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_BULK_PROCESSING_REQUEST_UI_FLAG, { isFetching: false });
    }
  },

  dismiss: async function dismissBulkProcessingRequest({ commit }, requestId) {
    commit(types.SET_BULK_PROCESSING_REQUEST_UI_FLAG, { isFetching: true });
    try {
      await BulkProcessingRequestsAPI.dismiss(requestId);
      // Fetch updated request to get the new dismissed_at timestamp
      const response = await BulkProcessingRequestsAPI.show(requestId);
      commit(types.UPDATE_BULK_PROCESSING_REQUEST, response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_BULK_PROCESSING_REQUEST_UI_FLAG, { isFetching: false });
    }
  },
};

export const mutations = {
  [types.SET_BULK_PROCESSING_REQUEST_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_BULK_PROCESSING_REQUESTS]: MutationHelpers.set,
  [types.ADD_BULK_PROCESSING_REQUEST]: MutationHelpers.create,
  [types.UPDATE_BULK_PROCESSING_REQUEST]: MutationHelpers.update,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
