/* global axios */
import ApiClient from '../ApiClient';

class CaptainAssistant extends ApiClient {
  constructor() {
    super('captain/assistants', { accountScoped: true });
  }

  get({ page = 1, searchKey } = {}) {
    return axios.get(this.url, {
      params: {
        page,
        searchKey,
      },
    });
  }

  getAll() {
    return axios.get(this.url, {
      params: {
        per_page: 100, // Get a large number to ensure we get all assistants
      },
    });
  }
}

export default new CaptainAssistant();
