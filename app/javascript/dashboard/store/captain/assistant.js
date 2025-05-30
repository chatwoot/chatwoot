import AiAgentTopicAPI from 'dashboard/api/ai_agent/topic';
import { createStore } from './storeFactory';

export default createStore({
  name: 'AiAgentTopic',
  API: AiAgentTopicAPI,
});
