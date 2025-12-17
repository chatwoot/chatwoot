import aiAPI from '../../../../api/aiFeatures';

export const aiFeatureActions = {
  searchSemantic: async ({ commit }, { accountId, query, limit = 20, inbox_id, team_id }) => {
    try {
      const response = await aiAPI.searchConversationsSemantic({
        query,
        limit,
        inbox_id,
        team_id,
      });
      return response;
    } catch (error) {
      console.error('Error in semantic search:', error);
      throw error;
    }
  },

  fetchSimilar: async ({ commit }, { accountId, conversationId, limit = 5 }) => {
    try {
      const response = await aiAPI.fetchSimilarConversations(conversationId, { limit });
      return response;
    } catch (error) {
      console.error('Error fetching similar conversations:', error);
      throw error;
    }
  },
};

export default aiFeatureActions;
