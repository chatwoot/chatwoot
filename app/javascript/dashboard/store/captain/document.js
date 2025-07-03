import CaptainDocumentAPI from 'dashboard/api/captain/document';
import { createStore } from './storeFactory';

export default createStore({
  name: 'CaptainDocument',
  API: CaptainDocumentAPI,
});
