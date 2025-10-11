import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import TemplatesAPI from '../../api/templates';

export const state = {
  records: [],
  selectedTemplate: null, // For handling template selection across components
  uiFlags: {
    isFetching: false,
    isFetchingItem: false,
    isCreating: false,
    isDeleting: false,
  },
};

export const getters = {
  getTemplates(_state) {
    return _state.records;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getTemplate: _state => id => {
    return _state.records.find(record => record.id === Number(id));
  },
  getSelectedTemplate(_state) {
    return _state.selectedTemplate;
  },
};

export const actions = {
  get: async function getTemplates(
    { commit },
    { search = '', channel = '' } = {}
  ) {
    commit(types.SET_TEMPLATE_UI_FLAG, { isFetching: true });
    try {
      const response = await TemplatesAPI.get({ search, channel });
      // Extract templates array from paginated response
      const templates = response.data.templates || response.data;
      commit(types.SET_TEMPLATES, templates);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_TEMPLATE_UI_FLAG, { isFetching: false });
    }
  },
  show: async function showTemplate({ commit }, { id }) {
    commit(types.SET_TEMPLATE_UI_FLAG, { isFetchingItem: true });
    try {
      const response = await TemplatesAPI.show(id);
      commit(types.ADD_TEMPLATE, response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_TEMPLATE_UI_FLAG, { isFetchingItem: false });
    }
  },
  create: async function createTemplate({ commit }, templateObj) {
    commit(types.SET_TEMPLATE_UI_FLAG, { isCreating: true });
    try {
      const response = await TemplatesAPI.create(templateObj);
      commit(types.ADD_TEMPLATE, response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_TEMPLATE_UI_FLAG, { isCreating: false });
    }
  },
  update: async function updateTemplate({ commit }, { id, ...templateObj }) {
    commit(types.SET_TEMPLATE_UI_FLAG, { isUpdating: true });
    try {
      const response = await TemplatesAPI.update(id, templateObj);
      commit(types.EDIT_TEMPLATE, response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_TEMPLATE_UI_FLAG, { isUpdating: false });
    }
  },
  delete: async function deleteTemplate({ commit }, id) {
    commit(types.SET_TEMPLATE_UI_FLAG, { isDeleting: true });
    try {
      await TemplatesAPI.delete(id);
      commit(types.DELETE_TEMPLATE, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_TEMPLATE_UI_FLAG, { isDeleting: false });
    }
  },
  render: async function renderTemplate(
    { commit },
    { templateId, parameters, channelType }
  ) {
    commit(types.SET_TEMPLATE_UI_FLAG, { isRendering: true });
    try {
      const response = await TemplatesAPI.render(
        templateId,
        parameters,
        channelType
      );
      return response;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_TEMPLATE_UI_FLAG, { isRendering: false });
    }
  },
  createFromAppleMessage: async function createFromAppleMessage(
    { commit },
    payload
  ) {
    commit(types.SET_TEMPLATE_UI_FLAG, { isCreating: true });
    try {
      const response = await TemplatesAPI.createFromAppleMessage(payload);
      commit(types.ADD_TEMPLATE, response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_TEMPLATE_UI_FLAG, { isCreating: false });
    }
  },
  templateSelected: function selectTemplate({ commit }, item) {
    commit(types.SET_SELECTED_TEMPLATE, item);
  },
};

export const mutations = {
  [types.SET_TEMPLATE_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },
  [types.SET_TEMPLATES]: MutationHelpers.set,
  [types.ADD_TEMPLATE]: MutationHelpers.create,
  [types.EDIT_TEMPLATE]: MutationHelpers.update,
  [types.DELETE_TEMPLATE]: MutationHelpers.destroy,
  [types.SET_SELECTED_TEMPLATE](_state, item) {
    _state.selectedTemplate = item;
  },
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
