/* global axios */
import ApiClient from '../../ApiClient';

class WhatsappCallsAPI extends ApiClient {
  constructor() {
    super('whatsapp_calls', { accountScoped: true });
  }

  show(callId) {
    return axios.get(`${this.url}/${callId}`).then(r => r.data);
  }

  // Either conversationId, or contactId + inboxId to let the BE resolve the conversation.
  initiate({ conversationId, contactId, inboxId }, sdpOffer) {
    return axios
      .post(`${this.url}/initiate`, {
        conversation_id: conversationId,
        contact_id: contactId,
        inbox_id: inboxId,
        sdp_offer: sdpOffer,
      })
      .then(r => r.data);
  }

  accept(callId, sdpAnswer) {
    return axios
      .post(`${this.url}/${callId}/accept`, { sdp_answer: sdpAnswer })
      .then(r => r.data);
  }

  reject(callId) {
    return axios.post(`${this.url}/${callId}/reject`).then(r => r.data);
  }

  terminate(callId) {
    return axios.post(`${this.url}/${callId}/terminate`).then(r => r.data);
  }

  uploadRecording(callId, blob, filename = 'call-recording.webm') {
    const formData = new FormData();
    formData.append('recording', blob, filename);
    return axios
      .post(`${this.url}/${callId}/upload_recording`, formData)
      .then(r => r.data);
  }
}

export default new WhatsappCallsAPI();
