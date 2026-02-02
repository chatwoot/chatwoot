import CaptainAssistantMcpServers from 'dashboard/api/captain/assistantMcpServers';
import { createStore } from '../storeFactory';
import { throwErrorMessage } from 'dashboard/store/utils/api';

export default createStore({
  name: 'CaptainAssistantMcpServer',
  API: CaptainAssistantMcpServers,
  actions: mutations => ({
    update: async ({ commit }, { assistantId, id, ...updateObj }) => {
      commit(mutations.SET_UI_FLAG, { updatingItem: true });
      try {
        const response = await CaptainAssistantMcpServers.update(
          assistantId,
          id,
          {
            assistant_mcp_server: updateObj,
          }
        );
        commit(mutations.EDIT, response.data);
        commit(mutations.SET_UI_FLAG, { updatingItem: false });
        return response.data;
      } catch (error) {
        commit(mutations.SET_UI_FLAG, { updatingItem: false });
        return throwErrorMessage(error);
      }
    },

    delete: async ({ commit }, { assistantId, id }) => {
      commit(mutations.SET_UI_FLAG, { deletingItem: true });
      try {
        await CaptainAssistantMcpServers.delete(assistantId, id);
        commit(mutations.DELETE, id);
        commit(mutations.SET_UI_FLAG, { deletingItem: false });
        return id;
      } catch (error) {
        commit(mutations.SET_UI_FLAG, { deletingItem: false });
        return throwErrorMessage(error);
      }
    },
  }),
});
