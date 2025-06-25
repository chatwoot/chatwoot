import CaptainDocumentAPI from 'dashboard/api/captain/document';
import { createStore } from './storeFactory';

const actions = mutationTypes => ({
  async uploadPdf({ commit }, formData) {
    commit(mutationTypes.SET_UI_FLAG, { creatingItem: true });
    try {
      const response = await CaptainDocumentAPI.uploadPdf(formData);
      const { data } = response;
      commit(mutationTypes.ADD, data.document);
      commit(mutationTypes.SET_UI_FLAG, { creatingItem: false });
      return Promise.resolve(data);
    } catch (error) {
      commit(mutationTypes.SET_UI_FLAG, { creatingItem: false });
      return Promise.reject(error);
    }
  },
});

export default createStore({
  name: 'CaptainDocument',
  API: CaptainDocumentAPI,
  actions,
});
