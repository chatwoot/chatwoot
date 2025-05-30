import AiAgentTopicAPI from 'dashboard/api/ai_agent/topic';
import { createStore } from '../captain/storeFactory';

export default createStore({
  name: 'aiAgentTopics',
  API: AiAgentTopicAPI,
});
