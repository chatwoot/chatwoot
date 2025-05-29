import AiagentAssistantAPI from 'dashboard/api/aiagent/assistant';
import { createStore } from './storeFactory';

export default createStore({
  name: 'AiagentAssistant',
  API: AiagentAssistantAPI,
});
