/* global axios */
import ApiClient from '../ApiClient';

class StripeAPI extends ApiClient {
  constructor() {
    super('integrations/stripe', { accountScoped: true });
  }

  connect() {
    return axios.post(`${this.url}/auth`);
  }

  disconnect() {
    return axios.delete(this.url);
  }

  customer(conversationId, customerId, signal) {
    return axios.get(`${this.url}/customer`, {
      params: { conversation_id: conversationId, customer_id: customerId },
      signal,
    });
  }
}

export default new StripeAPI();
