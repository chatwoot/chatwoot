import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import AgentCapacityPoliciesAPI from '../../api/agentCapacityPolicies';
import { throwErrorMessage } from '../utils/api';
import camelcaseKeys from 'camelcase-keys';
import snakecaseKeys from 'snakecase-keys';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isFetchingItem: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
  usersUiFlags: {
    isFetching: false,
    isDeleting: false,
  },
};

export const getters = {
  getAgentCapacityPolicies(_state) {
    return _state.records;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getUsersUIFlags(_state) {
    return _state.usersUiFlags;
  },
  getAgentCapacityPolicyById: _state => id => {
    return _state.records.find(record => record.id === Number(id)) || {};
  },
};

export const actions = {
  get: async function get({ commit }) {
    commit(types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isFetching: true });
    try {
      const response = await AgentCapacityPoliciesAPI.get();
      commit(types.SET_AGENT_CAPACITY_POLICIES, camelcaseKeys(response.data));
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isFetching: false });
    }
  },

  show: async function show({ commit }, policyId) {
    commit(types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isFetchingItem: true });
    try {
      const response = await AgentCapacityPoliciesAPI.show(policyId);
      const policy = camelcaseKeys(response.data);
      commit(types.SET_AGENT_CAPACITY_POLICY, policy);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, {
        isFetchingItem: false,
      });
    }
  },

  create: async function create({ commit }, policyObj) {
    commit(types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isCreating: true });
    try {
      const response = await AgentCapacityPoliciesAPI.create(
        snakecaseKeys(policyObj)
      );
      commit(types.ADD_AGENT_CAPACITY_POLICY, camelcaseKeys(response.data));
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit(types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isCreating: false });
    }
  },

  update: async function update({ commit }, { id, ...policyParams }) {
    commit(types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isUpdating: true });
    try {
      const response = await AgentCapacityPoliciesAPI.update(
        id,
        snakecaseKeys(policyParams)
      );
      commit(types.EDIT_AGENT_CAPACITY_POLICY, camelcaseKeys(response.data));
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit(types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async function deletePolicy({ commit }, policyId) {
    commit(types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isDeleting: true });
    try {
      await AgentCapacityPoliciesAPI.delete(policyId);
      commit(types.DELETE_AGENT_CAPACITY_POLICY, policyId);
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit(types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG, { isDeleting: false });
    }
  },

  getUsers: async function getUsers({ commit }, policyId) {
    commit(types.SET_AGENT_CAPACITY_POLICIES_USERS_UI_FLAG, {
      isFetching: true,
    });
    try {
      const response = await AgentCapacityPoliciesAPI.getUsers(policyId);
      commit(types.SET_AGENT_CAPACITY_POLICIES_USERS, {
        policyId,
        users: camelcaseKeys(response.data),
      });
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit(types.SET_AGENT_CAPACITY_POLICIES_USERS_UI_FLAG, {
        isFetching: false,
      });
    }
  },
};

export const mutations = {
  [types.SET_AGENT_CAPACITY_POLICIES_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_AGENT_CAPACITY_POLICIES]: MutationHelpers.set,
  [types.SET_AGENT_CAPACITY_POLICY]: MutationHelpers.setSingleRecord,
  [types.ADD_AGENT_CAPACITY_POLICY]: MutationHelpers.create,
  [types.EDIT_AGENT_CAPACITY_POLICY]: MutationHelpers.updateAttributes,
  [types.DELETE_AGENT_CAPACITY_POLICY]: MutationHelpers.destroy,

  [types.SET_AGENT_CAPACITY_POLICIES_USERS_UI_FLAG](_state, data) {
    _state.usersUiFlags = {
      ..._state.usersUiFlags,
      ...data,
    };
  },
  [types.SET_AGENT_CAPACITY_POLICIES_USERS](_state, { policyId, users }) {
    const policy = _state.records.find(p => p.id === policyId);
    if (policy) {
      policy.users = users;
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
