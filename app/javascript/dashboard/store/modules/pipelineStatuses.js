import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import PipelineStatusesAPI from '../../api/pipeline_statuses';

const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

export const getters = {
  getPipelineStatuses($state) {
    return $state.records;
  },
  getUiFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  get: async ({ commit }) => {
    commit(types.SET_PIPELINE_STATUS_FETCHING_STATUS, true);

    try {
      const response = await PipelineStatusesAPI.get();

      commit(types.SET_PIPELINE_STATUS_FETCHING_STATUS, false);
      commit(types.SET_PIPELINE_STATUSES, response.data.pipeline_statuses);
    } catch (error) {
      commit(types.SET_PIPELINE_STATUS_FETCHING_STATUS, false);
    }
  },

  create: async ({ commit }, pipelineStatusInfo) => {
    commit(types.SET_PIPELINE_STATUS_CREATING_STATUS, true);
    try {
      const response = await PipelineStatusesAPI.create(pipelineStatusInfo);
      commit(types.ADD_PIPELINE_STATUS, response.data);
      commit(types.SET_PIPELINE_STATUS_CREATING_STATUS, false);
    } catch (error) {
      commit(types.SET_PIPELINE_STATUS_CREATING_STATUS, false);
      throw error;
    }
  },

  update: async ({ commit }, { id, ...pipelineStatusParams }) => {
    commit(types.SET_PIPELINE_STATUS_UPDATING_STATUS, true);
    try {
      const response = await PipelineStatusesAPI.update(
        id,
        pipelineStatusParams
      );

      commit(types.EDIT_PIPELINE_STATUS, response.data);
      commit(types.SET_PIPELINE_STATUS_UPDATING_STATUS, false);
    } catch (error) {
      commit(types.SET_PIPELINE_STATUS_UPDATING_STATUS, false);
      throw error;
    }
  },

  delete: async ({ commit }, pipelineStatusId) => {
    commit(types.SET_PIPELINE_STATUS_DELETING_STATUS, true);
    try {
      await PipelineStatusesAPI.delete(pipelineStatusId);
      commit(types.DELETE_PIPELINE_STATUS, pipelineStatusId);
      commit(types.SET_PIPELINE_STATUS_DELETING_STATUS, false);
    } catch (error) {
      commit(types.SET_PIPELINE_STATUS_DELETING_STATUS, false);
      throw error;
    }
  },
};

export const mutations = {
  [types.SET_PIPELINE_STATUS_FETCHING_STATUS]($state, status) {
    $state.uiFlags.isFetching = status;
  },
  [types.SET_PIPELINE_STATUS_CREATING_STATUS]($state, status) {
    $state.uiFlags.isCreating = status;
  },
  [types.SET_PIPELINE_STATUS_UPDATING_STATUS]($state, status) {
    $state.uiFlags.isUpdating = status;
  },
  [types.SET_PIPELINE_STATUS_DELETING_STATUS]($state, status) {
    $state.uiFlags.isDeleting = status;
  },
  [types.SET_PIPELINE_STATUSES]: MutationHelpers.set,
  [types.ADD_PIPELINE_STATUS]: MutationHelpers.create,
  [types.EDIT_PIPELINE_STATUS]: MutationHelpers.update,
  [types.DELETE_PIPELINE_STATUS]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
