import { describe, it, expect } from 'vitest';
import {
  formatPhoneNumber,
  formatAsYouTypeInput,
} from 'shared/helpers/PhoneNumberHelper';

describe('PhoneNumberHelper', () => {
  describe('formatPhoneNumber', () => {
    it('returns empty string for falsy or non-string inputs', () => {
      expect(formatPhoneNumber(null)).toBe('');
      expect(formatPhoneNumber(undefined)).toBe('');
      expect(formatPhoneNumber('')).toBe('');
      expect(formatPhoneNumber(123456789)).toBe('');
      expect(formatPhoneNumber({})).toBe('');
    });

    it('formats E.164 phone numbers with proper international spacing', () => {
      expect(formatPhoneNumber('+905321234567')).toBe('+90 532 123 45 67');
      expect(formatPhoneNumber('+12025550123')).toBe('+1 202 555 0123');
      expect(formatPhoneNumber('+442071838750')).toBe('+44 20 7183 8750');
      expect(formatPhoneNumber('+33123456789')).toBe('+33 1 23 45 67 89');
      expect(formatPhoneNumber('+93701234567')).toBe('+93 70 123 4567');
    });

    it('formats numbers containing dashes or pre-existing spacing correctly', () => {
      expect(formatPhoneNumber('+1-202-555-0123')).toBe('+1 202 555 0123');
      expect(formatPhoneNumber('+90 532 1234567')).toBe('+90 532 123 45 67');
    });

    it('safely returns the original string if parsing fails or input is invalid', () => {
      expect(formatPhoneNumber('invalid-number')).toBe('invalid-number');
      expect(formatPhoneNumber('not_a_phone')).toBe('not_a_phone');
    });
  });

  describe('formatAsYouTypeInput', () => {
    it('returns empty string for falsy inputs', () => {
      expect(formatAsYouTypeInput('+90', 'TR', '')).toBe('');
      expect(formatAsYouTypeInput('+90', 'TR', null)).toBe('');
      expect(formatAsYouTypeInput('+90', 'TR', undefined)).toBe('');
    });

    it('formats national inputs correctly across various countries', () => {
      // Turkey
      expect(formatAsYouTypeInput('+90', 'TR', '5321234567')).toBe(
        '532 123 45 67'
      );
      // United States
      expect(formatAsYouTypeInput('+1', 'US', '2025550123')).toBe(
        '(202) 555-0123'
      );
      // Afghanistan (requires dial code fallback for leading-zero trunk prefix)
      expect(formatAsYouTypeInput('+93', 'AF', '701234567')).toBe(
        '70 123 4567'
      );
      // United Kingdom
      expect(formatAsYouTypeInput('+44', 'GB', '7911123456')).toBe(
        '7911 123456'
      );
      // Germany
      expect(formatAsYouTypeInput('+49', 'DE', '15123456789')).toBe(
        '1512 3456789'
      );
      // France
      expect(formatAsYouTypeInput('+33', 'FR', '612345678')).toBe(
        '6 12 34 56 78'
      );
    });

    it('preserves raw string and does not strip characters when input contains invalid non-phone characters', () => {
      expect(formatAsYouTypeInput('+1', 'US', '1-800-FLOWERS')).toBe(
        '1-800-FLOWERS'
      );
      expect(formatAsYouTypeInput('+90', 'TR', '0555 ABC 1234')).toBe(
        '0555 ABC 1234'
      );
      expect(formatAsYouTypeInput('+1', 'US', 'invalid phone')).toBe(
        'invalid phone'
      );
    });
  });
});
