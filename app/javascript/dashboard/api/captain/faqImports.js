/* global axios */
import ApiClient from '../ApiClient';

class CaptainFaqImports extends ApiClient {
  constructor() {
    super('captain/assistants', { accountScoped: true });
  }

  getUrl(assistantId) {
    return `${this.url}/${assistantId}/faq_imports`;
  }

  create({ assistantId, file }) {
    const formData = new FormData();
    formData.append('file', file);

    return axios.post(this.getUrl(assistantId), formData);
  }

  confirm({ assistantId, importId, overwriteRowNumbers = [] }) {
    return axios.post(`${this.getUrl(assistantId)}/${importId}/confirm`, {
      overwrite_row_numbers: overwriteRowNumbers,
    });
  }

  latest({ assistantId, signal } = {}) {
    return axios.get(`${this.getUrl(assistantId)}/latest`, { signal });
  }

  downloadInvalidRows({ assistantId, importId }) {
    return axios.get(`${this.getUrl(assistantId)}/${importId}/invalid_rows`, {
      responseType: 'blob',
    });
  }
}

export default new CaptainFaqImports();
