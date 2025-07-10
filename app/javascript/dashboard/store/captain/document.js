import CaptainDocumentAPI from 'dashboard/api/captain/document';
import { createStore } from './storeFactory';

// Constants
const DOCUMENT_TYPE = {
  PDF: 'pdf',
  URL: 'url',
};

const FORM_DATA_FIELDS = {
  PDF_DOCUMENT: 'pdf_document',
  ASSISTANT_ID: 'assistant_id',
};

const actions = mutationTypes => ({
  async uploadPdf({ commit }, { pdf_document, assistant_id }) {
    commit(mutationTypes.SET_UI_FLAG, { creatingItem: true });
    try {
      const formData = new FormData();
      formData.append(FORM_DATA_FIELDS.PDF_DOCUMENT, pdf_document);
      formData.append(FORM_DATA_FIELDS.ASSISTANT_ID, assistant_id);

      const response = await CaptainDocumentAPI.uploadPdf(formData);
      const { data } = response;
      // Use UPSERT like the create action for consistency
      commit(mutationTypes.UPSERT, data);
      commit(mutationTypes.SET_UI_FLAG, { creatingItem: false });
      return Promise.resolve(data);
    } catch (error) {
      commit(mutationTypes.SET_UI_FLAG, { creatingItem: false });
      return Promise.reject(error);
    }
  },

  async createDocument({ dispatch }, documentData) {
    // Unified method to handle both URL and PDF document creation
    if (documentData.type === DOCUMENT_TYPE.PDF) {
      return dispatch('uploadPdf', {
        pdf_document: documentData.pdf_document,
        assistant_id: documentData.assistant_id,
      });
    }
    // URL creation uses the standard create action from storeFactory
    return dispatch('create', {
      document: {
        external_link: documentData.external_link,
        assistant_id: documentData.assistant_id,
      },
    });
  },
});

export default createStore({
  name: 'CaptainDocument',
  API: CaptainDocumentAPI,
  actions,
});
