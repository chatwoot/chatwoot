import CaptainResponseAPI from 'dashboard/api/captain/response';
import { createStore } from '../storeFactory';

const SET_PENDING_COUNT = 'SET_PENDING_COUNT';

export default createStore({
  name: 'CaptainResponse',
  API: CaptainResponseAPI,
  getters: {
    getPendingCount: state => state.meta.pendingCount || 0,
  },
  mutations: {
    [SET_PENDING_COUNT](state, count) {
      state.meta = {
        ...state.meta,
        pendingCount: Number(count),
      };
    },
  },
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
    fetchPendingCount: async ({ commit }, assistantId) => {
      try {
        const response = await CaptainResponseAPI.get({
          status: 'pending',
          page: 1,
          assistantId,
        });
        const count = response.data?.meta?.total_count || 0;
        commit(SET_PENDING_COUNT, count);
      } catch (error) {
        commit(SET_PENDING_COUNT, 0);
      }
    },
  }),
});
