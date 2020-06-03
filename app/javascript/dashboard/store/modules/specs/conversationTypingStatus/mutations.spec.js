import * as types from '../../../mutation-types';
import { mutations } from '../../conversationTypingStatus';

describe('#mutations', () => {
  describe('#ADD_USER_TYPING_TO_CONVERSATION', () => {
    it('add user to state', () => {
      const state = { records: {} };
      mutations[types.default.ADD_USER_TYPING_TO_CONVERSATION](state, {
        conversationId: 1,
        user: { id: 1, type: 'contact', name: 'user-1' },
      });
      expect(state.records).toEqual({
        1: [{ id: 1, type: 'contact', name: 'user-1' }],
      });
    });

    it('doesnot add user if user already exist', () => {
      const state = {
        records: {
          1: [{ id: 1, type: 'contact', name: 'user-1' }],
        },
      };
      mutations[types.default.ADD_USER_TYPING_TO_CONVERSATION](state, {
        conversationId: 1,
        user: { id: 1, type: 'contact', name: 'user-1' },
      });
      expect(state.records).toEqual({
        1: [{ id: 1, type: 'contact', name: 'user-1' }],
      });
    });

    it('add user to state if no matching user profiles are seen', () => {
      const state = {
        records: {
          1: [{ id: 1, type: 'user', name: 'user-1' }],
        },
      };
      mutations[types.default.ADD_USER_TYPING_TO_CONVERSATION](state, {
        conversationId: 1,
        user: { id: 1, type: 'contact', name: 'user-1' },
      });
      expect(state.records).toEqual({
        1: [
          { id: 1, type: 'user', name: 'user-1' },
          { id: 1, type: 'contact', name: 'user-1' },
        ],
      });
    });
  });

  describe('#REMOVE_USER_TYPING_FROM_CONVERSATION', () => {
    it('remove add user if user exist', () => {
      const state = {
        records: {
          1: [{ id: 1, type: 'contact', name: 'user-1' }],
        },
      };
      mutations[types.default.REMOVE_USER_TYPING_FROM_CONVERSATION](state, {
        conversationId: 1,
        user: { id: 1, type: 'contact', name: 'user-1' },
      });
      expect(state.records).toEqual({
        1: [],
      });
    });
  });
});
