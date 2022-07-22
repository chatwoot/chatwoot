import Vue from 'vue';
import { defaultPortalFlags } from './index';

export const types = {
  SET_UI_FLAG: 'setUIFlag',
  ADD_PORTAL_ENTRY: 'addPortalEntry',
  ADD_MANY_PORTALS_ENTRY: 'addManyPortalsEntry',
  ADD_PORTAL_ID: 'addPortalId',
  ADD_MANY_PORTALS_IDS: 'addManyPortalsIds',
  UPDATE_PORTAL_ENTRY: 'updatePortalEntry',
  REMOVE_PORTAL_ENTRY: 'removePortalEntry',
  REMOVE_PORTAL_ID: 'removePortalId',
  SET_HELP_PORTAL_UI_FLAG: 'setHelpCenterUIFlag',
};

export const mutations = {
  [types.SET_UI_FLAG]($state, uiFlags) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...uiFlags,
    };
  },

  [types.ADD_PORTAL_ENTRY]($state, portal) {
    Vue.set($state.portals.byId, portal.id, {
      ...portal,
    });
  },

  [types.ADD_MANY_PORTALS_ENTRY]($state, portals) {
    const allPortals = { ...$state.portals.byId };
    portals.forEach(portal => {
      allPortals[portal.id] = portal;
    });
    Vue.set($state.portals, 'byId', {
      allPortals,
    });
  },

  [types.ADD_PORTAL_ID]($state, portalId) {
    $state.portals.allIds.push(portalId);
  },

  [types.ADD_MANY_PORTALS_IDS]($state, portalIds) {
    $state.portals.allIds.push(...portalIds);
  },

  [types.UPDATE_PORTAL_ENTRY]($state, portal) {
    const portalId = portal.id;
    if (!$state.portals.allIds.includes(portalId)) return;

    Vue.set($state.portals.byId, portalId, {
      ...portal,
    });
  },

  [types.REMOVE_PORTAL_ENTRY]($state, portalId) {
    if (!portalId) return;

    const { [portalId]: toBeRemoved, ...newById } = $state.portals.byId;
    Vue.set($state.portals, 'byId', newById);
  },

  [types.REMOVE_PORTAL_ID]($state, portalId) {
    $state.portals.allIds = $state.portals.allIds.filter(id => id !== portalId);
  },

  [types.SET_HELP_PORTAL_UI_FLAG]($state, { portalId, uiFlags }) {
    const flags = $state.portals.uiFlags.byId[portalId];
    Vue.set($state.portals.uiFlags.byId, portalId, {
      ...defaultPortalFlags,
      ...flags,
      ...uiFlags,
    });
  },
};
