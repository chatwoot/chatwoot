import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import WhatsappInteractiveTemplatesAPI from '../../api/whatsappInteractiveTemplates';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isDeleting: false,
    isDispatching: false,
  },
};

export const getters = {
  getTemplates(_state) {
    return _state.records;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

export const actions = {
  get: async function getTemplates({ commit }) {
    commit(types.SET_WHATSAPP_INTERACTIVE_TEMPLATE_UI_FLAG, {
      isFetching: true,
    });
    try {
      const response = await WhatsappInteractiveTemplatesAPI.get();
      commit(types.SET_WHATSAPP_INTERACTIVE_TEMPLATES, response.data);
    } finally {
      commit(types.SET_WHATSAPP_INTERACTIVE_TEMPLATE_UI_FLAG, {
        isFetching: false,
      });
    }
  },

  create: async function createTemplate({ commit }, templateObj) {
    commit(types.SET_WHATSAPP_INTERACTIVE_TEMPLATE_UI_FLAG, {
      isCreating: true,
    });
    try {
      const response =
        await WhatsappInteractiveTemplatesAPI.create(templateObj);
      commit(types.ADD_WHATSAPP_INTERACTIVE_TEMPLATE, response.data);
      return response.data;
    } finally {
      commit(types.SET_WHATSAPP_INTERACTIVE_TEMPLATE_UI_FLAG, {
        isCreating: false,
      });
    }
  },

  delete: async function deleteTemplate({ commit }, id) {
    commit(types.SET_WHATSAPP_INTERACTIVE_TEMPLATE_UI_FLAG, {
      isDeleting: true,
    });
    try {
      await WhatsappInteractiveTemplatesAPI.delete(id);
      commit(types.DELETE_WHATSAPP_INTERACTIVE_TEMPLATE, id);
    } finally {
      commit(types.SET_WHATSAPP_INTERACTIVE_TEMPLATE_UI_FLAG, {
        isDeleting: false,
      });
    }
  },

  dispatch: async function dispatchTemplate(
    { commit },
    { templateId, conversationId, runtimeUrl, runtimeBodyText }
  ) {
    commit(types.SET_WHATSAPP_INTERACTIVE_TEMPLATE_UI_FLAG, {
      isDispatching: true,
    });
    try {
      const extraParams = {};
      if (runtimeUrl) extraParams.runtime_url = runtimeUrl;
      if (runtimeBodyText) extraParams.runtime_body_text = runtimeBodyText;
      const response =
        await WhatsappInteractiveTemplatesAPI.dispatchToConversation(
          templateId,
          conversationId,
          extraParams
        );
      return response.data;
    } finally {
      commit(types.SET_WHATSAPP_INTERACTIVE_TEMPLATE_UI_FLAG, {
        isDispatching: false,
      });
    }
  },
};

export const mutations = {
  [types.SET_WHATSAPP_INTERACTIVE_TEMPLATE_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },
  [types.SET_WHATSAPP_INTERACTIVE_TEMPLATES]: MutationHelpers.set,
  [types.ADD_WHATSAPP_INTERACTIVE_TEMPLATE]: MutationHelpers.create,
  [types.DELETE_WHATSAPP_INTERACTIVE_TEMPLATE]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
