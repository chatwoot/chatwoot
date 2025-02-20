import CaptainBulkActionsAPI from 'dashboard/api/captain/bulkActions';
import { createStore } from './storeFactory';
import { throwErrorMessage } from 'dashboard/store/utils/api';

export default createStore({
  name: 'CaptainBulkAction',
  API: CaptainBulkActionsAPI,
  actions: mutations => ({
    process: async function processAction({ commit }, payload) {
      commit(mutations.SET_UI_FLAG, { isUpdating: true });
      try {
        const response = await CaptainBulkActionsAPI.create(payload);
        commit(mutations.SET_UI_FLAG, { isUpdating: false });
        return response.data;
      } catch (error) {
        commit(mutations.SET_UI_FLAG, { isUpdating: false });
        return throwErrorMessage(error);
      }
    },

    handleBulkDelete: async function handleBulkDelete({ dispatch }, ids) {
      await dispatch('captainResponses/deleteBulkResponse', ids, {
        root: true,
      });
    },
  }),
});
