import types from '../../../mutation-types';
import { mutations } from '../../conversationUnreadCounts';

describe('#mutations', () => {
  describe('#SET_CONVERSATION_UNREAD_COUNTS', () => {
    it('normalizes unread count payload', () => {
      const state = { inboxes: {}, labels: {} };

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
      });

      expect(state).toEqual({
        inboxes: { 1: 2 },
        labels: { 4: 5 },
      });
    });

    it('clears counts when payload is empty', () => {
      const state = {
        inboxes: { 1: 2 },
        labels: { 4: 5 },
      };

      mutations[types.SET_CONVERSATION_UNREAD_COUNTS](state, {});

      expect(state).toEqual({
        inboxes: {},
        labels: {},
      });
    });
  });
});
