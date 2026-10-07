/* global axios */
import ApiClient from '../ApiClient';

class CaptainResponses extends ApiClient {
  constructor() {
    super('captain/assistant_responses', { accountScoped: true });
  }

  get({ page = 1, search, assistantId, documentId, signal } = {}) {
    return axios.get(this.url, {
      params: {
        page,
        search,
        assistant_id: assistantId,
        document_id: documentId,
      },
      signal,
    });
  }

  getDrilldown({ responseId, page, signal }) {
    const requestConfig = { params: { page } };
    if (signal) requestConfig.signal = signal;

    return axios.get(`${this.url}/${responseId}/drilldown`, requestConfig);
  }
}

export default new CaptainResponses();
