/* global axios */

import ApiClient from './ApiClient';

class NotificationSubscriptions extends ApiClient {
  constructor() {
    super('notification_subscriptions');
  }

  destroy(data) {
    return axios.delete(this.url, { data });
  }
}

export default new NotificationSubscriptions();
