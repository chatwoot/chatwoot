import { describe, it, expect } from 'vitest';
import WorkingHours from '../WorkingHoursHelper';
import workingHoursData from './WorkingHourFixtures';

describe('WorkingHours', () => {
  describe('isOpen', () => {
    it('returns true during business hours', () => {
      const workingHours = new WorkingHours(workingHoursData);
      const date = new Date(2025, 0, 6); // Monday
      date.setHours(12, 0, 0); // 12:00
      expect(workingHours.isOpen(date)).toBe(true);
    });

    it('returns false before opening hours', () => {
      const workingHours = new WorkingHours(workingHoursData);
      const date = new Date(2025, 0, 6); // Monday
      date.setHours(8, 0, 0); // 8:00
      expect(workingHours.isOpen(date)).toBe(false);
    });

    it('returns false after closing hours', () => {
      const workingHours = new WorkingHours(workingHoursData);
      const date = new Date(2025, 0, 6); // Monday
      date.setHours(18, 0, 0); // 18:00
      expect(workingHours.isOpen(date)).toBe(false);
    });

    it('returns false on closed days', () => {
      const workingHours = new WorkingHours(workingHoursData);
      const date = new Date(2025, 0, 4); // Saturday
      date.setHours(12, 0, 0); // 12:00
      expect(workingHours.isOpen(date)).toBe(false);
    });

    it('returns true for openAllDay', () => {
      const customData = [...workingHoursData];
      customData[1] = { ...customData[1], openAllDay: true };
      const workingHours = new WorkingHours(customData);
      const date = new Date(2025, 0, 6); // Monday
      date.setHours(22, 0, 0);
      expect(workingHours.isOpen(date)).toBe(true);
    });
  });

  describe('openInMinutes', () => {
    it('returns 0 when currently open', () => {
      const workingHours = new WorkingHours(workingHoursData);
      const date = new Date(2025, 0, 6); // Monday
      date.setHours(12, 0, 0); // 12:00
      expect(workingHours.openInMinutes(date)).toBe(0);
    });

    it('calculates minutes until opening same day', () => {
      const workingHours = new WorkingHours(workingHoursData);
      const date = new Date(2025, 0, 6); // Monday
      date.setHours(8, 0, 0); // 8:00
      expect(workingHours.openInMinutes(date)).toBe(60); // 60 minutes until 9:00
    });

    it('calculates minutes until opening next day', () => {
      const workingHours = new WorkingHours(workingHoursData);
      const date = new Date(2025, 0, 6); // Monday
      date.setHours(23, 0, 0); // 23:00
      // Tuesday opens at 9:00, so it's 10 hours (600 minutes) away
      expect(workingHours.openInMinutes(date)).toBe(600);
    });

    it('handles closed days correctly', () => {
      const workingHours = new WorkingHours(workingHoursData);
      const date = new Date(2025, 0, 4); // Saturday
      date.setHours(12, 0, 0); // 12:00
      // Should find Sunday's opening at 10:00
      const expectedMinutes = (24 - 12) * 60 + 10 * 60; // Remaining hours today + hours until opening tomorrow
      expect(workingHours.openInMinutes(date)).toBe(expectedMinutes);
    });

    it('returns -1 if no opening time found within a week', () => {
      const closedWeek = workingHoursData.map(day => ({
        ...day,
        closedAllDay: true,
      }));
      const workingHours = new WorkingHours(closedWeek);
      const date = new Date(2025, 0, 6); // Monday
      date.setHours(12, 0, 0); // 12:00
      expect(workingHours.openInMinutes(date)).toBe(-1);
    });

    it('returns -1 if no working hours are provided', () => {
      const workingHours = new WorkingHours([]);
      const date = new Date(2025, 0, 6); // Monday
      date.setHours(12, 0, 0); // 12:00
      expect(workingHours.openInMinutes(date)).toBe(-1);
    });
  });
});
