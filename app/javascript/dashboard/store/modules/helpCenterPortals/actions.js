import PortalAPI from 'dashboard/api/helpCenter/portals';
import { throwErrorMessage } from 'dashboard/store/utils/api';
import { types } from './mutations';
const portalAPIs = new PortalAPI();

export const actions = {
  index: async ({ commit }) => {
    try {
      commit(types.SET_UI_FLAG, { isFetching: true });
      const {
        data: { payload },
      } = await portalAPIs.get();
      commit(types.CLEAR_PORTALS);
      const portalSlugs = payload.map(portal => portal.slug);
      commit(types.ADD_MANY_PORTALS_ENTRY, payload);
      commit(types.ADD_MANY_PORTALS_IDS, portalSlugs);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_UI_FLAG, { isFetching: false });
    }
  },

  show: async ({ commit }, { portalSlug, locale }) => {
    commit(types.SET_UI_FLAG, { isFetchingItem: true });
    try {
      const response = await portalAPIs.getPortal({ portalSlug, locale });
      const {
        data: { meta },
      } = response;
      commit(types.SET_PORTALS_META, meta);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_UI_FLAG, { isFetchingItem: false });
    }
  },

  create: async ({ commit }, params) => {
    commit(types.SET_UI_FLAG, { isCreating: true });
    try {
      const { data } = await portalAPIs.create(params);
      const { slug: portalSlug } = data;
      commit(types.ADD_PORTAL_ENTRY, data);
      commit(types.ADD_PORTAL_ID, portalSlug);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_UI_FLAG, { isCreating: false });
    }
  },

  update: async ({ commit }, { portalSlug, ...portalObj }) => {
    commit(types.SET_HELP_PORTAL_UI_FLAG, {
      uiFlags: { isUpdating: true },
      portalSlug,
    });
    try {
      const { data } = await portalAPIs.updatePortal({
        portalSlug,
        portalObj,
      });
      commit(types.UPDATE_PORTAL_ENTRY, data);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_HELP_PORTAL_UI_FLAG, {
        uiFlags: { isUpdating: false },
        portalSlug,
      });
    }
  },

  delete: async ({ commit }, { portalSlug }) => {
    commit(types.SET_HELP_PORTAL_UI_FLAG, {
      uiFlags: { isDeleting: true },
      portalSlug,
    });
    try {
      await portalAPIs.delete(portalSlug);
      commit(types.REMOVE_PORTAL_ENTRY, portalSlug);
      commit(types.REMOVE_PORTAL_ID, portalSlug);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_HELP_PORTAL_UI_FLAG, {
        uiFlags: { isDeleting: false },
        portalSlug,
      });
    }
  },

  deleteLogo: async ({ commit }, { portalSlug }) => {
    commit(types.SET_HELP_PORTAL_UI_FLAG, {
      uiFlags: { isUpdating: true },
      portalSlug,
    });
    try {
      await portalAPIs.deleteLogo(portalSlug);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_HELP_PORTAL_UI_FLAG, {
        uiFlags: { isUpdating: false },
        portalSlug,
      });
    }
  },

  updatePortal: async ({ commit }, portal) => {
    commit(types.UPDATE_PORTAL_ENTRY, portal);
  },
};
