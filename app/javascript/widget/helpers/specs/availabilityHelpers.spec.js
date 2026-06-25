import { utcToZonedTime } from 'date-fns-tz';
import {
  isOpenAllDay,
  isClosedAllDay,
  isInWorkingHours,
  findNextAvailableSlotDetails,
  findNextAvailableSlotDiff,
  isOnline,
} from '../availabilityHelpers';

// Mock date-fns-tz
vi.mock('date-fns-tz', () => ({
  utcToZonedTime: vi.fn(),
}));

describe('availabilityHelpers', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('isOpenAllDay', () => {
    it('should return true when slot is marked as open_all_day', () => {
      const mockDate = new Date('2024-01-15T10:00:00.000Z'); // Monday
      mockDate.getDay = vi.fn().mockReturnValue(1);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [{ dayOfWeek: 1, openAllDay: true }];

      expect(isOpenAllDay(new Date(), 'UTC', workingHours)).toBe(true);
    });

    it('should return false when slot is not open_all_day', () => {
      const mockDate = new Date('2024-01-15T10:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [
        { dayOfWeek: 1, openHour: 9, closeHour: 17, openAllDay: false },
      ];

      expect(isOpenAllDay(new Date(), 'UTC', workingHours)).toBe(false);
    });

    it('should return false when no config exists for the day', () => {
      const mockDate = new Date('2024-01-15T10:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [
        { dayOfWeek: 2, openHour: 9, closeHour: 17 }, // Tuesday config
      ];

      expect(isOpenAllDay(new Date(), 'UTC', workingHours)).toBe(false);
    });
  });

  describe('isClosedAllDay', () => {
    it('should return true when slot is marked as closed_all_day', () => {
      const mockDate = new Date('2024-01-15T10:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [{ dayOfWeek: 1, closedAllDay: true }];

      expect(isClosedAllDay(new Date(), 'UTC', workingHours)).toBe(true);
    });

    it('should return false when slot is not closed_all_day', () => {
      const mockDate = new Date('2024-01-15T10:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [
        { dayOfWeek: 1, openHour: 9, closeHour: 17, closedAllDay: false },
      ];

      expect(isClosedAllDay(new Date(), 'UTC', workingHours)).toBe(false);
    });

    it('should return false when no config exists for the day', () => {
      const mockDate = new Date('2024-01-15T10:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [{ dayOfWeek: 2, openHour: 9, closeHour: 17 }];

      expect(isClosedAllDay(new Date(), 'UTC', workingHours)).toBe(false);
    });
  });

  describe('isInWorkingHours', () => {
    it('should return false when no working hours are configured', () => {
      expect(isInWorkingHours(new Date(), 'UTC', [])).toBe(false);
    });

    it('should return true when open_all_day is true', () => {
      const mockDate = new Date('2024-01-15T10:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(10);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [{ dayOfWeek: 1, openAllDay: true }];

      expect(isInWorkingHours(new Date(), 'UTC', workingHours)).toBe(true);
    });

    it('should return false when closed_all_day is true', () => {
      const mockDate = new Date('2024-01-15T10:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(10);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [{ dayOfWeek: 1, closedAllDay: true }];

      expect(isInWorkingHours(new Date(), 'UTC', workingHours)).toBe(false);
    });

    it('should return true when current time is within working hours', () => {
      const mockDate = new Date('2024-01-15T10:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(10);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [
        {
          dayOfWeek: 1,
          openHour: 9,
          openMinutes: 0,
          closeHour: 17,
          closeMinutes: 0,
        },
      ];

      expect(isInWorkingHours(new Date(), 'UTC', workingHours)).toBe(true);
    });

    it('should return false when current time is before opening', () => {
      const mockDate = new Date('2024-01-15T08:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(8);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [{ dayOfWeek: 1, openHour: 9, closeHour: 17 }];

      expect(isInWorkingHours(new Date(), 'UTC', workingHours)).toBe(false);
    });

    it('should return false when current time is after closing', () => {
      const mockDate = new Date('2024-01-15T18:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(18);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [{ dayOfWeek: 1, openHour: 9, closeHour: 17 }];

      expect(isInWorkingHours(new Date(), 'UTC', workingHours)).toBe(false);
    });

    it('should handle minutes in time comparison', () => {
      const mockDate = new Date('2024-01-15T09:30:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(9);
      mockDate.getMinutes = vi.fn().mockReturnValue(30);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [
        {
          dayOfWeek: 1,
          openHour: 9,
          openMinutes: 15,
          closeHour: 17,
          closeMinutes: 30,
        },
      ];

      expect(isInWorkingHours(new Date(), 'UTC', workingHours)).toBe(true);
    });

    it('should return false when no config for current day', () => {
      const mockDate = new Date('2024-01-15T10:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(10);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [
        { dayOfWeek: 2, openHour: 9, closeHour: 17 }, // Only Tuesday
      ];

      expect(isInWorkingHours(new Date(), 'UTC', workingHours)).toBe(false);
    });
  });

  describe('findNextAvailableSlotDetails', () => {
    it('should return null when no open days exist', () => {
      const mockDate = new Date('2024-01-15T10:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(10);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [
        { dayOfWeek: 0, closedAllDay: true },
        { dayOfWeek: 1, closedAllDay: true },
        { dayOfWeek: 2, closedAllDay: true },
        { dayOfWeek: 3, closedAllDay: true },
        { dayOfWeek: 4, closedAllDay: true },
        { dayOfWeek: 5, closedAllDay: true },
        { dayOfWeek: 6, closedAllDay: true },
      ];

      expect(
        findNextAvailableSlotDetails(new Date(), 'UTC', workingHours)
      ).toBe(null);
    });

    it('should return today slot when not opened yet', () => {
      const mockDate = new Date('2024-01-15T08:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(8);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [
        { dayOfWeek: 1, openHour: 9, openMinutes: 30, closeHour: 17 },
      ];

      const result = findNextAvailableSlotDetails(
        new Date(),
        'UTC',
        workingHours
      );

      expect(result).toEqual({
        config: workingHours[0],
        minutesUntilOpen: 90, // 1.5 hours = 90 minutes
        daysUntilOpen: 0,
        dayOfWeek: 1,
      });
    });

    it('should return tomorrow slot when today is past closing', () => {
      const mockDate = new Date('2024-01-15T18:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(18);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [
        { dayOfWeek: 1, openHour: 9, closeHour: 17 },
        { dayOfWeek: 2, openHour: 9, closeHour: 17 },
      ];

      const result = findNextAvailableSlotDetails(
        new Date(),
        'UTC',
        workingHours
      );

      expect(result).toEqual({
        config: workingHours[1],
        minutesUntilOpen: 900, // 15 hours = 900 minutes
        daysUntilOpen: 1,
        dayOfWeek: 2,
      });
    });

    it('should skip closed days and find next open day', () => {
      const mockDate = new Date('2024-01-15T18:00:00.000Z'); // Monday evening
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(18);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [
        { dayOfWeek: 1, openHour: 9, closeHour: 17 },
        { dayOfWeek: 2, closedAllDay: true },
        { dayOfWeek: 3, closedAllDay: true },
        { dayOfWeek: 4, openHour: 10, closeHour: 16 },
      ];

      const result = findNextAvailableSlotDetails(
        new Date(),
        'UTC',
        workingHours
      );

      // Monday 18:00 to Thursday 10:00
      // Rest of Monday: 6 hours (18:00 to 24:00) = 360 minutes
      // Tuesday: 24 hours = 1440 minutes
      // Wednesday: 24 hours = 1440 minutes
      // Thursday morning: 10 hours = 600 minutes
      // Total: 360 + 1440 + 1440 + 600 = 3840 minutes
      expect(result).toEqual({
        config: workingHours[3],
        minutesUntilOpen: 3840, // 64 hours = 3840 minutes
        daysUntilOpen: 3,
        dayOfWeek: 4,
      });
    });

    it('should handle open_all_day slots', () => {
      const mockDate = new Date('2024-01-15T18:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(18);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [
        { dayOfWeek: 1, openHour: 9, closeHour: 17 },
        { dayOfWeek: 2, openAllDay: true },
      ];

      const result = findNextAvailableSlotDetails(
        new Date(),
        'UTC',
        workingHours
      );

      expect(result).toEqual({
        config: workingHours[1],
        minutesUntilOpen: 360, // 6 hours to midnight = 360 minutes
        daysUntilOpen: 1,
        dayOfWeek: 2,
      });
    });

    it('should wrap around week correctly', () => {
      const mockDate = new Date('2024-01-20T18:00:00.000Z'); // Saturday evening
      mockDate.getDay = vi.fn().mockReturnValue(6);
      mockDate.getHours = vi.fn().mockReturnValue(18);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [
        { dayOfWeek: 1, openHour: 9, closeHour: 17 }, // Monday
      ];

      const result = findNextAvailableSlotDetails(
        new Date(),
        'UTC',
        workingHours
      );

      // Saturday 18:00 to Monday 9:00
      // Rest of Saturday: 6 hours = 360 minutes
      // Sunday: 24 hours = 1440 minutes
      // Monday morning: 9 hours = 540 minutes
      // Total: 360 + 1440 + 540 = 2340 minutes
      expect(result).toEqual({
        config: workingHours[0],
        minutesUntilOpen: 2340, // 39 hours = 2340 minutes
        daysUntilOpen: 2,
        dayOfWeek: 1,
      });
    });

    it('should handle today open_all_day correctly', () => {
      const mockDate = new Date('2024-01-15T10:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(10);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [
        { dayOfWeek: 1, openAllDay: true },
        { dayOfWeek: 2, openHour: 9, closeHour: 17 },
      ];

      // Should skip today since it's open_all_day and look for next slot
      const result = findNextAvailableSlotDetails(
        new Date(),
        'UTC',
        workingHours
      );

      expect(result).toEqual({
        config: workingHours[1],
        minutesUntilOpen: 1380, // Rest of today + 9 hours tomorrow = 1380 minutes
        daysUntilOpen: 1,
        dayOfWeek: 2,
      });
    });
  });

  describe('findNextAvailableSlotDiff', () => {
    it('should return 0 when currently in working hours', () => {
      const mockDate = new Date('2024-01-15T10:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(10);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [{ dayOfWeek: 1, openHour: 9, closeHour: 17 }];

      expect(findNextAvailableSlotDiff(new Date(), 'UTC', workingHours)).toBe(
        0
      );
    });

    it('should return minutes until next slot when not in working hours', () => {
      const mockDate = new Date('2024-01-15T08:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(8);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [{ dayOfWeek: 1, openHour: 9, closeHour: 17 }];

      expect(findNextAvailableSlotDiff(new Date(), 'UTC', workingHours)).toBe(
        60
      );
    });

    it('should return null when no next slot available', () => {
      const mockDate = new Date('2024-01-15T10:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(10);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [
        { dayOfWeek: 0, closedAllDay: true },
        { dayOfWeek: 1, closedAllDay: true },
        { dayOfWeek: 2, closedAllDay: true },
        { dayOfWeek: 3, closedAllDay: true },
        { dayOfWeek: 4, closedAllDay: true },
        { dayOfWeek: 5, closedAllDay: true },
        { dayOfWeek: 6, closedAllDay: true },
      ];

      expect(findNextAvailableSlotDiff(new Date(), 'UTC', workingHours)).toBe(
        null
      );
    });
  });

  describe('isOnline', () => {
    it('should return agent status when working hours disabled', () => {
      expect(isOnline(false, new Date(), 'UTC', [], true)).toBe(true);
      expect(isOnline(false, new Date(), 'UTC', [], false)).toBe(false);
    });

    it('should check both working hours and agents when enabled', () => {
      const mockDate = new Date('2024-01-15T10:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(10);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [{ dayOfWeek: 1, openHour: 9, closeHour: 17 }];

      // In working hours + agents available = online
      expect(isOnline(true, new Date(), 'UTC', workingHours, true)).toBe(true);

      // In working hours but no agents = offline
      expect(isOnline(true, new Date(), 'UTC', workingHours, false)).toBe(
        false
      );
    });

    it('should return false when outside working hours even with agents', () => {
      const mockDate = new Date('2024-01-15T08:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(8);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [{ dayOfWeek: 1, openHour: 9, closeHour: 17 }];

      expect(isOnline(true, new Date(), 'UTC', workingHours, true)).toBe(false);
    });

    it('should handle open_all_day with agents', () => {
      const mockDate = new Date('2024-01-15T02:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(2);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [{ dayOfWeek: 1, openAllDay: true }];

      expect(isOnline(true, new Date(), 'UTC', workingHours, true)).toBe(true);
      expect(isOnline(true, new Date(), 'UTC', workingHours, false)).toBe(
        false
      );
    });

    it('should handle string date input', () => {
      const mockDate = new Date('2024-01-15T10:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(10);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [{ dayOfWeek: 1, openHour: 9, closeHour: 17 }];

      expect(
        isOnline(true, '2024-01-15T10:00:00.000Z', 'UTC', workingHours, true)
      ).toBe(true);
    });
  });

  describe('Timezone handling', () => {
    it('should correctly handle different timezones', () => {
      const mockDate = new Date('2024-01-15T15:30:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(15);
      mockDate.getMinutes = vi.fn().mockReturnValue(30);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [{ dayOfWeek: 1, openHour: 9, closeHour: 17 }];

      expect(isInWorkingHours(new Date(), 'Asia/Kolkata', workingHours)).toBe(
        true
      );
      expect(vi.mocked(utcToZonedTime)).toHaveBeenCalledWith(
        expect.any(String),
        'Asia/Kolkata'
      );
    });

    it('should handle UTC offset format', () => {
      const mockDate = new Date('2024-01-15T10:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(10);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [{ dayOfWeek: 1, openHour: 9, closeHour: 17 }];

      expect(isInWorkingHours(new Date(), '+05:30', workingHours)).toBe(true);
      expect(vi.mocked(utcToZonedTime)).toHaveBeenCalledWith(
        expect.any(String),
        '+05:30'
      );
    });
  });

  describe('Edge cases', () => {
    it('should handle working hours at exact boundaries', () => {
      // Test at exact opening time
      const mockDate1 = new Date('2024-01-15T09:00:00.000Z');
      mockDate1.getDay = vi.fn().mockReturnValue(1);
      mockDate1.getHours = vi.fn().mockReturnValue(9);
      mockDate1.getMinutes = vi.fn().mockReturnValue(0);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate1);

      const workingHours = [{ dayOfWeek: 1, openHour: 9, closeHour: 17 }];

      expect(isInWorkingHours(new Date(), 'UTC', workingHours)).toBe(true);

      // Test at exact closing time
      const mockDate2 = new Date('2024-01-15T17:00:00.000Z');
      mockDate2.getDay = vi.fn().mockReturnValue(1);
      mockDate2.getHours = vi.fn().mockReturnValue(17);
      mockDate2.getMinutes = vi.fn().mockReturnValue(0);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate2);

      expect(isInWorkingHours(new Date(), 'UTC', workingHours)).toBe(false);
    });

    it('should handle one minute before closing', () => {
      const mockDate = new Date('2024-01-15T16:59:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(16);
      mockDate.getMinutes = vi.fn().mockReturnValue(59);
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const workingHours = [{ dayOfWeek: 1, openHour: 9, closeHour: 17 }];

      expect(isInWorkingHours(new Date(), 'UTC', workingHours)).toBe(true);
    });
  });
});
