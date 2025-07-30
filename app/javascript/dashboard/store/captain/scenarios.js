import CaptainScenarios from 'dashboard/api/captain/scenarios';
import { createStore } from './storeFactory';
import { throwErrorMessage } from 'dashboard/store/utils/api';

export default createStore({
  name: 'CaptainScenario',
  API: CaptainScenarios,
  actions: mutations => ({
    update: async ({ commit }, { id, assistantId, ...updateObj }) => {
      commit(mutations.SET_UI_FLAG, { updatingItem: true });
      try {
        const response = await CaptainScenarios.update(
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
        await CaptainScenarios.delete({ id, assistantId });
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
