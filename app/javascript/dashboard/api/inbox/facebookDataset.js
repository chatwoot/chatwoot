/* global axios */
import ApiClient from '../ApiClient';

class FacebookDatasetAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: true });
  }

  getConfiguration(inboxId) {
    return axios.get(`${this.baseUrl()}/inboxes/${inboxId}/facebook_dataset`);
  }

  updateConfiguration(inboxId, params) {
    return axios.put(`${this.baseUrl()}/inboxes/${inboxId}/facebook_dataset`, params);
  }

  testConnection(inboxId) {
    return axios.post(`${this.baseUrl()}/inboxes/${inboxId}/facebook_dataset/test_connection`);
  }

  getTrackingData(inboxId, params = {}) {
    return axios.get(`${this.baseUrl()}/inboxes/${inboxId}/facebook_dataset/tracking_data`, {
      params,
    });
  }

  resendConversion(inboxId, trackingId) {
    return axios.post(`${this.baseUrl()}/inboxes/${inboxId}/facebook_dataset/resend_conversion/${trackingId}`);
  }

  getFacebookPixels(inboxId) {
    return axios.get(`${this.baseUrl()}/inboxes/${inboxId}/facebook_dataset/pixels`);
  }

  generateAccessToken(inboxId, params) {
    return axios.post(`${this.baseUrl()}/inboxes/${inboxId}/facebook_dataset/generate_token`, params);
  }
}

export default new FacebookDatasetAPI();
