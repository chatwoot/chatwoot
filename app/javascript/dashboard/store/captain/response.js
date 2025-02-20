import CaptainResponseAPI from 'dashboard/api/captain/response';
import { createStore } from './storeFactory';

export default createStore({
  name: 'CaptainResponse',
  API: CaptainResponseAPI,
  actions: mutations => ({
    // Response bulk actions
    deleteBulkResponse: ({ commit, state }, ids) => {
      const updatedRecords = state.records.filter(
        record => !ids.includes(record.id)
      );
      commit(mutations.SET, updatedRecords);
    },
    approveBulkResponse: ({ commit, state }, ids) => {
      const updatedRecords = state.records.map(record => {
        if (ids.includes(record.id) && record.status === 'pending') {
          return { ...record, status: 'approved' };
        }
        return record;
      });
      commit(mutations.SET, updatedRecords);
    },
  }),
});
