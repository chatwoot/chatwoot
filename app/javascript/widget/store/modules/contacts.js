import ContactsAPI from '../../api/contacts';
import { refreshActionCableConnector } from '../../helpers/actionCable';

const state = {
  currentUser: {},
  uiFlags: {
    isUpdating: false,
  },
};

const SET_CURRENT_USER = 'SET_CURRENT_USER';
const SET_CONTACTS_UI_FLAG = 'SET_CONTACTS_UI_FLAG';

export const getters = {
  getCurrentUser(_state) {
    return _state.currentUser;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

export const actions = {
  update: async ({ dispatch, commit }, { identifier, user: userObject }) => {
    try {
      const user = {
        email: userObject.email,
        name: userObject.name,
        avatar_url: userObject.avatar_url,
        identifier_hash: userObject.identifier_hash,
      };
      commit(SET_CONTACTS_UI_FLAG, { isUpdating: true });
      commit(SET_CURRENT_USER, user);
      const {
        data: { pubsub_token: pubsubToken },
      } = await ContactsAPI.update(identifier, user);

      if (userObject.identifier_hash) {
        dispatch('conversation/clearConversations', {}, { root: true });
        dispatch('conversation/fetchOldConversations', {}, { root: true });
      }

      refreshActionCableConnector(pubsubToken);
    } catch (error) {
      // Ingore error
    } finally {
      commit(SET_CONTACTS_UI_FLAG, { isUpdating: false });
    }
  },
  setCustomAttributes: async (_, customAttributes = {}) => {
    try {
      await ContactsAPI.setCustomAttibutes(customAttributes);
    } catch (error) {
      // Ingore error
    }
  },
};

export const mutations = {
  [SET_CURRENT_USER]($state, user) {
    $state.currentUser = user;
  },
  [SET_CONTACTS_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
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
