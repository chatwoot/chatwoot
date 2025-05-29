import AiagentInboxes from 'dashboard/api/aiagent/inboxes';
import { createStore } from './storeFactory';
import { throwErrorMessage } from 'dashboard/store/utils/api';

export default createStore({
  name: 'AiagentInbox',
  API: AiagentInboxes,
  actions: mutations => ({
    delete: async function remove({ commit }, { inboxId, topicId }) {
      commit(mutations.SET_UI_FLAG, { deletingItem: true });
      try {
        await AiagentInboxes.delete({ inboxId, topicId });
        commit(mutations.DELETE, inboxId);
        commit(mutations.SET_UI_FLAG, { deletingItem: false });
        return inboxId;
      } catch (error) {
        commit(mutations.SET_UI_FLAG, { deletingItem: false });
        return throwErrorMessage(error);
      }
    },
  }),
});
