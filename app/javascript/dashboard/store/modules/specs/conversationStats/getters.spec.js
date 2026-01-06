import { getters } from '../../conversationStats';

describe('#getters', () => {
  it('getStats', () => {
    const state = {
      mineCount: 1,
      unAssignedCount: 1,
      allCount: 2,
    };
    expect(getters.getStats(state)).toEqual({
      mineCount: 1,
      unAssignedCount: 1,
      allCount: 2,
    });
  });

  describe('unread count getters', () => {
    const state = {
      unreadCounts: {
        byInbox: { 1: 5, 2: 3 },
        byLabel: { support: 2, billing: 1 },
        byStatus: { all: 8, mine: 3, unassigned: 2 },
        total: 8,
      },
    };

    it('getUnreadCountForInbox returns count for existing inbox', () => {
      expect(getters.getUnreadCountForInbox(state)(1)).toBe(5);
      expect(getters.getUnreadCountForInbox(state)(2)).toBe(3);
    });

    it('getUnreadCountForInbox returns 0 for non-existent inbox', () => {
      expect(getters.getUnreadCountForInbox(state)(999)).toBe(0);
    });

    it('getUnreadCountForLabel returns count for existing label', () => {
      expect(getters.getUnreadCountForLabel(state)('support')).toBe(2);
      expect(getters.getUnreadCountForLabel(state)('billing')).toBe(1);
    });

    it('getUnreadCountForLabel returns 0 for non-existent label', () => {
      expect(getters.getUnreadCountForLabel(state)('unknown')).toBe(0);
    });

    it('getUnreadCountAll returns all status count', () => {
      expect(getters.getUnreadCountAll(state)).toBe(8);
    });

    it('getUnreadCountMine returns mine status count', () => {
      expect(getters.getUnreadCountMine(state)).toBe(3);
    });

    it('getUnreadCountUnassigned returns unassigned count', () => {
      expect(getters.getUnreadCountUnassigned(state)).toBe(2);
    });

    it('getTotalUnreadCount returns total', () => {
      expect(getters.getTotalUnreadCount(state)).toBe(8);
    });
  });
});
