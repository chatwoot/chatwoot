import CaptainDocumentAPI from 'dashboard/api/captain/document';
import { createStore } from '../storeFactory';

export default createStore({
  name: 'CaptainDocument',
  API: CaptainDocumentAPI,
  actions: mutations => ({
    removeBulkRecords({ commit, getters }, ids) {
      const records = getters.getRecords.filter(
        record => !ids.includes(record.id)
      );
      commit(mutations.SET, records);
    },
  }),
});
