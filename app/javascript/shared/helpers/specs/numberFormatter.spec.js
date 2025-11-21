import {
  formatCompactNumber,
  formatFullNumber,
} from '../numberFormatterHelper';

describe('numberFormatter', () => {
  describe('formatCompactNumber', () => {
    it('should return exact numbers for values under 1,000', () => {
      expect(formatCompactNumber(0)).toBe('0');
      expect(formatCompactNumber(1)).toBe('1');
      expect(formatCompactNumber(42)).toBe('42');
      expect(formatCompactNumber(999)).toBe('999');
    });

    it('should return "Xk" for exact thousands and "Xk+" for values with remainder', () => {
      expect(formatCompactNumber(1000)).toBe('1k');
      expect(formatCompactNumber(1020)).toBe('1k+');
      expect(formatCompactNumber(1500)).toBe('1k+');
      expect(formatCompactNumber(1999)).toBe('1k+');
      expect(formatCompactNumber(2000)).toBe('2k');
      expect(formatCompactNumber(15000)).toBe('15k');
      expect(formatCompactNumber(15500)).toBe('15k+');
      expect(formatCompactNumber(999999)).toBe('999k+');
    });

    it('should return millions format for values 1,000,000 and above', () => {
      expect(formatCompactNumber(1000000)).toBe('1M');
      expect(formatCompactNumber(1200000)).toBe('1.2M');
      expect(formatCompactNumber(1234000)).toBe('1.2M');
      expect(formatCompactNumber(2500000)).toBe('2.5M');
      expect(formatCompactNumber(10000000)).toBe('10M');
    });

    it('should handle edge cases gracefully', () => {
      expect(formatCompactNumber(null)).toBe('0');
      expect(formatCompactNumber(undefined)).toBe('0');
      expect(formatCompactNumber(NaN)).toBe('0');
      expect(formatCompactNumber('string')).toBe('0');
    });

    it('should handle negative numbers', () => {
      expect(formatCompactNumber(-500)).toBe('-500');
      expect(formatCompactNumber(-1000)).toBe('-1k');
      expect(formatCompactNumber(-1500)).toBe('-1k+');
      expect(formatCompactNumber(-2000)).toBe('-2k');
      expect(formatCompactNumber(-1200000)).toBe('-1.2M');
    });
  });

  describe('formatFullNumber', () => {
    it('should format numbers with locale-specific formatting', () => {
      expect(formatFullNumber(1000)).toBe('1,000');
      expect(formatFullNumber(1234567)).toBe('1,234,567');
    });

    it('should handle edge cases gracefully', () => {
      expect(formatFullNumber(null)).toBe('0');
      expect(formatFullNumber(undefined)).toBe('0');
      expect(formatFullNumber(NaN)).toBe('0');
      expect(formatFullNumber('string')).toBe('0');
    });
  });
});
