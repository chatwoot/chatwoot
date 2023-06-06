import { findSnoozeTime } from '../snoozeHelpers';

describe('#Snooze Helpers', () => {
  describe('findSnoozeTime', () => {
    it('should return nil if nextReply is passed', () => {
      expect(findSnoozeTime('nextReply')).toEqual(null);
    });

    it('should return next hour time stamp if an hour from now is passed', () => {
      const nextHour = new Date();
      nextHour.setHours(nextHour.getHours() + 1);
      expect(findSnoozeTime('an hour from now')).toBeCloseTo(
        Math.round(nextHour.getTime() / 1000),
        2
      );
    });

    it('should return next day 9.00AM time stamp if tomorrow at 9.00AM is passed', () => {
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      tomorrow.setHours(9, 0, 0, 0);
      expect(findSnoozeTime('tomorrow at 9.00AM')).toBeCloseTo(
        tomorrow.getTime() / 1000
      );
    });

    it('should return next week 9.00AM time stamp if next week at 9.00AM is passed', () => {
      const nextWeek = new Date();
      nextWeek.setDate(nextWeek.getDate() + 7);
      nextWeek.setHours(9, 0, 0, 0);
      expect(findSnoozeTime('next week at 9.00AM')).toBeCloseTo(
        nextWeek.getTime() / 1000
      );
    });

    it('should return next month 9.00AM time stamp if next month at 9.00AM is passed', () => {
      const nextMonth = new Date();
      nextMonth.setMonth(nextMonth.getMonth() + 1);
      nextMonth.setHours(9, 0, 0, 0);
      expect(findSnoozeTime('next month at 9.00AM')).toBeCloseTo(
        nextMonth.getTime() / 1000
      );
    });
  });
});
