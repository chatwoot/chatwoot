import AlooConversationAPI from 'dashboard/api/aloo/conversation';
import { createStore } from '../storeFactory';

export default createStore({
  name: 'AlooConversation',
  API: AlooConversationAPI,
  actions: mutationTypes => ({
    async getConversations({ commit }, { assistantId, page = 1 }) {
      commit(mutationTypes.SET_UI_FLAG, { fetchingList: true });
      try {
        const response = await AlooConversationAPI.getConversations(
          assistantId,
          { page }
        );
        commit(mutationTypes.SET, response.data.payload || response.data);
        if (response.data.meta) {
          commit(mutationTypes.SET_META, response.data.meta);
        }
        return response.data;
      } finally {
        commit(mutationTypes.SET_UI_FLAG, { fetchingList: false });
      }
    },
  }),
});
