import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import SchedulersAPI from '../../api/schedulers';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

export const getters = {
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getSchedulers(_state) {
    return _state.records.sort((a, b) => a.id - b.id);
  },
  getSchedulerById: _state => id => {
    return _state.records.find(record => record.id === id);
  },
};

export const actions = {
  get: async function getSchedulers({ commit }) {
    commit(types.SET_SCHEDULER_UI_FLAG, { isFetching: true });
    try {
      const response = await SchedulersAPI.get();
      commit(types.SET_SCHEDULERS, response.data);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_SCHEDULER_UI_FLAG, { isFetching: false });
    }
  },
  create: async function createScheduler({ commit }, schedulerObj) {
    commit(types.SET_SCHEDULER_UI_FLAG, { isCreating: true });
    try {
      const response = await SchedulersAPI.create(schedulerObj);
      commit(types.ADD_SCHEDULER, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_SCHEDULER_UI_FLAG, { isCreating: false });
    }
  },
  update: async ({ commit }, { id, ...updateObj }) => {
    commit(types.SET_SCHEDULER_UI_FLAG, { isUpdating: true });
    try {
      const response = await SchedulersAPI.update(id, updateObj);
      commit(types.EDIT_SCHEDULER, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_SCHEDULER_UI_FLAG, { isUpdating: false });
    }
  },
  delete: async ({ commit }, id) => {
    commit(types.SET_SCHEDULER_UI_FLAG, { isDeleting: true });
    try {
      await SchedulersAPI.delete(id);
      commit(types.DELETE_SCHEDULER, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_SCHEDULER_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_SCHEDULER_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },
  [types.ADD_SCHEDULER]: MutationHelpers.create,
  [types.SET_SCHEDULERS]: MutationHelpers.set,
  [types.EDIT_SCHEDULER]: MutationHelpers.update,
  [types.DELETE_SCHEDULER]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
