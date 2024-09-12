import types from '../../mutation-types';
import IntegrationsOrderAPI from '../../../api/IntegrationOrders';
export const actions = {
  search: async ({ commit }, { search, page, sortAttr }) => {
    commit(types.SET_INTEGRATIONS_UI_FLAG, { isFetching: true });
    try {
      const {
        data: { payload, meta },
      } = await IntegrationsOrderAPI.search(search, page, sortAttr);
      commit(types.CLEAR_INTEGRATIONS);
      commit(types.SET_INTEGRATIONS, payload);
      commit(types.SET_INTEGRATIONS_META, meta);
      commit(types.SET_INTEGRATIONS_UI_FLAG, { isFetching: false });
    } catch (error) {
      commit(types.SET_INTEGRATIONS_UI_FLAG, { isFetching: false });
    }
  },

  get: async ({ commit }, { page = 1, sortAttr } = {}) => {
    commit(types.SET_INTEGRATIONS_UI_FLAG, { isFetching: true });

    try {
      const {
        data: { payload, meta },
      } = await IntegrationsOrderAPI.get(page, sortAttr);
      commit(types.CLEAR_INTEGRATIONS);
      commit(types.SET_INTEGRATIONS, payload);
      commit(types.SET_INTEGRATIONS_META, meta);
      commit(types.SET_INTEGRATIONS_UI_FLAG, { isFetching: false });
    } catch (error) {
      commit(types.SET_INTEGRATIONS_UI_FLAG, { isFetching: false });
    }
  },

  show: async ({ commit }, { id }) => {
    commit(types.SET_INTEGRATIONS_UI_FLAG, { isFetchingItem: true });
    try {
      const response = await IntegrationsOrderAPI.show(id);
      commit(types.SET_INTEGRATION_ORDER_ITEM, response.data.payload);
      commit(types.SET_INTEGRATIONS_UI_FLAG, {
        isFetchingItem: false,
      });
    } catch (error) {
      commit(types.SET_INTEGRATIONS_UI_FLAG, {
        isFetchingItem: false,
      });
    }
  },

  update: async ({ commit }) => {
    commit(types.SET_INTEGRATIONS_UI_FLAG, { isFetching: true });

    try {
      await IntegrationsOrderAPI.update();
    } catch (error) {
      commit(types.SET_INTEGRATIONS_UI_FLAG, { isFetching: false });
    } finally {
      commit(types.SET_INTEGRATIONS_UI_FLAG, { isFetching: false });
    }
  },

  filter: async (
    { commit },
    { page = 1, sortAttr, queryPayload, resetState = true } = {}
  ) => {
    commit(types.SET_INTEGRATIONS_UI_FLAG, { isFetching: true });
    try {
      const {
        data: { payload, meta },
      } = await IntegrationsOrderAPI.filter(page, sortAttr, queryPayload);
      if (resetState) {
        commit(types.CLEAR_INTEGRATIONS);
        commit(types.SET_INTEGRATIONS, payload);
        commit(types.SET_INTEGRATIONS_META, meta);
        commit(types.SET_INTEGRATIONS_UI_FLAG, { isFetching: false });
      }
      return payload;
    } catch (error) {
      commit(types.SET_INTEGRATIONS_UI_FLAG, { isFetching: false });
    }
    return [];
  },

  contactOrders: async ({ commit }, { contactId }) => {
    commit(types.SET_INTEGRATIONS_UI_FLAG, { isFetching: true });
    try {
      const {
        data: { payload },
      } = await IntegrationsOrderAPI.contactOrders(contactId);

      commit(types.SET_CONTACT_ORDERS, payload);
      commit(types.SET_INTEGRATIONS_UI_FLAG, {
        isFetchingItem: false,
      });
    } catch (error) {
      commit(types.SET_INTEGRATIONS_UI_FLAG, { isFetching: false });
    }
  },

  setOrdersFilters({ commit }, data) {
    commit(types.SET_ORDERS_FILTERS, data);
  },

  clearOrdersFilters({ commit }) {
    commit(types.CLEAR_ORDERS_FILTERS);
  },
};
