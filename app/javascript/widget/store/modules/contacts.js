import ContactsAPI from '../../api/contacts';
import { refreshActionCableConnector } from '../../helpers/actionCable';

export const actions = {
  update: async (_, { identifier, user: userObject }) => {
    try {
      const customAttributes = userObject.customAttributes || {};
      const user = {
        email: userObject.email,
        name: userObject.name,
        custom_attributes: {
          avatar_url: customAttributes.avatarUrl,
        },
      };
      const {
        data: { pubsub_token: pubsubToken },
      } = await ContactsAPI.update(identifier, user);
      refreshActionCableConnector(pubsubToken);
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
