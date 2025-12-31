import AlooEmbeddingAPI from 'dashboard/api/aloo/embedding';
import { createStore } from '../storeFactory';

export default createStore({
  name: 'AlooEmbedding',
  API: AlooEmbeddingAPI,
  actions: mutationTypes => ({
    async getEmbeddings({ commit }, { assistantId, page = 1, status }) {
      commit(mutationTypes.SET_UI_FLAG, { fetchingList: true });
      try {
        const response = await AlooEmbeddingAPI.getEmbeddings(assistantId, {
          page,
          status,
        });
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
