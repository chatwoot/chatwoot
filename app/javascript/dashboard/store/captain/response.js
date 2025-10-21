import CaptainResponseAPI from 'dashboard/api/captain/response';
import { createStore } from './storeFactory';

export default createStore({
  name: 'CaptainResponse',
  API: CaptainResponseAPI,
  actions: mutations => ({
    removeBulkResponses: ({ commit, state }, ids) => {
      const updatedRecords = state.records.filter(
        record => !ids.includes(record.id)
      );
      commit(mutations.SET, updatedRecords);
    },
    updateBulkResponses: ({ commit, state }, approvedResponses) => {
      // Create a map of updated responses for faster lookup
      const updatedResponsesMap = approvedResponses.reduce((map, response) => {
        map[response.id] = response;
        return map;
      }, {});

      // Update existing records with updated data
      const updatedRecords = state.records.map(record => {
        if (updatedResponsesMap[record.id]) {
          return updatedResponsesMap[record.id]; // Replace with the updated response
        }
        return record;
      });

      commit(mutations.SET, updatedRecords);
    },
  }),
});
