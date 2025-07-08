/* global axios */

import ApiClient from './ApiClient';

class VouchersAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: false });
  }

  validate(data) {
    return axios.post(`${this.url}/validate_voucher`, data);
  }
  
  preview(data) {
    return axios.post(`${this.url}/preview_voucher`, data);
  }
}

export default new VouchersAPI();
