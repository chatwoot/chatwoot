import CaptainAssistantAPI from '../../api/captainAssistant';
import { createStore } from './storeFactory';

export default createStore({
  name: 'CaptainAssistant',
  API: CaptainAssistantAPI,
});
