import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import AssignmentPoliciesAPI from '../../api/assignmentPolicies';
import { throwErrorMessage } from '../utils/api';
import camelcaseKeys from 'camelcase-keys';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isFetchingItem: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
  inboxUiFlags: {
    isFetching: false,
  },
};

export const getters = {
  getAssignmentPolicies(_state) {
    return _state.records;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getInboxUiFlags(_state) {
    return _state.inboxUiFlags;
  },
  getAssignmentPolicyById: _state => id => {
    return _state.records.find(record => record.id === Number(id)) || {};
  },
  getAssignmentPoliciesByOrder: _state => order => {
    return _state.records.filter(record => record.assignment_order === order);
  },
};

export const actions = {
  get: async function get({ commit }) {
    commit(types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isFetching: true });
    try {
      const response = await AssignmentPoliciesAPI.get();
      commit(types.SET_ASSIGNMENT_POLICIES, camelcaseKeys(response.data));
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isFetching: false });
    }
  },

  show: async function show({ commit }, policyId) {
    commit(types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isFetchingItem: true });
    try {
      const response = await AssignmentPoliciesAPI.show(policyId);
      const policy = camelcaseKeys(response.data);
      commit(types.EDIT_ASSIGNMENT_POLICY, policy);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isFetchingItem: false });
    }
  },

  create: async function create({ commit }, policyObj) {
    commit(types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isCreating: true });
    try {
      const response = await AssignmentPoliciesAPI.create(policyObj);
      commit(types.ADD_ASSIGNMENT_POLICY, camelcaseKeys(response.data));
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit(types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isCreating: false });
    }
  },

  update: async function update({ commit }, { id, ...policyParams }) {
    commit(types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isUpdating: true });
    try {
      const response = await AssignmentPoliciesAPI.update(id, policyParams);
      commit(types.EDIT_ASSIGNMENT_POLICY, camelcaseKeys(response.data));
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit(types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async function deletePolicy({ commit }, policyId) {
    commit(types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isDeleting: true });
    try {
      await AssignmentPoliciesAPI.delete(policyId);
      commit(types.DELETE_ASSIGNMENT_POLICY, policyId);
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit(types.SET_ASSIGNMENT_POLICIES_UI_FLAG, { isDeleting: false });
    }
  },

  getInboxes: async function getInboxes({ commit }, policyId) {
    commit(types.SET_ASSIGNMENT_POLICIES_INBOXES_UI_FLAG, { isFetching: true });
    try {
      const response = await AssignmentPoliciesAPI.getInboxes(policyId);
      commit(types.SET_ASSIGNMENT_POLICIES_INBOXES, {
        policyId,
        inboxes: camelcaseKeys(response.data.inboxes),
      });
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit(types.SET_ASSIGNMENT_POLICIES_INBOXES_UI_FLAG, {
        isFetching: false,
      });
    }
  },

  // TODO: Check when working on this
  setInboxPolicy: async function setInboxPolicy({ inboxId, policyId }) {
    try {
      const response = await AssignmentPoliciesAPI.setInboxPolicy(
        inboxId,
        policyId
      );
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    }
  },

  getInboxPolicy: async function getInboxPolicy(inboxId) {
    try {
      const response = await AssignmentPoliciesAPI.getInboxPolicy(inboxId);
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    }
  },

  removeInboxPolicy: async function removeInboxPolicy(inboxId) {
    try {
      await AssignmentPoliciesAPI.removeInboxPolicy(inboxId);
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    }
  },
};

export const mutations = {
  [types.SET_ASSIGNMENT_POLICIES_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_ASSIGNMENT_POLICIES]: MutationHelpers.set,
  [types.ADD_ASSIGNMENT_POLICY]: MutationHelpers.create,
  [types.EDIT_ASSIGNMENT_POLICY]: MutationHelpers.update,
  [types.DELETE_ASSIGNMENT_POLICY]: MutationHelpers.destroy,

  [types.SET_ASSIGNMENT_POLICIES_INBOXES_UI_FLAG](_state, data) {
    _state.inboxUiFlags = {
      ..._state.inboxUiFlags,
      ...data,
    };
  },

  [types.SET_ASSIGNMENT_POLICIES_INBOXES](_state, { policyId, inboxes }) {
    const policy = _state.records.find(p => p.id === policyId);
    if (policy) {
      policy.inboxes = inboxes;
    }
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
