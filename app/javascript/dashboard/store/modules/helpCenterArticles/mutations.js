import types from '../../mutation-types';
import Vue from 'vue';

export const mutations = {
  [types.default.SET_UI_FLAG](_state, uiFlags) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...uiFlags,
    };
  },

  [types.default.ADD_HELP_CENTER_ARTICLE]: ($state, helpCenter) => {
    if (!helpCenter.id) return;

    Vue.set($state.articles.byId, helpCenter.id, {
      ...helpCenter,
    });
  },
  [types.default.ADD_HELP_CENTER_ARTICLE_ID]: ($state, helpCenterId) => {
    if (!helpCenterId) return;
    $state.articles.allIds.push(helpCenterId);
  },
  [types.default.ADD_HELP_CENTER_ARTICLE_FLAG]: (
    $state,
    { helpCenterId, uiFlags }
  ) => {
    const flags = $state.helpCenters.uiFlags.byId[helpCenterId];
    Vue.set($state.helpCenters.uiFlags.byId, helpCenterId, {
      ...{
        isFetching: false,
        isUpdating: false,
        isDeleting: false,
      },
      ...flags,
      ...uiFlags,
    });
  },
};
