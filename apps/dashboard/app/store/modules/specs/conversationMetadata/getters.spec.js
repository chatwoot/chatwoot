import { getters } from '../../conversationMetadata';

describe('#getters', () => {
  it('getConversationMetadata', () => {
    const state = {
      records: {
        1: {
          browser: { name: 'Chrome' },
        },
      },
    };
    expect(getters.getConversationMetadata(state)(1)).toEqual({
      browser: { name: 'Chrome' },
    });
  });
});
