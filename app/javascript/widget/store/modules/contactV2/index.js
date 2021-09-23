import ContactPublicAPI from 'widget/api/contacts';
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
  create: async ({ commit }, { inboxIdentifier, user: userObject }) => {
    try {
      commit('setUIFlag', { isCreating: true });
      const user = {
        email: userObject.email,
        name: userObject.name,
        avatar_url: userObject.avatar_url,
        identifier_hash: userObject.identifier_hash,
        phone_number: userObject.phone_number,
      };
      const { data } = await ContactPublicAPI.update(inboxIdentifier, user);
      const { pubsub_token: pubsubToken } = data;

      commit('setCurrentUser', data);
      refreshActionCableConnector(pubsubToken);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isCreating: false });
    }
  },
  get: async ({ commit }, { inboxIdentifier, contactIdentifier }) => {
    try {
      commit('setUIFlag', { isFetching: true });
      const { data } = await ContactPublicAPI.get(
        inboxIdentifier,
        contactIdentifier
      );
      commit('setCurrentUser', data);
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
      } = await ContactPublicAPI.update(identifier, user);

      refreshActionCableConnector(pubsubToken);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isUpdating: false });
    }
  },
  setCustomAttributes: async (_, customAttributes = {}) => {
    try {
      await ContactPublicAPI.setCustomAttibutes(customAttributes);
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
