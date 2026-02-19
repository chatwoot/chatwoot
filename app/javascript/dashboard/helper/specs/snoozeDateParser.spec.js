import { parseDateFromText } from '../snoozeDateParser';

const now = new Date('2023-06-16T10:00:00');

const examples = [
  'mar 20 next year',
  'snooze for a day',
  'snooze till jan 2028',
  '3 weeks',
  '5 d',
  'two months',
  'half day',
  'a week',
  'tomorrow',
  'tomorrow at 3pm',
  'tonight',
  'next friday',
  'next week',
  'next month',
  'friday',
  'this friday at 13:00',
  'march 5th',
  'jan 20',
  'march 5 at 2pm',
  'in 10 days',
  'snooze for 2 hours',
  'for 3 weeks',
  'day after tomorrow',
  'this weekend',
  'next weekend',
  'morning',
  'eod',
  'at 3pm',
  '9:30am',
  '15 jan',
  '2025-01-15',
  '01/15/2025',
  'tomorrow morning',
  'this afternoon',
  'in half an hour',
  '5 minutes from now',
  // New natural language patterns
  'Tonight at 8 PM',
  'Tomorrow same time',
  'Upcoming Friday',
  'Monday of next week',
  'Approx 2 hours from now',
  'next hour',
  'add a deadline on march 30th',
  'remind me tomorrow at 9am',
  'please snooze for 3 days',
  'coming wednesday',
  'about 30 minutes from now',
  'schedule on jan 15',
  'postpone till next week',
  'tomorrow this time',
  'midnight',
  'monday next week',
  'next week monday',
  'same time friday',
  'this time wednesday',
  'morning 6am',
  'evening 7pm',
  'afternoon at 2pm',
];

describe('snooze examples', () => {
  examples.forEach(input => {
    it(`"${input}" parses to a future date`, () => {
      const result = parseDateFromText(input, now);
      expect(result).not.toBeNull();
      expect(result.date).toBeInstanceOf(Date);
      expect(result.date > now).toBe(true);
      expect(typeof result.unix).toBe('number');
    });
  });
});

const invalidDates = [
  'feb 30',
  'feb 31',
  'apr 31',
  'jun 31',
  'feb 30 2025',
  '30 feb',
  '31st feb 2025',
  // Past formal dates should also return null
  '2020-01-15',
  '01/15/2020',
  '15-01-2020',
];

describe('today at past time should roll forward', () => {
  it('"today at 9am" (already past 10am) should roll to tomorrow', () => {
    const result = parseDateFromText('today at 9am', now);
    expect(result).not.toBeNull();
    expect(result.date.getDate()).toEqual(17);
    expect(result.date.getHours()).toEqual(9);
  });

  it('"today at 3pm" (still future) should stay today', () => {
    const result = parseDateFromText('today at 3pm', now);
    expect(result).not.toBeNull();
    expect(result.date.getDate()).toEqual(16);
    expect(result.date.getHours()).toEqual(15);
  });
});

describe('invalid dates should return null', () => {
  invalidDates.forEach(input => {
    it(`"${input}" → null`, () => {
      const result = parseDateFromText(input, now);
      expect(result).toBeNull();
    });
  });
});

// ─── Regression Test Matrix ───────────────────────────────────────────────────

describe('regression: leap day / end-of-month', () => {
  const jan30 = new Date('2024-01-30T10:00:00');

  it('feb 29 on leap year (2024) should resolve', () => {
    const result = parseDateFromText('feb 29', jan30);
    expect(result).not.toBeNull();
    expect(result.date.getMonth()).toEqual(1);
    expect(result.date.getDate()).toEqual(29);
  });

  it('feb 29 on non-leap year should return null', () => {
    const jan2025 = new Date('2025-01-30T10:00:00');
    const result = parseDateFromText('feb 29 2025', jan2025);
    expect(result).toBeNull();
  });

  it('feb 29 2028 explicit leap year should resolve', () => {
    const result = parseDateFromText('feb 29 2028', now);
    expect(result).not.toBeNull();
    expect(result.date.getFullYear()).toEqual(2028);
    expect(result.date.getMonth()).toEqual(1);
    expect(result.date.getDate()).toEqual(29);
  });

  it('feb 29 without year in non-leap year scans to next leap year', () => {
    const mar2025 = new Date('2025-03-01T10:00:00');
    const result = parseDateFromText('feb 29', mar2025);
    expect(result).not.toBeNull();
    expect(result.date.getFullYear()).toEqual(2028);
    expect(result.date.getMonth()).toEqual(1);
    expect(result.date.getDate()).toEqual(29);
  });
});

