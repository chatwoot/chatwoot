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

    const { [helpCenterId]: toBeRemoved, ...newById } = $state.helpCenters.byId;
    Vue.set($state.helpCenters, 'byId', newById);
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
};
