import PortalAPI from 'dashboard/api/helpCenter/portals.js';
import { throwErrorMessage } from 'dashboard/store/utils/api';
import { types } from './mutations';
const portalAPIs = new PortalAPI();
export const actions = {
  index: async ({ commit, state, dispatch }) => {
    try {
      commit(types.SET_UI_FLAG, { isFetching: true });
      const {
        data: { payload, meta },
      } = await portalAPIs.get();
      commit(types.CLEAR_PORTALS);
      const portalIds = payload.map(portal => portal.id);
      commit(types.ADD_MANY_PORTALS_ENTRY, payload);
      commit(types.ADD_MANY_PORTALS_IDS, portalIds);
      const { selectedPortalId } = state;
      // Check if selected portal is still in the portals list
      if (!portalIds.includes(selectedPortalId)) {
        dispatch('setPortalId', portalIds[0]);
      }
      commit(types.SET_PORTALS_META, meta);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_UI_FLAG, { isFetching: false });
    }
  },

  create: async ({ commit, state, dispatch }, params) => {
    commit(types.SET_UI_FLAG, { isCreating: true });
    try {
      const { data } = await portalAPIs.create(params);
      const { id: portalId } = data;
      commit(types.ADD_PORTAL_ENTRY, data);
      commit(types.ADD_PORTAL_ID, portalId);
      const {
        portals: { selectedPortalId },
      } = state;
      // Check if there are any selected portal
      if (!selectedPortalId) {
        dispatch('setPortalId', portalId);
      }
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_UI_FLAG, { isCreating: false });
    }
  },

  update: async ({ commit }, params) => {
    const portalId = params.id;
    commit(types.SET_HELP_PORTAL_UI_FLAG, {
      uiFlags: { isUpdating: true },
      portalId,
    });
    try {
      const { data } = await portalAPIs.update(params);
      commit(types.UPDATE_PORTAL_ENTRY, data);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_HELP_PORTAL_UI_FLAG, {
        uiFlags: { isUpdating: false },
        portalId,
      });
    }
  },

  delete: async ({ commit }, portalId) => {
    commit(types.SET_HELP_PORTAL_UI_FLAG, {
      uiFlags: { isDeleting: true },
      portalId,
    });
    try {
      await portalAPIs.delete(portalId);
      commit(types.REMOVE_PORTAL_ENTRY, portalId);
      commit(types.REMOVE_PORTAL_ID, portalId);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_HELP_PORTAL_UI_FLAG, {
        uiFlags: { isDeleting: false },
        portalId,
      });
    }
  },
  setPortalId: async ({ commit }, portalId) => {
    commit(types.SET_SELECTED_PORTAL_ID, portalId);
  },
  updatePortal: async ({ commit }, portal) => {
    commit(types.UPDATE_PORTAL_ENTRY, portal);
  },
};
