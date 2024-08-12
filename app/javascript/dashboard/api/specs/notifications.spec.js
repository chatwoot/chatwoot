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
    const originalAxios = window.axios;
    const axiosMock = {
      post: vi.fn(() => Promise.resolve()),
      get: vi.fn(() => Promise.resolve()),
      patch: vi.fn(() => Promise.resolve()),
      delete: vi.fn(() => Promise.resolve()),
    };

    beforeEach(() => {
      window.axios = axiosMock;
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    describe('#get', () => {
      it('generates the API call if both params are available', () => {
        notificationsAPI.get({
          page: 1,
          status: 'snoozed',
          type: 'read',
          sortOrder: 'desc',
        });
        expect(axiosMock.get).toHaveBeenCalledWith('/api/v1/notifications', {
          params: {
            page: 1,
            sort_order: 'desc',
            includes: ['snoozed', 'read'],
          },
        });
      });

      it('generates the API call if one of the params are available', () => {
        notificationsAPI.get({
          page: 1,
          type: 'read',
          sortOrder: 'desc',
        });
        expect(axiosMock.get).toHaveBeenCalledWith('/api/v1/notifications', {
          params: {
            page: 1,
            sort_order: 'desc',
            includes: ['read'],
          },
        });
      });
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

    it('#snooze', () => {
      notificationsAPI.snooze({ id: 1, snoozedUntil: 12332211 });
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/notifications/1/snooze',
        {
          snoozed_until: 12332211,
        }
      );
    });

    it('#delete', () => {
      notificationsAPI.delete(1);
      expect(axiosMock.delete).toHaveBeenCalledWith('/api/v1/notifications/1');
    });

    it('#deleteAll', () => {
      notificationsAPI.deleteAll({ type: 'all' });
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/notifications/destroy_all',
        {
          type: 'all',
        }
      );
    });
  });
});
