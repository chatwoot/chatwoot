/* global axios */

const API_VERSION = `/api/v1`;

class ApiClient {
  constructor(url) {
    this.apiVersion = API_VERSION;
    this.url = `${this.apiVersion}/${url}`;
  }

  get() {
    return axios.get(this.url);
  }

  show(id) {
    return axios.get(`${this.url}/${id}`);
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

export default ApiClient;
