/* global axios */
import ApiClient from './ApiClient';

class DataExportsAPI extends ApiClient {
  constructor() {
    super('data_exports', { accountScoped: true });
  }

  get({ beforeId } = {}) {
    return axios.get(this.url, { params: { before_id: beforeId } });
  }

  download(id) {
    return axios.get(`${this.url}/${id}/download`);
  }

  rerun(id) {
    return axios.post(`${this.url}/${id}/rerun`);
  }
}

export default new DataExportsAPI();
