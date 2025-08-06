/* global axios */
import ApiClient from '../ApiClient';

class PdfDocumentsAPI extends ApiClient {
  constructor() {
    super('portals', { accountScoped: true });
  }

  uploadContent(portalSlug, formData) {
    return axios.post(`${this.url}/${portalSlug}/upload_content`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
  }

  getGeneratedContent(portalSlug) {
    return axios.get(`${this.url}/${portalSlug}/generated_content`);
  }

  publishContent(portalSlug, responseIds, categoryId = null) {
    return axios.post(`${this.url}/${portalSlug}/publish_content`, {
      response_ids: responseIds,
      category_id: categoryId
    });
  }
}

export default PdfDocumentsAPI;