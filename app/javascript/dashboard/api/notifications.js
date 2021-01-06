/* global axios */
import ApiClient from './ApiClient';

class NotificationsAPI extends ApiClient {
  constructor() {
    super('notifications', { accountScoped: true });
  }

  get(page) {
    return axios.get(`${this.url}?page=${page}`);
  }

  getNotifications(contactId) {
    return axios.get(`${this.url}/${contactId}/notifications`);
  }

  read(primaryActorType, primaryActorId) {
    return axios.post(`${this.url}/read_all`, {
      primary_actor_type: primaryActorType,
      primary_actor_id: primaryActorId,
    });
  }
}

export default new NotificationsAPI();
