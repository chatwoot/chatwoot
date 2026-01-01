/* global axios */
import ApiClient from '../ApiClient';

class AlooDocument extends ApiClient {
  constructor() {
    super('aloo/assistants', { accountScoped: true });
  }

  getDocuments(assistantId, { page = 1 } = {}) {
    return axios.get(`${this.url}/${assistantId}/documents`, {
      params: { page },
    });
  }

  getDocument(assistantId, documentId) {
    return axios.get(`${this.url}/${assistantId}/documents/${documentId}`);
  }

  uploadDocument(assistantId, formData) {
    return axios.post(`${this.url}/${assistantId}/documents`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  }

  deleteDocument(assistantId, documentId) {
    return axios.delete(`${this.url}/${assistantId}/documents/${documentId}`);
  }

  reprocessDocument(assistantId, documentId) {
    return axios.post(
      `${this.url}/${assistantId}/documents/${documentId}/reprocess`
    );
  }

  addWebsite(assistantId, { url, title, crawlFullSite }) {
    return axios.post(`${this.url}/${assistantId}/documents`, {
      source_url: url,
      title,
      crawl_full_site: crawlFullSite,
    });
  }
}

export default new AlooDocument();
