import { getters } from '../../notifications/getters';

describe('#getters', () => {
  it('getNotifications', () => {
    const state = {
      records: {
        1: { id: 1 },
        2: { id: 2 },
        3: { id: 3 },
      },
    };
    expect(getters.getNotifications(state)).toEqual([
      { id: 3 },
      { id: 2 },
      { id: 1 },
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

  it('getNotification', () => {
    const state = {
      records: {
        1: { id: 1 },
      },
    };
    expect(getters.getNotification(state)(1)).toEqual({ id: 1 });
    expect(getters.getNotification(state)(2)).toEqual({});
  });

  it('getMeta', () => {
    const state = {
      meta: { unreadCount: 1 },
    };
    expect(getters.getMeta(state)).toEqual({ unreadCount: 1 });
  });
});
