import { getters } from '../../conversationList';

const records = [
  { id: 4, status: 'resolved', unread_count: 1 },
  { id: 3, status: 'open', unread_count: 2 },
  { id: 2, status: 'pending', unread_count: 3 },
  { id: 1, status: 'resolved', unread_count: 0 },
];

describe('#getters', () => {
  it('returns the most recent conversation', () => {
    expect(getters.getLatestConversation({ records })).toEqual(records[0]);
    expect(getters.getLatestConversation({ records: [] })).toBe(undefined);
  });

  it('counts unread conversations, leaving the one on screen to the thread', () => {
    const state = { records, unreadCount: 3 };
    expect(
      getters.getUnreadCount(state, {}, { conversationAttributes: { id: 3 } })
    ).toBe(2);
    expect(
      getters.getUnreadCount(state, {}, { conversationAttributes: { id: 1 } })
    ).toBe(3);
  });
});
