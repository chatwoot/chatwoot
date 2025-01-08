import CaptainResponseAPI from '../../api/captainResponse';
import { createStore } from './storeFactory';

export default createStore({
  name: 'CaptainResponse',
  API: CaptainResponseAPI,
});
