import CaptainResponseAPI from 'dashboard/api/captain/response';
import { createStore } from './storeFactory';

export default createStore({
  name: 'CaptainResponse',
  API: CaptainResponseAPI,
  actions: mutations => ({
    deleteBulkResponse: ({ commit, state }, ids) => {
      const updatedRecords = state.records.filter(
        record => !ids.includes(record.id)
      );
      commit(mutations.SET, updatedRecords);
    },
  }),
});