describe('regression: "next year" suffix', () => {
  it('"feb 20 next year" resolves to next year', () => {
    const result = parseDateFromText('feb 20 next year', now);
    expect(result).not.toBeNull();
    expect(result.date.getFullYear()).toEqual(2024);
    expect(result.date.getMonth()).toEqual(1);
    expect(result.date.getDate()).toEqual(20);
  });

  it('"20 feb next year" (reversed) resolves to next year', () => {
    const result = parseDateFromText('20 feb next year', now);
    expect(result).not.toBeNull();
    expect(result.date.getFullYear()).toEqual(2024);
    expect(result.date.getMonth()).toEqual(1);
    expect(result.date.getDate()).toEqual(20);
  });

  it('"dec 25 next year at 3pm" resolves with time', () => {
    const result = parseDateFromText('dec 25 next year at 3pm', now);
    expect(result).not.toBeNull();
    expect(result.date.getFullYear()).toEqual(2024);
    expect(result.date.getHours()).toEqual(15);
  });
});

describe('regression: weekend semantics', () => {
  it('"this weekend" on Saturday morning should be today', () => {
    const satMorning = new Date('2023-06-17T07:00:00');
    const result = parseDateFromText('this weekend', satMorning);
    expect(result).not.toBeNull();
    expect(result.date.getDate()).toEqual(17);
    expect(result.date.getHours()).toEqual(10);
  });

  it('"this weekend" on Sunday should be today', () => {
    const sunMorning = new Date('2023-06-18T07:00:00');
    const result = parseDateFromText('this weekend', sunMorning);
    expect(result).not.toBeNull();
    expect(result.date.getDate()).toEqual(18);
    expect(result.date.getHours()).toEqual(10);
  });

  it('"next weekend" on Saturday should skip to next Saturday', () => {
    const satMorning = new Date('2023-06-17T07:00:00');
    const result = parseDateFromText('next weekend', satMorning);
    expect(result).not.toBeNull();
    expect(result.date.getDate()).toEqual(24);
  });

  it('"this weekend" on a weekday should be next Saturday', () => {
    const result = parseDateFromText('this weekend', now);
    expect(result).not.toBeNull();
    expect(result.date.getDate()).toEqual(17);
  });
});

describe('regression: ambiguous numeric dates', () => {
  it('"01/05/2025" treats first number as month (US format)', () => {
    const result = parseDateFromText('01/05/2025', now);
    expect(result).not.toBeNull();
    expect(result.date.getMonth()).toEqual(0);
    expect(result.date.getDate()).toEqual(5);
  });

  it('"13/05/2025" disambiguates — 13 must be day', () => {
    const result = parseDateFromText('13/05/2025', now);
    expect(result).not.toBeNull();
    expect(result.date.getMonth()).toEqual(4);
    expect(result.date.getDate()).toEqual(13);
  });
});

describe('regression: same-time edge cases', () => {
  it('"today same time" should return null (not future)', () => {
    const result = parseDateFromText('today same time', now);
    expect(result).toBeNull();
  });

  it('"tomorrow same time" preserves hour and minute', () => {
    const at1430 = new Date('2023-06-16T14:30:00');
    const result = parseDateFromText('tomorrow same time', at1430);
    expect(result).not.toBeNull();
    expect(result.date.getDate()).toEqual(17);
    expect(result.date.getHours()).toEqual(14);
    expect(result.date.getMinutes()).toEqual(30);
  });

  it('"tomorrow same time" with seconds does not produce past', () => {
    const at1030WithSecs = new Date('2023-06-16T10:00:45.500');
    const result = parseDateFromText('tomorrow same time', at1030WithSecs);
    expect(result).not.toBeNull();
    expect(result.date > at1030WithSecs).toBe(true);
  });
});

