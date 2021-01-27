import types from '../../../mutation-types';
import { mutations } from '../../notifications/mutations';

describe('#mutations', () => {
  describe('#SET_NOTIFICATIONS_UI_FLAG', () => {
    it('set notification ui flag', () => {
      const state = { uiFlags: { isFetching: true } };
      mutations[types.SET_NOTIFICATIONS_UI_FLAG](state, { isFetching: false });
      expect(state.uiFlags).toEqual({ isFetching: false });
    });
  });

  describe('#CLEAR_NOTIFICATIONS', () => {
    it('clear notifications', () => {
      const state = { records: { 1: { id: 1 } } };
      mutations[types.CLEAR_NOTIFICATIONS](state);
      expect(state.records).toEqual({});
    });
  });

  describe('#SET_NOTIFICATIONS_META', () => {
    it('set notifications meta data', () => {
      const state = { meta: {} };
      mutations[types.SET_NOTIFICATIONS_META](state, {
        count: 3,
        current_page: 1,
        unread_count: 2,
      });
      expect(state.meta).toEqual({
        count: 3,
        currentPage: 1,
        unreadCount: 2,
      });
    });
  });

  describe('#SET_NOTIFICATIONS_UNREAD_COUNT', () => {
    it('set notifications unread count', () => {
      const state = { meta: { unreadCount: 4 } };
      mutations[types.SET_NOTIFICATIONS_UNREAD_COUNT](state, 3);
      expect(state.meta).toEqual({ unreadCount: 3 });
    });

    it('set notifications unread count to 0 if invalid', () => {
      const state = { meta: { unreadCount: 4 } };
      mutations[types.SET_NOTIFICATIONS_UNREAD_COUNT](state, -1);
      expect(state.meta).toEqual({ unreadCount: 0 });
    });
  });

  describe('#SET_NOTIFICATIONS', () => {
    it('set notifications ', () => {
      const state = { records: {} };
      mutations[types.SET_NOTIFICATIONS](state, [
        { id: 1 },
        { id: 2 },
        { id: 3 },
        { id: 4 },
      ]);
      expect(state.records).toEqual({
        1: { id: 1 },
        2: { id: 2 },
        3: { id: 3 },
        4: { id: 4 },
      });
    });
  });
  describe('#UPDATE_NOTIFICATION', () => {
    it('update notifications ', () => {
      const state = {
        records: {
          1: { id: 1, primary_actor_id: 1 },
        },
      };
      mutations[types.UPDATE_NOTIFICATION](state, 1);
      expect(state.records).toEqual({
        1: { id: 1, primary_actor_id: 1, read_at: true },
      });
    });
  });
  describe('#UPDATE_ALL_NOTIFICATIONS', () => {
    it('update all notifications ', () => {
      const state = {
        records: {
          1: { id: 1, primary_actor_id: 1 },
          2: { id: 2, primary_actor_id: 2 },
        },
      };
      mutations[types.UPDATE_ALL_NOTIFICATIONS](state);
      expect(state.records).toEqual({
        1: { id: 1, primary_actor_id: 1, read_at: true },
        2: { id: 2, primary_actor_id: 2, read_at: true },
      });
    });
  });
});
