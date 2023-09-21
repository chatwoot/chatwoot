import userNotificationSettings from '../userNotificationSettings';
import ApiClient from '../ApiClient';

describe('#AgentAPI', () => {
  it('creates correct instance', () => {
    expect(userNotificationSettings).toBeInstanceOf(ApiClient);
    expect(userNotificationSettings).toHaveProperty('get');
    expect(userNotificationSettings).toHaveProperty('show');
    expect(userNotificationSettings).toHaveProperty('create');
    expect(userNotificationSettings).toHaveProperty('update');
    expect(userNotificationSettings).toHaveProperty('delete');
  });
});
