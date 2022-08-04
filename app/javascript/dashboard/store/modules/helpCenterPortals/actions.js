import PortalAPI from 'dashboard/api/helpCenter/portals.js';
import { throwErrorMessage } from 'dashboard/store/utils/api';
import { types } from './mutations';
const portalAPIs = new PortalAPI();
export const actions = {
  index: async ({ commit }) => {
    try {
      commit(types.SET_UI_FLAG, { isFetching: true });
      const { data } = await portalAPIs.get();
      const portalIds = data.map(portal => portal.id);
      commit(types.ADD_MANY_PORTALS_ENTRY, data);
      commit(types.ADD_MANY_PORTALS_IDS, portalIds);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_UI_FLAG, { isFetching: false });
    }
  },

  create: async ({ commit }, params) => {
    commit(types.SET_UI_FLAG, { isCreating: true });
    try {
      const { data } = await portalAPIs.create(params);
      const { id: portalId } = data;
      commit(types.ADD_PORTAL_ENTRY, data);
      commit(types.ADD_PORTAL_ID, portalId);
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
};
