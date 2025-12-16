import { getBusinessHoursConfig } from '../slaHelper';

describe('slaHelper', () => {
  describe('getBusinessHoursConfig', () => {
    const mockWorkingHours = [
      {
        day_of_week: 1, // Monday
        open_hour: 9,
        open_minutes: 0,
        close_hour: 17,
        close_minutes: 30,
        closed_all_day: false,
      },
      {
        day_of_week: 2, // Tuesday
        open_hour: 8,
        open_minutes: 30,
        close_hour: 18,
        close_minutes: 0,
        closed_all_day: false,
      },
      {
        day_of_week: 0, // Sunday
        closed_all_day: true,
      },
    ];

    const mockWorkingHoursCamelCase = [
      {
        dayOfWeek: 1, // Monday
        openHour: 9,
        openMinutes: 0,
        closeHour: 17,
        closeMinutes: 30,
        closedAllDay: false,
      },
      {
        dayOfWeek: 2, // Tuesday
        openHour: 8,
        openMinutes: 30,
        closeHour: 18,
        closeMinutes: 0,
        closedAllDay: false,
      },
      {
        dayOfWeek: 0, // Sunday
        closedAllDay: true,
      },
    ];

    describe('when business hours are not required', () => {
      it('returns null when SLA policy does not require business hours', () => {
        const slaPolicy = { only_during_business_hours: false };
        const inbox = {
          working_hours_enabled: true,
          working_hours: mockWorkingHours,
        };

        const result = getBusinessHoursConfig(slaPolicy, inbox);

        expect(result).toBeNull();
      });

      it('returns null when inbox does not have working hours enabled', () => {
        const slaPolicy = { only_during_business_hours: true };
        const inbox = {
          working_hours_enabled: false,
          working_hours: mockWorkingHours,
        };

        const result = getBusinessHoursConfig(slaPolicy, inbox);

        expect(result).toBeNull();
      });

      it('returns null when both conditions are false', () => {
        const slaPolicy = { only_during_business_hours: false };
        const inbox = { working_hours_enabled: false };

        const result = getBusinessHoursConfig(slaPolicy, inbox);

        expect(result).toBeNull();
      });

      it('returns null when slaPolicy is null', () => {
        const inbox = {
          working_hours_enabled: true,
          working_hours: mockWorkingHours,
        };

        const result = getBusinessHoursConfig(null, inbox);

        expect(result).toBeNull();
      });

      it('returns null when inbox is null', () => {
        const slaPolicy = { only_during_business_hours: true };

        const result = getBusinessHoursConfig(slaPolicy, null);

        expect(result).toBeNull();
      });
    });

    describe('when business hours are required - snake_case properties', () => {
      it('converts working hours correctly with snake_case properties', () => {
        const slaPolicy = { only_during_business_hours: true };
        const inbox = {
          working_hours_enabled: true,
          working_hours: mockWorkingHours,
          timezone: 'America/New_York',
        };

        const result = getBusinessHoursConfig(slaPolicy, inbox);

        expect(result).toEqual({
          working_hours_enabled: true,
          timezone: 'America/New_York',
          working_hours: {
            sun: null, // Closed all day
            mon: {
              start: '09:00',
              finish: '17:30',
            },
            tue: {
              start: '08:30',
              finish: '18:00',
            },
          },
          only_during_business_hours: true,
        });
      });

      it('handles missing timezone by defaulting to UTC', () => {
        const slaPolicy = { only_during_business_hours: true };
        const inbox = {
          working_hours_enabled: true,
          working_hours: mockWorkingHours.slice(0, 1), // Just Monday
        };

        const result = getBusinessHoursConfig(slaPolicy, inbox);

        expect(result.timezone).toBe('UTC');
      });

      it('handles zero hours and minutes correctly', () => {
        const workingHoursWithZeros = [
          {
            day_of_week: 1,
            open_hour: 0,
            open_minutes: 0,
            close_hour: 0,
            close_minutes: 0,
            closed_all_day: false,
          },
        ];

        const slaPolicy = { only_during_business_hours: true };
        const inbox = {
          working_hours_enabled: true,
          working_hours: workingHoursWithZeros,
        };

        const result = getBusinessHoursConfig(slaPolicy, inbox);

        expect(result.working_hours.mon).toEqual({
          start: '00:00',
          finish: '00:00',
        });
      });
    });

    describe('when business hours are required - camelCase properties', () => {
      it('converts working hours correctly with camelCase properties', () => {
        const slaPolicy = { onlyDuringBusinessHours: true };
        const inbox = {
          workingHoursEnabled: true,
          workingHours: mockWorkingHoursCamelCase,
          timezone: 'America/Los_Angeles',
        };

        const result = getBusinessHoursConfig(slaPolicy, inbox);

        expect(result).toEqual({
          working_hours_enabled: true,
          timezone: 'America/Los_Angeles',
          working_hours: {
            sun: null, // Closed all day
            mon: {
              start: '09:00',
              finish: '17:30',
            },
            tue: {
              start: '08:30',
              finish: '18:00',
            },
          },
          only_during_business_hours: true,
        });
      });
    });

    describe('mixed property naming conventions', () => {
      it('handles mixed snake_case and camelCase properties', () => {
        const slaPolicy = {
          only_during_business_hours: true, // snake_case
          onlyDuringBusinessHours: false, // This should be ignored due to nullish coalescing
        };
        const inbox = {
          working_hours_enabled: true, // snake_case
          workingHours: mockWorkingHoursCamelCase, // camelCase
          timezone: 'UTC',
        };

        const result = getBusinessHoursConfig(slaPolicy, inbox);

        expect(result).not.toBeNull();
        expect(result.only_during_business_hours).toBe(true);
        expect(result.working_hours_enabled).toBe(true);
      });

      it('prioritizes snake_case over camelCase when both exist', () => {
        const slaPolicy = {
          only_during_business_hours: true,
          onlyDuringBusinessHours: false,
        };
        const inbox = {
          working_hours_enabled: true,
          workingHoursEnabled: false,
          working_hours: mockWorkingHours,
          workingHours: mockWorkingHoursCamelCase,
        };

        const result = getBusinessHoursConfig(slaPolicy, inbox);

        expect(result.only_during_business_hours).toBe(true);
        expect(result.working_hours_enabled).toBe(true);
        // Should use snake_case working_hours
        expect(result.working_hours.mon.start).toBe('09:00');
      });
    });

    describe('edge cases', () => {
      it('handles empty working hours array', () => {
        const slaPolicy = { only_during_business_hours: true };
        const inbox = {
          working_hours_enabled: true,
          working_hours: [],
        };

        const result = getBusinessHoursConfig(slaPolicy, inbox);

        expect(result.working_hours).toEqual({});
      });

      it('handles missing working hours property', () => {
        const slaPolicy = { only_during_business_hours: true };
        const inbox = {
          working_hours_enabled: true,
          // No working_hours property
        };

        const result = getBusinessHoursConfig(slaPolicy, inbox);

        expect(result.working_hours).toEqual({});
      });

      it('handles undefined values in working hours', () => {
        const workingHoursWithUndefined = [
          {
            day_of_week: 1,
            open_hour: undefined,
            open_minutes: undefined,
            close_hour: undefined,
            close_minutes: undefined,
            closed_all_day: false,
          },
        ];

        const slaPolicy = { only_during_business_hours: true };
        const inbox = {
          working_hours_enabled: true,
          working_hours: workingHoursWithUndefined,
        };

        const result = getBusinessHoursConfig(slaPolicy, inbox);

        expect(result.working_hours.mon).toEqual({
          start: '00:00',
          finish: '00:00',
        });
      });

      it('pads single digit hours and minutes correctly', () => {
        const workingHoursSingleDigit = [
          {
            day_of_week: 3, // Wednesday
            open_hour: 9,
            open_minutes: 5,
            close_hour: 5,
            close_minutes: 0,
            closed_all_day: false,
          },
        ];

        const slaPolicy = { only_during_business_hours: true };
        const inbox = {
          working_hours_enabled: true,
          working_hours: workingHoursSingleDigit,
        };

        const result = getBusinessHoursConfig(slaPolicy, inbox);

        expect(result.working_hours.wed).toEqual({
          start: '09:05',
          finish: '05:00',
        });
      });

      it('handles all days of the week correctly', () => {
        const fullWeekWorkingHours = [
          { day_of_week: 0, closed_all_day: true }, // Sunday
          {
            day_of_week: 1,
            open_hour: 9,
            open_minutes: 0,
            close_hour: 17,
            close_minutes: 0,
            closed_all_day: false,
          }, // Monday
          {
            day_of_week: 2,
            open_hour: 9,
            open_minutes: 0,
            close_hour: 17,
            close_minutes: 0,
            closed_all_day: false,
          }, // Tuesday
          {
            day_of_week: 3,
            open_hour: 9,
            open_minutes: 0,
            close_hour: 17,
            close_minutes: 0,
            closed_all_day: false,
          }, // Wednesday
          {
            day_of_week: 4,
            open_hour: 9,
            open_minutes: 0,
            close_hour: 17,
            close_minutes: 0,
            closed_all_day: false,
          }, // Thursday
          {
            day_of_week: 5,
            open_hour: 9,
            open_minutes: 0,
            close_hour: 17,
            close_minutes: 0,
            closed_all_day: false,
          }, // Friday
          { day_of_week: 6, closed_all_day: true }, // Saturday
        ];

        const slaPolicy = { only_during_business_hours: true };
        const inbox = {
          working_hours_enabled: true,
          working_hours: fullWeekWorkingHours,
        };

        const result = getBusinessHoursConfig(slaPolicy, inbox);

        expect(result.working_hours).toEqual({
          sun: null,
          mon: { start: '09:00', finish: '17:00' },
          tue: { start: '09:00', finish: '17:00' },
          wed: { start: '09:00', finish: '17:00' },
          thu: { start: '09:00', finish: '17:00' },
          fri: { start: '09:00', finish: '17:00' },
          sat: null,
        });
      });
    });
  });
});