describe('regression: future-only rollover', () => {
  it('"today morning" at 11am rolls to tomorrow morning', () => {
    const at11am = new Date('2023-06-16T11:00:00');
    const result = parseDateFromText('today morning', at11am);
    expect(result).not.toBeNull();
    expect(result.date.getDate()).toEqual(17);
    expect(result.date.getHours()).toEqual(9);
  });

  it('"today afternoon" at 10am stays today', () => {
    const result = parseDateFromText('today afternoon', now);
    expect(result).not.toBeNull();
    expect(result.date.getDate()).toEqual(16);
    expect(result.date.getHours()).toEqual(14);
  });

  it('"at 9am" when it is 10am rolls to tomorrow', () => {
    const result = parseDateFromText('at 9am', now);
    expect(result).not.toBeNull();
    expect(result.date.getDate()).toEqual(17);
  });

  it('past formal date "2020-06-01" returns null', () => {
    const result = parseDateFromText('2020-06-01', now);
    expect(result).toBeNull();
  });

  it('past month-day "jan 1" rolls to next year', () => {
    const result = parseDateFromText('jan 1', now);
    expect(result).not.toBeNull();
    expect(result.date.getFullYear()).toEqual(2024);
  });

  it('past month-name with explicit year "jan 5 2024" returns null', () => {
    const feb2025 = new Date('2025-02-01T10:00:00');
    const result = parseDateFromText('jan 5 2024', feb2025);
    expect(result).toBeNull();
  });

  it('past reversed date with explicit year "5 jan 2024" returns null', () => {
    const feb2025 = new Date('2025-02-01T10:00:00');
    const result = parseDateFromText('5 jan 2024', feb2025);
    expect(result).toBeNull();
  });

  it('future month-name with explicit year "dec 25 2025" resolves', () => {
    const result = parseDateFromText('dec 25 2025', now);
    expect(result).not.toBeNull();
    expect(result.date.getFullYear()).toEqual(2025);
    expect(result.date.getMonth()).toEqual(11);
    expect(result.date.getDate()).toEqual(25);
  });
});

describe('regression: noise-stripped bare durations', () => {
  it('"approx 2 hours" resolves (noise stripped to "2 hours")', () => {
    const result = parseDateFromText('approx 2 hours', now);
    expect(result).not.toBeNull();
    expect(result.date > now).toBe(true);
  });

  it('"about 3 days" resolves', () => {
    const result = parseDateFromText('about 3 days', now);
    expect(result).not.toBeNull();
  });

  it('"roughly 30 minutes" resolves', () => {
    const result = parseDateFromText('roughly 30 minutes', now);
    expect(result).not.toBeNull();
  });

  it('"~ 1 hour" resolves', () => {
    const result = parseDateFromText('~ 1 hour', now);
    expect(result).not.toBeNull();
  });
});

describe('regression: invalid meridiem inputs', () => {
  it('"0am" should return null', () => {
    const result = parseDateFromText('tomorrow at 0am', now);
    expect(result).toBeNull();
  });

  it('"13pm" should return null', () => {
    const result = parseDateFromText('tomorrow at 13pm', now);
    expect(result).toBeNull();
  });

  it('"0pm" should return null', () => {
    const result = parseDateFromText('tomorrow at 0pm', now);
    expect(result).toBeNull();
  });

  it('"12am" is valid (midnight)', () => {
    const result = parseDateFromText('tomorrow at 12am', now);
    expect(result).not.toBeNull();
    expect(result.date.getHours()).toEqual(0);
  });

  it('"12pm" is valid (noon)', () => {
    const result = parseDateFromText('tomorrow at 12pm', now);
    expect(result).not.toBeNull();
    expect(result.date.getHours()).toEqual(12);
  });
});

describe('regression: strict future (> not >=)', () => {
  it('"today at 10:00am" when now is exactly 10:00:00 rolls to tomorrow', () => {
    const exact10 = new Date('2023-06-16T10:00:00.000');
    const result = parseDateFromText('today at 10am', exact10);
    expect(result).not.toBeNull();
    expect(result.date.getDate()).toEqual(17);
  });

  it('"eod" at exactly 5pm rolls to tomorrow', () => {
    const exact5pm = new Date('2023-06-16T17:00:00.000');
    const result = parseDateFromText('eod', exact5pm);
    expect(result).not.toBeNull();
    expect(result.date.getDate()).toEqual(17);
  });
});

