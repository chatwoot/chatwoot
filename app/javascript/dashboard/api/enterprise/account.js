/* global axios */
import ApiClient from '../ApiClient';

class EnterpriseAccountAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: true, enterprise: true });
  }

  checkout() {
    return axios.post(`${this.url}checkout`);
  }

  subscription() {
    return axios.post(`${this.url}subscription`);
  }
}

export default new EnterpriseAccountAPI();
