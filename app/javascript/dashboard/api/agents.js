/* global axios */

import ApiClient from './ApiClient';

class Agents extends ApiClient {
  constructor() {
    super('agents', { accountScoped: true });
  }

  bulkInvite({ emails }) {
    return axios.post(`${this.url}/bulk_create`, {
      emails,
    });
  }

  newStringeeToken(id) {
    return axios.get(`${this.url}/${id}/new_stringee_token`);
  }
}

export default new Agents();
