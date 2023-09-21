import { actions } from '../../conversationTypingStatus';
import * as types from '../../../mutation-types';

const commit = jest.fn();

describe('#actions', () => {
  describe('#create', () => {
    it('sends correct actions', () => {
      actions.create(
        { commit },
        { conversationId: 1, user: { id: 1, name: 'user-1' } }
      );
      expect(commit.mock.calls).toEqual([
        [
          types.default.ADD_USER_TYPING_TO_CONVERSATION,
          { conversationId: 1, user: { id: 1, name: 'user-1' } },
        ],
      ]);
    });
  });

  describe('#destroy', () => {
    it('sends correct actions', () => {
      actions.destroy(
        { commit },
        { conversationId: 1, user: { id: 1, name: 'user-1' } }
      );
      expect(commit.mock.calls).toEqual([
        [
          types.default.REMOVE_USER_TYPING_FROM_CONVERSATION,
          { conversationId: 1, user: { id: 1, name: 'user-1' } },
        ],
      ]);
    });
  });
});
