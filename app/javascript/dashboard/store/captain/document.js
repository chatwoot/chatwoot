import CaptainDocumentAPI from '../../api/captainDocument';
import { createStore } from './storeFactory';

export default createStore({
  name: 'CaptainDocument',
  API: CaptainDocumentAPI,
});
