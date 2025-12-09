/* global axios */
import ApiClient from './ApiClient';

class FunnelsAPI extends ApiClient {
  constructor() {
    super('funnels', { accountScoped: true });
  }

  moveContact(funnelId, contactId, columnId, position = 0) {
    return axios.post(`${this.url}/${funnelId}/move_contact`, {
      contact_id: contactId,
      column_id: columnId,
      position,
    });
  }

  getContacts(funnelId) {
    return axios.get(`${this.url}/${funnelId}/funnel_contacts`);
  }

  addContact(funnelId, contactId, columnId) {
    return axios.post(`${this.url}/${funnelId}/funnel_contacts`, {
      contact_id: contactId,
      column_id: columnId,
    });
  }

  updateContact(funnelId, contactId, data) {
    return axios.patch(`${this.url}/${funnelId}/funnel_contacts/${contactId}`, {
      funnel_contact: data,
    });
  }

  removeContact(funnelId, contactId) {
    return axios.delete(`${this.url}/${funnelId}/funnel_contacts/${contactId}`);
  }
}

export default new FunnelsAPI();
