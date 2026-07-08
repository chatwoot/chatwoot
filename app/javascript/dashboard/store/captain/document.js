import CaptainDocumentAPI from 'dashboard/api/captain/document';
import { throwErrorMessage } from 'dashboard/store/utils/api';
import { createStore } from '../storeFactory';

const SYNCING_STATE = 'syncing';

const markRecordsSyncing = (records, ids) => {
  const idSet = new Set(ids);
  return records.map(record =>
    idSet.has(record.id)
      ? {
          ...record,
          sync_status: SYNCING_STATE,
          sync_in_progress: true,
          last_sync_attempted_at: Math.floor(Date.now() / 1000),
          last_sync_error_code: null,
        }
      : record
  );
};

export default createStore({
  name: 'CaptainDocument',
  API: CaptainDocumentAPI,
  getters: {
    getRecords: state => state.records,
  },
  actions: mutations => ({
    setFetchingList({ commit }, isFetching) {
      commit(mutations.SET_UI_FLAG, { fetchingList: isFetching });
    },
    setRecords({ commit }, { records, meta }) {
      commit(mutations.SET, records);
      commit(mutations.SET_META, meta);
    },
    removeBulkRecords({ commit, getters }, ids) {
      const records = getters.getRecords.filter(
        record => !ids.includes(record.id)
      );
      commit(mutations.SET, records);
    },
    markSyncing({ commit, getters }, ids) {
      commit(mutations.SET, markRecordsSyncing(getters.getRecords, ids));
    },
    async sync({ dispatch }, id) {
      try {
        await CaptainDocumentAPI.sync(id);
        dispatch('markSyncing', [id]);
        return id;
      } catch (error) {
        return throwErrorMessage(error);
      }
    },
  }),
});
