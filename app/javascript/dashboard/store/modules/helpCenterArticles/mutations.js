import Vue from 'vue';

export const mutations = {
  setUIFlag($state, uiFlags) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...uiFlags,
    };
  },

  addHelpCenterEntry($state, helpCenter) {
    if (!helpCenter.id) return;

    Vue.set($state.articles.byId, helpCenter.id, {
      ...helpCenter,
    });
  },

  addHelpCenterId($state, helpCenterId) {
    $state.articles.allIds.push(helpCenterId);
  },
};
