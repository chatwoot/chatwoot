import { getters } from '../../conversationAttributes';

describe('#getters', () => {
  it('getConversationParams', () => {
    const state = {
      id: 1,
      status: 'pending',
    };
    expect(getters.getConversationParams(state)).toEqual({
      id: 1,
      status: 'pending',
    });
  });
});
