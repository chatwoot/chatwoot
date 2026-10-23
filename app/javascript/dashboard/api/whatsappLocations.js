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
}

export default new WhatsappLocations();
