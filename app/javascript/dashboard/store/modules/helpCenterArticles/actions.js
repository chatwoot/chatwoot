import helpCenterArticlesAPI from 'widget/api/conversationPublic';

export const actions = {
  fetchAllArticles: async ({ commit }) => {
    try {
      commit('setUIFlag', { isFetching: true });
      const { data } = await helpCenterArticlesAPI.get();
      data.forEach(helpCenter => {
        const { id: helpCenterId } = helpCenter;

        commit('addHelpCenterArticleEntry', helpCenter);
        commit('addHelpCenterArticleId', helpCenterId);
        commit('setHelpCenterArticleUIFlag', {
          uiFlags: {},
          helpCenterId,
        });
      });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isFetching: false });
    }
  },
};
