import CopilotMessagesAPI from 'dashboard/api/captain/copilotMessages';
import { throwErrorMessage } from 'dashboard/store/utils/api';
import { createStore } from '../storeFactory';

let accountVersion = 0;
let activeAccountId = null;

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
    reset({ commit }, accountId) {
      accountVersion += 1;
      activeAccountId = Number(accountId) || null;
      commit(mutationTypes.SET, []);
      commit(mutationTypes.SET_META, {});
      commit(mutationTypes.SET_UI_FLAG, {
        fetchingList: false,
        creatingItem: false,
      });
    },
    async get({ commit, state }, { threadId, accountId }) {
      const version = accountVersion;
      commit(mutationTypes.SET_UI_FLAG, { fetchingList: true });
      try {
        const messages = [];
        let page = 1;
        let meta;
        do {
          // Fetch the next page only after the previous page establishes the remaining count.
          // eslint-disable-next-line no-await-in-loop
          const response = await CopilotMessagesAPI.get(threadId, { page });
          if (version !== accountVersion) return [];

          messages.push(...response.data.payload);
          meta = response.data.meta;
          page += 1;
          if (!response.data.payload.length) break;
        } while (messages.length < meta.total_count);

        const recordsById = new Map(
          state.records
            .filter(record => Number(record.account_id) === Number(accountId))
            .map(record => [record.id, record])
        );
        messages.forEach(message => recordsById.set(message.id, message));
        commit(mutationTypes.SET, [...recordsById.values()]);
        commit(mutationTypes.SET_META, meta);
        return messages;
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        if (version === accountVersion) {
          commit(mutationTypes.SET_UI_FLAG, { fetchingList: false });
        }
      }
    },
    async create({ commit }, data) {
      const version = accountVersion;
      commit(mutationTypes.SET_UI_FLAG, { creatingItem: true });
      try {
        const response = await CopilotMessagesAPI.create(data);
        const message = response.data;
        const messageAccountId =
          message.account_id || message.copilot_thread?.account_id;
        if (
          version === accountVersion &&
          Number(messageAccountId) === activeAccountId
        ) {
          commit(mutationTypes.UPSERT, message);
        }
        return message;
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        if (version === accountVersion) {
          commit(mutationTypes.SET_UI_FLAG, { creatingItem: false });
        }
      }
    },
    upsert({ commit }, data) {
      const messageAccountId =
        data.account_id || data.copilot_thread?.account_id;
      if (
        activeAccountId &&
        Number(messageAccountId) !== Number(activeAccountId)
      ) {
        return;
      }

      commit(mutationTypes.UPSERT, data);
    },
  }),
});
