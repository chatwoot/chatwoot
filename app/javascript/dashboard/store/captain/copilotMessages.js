import CopilotMessagesAPI from 'dashboard/api/captain/copilotMessages';
import { throwErrorMessage } from 'dashboard/store/utils/api';
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
    async fetchThread({ commit }, { threadId }) {
      try {
        const messages = [];
        let page = 1;
        let meta;

        do {
          // Fetch each page in order so older chats are complete before they are shown.
          // eslint-disable-next-line no-await-in-loop
          const response = await CopilotMessagesAPI.get(threadId, { page });
          messages.push(...response.data.payload);
          meta = response.data.meta;
          page += 1;
          if (!response.data.payload.length) break;
        } while (messages.length < meta.total_count);

        messages.forEach(message => commit(mutationTypes.UPSERT, message));
        return messages;
      } catch (error) {
        return throwErrorMessage(error);
      }
    },
    upsert({ commit }, data) {
      commit(mutationTypes.UPSERT, data);
    },
  }),
});
