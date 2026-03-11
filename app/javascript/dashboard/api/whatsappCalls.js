/* global axios */
class WhatsappCallsAPI {
  constructor() {
    this.apiVersion = '/api/v1';
  }

  // eslint-disable-next-line class-methods-use-this
  get accountIdFromRoute() {
    const isInsideAccountScopedURLs =
      window.location.pathname.includes('/app/accounts');
    if (isInsideAccountScopedURLs) {
      return window.location.pathname.split('/')[3];
    }
    return '';
  }

  get baseUrl() {
    return `${this.apiVersion}/accounts/${this.accountIdFromRoute}/whatsapp_calls`;
  }

  accept(callId, sdpAnswer) {
    return axios.post(`${this.baseUrl}/${callId}/accept`, {
      sdp_answer: sdpAnswer,
    });
  }

  reject(callId) {
    return axios.post(`${this.baseUrl}/${callId}/reject`);
  }

  terminate(callId) {
    return axios.post(`${this.baseUrl}/${callId}/terminate`);
  }

  initiate(conversationId, sdpOffer) {
    return axios.post(`${this.baseUrl}/initiate`, {
      conversation_id: conversationId,
      sdp_offer: sdpOffer,
    });
  }
}

export default new WhatsappCallsAPI();
