import CaptainAssistantAPI from 'dashboard/api/captain/assistant';
import { createStore } from './storeFactory';

export default createStore({
  name: 'CaptainAssistant',
  API: CaptainAssistantAPI,
});
