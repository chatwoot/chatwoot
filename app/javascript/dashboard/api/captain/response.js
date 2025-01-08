/* global axios */
import ApiClient from '../ApiClient';

class CaptainResponses extends ApiClient {
  constructor() {
    super('captain/assistant_responses', { accountScoped: true });
  }

  get({ searchKey } = {}) {
    const url = searchKey ? `${this.url}?search=${searchKey}` : this.url;
    return axios.get(url);
  }

  create(data) {
    return axios.post(this.url, data);
  }

  update(id, data) {
    return axios.patch(`${this.url}/${id}`, data);
  }

  delete(id) {
    return axios.delete(`${this.url}/${id}`);
  }
}

export default new CaptainResponses();
