import CaptainAssistantAPI from 'dashboard/api/captain/assistant';
import { createStore } from '../storeFactory';
import { throwErrorMessage } from 'dashboard/store/utils/api';

export default createStore({
  name: 'CaptainAssistant',
  API: CaptainAssistantAPI,
  actions: mutationTypes => ({
    uploadAvatar: async ({ commit }, { id, file }) => {
      try {
        const { data } = await CaptainAssistantAPI.uploadAvatar(id, file);
        commit(mutationTypes.EDIT, data);
      } catch (error) {
        throwErrorMessage(error);
      }
    },
    deleteAvatar: async ({ commit }, id) => {
      try {
        const { data } = await CaptainAssistantAPI.deleteAvatar(id);
        commit(mutationTypes.EDIT, data);
      } catch (error) {
        throwErrorMessage(error);
      }
    },
  }),
});
