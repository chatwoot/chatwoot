import CaptainWorkflows from 'dashboard/api/captain/workflows';
import { createStore } from '../storeFactory';
import { throwErrorMessage } from 'dashboard/store/utils/api';

export default createStore({
  name: 'CaptainWorkflow',
  API: CaptainWorkflows,
  actions: mutations => ({
    get: async ({ commit }, { assistantId, page = 1 } = {}) => {
      commit(mutations.SET_UI_FLAG, { fetchingList: true });
      try {
        const response = await CaptainWorkflows.get({ assistantId, page });
        commit(mutations.SET, response.data.payload);
        commit(mutations.SET_META, response.data.meta);
        commit(mutations.SET_UI_FLAG, { fetchingList: false });
        return response.data;
      } catch (error) {
        commit(mutations.SET_UI_FLAG, { fetchingList: false });
        return throwErrorMessage(error);
      }
    },

    show: async ({ commit }, { assistantId, id }) => {
      commit(mutations.SET_UI_FLAG, { fetchingItem: true });
      try {
        const response = await CaptainWorkflows.show({ assistantId, id });
        commit(mutations.ADD, response.data);
        commit(mutations.SET_UI_FLAG, { fetchingItem: false });
        return response.data;
      } catch (error) {
        commit(mutations.SET_UI_FLAG, { fetchingItem: false });
        return throwErrorMessage(error);
      }
    },

    create: async ({ commit }, { assistantId, ...data }) => {
      commit(mutations.SET_UI_FLAG, { creatingItem: true });
      try {
        const response = await CaptainWorkflows.create({
          assistantId,
          ...data,
        });
        commit(mutations.ADD, response.data);
        commit(mutations.SET_UI_FLAG, { creatingItem: false });
        return response.data;
      } catch (error) {
        commit(mutations.SET_UI_FLAG, { creatingItem: false });
        return throwErrorMessage(error);
      }
    },

    update: async ({ commit }, { id, assistantId, ...updateObj }) => {
      commit(mutations.SET_UI_FLAG, { updatingItem: true });
      try {
        const response = await CaptainWorkflows.update(
          { id, assistantId },
          updateObj
        );
        commit(mutations.EDIT, response.data);
        commit(mutations.SET_UI_FLAG, { updatingItem: false });
        return response.data;
      } catch (error) {
        commit(mutations.SET_UI_FLAG, { updatingItem: false });
        return throwErrorMessage(error);
      }
    },

    delete: async ({ commit }, { id, assistantId }) => {
      commit(mutations.SET_UI_FLAG, { deletingItem: true });
      try {
        await CaptainWorkflows.delete({ id, assistantId });
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
