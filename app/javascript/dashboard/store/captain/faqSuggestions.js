import CaptainFaqSuggestionsAPI from 'dashboard/api/captain/faqSuggestions';
import { createStore } from '../storeFactory';
import { throwErrorMessage } from 'dashboard/store/utils/api';

const SET_OPEN_COUNT = 'SET_OPEN_COUNT';
let openCountRequestId = 0;

export default createStore({
  name: 'CaptainFaqSuggestion',
  API: CaptainFaqSuggestionsAPI,
  getters: {
    getRecords: state => state.records,
    getOpenCount: state => state.meta.openCount || 0,
  },
  mutations: {
    [SET_OPEN_COUNT](state, count) {
      state.meta = {
        ...state.meta,
        openCount: Number(count),
      };
    },
  },
  actions: mutations => ({
    setFetchingList({ commit }, isFetching) {
      commit(mutations.SET_UI_FLAG, { fetchingList: isFetching });
    },
    setRecords({ commit }, { records, meta }) {
      commit(mutations.SET, records);
      commit(mutations.SET_META, meta);
    },
    approve: async ({ commit }, { id, question, answer }) => {
      commit(mutations.SET_UI_FLAG, { updatingItem: true });
      try {
        const response = await CaptainFaqSuggestionsAPI.approve(id, {
          question,
          answer,
        });
        commit(mutations.DELETE, id);
        return response.data;
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        commit(mutations.SET_UI_FLAG, { updatingItem: false });
      }
    },
    dismiss: async ({ commit }, id) => {
      commit(mutations.SET_UI_FLAG, { deletingItem: true });
      try {
        await CaptainFaqSuggestionsAPI.dismiss(id);
        commit(mutations.DELETE, id);
        return id;
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        commit(mutations.SET_UI_FLAG, { deletingItem: false });
      }
    },
    fetchOpenCount: async ({ commit }, assistantId) => {
      openCountRequestId += 1;
      const requestId = openCountRequestId;
      commit(SET_OPEN_COUNT, 0);

      try {
        const response = await CaptainFaqSuggestionsAPI.get({
          assistantId,
          page: 1,
        });
        if (requestId !== openCountRequestId) return;

        commit(SET_OPEN_COUNT, response.data?.meta?.total_count || 0);
      } catch {
        if (requestId === openCountRequestId) commit(SET_OPEN_COUNT, 0);
      }
    },
  }),
});
