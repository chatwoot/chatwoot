import CaptainInboxes from 'dashboard/api/captain/inboxes';
import { createStore } from './storeFactory';

export default createStore({
  name: 'CaptainInbox',
  API: CaptainInboxes,
});