describe('regression: DST / month-end rollovers', () => {
  it('"in 1 day" always advances by ~24h regardless of DST', () => {
    const ref = new Date('2025-03-09T01:00:00');
    const result = parseDateFromText('in 1 day', ref);
    expect(result).not.toBeNull();
    const diffMs = result.date.getTime() - ref.getTime();
    const diffHours = diffMs / (1000 * 60 * 60);
    // date-fns add({ days: 1 }) adds a calendar day; exact hours vary by TZ
    expect(diffHours).toBeGreaterThanOrEqual(22);
    expect(diffHours).toBeLessThanOrEqual(48);
  });

  it('"tomorrow" at end of month (Jan 31 → Feb 1)', () => {
    const jan31 = new Date('2025-01-31T10:00:00');
    const result = parseDateFromText('tomorrow', jan31);
    expect(result).not.toBeNull();
    expect(result.date.getMonth()).toEqual(1);
    expect(result.date.getDate()).toEqual(1);
  });

  it('"in 1 month" from Jan 31 clamps to Feb 28 (date-fns behavior)', () => {
    const jan31 = new Date('2025-01-31T10:00:00');
    const result = parseDateFromText('in 1 month', jan31);
    expect(result).not.toBeNull();
    expect(result.date.getMonth()).toEqual(1);
    expect(result.date.getDate()).toEqual(28);
    expect(result.date > jan31).toBe(true);
  });

  it('"next friday" across year boundary (Dec 29 → Jan 2026)', () => {
    const dec29 = new Date('2025-12-29T10:00:00');
    const result = parseDateFromText('next friday', dec29);
    expect(result).not.toBeNull();
    expect(result.date.getFullYear()).toEqual(2026);
    expect(result.date.getMonth()).toEqual(0);
  });
});

describe('regression: max 999 years cap', () => {
  it('"jan 1 9999" should return null (>999 years from now)', () => {
    const result = parseDateFromText('jan 1 9999', now);
    expect(result).toBeNull();
  });

  it('"dec 25 2999" should resolve (within 999 years)', () => {
    const result = parseDateFromText('dec 25 2999', now);
    expect(result).not.toBeNull();
  });

  it('"9999-01-01" should return null', () => {
    const result = parseDateFromText('9999-01-01', now);
    expect(result).toBeNull();
  });
});

describe('regression: invalid time in applyTimeOrDefault', () => {
  it('"next monday at 99" should return null (invalid hour)', () => {
    const result = parseDateFromText('next monday at 99', now);
    expect(result).toBeNull();
  });

  it('"jan 5 at 25" should return null (invalid hour)', () => {
    const result = parseDateFromText('jan 5 at 25', now);
    expect(result).toBeNull();
  });

  it('"friday at 10:99" should return null (invalid minutes)', () => {
    const result = parseDateFromText('friday at 10:99', now);
    expect(result).toBeNull();
  });

  it('"tomorrow at 3pm" is still valid', () => {
    const result = parseDateFromText('tomorrow at 3pm', now);
    expect(result).not.toBeNull();
    expect(result.date.getHours()).toEqual(15);
  });
});

describe('regression: zero durations rejected', () => {
  it('"0 minutes" should return null', () => {
    const result = parseDateFromText('0 minutes', now);
    expect(result).toBeNull();
  });

  it('"0 days" should return null', () => {
    const result = parseDateFromText('0 days', now);
    expect(result).toBeNull();
  });

  it('"in 0 hours" should return null', () => {
    const result = parseDateFromText('in 0 hours', now);
    expect(result).toBeNull();
  });

  it('"0 days from now" should return null', () => {
    const result = parseDateFromText('0 days from now', now);
    expect(result).toBeNull();
  });

  it('"1 minute" is still valid', () => {
    const result = parseDateFromText('1 minute', now);
    expect(result).not.toBeNull();
    expect(result.date > now).toBe(true);
  });
});

describe('regression: today date with default 9am past now', () => {
  it('"jun 16" at 10am defaults to 9am which is past → rolls to next year', () => {
    // now = 2023-06-16T10:00:00 (Friday)
    // "jun 16" defaults to 9am today → past → futureOrNextYear bumps to 2024
    const result = parseDateFromText('jun 16', now);
    expect(result).not.toBeNull();
    expect(result.date.getFullYear()).toEqual(2024);
    expect(result.date.getMonth()).toEqual(5);
    expect(result.date.getDate()).toEqual(16);
    expect(result.date.getHours()).toEqual(9);
  });

  it('"jun 16 at 3pm" at 10am stays today (3pm is future)', () => {
    const result = parseDateFromText('jun 16 at 3pm', now);
    expect(result).not.toBeNull();
    expect(result.date.getFullYear()).toEqual(2023);
    expect(result.date.getDate()).toEqual(16);
    expect(result.date.getHours()).toEqual(15);
  });
});

