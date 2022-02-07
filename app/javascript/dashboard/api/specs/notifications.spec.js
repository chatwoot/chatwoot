import notificationsAPI from '../notifications';
import ApiClient from '../ApiClient';
import describeWithAPIMock from './apiSpecHelper';

describe('#NotificationAPI', () => {
  it('creates correct instance', () => {
    expect(notificationsAPI).toBeInstanceOf(ApiClient);
    expect(notificationsAPI).toHaveProperty('get');
    expect(notificationsAPI).toHaveProperty('getNotifications');
    expect(notificationsAPI).toHaveProperty('getUnreadCount');
    expect(notificationsAPI).toHaveProperty('read');
    expect(notificationsAPI).toHaveProperty('readAll');
  });
  describeWithAPIMock('API calls', context => {
    it('#get', () => {
      notificationsAPI.get(1);
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/notifications?page=1'
      );
    });

    it('#getNotifications', () => {
      notificationsAPI.getNotifications(1);
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/notifications/1/notifications'
      );
    });

    it('#getUnreadCount', () => {
      notificationsAPI.getUnreadCount();
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/notifications/unread_count'
      );
    });

    it('#read', () => {
      notificationsAPI.read(48670, 'Conversation');
      expect(context.axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/notifications/read_all',
        {
          primary_actor_id: 'Conversation',
          primary_actor_type: 48670,
        }
      );
    });

    it('#readAll', () => {
      notificationsAPI.readAll();
      expect(context.axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/notifications/read_all'
      );
    });
  });
});
