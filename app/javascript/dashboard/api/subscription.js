import axios from 'axios';
import ApiClient from './ApiClient';

class SubscriptionAPI extends ApiClient {
  constructor() {
    super('subscription', { accountScoped: true });
  }

  createCheckoutSession(tier) {
    return axios.post(`${this.url}/create_checkout_session`, { tier });
  }

  createPortalSession() {
    return axios.post(`${this.url}/create_portal_session`);
  }
}

export default new SubscriptionAPI();
