/* global axios */
import ApiClient from './ApiClient';

class PaymentLinkSettingsAPI extends ApiClient {
  constructor() {
    super('payment_link_settings', { accountScoped: true });
  }

  get() {
    return axios.get(this.url);
  }

  create(data) {
    return axios.post(this.url, { payment_link_settings: data });
  }

  update(data) {
    return axios.put(this.url, { payment_link_settings: data });
  }
}

export default new PaymentLinkSettingsAPI();
