import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import FlowsAPI from '../../api/flows';
import { throwErrorMessage } from '../utils/api';

const SET_UI = 'SET_FLOWS_UI_FLAG';
const SET = 'SET_FLOWS';
const ADD = 'ADD_FLOW';
const EDIT = 'EDIT_FLOW';
const DELETE = 'DELETE_FLOW';

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
  getFlows($state) {
    return $state.records;
  },
  getFlow: $state => id =>
    $state.records.find(record => record.id === Number(id)),
  getUIFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  get: async ({ commit }) => {
    commit(SET_UI, { isFetching: true });
    try {
      const response = await FlowsAPI.get();
      commit(SET, response.data.payload);
    } catch (error) {
      // ignore
    } finally {
      commit(SET_UI, { isFetching: false });
    }
  },
  show: async ({ commit }, id) => {
    const response = await FlowsAPI.show(id);
    commit(ADD, response.data.payload);
    return response.data.payload;
  },
  create: async ({ commit }, flowObj) => {
    commit(SET_UI, { isCreating: true });
    try {
      const response = await FlowsAPI.create(flowObj);
      commit(ADD, response.data.payload);
      return response.data.payload;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit(SET_UI, { isCreating: false });
    }
  },
  update: async ({ commit }, { id, ...updateObj }) => {
    commit(SET_UI, { isUpdating: true });
    try {
      const response = await FlowsAPI.update(id, updateObj);
      commit(EDIT, response.data.payload);
      return response.data.payload;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit(SET_UI, { isUpdating: false });
    }
  },
  delete: async ({ commit }, id) => {
    commit(SET_UI, { isDeleting: true });
    try {
      await FlowsAPI.delete(id);
      commit(DELETE, id);
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit(SET_UI, { isDeleting: false });
    }
  },
};

export const mutations = {
  [SET_UI]($state, data) {
    $state.uiFlags = { ...$state.uiFlags, ...data };
  },
  [SET]: MutationHelpers.set,
  [ADD]: MutationHelpers.create,
  [EDIT]: MutationHelpers.update,
  [DELETE]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
