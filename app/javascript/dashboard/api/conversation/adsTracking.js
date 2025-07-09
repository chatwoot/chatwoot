/* global axios */
import ApiClient from '../ApiClient';

class ConversationAdsTrackingAPI extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  getAdsTracking(conversationId) {
    // Đảm bảo conversationId là số và hợp lệ
    if (!conversationId || isNaN(conversationId)) {
      console.error('Invalid conversationId:', conversationId);
      return Promise.reject(new Error('Invalid conversation ID'));
    }

    const url = `${this.baseUrl()}/${conversationId}/ads_tracking`;
    console.log('Fetching ads tracking from URL:', url);

    return axios.get(url);
  }
}

export default new ConversationAdsTrackingAPI();
