/* global axios */
import ApiClient from './ApiClient';

class AppointmentsAPI extends ApiClient {
  constructor() {
    super('appointments', { accountScoped: true });
  }

  index({ page, status, contactId, conversationId, q } = {}) {
    return axios.get(this.url, {
      params: {
        page,
        status,
        contact_id: contactId,
        conversation_id: conversationId,
        q,
      },
    });
  }

  show(id) {
    return axios.get(`${this.url}/${id}`);
  }

  createForConversation({ conversationId, eventTypeUri, eventTypeName }) {
    return axios.post(
      `${this.url.replace('/appointments', '')}/conversations/${conversationId}/appointments`,
      {
        event_type_uri: eventTypeUri,
        event_type_name: eventTypeName,
      }
    );
  }
}

export default new AppointmentsAPI();
