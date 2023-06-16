import {
  findSnoozeTime,
  conversationReopenTime,
  findStartOfNextWeek,
  findStartOfNextMonth,
  findNextDay,
  setHoursToNine,
} from '../snoozeHelpers';

describe('#Snooze Helpers', () => {
  describe('findSnoozeTime', () => {
    it('should return nil if nextReply is passed', () => {
      expect(findSnoozeTime('until_next_reply')).toEqual(null);
    });

    it('should return next hour time stamp if an hour from now is passed', () => {
      const nextHour = new Date();
      nextHour.setHours(nextHour.getHours() + 1);
      expect(findSnoozeTime('an_hour_from_now')).toBeCloseTo(
        Math.floor(nextHour.getTime() / 1000)
      );
    });

    it('should return next day 9.00AM time stamp if tomorrow at 9.00AM is passed', () => {
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

  describe('conversationReopenTime', () => {
    it('should return nil if snoozedUntil is nil', () => {
      expect(conversationReopenTime(null)).toEqual(null);
    });

    it('should return formatted date if snoozedUntil is not nil', () => {
      expect(conversationReopenTime('2023-06-07T09:00:00.000Z')).toEqual(
        '7 Jun, 9.00am'
      );
    });
  });

  describe('findStartOfNextWeek', () => {
    it('should return start of next week', () => {
      const today = new Date('06/16/2023');
      const startOfNextWeek = new Date('06/19/2023');
      expect(findStartOfNextWeek(today)).toEqual(startOfNextWeek);
    });
  });

  describe('findStartOfNextMonth', () => {
    it('should return start of next month', () => {
      const today = new Date('06/21/2023');
      const startOfNextMonth = new Date('07/03/2023');
      expect(findStartOfNextMonth(today)).toEqual(startOfNextMonth);
    });
  });

  describe('findNextDay', () => {
    it('should return next day', () => {
      const today = new Date('06/16/2023');
      const nextDay = new Date('06/17/2023');
      expect(findNextDay(today)).toEqual(nextDay);
    });
  });

  describe('setHoursToNine', () => {
    it('should return date with 9.00AM time', () => {
      const nextDay = new Date('06/17/2023');
      nextDay.setHours(9, 0, 0, 0);
      expect(setHoursToNine(nextDay)).toEqual(nextDay);
    });
  });
});
