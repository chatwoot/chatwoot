/* global axios */
import ApiClient from './ApiClient';

class BulkProcessingRequestsAPI extends ApiClient {
  constructor() {
    super('bulk_processing_requests', { accountScoped: true });
  }

  cancel(id) {
    return axios.post(`${this.url}/${id}/cancel`);
  }

  downloadErrors(id) {
    return axios.get(`${this.url}/${id}/download_errors`);
  }
}

export default new BulkProcessingRequestsAPI();
