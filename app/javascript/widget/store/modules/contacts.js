import ContactsAPI from '../../api/contacts';
import { refreshActionCableConnector } from '../../helpers/actionCable';

export const actions = {
  update: async (_, { identifier, user: userObject }) => {
    try {
      const user = {
        email: userObject.email,
        name: userObject.name,
        avatar_url: userObject.avatar_url,
      };
      const {
        data: { pubsub_token: pubsubToken },
      } = await ContactsAPI.update(identifier, user);
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
