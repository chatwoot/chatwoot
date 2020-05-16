import ApiClient from './ApiClient';

class NotificationSubscriptions extends ApiClient {
  constructor() {
    super('notification_subscriptions');
  }
}

export default new NotificationSubscriptions();
