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
}

export default new NotificationsAPI();
