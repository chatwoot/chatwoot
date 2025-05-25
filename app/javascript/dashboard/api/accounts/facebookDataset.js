/* global axios */
import ApiClient from '../ApiClient';

class FacebookDatasetAPI extends ApiClient {
  constructor() {
    super('facebook_dataset', { accountScoped: true });
  }

  getTrackingData(params = {}) {
    return axios.get(`${this.baseUrl()}`, { params });
  }

  getStats(params = {}) {
    return axios.get(`${this.baseUrl()}/stats`, { params });
  }

  export(params = {}) {
    return axios.get(`${this.baseUrl()}/export`, {
      params: { ...params, format: 'csv' },
      responseType: 'blob',
    });
  }

  resendConversion(trackingId) {
    return axios.post(`${this.baseUrl()}/${trackingId}/resend_conversion`);
  }

  bulkResend(params) {
    return axios.post(`${this.baseUrl()}/bulk_resend`, params);
  }

  show(trackingId) {
    return axios.get(`${this.baseUrl()}/${trackingId}`);
  }
}

export default new FacebookDatasetAPI();
