import CopilotThreadsAPI from 'dashboard/api/captain/copilotThreads';
import { createStore } from '../storeFactory';

export default createStore({
  name: 'CopilotThreads',
  API: CopilotThreadsAPI,
  actions: () => ({
    async getPage(_, params) {
      const { data } = await CopilotThreadsAPI.get(params);
      return data;
    },
  }),
});
