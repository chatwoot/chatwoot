import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import MessageTemplatesAPI from '../../api/messageTemplates';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
  builderConfig: {
    name: '',
    language: 'en',
    channelType: 'Channel::Whatsapp',
    inboxId: null,
    category: 'utility',
    templateId: null, // for edit mode
  },
};

export const getters = {
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getTemplates(_state) {
    return _state.records.sort((a, b) => b.id - a.id);
  },
  getTemplatesByInbox: _state => inboxId => {
    return _state.records.filter(template => template.inbox_id === inboxId);
  },
  getTemplatesByStatus: _state => status => {
    return _state.records.filter(template => template.status === status);
  },
  getApprovedTemplates(_state) {
    return _state.records.filter(template => template.status === 'approved');
  },
  getTemplate: _state => id => {
    return _state.records.find(template => template.id === Number(id));
  },
  getBuilderConfig(_state) {
    return _state.builderConfig;
  },
};

export const actions = {
  get: async function getMessageTemplates({ commit }, filters = {}) {
    commit(types.SET_MESSAGE_TEMPLATE_UI_FLAG, { isFetching: true });
    try {
      const response = await MessageTemplatesAPI.getFiltered(filters);
      commit(types.SET_MESSAGE_TEMPLATES, response.data);
    } finally {
      commit(types.SET_MESSAGE_TEMPLATE_UI_FLAG, { isFetching: false });
    }
  },

  create: async function createMessageTemplate({ commit }, templateData) {
    commit(types.SET_MESSAGE_TEMPLATE_UI_FLAG, { isCreating: true });
    try {
      const response = await MessageTemplatesAPI.create({
        message_template: templateData,
      });
      commit(types.ADD_MESSAGE_TEMPLATE, response.data);
      return response.data;
    } finally {
      commit(types.SET_MESSAGE_TEMPLATE_UI_FLAG, { isCreating: false });
    }
  },

  // update: async function updateMessageTemplate(
  //   { commit },
  //   { id, ...templateData }
  // ) {
  //   commit(types.SET_MESSAGE_TEMPLATE_UI_FLAG, { isUpdating: true });
  //   try {
  //     const response = await MessageTemplatesAPI.update(id, {
  //       message_template: templateData,
  //     });
  //     commit(types.EDIT_MESSAGE_TEMPLATE, response.data);
  //     return response.data;
  //   } finally {
  //     commit(types.SET_MESSAGE_TEMPLATE_UI_FLAG, { isUpdating: false });
  //   }
  // },

  delete: async function deleteMessageTemplate({ commit }, templateId) {
    commit(types.SET_MESSAGE_TEMPLATE_UI_FLAG, { isDeleting: true });
    try {
      await MessageTemplatesAPI.delete(templateId);
      commit(types.DELETE_MESSAGE_TEMPLATE, templateId);
    } finally {
      commit(types.SET_MESSAGE_TEMPLATE_UI_FLAG, { isDeleting: false });
    }
  },

  show: async function showMessageTemplate(_, templateId) {
    const response = await MessageTemplatesAPI.show(templateId);
    return response.data;
  },

  setBuilderConfig: function setBuilderConfig({ commit }, config) {
    commit(types.SET_TEMPLATE_BUILDER_CONFIG, config);
  },

  resetBuilderConfig: function resetBuilderConfig({ commit }) {
    commit(types.RESET_TEMPLATE_BUILDER);
  },
};

export const mutations = {
  [types.SET_MESSAGE_TEMPLATE_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_MESSAGE_TEMPLATES]: MutationHelpers.set,
  [types.ADD_MESSAGE_TEMPLATE]: MutationHelpers.create,
  [types.DELETE_MESSAGE_TEMPLATE]: MutationHelpers.destroy,

  [types.SET_TEMPLATE_BUILDER_CONFIG](_state, config) {
    _state.builderConfig = {
      ..._state.builderConfig,
      ...config,
    };
  },

  [types.RESET_TEMPLATE_BUILDER](_state) {
    _state.builderConfig = {
      name: '',
      language: 'en',
      channelType: 'Channel::Whatsapp',
      inboxId: null,
      category: 'utility',
      templateId: null,
    };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
