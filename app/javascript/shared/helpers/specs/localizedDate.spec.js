import { ref } from 'vue';
import {
  attributeCalendarDate,
  bindDateLocale,
  formatClockTime,
  formatDuration,
  formatElapsed,
  formatLocalized,
  intlOptionsFor,
  normalizeLocale,
  relativeParts,
  weekdayName,
} from 'shared/helpers/localizedDate';
import {
  dateFormat,
  dynamicTime,
  messageStamp,
  messageTimestamp,
  relativeDayTimestamp,
  shortTimestamp,
} from 'shared/helpers/timeHelper';
import { formatDate } from 'shared/helpers/DateHelper';

const locale = ref('en');
bindDateLocale({ global: { locale } });

// 2026-04-21 21:48 UTC and 2025-08-03 00:05 UTC.
const APRIL_EVENING = Date.UTC(2026, 3, 21, 21, 48) / 1000;
const LAST_YEAR_MIDNIGHT = Date.UTC(2025, 7, 3, 0, 5) / 1000;

beforeEach(() => {
  process.env.TZ = 'UTC';
  vi.useFakeTimers('modern');
  vi.setSystemTime(new Date(Date.UTC(2026, 4, 5, 12)));
  locale.value = 'en';
});

afterEach(() => {
  vi.useRealTimers();
});

describe('message times in the conversation', () => {
  it('follow pt_BR with a 24-hour clock', () => {
    locale.value = 'pt_BR';
    const text = messageTimestamp(APRIL_EVENING, 'LLL d, h:mm a');
    expect(text).toContain('abr');
    expect(text).toContain('21:48');
    expect(text).not.toMatch(/Apr|AM|PM/);
  });

  it('carry the year and a 24-hour midnight for another year', () => {
    locale.value = 'pt_BR';
    const text = messageTimestamp(LAST_YEAR_MIDNIGHT, 'LLL d, h:mm a');
    expect(text).toContain('2025');
    expect(text).toContain('ago');
    expect(text).toContain('00:05');
  });

  it('keep the day and month of an old time-only stamp', () => {
    locale.value = 'pt_BR';
    const text = messageTimestamp(LAST_YEAR_MIDNIGHT, 'h:mm a');
    expect(text).toContain('3');
    expect(text).toContain('ago');
    expect(text).toContain('2025');
  });

  it('follow Spanish', () => {
    locale.value = 'es';
    expect(messageTimestamp(APRIL_EVENING, 'LLL d, h:mm a')).toContain('21:48');
  });

  it('stay byte-identical in English', () => {
    expect(messageTimestamp(APRIL_EVENING, 'LLL d, h:mm a')).toBe(
      'Apr 21, 9:48 PM'
    );
    expect(messageTimestamp(LAST_YEAR_MIDNIGHT, 'LLL d, h:mm a')).toBe(
      'Aug 3 2025, 12:05 AM'
    );
    expect(messageStamp(APRIL_EVENING)).toBe('9:48 PM');
    // Intl would reorder this one to "Apr 21, 2026, 9:48 PM".
    expect(dateFormat(APRIL_EVENING, 'dd MMM yyyy, h:mm a')).toBe(
      '21 Apr 2026, 9:48 PM'
    );
  });

  it('switch language without a reload', () => {
    locale.value = 'pt_BR';
    expect(messageStamp(APRIL_EVENING)).toBe('21:48');
    locale.value = 'en';
    expect(messageStamp(APRIL_EVENING)).toBe('9:48 PM');
  });

  it('fall back to English for a locale Intl does not know', () => {
    locale.value = 'xx_YY';
    expect(messageStamp(APRIL_EVENING)).toBe('9:48 PM');
  });
});

describe('list timestamps', () => {
  it('show today as a 24-hour time and older dates by name in pt_BR', () => {
    locale.value = 'pt_BR';
    vi.setSystemTime(new Date(Date.UTC(2026, 3, 21, 23)));
    expect(relativeDayTimestamp(APRIL_EVENING, 'ontem')).toBe('21:48');
    expect(dateFormat(LAST_YEAR_MIDNIGHT)).toContain('2025');
    expect(dateFormat(LAST_YEAR_MIDNIGHT)).not.toContain('Aug');
  });

  it('word relative times in pt_BR and shorten them from numbers', () => {
    locale.value = 'pt_BR';
    const fiveMinutesAgo = Date.now() / 1000 - 5 * 60;
    const long = dynamicTime(fiveMinutesAgo);
    expect(long).toBe('há 5 minutos');
    expect(shortTimestamp(long)).toMatch(/^5\s?min/);
    expect(shortTimestamp(long, true)).toContain('5');
    expect(shortTimestamp(long, true)).not.toContain('ago');
  });

  it('keep the English short form', () => {
    const fiveMinutesAgo = Date.now() / 1000 - 5 * 60;
    expect(shortTimestamp(dynamicTime(fiveMinutesAgo))).toBe('5m');
  });
});

