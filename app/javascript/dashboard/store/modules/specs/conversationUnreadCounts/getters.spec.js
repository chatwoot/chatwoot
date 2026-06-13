import { getters } from '../../conversationUnreadCounts';

describe('#getters', () => {
  it('returns inbox unread count by id', () => {
    const state = {
      allCount: 0,
      inboxes: { 1: 2 },
      labels: {},
      teams: {},
    };

    expect(getters.getInboxUnreadCount(state)(1)).toBe(2);
    expect(getters.getInboxUnreadCount(state)('1')).toBe(2);
    expect(getters.getInboxUnreadCount(state)(2)).toBe(0);
  });

  it('returns label unread count by id', () => {
    const state = {
      allCount: 0,
      inboxes: {},
      labels: { 3: 4 },
      teams: {},
    };

    expect(getters.getLabelUnreadCount(state)(3)).toBe(4);
    expect(getters.getLabelUnreadCount(state)('3')).toBe(4);
    expect(getters.getLabelUnreadCount(state)(4)).toBe(0);
  });

  it('returns team unread count by id', () => {
    const state = {
      allCount: 0,
      inboxes: {},
      labels: {},
      teams: { 5: 6 },
    };

    expect(getters.getTeamUnreadCount(state)(5)).toBe(6);
    expect(getters.getTeamUnreadCount(state)('5')).toBe(6);
    expect(getters.getTeamUnreadCount(state)(6)).toBe(0);
  });

  it('returns all unread count', () => {
    const state = {
      allCount: 7,
      inboxes: {},
      labels: {},
      teams: {},
    };

    expect(getters.getAllUnreadCount(state)).toBe(7);
  });

  it('returns unread count maps', () => {
    const state = {
      allCount: 0,
      inboxes: { 1: 2 },
      labels: { 3: 4 },
      teams: { 5: 6 },
    };

    expect(getters.getInboxUnreadCounts(state)).toEqual({ 1: 2 });
    expect(getters.getLabelUnreadCounts(state)).toEqual({ 3: 4 });
    expect(getters.getTeamUnreadCounts(state)).toEqual({ 5: 6 });
  });
});
