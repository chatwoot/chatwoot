import ApiClient from './ApiClient';

class NotificationsAPI extends ApiClient {
  constructor() {
    super('notifications', { accountScoped: true });
  }

  get(page) {
    return this.axios.get(`${this.url}?page=${page}`);
  }

  getNotifications(contactId) {
    return this.axios.get(`${this.url}/${contactId}/notifications`);
  }

  getUnreadCount() {
    return this.axios.get(`${this.url}/unread_count`);
  }

  read(primaryActorType, primaryActorId) {
    return this.axios.post(`${this.url}/read_all`, {
      primary_actor_type: primaryActorType,
      primary_actor_id: primaryActorId,
    });
  }

  readAll() {
    return this.axios.post(`${this.url}/read_all`);
  }
}

export default new NotificationsAPI();