describe('date separators', () => {
  it('name the month in the app language, keeping Today and Yesterday', () => {
    locale.value = 'pt_BR';
    expect(
      formatDate({
        date: 'Apr 21, 2026',
        todayText: 'Hoje',
        yesterdayText: 'Ontem',
      })
    ).toBe('21 de abr. de 2026');
    expect(
      formatDate({
        date: 'May 05, 2026',
        todayText: 'Hoje',
        yesterdayText: 'Ontem',
      })
    ).toBe('Hoje');
  });
});

describe('pattern reading', () => {
  it('drops literals and day periods and keeps the fields', () => {
    expect(intlOptionsFor("EEE, MMM d, yyyy 'at' p")).toEqual({
      weekday: 'short',
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
    });
  });

  it('refuses machine patterns so they stay date-fns', () => {
    expect(intlOptionsFor("yyyy-MM-dd'T'HH:mm:ssXXX")).toBeNull();
    locale.value = 'pt_BR';
    expect(formatLocalized(new Date(APRIL_EVENING * 1000), 'T')).toBe(
      String(APRIL_EVENING * 1000)
    );
  });

  it('normalizes vue-i18n locales into Intl tags', () => {
    expect(normalizeLocale('pt_BR')).toBe('pt-BR');
    expect(normalizeLocale('zz')).toBe('en');
    expect(normalizeLocale(undefined)).toBe('en');
  });
});

describe('relative units', () => {
  it('round like date-fns at the unit edges', () => {
    expect(relativeParts(-30)).toEqual({ value: 0, unit: 'second' });
    expect(relativeParts(-44 * 60)).toEqual({ value: -44, unit: 'minute' });
    expect(relativeParts(-46 * 60)).toEqual({ value: -1, unit: 'hour' });
    expect(relativeParts(3 * 86400)).toEqual({ value: 3, unit: 'day' });
  });
});

// These hold in any time zone; the suite runs in UTC, so run this file with
// TZ=America/Sao_Paulo and TZ=Asia/Kolkata too when touching the helper.
describe('date attributes', () => {
  it('read UTC midnight (contact page, API) as that UTC day', () => {
    const day = attributeCalendarDate('2026-03-07T00:00:00.000Z');
    expect([day.getFullYear(), day.getMonth(), day.getDate()]).toEqual([
      2026, 2, 7,
    ]);
    expect(attributeCalendarDate('2026-03-07').getDate()).toBe(7);
  });

  it('read local midnight (conversation sidebar) as that local day', () => {
    const saved = new Date(2026, 10, 14).toISOString();
    expect(attributeCalendarDate(saved).getDate()).toBe(14);
  });
});

describe('elapsed durations', () => {
  it('keep strict units in other languages', () => {
    locale.value = 'pt_BR';
    const start = new Date(Date.UTC(2026, 0, 1, 10));
    expect(formatElapsed(start, new Date(start.getTime() + 30 * 1000))).toBe(
      '30 segundos'
    );
    expect(
      formatElapsed(start, new Date(start.getTime() + 50 * 60 * 1000))
    ).toBe('50 minutos');
  });
});

describe('clock times', () => {
  it('format a slot hour that a daylight-saving gap would skip locally', () => {
    locale.value = 'pt_BR';
    // 02:00 does not exist on 2026-03-08 in America/New_York.
    vi.setSystemTime(new Date(Date.UTC(2026, 2, 8, 12)));
    expect(formatClockTime(2, 0)).toBe('02:00');
    expect(formatClockTime(14, 30)).toBe('14:30');
  });
});

describe('weekday names', () => {
  it('names the days of the week in the app language, as labels', () => {
    expect([0, 3, 6].map(weekdayName)).toEqual([
      'Sunday',
      'Wednesday',
      'Saturday',
    ]);

    locale.value = 'pt_BR';
    expect([0, 3, 6].map(weekdayName)).toEqual([
      'Domingo',
      'Quarta-feira',
      'Sábado',
    ]);

    locale.value = 'es';
    expect(weekdayName(5)).toBe('Viernes');
  });
});

describe('report durations', () => {
  const samples = [45, 28 * 60 + 40, 3 * 3600 + 5 * 60, 2 * 86400 + 4 * 3600];

  it('keeps the English report units', () => {
    expect(samples.map(formatDuration)).toEqual([
      '45 Sec',
      '28 Min 40 Sec',
      '3 Hr 5 Min',
      '2 Day 4 Hr',
    ]);
  });

  it('writes the units of the app language', () => {
    locale.value = 'pt_BR';
    const pt = samples.map(formatDuration);
    locale.value = 'es';
    const es = samples.map(formatDuration);
    [...pt, ...es].forEach(text => {
      expect(text).not.toMatch(/Sec|Min|Hr|Day/);
    });
    expect(pt[1]).toMatch(/^28 min 40 s$/);
    expect(es[3]).toMatch(/^2 d(ías?)? 4 h$/);
  });
});
