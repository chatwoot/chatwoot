import * as MutationTypes from 'dashboard/store/mutation-types';

const state = {
  salesPipeline: null,
  stages: [],
  kanbanData: [],
  uiFlags: {
    isFetching: false,
    isUpdating: false,
    isCreating: false,
    isDeleting: false,
  },
};

const getters = {
  getSalesPipeline: $state => $state.salesPipeline,
  getStages: $state => $state.stages,
  getKanbanData: $state => $state.kanbanData,
  getUIFlags: $state => $state.uiFlags,
  getDefaultStage: $state => $state.stages.find(stage => stage.is_default),
  getStageById: $state => stageId => $state.stages.find(stage => stage.id === stageId),
};

const actions = {
  async fetchSalesPipeline({ commit }, { accountId }) {
    commit(MutationTypes.SET_SALES_PIPELINE_UI_FLAG, { isFetching: true });
    try {
      const response = await axios.get(
        `/api/v1/accounts/${accountId}/sales_pipelines`
      );
      commit(MutationTypes.SET_SALES_PIPELINE, response.data);
      commit(MutationTypes.SET_SALES_PIPELINE_STAGES, response.data.stages || []);
      return response.data;
    } catch (error) {
      throw error;
    } finally {
      commit(MutationTypes.SET_SALES_PIPELINE_UI_FLAG, { isFetching: false });
    }
  },

  async fetchKanbanData({ commit }, { accountId, filters = {} }) {
    commit(MutationTypes.SET_SALES_PIPELINE_UI_FLAG, { isFetching: true });
    try {
      const response = await axios.get(
        `/api/v1/accounts/${accountId}/sales_pipelines/kanban`,
        { params: filters }
      );
      commit(MutationTypes.SET_KANBAN_DATA, response.data);
      return response.data;
    } catch (error) {
      throw error;
    } finally {
      commit(MutationTypes.SET_SALES_PIPELINE_UI_FLAG, { isFetching: false });
    }
  },

  async createStage({ commit }, { accountId, stageData }) {
    commit(MutationTypes.SET_SALES_PIPELINE_UI_FLAG, { isCreating: true });
    try {
      const response = await axios.post(
        `/api/v1/accounts/${accountId}/sales_pipeline_stages`,
        { stage: stageData }
      );
      commit(MutationTypes.ADD_SALES_PIPELINE_STAGE, response.data);
      return response.data;
    } catch (error) {
      throw error;
    } finally {
      commit(MutationTypes.SET_SALES_PIPELINE_UI_FLAG, { isCreating: false });
    }
  },

  async updateStage({ commit }, { accountId, stageId, stageData }) {
    commit(MutationTypes.SET_SALES_PIPELINE_UI_FLAG, { isUpdating: true });
    try {
      const response = await axios.put(
        `/api/v1/accounts/${accountId}/sales_pipeline_stages/${stageId}`,
        { stage: stageData }
      );
      commit(MutationTypes.UPDATE_SALES_PIPELINE_STAGE, response.data);
      return response.data;
    } catch (error) {
      throw error;
    } finally {
      commit(MutationTypes.SET_SALES_PIPELINE_UI_FLAG, { isUpdating: false });
    }
  },

  async deleteStage({ commit }, { accountId, stageId, migrationStageId }) {
    commit(MutationTypes.SET_SALES_PIPELINE_UI_FLAG, { isDeleting: true });
    try {
      await axios.delete(
        `/api/v1/accounts/${accountId}/sales_pipeline_stages/${stageId}`,
        { data: { stage: { migration_stage_id: migrationStageId } } }
      );
      commit(MutationTypes.REMOVE_SALES_PIPELINE_STAGE, stageId);
    } catch (error) {
      throw error;
    } finally {
      commit(MutationTypes.SET_SALES_PIPELINE_UI_FLAG, { isDeleting: false });
    }
  },

  async reorderStages({ commit }, { accountId, stages }) {
    commit(MutationTypes.SET_SALES_PIPELINE_UI_FLAG, { isUpdating: true });
    try {
      await axios.put(
        `/api/v1/accounts/${accountId}/sales_pipeline_stages/reorder`,
        { stages }
      );
      commit(MutationTypes.REORDER_SALES_PIPELINE_STAGES, stages);
    } catch (error) {
      throw error;
    } finally {
      commit(MutationTypes.SET_SALES_PIPELINE_UI_FLAG, { isUpdating: false });
    }
  },

  async updateConversationStage({ commit }, { accountId, conversationId, stageId }) {
    try {
      const response = await axios.put(
        `/api/v1/accounts/${accountId}/conversations/${conversationId}/sales_stage`,
        { sales_stage: { stage_id: stageId } }
      );
      return response.data;
    } catch (error) {
      throw error;
    }
  },

  async removeConversationStage({ commit }, { accountId, conversationId }) {
    try {
      await axios.delete(
        `/api/v1/accounts/${accountId}/conversations/${conversationId}/sales_stage`
      );
    } catch (error) {
      throw error;
    }
  },
};

const mutations = {
  [MutationTypes.SET_SALES_PIPELINE_UI_FLAG]($state, uiFlag) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...uiFlag,
    };
  },

  [MutationTypes.SET_SALES_PIPELINE]($state, data) {
    $state.salesPipeline = data;
  },

  [MutationTypes.SET_SALES_PIPELINE_STAGES]($state, stages) {
    $state.stages = stages.sort((a, b) => a.position - b.position);
  },

  [MutationTypes.SET_KANBAN_DATA]($state, data) {
    $state.kanbanData = data;
  },

  [MutationTypes.ADD_SALES_PIPELINE_STAGE]($state, stage) {
    $state.stages.push(stage);
    $state.stages.sort((a, b) => a.position - b.position);
  },

  [MutationTypes.UPDATE_SALES_PIPELINE_STAGE]($state, updatedStage) {
    const index = $state.stages.findIndex(stage => stage.id === updatedStage.id);
    if (index !== -1) {
      $state.stages.splice(index, 1, updatedStage);
    }
  },

  [MutationTypes.REMOVE_SALES_PIPELINE_STAGE]($state, stageId) {
    $state.stages = $state.stages.filter(stage => stage.id !== stageId);
  },

  [MutationTypes.REORDER_SALES_PIPELINE_STAGES]($state, stages) {
    stages.forEach(({ id, position }) => {
      const stage = $state.stages.find(s => s.id === id);
      if (stage) {
        stage.position = position;
      }
    });
    $state.stages.sort((a, b) => a.position - b.position);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};