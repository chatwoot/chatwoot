import PortalsAPI from 'dashboard/api/helpCenter/portals.js';
import { throwErrorMessage } from 'dashboard/store/utils/api';
import { types } from './mutations';

export const actions = {
  fetchAllPortals: async ({ commit }) => {
    try {
      commit(types.SET_UI_FLAG, { isFetching: true });
      const { data } = await HelpCenterPortalsAPI.get();
      const portalIds = data.map(portal => portal.id);

      commit(types.ADD_MANY_PORTALS_ENTRY, data);
      commit(types.ADD_MANY_PORTALS_IDS, portalIds);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_UI_FLAG, { isFetching: false });
    }
  },

  createPortal: async ({ commit }, params) => {
    commit(types.SET_UI_FLAG, { isCreating: true });
    try {
      const { data } = await HelpCenterPortalsAPI.create(params);
      const { id: helpCenterId } = data;

      commit(types.ADD_PORTAL_ENTRY, data);
      commit(types.ADD_PORTAL_ID, helpCenterId);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_UI_FLAG, { isCreating: false });
    }
  },

  updatePortal: async ({ commit }, { helpCenter }) => {
    const helpCenterId = helpCenter.id;
    commit(types.SET_HELP_PORTAL_UI_FLAG, {
      uiFlags: {
        isUpdating: true,
      },
      helpCenterId,
    });
    try {
      const { data } = await HelpCenterPortalsAPI.update(helpCenter);
      commit(types.UPDATE_PORTAL_ENTRY, data);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_HELP_PORTAL_UI_FLAG, {
        uiFlags: {
          isUpdating: false,
        },
        helpCenterId,
      });
    }
  },

  deletePortal: async ({ commit }, { helpCenterId }) => {
    commit(types.SET_HELP_PORTAL_UI_FLAG, {
      uiFlags: {
        isDeleting: true,
      },
      helpCenterId,
    });
    try {
      await HelpCenterPortalsAPI.delete(helpCenterId);

      commit(types.REMOVE_PORTAL_ENTRY, helpCenterId);
      commit(types.REMOVE_PORTAL_ID, helpCenterId);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_HELP_PORTAL_UI_FLAG, {
        uiFlags: {
          isDeleting: false,
        },
        helpCenterId,
      });
    }
  },
};
