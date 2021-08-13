import ContactsAPI from '../../api/contacts';
import { refreshActionCableConnector } from '../../helpers/actionCable';

const state = {
  currentUser: {},
};

const SET_CURRENT_USER = 'SET_CURRENT_USER';

export const getters = {
  getCurrentUser(_state) {
    return _state.currentUser;
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
  update: async ({ dispatch }, { identifier, user: userObject }) => {
    try {
      const user = {
        email: userObject.email,
        name: userObject.name,
        avatar_url: userObject.avatar_url,
        identifier_hash: userObject.identifier_hash,
        phone_number: userObject.phone_number,
      };
      const {
        data: { pubsub_token: pubsubToken },
      } = await ContactsAPI.update(identifier, user);

      dispatch('get');
      if (userObject.identifier_hash) {
        dispatch('conversation/clearConversations', {}, { root: true });
        dispatch('conversation/fetchOldConversations', {}, { root: true });
      }

      refreshActionCableConnector(pubsubToken);
    } catch (error) {
      // Ingore error
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
    const { currentUser } = $state;
    $state.currentUser = { ...currentUser, ...user };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
