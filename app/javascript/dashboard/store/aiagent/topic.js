import AiagentTopicAPI from 'dashboard/api/aiagent/topic';
import { createStore } from './storeFactory';

export default createStore({
  name: 'AiagentTopic',
  API: AiagentTopicAPI,
});
