import CopilotMessagesAPI from 'dashboard/api/captain/copilotMessages';
import { throwErrorMessage } from 'dashboard/store/utils/api';
import { setSingleRecord } from 'shared/helpers/vuex/mutationHelpers';
import { createStore, generateMutationTypes } from '../storeFactory';

const { UPSERT } = generateMutationTypes('CopilotMessages');

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
  mutations: {
    // A thread read that started before an approval can answer after it. Like conversations, a copy older than the
    // one held is ignored, so a decided card doesn't show Approve and Reject again.
    [UPSERT](state, message) {
      const held = state.records.find(record => record.id === message.id);
      if (held && message.updated_at < held.updated_at) return;
      setSingleRecord(state, message);
    },
  },
  actions: mutationTypes => ({
    // Merges by ID, so a saved approval status and any message the panel missed replace what it holds, and other
    // threads stay as they are.
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
