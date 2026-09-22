import CopilotMessagesAPI from 'dashboard/api/captain/copilotMessages';
import { createStore } from '../storeFactory';

export default createStore({
  name: 'CopilotMessages',
  API: CopilotMessagesAPI,
  getters: {
    getMessagesByThreadId: state => copilotThreadId => {
      return state.records
        .filter(record => record.copilot_thread?.id === Number(copilotThreadId))
        .sort((a, b) => a.id - b.id);
    },
  },
  actions: mutationTypes => ({
    async getPage({ commit, state }, { threadId, page = 1 }) {
      const { data } = await CopilotMessagesAPI.get(threadId, {
        page,
        history: true,
      });
      // A websocket may have delivered a newer copy while this page was loading.
      data.payload.forEach(record => {
        if (!state.records.some(existing => existing.id === record.id)) {
          commit(mutationTypes.UPSERT, record);
        }
      });
      return data;
    },
    upsert({ commit }, data) {
      commit(mutationTypes.UPSERT, data);
    },
  }),
});
