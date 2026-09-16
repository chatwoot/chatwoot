import { getters } from '../../conversationUnreadCounts';

describe('#getters', () => {
  it('returns inbox unread count by id', () => {
    const state = {
      allCount: 0,
      inboxes: { 1: 2 },
      labels: {},
      teams: {},
      folders: {},
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
      folders: {},
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
      folders: {},
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
      folders: {},
    };

    expect(getters.getAllUnreadCount(state)).toBe(7);
  });

  it('returns filtered unread counts', () => {
    const state = {
      allCount: 0,
      inboxes: {},
      labels: {},
      teams: {},
      mentionsCount: 1,
      participatingCount: 2,
      unattendedCount: 3,
      folders: { 8: 4 },
    };

    expect(getters.getMentionsUnreadCount(state)).toBe(1);
    expect(getters.getParticipatingUnreadCount(state)).toBe(2);
    expect(getters.getUnattendedUnreadCount(state)).toBe(3);
    expect(getters.getFolderUnreadCount(state)(8)).toBe(4);
    expect(getters.getFolderUnreadCount(state)('8')).toBe(4);
    expect(getters.getFolderUnreadCount(state)(9)).toBe(0);
  });

  it('returns unread count maps', () => {
    const state = {
      allCount: 0,
      inboxes: { 1: 2 },
      labels: { 3: 4 },
      teams: { 5: 6 },
      folders: { 7: 8 },
    };

    expect(getters.getInboxUnreadCounts(state)).toEqual({ 1: 2 });
    expect(getters.getLabelUnreadCounts(state)).toEqual({ 3: 4 });
    expect(getters.getTeamUnreadCounts(state)).toEqual({ 5: 6 });
    expect(getters.getFolderUnreadCounts(state)).toEqual({ 7: 8 });
  });
});
