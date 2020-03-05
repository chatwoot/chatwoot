import { getters } from '../../conversationPage';

describe('#getters', () => {
  it('getCurrentPage', () => {
    const state = {
      currentPage: {
        me: 1,
        unassigned: 2,
        all: 3,
      },
    };
    expect(getters.getCurrentPage(state)('me')).toEqual(1);
    expect(getters.getCurrentPage(state)('unassigned')).toEqual(2);
    expect(getters.getCurrentPage(state)('all')).toEqual(3);
  });

  it('getCurrentPage', () => {
    const state = {
      hasEndReached: {
        me: false,
        unassigned: true,
        all: false,
      },
    };
    expect(getters.getHasEndReached(state)('me')).toEqual(false);
    expect(getters.getHasEndReached(state)('unassigned')).toEqual(true);
    expect(getters.getHasEndReached(state)('all')).toEqual(false);
  });
});
