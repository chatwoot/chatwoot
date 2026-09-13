/* global axios */
import ApiClient from '../ApiClient';

class AproposSessions extends ApiClient {
  constructor() {
    super('captain/apropos_sessions', { accountScoped: true });
  }

  list(config) {
    return axios.get(this.url, config);
  }

  read(id, config) {
    return axios.get(`${this.url}/${id}`, config);
  }
}

export default new AproposSessions();
