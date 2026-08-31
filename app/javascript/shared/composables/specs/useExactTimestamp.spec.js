import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useExactTimestamp } from '../useExactTimestamp';

vi.mock('vue-i18n');

// Feb 10 2021, 3:35:43 PM UTC
const TIMESTAMP = 1612971343;

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

  it('translates the month name and clock convention per locale', () => {
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
    vi.mocked(useI18n).mockReturnValue({ locale: ref('th') });
    const exactTimestamp = useExactTimestamp();
    // The Buddhist calendar Thai defaults to would date this to 2564.
    expect(exactTimestamp(TIMESTAMP)).toContain('2021');
  });

  it('returns an empty string when there is no timestamp', () => {
    const exactTimestamp = useExactTimestamp();
    expect(exactTimestamp(0)).toBe('');
    expect(exactTimestamp(null)).toBe('');
    expect(exactTimestamp(undefined)).toBe('');
    expect(exactTimestamp('')).toBe('');
  });
});
