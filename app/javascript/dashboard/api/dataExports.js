/* global axios */
import ApiClient from './ApiClient';

class DataExportsAPI extends ApiClient {
  constructor() {
    super('data_exports', { accountScoped: true });
  }

  download(id) {
    return axios.get(`${this.url}/${id}/download`);
  }

  rerun(id) {
    return axios.post(`${this.url}/${id}/rerun`);
  }
}

export default new DataExportsAPI();
