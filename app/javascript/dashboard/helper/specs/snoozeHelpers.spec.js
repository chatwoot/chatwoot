import {
  findSnoozeTime,
  snoozedReopenTime,
  findStartOfNextWeek,
  findStartOfNextMonth,
  findNextDay,
  setHoursToNine,
  snoozedReopenTimeToTimestamp,
  shortenSnoozeTime,
  generateSnoozeSuggestions,
} from '../snoozeHelpers';

describe('#Snooze Helpers', () => {
  describe('findStartOfNextWeek', () => {
    it('should return first working day of next week if a date is passed', () => {
      const today = new Date('06/16/2023');
      const startOfNextWeek = new Date('06/19/2023');
      expect(findStartOfNextWeek(today)).toEqual(startOfNextWeek);
    });
    it('should return first working day of next week if a date is passed', () => {
      const today = new Date('06/03/2023');
      const startOfNextWeek = new Date('06/05/2023');
      expect(findStartOfNextWeek(today)).toEqual(startOfNextWeek);
    });
  });

  describe('findStartOfNextMonth', () => {
    it('should return first working day of next month if a valid date is passed', () => {
      const today = new Date('06/21/2023');
      const startOfNextMonth = new Date('07/03/2023');
      expect(findStartOfNextMonth(today)).toEqual(startOfNextMonth);
    });
    it('should return first working day of next month if a valid date is passed', () => {
      const today = new Date('02/28/2023');
      const startOfNextMonth = new Date('03/06/2023');
      expect(findStartOfNextMonth(today)).toEqual(startOfNextMonth);
    });
  });

  describe('setHoursToNine', () => {
    it('should return date with 9.00AM time', () => {
      const nextDay = new Date('06/17/2023');
      nextDay.setHours(9, 0, 0, 0);
      expect(setHoursToNine(nextDay)).toEqual(nextDay);
    });
    it('should return date with 9.00AM time if date with 10am is passes', () => {
      const nextDay = new Date('06/17/2023 10:00:00');
      nextDay.setHours(9, 0, 0, 0);
      expect(setHoursToNine(nextDay)).toEqual(nextDay);
    });
  });

  describe('findSnoozeTime', () => {
    it('should return nil if until_next_reply is passed', () => {
      expect(findSnoozeTime('until_next_reply')).toEqual(null);
    });

    it('should return next hour time stamp if an_hour_from_now is passed', () => {
      const nextHour = new Date();
      nextHour.setHours(nextHour.getHours() + 1);
      expect(findSnoozeTime('an_hour_from_now')).toBeCloseTo(
        Math.floor(nextHour.getTime() / 1000)
      );
    });

    it('should return next day 9.00AM time stamp until_tomorrow is passed', () => {
      const today = new Date('06/16/2023');
      const nextDay = new Date('06/17/2023');
      nextDay.setHours(9, 0, 0, 0);
      expect(findSnoozeTime('until_tomorrow', today)).toBeCloseTo(
        nextDay.getTime() / 1000
      );
    });

    it('should return next week monday 9.00AM time stamp if until_next_week is passed', () => {
      const today = new Date('06/16/2023');
      const startOfNextWeek = new Date('06/19/2023');
      startOfNextWeek.setHours(9, 0, 0, 0);
      expect(findSnoozeTime('until_next_week', today)).toBeCloseTo(
        startOfNextWeek.getTime() / 1000
      );
    });

    it('should return next month 9.00AM time stamp if until_next_month is passed', () => {
      const today = new Date('06/21/2023');
      const startOfNextMonth = new Date('07/03/2023');
      startOfNextMonth.setHours(9, 0, 0, 0);
      expect(findSnoozeTime('until_next_month', today)).toBeCloseTo(
        startOfNextMonth.getTime() / 1000
      );
    });
  });

  describe('snoozedReopenTime', () => {
    beforeEach(() => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2024-01-01T12:00:00Z'));
    });

    afterEach(() => {
      vi.useRealTimers();
    });

    it('should return formatted date with year if snoozedUntil is not in current year', () => {
      // Input is 09:00 UTC.
      // If your environment is UTC, this will be 9.00am.
      expect(snoozedReopenTime('2023-06-07T09:00:00.000Z')).toEqual(
        '7 Jun 2023, 9.00am'
      );
    });

    it('should return formatted date without year if snoozedUntil is in current year', () => {
      // This uses 2024 because we mocked the system time above
      expect(snoozedReopenTime('2024-06-07T09:00:00.000Z')).toEqual(
        '7 Jun, 9.00am'
      );
    });
  });

  describe('findNextDay', () => {
    it('should return next day', () => {
      const today = new Date('06/16/2023');
      const nextDay = new Date('06/17/2023');
      expect(findNextDay(today)).toEqual(nextDay);
    });
  });

  describe('snoozedReopenTimeToTimestamp', () => {
    it('should return timestamp if snoozedUntil is not nil', () => {
      expect(snoozedReopenTimeToTimestamp('2023-06-07T09:00:00.000Z')).toEqual(
        1686128400
      );
    });
    it('should return nil if snoozedUntil is nil', () => {
      expect(snoozedReopenTimeToTimestamp(null)).toEqual(null);
    });
  });

  describe('shortenSnoozeTime', () => {
    it('should return shortened time if snoozedUntil is not nil and day is passed', () => {
      expect(shortenSnoozeTime('1 day')).toEqual('1d');
    });

    it('should return shortened time if snoozedUntil is not nil and month is passed', () => {
      expect(shortenSnoozeTime('1 month')).toEqual('1mo');
    });

    it('should return shortened time if snoozedUntil is not nil and year is passed', () => {
      expect(shortenSnoozeTime('1 year')).toEqual('1y');
    });

    it('should return shortened time if snoozedUntil is not nil and hour is passed', () => {
      expect(shortenSnoozeTime('1 hour')).toEqual('1h');
    });

    it('should return shortened time if snoozedUntil is not nil and minutes is passed', () => {
      expect(shortenSnoozeTime('1 minutes')).toEqual('1m');
    });

    it('should return shortened time if snoozedUntil is not nil and in is passed', () => {
      expect(shortenSnoozeTime('in 1 hour')).toEqual('1h');
    });

    it('should return nil if snoozedUntil is nil', () => {
      expect(shortenSnoozeTime(null)).toEqual(null);
    });
  });

  describe('generateSnoozeSuggestions label expansion', () => {
    const now = new Date('2023-06-16T10:00:00');

    it('expands abbreviated units: "1d" → "1 Day"', () => {
      const results = generateSnoozeSuggestions('1d', now);
      expect(results.length).toBeGreaterThan(0);
      expect(results[0].label).toBe('1 day');
    });

    it('expands abbreviated units: "2 d" → "2 Days"', () => {
      const results = generateSnoozeSuggestions('2 d', now);
      expect(results.length).toBeGreaterThan(0);
      expect(results[0].label).toBe('2 days');
    });

    it('expands abbreviated units: "1h" → "1 Hour"', () => {
      const results = generateSnoozeSuggestions('1h', now);
      expect(results.length).toBeGreaterThan(0);
      expect(results[0].label).toBe('1 hour');
    });

    it('expands abbreviated units: "2min" → "2 Minutes"', () => {
      const results = generateSnoozeSuggestions('2min', now);
      expect(results.length).toBeGreaterThan(0);
      expect(results[0].label).toBe('2 minutes');
    });

    it('handles singular: "1 hours" → "1 Hour"', () => {
      const results = generateSnoozeSuggestions('1 hours', now);
      expect(results.length).toBeGreaterThan(0);
      expect(results[0].label).toBe('1 hour');
    });

    it('handles singular: "1 minutes" → "1 Minute"', () => {
      const results = generateSnoozeSuggestions('1 minutes', now);
      expect(results.length).toBeGreaterThan(0);
      expect(results[0].label).toBe('1 minute');
    });

    it('keeps plural for non-1: "2 days" → "2 Days"', () => {
      const results = generateSnoozeSuggestions('2 days', now);
      expect(results.length).toBeGreaterThan(0);
      expect(results[0].label).toBe('2 days');
    });

    it('expands compound: "1h30m" → "1 Hour 30 Minutes"', () => {
      const results = generateSnoozeSuggestions('1h30m', now);
      expect(results.length).toBeGreaterThan(0);
      expect(results[0].label).toBe('1 hour 30 minutes');
    });
  });
});
