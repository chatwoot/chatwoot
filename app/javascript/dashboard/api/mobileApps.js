/* global axios */
import ApiClient from './ApiClient';

class MobileAppsAPI extends ApiClient {
  constructor() {
    super('inboxes', { accountScoped: true });
  }

  get(inboxId) {
    return axios.get(`${this.url}/${inboxId}/mobile_app`);
  }

  update(inboxId, mobileApp) {
    return axios.patch(`${this.url}/${inboxId}/mobile_app`, {
      mobile_app: mobileApp,
    });
  }

  testNotification(inboxId, deviceId) {
    return axios.post(`${this.url}/${inboxId}/mobile_app/test_notification`, {
      device_id: deviceId,
    });
  }

  remove(inboxId) {
    return axios.delete(`${this.url}/${inboxId}/mobile_app`);
  }
}

export default new MobileAppsAPI();
