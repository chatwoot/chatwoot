import types from '../../../mutation-types';
import { mutations } from '../../conversationUnreadCounts';

describe('#mutations', () => {
  describe('#SET_CONVERSATION_UNREAD_COUNTS', () => {
    it('normalizes unread count payload', () => {
      const state = {
        allCount: 0,
        inboxes: {},
        labels: {},
        teams: {},
        mentionsCount: 0,
        participatingCount: 0,
        unattendedCount: 0,
        folders: {},
      };

      mutations[types.SET_CONVERSATION_UNREAD_COUNTS](state, {
        all_count: '3',
        inboxes: {
          1: '2',
          2: 0,
          3: 'invalid',
        },
        labels: {
          4: 5,
          5: -1,
        },
        teams: {
          6: '7',
          7: 0,
        },
        mentions_count: '8',
        participating_count: 9,
        unattended_count: 0,
        folders: {
          10: '11',
          12: -1,
        },
      });

      expect(state).toEqual({
        allCount: 3,
        inboxes: { 1: 2 },
        labels: { 4: 5 },
        teams: { 6: 7 },
        mentionsCount: 8,
        participatingCount: 9,
        unattendedCount: 0,
        folders: { 10: 11 },
      });
    });

    it('clears counts when payload is empty', () => {
      const state = {
        allCount: 2,
        inboxes: { 1: 2 },
        labels: { 4: 5 },
        teams: { 6: 7 },
        mentionsCount: 8,
        participatingCount: 9,
        unattendedCount: 10,
        folders: { 11: 12 },
      };

      mutations[types.SET_CONVERSATION_UNREAD_COUNTS](state, {});

      expect(state).toEqual({
        allCount: 0,
        inboxes: {},
        labels: {},
        teams: {},
        mentionsCount: 0,
        participatingCount: 0,
        unattendedCount: 0,
        folders: {},
      });
    });

    it('normalizes invalid aggregate counts to zero', () => {
      const state = {
        allCount: 2,
        inboxes: {},
        labels: {},
        teams: {},
        mentionsCount: 2,
        participatingCount: 3,
        unattendedCount: 4,
        folders: {},
      };

      mutations[types.SET_CONVERSATION_UNREAD_COUNTS](state, {
        all_count: 'invalid',
        mentions_count: 'invalid',
        participating_count: -1,
        unattended_count: 0,
      });

      expect(state.allCount).toBe(0);
      expect(state.mentionsCount).toBe(0);
      expect(state.participatingCount).toBe(0);
      expect(state.unattendedCount).toBe(0);
    });
  });
});