describe('regression: 24h time support', () => {
  it('"today at 14:30" resolves to 2:30pm today', () => {
    const result = parseDateFromText('today at 14:30', now);
    expect(result).not.toBeNull();
    expect(result.date.getHours()).toEqual(14);
    expect(result.date.getMinutes()).toEqual(30);
  });

  it('"tomorrow at 14:00" resolves', () => {
    const result = parseDateFromText('tomorrow at 14:00', now);
    expect(result).not.toBeNull();
    expect(result.date.getDate()).toEqual(17);
    expect(result.date.getHours()).toEqual(14);
  });

  it('"jan 15 at 14:00" resolves with 24h time', () => {
    const result = parseDateFromText('jan 15 at 14:00', now);
    expect(result).not.toBeNull();
    expect(result.date.getHours()).toEqual(14);
    expect(result.date.getMinutes()).toEqual(0);
  });

  it('"next monday 18:00" resolves', () => {
    const result = parseDateFromText('next monday 18:00', now);
    expect(result).not.toBeNull();
    expect(result.date.getHours()).toEqual(18);
  });

  it('"friday 16:30" resolves', () => {
    const result = parseDateFromText('friday 16:30', now);
    expect(result).not.toBeNull();
    expect(result.date.getHours()).toEqual(16);
    expect(result.date.getMinutes()).toEqual(30);
  });

  it('"day after tomorrow 13:00" resolves', () => {
    const result = parseDateFromText('day after tomorrow 13:00', now);
    expect(result).not.toBeNull();
    expect(result.date.getDate()).toEqual(18);
    expect(result.date.getHours()).toEqual(13);
  });
});

// ─── parseDateFromText direct tests ──────────────────────────────────────────

describe('parseDateFromText: relative durations', () => {
  it('"in 2 hours" adds 2 hours', () => {
    const result = parseDateFromText('in 2 hours', now);
    expect(result).not.toBeNull();
    expect(result.date.getHours()).toEqual(12);
  });

  it('"half hour" adds 30 minutes', () => {
    const result = parseDateFromText('half hour', now);
    expect(result).not.toBeNull();
    expect(result.date.getMinutes()).toEqual(30);
  });

  it('"3 days from now" adds 3 days', () => {
    const result = parseDateFromText('3 days from now', now);
    expect(result).not.toBeNull();
    expect(result.date.getDate()).toEqual(19);
  });

  it('"a week" adds 7 days', () => {
    const result = parseDateFromText('a week', now);
    expect(result).not.toBeNull();
    expect(result.date.getDate()).toEqual(23);
  });

  it('"two months" adds 2 months', () => {
    const result = parseDateFromText('two months', now);
    expect(result).not.toBeNull();
    expect(result.date.getMonth()).toEqual(7);
  });
});

describe('parseDateFromText: next patterns', () => {
  it('"next week" returns next Monday 9am', () => {
    const result = parseDateFromText('next week', now);
    expect(result).not.toBeNull();
    expect(result.date.getDay()).toEqual(1);
    expect(result.date.getHours()).toEqual(9);
  });

  it('"next month" returns same day next month at 9am', () => {
    // add(startOfDay(Jun 16), { months: 1 }) → Jul 16
    const result = parseDateFromText('next month', now);
    expect(result).not.toBeNull();
    expect(result.date.getMonth()).toEqual(6);
    expect(result.date.getDate()).toEqual(16);
    expect(result.date.getHours()).toEqual(9);
  });

  it('"next hour" adds 1 hour', () => {
    const result = parseDateFromText('next hour', now);
    expect(result).not.toBeNull();
    expect(result.date.getHours()).toEqual(11);
  });
});

