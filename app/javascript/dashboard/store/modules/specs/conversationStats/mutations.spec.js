import types from '../../../mutation-types';
import { mutations } from '../../conversationStats';

describe('#mutations', () => {
  describe('#SET_CONV_TAB_META', () => {
    it('set conversation stats correctly', () => {
      const state = {};
      mutations[types.SET_CONV_TAB_META](state, {
        mine_count: 1,
        unassigned_count: 1,
        all_count: 2,
      });
      expect(state).toEqual({
        mineCount: 1,
        unAssignedCount: 1,
        allCount: 2,
        updatedOn: expect.any(Date),
      });
    });
  });

  describe('#SET_UNREAD_COUNTS', () => {
    it('sets unread counts correctly', () => {
      const state = {
        unreadCounts: {
          byInbox: {},
          byLabel: {},
          byStatus: { all: 0, mine: 0, unassigned: 0 },
          total: 0,
        },
      };
      mutations[types.SET_UNREAD_COUNTS](state, {
        by_inbox: { 1: 5, 2: 3 },
        by_label: { support: 2, billing: 1 },
        by_status: { all: 8, mine: 3, unassigned: 2 },
        total: 8,
      });
      expect(state.unreadCounts).toEqual({
        byInbox: { 1: 5, 2: 3 },
        byLabel: { support: 2, billing: 1 },
        byStatus: { all: 8, mine: 3, unassigned: 2 },
        total: 8,
      });
    });

    it('handles empty payload gracefully', () => {
      const state = {
        unreadCounts: {
          byInbox: { 1: 5 },
          byLabel: { support: 2 },
          byStatus: { all: 5, mine: 2, unassigned: 1 },
          total: 5,
        },
      };
      mutations[types.SET_UNREAD_COUNTS](state, {});
      expect(state.unreadCounts).toEqual({
        byInbox: {},
        byLabel: {},
        byStatus: { all: 0, mine: 0, unassigned: 0 },
        total: 0,
      });
    });

    it('handles undefined payload gracefully', () => {
      const state = {
        unreadCounts: {
          byInbox: { 1: 5 },
          byLabel: { support: 2 },
          byStatus: { all: 5, mine: 2, unassigned: 1 },
          total: 5,
        },
      };
      mutations[types.SET_UNREAD_COUNTS](state);
      expect(state.unreadCounts).toEqual({
        byInbox: {},
        byLabel: {},
        byStatus: { all: 0, mine: 0, unassigned: 0 },
        total: 0,
      });
    });
  });
});
