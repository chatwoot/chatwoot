import { getters } from '../../conversationPins';

describe('#getters', () => {
  const state = { records: { 1: 100 }, uiFlags: { isFetching: false } };

  it('getRecords returns the pin map', () => {
    expect(getters.getRecords(state)).toEqual({ 1: 100 });
  });

  it('isPinned returns true only for pinned conversations', () => {
    expect(getters.isPinned(state)(1)).toBe(true);
    expect(getters.isPinned(state)(2)).toBe(false);
  });

  it('getUIFlags returns the ui flags', () => {
    expect(getters.getUIFlags(state)).toEqual({ isFetching: false });
  });
});
