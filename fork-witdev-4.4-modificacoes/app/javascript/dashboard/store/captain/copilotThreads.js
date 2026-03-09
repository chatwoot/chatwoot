import CopilotThreadsAPI from 'dashboard/api/captain/copilotThreads';
import { createStore } from './storeFactory';

export default createStore({
  name: 'CopilotThreads',
  API: CopilotThreadsAPI,
});
