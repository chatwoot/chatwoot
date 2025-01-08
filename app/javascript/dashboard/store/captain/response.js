import CaptainResponseAPI from 'dashboard/api/captain/response';
import { createStore } from './storeFactory';

export default createStore({
  name: 'CaptainResponse',
  API: CaptainResponseAPI,
});
