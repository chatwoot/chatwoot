import Vue from 'vue';
import { defaultHelpCenterFlags } from './index';

export const mutations = {
  setUIFlag($state, uiFlags) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...uiFlags,
    };
  },

  addHelpCenterEntry($state, helpCenter) {
    if (!helpCenter.id) return;

    Vue.set($state.helpCenters.byId, helpCenter.id, {
      ...helpCenter,
      localeIds: [],
    });
  },

  addHelpCenterId($state, helpCenterId) {
    $state.helpCenters.allIds.push(helpCenterId);
  },

  updateHelpCenterEntry($state, helpCenter) {
    const helpCenterId = helpCenter.id;
    if (!helpCenterId) return;
    if (!$state.helpCenters.allIds.includes(helpCenterId)) return;

    Vue.set($state.helpCenters.byId, helpCenterId, {
      ...helpCenter,
    });
  },

  removeHelpCenterEntry($state, helpCenterId) {
    if (!helpCenterId) return;

    Vue.set($state.helpCenters.byId, helpCenterId, undefined);
  },

  removeHelpCenterId($state, helpCenterId) {
    $state.helpCenters.allIds = $state.helpCenters.allIds.filter(
      id => id !== helpCenterId
    );
  },

  setHelpCenterUIFlag($state, { helpCenterId, uiFlags }) {
    const flags = $state.helpCenters.uiFlags.byId[helpCenterId];
    Vue.set($state.helpCenters.uiFlags.byId, helpCenterId, {
      ...defaultHelpCenterFlags,
      ...flags,
      ...uiFlags,
    });
  },

  appendLocaleIdsToHelpCenter($state, { helpCenterId, locales }) {
    if (!helpCenterId) return;
    const helpCenter = $state.helpCenters.byId[helpCenterId];

    const localeIds = locales.map(locale => locale.id);
    const updatedLocaleIds = [...helpCenter.locales, ...localeIds];
    const uniqIds = Array.from(new Set(updatedLocaleIds));

    Vue.set(helpCenter, 'localeIds', uniqIds);
  },

  removeLocaleIdFromConversation($state, { helpCenterId, localeId }) {
    if (!localeId || !helpCenterId) return;

    const helpCenter = $state.helpCenter.byId[helpCenterId];
    if (!helpCenter) return;

    Vue.set(
      helpCenter,
      'localeIds',
      helpCenter.localeIds.filter(id => id !== localeId)
    );
  },
};
