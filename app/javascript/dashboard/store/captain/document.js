import CaptainDocumentAPI from 'dashboard/api/captain/document';
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import { createStore } from '../storeFactory';

const UPDATE_FROM_ACTION_CABLE = 'UPDATE_CAPTAIN_DOCUMENT_FROM_ACTION_CABLE';

export default createStore({
  name: 'CaptainDocument',
  API: CaptainDocumentAPI,
  mutations: {
    [UPDATE_FROM_ACTION_CABLE]: MutationHelpers.updateAttributes,
  },
  actions: () => ({
    updateFromActionCable({ commit }, data) {
      commit(UPDATE_FROM_ACTION_CABLE, data);
    },
  }),
});
