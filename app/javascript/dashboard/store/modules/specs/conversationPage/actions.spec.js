import { actions } from '../../conversationPage';
import * as types from '../../../mutation-types';

const commit = vi.fn();

describe('#actions', () => {
  describe('#setCurrentPage', () => {
    it('sends correct actions', () => {
      actions.setCurrentPage({ commit }, { filter: 'me', page: 1 });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CURRENT_PAGE, { filter: 'me', page: 1 }],
      ]);
    });
  });

  describe('#setEndReached', () => {
    it('sends correct actions', () => {
      actions.setEndReached({ commit }, { filter: 'me' });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONVERSATION_END_REACHED, { filter: 'me' }],
      ]);
    });
  });

  describe('#reset', () => {
    it('sends correct actions', () => {
      actions.reset({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.CLEAR_CONVERSATION_PAGE],
      ]);
    });
  });
});
