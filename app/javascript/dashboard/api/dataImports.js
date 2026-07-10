/* global axios */

import ApiClient from './ApiClient';

class DataImportsAPI extends ApiClient {
  constructor() {
    super('data_imports', { accountScoped: true });
  }

  start(id) {
    return axios.post(`${this.url}/${id}/start`);
  }

  abandon(id) {
    return axios.post(`${this.url}/${id}/abandon`);
  }

  show(id, params = {}) {
    return axios.get(`${this.url}/${id}`, { params });
  }

  validateSource(payload) {
    return axios.post(`${this.url}/validate_source`, payload);
  }

  downloadSkipLogs(id) {
    return axios.get(`${this.url}/${id}/skip_logs.csv`, {
      responseType: 'blob',
    });
  }

  downloadErrorLogs(id) {
    return axios.get(`${this.url}/${id}/error_logs.csv`, {
      responseType: 'blob',
    });
  }
}

export default new DataImportsAPI();
