import AlooDocumentAPI from 'dashboard/api/aloo/document';
import { createStore } from '../storeFactory';

export default createStore({
  name: 'AlooDocument',
  API: AlooDocumentAPI,
  actions: mutationTypes => ({
    async getDocuments({ commit }, { assistantId, page = 1 }) {
      commit(mutationTypes.SET_UI_FLAG, { fetchingList: true });
      try {
        const response = await AlooDocumentAPI.getDocuments(assistantId, {
          page,
        });
        commit(mutationTypes.SET, response.data.payload || response.data);
        if (response.data.meta) {
          commit(mutationTypes.SET_META, response.data.meta);
        }
        return response.data;
      } finally {
        commit(mutationTypes.SET_UI_FLAG, { fetchingList: false });
      }
    },
    async uploadDocument({ commit }, { assistantId, formData }) {
      commit(mutationTypes.SET_UI_FLAG, { creatingItem: true });
      try {
        const response = await AlooDocumentAPI.uploadDocument(
          assistantId,
          formData
        );
        commit(mutationTypes.ADD, response.data);
        return response.data;
      } finally {
        commit(mutationTypes.SET_UI_FLAG, { creatingItem: false });
      }
    },
    async deleteDocument({ commit }, { assistantId, documentId }) {
      commit(mutationTypes.SET_UI_FLAG, { deletingItem: true });
      try {
        await AlooDocumentAPI.deleteDocument(assistantId, documentId);
        commit(mutationTypes.DELETE, documentId);
        return documentId;
      } finally {
        commit(mutationTypes.SET_UI_FLAG, { deletingItem: false });
      }
    },
    async reprocessDocument({ commit }, { assistantId, documentId }) {
      commit(mutationTypes.SET_UI_FLAG, { updatingItem: true });
      try {
        const response = await AlooDocumentAPI.reprocessDocument(
          assistantId,
          documentId
        );
        commit(mutationTypes.EDIT, response.data);
        return response.data;
      } finally {
        commit(mutationTypes.SET_UI_FLAG, { updatingItem: false });
      }
    },
    async addWebsite({ commit }, { assistantId, url, title, crawlFullSite }) {
      commit(mutationTypes.SET_UI_FLAG, { creatingItem: true });
      try {
        const response = await AlooDocumentAPI.addWebsite(assistantId, {
          url,
          title,
          crawlFullSite,
        });
        commit(mutationTypes.ADD, response.data);
        return response.data;
      } finally {
        commit(mutationTypes.SET_UI_FLAG, { creatingItem: false });
      }
    },
  }),
});
