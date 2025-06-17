/* global axios */
import ApiClient from '../ApiClient';

class ConversationAdsTrackingAPI extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  getAdsTracking(conversationId) {
    return axios.get(`${this.baseUrl()}/${conversationId}/ads_tracking`);
  }
}

export default new ConversationAdsTrackingAPI();
