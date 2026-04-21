import { describe, it, expect, beforeEach, vi } from 'vitest';
import { useLocale } from '../useLocale';
import { useI18n } from 'vue-i18n';
import { ref } from 'vue';

vi.mock('vue-i18n');

describe('useLocale', () => {
  beforeEach(() => {
    vi.mocked(useI18n).mockReturnValue({
      locale: ref('en-US'),
    });
  });

  describe('resolvedLocale', () => {
    it('should return normalized locale for valid hyphen-based tags', () => {
      const mockLocale = ref('en-US');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { resolvedLocale } = useLocale();
      expect(resolvedLocale.value).toBe('en-US');
    });

    it('should normalize underscore-based locale tags to hyphens', () => {
      const mockLocale = ref('pt_BR');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { resolvedLocale } = useLocale();
      // Should normalize pt_BR to pt-BR
      expect(resolvedLocale.value).toMatch(/^pt(-BR)?$/);
    });

    it('should normalize zh_CN to zh-CN or fall back to zh', () => {
      const mockLocale = ref('zh_CN');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { resolvedLocale } = useLocale();
      // Should normalize zh_CN to zh-CN or fall back to zh
      expect(resolvedLocale.value).toMatch(/^zh(-CN)?$/);
    });

    it('should normalize en_US to en-US or fall back to en', () => {
      const mockLocale = ref('en_US');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { resolvedLocale } = useLocale();
      // Should normalize en_US to en-US or fall back to en
      expect(resolvedLocale.value).toMatch(/^en(-US)?$/);
    });

    it('should fall back to base language when specific locale not supported', () => {
      // Use a specific locale that might not be fully supported
      const mockLocale = ref('pt-BR');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { resolvedLocale } = useLocale();
      // Should return either pt-BR or pt (base language)
      expect(resolvedLocale.value).toMatch(/^pt(-BR)?$/);
    });

    it('should fall back to English for completely unsupported locales', () => {
      const mockLocale = ref('xx-YY');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { resolvedLocale } = useLocale();
      // Should fall back to 'en'
      expect(resolvedLocale.value).toBe('en');
    });

    it('should handle null locale gracefully', () => {
      const mockLocale = ref(null);
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { resolvedLocale } = useLocale();
      // Should fall back to 'en'
      expect(resolvedLocale.value).toBe('en');
    });

    it('should handle undefined locale gracefully', () => {
      const mockLocale = ref(undefined);
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { resolvedLocale } = useLocale();
      // Should fall back to 'en'
      expect(resolvedLocale.value).toBe('en');
    });

    it('should handle base language code without region', () => {
      const mockLocale = ref('pt');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { resolvedLocale } = useLocale();
      // Should work with base language
      expect(resolvedLocale.value).toBe('pt');
    });

    it('should handle multiple underscores in locale tag', () => {
      const mockLocale = ref('zh_Hans_CN');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { resolvedLocale } = useLocale();
      // Should normalize all underscores to hyphens
      expect(resolvedLocale.value).toMatch(/^zh(-Hans-CN|-Hans|-CN)?$/);
    });

    it('should be reactive to locale changes', () => {
      const mockLocale = ref('en-US');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { resolvedLocale } = useLocale();

      expect(resolvedLocale.value).toBe('en-US');

      // Change locale
      mockLocale.value = 'pt_BR';

      // Should update reactively
      expect(resolvedLocale.value).toMatch(/^pt(-BR)?$/);
    });

    it('should work with common locales', () => {
      const testCases = [
        { input: 'de-DE', expected: /^de(-DE)?$/ },
        { input: 'fr-FR', expected: /^fr(-FR)?$/ },
        { input: 'es-ES', expected: /^es(-ES)?$/ },
        { input: 'ja-JP', expected: /^ja(-JP)?$/ },
        { input: 'ko-KR', expected: /^ko(-KR)?$/ },
        { input: 'ar-SA', expected: /^ar(-SA)?$/ },
        { input: 'hi-IN', expected: /^hi(-IN)?$/ },
        { input: 'ru-RU', expected: /^ru(-RU)?$/ },
        { input: 'tr-TR', expected: /^tr(-TR)?$/ },
      ];

      testCases.forEach(({ input, expected }) => {
        const mockLocale = ref(input);
        vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
        const { resolvedLocale } = useLocale();
        expect(resolvedLocale.value).toMatch(expected);
      });
    });
  });

  describe('locale (raw)', () => {
    it('should expose raw locale value', () => {
      const mockLocale = ref('pt_BR');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { locale } = useLocale();
      // Raw locale should be unchanged
      expect(locale.value).toBe('pt_BR');
    });

    it('should be reactive', () => {
      const mockLocale = ref('en-US');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { locale } = useLocale();

      expect(locale.value).toBe('en-US');

      mockLocale.value = 'pt-BR';

      expect(locale.value).toBe('pt-BR');
    });
  });

  describe('Intl API compatibility', () => {
    it('should work with Intl.NumberFormat', () => {
      const mockLocale = ref('pt_BR');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { resolvedLocale } = useLocale();

      // Should not throw error
      expect(() => {
        new Intl.NumberFormat(resolvedLocale.value).format(1234567);
      }).not.toThrow();
    });

    it('should work with Intl.DateTimeFormat', () => {
      const mockLocale = ref('zh_CN');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { resolvedLocale } = useLocale();

      // Should not throw error
      expect(() => {
        new Intl.DateTimeFormat(resolvedLocale.value).format(new Date());
      }).not.toThrow();
    });

    it('should work with Intl.Collator', () => {
      const mockLocale = ref('en_US');
      vi.mocked(useI18n).mockReturnValue({ locale: mockLocale });
      const { resolvedLocale } = useLocale();

      // Should not throw error
      expect(() => {
        new Intl.Collator(resolvedLocale.value).compare('a', 'b');
      }).not.toThrow();
    });
  });
});
