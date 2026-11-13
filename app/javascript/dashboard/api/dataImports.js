/* global axios */

import ApiClient from './ApiClient';

class DataImportsAPI extends ApiClient {
  constructor() {
    super('data_imports', { accountScoped: true });
  }

  start(id) {
    return axios.post(`${this.url}/${id}/start`);
  }

  retry(id) {
    return axios.post(`${this.url}/${id}/retry`);
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

  createFile(payload, onUploadProgress) {
    const form = new FormData();
    form.append('source_provider', 'csv');
    form.append('import_types[]', 'contacts');
    form.append('name', payload.name);
    form.append('import_file', payload.file);
    return axios.post(this.url, form, { onUploadProgress });
  }

  downloadRejectedRows(id) {
    return axios.get(`${this.url}/${id}/rejected_rows`);
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
