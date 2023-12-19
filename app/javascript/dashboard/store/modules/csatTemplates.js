import Vue from 'vue';
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import CsatTemplatesAPI from '../../api/csatTemplates';

export const state = {
  records: [],
  csat_template_enabled: false,
  inboxes_for_select: [],
  current_template_id: 0,
  current_template: {},
  csat_trigger: ''
};

export const getters = {
  records(_state) {
    return _state.records;
  },
  csatTemplateEnabled(_state) {
    return _state.csat_template_enabled;
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
  getCsatTrigger(_state) {
    return _state.csat_trigger;
  }
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
  getStatus: async function getStatus({ commit }) {
    const response = await CsatTemplatesAPI.getStatus();
    commit(types.ENABLE_CSAT_TEMPLATES, response.data.status);
  },
  toggleSetting: async function toggleSetting({ commit }, status) {
    await CsatTemplatesAPI.toggleSetting(status);
    commit(types.ENABLE_CSAT_TEMPLATES, status);
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
  getCsatTrigger: async function getCsatTrigger({ commit }){
    const response = await CsatTemplatesAPI.getCsatTrigger();
    commit('SET_CSAT_TRIGGER', response.data.csat_trigger);
  },
  updateCsatTrigger: async function updateCsatTrigger({ _ }, csat_trigger){
    await CsatTemplatesAPI.updateCsatTrigger(csat_trigger);
  }
};

export const mutations = {
  [types.ENABLE_CSAT_TEMPLATES]($state, status) {
    Vue.set($state, 'csat_template_enabled', status);
  },
  ['SET_CSAT_TRIGGER']($state, csat_trigger) {
    Vue.set($state, 'csat_trigger', csat_trigger);
  },
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
