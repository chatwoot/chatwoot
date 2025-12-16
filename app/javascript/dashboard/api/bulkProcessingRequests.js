/* global axios */
import ApiClient from './ApiClient';

class BulkProcessingRequestsAPI extends ApiClient {
  constructor() {
    super('bulk_processing_requests', { accountScoped: true });
  }

  getAll({ page = 1, per_page = 50, entity_type = undefined, operation_type = undefined, include_dismissed = undefined } = {}) {
    const params = { page, per_page };
    if (entity_type) {
      params.entity_type = entity_type;
    }
    if (operation_type) {
      params.operation_type = operation_type;
    }
    if (include_dismissed !== undefined) {
      params.include_dismissed = include_dismissed;
    }
    return axios.get(this.url, { params });
  }

  cancel(id) {
    return axios.post(`${this.url}/${id}/cancel`);
  }

  dismiss(id) {
    return axios.post(`${this.url}/${id}/dismiss`);
  }

  downloadErrors(id) {
    return axios.get(`${this.url}/${id}/download_errors`);
  }
}

export default new BulkProcessingRequestsAPI();
