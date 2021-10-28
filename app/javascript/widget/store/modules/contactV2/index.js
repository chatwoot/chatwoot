import ContactsAPI from 'widget/api/contacts';
import { refreshActionCableConnector } from '../../../helpers/actionCable';

const state = {
  currentUser: {},
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
  },
};

export const getters = {
  getCurrentUser(_state) {
    return _state.currentUser;
  },
};

export const actions = {
  get: async ({ commit }) => {
    try {
      commit('setUIFlag', { isFetching: true });
      const { data } = await ContactsAPI.get();
      const { pubsub_token: pubsubToken } = data;
      commit('setCurrentUser', data);

      refreshActionCableConnector(pubsubToken);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isFetching: false });
    }
  },
  update: async ({ commit }, { identifier, user: userObject }) => {
    try {
      commit('setUIFlag', { isUpdating: false });
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

      refreshActionCableConnector(pubsubToken);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isUpdating: false });
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
  setCurrentUser($state, user) {
    const { currentUser } = $state;
    $state.currentUser = { ...currentUser, ...user };
  },
  setUIFlag($state, uiFlags) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...uiFlags,
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
