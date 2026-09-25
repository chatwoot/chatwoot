import { mutations } from '../../conversationList';

describe('#mutations', () => {
  describe('#setRecords', () => {
    it('replaces the list with the first page', () => {
      const state = {
        records: [{ id: 9 }],
        page: 2,
        hasNextPage: true,
        unreadCount: 0,
      };
      mutations.setRecords(state, {
        payload: [{ id: 2 }, { id: 1 }],
        page: 1,
        hasNextPage: false,
        unreadCount: 1,
      });
      expect(state).toEqual({
        records: [{ id: 2 }, { id: 1 }],
        page: 1,
        hasNextPage: false,
        unreadCount: 1,
      });
    });

    it('appends later pages without repeating conversations already listed', () => {
      const state = { records: [{ id: 3 }, { id: 2 }], page: 1 };
      mutations.setRecords(state, {
        payload: [{ id: 2 }, { id: 1 }],
        page: 2,
        hasNextPage: false,
      });
      expect(state.records).toEqual([{ id: 3 }, { id: 2 }, { id: 1 }]);
      expect(state.page).toBe(2);
    });
  });

  describe('#switchThread', () => {
    it('moves to the next thread', () => {
      const state = { thread: 1 };
      mutations.switchThread(state);
      expect(state.thread).toBe(2);
    });
  });

  describe('#markRead', () => {
    it('clears the conversation and drops it from the unread total once', () => {
      const state = { records: [{ id: 1, unread_count: 4 }], unreadCount: 2 };
      mutations.markRead(state, 1);
      mutations.markRead(state, 1);
      mutations.markRead(state, 2);
      expect(state.records).toEqual([{ id: 1, unread_count: 0 }]);
      expect(state.unreadCount).toBe(1);
    });
  });

  describe('#setFetching', () => {
    it('sets the loading flag', () => {
      const state = { uiFlags: { isFetching: false } };
      mutations.setFetching(state, true);
      expect(state.uiFlags.isFetching).toBe(true);
    });
  });
});
