import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import { uploadFile } from 'dashboard/helper/uploadHelper';
import AutomationAPI from '../../api/automation';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isDeleting: false,
    isUpdating: false,
  },
};

export const getters = {
  getAutomations(_state) {
    return _state.records;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

export const actions = {
  get: async function getAutomations({ commit }) {
    commit(types.SET_AUTOMATION_UI_FLAG, { isFetching: true });
    try {
      const response = await AutomationAPI.get();
      commit(types.SET_AUTOMATIONS, response.data.payload);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_AUTOMATION_UI_FLAG, { isFetching: false });
    }
  },
  create: async function createAutomation({ commit }, automationObj) {
    commit(types.SET_AUTOMATION_UI_FLAG, { isCreating: true });
    try {
      const response = await AutomationAPI.create(automationObj);
      commit(types.ADD_AUTOMATION, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_AUTOMATION_UI_FLAG, { isCreating: false });
    }
  },
  update: async ({ commit }, { id, ...updateObj }) => {
    commit(types.SET_AUTOMATION_UI_FLAG, { isUpdating: true });
    try {
      const response = await AutomationAPI.update(id, updateObj);
      commit(types.EDIT_AUTOMATION, response.data.payload);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_AUTOMATION_UI_FLAG, { isUpdating: false });
    }
  },
  delete: async ({ commit }, id) => {
    commit(types.SET_AUTOMATION_UI_FLAG, { isDeleting: true });
    try {
      await AutomationAPI.delete(id);
      commit(types.DELETE_AUTOMATION, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_AUTOMATION_UI_FLAG, { isDeleting: false });
    }
  },
  clone: async ({ commit }, id) => {
    commit(types.SET_AUTOMATION_UI_FLAG, { isCloning: true });
    try {
      await AutomationAPI.clone(id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_AUTOMATION_UI_FLAG, { isCloning: false });
    }
  },
  uploadAttachment: async (_, file) => {
    const { blobId } = await uploadFile(file);
    return blobId;
  },
};

export const mutations = {
  [types.SET_AUTOMATION_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },
  [types.ADD_AUTOMATION]: MutationHelpers.create,
  [types.SET_AUTOMATIONS]: MutationHelpers.set,
  [types.EDIT_AUTOMATION]: MutationHelpers.update,
  [types.DELETE_AUTOMATION]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
