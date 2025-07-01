import { sendMessage } from 'widget/helpers/utils';
import ContactsAPI from '../../api/contacts';
import { SET_USER_ERROR } from '../../constants/errorTypes';
import { setHeader } from '../../helpers/axios';
const state = {
  currentUser: {},
  botConfig: {},
};

const SET_CURRENT_USER = 'SET_CURRENT_USER';
const SET_BOT_CONFIG = 'SET_BOT_CONFIG';
const parseErrorData = error =>
  error && error.response && error.response.data ? error.response.data : error;
export const updateWidgetAuthToken = widgetAuthToken => {
  if (widgetAuthToken) {
    setHeader(widgetAuthToken);
    sendMessage({
      event: 'setAuthCookie',
      data: { widgetAuthToken },
    });
  }
};

export const getters = {
  getCurrentUser(_state) {
    return _state.currentUser;
  },
  getBotConfig(_state) {
    return _state.botConfig;
  },
};

export const actions = {
  get: async ({ commit }) => {
    try {
      const { data } = await ContactsAPI.get();
      commit(SET_CURRENT_USER, data);
    } catch (error) {
      // Ignore error
    }
  },
  getBotConfig: async ({ commit }) => {
    try {
      const { data } = await ContactsAPI.getBotConfig();
      commit(SET_BOT_CONFIG, data);
    } catch (error) {
      // Ignore error
    }
  },
  updateBotConfig: async ({ dispatch }, { popupId }) => {
    try {
      await ContactsAPI.updateBotConfig(popupId);
      dispatch('getBotConfig');
    } catch (error) {
      // Ignore error
    }
  },
  update: async ({ dispatch }, { user }) => {
    try {
      await ContactsAPI.update(user);
      dispatch('get');
    } catch (error) {
      // Ignore error
    }
  },
  setUser: async ({ dispatch }, { identifier, user: userObject }) => {
    try {
      const {
        email,
        name,
        avatar_url,
        identifier_hash: identifierHash,
        phone_number,
        company_name,
        city,
        country_code,
        description,
        custom_attributes,
        social_profiles,
      } = userObject;
      const user = {
        email,
        name,
        avatar_url,
        identifier_hash: identifierHash,
        phone_number,
        additional_attributes: {
          company_name,
          city,
          description,
          country_code,
          social_profiles,
        },
        custom_attributes,
      };
      const {
        data: { widget_auth_token: widgetAuthToken },
      } = await ContactsAPI.setUser(identifier, user);
      updateWidgetAuthToken(widgetAuthToken);
      dispatch('get');
      if (identifierHash || widgetAuthToken) {
        dispatch('conversation/clearConversations', {}, { root: true });
        dispatch('conversation/fetchOldConversations', {}, { root: true });
        dispatch('conversationAttributes/getAttributes', {}, { root: true });
      }
    } catch (error) {
      const data = parseErrorData(error);
      sendMessage({ event: 'error', errorType: SET_USER_ERROR, data });
    }
  },
  setCustomAttributes: async (_, customAttributes = {}) => {
    try {
      await ContactsAPI.setCustomAttributes(customAttributes);
    } catch (error) {
      // Ignore error
    }
  },
  deleteCustomAttribute: async (_, customAttribute) => {
    try {
      await ContactsAPI.deleteCustomAttribute(customAttribute);
    } catch (error) {
      // Ignore error
    }
  },
};

export const mutations = {
  [SET_CURRENT_USER]($state, user) {
    const { currentUser } = $state;
    $state.currentUser = { ...currentUser, ...user };
  },
  [SET_BOT_CONFIG]($state, config) {
    $state.botConfig = { ...$state.botConfig, ...config };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
