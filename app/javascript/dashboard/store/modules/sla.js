import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import SlaAPI from '../../api/sla';
import AnalyticsHelper from '../../helper/AnalyticsHelper';
import { SLA_EVENTS } from '../../helper/AnalyticsHelper/events';
import { throwErrorMessage } from '../utils/api';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isFetchingItem: false,
    isCreating: false,
    isDeleting: false,
  },
};

export const getters = {
  getSLA(_state) {
    return _state.records;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

export const actions = {
  get: async function get({ commit }) {
    commit(types.SET_SLA_UI_FLAG, { isFetching: true });
    try {
      const response = await SlaAPI.get();
      commit(types.SET_SLA, response.data.payload);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_SLA_UI_FLAG, { isFetching: false });
    }
  },

  create: async function create({ commit }, slaObj) {
    commit(types.SET_SLA_UI_FLAG, { isCreating: true });
    try {
      const response = await SlaAPI.create(slaObj);
      AnalyticsHelper.track(SLA_EVENTS.CREATE);
      commit(types.ADD_SLA, response.data.payload);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_SLA_UI_FLAG, { isCreating: false });
    }
  },

  delete: async function deleteSla({ commit }, id) {
    commit(types.SET_SLA_UI_FLAG, { isDeleting: true });
    try {
      await SlaAPI.delete(id);
      AnalyticsHelper.track(SLA_EVENTS.DELETED);
      commit(types.DELETE_SLA, id);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_SLA_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_SLA_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_SLA]: MutationHelpers.set,
  [types.ADD_SLA]: MutationHelpers.create,
  [types.DELETE_SLA]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
