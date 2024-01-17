import Vue from 'vue';
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import CsatTemplatesAPI from '../../api/csatTemplates';

export const state = {
  records: [],
  inboxes_for_select: [],
  current_template_id: 0,
  current_template: {},
};

export const getters = {
  records(_state) {
    return _state.records;
  },
  inboxesForSelect(_state) {
    return _state.inboxes_for_select;
  },
  getCurrentTemplateId(_state) {
    return _state.current_template_id;
  },
  getCurrentTemplate(_state) {
    return _state.current_template;
  },
};

export const actions = {
  get: async function get({ commit }) {
    const response = await CsatTemplatesAPI.get({ page: 1 });
    commit(types.SET_CSAT_TEMPLATES, response.data.payload);
  },
  create: async function create({ commit }, params) {
    try {
      const response = await CsatTemplatesAPI.create(params);
      commit(types.CREATE_CSAT_TEMPLATE, response.data);
      return response.data;
    } catch (error) {
      return error;
    }
  },
  update: async function update({ commit, dispatch }, { id, ...params }) {
    try {
      const response = await CsatTemplatesAPI.update(id, params);
      commit(types.UPDATE_CSAT_TEMPLATE, response.data);
      dispatch('get');
      return response.data;
    } catch (error) {
      return error;
    }
  },
  getInboxes: async function getInboxes({ commit }) {
    const response = await CsatTemplatesAPI.getInboxes();
    commit(types.SET_CSAT_INBOXES, response.data.inboxes);
  },
  getCsatTemplate: async function getCsatTemplate({ commit }, id) {
    const response = await CsatTemplatesAPI.getTemplate(id);
    commit(types.SET_CURRENT_TEMPLATE_ID, id);
    commit(types.SET_CSAT_TEMPLATE, response.data.csat_template);
  },
  delete: async function deleteTemplate({ commit }, id) {
    const response = await CsatTemplatesAPI.delete(id);
    if (response.data.success) {
      commit(types.DELETE_CSAT_TEMPLATE, id);
    }
  },
};

export const mutations = {
  [types.SET_CSAT_INBOXES]($state, inboxes) {
    Vue.set($state, 'inboxes_for_select', inboxes);
  },
  [types.SET_CURRENT_TEMPLATE_ID]($state, id) {
    Vue.set($state, 'current_template_id', id);
  },
  [types.SET_CSAT_TEMPLATE]($state, template) {
    Vue.set($state, 'current_template', template);
  },

  [types.SET_CSAT_TEMPLATES]: MutationHelpers.set,
  [types.CREATE_CSAT_TEMPLATE]: MutationHelpers.create,
  [types.UPDATE_CSAT_TEMPLATE]: MutationHelpers.update,
  [types.DELETE_CSAT_TEMPLATE]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
