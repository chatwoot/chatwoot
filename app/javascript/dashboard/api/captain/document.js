/* global axios */
import ApiClient from '../ApiClient';

class CaptainDocument extends ApiClient {
  constructor() {
    super('captain/documents', { accountScoped: true });
  }

  get({ page = 1, searchKey, assistantId, filter, source, sort } = {}) {
    return axios.get(this.url, {
      params: {
        page,
        search_key: searchKey,
        assistant_id: assistantId,
        filter,
        source,
        sort,
      },
    });
  }

  sync(id) {
    return axios.post(`${this.url}/${id}/sync`);
  }

  getDrilldown({ documentId, page, signal }) {
    const requestConfig = { params: { page } };
    if (signal) requestConfig.signal = signal;

    return axios.get(`${this.url}/${documentId}/drilldown`, requestConfig);
  }
}

export default new CaptainDocument();
