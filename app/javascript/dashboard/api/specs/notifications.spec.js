import notificationsAPI from '../notifications';
import ApiClient from '../ApiClient';

describe('#NotificationAPI', () => {
  it('creates correct instance', () => {
    expect(notificationsAPI).toBeInstanceOf(ApiClient);
    expect(notificationsAPI).toHaveProperty('get');
    expect(notificationsAPI).toHaveProperty('getNotifications');
    expect(notificationsAPI).toHaveProperty('getUnreadCount');
    expect(notificationsAPI).toHaveProperty('read');
    expect(notificationsAPI).toHaveProperty('readAll');
  });
  describe('API calls', () => {
    let originalAxios = null;
    let axiosMock = null;
    beforeEach(() => {
      originalAxios = window.axios;
      axiosMock = {
        post: jest.fn(() => Promise.resolve()),
        get: jest.fn(() => Promise.resolve()),
      };
      window.axios = axiosMock;
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    it('#get', () => {
      notificationsAPI.get(1);
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/notifications?page=1'
      );
    });

    it('#getNotifications', () => {
      notificationsAPI.getNotifications(1);
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/notifications/1/notifications'
      );
    });

    it('#getUnreadCount', () => {
      notificationsAPI.getUnreadCount();
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/notifications/unread_count'
      );
    });

    it('#read', () => {
      notificationsAPI.read(48670, 'Conversation');
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/notifications/read_all',
        {
          primary_actor_id: 'Conversation',
          primary_actor_type: 48670,
        }
      );
    });

    it('#readAll', () => {
      notificationsAPI.readAll();
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/notifications/read_all'
      );
    });
  });
});
