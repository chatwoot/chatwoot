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
}

export default new AccountAPI();
