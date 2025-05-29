import AiagentDocumentAPI from 'dashboard/api/aiagent/document';
import { createStore } from './storeFactory';

export default createStore({
  name: 'AiagentDocument',
  API: AiagentDocumentAPI,
});
