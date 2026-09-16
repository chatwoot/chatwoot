import messages from 'dashboard/i18n';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useExactTimestamp } from '../useExactTimestamp';

vi.mock('vue-i18n');

// Feb 10 2021, 3:35:43 PM UTC
const TIMESTAMP = 1612971343;

// The languages the dashboard registers, so a newly shipped one is covered.
const LOCALES = Object.keys(messages);

describe('useExactTimestamp', () => {
  // Expectations are in UTC; vitest runs with TZ=UTC in CI.
  beforeEach(() => {
    vi.mocked(useI18n).mockReturnValue({ locale: ref('en') });
  });

  it('formats the full date and time in the dashboard language', () => {
    vi.mocked(useI18n).mockReturnValue({ locale: ref('de') });
    const exactTimestamp = useExactTimestamp();
    expect(exactTimestamp(TIMESTAMP)).toBe('10.02.2021, 15:35');
  });

  it('formats the month name and clock convention per locale', () => {
    vi.mocked(useI18n).mockReturnValue({ locale: ref('fr') });
    const exactTimestamp = useExactTimestamp();
    expect(exactTimestamp(TIMESTAMP)).toBe('10 févr. 2021, 15:35');
  });

  it('keeps the 12 hour clock for locales that use it', () => {
    const exactTimestamp = useExactTimestamp();
    // The space before the meridiem differs between ICU versions.
    expect(exactTimestamp(TIMESTAMP)).toMatch(/^Feb 10, 2021, 3:35\sPM$/);
  });

  it('reformats when the dashboard language changes', () => {
    const locale = ref('en');
    vi.mocked(useI18n).mockReturnValue({ locale });
    const exactTimestamp = useExactTimestamp();
    expect(exactTimestamp(TIMESTAMP)).toContain('Feb 10, 2021');

    locale.value = 'ja';
    expect(exactTimestamp(TIMESTAMP)).toBe('2021/02/10 15:35');
  });

  it('keeps the Gregorian calendar for locales that default to another one', () => {
    // Thai and Persian default to the Buddhist and Solar Hijri calendars, which
    // would date this to 2564 and 1399.
    vi.mocked(useI18n).mockReturnValue({ locale: ref('th') });
    expect(useExactTimestamp()(TIMESTAMP)).toContain('2021');

    vi.mocked(useI18n).mockReturnValue({ locale: ref('fa') });
    expect(useExactTimestamp()(TIMESTAMP)).toContain('۲۰۲۱');
  });

  it.each(LOCALES)('formats a timestamp in %s', localeCode => {
    vi.mocked(useI18n).mockReturnValue({ locale: ref(localeCode) });
    const exactTimestamp = useExactTimestamp();
    // Each locale renders digits in its own numbering system, so build the
    // year the same way rather than assuming Latin ones.
    const year = new Intl.NumberFormat(localeCode.replace(/_/g, '-'), {
      useGrouping: false,
    }).format(2021);

    expect(exactTimestamp(TIMESTAMP)).toContain(year);
  });

  it('returns an empty string when there is no timestamp', () => {
    const exactTimestamp = useExactTimestamp();
    expect(exactTimestamp(0)).toBe('');
    expect(exactTimestamp(null)).toBe('');
    expect(exactTimestamp(undefined)).toBe('');
    expect(exactTimestamp('')).toBe('');
  });

  describe('with showTimeZone', () => {
    // Nov 27 2025, 15:35:53 UTC — late November keeps northern zones on
    // standard time.
    const WINTER_TIMESTAMP = 1764257753;
    // Jul 15 2025, 12:00:00 UTC — the same zones' daylight-saving half.
    const SUMMER_TIMESTAMP = 1752580800;

    const RealDateTimeFormat = Intl.DateTimeFormat;
    let dateTimeFormatSpy;

    afterEach(() => {
      dateTimeFormatSpy?.mockRestore();
      dateTimeFormatSpy = undefined;
    });

    // Browsers default Intl to the agent's zone, but vitest workers cannot
    // switch the process zone at runtime, so simulate the agent's zone by
    // injecting an explicit timeZone into the formatters the composable
    // builds. Fresh module per case, as its formatter cache is locale-keyed.
    const exactTimestampIn = async (timeZone, options) => {
      dateTimeFormatSpy = vi
        .spyOn(Intl, 'DateTimeFormat')
        .mockImplementation(
          (locale, formatOptions) =>
            new RealDateTimeFormat(locale, { ...formatOptions, timeZone })
        );
      vi.resetModules();
      const { useExactTimestamp: freshComposable } = await import(
        '../useExactTimestamp'
      );
      return freshComposable(options);
    };

    it('appends the UTC label for a UTC user', async () => {
      const exactTimestamp = await exactTimestampIn('UTC', {
        showTimeZone: true,
      });
      expect(exactTimestamp(WINTER_TIMESTAMP)).toMatch(
        /^Nov 27, 2025, 3:35\sPM \(UTC\)$/
      );
    });

    it('uses the named abbreviation where the locale has one', async () => {
      const exactTimestamp = await exactTimestampIn('America/Los_Angeles', {
        showTimeZone: true,
      });
      expect(exactTimestamp(WINTER_TIMESTAMP)).toMatch(
        /^Nov 27, 2025, 7:35\sAM \(PST\)$/
      );
    });

    it('follows daylight saving for the formatted instant', async () => {
      const exactTimestamp = await exactTimestampIn('America/Los_Angeles', {
        showTimeZone: true,
      });
      expect(exactTimestamp(SUMMER_TIMESTAMP)).toMatch(
        /^Jul 15, 2025, 5:00\sAM \(PDT\)$/
      );
    });

    it('renders whole-hour offsets as a GMT label', async () => {
      const exactTimestamp = await exactTimestampIn('Europe/Berlin', {
        showTimeZone: true,
      });
      expect(exactTimestamp(WINTER_TIMESTAMP)).toMatch(
        /^Nov 27, 2025, 4:35\sPM \(GMT\+1\)$/
      );
    });

    it.each([
      ['Asia/Kolkata', /^Nov 27, 2025, 9:05\sPM \(GMT\+5:30\)$/],
      ['Asia/Kathmandu', /^Nov 27, 2025, 9:20\sPM \(GMT\+5:45\)$/],
      ['America/St_Johns', /^Nov 27, 2025, 12:05\sPM \(GMT-3:30\)$/],
    ])(
      'keeps the fractional offset exact in %s',
      async (timeZone, expected) => {
        const exactTimestamp = await exactTimestampIn(timeZone, {
          showTimeZone: true,
        });
        expect(exactTimestamp(WINTER_TIMESTAMP)).toMatch(expected);
      }
    );

    it('crosses the date line for extreme offsets', async () => {
      const exactTimestamp = await exactTimestampIn('Pacific/Kiritimati', {
        showTimeZone: true,
      });
      expect(exactTimestamp(WINTER_TIMESTAMP)).toMatch(
        /^Nov 28, 2025, 5:35\sAM \(GMT\+14\)$/
      );
    });

    it('localizes the zone label with the dashboard language', async () => {
      vi.mocked(useI18n).mockReturnValue({ locale: ref('fr') });
      const exactTimestamp = await exactTimestampIn('Asia/Kolkata', {
        showTimeZone: true,
      });
      expect(exactTimestamp(WINTER_TIMESTAMP)).toBe(
        '27 nov. 2025, 21:05 (UTC+5:30)'
      );
    });

    it('keeps the parenthesized zone label at the end for RTL languages', async () => {
      vi.mocked(useI18n).mockReturnValue({ locale: ref('ar') });
      const exactTimestamp = await exactTimestampIn('Asia/Kolkata', {
        showTimeZone: true,
      });
      const formatted = exactTimestamp(WINTER_TIMESTAMP);
      expect(formatted).toContain('9:05 م');
      expect(formatted).toMatch(/\(غرينتش\+5:30\)$/);
    });

    it('leaves the default format without a zone label', async () => {
      dateTimeFormatSpy = vi.spyOn(Intl, 'DateTimeFormat').mockImplementation(
        (locale, formatOptions) =>
          new RealDateTimeFormat(locale, {
            ...formatOptions,
            timeZone: 'Asia/Kolkata',
          })
      );
      vi.resetModules();
      const { useExactTimestamp: freshComposable } = await import(
        '../useExactTimestamp'
      );
      // Both variants from the same module instance, so this also proves the
      // formatter cache keeps the two apart.
      expect(freshComposable()(WINTER_TIMESTAMP)).toMatch(
        /^Nov 27, 2025, 9:05\sPM$/
      );
      expect(freshComposable({ showTimeZone: true })(WINTER_TIMESTAMP)).toMatch(
        /^Nov 27, 2025, 9:05\sPM \(GMT\+5:30\)$/
      );
    });
  });
});
