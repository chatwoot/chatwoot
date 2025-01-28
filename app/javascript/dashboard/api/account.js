/* global axios */
import ApiClient from './ApiClient';

class AccountAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: true });
  }

  createAccount(data) {
    return axios.post(`${this.apiVersion}/accounts`, data);
  }

  async getCacheKeys() {
    const response = await axios.get(
      `/api/v1/accounts/${this.accountIdFromRoute}/cache_keys`
    );
    return response.data.cache_keys;
  }

  async assignUnassignedConversations(inboxIds) {
    return axios.post(
      `/api/v1/accounts/${this.accountIdFromRoute}/unassigned_conversations_assignment`,
      { inbox_ids: inboxIds }
    );
  }

  async createOneClickConversations(payload) {
    const url = `/api/v1/accounts/${this.accountIdFromRoute}/create_one_click_conversations`;

    return axios.post(url, payload, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
  }
}

export default new AccountAPI();
