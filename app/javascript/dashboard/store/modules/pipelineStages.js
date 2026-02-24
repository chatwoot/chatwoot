import types from '../mutation-types';
import PipelineStagesAPI from '../../api/pipelineStages';

const state = {
  records: {},
  contactStages: {},
  uiFlags: {
    isFetching: false,
    isUpdating: false,
  },
};

export const getters = {
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getStages: $state => labelId => {
    return $state.records[Number(labelId)] || [];
  },
  getContactStages: $state => contactId => {
    return $state.contactStages[Number(contactId)] || [];
  },
};

export const actions = {
  fetchStages: async ({ commit }, labelId) => {
    commit(types.SET_PIPELINE_STAGES_UI_FLAG, { isFetching: true });
    try {
      const response = await PipelineStagesAPI.getStages(labelId);
      commit(types.SET_PIPELINE_STAGES, {
        labelId,
        data: response.data.payload,
      });
    } catch (error) {
      // noop
    } finally {
      commit(types.SET_PIPELINE_STAGES_UI_FLAG, { isFetching: false });
    }
  },

  createStage: async ({ commit }, { labelId, ...stageData }) => {
    commit(types.SET_PIPELINE_STAGES_UI_FLAG, { isUpdating: true });
    try {
      await PipelineStagesAPI.createStage(labelId, stageData);
      const response = await PipelineStagesAPI.getStages(labelId);
      commit(types.SET_PIPELINE_STAGES, {
        labelId,
        data: response.data.payload,
      });
    } finally {
      commit(types.SET_PIPELINE_STAGES_UI_FLAG, { isUpdating: false });
    }
  },

  updateStage: async ({ commit }, { labelId, stageId, ...stageData }) => {
    commit(types.SET_PIPELINE_STAGES_UI_FLAG, { isUpdating: true });
    try {
      await PipelineStagesAPI.updateStage(labelId, stageId, stageData);
      const response = await PipelineStagesAPI.getStages(labelId);
      commit(types.SET_PIPELINE_STAGES, {
        labelId,
        data: response.data.payload,
      });
    } finally {
      commit(types.SET_PIPELINE_STAGES_UI_FLAG, { isUpdating: false });
    }
  },

  deleteStage: async ({ commit }, { labelId, stageId }) => {
    commit(types.SET_PIPELINE_STAGES_UI_FLAG, { isUpdating: true });
    try {
      await PipelineStagesAPI.deleteStage(labelId, stageId);
      const response = await PipelineStagesAPI.getStages(labelId);
      commit(types.SET_PIPELINE_STAGES, {
        labelId,
        data: response.data.payload,
      });
    } finally {
      commit(types.SET_PIPELINE_STAGES_UI_FLAG, { isUpdating: false });
    }
  },

  reorderStages: async ({ commit }, { labelId, positions }) => {
    commit(types.SET_PIPELINE_STAGES_UI_FLAG, { isUpdating: true });
    try {
      await PipelineStagesAPI.reorderStages(labelId, positions);
      const response = await PipelineStagesAPI.getStages(labelId);
      commit(types.SET_PIPELINE_STAGES, {
        labelId,
        data: response.data.payload,
      });
    } finally {
      commit(types.SET_PIPELINE_STAGES_UI_FLAG, { isUpdating: false });
    }
  },

  fetchContactStages: async ({ commit }, contactId) => {
    commit(types.SET_PIPELINE_STAGES_UI_FLAG, { isFetching: true });
    try {
      const response = await PipelineStagesAPI.getContactStages(contactId);
      commit(types.SET_CONTACT_PIPELINE_STAGES, {
        contactId,
        data: response.data.payload,
      });
    } catch (error) {
      // noop
    } finally {
      commit(types.SET_PIPELINE_STAGES_UI_FLAG, { isFetching: false });
    }
  },

  updateContactStage: async (
    { commit },
    { contactId, assignmentId, pipelineStageId }
  ) => {
    commit(types.SET_PIPELINE_STAGES_UI_FLAG, { isUpdating: true });
    try {
      const response = await PipelineStagesAPI.updateContactStage(
        contactId,
        assignmentId,
        pipelineStageId
      );
      commit(types.SET_CONTACT_PIPELINE_STAGES, {
        contactId,
        data: response.data.payload,
      });
    } finally {
      commit(types.SET_PIPELINE_STAGES_UI_FLAG, { isUpdating: false });
    }
  },
};

export const mutations = {
  [types.SET_PIPELINE_STAGES_UI_FLAG]($state, data) {
    $state.uiFlags = { ...$state.uiFlags, ...data };
  },
  [types.SET_PIPELINE_STAGES]($state, { labelId, data }) {
    $state.records = { ...$state.records, [labelId]: data };
  },
  [types.SET_CONTACT_PIPELINE_STAGES]($state, { contactId, data }) {
    $state.contactStages = { ...$state.contactStages, [contactId]: data };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
