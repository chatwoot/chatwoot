import AlooAssistantAPI from 'dashboard/api/aloo/assistant';
import { createStore } from '../storeFactory';

export default createStore({
  name: 'AlooAssistant',
  API: AlooAssistantAPI,
  actions: mutationTypes => ({
    async assignInbox({ commit }, { assistantId, inboxId }) {
      const response = await AlooAssistantAPI.assignInbox(assistantId, inboxId);
      commit(mutationTypes.EDIT, response.data);
      return response.data;
    },
    async unassignInbox({ commit }, { assistantId, inboxId }) {
      const response = await AlooAssistantAPI.unassignInbox(
        assistantId,
        inboxId
      );
      commit(mutationTypes.EDIT, response.data);
      return response.data;
    },
    async getStats(_, assistantId) {
      const response = await AlooAssistantAPI.getStats(assistantId);
      return response.data;
    },
  }),
});
