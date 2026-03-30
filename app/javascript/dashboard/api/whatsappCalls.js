/* global axios */
import ApiClient from './ApiClient';

class WhatsappCallsAPI extends ApiClient {
  constructor() {
    super('whatsapp_calls', { accountScoped: true });
  }

  show(callId) {
    return axios.get(`${this.url}/${callId}`);
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

  uploadRecording(callId, blob) {
    const formData = new FormData();
    formData.append('recording', blob, `call-${callId}.webm`);
    return axios.post(`${this.url}/${callId}/upload_recording`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  }
}

export default new WhatsappCallsAPI();
