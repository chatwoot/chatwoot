import * as AnalyticsEvents from '../events';

describe('Analytics Events', () => {
  it('should be frozen', () => {
    Object.entries(AnalyticsEvents).forEach(([, value]) => {
      expect(Object.isFrozen(value)).toBe(true);
    });
  });

  it('event names should be unique across the board', () => {
    const allValues = Object.values(AnalyticsEvents).reduce(
      (acc, curr) => acc.concat(Object.values(curr)),
      []
    );
    const uniqueValues = new Set(allValues);
    expect(allValues.length).toBe(uniqueValues.size);
  });

  it('should not allow properties to be modified', () => {
    Object.values(AnalyticsEvents).forEach(eventsObject => {
      expect(() => {
        eventsObject.NEW_PROPERTY = 'new value';
      }).toThrow();
    });
  });
});
