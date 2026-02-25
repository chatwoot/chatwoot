import { getters } from '../../conversationLabels';

describe('#getters', () => {
  it('getConversationLabels', () => {
    const state = {
      records: { 1: ['customer-success', 'on-hold'] },
    };
    expect(getters.getConversationLabels(state)(1)).toEqual([
      'customer-success',
      'on-hold',
    ]);
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: true,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: true,
    });
  });
});
