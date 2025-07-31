import assignmentPoliciesAPI from '../../../api/assignmentPolicies';

export const actions = {
  get: async ({ commit }) => {
    commit('setUIFlag', { isFetching: true });
    try {
      const response = await assignmentPoliciesAPI.get();
      const policies = response.data.assignment_policies || response.data;
      commit('setAssignmentPolicies', policies);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isFetching: false });
    }
  },

  show: async ({ commit }, id) => {
    try {
      const response = await assignmentPoliciesAPI.show(id);
      const policy = response.data.assignment_policy || response.data;
      commit('setAssignmentPolicy', policy);
      return policy;
    } catch (error) {
      throw new Error(error);
    }
  },

  create: async ({ commit }, data) => {
    commit('setUIFlag', { isCreating: true });
    try {
      const response = await assignmentPoliciesAPI.create(data);
      const policy = response.data.assignment_policy || response.data;
      commit('setAssignmentPolicy', policy);
      return policy;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isCreating: false });
    }
  },

  update: async ({ commit }, { id, ...data }) => {
    commit('setUIFlag', { isUpdating: true });
    try {
      const response = await assignmentPoliciesAPI.update(id, data);
      const policy = response.data.assignment_policy || response.data;
      commit('setAssignmentPolicy', policy);
      return policy;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isUpdating: false });
    }
  },

  delete: async ({ commit }, id) => {
    commit('setUIFlag', { isDeleting: true });
    try {
      await assignmentPoliciesAPI.delete(id);
      commit('deleteAssignmentPolicy', id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isDeleting: false });
    }
  },
};