describe('parseDateFromText: weekday patterns', () => {
  it('"friday" returns this friday with default time', () => {
    const result = parseDateFromText('friday', now);
    expect(result).not.toBeNull();
    expect(result.date.getDay()).toEqual(5);
  });

  it('"this wednesday at 2pm" returns wednesday 2pm', () => {
    const result = parseDateFromText('this wednesday at 2pm', now);
    expect(result).not.toBeNull();
    expect(result.date.getDay()).toEqual(3);
    expect(result.date.getHours()).toEqual(14);
  });

  it('"upcoming thursday" returns next thursday', () => {
    const result = parseDateFromText('upcoming thursday', now);
    expect(result).not.toBeNull();
    expect(result.date.getDay()).toEqual(4);
  });
});

describe('parseDateFromText: formal date formats', () => {
  it('"2025-01-15" parses YYYY-MM-DD', () => {
    const result = parseDateFromText('2025-01-15', now);
    expect(result).not.toBeNull();
    expect(result.date.getFullYear()).toEqual(2025);
    expect(result.date.getMonth()).toEqual(0);
    expect(result.date.getDate()).toEqual(15);
  });

  it('"01/15/2025" parses MM/DD/YYYY', () => {
    const result = parseDateFromText('01/15/2025', now);
    expect(result).not.toBeNull();
    expect(result.date.getMonth()).toEqual(0);
    expect(result.date.getDate()).toEqual(15);
  });

  it('"15-01-2025" parses DD-MM-YYYY', () => {
    const result = parseDateFromText('15-01-2025', now);
    expect(result).not.toBeNull();
    expect(result.date.getDate()).toEqual(15);
    expect(result.date.getMonth()).toEqual(0);
  });
});

describe('parseDateFromText: returns null for garbage', () => {
  it('empty string returns null', () => {
    expect(parseDateFromText('', now)).toBeNull();
  });

  it('random text returns null', () => {
    expect(parseDateFromText('hello world', now)).toBeNull();
  });

  it('null input returns null', () => {
    expect(parseDateFromText(null, now)).toBeNull();
  });

  it('number input returns null', () => {
    expect(parseDateFromText(123, now)).toBeNull();
  });
});

describe('regression: mid-text punctuation is stripped', () => {
  it('"today, at 3pm" resolves (comma stripped)', () => {
    const result = parseDateFromText('today, at 3pm', now);
    expect(result).not.toBeNull();
    expect(result.date.getHours()).toEqual(15);
  });

  it('"tomorrow; 9am" resolves (semicolon stripped)', () => {
    const result = parseDateFromText('tomorrow; 9am', now);
    expect(result).not.toBeNull();
    expect(result.date.getHours()).toEqual(9);
  });

  it('"jan 15, 2025" resolves (comma after day)', () => {
    const result = parseDateFromText('jan 15, 2025', now);
    expect(result).not.toBeNull();
    expect(result.date.getDate()).toEqual(15);
  });

  it('"next friday!" resolves (trailing punctuation)', () => {
    const result = parseDateFromText('next friday!', now);
    expect(result).not.toBeNull();
    expect(result.date.getDay()).toEqual(5);
  });

  it('"tomorrow at 3p.m." still works (periods preserved for a.m./p.m.)', () => {
    const result = parseDateFromText('tomorrow at 3p.m.', now);
    expect(result).not.toBeNull();
    expect(result.date.getHours()).toEqual(15);
  });
});

describe('regression: contradictory time-of-day + time rejected', () => {
  it('"morning 7pm" returns null', () => {
    const result = parseDateFromText('morning 7pm', now);
    expect(result).toBeNull();
  });

  it('"evening 6am" returns null', () => {
    const result = parseDateFromText('evening 6am', now);
    expect(result).toBeNull();
  });

  it('"night 8am" returns null', () => {
    const result = parseDateFromText('night 8am', now);
    expect(result).toBeNull();
  });

  it('"afternoon 7am" returns null', () => {
    const result = parseDateFromText('afternoon 7am', now);
    expect(result).toBeNull();
  });

  it('"morning 6am" is valid (consistent)', () => {
    const result = parseDateFromText('morning 6am', now);
    expect(result).not.toBeNull();
    expect(result.date.getHours()).toEqual(6);
  });

  it('"evening 7pm" is valid (consistent)', () => {
    const result = parseDateFromText('evening 7pm', now);
    expect(result).not.toBeNull();
    expect(result.date.getHours()).toEqual(19);
  });

  it('"afternoon at 2pm" is valid (consistent)', () => {
    const result = parseDateFromText('afternoon at 2pm', now);
    expect(result).not.toBeNull();
    expect(result.date.getHours()).toEqual(14);
  });
});
