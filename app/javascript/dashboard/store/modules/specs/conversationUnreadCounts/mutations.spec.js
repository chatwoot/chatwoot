import types from '../../../mutation-types';
import { mutations } from '../../conversationUnreadCounts';

describe('#mutations', () => {
  describe('#SET_CONVERSATION_UNREAD_COUNTS', () => {
    it('normalizes unread count payload', () => {
      const state = { inboxes: {}, labels: {}, teams: {} };

      mutations[types.SET_CONVERSATION_UNREAD_COUNTS](state, {
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
      });

      expect(state).toEqual({
        inboxes: { 1: 2 },
        labels: { 4: 5 },
        teams: { 6: 7 },
      });
    });

    it('clears counts when payload is empty', () => {
      const state = {
        inboxes: { 1: 2 },
        labels: { 4: 5 },
        teams: { 6: 7 },
      };

      mutations[types.SET_CONVERSATION_UNREAD_COUNTS](state, {});

      expect(state).toEqual({
        inboxes: {},
        labels: {},
        teams: {},
      });
    });
  });
});
