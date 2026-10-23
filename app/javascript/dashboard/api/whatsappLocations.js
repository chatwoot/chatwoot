/* global axios */
import ApiClient from './ApiClient';

class WhatsappLocations extends ApiClient {
  constructor() {
    super('inboxes', { accountScoped: true });
  }

  saveLocations(inboxId, locations) {
    return axios.put(`${this.url}/${inboxId}/whatsapp_locations`, {
      locations,
    });
  }

  sendMessage(conversationId, payload) {
    return axios.post(
      `${this.baseUrl()}/conversations/${conversationId}/location_message`,
      payload
    );
  }
}

export default new WhatsappLocations();
