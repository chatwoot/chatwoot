/* global axios */

import ApiClient from './ApiClient';

class Agents extends ApiClient {
  constructor() {
    super('agents', { accountScoped: true });
  }

  getTeams(id) {
    return axios.get(`${this.url}/${id}/teams`);
  }

  getInboxes(id) {
    return axios.get(`${this.url}/${id}/inboxes`);
  }

  bulkInvite({ emails }) {
    return axios.post(`${this.url}/bulk_create`, {
      emails,
    });
  }
}

export default new Agents();
