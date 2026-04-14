import {
  parseDateFromText,
  generateDateSuggestions,
} from '../snoozeDateParser';

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

  it('"05-04-2027" ambiguous dash → day-first (April 5)', () => {
    const result = parseDateFromText('05-04-2027', now);
    expect(result).not.toBeNull();
    expect(result.date.getDate()).toEqual(5);
    expect(result.date.getMonth()).toEqual(3);
  });

  it('"05.04.2027" ambiguous dot → day-first (April 5)', () => {
    const result = parseDateFromText('05.04.2027', now);
    expect(result).not.toBeNull();
    expect(result.date.getDate()).toEqual(5);
    expect(result.date.getMonth()).toEqual(3);
  });

  it('"05/04/2027" ambiguous slash → month-first (May 4)', () => {
    const result = parseDateFromText('05/04/2027', now);
    expect(result).not.toBeNull();
    expect(result.date.getMonth()).toEqual(4);
    expect(result.date.getDate()).toEqual(4);
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

describe('generateDateSuggestions', () => {
  describe('half suggestions', () => {
    it('"half" returns half hour/day/week/month/year suggestions', () => {
      const results = generateDateSuggestions('half', now);
      const labels = results.map(r => r.label);
      expect(labels).toContain('half hour');
      expect(labels).toContain('half day');
      expect(labels).toContain('half week');
      expect(labels).toContain('half month');
      expect(labels).toContain('half year');
    });

    it('"ha" returns half suggestions (partial match)', () => {
      const results = generateDateSuggestions('ha', now);
      const labels = results.map(r => r.label);
      expect(labels).toContain('half hour');
      expect(labels).toContain('half day');
    });

    it('"hal" returns half suggestions (partial match)', () => {
      const results = generateDateSuggestions('hal', now);
      expect(results.length).toBeGreaterThan(0);
      expect(results[0].label).toMatch(/^half /);
    });
  });

  describe('word number suggestions', () => {
    it('"two" returns duration suggestions', () => {
      const results = generateDateSuggestions('two', now);
      const labels = results.map(r => r.label);
      expect(labels).toContain('2 minutes');
      expect(labels).toContain('2 hours');
      expect(labels).toContain('2 days');
    });

    it('"ten" returns duration suggestions', () => {
      const results = generateDateSuggestions('ten', now);
      const labels = results.map(r => r.label);
      expect(labels).toContain('10 minutes');
      expect(labels).toContain('10 hours');
    });

    it('"five" returns duration suggestions', () => {
      const results = generateDateSuggestions('five', now);
      const labels = results.map(r => r.label);
      expect(labels).toContain('5 minutes');
      expect(labels).toContain('5 hours');
      expect(labels).toContain('5 days');
    });
  });

  describe('no seconds in suggestions', () => {
    it('"2" does not suggest seconds', () => {
      const results = generateDateSuggestions('2', now);
      const labels = results.map(r => r.label);
      expect(labels).not.toContain('2 seconds');
      expect(labels).toContain('2 minutes');
    });

    it('"100" does not suggest seconds', () => {
      const results = generateDateSuggestions('100', now);
      const labels = results.map(r => r.label);
      const hasSeconds = labels.some(l => l.includes('seconds'));
      expect(hasSeconds).toBe(false);
    });
  });

  describe('decimal number suggestions', () => {
    it('"1.5" returns duration suggestions', () => {
      const results = generateDateSuggestions('1.5', now);
      const labels = results.map(r => r.label);
      expect(labels).toContain('1.5 hours');
      expect(labels).toContain('1.5 days');
    });
  });

  describe('caps at MAX_SUGGESTIONS', () => {
    it('returns at most 5 results', () => {
      const results = generateDateSuggestions('2', now);
      expect(results.length).toBeLessThanOrEqual(5);
    });
  });

  describe('smart compositional suggestions', () => {
    it('"mon" suggests monday + time-of-day variants (noon, afternoon, evening, night)', () => {
      const results = generateDateSuggestions('mon', now);
      const labels = results.map(r => r.label);
      // "monday morning" (9am) is deduped with "monday" (default 9am), so noon+ appear
      expect(labels.some(l => /monday\s+afternoon/.test(l))).toBe(true);
      expect(labels.some(l => /monday\s+evening/.test(l))).toBe(true);
    });

    it('"monday" suggests multiple time-of-day variants', () => {
      const results = generateDateSuggestions('monday', now);
      const labels = results.map(r => r.label);
      expect(labels.some(l => l.includes('monday afternoon'))).toBe(true);
      expect(labels.some(l => l.includes('monday evening'))).toBe(true);
      expect(results.length).toBeGreaterThanOrEqual(3);
    });

    it('"fri" suggests friday + time-of-day variants', () => {
      const results = generateDateSuggestions('fri', now);
      const labels = results.map(r => r.label);
      expect(labels.some(l => /friday/.test(l))).toBe(true);
      expect(results.length).toBeGreaterThanOrEqual(3);
    });

    it('"tomorrow m" suggests tomorrow morning', () => {
      const results = generateDateSuggestions('tomorrow m', now);
      const labels = results.map(r => r.label);
      expect(labels.some(l => l.includes('tomorrow morning'))).toBe(true);
    });

    it('"tomorrow a" suggests tomorrow afternoon', () => {
      const results = generateDateSuggestions('tomorrow a', now);
      const labels = results.map(r => r.label);
      expect(labels.some(l => l.includes('tomorrow afternoon'))).toBe(true);
    });

    it('"next mon" suggests next monday and next month', () => {
      const results = generateDateSuggestions('next mon', now);
      const labels = results.map(r => r.label);
      expect(labels.some(l => l.includes('next mon'))).toBe(true);
    });

    it('"next monday m" suggests next monday morning', () => {
      const results = generateDateSuggestions('next monday m', now);
      const labels = results.map(r => r.label);
      expect(labels.some(l => l.includes('next monday morning'))).toBe(true);
    });

    it('"t" suggests today, tonight, tomorrow', () => {
      const results = generateDateSuggestions('t', now);
      const labels = results.map(r => r.label);
      expect(
        labels.some(l => l === 'today' || l === 'tonight' || l === 'tomorrow')
      ).toBe(true);
    });

    it('"n" suggests next week, next month, next weekdays', () => {
      const results = generateDateSuggestions('n', now);
      const labels = results.map(r => r.label);
      expect(labels.some(l => l.includes('next'))).toBe(true);
    });

    it('all suggestions parse to valid future dates', () => {
      const inputs = ['mon', 'monday', 'fri', 'tomorrow m', 'next mon', 't'];
      inputs.forEach(input => {
        const results = generateDateSuggestions(input, now);
        results.forEach(r => {
          expect(r.date).toBeInstanceOf(Date);
          expect(r.date > now).toBe(true);
          expect(typeof r.unix).toBe('number');
        });
      });
    });
  });
});

describe('bare number + time-of-day context inference', () => {
  it('"morning 6" parses to 6am', () => {
    const result = parseDateFromText('morning 6', now);
    expect(result).not.toBeNull();
    expect(result.date.getHours()).toBe(6);
  });

  it('"evening 7" parses to 7pm (19:00)', () => {
    const result = parseDateFromText('evening 7', now);
    expect(result).not.toBeNull();
    expect(result.date.getHours()).toBe(19);
  });

  it('"afternoon 3" parses to 3pm (15:00)', () => {
    const result = parseDateFromText('afternoon 3', now);
    expect(result).not.toBeNull();
    expect(result.date.getHours()).toBe(15);
  });

  it('"night 9" parses to 9pm (21:00)', () => {
    const result = parseDateFromText('night 9', now);
    expect(result).not.toBeNull();
    expect(result.date.getHours()).toBe(21);
  });

  it('"tomorrow morning 6" parses to tomorrow 6am', () => {
    const result = parseDateFromText('tomorrow morning 6', now);
    expect(result).not.toBeNull();
    expect(result.date.getDate()).toBe(17);
    expect(result.date.getHours()).toBe(6);
  });

  it('"tomorrow evening 7" parses to tomorrow 7pm', () => {
    const result = parseDateFromText('tomorrow evening 7', now);
    expect(result).not.toBeNull();
    expect(result.date.getDate()).toBe(17);
    expect(result.date.getHours()).toBe(19);
  });

  it('"monday morning 6" parses to next monday 6am', () => {
    const result = parseDateFromText('monday morning 6', now);
    expect(result).not.toBeNull();
    expect(result.date.getHours()).toBe(6);
  });

  it('"friday evening 8" parses to friday 8pm', () => {
    const result = parseDateFromText('friday evening 8', now);
    expect(result).not.toBeNull();
    expect(result.date.getHours()).toBe(20);
  });

  it('explicit meridiem still works: "morning 6am" → 6am', () => {
    const result = parseDateFromText('morning 6am', now);
    expect(result).not.toBeNull();
    expect(result.date.getHours()).toBe(6);
  });

  it('contradictory meridiem still rejected: "morning 7pm" → null', () => {
    expect(parseDateFromText('morning 7pm', now)).toBeNull();
  });
});

// Pin exact output for ~35 common phrases so any matcher reorder or refactor
// that changes behavior will fail loudly. Reference: 2023-06-16T10:00:00 (Fri).

describe('golden tests: pinned phrase → exact date/time', () => {
  // [input, expectedYear, expectedMonth(0-based), expectedDay, expectedHour, expectedMinute]
  const golden = [
    // ── Durations ──
    ['in 30 minutes', 2023, 5, 16, 10, 30],
    ['in 2 hours', 2023, 5, 16, 12, 0],
    ['in 3 days', 2023, 5, 19, 10, 0],
    ['a week', 2023, 5, 23, 10, 0],
    ['two months', 2023, 7, 16, 10, 0],
    ['half hour', 2023, 5, 16, 10, 30],
    ['half day', 2023, 5, 16, 22, 0],
    ['1.5 hours', 2023, 5, 16, 11, 30],
    ['1h30m', 2023, 5, 16, 11, 30],
    ['couple hours', 2023, 5, 16, 12, 0],
    ['few hours', 2023, 5, 16, 13, 0],

    // ── Relative days ──
    ['tomorrow', 2023, 5, 17, 9, 0],
    ['tomorrow at 3pm', 2023, 5, 17, 15, 0],
    ['tomorrow at 14:30', 2023, 5, 17, 14, 30],
    ['tonight', 2023, 5, 16, 20, 0],
    ['today at 3pm', 2023, 5, 16, 15, 0],
    ['tomorrow morning', 2023, 5, 17, 9, 0],
    ['tomorrow evening', 2023, 5, 17, 18, 0],
    ['day after tomorrow', 2023, 5, 18, 9, 0],

    // ── Time-of-day ──
    ['morning', 2023, 5, 17, 9, 0],
    ['this afternoon', 2023, 5, 16, 14, 0],
    ['eod', 2023, 5, 16, 17, 0],
    ['later today', 2023, 5, 16, 13, 0],

    // ── Standalone time ──
    ['at 3pm', 2023, 5, 16, 15, 0],

    // ── Next patterns ──
    ['next hour', 2023, 5, 16, 11, 0],
    ['next week', 2023, 5, 19, 9, 0],
    ['next month', 2023, 6, 16, 9, 0],

    // ── Weekdays ──
    ['friday', 2023, 5, 23, 9, 0],
    ['monday 3pm', 2023, 5, 19, 15, 0],

    // ── Named dates ──
    ['jan 15', 2024, 0, 15, 9, 0],
    ['march 5 at 2pm', 2024, 2, 5, 14, 0],
    ['dec 25 2025', 2025, 11, 25, 9, 0],

    // ── Month ordinal week ──
    ['july 1st week', 2023, 6, 1, 9, 0], // July 1st week = July 1
    ['july 2nd week', 2023, 6, 8, 9, 0], // July 2nd week = July 8
    ['july 3rd week', 2023, 6, 15, 9, 0], // July 3rd week = July 15
    ['aug 1st week', 2023, 7, 1, 9, 0], // August 1st week = Aug 1
    ['feb 2nd week at 3pm', 2024, 1, 8, 15, 0], // Feb 2nd week with time
    ['march first week', 2024, 2, 1, 9, 0], // Ordinal: first
    ['march second week', 2024, 2, 8, 9, 0], // Ordinal: second
    ['april third week', 2024, 3, 15, 9, 0], // Ordinal: third
    ['may fourth week', 2024, 4, 22, 9, 0], // Ordinal: fourth
    ['june fifth week', 2023, 5, 29, 9, 0], // Ordinal: fifth (same year since we're before week 5)

    // ── Month ordinal day ──
    ['april first day', 2024, 3, 1, 9, 0],
    ['april second day', 2024, 3, 2, 9, 0],
    ['july third day', 2023, 6, 3, 9, 0],
    ['march 5th day', 2024, 2, 5, 9, 0],
    ['jan tenth day at 2pm', 2024, 0, 10, 14, 0],

    // ── Reversed order: ordinal unit of month ──
    ['first week of april', 2024, 3, 1, 9, 0],
    ['2nd week of july', 2023, 6, 8, 9, 0],
    ['third day of march', 2024, 2, 3, 9, 0],
    ['5th day of jan at 2pm', 2024, 0, 5, 14, 0],
    ['second week of feb at 3pm', 2024, 1, 8, 15, 0],

    // ── Formal dates ──
    ['2025-01-15', 2025, 0, 15, 9, 0],
    ['01/15/2025', 2025, 0, 15, 9, 0],

    // ── Tonight bare-hour (must infer PM, not AM) ──
    ['tonight 8', 2023, 5, 16, 20, 0],
    ['tonite 7', 2023, 5, 16, 19, 0],
    ['tonight 11', 2023, 5, 16, 23, 0],
    ['today 8', 2023, 5, 17, 8, 0], // 8am is past → rolls to next day

    // ── Shorthand durations ──
    ['2h', 2023, 5, 16, 12, 0],
    ['30m', 2023, 5, 16, 10, 30],
    ['1h30minutes', 2023, 5, 16, 11, 30],
    ['2hr15min', 2023, 5, 16, 12, 15],

    // ── Couple / few ──
    ['couple hours', 2023, 5, 16, 12, 0],
    ['a couple of days', 2023, 5, 18, 10, 0],
    ['a few minutes', 2023, 5, 16, 10, 3],
    ['in a few hours', 2023, 5, 16, 13, 0],

    // ── Fortnight ──
    ['fortnight', 2023, 5, 30, 10, 0],
    ['in a fortnight', 2023, 5, 30, 10, 0],

    // ── X later ──
    ['2 days later', 2023, 5, 18, 10, 0],
    ['a week later', 2023, 5, 23, 10, 0],
    ['month later', 2023, 6, 16, 10, 0],

    // ── Same time reversed ──
    ['same time tomorrow', 2023, 5, 17, 10, 0],

    // ── Early / late time of day ──
    ['early morning', 2023, 5, 17, 8, 0],
    ['late evening', 2023, 5, 16, 20, 0],
    ['late night', 2023, 5, 16, 22, 0],

    // ── Beginning / end of next ──
    ['beginning of next week', 2023, 5, 19, 9, 0],
    ['start of next week', 2023, 5, 19, 9, 0],
    ['end of next week', 2023, 5, 23, 17, 0],
    ['end of next month', 2023, 6, 31, 17, 0],
    ['beginning of next month', 2023, 6, 1, 9, 0],

    // ── Next business day ──
    ['next business day', 2023, 5, 19, 9, 0],
    ['next working day', 2023, 5, 19, 9, 0],

    // ── One and a half ──
    ['one and a half hours', 2023, 5, 16, 11, 30],
    ['an hour and a half', 2023, 5, 16, 11, 30],

    // ── Noise prefix: after / within ──
    ['after 2 hours', 2023, 5, 16, 12, 0],
    ['within a week', 2023, 5, 23, 10, 0],

    // ── The day after tomorrow ──
    ['the day after tomorrow', 2023, 5, 18, 9, 0],

    // ── Special ──
    ['this weekend', 2023, 5, 17, 9, 0],
    ['end of month', 2023, 5, 30, 17, 0],
  ];

  golden.forEach(([input, yr, mo, day, hr, min]) => {
    it(`"${input}" → ${yr}-${String(mo + 1).padStart(2, '0')}-${String(day).padStart(2, '0')} ${String(hr).padStart(2, '0')}:${String(min).padStart(2, '0')}`, () => {
      const result = parseDateFromText(input, now);
      expect(result).not.toBeNull();
      expect(result.date.getFullYear()).toBe(yr);
      expect(result.date.getMonth()).toBe(mo);
      expect(result.date.getDate()).toBe(day);
      expect(result.date.getHours()).toBe(hr);
      expect(result.date.getMinutes()).toBe(min);
    });
  });
});

describe('regression: month-ordinal week overflow (P1)', () => {
  it('"feb fifth week" returns null in non-leap year (would overflow into March)', () => {
    const ref = new Date(2023, 0, 10, 10, 0, 0);
    expect(parseDateFromText('feb fifth week', ref)).toBeNull();
  });

  it('"feb fourth week" is still valid', () => {
    const ref = new Date(2023, 0, 10, 10, 0, 0);
    const result = parseDateFromText('feb fourth week', ref);
    expect(result).not.toBeNull();
    expect(result.date.getMonth()).toBe(1);
  });
});

describe('localized suggestions with Malayalam translations', () => {
  const mlTranslations = {
    UNITS: {
      MINUTE: 'മിനിറ്റ്',
      MINUTES: 'മിനിറ്റ്',
      HOUR: 'മണിക്കൂർ',
      HOURS: 'മണിക്കൂർ',
      DAY: 'ദിവസം',
      DAYS: 'ദിവസം',
      WEEK: 'ആഴ്ച',
      WEEKS: 'ആഴ്ച',
      MONTH: 'മാസം',
      MONTHS: 'മാസം',
      YEAR: 'വർഷം',
      YEARS: 'വർഷം',
    },
    HALF: 'അര',
    NEXT: 'അടുത്ത',
    THIS: 'ഈ',
    AT: 'സമയം',
    IN: 'കഴിഞ്ഞ്',
    FROM_NOW: 'ഇപ്പോൾ മുതൽ',
    NEXT_YEAR: 'അടുത്ത വർഷം',
    MERIDIEM: { AM: 'രാവിലെ', PM: 'വൈകുന്നേരം' },
    RELATIVE: {
      TOMORROW: 'നാളെ',
      DAY_AFTER_TOMORROW: 'മറ്റന്നാൾ',
      NEXT_WEEK: 'അടുത്ത ആഴ്ച',
      NEXT_MONTH: 'അടുത്ത മാസം',
      THIS_WEEKEND: 'ഈ വാരാന്ത്യം',
      NEXT_WEEKEND: 'അടുത്ത വാരാന്ത്യം',
    },
    TIME_OF_DAY: {
      MORNING: 'രാവിലെ',
      AFTERNOON: 'ഉച്ചയ്ക്ക്',
      EVENING: 'വൈകുന്നേരം',
      NIGHT: 'രാത്രി',
      NOON: 'ഉച്ച',
      MIDNIGHT: 'അർദ്ധരാത്രി',
    },
    WORD_NUMBERS: {
      ONE: 'ഒന്ന്',
      TWO: 'രണ്ട്',
      THREE: 'മൂന്ന്',
      FOUR: 'നാല്',
      FIVE: 'അഞ്ച്',
      SIX: 'ആറ്',
      SEVEN: 'ഏഴ്',
      EIGHT: 'എട്ട്',
      NINE: 'ഒൻപത്',
      TEN: 'പത്ത്',
      TWELVE: 'പന്ത്രണ്ട്',
      FIFTEEN: 'പതിനഞ്ച്',
      TWENTY: 'ഇരുപത്',
      THIRTY: 'മുപ്പത്',
    },
  };

  it('Malayalam "നാളെ രാവിലെ 6" parses to tomorrow 6am', () => {
    const results = generateDateSuggestions('നാളെ രാവിലെ 6', now, {
      translations: mlTranslations,
      locale: 'ml',
    });
    expect(results.length).toBeGreaterThan(0);
    expect(results[0].date.getDate()).toBe(17);
    expect(results[0].date.getHours()).toBe(6);
  });

  it('Malayalam "നാളെ" (tomorrow) generates multiple suggestions', () => {
    const results = generateDateSuggestions('നാളെ', now, {
      translations: mlTranslations,
      locale: 'ml',
    });
    expect(results.length).toBeGreaterThanOrEqual(3);
    expect(results[0].date.getDate()).toBe(17);
  });

  it('Malayalam suggestion labels are in Malayalam, not English', () => {
    const results = generateDateSuggestions('നാളെ', now, {
      translations: mlTranslations,
      locale: 'ml',
    });
    const labels = results.map(r => r.label);
    expect(labels.some(l => /നാളെ/.test(l))).toBe(true);
    expect(labels.every(l => !/\btomorrow\b/.test(l))).toBe(true);
  });
});

describe('chrono-level patterns', () => {
  describe('tomorrow at TOD', () => {
    it('"tomorrow at noon" parses to tomorrow 12pm', () => {
      const result = parseDateFromText('tomorrow at noon', now);
      expect(result).not.toBeNull();
      expect(result.date.getDate()).toBe(17);
      expect(result.date.getHours()).toBe(12);
    });

    it('"tomorrow at midnight" parses to tomorrow 0am', () => {
      const result = parseDateFromText('tomorrow at midnight', now);
      expect(result).not.toBeNull();
      expect(result.date.getHours()).toBe(0);
    });

    it('"tomorrow at evening" parses to tomorrow 6pm', () => {
      const result = parseDateFromText('tomorrow at evening', now);
      expect(result).not.toBeNull();
      expect(result.date.getHours()).toBe(18);
    });
  });

  describe('duration at time', () => {
    it('"in 2 days at 3pm" parses correctly', () => {
      const result = parseDateFromText('in 2 days at 3pm', now);
      expect(result).not.toBeNull();
      expect(result.date.getDate()).toBe(18);
      expect(result.date.getHours()).toBe(15);
    });

    it('"in 1 week at 9am" parses correctly', () => {
      const result = parseDateFromText('in 1 week at 9am', now);
      expect(result).not.toBeNull();
      expect(result.date.getHours()).toBe(9);
    });
  });

  describe('end of period', () => {
    it('"end of day" parses to today 5pm', () => {
      const result = parseDateFromText('end of day', now);
      expect(result).not.toBeNull();
      expect(result.date.getHours()).toBe(17);
    });

    it('"end of the week" parses to next friday 5pm', () => {
      const result = parseDateFromText('end of the week', now);
      expect(result).not.toBeNull();
      expect(result.date.getDay()).toBe(5);
      expect(result.date.getHours()).toBe(17);
    });

    it('"end of month" parses to last day of month 5pm', () => {
      const result = parseDateFromText('end of month', now);
      expect(result).not.toBeNull();
      expect(result.date.getDate()).toBe(30);
      expect(result.date.getHours()).toBe(17);
    });

    it('"end of month" on last day after 5pm rolls to next month-end', () => {
      const lastDayLate = new Date('2025-06-30T18:00:00');
      const result = parseDateFromText('end of month', lastDayLate);
      expect(result).not.toBeNull();
      expect(result.date.getMonth()).toBe(6);
      expect(result.date.getDate()).toBe(31);
      expect(result.date.getHours()).toBe(17);
    });
  });

  describe('later today', () => {
    it('"later today" parses to +3 hours from now', () => {
      const result = parseDateFromText('later today', now);
      expect(result).not.toBeNull();
      expect(result.date.getHours()).toBe(13);
    });
  });

  describe('compound durations', () => {
    it('"1 hour 30 minutes" parses correctly', () => {
      const result = parseDateFromText('1 hour 30 minutes', now);
      expect(result).not.toBeNull();
      expect(result.date.getHours()).toBe(11);
      expect(result.date.getMinutes()).toBe(30);
    });

    it('"1h30m" parses correctly', () => {
      const result = parseDateFromText('1h30m', now);
      expect(result).not.toBeNull();
      expect(result.date.getHours()).toBe(11);
      expect(result.date.getMinutes()).toBe(30);
    });

    it('"2 hours and 30 minutes" parses correctly', () => {
      const result = parseDateFromText('2 hours and 30 minutes', now);
      expect(result).not.toBeNull();
      expect(result.date.getHours()).toBe(12);
      expect(result.date.getMinutes()).toBe(30);
    });
  });

  describe('aliases and shortcuts', () => {
    it('"tonite" parses to tonight (8pm)', () => {
      const result = parseDateFromText('tonite', now);
      expect(result).not.toBeNull();
      expect(result.date.getHours()).toBe(20);
    });

    it('"couple hours" parses to +2 hours', () => {
      const result = parseDateFromText('couple hours', now);
      expect(result).not.toBeNull();
      expect(result.date.getHours()).toBe(12);
    });

    it('"couple of hours" parses to +2 hours', () => {
      const result = parseDateFromText('couple of hours', now);
      expect(result).not.toBeNull();
      expect(result.date.getHours()).toBe(12);
    });

    it('"few hours" parses to +3 hours', () => {
      const result = parseDateFromText('few hours', now);
      expect(result).not.toBeNull();
      expect(result.date.getHours()).toBe(13);
    });

    it('"nxt week" parses like "next week"', () => {
      const result = parseDateFromText('nxt week', now);
      expect(result).not.toBeNull();
    });

    it('"nxt monday" parses like "next monday"', () => {
      const result = parseDateFromText('nxt monday', now);
      expect(result).not.toBeNull();
    });
  });

  describe('weekday bare hour defaults to PM', () => {
    it('"monday at 3" parses to 3pm', () => {
      const result = parseDateFromText('monday at 3', now);
      expect(result).not.toBeNull();
      expect(result.date.getHours()).toBe(15);
    });

    it('"friday at 5" parses to 5pm', () => {
      const result = parseDateFromText('friday at 5', now);
      expect(result).not.toBeNull();
      expect(result.date.getHours()).toBe(17);
    });

    it('"monday at 9" stays 9am (hour >= 8)', () => {
      const result = parseDateFromText('monday at 9', now);
      expect(result).not.toBeNull();
      expect(result.date.getHours()).toBe(9);
    });
  });
});

describe('dot-delimited dates', () => {
  it('"12.12.2034" parses to Dec 12 2034', () => {
    const result = parseDateFromText('12.12.2034', now);
    expect(result).not.toBeNull();
    expect(result.date.getFullYear()).toEqual(2034);
    expect(result.date.getMonth()).toEqual(11);
    expect(result.date.getDate()).toEqual(12);
  });

  it('"01.06.2025" parses correctly', () => {
    const result = parseDateFromText('01.06.2025', now);
    expect(result).not.toBeNull();
    expect(result.date.getFullYear()).toEqual(2025);
  });
});

describe('noise word stripping', () => {
  it('"snooze this for 5 minutes" parses', () => {
    const result = parseDateFromText('snooze this for 5 minutes', now);
    expect(result).not.toBeNull();
  });

  it('"please snooze this for half a day" parses', () => {
    const result = parseDateFromText('please snooze this for half a day', now);
    expect(result).not.toBeNull();
  });

  it('"snooze this until tomorrow" parses', () => {
    const result = parseDateFromText('snooze this until tomorrow', now);
    expect(result).not.toBeNull();
  });

  it('"after ten year" strips "after" and parses as duration', () => {
    const result = parseDateFromText('after ten year', now);
    expect(result).not.toBeNull();
  });

  it('"after 2 hours" strips "after" and parses as duration', () => {
    const result = parseDateFromText('after 2 hours', now);
    expect(result).not.toBeNull();
    expect(result.date.getHours()).toEqual(12);
  });

  it('"after 3 days" strips "after" and parses as duration', () => {
    const result = parseDateFromText('after 3 days', now);
    expect(result).not.toBeNull();
    expect(result.date.getDate()).toEqual(19);
  });

  it('"schedule this for 2025-01-15" parses', () => {
    const result = parseDateFromText('schedule this for 2025-01-15', now);
    expect(result).not.toBeNull();
    expect(result.date.getFullYear()).toEqual(2025);
    expect(result.date.getMonth()).toEqual(0);
    expect(result.date.getDate()).toEqual(15);
  });
});

describe('half unit parsing', () => {
  it('"half hour" adds 30 minutes', () => {
    const result = parseDateFromText('half hour', now);
    expect(result).not.toBeNull();
    expect(result.date.getMinutes()).toEqual(30);
  });

  it('"half day" adds 12 hours', () => {
    const result = parseDateFromText('half day', now);
    expect(result).not.toBeNull();
    expect(result.date.getHours()).toEqual(22);
  });

  it('"half week" parses to a future date', () => {
    const result = parseDateFromText('half week', now);
    expect(result).not.toBeNull();
    expect(result.date > now).toBe(true);
  });

  it('"half month" parses to a future date', () => {
    const result = parseDateFromText('half month', now);
    expect(result).not.toBeNull();
    expect(result.date > now).toBe(true);
  });

  it('"half year" parses to ~6 months ahead', () => {
    const result = parseDateFromText('half year', now);
    expect(result).not.toBeNull();
    expect(result.date.getMonth()).toEqual(11);
  });
});

describe('decimal duration parsing (only .5 allowed)', () => {
  it('"1.5 hours" parses correctly', () => {
    const result = parseDateFromText('1.5 hours', now);
    expect(result).not.toBeNull();
    expect(result.date > now).toBe(true);
  });

  it('"1.5 days" parses correctly', () => {
    const result = parseDateFromText('1.5 days', now);
    expect(result).not.toBeNull();
    expect(result.date > now).toBe(true);
  });

  it('"0.5 hours" parses correctly', () => {
    const result = parseDateFromText('0.5 hours', now);
    expect(result).not.toBeNull();
    expect(result.date > now).toBe(true);
  });

  it('"1.3 hours" returns null (only .5 allowed)', () => {
    expect(parseDateFromText('1.3 hours', now)).toBeNull();
  });

  it('"2.7 days" returns null (only .5 allowed)', () => {
    expect(parseDateFromText('2.7 days', now)).toBeNull();
  });
});

// ─── Multilingual / Localized Input Regressions ─────────────────────────────

describe('generateDateSuggestions — localized input regressions', () => {
  const arTranslations = {
    UNITS: {
      MINUTE: 'دقيقة',
      MINUTES: 'دقائق',
      HOUR: 'ساعة',
      HOURS: 'ساعات',
      DAY: 'يوم',
      DAYS: 'أيام',
      WEEK: 'أسبوع',
      WEEKS: 'أسابيع',
      MONTH: 'شهر',
      MONTHS: 'أشهر',
      YEAR: 'سنة',
      YEARS: 'سنوات',
    },
    HALF: 'نصف',
    NEXT: 'القادم',
    THIS: 'هذا',
    AT: 'الساعة',
    IN: 'في',
    FROM_NOW: 'من الآن',
    NEXT_YEAR: 'العام المقبل',
    MERIDIEM: { AM: 'صباحاً', PM: 'مساءً' },
    RELATIVE: {
      TOMORROW: 'غداً',
      DAY_AFTER_TOMORROW: 'بعد غد',
      NEXT_WEEK: 'الأسبوع القادم',
      NEXT_MONTH: 'الشهر القادم',
      THIS_WEEKEND: 'نهاية هذا الأسبوع',
      NEXT_WEEKEND: 'نهاية الأسبوع القادم',
    },
    TIME_OF_DAY: {
      MORNING: 'صباحاً',
      AFTERNOON: 'بعد الظهر',
      EVENING: 'مساءً',
      NIGHT: 'ليلاً',
      NOON: 'ظهراً',
      MIDNIGHT: 'منتصف الليل',
    },
    WORD_NUMBERS: {
      ONE: 'واحد',
      TWO: 'اثنان',
      THREE: 'ثلاثة',
      FOUR: 'أربعة',
      FIVE: 'خمسة',
      SIX: 'ستة',
      SEVEN: 'سبعة',
      EIGHT: 'ثمانية',
      NINE: 'تسعة',
      TEN: 'عشرة',
      TWELVE: 'اثنا عشر',
      FIFTEEN: 'خمسة عشر',
      TWENTY: 'عشرون',
      THIRTY: 'ثلاثون',
    },
  };

  const hiTranslations = {
    UNITS: {
      MINUTE: 'मिनट',
      MINUTES: 'मिनट',
      HOUR: 'घंटा',
      HOURS: 'घंटे',
      DAY: 'दिन',
      DAYS: 'दिन',
      WEEK: 'सप्ताह',
      WEEKS: 'सप्ताह',
      MONTH: 'महीना',
      MONTHS: 'महीने',
      YEAR: 'साल',
      YEARS: 'साल',
    },
    HALF: 'आधा',
    NEXT: 'अगला',
    THIS: 'यह',
    AT: 'बजे',
    IN: 'में',
    FROM_NOW: 'अब से',
    NEXT_YEAR: 'अगले साल',
    MERIDIEM: { AM: 'सुबह', PM: 'शाम' },
    RELATIVE: {
      TOMORROW: 'कल',
      DAY_AFTER_TOMORROW: 'परसों',
      NEXT_WEEK: 'अगले सप्ताह',
      NEXT_MONTH: 'अगले महीने',
      THIS_WEEKEND: 'इस सप्ताहांत',
      NEXT_WEEKEND: 'अगले सप्ताहांत',
    },
    TIME_OF_DAY: {
      MORNING: 'सुबह',
      AFTERNOON: 'दोपहर',
      EVENING: 'शाम',
      NIGHT: 'रात',
      NOON: 'दोपहर',
      MIDNIGHT: 'आधी रात',
    },
    WORD_NUMBERS: {
      ONE: 'एक',
      TWO: 'दो',
      THREE: 'तीन',
      FOUR: 'चार',
      FIVE: 'पाँच',
      SIX: 'छह',
      SEVEN: 'सात',
      EIGHT: 'आठ',
      NINE: 'नौ',
      TEN: 'दस',
      TWELVE: 'बारह',
      FIFTEEN: 'पंद्रह',
      TWENTY: 'बीस',
      THIRTY: 'तीस',
    },
  };

  const zhTWSnoozeTranslations = {
    UNITS: {
      HOUR: '小時',
      HOURS: '小時',
      DAY: '天',
      DAYS: '天',
    },
    HALF: '半',
    RELATIVE: {
      TOMORROW: '明天',
    },
    MERIDIEM: {
      AM: '上午',
      PM: '下午',
    },
    AFTER: '後',
  };

  describe('P1: short non-English tokens must NOT produce spurious half-duration suggestions', () => {
    it('Arabic "غد" does not produce half-duration suggestions', () => {
      const results = generateDateSuggestions('غد', now, {
        translations: arTranslations,
        locale: 'ar',
      });
      const halfLabels = results.filter(r => /half/i.test(r.label));
      expect(halfLabels).toHaveLength(0);
    });

    it('Hindi "सु" does not produce half-duration suggestions', () => {
      const results = generateDateSuggestions('सु', now, {
        translations: hiTranslations,
        locale: 'hi',
      });
      const halfLabels = results.filter(r => /half/i.test(r.label));
      expect(halfLabels).toHaveLength(0);
    });
  });

  describe('P1: MERIDIEM vs TIME_OF_DAY — "tomorrow morning" must parse in locales where AM = morning', () => {
    it('Arabic "غداً صباحاً" (tomorrow morning) parses correctly', () => {
      const results = generateDateSuggestions('غداً صباحاً', now, {
        translations: arTranslations,
        locale: 'ar',
      });
      expect(results.length).toBeGreaterThan(0);
      const first = results[0];
      expect(first.date.getDate()).toBe(17);
      expect(first.date.getHours()).toBe(9);
    });

    it('Hindi "कल सुबह" (tomorrow morning) parses correctly', () => {
      const results = generateDateSuggestions('कल सुबह', now, {
        translations: hiTranslations,
        locale: 'hi',
      });
      expect(results.length).toBeGreaterThan(0);
      const first = results[0];
      expect(first.date.getDate()).toBe(17);
      expect(first.date.getHours()).toBe(9);
    });
  });

  describe('basic localized parsing still works', () => {
    it('Arabic "غداً" (tomorrow) parses to tomorrow 9am', () => {
      const results = generateDateSuggestions('غداً', now, {
        translations: arTranslations,
        locale: 'ar',
      });
      expect(results.length).toBeGreaterThan(0);
      expect(results[0].date.getDate()).toBe(17);
    });

    it('Hindi "कल" (tomorrow) parses to tomorrow', () => {
      const results = generateDateSuggestions('कल', now, {
        translations: hiTranslations,
        locale: 'hi',
      });
      expect(results.length).toBeGreaterThan(0);
      expect(results[0].date.getDate()).toBe(17);
    });

    it('Arabic "غداً،" (tomorrow with attached Arabic comma) parses correctly', () => {
      const results = generateDateSuggestions('غداً،', now, {
        translations: arTranslations,
        locale: 'ar',
      });
      expect(results.length).toBeGreaterThan(0);
      expect(results[0].date.getDate()).toBe(17);
    });
  });

  describe('localized Unicode digits', () => {
    it('Arabic-Indic digits parse in time expressions', () => {
      const results = generateDateSuggestions('غداً الساعة ١٢:٣٠', now, {
        translations: arTranslations,
        locale: 'ar',
      });
      expect(results.length).toBeGreaterThan(0);
      expect(results[0].date.getDate()).toBe(17);
      expect(results[0].date.getHours()).toBe(12);
      expect(results[0].date.getMinutes()).toBe(30);
    });

    it('Devanagari digits parse in time-of-day expressions', () => {
      const results = generateDateSuggestions('कल सुबह ६', now, {
        translations: hiTranslations,
        locale: 'hi',
      });
      expect(results.length).toBeGreaterThan(0);
      expect(results[0].date.getDate()).toBe(17);
      expect(results[0].date.getHours()).toBe(6);
    });
  });

  describe('zh_TW compact CJK inputs', () => {
    const options = {
      translations: zhTWSnoozeTranslations,
      locale: 'zh-TW',
    };

    it('parses "2小時後" (2 hours from now) without spaces', () => {
      const results = generateDateSuggestions('2小時後', now, options);
      expect(results.length).toBeGreaterThan(0);
      expect(results[0].date.getDate()).toBe(16);
      expect(results[0].date.getHours()).toBe(12);
      expect(results[0].date.getMinutes()).toBe(0);
    });

    it('parses "半天" (half day) without spaces', () => {
      const results = generateDateSuggestions('半天', now, options);
      expect(results.length).toBeGreaterThan(0);
      expect(results[0].date.getDate()).toBe(16);
      expect(results[0].date.getHours()).toBe(22);
      expect(results[0].date.getMinutes()).toBe(0);
    });

    it('parses "明天 上午" (tomorrow AM) into tomorrow 9am', () => {
      const results = generateDateSuggestions('明天 上午', now, options);
      expect(results.length).toBeGreaterThan(0);
      expect(results[0].date.getDate()).toBe(17);
      expect(results[0].date.getHours()).toBe(9);
      expect(results[0].date.getMinutes()).toBe(0);
    });
  });
});

describe('no-space duration suggestions', () => {
  it('"1d" generates day suggestions', () => {
    const results = generateDateSuggestions('1d', now);
    expect(results.length).toBeGreaterThan(0);
    expect(results[0].label).toBe('1 days');
  });

  it('"2min" generates minute suggestions', () => {
    const results = generateDateSuggestions('2min', now);
    expect(results.length).toBeGreaterThan(0);
    expect(results[0].label).toBe('2 minutes');
  });

  it('"1h" generates hour suggestions', () => {
    const results = generateDateSuggestions('1h', now);
    expect(results.length).toBeGreaterThan(0);
    expect(results[0].label).toBe('1 hour');
  });

  it('"2ho" generates hour suggestions (partial match)', () => {
    const results = generateDateSuggestions('2ho', now);
    expect(results.length).toBeGreaterThan(0);
    expect(results[0].label).toBe('2 hours');
  });

  it('"3w" generates week suggestions', () => {
    const results = generateDateSuggestions('3w', now);
    expect(results.length).toBeGreaterThan(0);
    expect(results[0].label).toBe('3 weeks');
  });

  it('"1h30m" generates compound suggestion', () => {
    const results = generateDateSuggestions('1h30m', now);
    expect(results.length).toBeGreaterThan(0);
  });
});
