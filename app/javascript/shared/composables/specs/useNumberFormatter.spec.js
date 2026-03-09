import { describe, it, expect, beforeEach, vi } from 'vitest';
import { useNumberFormatter } from '../useNumberFormatter';
import { useI18n } from 'vue-i18n';
import { ref } from 'vue';

vi.mock('vue-i18n');

describe('useNumberFormatter', () => {
  beforeEach(() => {
    vi.mocked(useI18n).mockReturnValue({
      locale: ref('en-US'),
    });
  });

  describe('formatCompactNumber', () => {
    it('should return exact numbers for values under 1,000', () => {
      const { formatCompactNumber } = useNumberFormatter();
      expect(formatCompactNumber(0)).toBe('0');
      expect(formatCompactNumber(1)).toBe('1');
      expect(formatCompactNumber(42)).toBe('42');
      expect(formatCompactNumber(999)).toBe('999');
    });

    it('should return "Xk" for exact thousands and "Xk+" for values with remainder', () => {
      const { formatCompactNumber } = useNumberFormatter();
      expect(formatCompactNumber(1000)).toBe('1k');
      expect(formatCompactNumber(1020)).toBe('1k+');
      expect(formatCompactNumber(1500)).toBe('1k+');
      expect(formatCompactNumber(1999)).toBe('1k+');
      expect(formatCompactNumber(2000)).toBe('2k');
      expect(formatCompactNumber(15000)).toBe('15k');
      expect(formatCompactNumber(15500)).toBe('15k+');
      expect(formatCompactNumber(999999)).toBe('999k+');
    });

    it('should return millions/billion/trillion format for values 1,000,000 and above', () => {
      const { formatCompactNumber } = useNumberFormatter();
      expect(formatCompactNumber(1000000)).toBe('1M');
      expect(formatCompactNumber(1000001)).toBe('1.0M');
      expect(formatCompactNumber(1200000)).toBe('1.2M');
      expect(formatCompactNumber(1234000)).toBe('1.2M');
      expect(formatCompactNumber(2500000)).toBe('2.5M');
      expect(formatCompactNumber(10000000)).toBe('10M');
      expect(formatCompactNumber(1000000000)).toBe('1B');
      expect(formatCompactNumber(1100000000)).toBe('1.1B');
      expect(formatCompactNumber(10000000000)).toBe('10B');
      expect(formatCompactNumber(11000000000)).toBe('11B');
      expect(formatCompactNumber(1000000000000)).toBe('1T');
      expect(formatCompactNumber(1100000000000)).toBe('1.1T');
      expect(formatCompactNumber(10000000000000)).toBe('10T');
      expect(formatCompactNumber(11000000000000)).toBe('11T');
    });

    it('should handle edge cases gracefully', () => {
      const { formatCompactNumber } = useNumberFormatter();
      expect(formatCompactNumber(null)).toBe('0');
      expect(formatCompactNumber(undefined)).toBe('0');
      expect(formatCompactNumber(NaN)).toBe('0');
      expect(formatCompactNumber('string')).toBe('0');
    });

    it('should handle negative numbers', () => {
      const { formatCompactNumber } = useNumberFormatter();
      expect(formatCompactNumber(-500)).toBe('-500');
      expect(formatCompactNumber(-1000)).toBe('-1k');
      expect(formatCompactNumber(-1500)).toBe('-1k+');
      expect(formatCompactNumber(-2000)).toBe('-2k');
      expect(formatCompactNumber(-1200000)).toBe('-1.2M');
    });

    it('should format with en-US locale', () => {
      const mockLocale = ref('en-US');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatCompactNumber } = useNumberFormatter();
      expect(formatCompactNumber(1500)).toBe('1k+');
    });

    it('should format with de-DE locale', () => {
      const mockLocale = ref('de-DE');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatCompactNumber } = useNumberFormatter();
      expect(formatCompactNumber(2000)).toBe('2k');
    });

    it('should format with fr-FR locale (compact notation)', () => {
      const mockLocale = ref('fr-FR');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatCompactNumber } = useNumberFormatter();
      const result = formatCompactNumber(1000000);
      expect(result).toMatch(/1\s*M/); // French uses space before M
    });

    it('should format with ja-JP locale', () => {
      const mockLocale = ref('ja-JP');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatCompactNumber } = useNumberFormatter();
      expect(formatCompactNumber(999)).toBe('999');
    });

    it('should format with ar-SA locale (Arabic numerals)', () => {
      const mockLocale = ref('ar-SA');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatCompactNumber } = useNumberFormatter();
      const result = formatCompactNumber(5000);
      expect(result).toContain('k');
      expect(typeof result).toBe('string');
    });

    it('should format with es-ES locale', () => {
      const mockLocale = ref('es-ES');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatCompactNumber } = useNumberFormatter();
      expect(formatCompactNumber(7500)).toBe('7k+');
    });

    it('should format with hi-IN locale', () => {
      const mockLocale = ref('hi-IN');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatCompactNumber } = useNumberFormatter();
      expect(formatCompactNumber(100000)).toBe('100k');
    });

    it('should format with ru-RU locale', () => {
      const mockLocale = ref('ru-RU');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatCompactNumber } = useNumberFormatter();
      expect(formatCompactNumber(3000)).toBe('3k');
    });

    it('should format with ko-KR locale (uses 만 for 10,000)', () => {
      const mockLocale = ref('ko-KR');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatCompactNumber } = useNumberFormatter();
      const result = formatCompactNumber(2500000);
      expect(result).toContain('만'); // Korean uses 만 (10,000) as a unit, so 2,500,000 should contain 만
    });

    it('should format with pt-BR locale', () => {
      const mockLocale = ref('pt-BR');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatCompactNumber } = useNumberFormatter();
      expect(formatCompactNumber(8888)).toBe('8k+');
    });

    it('should handle underscore-based locale tags (pt_BR)', () => {
      const mockLocale = ref('pt_BR');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatCompactNumber } = useNumberFormatter();
      // Should normalize pt_BR to pt-BR and work correctly
      expect(formatCompactNumber(8888)).toBe('8k+');
      expect(formatCompactNumber(1000000)).toBe('1\u00a0mi');
    });

    it('should handle underscore-based locale tags (zh_CN)', () => {
      const mockLocale = ref('zh_CN');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatCompactNumber } = useNumberFormatter();
      // Should normalize zh_CN to zh-CN and work correctly
      expect(formatCompactNumber(999)).toBe('999');
      expect(formatCompactNumber(5000)).toBe('5k');
    });

    it('should handle underscore-based locale tags (en_US)', () => {
      const mockLocale = ref('en_US');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatCompactNumber } = useNumberFormatter();
      // Should normalize en_US to en-US and work correctly
      expect(formatCompactNumber(1500)).toBe('1k+');
      expect(formatCompactNumber(1000000)).toBe('1M');
    });

    it('should handle null/undefined locale gracefully', () => {
      const mockLocale = ref(null);
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatCompactNumber } = useNumberFormatter();
      // Should fall back to 'en' locale
      expect(formatCompactNumber(1500)).toBe('1k+');
    });

    it('should fall back to base language when specific locale not supported', () => {
      // Simulate a case where pt-BR might not be fully supported but pt is
      const mockLocale = ref('pt-BR');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatCompactNumber } = useNumberFormatter();
      // Should work with either pt-BR or pt fallback
      const result = formatCompactNumber(1500);
      expect(result).toMatch(/1k\+/);
    });

    it('should fall back to English for completely unsupported locales', () => {
      // Use a completely made-up locale
      const mockLocale = ref('xx-YY');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatCompactNumber } = useNumberFormatter();
      // Should fall back to 'en' and work
      expect(formatCompactNumber(1500)).toBe('1k+');
      expect(formatCompactNumber(1000000)).toBe('1M');
    });

    it('should handle edge case with only base language code', () => {
      const mockLocale = ref('pt');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatCompactNumber } = useNumberFormatter();
      // Should work with base language
      expect(formatCompactNumber(2000)).toBe('2k');
    });
  });

  describe('formatFullNumber', () => {
    it('should format numbers with locale-specific formatting', () => {
      const { formatFullNumber } = useNumberFormatter();
      expect(formatFullNumber(1000)).toBe('1,000');
      expect(formatFullNumber(1234567)).toBe('1,234,567');
      expect(formatFullNumber(1234567890)).toBe('1,234,567,890');
      expect(formatFullNumber(1234567890123)).toBe('1,234,567,890,123');
    });

    it('should handle edge cases gracefully', () => {
      const { formatFullNumber } = useNumberFormatter();
      expect(formatFullNumber(null)).toBe('0');
      expect(formatFullNumber(undefined)).toBe('0');
      expect(formatFullNumber(NaN)).toBe('0');
      expect(formatFullNumber('string')).toBe('0');
    });

    it('should format with en-US locale (comma separator)', () => {
      const mockLocale = ref('en-US');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatFullNumber } = useNumberFormatter();
      expect(formatFullNumber(1234567)).toBe('1,234,567');
    });

    it('should format with de-DE locale (period separator)', () => {
      const mockLocale = ref('de-DE');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatFullNumber } = useNumberFormatter();
      expect(formatFullNumber(9876543)).toBe('9.876.543');
    });

    it('should format with es-ES locale (period separator)', () => {
      const mockLocale = ref('es-ES');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatFullNumber } = useNumberFormatter();
      expect(formatFullNumber(5555555)).toBe('5.555.555');
    });

    it('should format with zh-CN locale', () => {
      const mockLocale = ref('zh-CN');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatFullNumber } = useNumberFormatter();
      expect(formatFullNumber(1000000)).toBe('1,000,000');
    });

    it('should format with ar-EG locale (Arabic numerals, RTL)', () => {
      const mockLocale = ref('ar-EG');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatFullNumber } = useNumberFormatter();
      const result = formatFullNumber(7654321);
      // Arabic locale uses Eastern Arabic numerals (٠-٩)
      // Just verify it's formatted (length should be reasonable)
      expect(result.length).toBeGreaterThan(6);
    });

    it('should format with fr-FR locale (narrow no-break space)', () => {
      const mockLocale = ref('fr-FR');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatFullNumber } = useNumberFormatter();
      const result = formatFullNumber(3333333);
      expect(result).toContain('3');
      expect(result).toContain('333');
    });

    it('should format with hi-IN locale (Indian numbering system)', () => {
      const mockLocale = ref('hi-IN');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatFullNumber } = useNumberFormatter();
      expect(formatFullNumber(9999999)).toBe('99,99,999');
    });

    it('should format with th-TH locale', () => {
      const mockLocale = ref('th-TH');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatFullNumber } = useNumberFormatter();
      expect(formatFullNumber(4444444)).toBe('4,444,444');
    });

    it('should format with tr-TR locale', () => {
      const mockLocale = ref('tr-TR');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatFullNumber } = useNumberFormatter();
      expect(formatFullNumber(6666666)).toBe('6.666.666');
    });

    it('should format with pt-PT locale (space separator)', () => {
      const mockLocale = ref('pt-PT');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatFullNumber } = useNumberFormatter();
      const result = formatFullNumber(2222222);
      // Portuguese (Portugal) uses narrow no-break space as separator
      expect(result).toMatch(/2[\s\u202f]222[\s\u202f]222/);
    });

    it('should handle underscore-based locale tags (pt_BR)', () => {
      const mockLocale = ref('pt_BR');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatFullNumber } = useNumberFormatter();
      // Should normalize pt_BR to pt-BR and work correctly
      expect(formatFullNumber(1234567)).toBe('1.234.567');
    });

    it('should handle underscore-based locale tags (zh_CN)', () => {
      const mockLocale = ref('zh_CN');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatFullNumber } = useNumberFormatter();
      // Should normalize zh_CN to zh-CN and work correctly
      expect(formatFullNumber(1000000)).toBe('1,000,000');
    });

    it('should handle underscore-based locale tags (en_US)', () => {
      const mockLocale = ref('en_US');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatFullNumber } = useNumberFormatter();
      // Should normalize en_US to en-US and work correctly
      expect(formatFullNumber(1234567)).toBe('1,234,567');
    });

    it('should handle null/undefined locale gracefully', () => {
      const mockLocale = ref(null);
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatFullNumber } = useNumberFormatter();
      // Should fall back to 'en' locale
      expect(formatFullNumber(1234567)).toBe('1,234,567');
    });

    it('should fall back to base language when specific locale not supported', () => {
      // Simulate a case where pt-BR might not be fully supported but pt is
      const mockLocale = ref('pt-BR');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatFullNumber } = useNumberFormatter();
      // Should work with either pt-BR or pt fallback
      const result = formatFullNumber(1234567);
      // Portuguese uses period as thousands separator
      expect(result).toMatch(/1[.,\s]234[.,\s]567/);
    });

    it('should fall back to English for completely unsupported locales', () => {
      // Use a completely made-up locale
      const mockLocale = ref('xx-YY');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatFullNumber } = useNumberFormatter();
      // Should fall back to 'en' and work
      expect(formatFullNumber(1234567)).toBe('1,234,567');
    });

    it('should handle edge case with only base language code', () => {
      const mockLocale = ref('pt');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { formatFullNumber } = useNumberFormatter();
      // Should work with base language
      const result = formatFullNumber(1000000);
      expect(result).toMatch(/1[.,\s]000[.,\s]000/);
    });
  });
});
