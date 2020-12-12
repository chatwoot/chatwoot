import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import * as types from '../mutation-types';
import WorkflowAccountTemplatesAPI from '../../api/workflowAccountTemplates';

const state = {
  records: [],
  uiFlags: {
    fetchingList: false,
    fetchingItem: false,
    creatingItem: false,
    updatingItem: false,
    deletingItem: false,
  },
};

const getters = {
  getAccountWorkflowTemplates(_state) {
    return _state.records;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

const actions = {
  getAccountWorkflowTemplates: async function getAccountWorkflowTemplates({commit}) {
    commit(types.default.SET_WORKFLOW_ACCOUNT_TEMPLATES_UI_FLAG, { fetchingList: true });
    try {
      const response = await WorkflowAccountTemplatesAPI.get();
      commit(types.default.SET_WORKFLOW_ACCOUNT_TEMPLATES, response.data.payload);
      commit(types.default.SET_WORKFLOW_ACCOUNT_TEMPLATES_UI_FLAG, { fetchingList: false });
    } catch (error) {
      commit(types.default.SET_WORKFLOW_ACCOUNT_TEMPLATES_UI_FLAG, { fetchingList: false });
    }
  },
};

const mutations = {
  [types.default.SET_WORKFLOW_ACCOUNT_TEMPLATES_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.default.SET_WORKFLOW_ACCOUNT_TEMPLATES]: MutationHelpers.set,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
