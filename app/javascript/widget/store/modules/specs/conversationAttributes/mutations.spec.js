import { mutations } from '../../conversationAttributes';

describe('#mutations', () => {
  describe('#SET_CONVERSATION_ATTRIBUTES', () => {
    it('set status of the conversation', () => {
      const state = { id: '', status: '' };
      mutations.SET_CONVERSATION_ATTRIBUTES(state, {
        id: 1,
        status: 'open',
      });
      expect(state).toEqual({ id: 1, status: 'open' });
    });
  });

  describe('#UPDATE_CONVERSATION_ATTRIBUTES', () => {
    it('update status if it is same conversation', () => {
      const state = { id: 1, status: 'pending' };
      mutations.UPDATE_CONVERSATION_ATTRIBUTES(state, {
        id: 1,
        status: 'open',
      });
      expect(state).toEqual({ id: 1, status: 'open' });
    });
    it('doesnot update status if it is not the same conversation', () => {
      const state = { id: 1, status: 'pending' };
      mutations.UPDATE_CONVERSATION_ATTRIBUTES(state, {
        id: 2,
        status: 'open',
      });
      expect(state).toEqual({ id: 1, status: 'pending' });
    });
  });

  describe('#CLEAR_CONVERSATION_ATTRIBUTES', () => {
    it('clear status if it is same conversation', () => {
      const state = { id: 1, status: 'open' };
      mutations.CLEAR_CONVERSATION_ATTRIBUTES(state, {
        id: 1,
        status: 'open',
      });
      expect(state).toEqual({ id: '', status: '' });
    });
  });
});
