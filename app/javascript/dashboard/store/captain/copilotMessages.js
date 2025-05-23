import CopilotMessagesAPI from 'dashboard/api/captain/copilotMessages';
import { createStore } from './storeFactory';

export default createStore({
  name: 'CopilotMessages',
  API: CopilotMessagesAPI,
  getters: {
    getMessagesByThreadId: state => copilotThreadId => {
      return state.records.filter(
        record => record.copilot_thread?.id === Number(copilotThreadId)
      );
    },
  },
  actions: mutationTypes => ({
    upsert({ commit }, data) {
      commit(mutationTypes.UPSERT, data);
    },
  }),
});
