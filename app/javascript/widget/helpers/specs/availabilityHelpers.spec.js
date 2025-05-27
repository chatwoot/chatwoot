// availabilityHelpers.spec.js with detailed comments
import { utcToZonedTime } from 'date-fns-tz';
import { getTime } from 'dashboard/routes/dashboard/settings/inbox/helpers/businessHour.js';
import {
  getDateWithOffset,
  getWorkingHoursInfo,
  getNextAvailableTime,
} from '../availabilityHelpers';

// Mock the date-fns-tz library so we can control what it returns
vi.mock('date-fns-tz', () => ({
  utcToZonedTime: vi.fn(), // Create a mock function we can control
}));

// Mock the businessHour helper to simulate time formatting
vi.mock(
  'dashboard/routes/dashboard/settings/inbox/helpers/businessHour.js',
  () => ({
    getTime: vi.fn(),
  })
);

describe('availabilityHelpers', () => {
  describe('getDateWithOffset', () => {
    beforeEach(() => {
      // Clear all mock function calls before each test
      vi.resetAllMocks();
    });

    it('should return date with UTC offset', () => {
      const mockDate = new Date('2024-01-15T10:00:00.000Z');
      mockDate.getHours = vi.fn().mockReturnValue(15); // 10:00 + 5:30 = 15:30
      mockDate.getMinutes = vi.fn().mockReturnValue(30);

      vi.spyOn(Date.prototype, 'toISOString').mockReturnValue(
        '2024-01-15T10:00:00.000Z'
      );
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const result = getDateWithOffset('+05:30');
      expect(result).toBeInstanceOf(Date);
      expect(result.getHours()).toBe(15);
      expect(result.getMinutes()).toBe(30);
    });

    it('should work with timezone name', () => {
      // Similar setup but testing with timezone name instead of offset
      const mockDate = new Date('2024-01-15T10:00:00.000Z');
      mockDate.getHours = vi.fn().mockReturnValue(15);
      mockDate.getMinutes = vi.fn().mockReturnValue(30);

      vi.spyOn(Date.prototype, 'toISOString').mockReturnValue(
        '2024-01-15T10:00:00.000Z'
      );
      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      // Call with timezone name instead of offset
      const result = getDateWithOffset('Asia/Kolkata');
      expect(result).toBeInstanceOf(Date);
      expect(result.getHours()).toBe(15);
      expect(result.getMinutes()).toBe(30);
    });
  });

  describe('getWorkingHoursInfo', () => {
    // Sample working hours configuration for testing
    const mockWorkingHours = [
      {
        day_of_week: 1, // Monday
        open_hour: 9, // Opens at 9:00 AM
        open_minutes: 0,
        close_hour: 17, // Closes at 5:00 PM
        close_minutes: 0,
      },
      {
        day_of_week: 2, // Tuesday
        open_hour: 9,
        open_minutes: 0,
        close_hour: 17,
        close_minutes: 0,
      },
      {
        day_of_week: 3, // Wednesday
        open_all_day: true, // Open 24 hours
      },
      {
        day_of_week: 4, // Thursday
        closed_all_day: true, // Closed all day
      },
      {
        day_of_week: 5, // Friday
        open_hour: 10,
        open_minutes: 30, // Opens at 10:30 AM
        close_hour: 16,
        close_minutes: 30, // Closes at 4:30 PM
      },
    ];

    beforeEach(() => {
      vi.clearAllMocks();
    });

    it('should return disabled state when not enabled', () => {
      const result = getWorkingHoursInfo(mockWorkingHours, 'UTC', false);
      // Should return disabled state with default "open" status
      expect(result).toEqual({
        enabled: false,
        isInWorkingHours: true, // Default to true when disabled
      });
    });

    it('should detect when in working hours on regular day', () => {
      // Create a mock date for Monday at 10:00 AM
      const mockDate = new Date('2024-01-15T10:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1); // Monday
      mockDate.getHours = vi.fn().mockReturnValue(10); // 10 AM
      mockDate.getMinutes = vi.fn().mockReturnValue(0);

      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const result = getWorkingHoursInfo(mockWorkingHours, 'UTC', true);
      expect(result.enabled).toBe(true);
      expect(result.isInWorkingHours).toBe(true); // 10 AM is between 9 AM and 5 PM
      expect(result.currentDay).toBe(1); // Monday
      expect(result.todayConfig.day_of_week).toBe(1); // Found Monday's config
    });

    it('should detect when outside working hours', () => {
      // Monday at 6:00 PM (after closing time)
      const mockDate = new Date('2024-01-15T18:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(18); // 6 PM
      mockDate.getMinutes = vi.fn().mockReturnValue(0);

      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const result = getWorkingHoursInfo(mockWorkingHours, 'UTC', true);
      // Should not be in working hours (closed at 5 PM)
      expect(result.isInWorkingHours).toBe(false);
    });

    it('should handle open_all_day configuration', () => {
      // Wednesday at 11:59 PM (open all day)
      const mockDate = new Date('2024-01-17T23:59:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(3); // Wednesday
      mockDate.getHours = vi.fn().mockReturnValue(23); // 11 PM
      mockDate.getMinutes = vi.fn().mockReturnValue(59);

      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const result = getWorkingHoursInfo(mockWorkingHours, 'UTC', true);
      // Should be in working hours even at 11:59 PM
      expect(result.isInWorkingHours).toBe(true);
    });

    it('should handle closed_all_day configuration', () => {
      // Thursday at noon (closed all day)
      const mockDate = new Date('2024-01-18T12:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(4); // Thursday
      mockDate.getHours = vi.fn().mockReturnValue(12);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);

      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const result = getWorkingHoursInfo(mockWorkingHours, 'UTC', true);
      // Should not be in working hours (closed all day)
      expect(result.isInWorkingHours).toBe(false);
    });

    it('should detect all days closed', () => {
      // Create array where every day is closed
      const allClosedHours = [
        { day_of_week: 0, closed_all_day: true }, // Sunday
        { day_of_week: 1, closed_all_day: true }, // Monday
        { day_of_week: 2, closed_all_day: true }, // Tuesday
        { day_of_week: 3, closed_all_day: true }, // Wednesday
        { day_of_week: 4, closed_all_day: true }, // Thursday
        { day_of_week: 5, closed_all_day: true }, // Friday
        { day_of_week: 6, closed_all_day: true }, // Saturday
      ];

      const mockDate = new Date('2024-01-15T12:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(12);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);

      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const result = getWorkingHoursInfo(allClosedHours, 'UTC', true);
      // Should detect that all days are closed
      expect(result.allClosed).toBe(true);
      expect(result.isInWorkingHours).toBe(false);
    });

    it('should handle minutes in time calculation', () => {
      // Friday at 10:45 AM (opens at 10:30 AM)
      const mockDate = new Date('2024-01-19T10:45:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(5); // Friday
      mockDate.getHours = vi.fn().mockReturnValue(10);
      mockDate.getMinutes = vi.fn().mockReturnValue(45); // 15 minutes after opening

      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const result = getWorkingHoursInfo(mockWorkingHours, 'UTC', true);
      // Should be in working hours (10:45 is after 10:30 opening)
      expect(result.isInWorkingHours).toBe(true);
    });

    it('should handle case at exact opening time', () => {
      // Monday at exactly 9:00 AM
      const mockDate = new Date('2024-01-15T09:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(9);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);

      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const result = getWorkingHoursInfo(mockWorkingHours, 'UTC', true);
      // Should be in working hours at exact opening time
      expect(result.isInWorkingHours).toBe(true);
    });

    it('should handle edge case at exact closing time', () => {
      // Monday at exactly 5:00 PM
      const mockDate = new Date('2024-01-15T17:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(1);
      mockDate.getHours = vi.fn().mockReturnValue(17);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);

      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const result = getWorkingHoursInfo(mockWorkingHours, 'UTC', true);
      // Should NOT be in working hours at exact closing time
      expect(result.isInWorkingHours).toBe(false);
    });

    it('should handle missing day configuration', () => {
      // Saturday (no configuration for this day)
      const mockDate = new Date('2024-01-20T12:00:00.000Z');
      mockDate.getDay = vi.fn().mockReturnValue(6); // Saturday
      mockDate.getHours = vi.fn().mockReturnValue(12);
      mockDate.getMinutes = vi.fn().mockReturnValue(0);

      vi.mocked(utcToZonedTime).mockReturnValue(mockDate);

      const result = getWorkingHoursInfo(mockWorkingHours, 'UTC', true);
      // Should not be in working hours (no config = closed)
      expect(result.isInWorkingHours).toBe(false);
      expect(result.todayConfig).toEqual({}); // Empty config object
    });
  });

  describe('getNextAvailableTime', () => {
    // Sample working hours for testing next available time
    const mockWorkingHours = [
      {
        day_of_week: 1, // Monday
        open_hour: 9,
        open_minutes: 0,
        close_hour: 17,
        close_minutes: 0,
      },
      {
        day_of_week: 2, // Tuesday
        open_hour: 9,
        open_minutes: 0,
        close_hour: 17,
        close_minutes: 0,
      },
      {
        day_of_week: 3, // Wednesday
        open_hour: 9,
        open_minutes: 0,
        close_hour: 17,
        close_minutes: 0,
      },
      {
        day_of_week: 4, // Thursday
        closed_all_day: true, // Closed
      },
      {
        day_of_week: 5, // Friday
        open_hour: 10,
        open_minutes: 30,
        close_hour: 16,
        close_minutes: 30,
      },
    ];

    beforeEach(() => {
      // Mock getTime to return formatted time strings
      vi.mocked(getTime).mockImplementation((hour, minute) => {
        const formattedHour = hour < 10 ? `0${hour}` : hour;
        const formattedMinute = minute < 10 ? `0${minute}` : minute;
        // Determine AM/PM
        const meridian = hour >= 12 ? 'PM' : 'AM';
        return `${formattedHour}:${formattedMinute} ${meridian}`;
      });
    });

    it('should return empty state when no working hours', () => {
      const workingHoursInfo = {
        enabled: true,
        isInWorkingHours: false,
        currentDay: 1,
        currentHour: 18,
        currentMinute: 0,
        todayConfig: {},
        workingHours: [], // No working hours configured
      };

      const result = getNextAvailableTime(workingHoursInfo, 'en');
      // Should return "back in some time" when no hours configured
      expect(result).toEqual({ type: 'BACK_IN_SOME_TIME' });
    });

    it('should return tomorrow when next day is tomorrow', () => {
      // Monday at 6 PM (after closing), Tuesday opens next
      const workingHoursInfo = {
        currentDay: 1, // Monday
        currentHour: 18, // 6 PM
        currentMinute: 0,
        todayConfig: { day_of_week: 1, close_hour: 17 }, // Closed at 5 PM
        workingHours: mockWorkingHours,
      };

      const result = getNextAvailableTime(workingHoursInfo, 'en');
      // Should show "tomorrow" for next day
      expect(result).toEqual({ type: 'BACK_TOMORROW' });
    });

    it('should return day name when 2+ days away', () => {
      // Create scenario where next open day is Friday
      const tuesdayToThursdayClosed = [
        {
          day_of_week: 1, // Monday
          open_hour: 9,
          open_minutes: 0,
          close_hour: 17,
          close_minutes: 0,
        },
        { day_of_week: 2, closed_all_day: true }, // Tuesday closed
        { day_of_week: 3, closed_all_day: true }, // Wednesday closed
        { day_of_week: 4, closed_all_day: true }, // Thursday closed
        {
          day_of_week: 5, // Friday
          open_hour: 9,
          open_minutes: 0,
          close_hour: 17,
          close_minutes: 0,
        },
      ];

      // Monday evening, next open is Friday
      const workingHoursInfo = {
        currentDay: 1,
        currentHour: 18,
        currentMinute: 0,
        todayConfig: { day_of_week: 1, close_hour: 17 },
        workingHours: tuesdayToThursdayClosed,
      };

      const result = getNextAvailableTime(workingHoursInfo, 'en');
      // Should show day name for 2+ days away
      expect(result).toEqual({ type: 'BACK_ON', value: 'Friday' });
    });

    it('should return specific time when 3+ hours away same day', () => {
      // Monday at 5 AM, opens at 9 AM (4 hours away)
      const workingHoursInfo = {
        currentDay: 1,
        currentHour: 5,
        currentMinute: 0,
        todayConfig: { day_of_week: 1, open_hour: 9, open_minutes: 0 },
        workingHours: mockWorkingHours,
      };

      const result = getNextAvailableTime(workingHoursInfo, 'en');
      // Should show specific opening time
      expect(result).toEqual({ type: 'BACK_AT', value: '09:00 AM' });
    });

    it('should return relative hours when 1-3 hours away', () => {
      // Monday at 7 AM, opens at 9 AM (2 hours away)
      const workingHoursInfo = {
        currentDay: 1,
        currentHour: 7,
        currentMinute: 0,
        todayConfig: { day_of_week: 1, open_hour: 9, open_minutes: 0 },
        workingHours: mockWorkingHours,
      };

      const result = getNextAvailableTime(workingHoursInfo, 'en');
      // Should show relative time in hours
      expect(result).toEqual({ type: 'BACK_IN', value: 'in 2 hours' });
    });

    it('should return relative minutes when less than 1 hour away', () => {
      // Monday at 8:30 AM, opens at 9 AM (30 minutes away)
      const workingHoursInfo = {
        currentDay: 1,
        currentHour: 8,
        currentMinute: 30,
        todayConfig: { day_of_week: 1, open_hour: 9, open_minutes: 0 },
        workingHours: mockWorkingHours,
      };

      const result = getNextAvailableTime(workingHoursInfo, 'en');
      // Should show relative time in minutes
      expect(result).toEqual({ type: 'BACK_IN', value: 'in 30 minutes' });
    });

    it('should round minutes to nearest 5 when less than 1 hour away', () => {
      // Monday at 8:47 AM, opens at 9 AM (13 minutes away)
      const workingHoursInfo = {
        currentDay: 1,
        currentHour: 8,
        currentMinute: 47,
        todayConfig: { day_of_week: 1, open_hour: 9, open_minutes: 0 },
        workingHours: mockWorkingHours,
      };

      const result = getNextAvailableTime(workingHoursInfo, 'en');
      // Should round 13 minutes up to 15
      expect(result).toEqual({ type: 'BACK_IN', value: 'in 15 minutes' });
    });

    it('should handle closed all day - next day', () => {
      // Thursday (closed), Friday opens next
      const workingHoursInfo = {
        currentDay: 4, // Thursday
        currentHour: 12,
        currentMinute: 0,
        todayConfig: { day_of_week: 4, closed_all_day: true },
        workingHours: mockWorkingHours,
      };

      const result = getNextAvailableTime(workingHoursInfo, 'en');
      // Should show tomorrow (Friday)
      expect(result).toEqual({ type: 'BACK_TOMORROW' });
    });

    it('should handle when all days are closed', () => {
      // Create array where every day is closed
      const allClosed = Array(7)
        .fill(null)
        .map((_, i) => ({
          day_of_week: i,
          closed_all_day: true,
        }));

      const workingHoursInfo = {
        currentDay: 1,
        currentHour: 12,
        currentMinute: 0,
        todayConfig: { day_of_week: 1, closed_all_day: true },
        workingHours: allClosed,
      };

      const result = getNextAvailableTime(workingHoursInfo, 'en');
      // Should return "some time" when all closed
      expect(result).toEqual({ type: 'BACK_IN_SOME_TIME' });
    });

    it('should handle exact closing time edge case', () => {
      // Monday at exactly 5:00 PM (closing time)
      const workingHoursInfo = {
        currentDay: 1,
        currentHour: 17, // 5 PM
        currentMinute: 0,
        todayConfig: { day_of_week: 1, close_hour: 17, close_minutes: 0 },
        workingHours: mockWorkingHours,
      };

      const result = getNextAvailableTime(workingHoursInfo, 'en');
      // Should show tomorrow since we're at closing time
      expect(result).toEqual({ type: 'BACK_TOMORROW' });
    });

    it('should handle opening time with minutes', () => {
      // Friday at 8 AM, opens at 10:30 AM (2.5 hours)
      const workingHoursInfo = {
        currentDay: 5,
        currentHour: 8,
        currentMinute: 0,
        todayConfig: { day_of_week: 5, open_hour: 10, open_minutes: 30 },
        workingHours: mockWorkingHours,
      };

      const result = getNextAvailableTime(workingHoursInfo, 'en');
      // Should round up to 3 hours
      expect(result).toEqual({ type: 'BACK_IN', value: 'in 3 hours' });
    });
  });
});
