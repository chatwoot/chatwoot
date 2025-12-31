import AlooMemoryAPI from 'dashboard/api/aloo/memory';
import { createStore } from '../storeFactory';

export default createStore({
  name: 'AlooMemory',
  API: AlooMemoryAPI,
  actions: mutationTypes => ({
    async getMemories(
      { commit },
      { assistantId, page = 1, memoryType, activeOnly = false }
    ) {
      commit(mutationTypes.SET_UI_FLAG, { fetchingList: true });
      try {
        const response = await AlooMemoryAPI.getMemories(assistantId, {
          page,
          memoryType,
          activeOnly,
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
    async deleteMemory({ commit }, { assistantId, memoryId }) {
      commit(mutationTypes.SET_UI_FLAG, { deletingItem: true });
      try {
        await AlooMemoryAPI.deleteMemory(assistantId, memoryId);
        commit(mutationTypes.DELETE, memoryId);
        return memoryId;
      } finally {
        commit(mutationTypes.SET_UI_FLAG, { deletingItem: false });
      }
    },
  }),
});
