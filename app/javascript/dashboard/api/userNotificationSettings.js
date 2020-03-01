/* global axios */
import ApiClient from './ApiClient';

class UserNotificationSettings extends ApiClient {
  constructor() {
    super('user/notification_settings');
  }

  update(params) {
    return axios.patch(`${this.url}`, params);
  }
}

export default new UserNotificationSettings();
