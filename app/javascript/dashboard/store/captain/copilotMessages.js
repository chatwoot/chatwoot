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
    async get({ commit, state }, threadId) {
      commit(mutationTypes.SET_UI_FLAG, { fetchingList: true });
      try {
        const messages = [];
        let page = 1;
        let meta;
        do {
          // Fetch the next page only after the previous page establishes the remaining count.
          // eslint-disable-next-line no-await-in-loop
          const response = await CopilotMessagesAPI.get(threadId, { page });
          messages.push(...response.data.payload);
          meta = response.data.meta;
          page += 1;
          if (!response.data.payload.length) break;
        } while (messages.length < meta.total_count);

        const recordsById = new Map(
          state.records.map(record => [record.id, record])
        );
        messages.forEach(message => recordsById.set(message.id, message));
        commit(mutationTypes.SET, [...recordsById.values()]);
        commit(mutationTypes.SET_META, meta);
        return messages;
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        commit(mutationTypes.SET_UI_FLAG, { fetchingList: false });
      }
    },
    upsert({ commit }, data) {
      commit(mutationTypes.UPSERT, data);
    },
  }),
});
