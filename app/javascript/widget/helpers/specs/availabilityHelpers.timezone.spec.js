import {
  isInWorkingHours,
  isOpenAllDay,
  isClosedAllDay,
} from '../availabilityHelpers';

// The sibling `availabilityHelpers.spec.js` mocks `date-fns-tz` and stubs the
// date getters, so it never exercises a real timezone conversion. These specs
// deliberately leave `date-fns-tz` unmocked and drive the helpers with real UTC
// instants, which is the only way to cover the day-of-week selection and the
// closing-minute boundary as they actually behave in the widget.
//
// Everything here depends solely on the inbox timezone that is passed in, never
// on the timezone of the machine running the suite, so the results are stable in
// CI and locally. `findNextAvailableSlotDetails` is intentionally left out: it
// converts to the *viewer's* timezone via `Intl`, so it cannot be asserted
// without pinning the runner's timezone.

const SEOUL = 'Asia/Seoul'; // UTC+9, no DST
const NEW_YORK = 'America/New_York'; // UTC-5 in January

const MONDAY = 1;
const SUNDAY = 0;

describe('availabilityHelpers with real timezone conversion', () => {
  describe('closing minute boundary', () => {
    // A full-day schedule is stored as 00:00-23:59 because 24:00 is not
    // representable, so the closing minute has to be inclusive to cover the day.
    const fullDay = [
      {
        dayOfWeek: MONDAY,
        openHour: 0,
        openMinutes: 0,
        closeHour: 23,
        closeMinutes: 59,
      },
    ];

    it('stays open for the whole of the last minute of the day', () => {
      // Mon 2024-01-15 23:59:30 in Seoul
      const time = new Date('2024-01-15T14:59:30.000Z');
      expect(isInWorkingHours(time, SEOUL, fullDay)).toBe(true);
    });

    it('closes at the next midnight in the inbox timezone', () => {
      // Tue 2024-01-16 00:00:00 in Seoul, so Monday's slot no longer applies
      const time = new Date('2024-01-15T15:00:00.000Z');
      expect(isInWorkingHours(time, SEOUL, fullDay)).toBe(false);
    });

    it('keeps a regular day open through its closing minute', () => {
      const nineToFive = [
        {
          dayOfWeek: MONDAY,
          openHour: 9,
          openMinutes: 0,
          closeHour: 17,
          closeMinutes: 0,
        },
      ];

      // Mon 2024-01-15 17:00:30 in Seoul
      expect(
        isInWorkingHours(
          new Date('2024-01-15T08:00:30.000Z'),
          SEOUL,
          nineToFive
        )
      ).toBe(true);
      // Mon 2024-01-15 17:01:00 in Seoul
      expect(
        isInWorkingHours(
          new Date('2024-01-15T08:01:00.000Z'),
          SEOUL,
          nineToFive
        )
      ).toBe(false);
    });

    it('keeps an open all day slot open for the last minute of the day', () => {
      const openAllDay = [{ dayOfWeek: MONDAY, openAllDay: true }];

      // Mon 2024-01-15 23:59:30 in Seoul
      expect(
        isInWorkingHours(
          new Date('2024-01-15T14:59:30.000Z'),
          SEOUL,
          openAllDay
        )
      ).toBe(true);
    });
  });

  describe('day selection when the inbox timezone is on another date', () => {
    const mondayOnly = [
      {
        dayOfWeek: MONDAY,
        openHour: 8,
        openMinutes: 0,
        closeHour: 17,
        closeMinutes: 0,
      },
    ];
    const sundayClosed = [{ dayOfWeek: SUNDAY, closedAllDay: true }];
    const sundayOpenAllDay = [{ dayOfWeek: SUNDAY, openAllDay: true }];

    it('uses the day that is ahead of UTC', () => {
      // Sun 2024-01-14 23:00 UTC is already Mon 2024-01-15 08:00 in Seoul
      const time = new Date('2024-01-14T23:00:00.000Z');
      expect(isInWorkingHours(time, SEOUL, mondayOnly)).toBe(true);
    });

    it('uses the day that is behind UTC', () => {
      // Mon 2024-01-15 02:00 UTC is still Sun 2024-01-14 21:00 in New York
      const time = new Date('2024-01-15T02:00:00.000Z');
      expect(isInWorkingHours(time, NEW_YORK, mondayOnly)).toBe(false);
      expect(isClosedAllDay(time, NEW_YORK, sundayClosed)).toBe(true);
      expect(isOpenAllDay(time, NEW_YORK, sundayOpenAllDay)).toBe(true);
    });
  });
});
