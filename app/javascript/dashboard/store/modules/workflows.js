import * as types from '../mutation-types';
import WorkflowsAPI from '../../api/workflows';

const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

const getters = {
  getWorkflows: $state => $state.records,
  getUIFlags: $state => $state.uiFlags,
};

const actions = {
  get: async ({ commit }) => {
    commit(types.default.SET_WORKFLOW_UI_FLAG, { isFetching: true });
    try {
      const response = await WorkflowsAPI.get();
      commit(types.default.SET_WORKFLOWS, response.data);
    } catch (error) {
      // Ignore
    } finally {
      commit(types.default.SET_WORKFLOW_UI_FLAG, { isFetching: false });
    }
  },
  create: async ({ commit }, data) => {
    commit(types.default.SET_WORKFLOW_UI_FLAG, { isCreating: true });
    try {
      const response = await WorkflowsAPI.create(data);
      commit(types.default.ADD_WORKFLOW, response.data);
      return response.data;
    } finally {
      commit(types.default.SET_WORKFLOW_UI_FLAG, { isCreating: false });
    }
  },
  update: async ({ commit }, { id, ...data }) => {
    commit(types.default.SET_WORKFLOW_UI_FLAG, { isUpdating: true });
    try {
      const response = await WorkflowsAPI.update(id, data);
      commit(types.default.UPDATE_WORKFLOW, response.data);
      return response.data;
    } finally {
      commit(types.default.SET_WORKFLOW_UI_FLAG, { isUpdating: false });
    }
  },
  delete: async ({ commit }, id) => {
    commit(types.default.SET_WORKFLOW_UI_FLAG, { isDeleting: true });
    try {
      await WorkflowsAPI.delete(id);
      commit(types.default.REMOVE_WORKFLOW, id);
    } finally {
      commit(types.default.SET_WORKFLOW_UI_FLAG, { isDeleting: false });
    }
  },
};

const mutations = {
  [types.default.SET_WORKFLOW_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.default.SET_WORKFLOWS]: ($state, data) => {
    $state.records = data;
  },
  [types.default.ADD_WORKFLOW]: ($state, data) => {
    $state.records.push(data);
  },
  [types.default.UPDATE_WORKFLOW]: ($state, data) => {
    const index = $state.records.findIndex(w => w.id === data.id);
    if (index > -1) {
      $state.records.splice(index, 1, data);
    }
  },
  [types.default.REMOVE_WORKFLOW]: ($state, id) => {
    $state.records = $state.records.filter(w => w.id !== id);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
