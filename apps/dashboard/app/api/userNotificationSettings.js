/* global axios */
import ApiClient from './ApiClient';

class UserNotificationSettings extends ApiClient {
  constructor() {
    super('notification_settings', { accountScoped: true });
  }

  update(params) {
    return axios.patch(`${this.url}`, params);
  }
}

export default new UserNotificationSettings();
