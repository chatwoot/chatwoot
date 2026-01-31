import CaptainMcpServers from 'dashboard/api/captain/mcpServers';
import { createStore } from '../storeFactory';
import { throwErrorMessage } from 'dashboard/store/utils/api';

export default createStore({
  name: 'CaptainMcpServer',
  API: CaptainMcpServers,
  actions: mutations => ({
    update: async ({ commit }, { id, ...updateObj }) => {
      commit(mutations.SET_UI_FLAG, { updatingItem: true });
      try {
        const response = await CaptainMcpServers.update(id, updateObj);
        commit(mutations.EDIT, response.data);
        commit(mutations.SET_UI_FLAG, { updatingItem: false });
        return response.data;
      } catch (error) {
        commit(mutations.SET_UI_FLAG, { updatingItem: false });
        return throwErrorMessage(error);
      }
    },

    delete: async ({ commit }, id) => {
      commit(mutations.SET_UI_FLAG, { deletingItem: true });
      try {
        await CaptainMcpServers.delete(id);
        commit(mutations.DELETE, id);
        commit(mutations.SET_UI_FLAG, { deletingItem: false });
        return id;
      } catch (error) {
        commit(mutations.SET_UI_FLAG, { deletingItem: false });
        return throwErrorMessage(error);
      }
    },

    connect: async ({ commit }, id) => {
      commit(mutations.SET_UI_FLAG, { updatingItem: true });
      try {
        const response = await CaptainMcpServers.connect(id);
        // Refetch to get updated cached_tools
        const serverResponse = await CaptainMcpServers.show(id);
        commit(mutations.EDIT, serverResponse.data);
        commit(mutations.SET_UI_FLAG, { updatingItem: false });
        return response.data;
      } catch (error) {
        commit(mutations.SET_UI_FLAG, { updatingItem: false });
        return throwErrorMessage(error);
      }
    },

    disconnect: async ({ commit }, id) => {
      commit(mutations.SET_UI_FLAG, { updatingItem: true });
      try {
        const response = await CaptainMcpServers.disconnect(id);
        const serverResponse = await CaptainMcpServers.show(id);
        commit(mutations.EDIT, serverResponse.data);
        commit(mutations.SET_UI_FLAG, { updatingItem: false });
        return response.data;
      } catch (error) {
        commit(mutations.SET_UI_FLAG, { updatingItem: false });
        return throwErrorMessage(error);
      }
    },

    refresh: async ({ commit }, id) => {
      commit(mutations.SET_UI_FLAG, { updatingItem: true });
      try {
        const response = await CaptainMcpServers.refresh(id);
        commit(mutations.EDIT, response.data);
        commit(mutations.SET_UI_FLAG, { updatingItem: false });
        return response.data;
      } catch (error) {
        commit(mutations.SET_UI_FLAG, { updatingItem: false });
        return throwErrorMessage(error);
      }
    },
  }),
});
