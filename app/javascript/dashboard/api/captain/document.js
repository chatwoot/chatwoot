/* global axios */
import ApiClient from '../ApiClient';

class CaptainDocument extends ApiClient {
  constructor() {
    super('captain/documents', { accountScoped: true });
  }

  get({ page = 1, searchKey, assistantId } = {}) {
    return axios.get(this.url, {
      params: {
        page,
        searchKey,
        assistant_id: assistantId,
      },
    });
  }

  uploadPdf(formData) {
    return axios.post(`${this.url}/upload_pdf`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
  }
}

export default new CaptainDocument();
