import { generateDateSuggestions } from '../localization';

describe('Snooze Date Parser Localization', () => {
  const referenceDate = new Date('2024-03-14T10:00:00');

  const mockTranslations = {
    UNITS: {
      MINUTE: 'mock_minute',
      MINUTES: 'mock_minutes',
      HOUR: 'mock_hour',
      HOURS: 'mock_hours',
      DAY: 'mock_day',
      DAYS: 'mock_days',
    },
    RELATIVE: {
      TODAY: 'mock_today',
      TONIGHT: 'mock_tonight',
      TOMORROW: 'mock_tomorrow',
      DAY_AFTER_TOMORROW: 'mock_day_after_tomorrow',
      NEXT_WEEK: 'mock_next_week',
    },
    TIME_OF_DAY: {
      MORNING: 'mock_morning',
      AFTERNOON: 'mock_afternoon',
      EVENING: 'mock_evening',
      NIGHT: 'mock_night',
      NOON: 'mock_noon',
    },
    FROM_NOW: 'mock_from_now',
  };

  describe('with locale translations', () => {
    const options = { translations: mockTranslations, locale: 'pt-BR' };

    it('generates localized weekday suggestions', () => {
      const results = generateDateSuggestions('sáb', referenceDate, options);
      expect(results.length).toBeGreaterThan(0);
    });

    it('includes time-of-day combinations with weekdays', () => {
      const results = generateDateSuggestions('sábado', referenceDate, options);
      expect(results.length).toBeGreaterThan(1);

      const queries = results.map(r => r.query.toLowerCase());
      expect(queries.some(q => q.includes('saturday'))).toBe(true);
    });

    it('keeps English query for parsing while showing localized label', () => {
      const results = generateDateSuggestions('sábado', referenceDate, options);
      expect(results.length).toBeGreaterThan(0);
      expect(results[0].query.toLowerCase()).toContain('saturday');
    });

    it('translates relative days from mock translations', () => {
      const results = generateDateSuggestions(
        'mock_tomorrow',
        referenceDate,
        options
      );
      expect(results.length).toBeGreaterThan(0);
      expect(results[0].query.toLowerCase()).toContain('tomorrow');
    });

    it('uses localized time-of-day from translations', () => {
      const results = generateDateSuggestions(
        'mock_tomorrow',
        referenceDate,
        options
      );
      expect(results.length).toBeGreaterThan(0);

      const hasLocalizedLabel = results.some(
        r => r.label.includes('mock_') || !r.label.includes('tomorrow')
      );
      expect(hasLocalizedLabel).toBe(true);
    });

    it('handles multi-word phrases like next week', () => {
      const results = generateDateSuggestions(
        'mock_next_week',
        referenceDate,
        options
      );
      expect(results.length).toBeGreaterThan(0);
      expect(results[0].query.toLowerCase()).toContain('next week');
    });

    it('includes numeric unit suggestions for localized users', () => {
      const results = generateDateSuggestions('5', referenceDate, options);
      const queries = results.map(r => r.query.toLowerCase());
      expect(
        queries.some(q => q.includes('hour') || q.includes('minute'))
      ).toBe(true);
    });

    it('merges localized and English suggestions', () => {
      const results = generateDateSuggestions('sáb', referenceDate, options);
      expect(results.length).toBeGreaterThanOrEqual(2);
    });
  });

  describe('without locale (English default)', () => {
    it('returns English suggestions', () => {
      const results = generateDateSuggestions('tomorrow', referenceDate);
      expect(results.length).toBeGreaterThan(0);
      expect(results[0].label.toLowerCase()).toContain('tomorrow');
    });

    it('includes time-of-day in English', () => {
      const results = generateDateSuggestions('saturday', referenceDate);
      const labels = results.map(r => r.label.toLowerCase());
      expect(labels.some(l => /morning|afternoon|evening/.test(l))).toBe(true);
    });
  });

  describe('edge cases', () => {
    const options = { translations: mockTranslations, locale: 'pt-BR' };

    it('returns empty array for empty input', () => {
      expect(generateDateSuggestions('', referenceDate, options)).toEqual([]);
    });

    it('returns empty array for null input', () => {
      expect(generateDateSuggestions(null, referenceDate, options)).toEqual([]);
    });

    it('returns empty array for no matches', () => {
      expect(generateDateSuggestions('xyz123', referenceDate, options)).toEqual(
        []
      );
    });

    it('is case insensitive', () => {
      const lower = generateDateSuggestions('sábado', referenceDate, options);
      const upper = generateDateSuggestions('SÁBADO', referenceDate, options);
      expect(lower.length).toBe(upper.length);
    });
  });

  describe('result structure', () => {
    it('returns objects with required properties', () => {
      const results = generateDateSuggestions('tomorrow', referenceDate);
      expect(results.length).toBeGreaterThan(0);

      const result = results[0];
      expect(result).toHaveProperty('label');
      expect(result).toHaveProperty('query');
      expect(result).toHaveProperty('date');
      expect(result).toHaveProperty('unix');
      expect(typeof result.label).toBe('string');
      expect(typeof result.query).toBe('string');
      expect(result.date).toBeInstanceOf(Date);
      expect(typeof result.unix).toBe('number');
    });

    it('returns future dates', () => {
      const results = generateDateSuggestions('tomorrow', referenceDate);
      results.forEach(r => {
        expect(r.date.getTime()).toBeGreaterThan(referenceDate.getTime());
      });
    });
  });
});
