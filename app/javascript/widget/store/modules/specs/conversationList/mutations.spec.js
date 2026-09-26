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

  describe('#setLastMessage', () => {
    it('shows the message on its row and moves the row to the top', () => {
      const state = {
        records: [
          { id: 3, last_message: { id: 30 } },
          { id: 2, last_message: { id: 20 }, last_activity_at: 1 },
        ],
      };
      mutations.setLastMessage(state, {
        id: 40,
        conversation_id: 2,
        created_at: 9,
      });
      expect(state.records.map(record => record.id)).toEqual([2, 3]);
      expect(state.records[0].last_message.id).toBe(40);
      expect(state.records[0].last_activity_at).toBe(9);
    });

    it('keeps a newer preview and ignores unknown conversations', () => {
      const state = { records: [{ id: 2, last_message: { id: 40 } }] };
      mutations.setLastMessage(state, { id: 30, conversation_id: 2 });
      mutations.setLastMessage(state, { id: 50, conversation_id: 9 });
      expect(state.records).toEqual([{ id: 2, last_message: { id: 40 } }]);
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
