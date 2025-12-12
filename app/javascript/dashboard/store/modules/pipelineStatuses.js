import types from '../mutation-types';
import PipelineStatusesAPI from '../../api/pipeline_statuses';

const state = {
  records: [],
  uiFlags: {
    isLoading: true,
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

  organizeConversations: ({ commit }, { conversations = [] }) => {
    commit(types.SET_PIPELINE_STATUS_LOADING, true);
    commit(types.ORGANIZE_CONVERSATIONS_BY_PIPELINE_STATUS, {
      conversations,
    });
    commit(types.SET_PIPELINE_STATUS_LOADING, false);
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
  [types.SET_PIPELINE_STATUSES]($state, data) {
    $state.records = data.map(status => ({
      id: status.id,
      name: status.name,
      conversations: [],
      is_new: false,
      conversations_count: status.conversation_count,
    }));
  },
  [types.ADD_PIPELINE_STATUS]($state, data) {
    $state.records.push({
      id: data.id,
      name: data.name,
      conversations: [],
      is_new: false,
    });
  },
  [types.EDIT_PIPELINE_STATUS]($state, data) {
    const index = $state.records.findIndex(record => record.id === data.id);
    if (index !== -1) {
      $state.records[index] = {
        ...$state.records[index],
        name: data.name,
      };
    }
  },
  [types.DELETE_PIPELINE_STATUS]($state, id) {
    $state.records = $state.records.filter(record => record.id !== id);
  },

  [types.SET_PIPELINE_STATUS_LOADING]($state, status) {
    $state.uiFlags.isLoading = status;
  },

  [types.ORGANIZE_CONVERSATIONS_BY_PIPELINE_STATUS]($state, { conversations }) {
    // Group conversations by pipeline_status_id (O(M) instead of O(N*M))
    const groupedConversations = conversations.reduce((acc, conversation) => {
      const statusId = conversation.pipeline_status_id;
      if (statusId) {
        if (!acc[statusId]) acc[statusId] = [];
        acc[statusId].push(conversation);
      }
      return acc;
    }, {});

    // Assign to records ensuring reactivity
    $state.records = $state.records.map(record => ({
      ...record,
      conversations: groupedConversations[record.id] || [],
    }));
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
