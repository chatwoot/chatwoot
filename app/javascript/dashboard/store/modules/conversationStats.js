import Vue from 'vue';
import * as types from '../mutation-types';

const state = {
  mineCount: 0,
  unAssignedCount: 0,
  allCount: 0,
};

export const getters = {
  getStats: $state => $state,
};

export const actions = {
  set(
    { commit },
    {
      mine_count: mineCount,
      unassigned_count: unAssignedCount,
      all_count: allCount,
    } = {}
  ) {
    commit(types.default.SET_CONV_TAB_META, {
      mineCount,
      unAssignedCount,
      allCount,
    });
  },
};

export const mutations = {
  [types.default.SET_CONV_TAB_META](
    $state,
    { mineCount, unAssignedCount, allCount } = {}
  ) {
    Vue.set($state, 'mineCount', mineCount);
    Vue.set($state, 'allCount', allCount);
    Vue.set($state, 'unAssignedCount', unAssignedCount);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
