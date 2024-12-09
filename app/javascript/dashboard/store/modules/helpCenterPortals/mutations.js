import { defaultPortalFlags } from './index';

export const types = {
  SET_UI_FLAG: 'setUIFlag',
  ADD_PORTAL_ENTRY: 'addPortalEntry',
  SET_PORTALS_META: 'setPortalsMeta',
  ADD_MANY_PORTALS_ENTRY: 'addManyPortalsEntry',
  ADD_PORTAL_ID: 'addPortalId',
  CLEAR_PORTALS: 'clearPortals',
  ADD_MANY_PORTALS_IDS: 'addManyPortalsIds',
  UPDATE_PORTAL_ENTRY: 'updatePortalEntry',
  REMOVE_PORTAL_ENTRY: 'removePortalEntry',
  REMOVE_PORTAL_ID: 'removePortalId',
  SET_HELP_PORTAL_UI_FLAG: 'setHelpCenterUIFlag',
  SET_PORTAL_SWITCHING_FLAG: 'setPortalSwitchingFlag',
};

export const mutations = {
  [types.SET_UI_FLAG]($state, uiFlags) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...uiFlags,
    };
  },

  [types.ADD_PORTAL_ENTRY]($state, portal) {
    $state.portals.byId = {
      ...$state.portals.byId,
      [portal.slug]: {
        ...portal,
      },
    };
  },

  [types.ADD_MANY_PORTALS_ENTRY]($state, portals) {
    const allPortals = { ...$state.portals.byId };
    portals.forEach(portal => {
      allPortals[portal.slug] = portal;
    });
    $state.portals.byId = allPortals;
  },

  [types.CLEAR_PORTALS]: $state => {
    $state.portals.byId = {};
    $state.portals.allIds = [];
    $state.portals.uiFlags.byId = {};
  },

  [types.SET_PORTALS_META]: ($state, data) => {
    const {
      all_articles_count: allArticlesCount = 0,
      mine_articles_count: mineArticlesCount = 0,
      draft_articles_count: draftArticlesCount = 0,
      archived_articles_count: archivedArticlesCount = 0,
    } = data;
    $state.meta = {
      ...$state.meta,
      allArticlesCount,
      archivedArticlesCount,
      mineArticlesCount,
      draftArticlesCount,
    };
  },

  [types.ADD_PORTAL_ID]($state, portalSlug) {
    $state.portals.allIds.push(portalSlug);
  },

  [types.ADD_MANY_PORTALS_IDS]($state, portalSlugs) {
    $state.portals.allIds.push(...portalSlugs);
  },

  [types.UPDATE_PORTAL_ENTRY]($state, portal) {
    const portalSlug = portal.slug;
    if (!$state.portals.allIds.includes(portalSlug)) return;

    $state.portals.byId = {
      ...$state.portals.byId,
      [portalSlug]: {
        ...portal,
      },
    };
  },

  [types.REMOVE_PORTAL_ENTRY]($state, portalSlug) {
    if (!portalSlug) return;

    const { [portalSlug]: toBeRemoved, ...newById } = $state.portals.byId;
    $state.portals.byId = newById;
  },

  [types.REMOVE_PORTAL_ID]($state, portalSlug) {
    $state.portals.allIds = $state.portals.allIds.filter(
      slug => slug !== portalSlug
    );
  },

  [types.SET_HELP_PORTAL_UI_FLAG]($state, { portalSlug, uiFlags }) {
    const flags = $state.portals.uiFlags.byId[portalSlug];
    $state.portals.uiFlags.byId = {
      ...$state.portals.uiFlags.byId,
      [portalSlug]: {
        ...defaultPortalFlags,
        ...flags,
        ...uiFlags,
      },
    };
  },

  [types.SET_PORTAL_SWITCHING_FLAG]($state, { isSwitching }) {
    $state.uiFlags.isSwitching = isSwitching;
  },
};
