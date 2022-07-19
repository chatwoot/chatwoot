import helpCenterArticlesAPI from 'dashboard/api/helpcenter/article.js';
import types from '../../mutation-types';
export const actions = {
  fetchAllArticles: async ({ commit }) => {
    try {
      commit(types.SET_UI_FLAG, { isFetching: true });
      const { data } = await helpCenterArticlesAPI.get();

      data.payload.forEach(helpCenter => {
        const { id: helpCenterId } = helpCenter;

        commit(types.ADD_HELP_CENTER_ARTICLE, helpCenter);
        commit(types.ADD_HELP_CENTER_ARTICLE_ID, helpCenterId);
        commit(types.ADD_HELP_CENTER_ARTICLE_FLAG, {
          uiFlags: {},
          helpCenterId,
        });
      });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_UI_FLAG, { isFetching: false });
    }
  },
};
