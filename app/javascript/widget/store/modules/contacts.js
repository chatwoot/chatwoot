import ContactsAPI from '../../api/contacts';
import { refreshActionCableConnector } from '../../helpers/actionCable';

export const actions = {
  update: async ({ dispatch }, { identifier, user: userObject }) => {
    try {
      const user = {
        email: userObject.email,
        name: userObject.name,
        avatar_url: userObject.avatar_url,
        identifier_hash: userObject.identifier_hash,
      };
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

export default {
  namespaced: true,
  state: {},
  getters: {},
  actions,
  mutations: {},
};
