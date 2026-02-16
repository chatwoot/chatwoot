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

  // Add a text block document
  addTextBlock(assistantId, { title, content }) {
    return axios.post(`${this.url}/${assistantId}/documents`, {
      title,
      text_content: content,
    });
  }

  updateTextBlock(assistantId, documentId, { title, content }) {
    return axios.patch(`${this.url}/${assistantId}/documents/${documentId}`, {
      title,
      text_content: content,
    });
  }

  updateWebsite(
    assistantId,
    documentId,
    { title, autoRefresh, selectedPages }
  ) {
    return axios.patch(`${this.url}/${assistantId}/documents/${documentId}`, {
      title,
      auto_refresh: autoRefresh,
      selected_pages: selectedPages,
    });
  }

  // Discover available pages from a website URL
  discoverPages(assistantId, url) {
    return axios.post(`${this.url}/${assistantId}/documents/discover_pages`, {
      url,
    });
  }

  // Add website with selected pages (legacy: crawlFullSite for backward compatibility)
  addWebsite(
    assistantId,
    { url, title, crawlFullSite, selectedPages, autoRefresh }
  ) {
    return axios.post(`${this.url}/${assistantId}/documents`, {
      source_url: url,
      title,
      crawl_full_site: crawlFullSite,
      selected_pages: selectedPages,
      auto_refresh: autoRefresh,
    });
  }
}

export default new AlooDocument();
