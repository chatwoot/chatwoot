/* global axios */
import ApiClient from './ApiClient';

class WhatsappCallsAPI extends ApiClient {
  constructor() {
    super('whatsapp_calls', { accountScoped: true });
  }

  accept(callId, sdpAnswer) {
    return axios.post(`${this.url}/${callId}/accept`, {
      sdp_answer: sdpAnswer,
    });
  }

  reject(callId) {
    return axios.post(`${this.url}/${callId}/reject`);
  }

  terminate(callId) {
    return axios.post(`${this.url}/${callId}/terminate`);
  }

  initiate(conversationId, sdpOffer) {
    return axios.post(`${this.url}/initiate`, {
      conversation_id: conversationId,
      sdp_offer: sdpOffer,
    });
  }
}

export default new WhatsappCallsAPI();
