import Vue from 'vue';
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
};

export const mutations = {
  [types.SET_UI_FLAG]($state, uiFlags) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...uiFlags,
    };
  },

  [types.ADD_PORTAL_ENTRY]($state, portal) {
    Vue.set($state.portals.byId, portal.slug, {
      ...portal,
    });
  },

  [types.ADD_MANY_PORTALS_ENTRY]($state, portals) {
    const allPortals = { ...$state.portals.byId };
    portals.forEach(portal => {
      allPortals[portal.slug] = portal;
    });
    Vue.set($state.portals, 'byId', allPortals);
  },

  [types.CLEAR_PORTALS]: $state => {
    Vue.set($state.portals, 'byId', {});
    Vue.set($state.portals, 'allIds', []);
    Vue.set($state.portals.uiFlags, 'byId', {});
  },

  [types.SET_PORTALS_META]: ($state, data) => {
    const {
      all_articles_count: allArticlesCount = 0,
      mine_articles_count: mineArticlesCount = 0,
      draft_articles_count: draftArticlesCount = 0,
      archived_articles_count: archivedArticlesCount = 0,
    } = data;
    Vue.set($state.meta, 'allArticlesCount', allArticlesCount);
    Vue.set($state.meta, 'archivedArticlesCount', archivedArticlesCount);
    Vue.set($state.meta, 'mineArticlesCount', mineArticlesCount);
    Vue.set($state.meta, 'draftArticlesCount', draftArticlesCount);
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

    Vue.set($state.portals.byId, portalSlug, {
      ...portal,
    });
  },

  [types.REMOVE_PORTAL_ENTRY]($state, portalSlug) {
    if (!portalSlug) return;

    const { [portalSlug]: toBeRemoved, ...newById } = $state.portals.byId;
    Vue.set($state.portals, 'byId', newById);
  },

  [types.REMOVE_PORTAL_ID]($state, portalSlug) {
    $state.portals.allIds = $state.portals.allIds.filter(
      slug => slug !== portalSlug
    );
  },

  [types.SET_HELP_PORTAL_UI_FLAG]($state, { portalSlug, uiFlags }) {
    const flags = $state.portals.uiFlags.byId[portalSlug];
    Vue.set($state.portals.uiFlags.byId, portalSlug, {
      ...defaultPortalFlags,
      ...flags,
      ...uiFlags,
    });
  },
};
