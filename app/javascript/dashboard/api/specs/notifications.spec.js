import notifications from '../notifications';
import ApiClient from '../ApiClient';

describe('#NotificationAPI', () => {
  it('creates correct instance', () => {
    expect(notifications).toBeInstanceOf(ApiClient);
    expect(notifications).toHaveProperty('get');
    expect(notifications).toHaveProperty('getNotifications');
    expect(notifications).toHaveProperty('getUnreadCount');
    expect(notifications).toHaveProperty('read');
    expect(notifications).toHaveProperty('readAll');
  });
});
