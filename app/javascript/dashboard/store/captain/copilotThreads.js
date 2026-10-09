import CopilotThreadsAPI from 'dashboard/api/captain/copilotThreads';
import { throwErrorMessage } from 'dashboard/store/utils/api';
import { createStore } from '../storeFactory';

let accountVersion = 0;
let activeAccountId = null;

export default createStore({
  name: 'CopilotThreads',
  API: CopilotThreadsAPI,
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
    async create({ commit }, data) {
      const version = accountVersion;
      commit(mutationTypes.SET_UI_FLAG, { creatingItem: true });
      try {
        const response = await CopilotThreadsAPI.create(data);
        const thread = response.data;
        if (
          version === accountVersion &&
          Number(thread.account_id) === activeAccountId
        ) {
          commit(mutationTypes.UPSERT, thread);
        }
        return thread;
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        if (version === accountVersion) {
          commit(mutationTypes.SET_UI_FLAG, { creatingItem: false });
        }
      }
    },
  }),
});
