import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

/**
 * Composable for locale resolution and validation
 * Provides a normalized, validated locale that works with Intl APIs
 */
export function useLocale() {
  const { locale } = useI18n();

  /**
   * Resolves and validates the current locale for use with Intl APIs
   *
   * Handles multiple fallback scenarios:
   * 1. Normalizes underscore-based tags (pt_BR → pt-BR, zh_CN → zh-CN)
   * 2. Falls back to base language if specific locale unsupported (pt-BR → pt)
   * 3. Falls back to English if base language unsupported (xx-YY → en)
   *
   * @returns {string} Valid BCP 47 locale tag for Intl APIs
   *
   * @example
   * const { resolvedLocale } = useLocale();
   * new Intl.NumberFormat(resolvedLocale.value).format(1234);
   * new Intl.DateTimeFormat(resolvedLocale.value).format(new Date());
   */
  const resolvedLocale = computed(() => {
    // Handle null/undefined locale
    if (!locale.value) return 'en';

    // Normalize underscore to hyphen (pt_BR → pt-BR, zh_CN → zh-CN)
    const normalized = locale.value.replace(/_/g, '-');

    // Check if the specific locale is supported (e.g., pt-BR, zh-CN)
    const supportedLocales = Intl.NumberFormat.supportedLocalesOf([normalized]);
    if (supportedLocales.length > 0) {
      return normalized;
    }

    // If specific locale not supported, try base language (pt-BR → pt, zh-CN → zh)
    const baseLocale = normalized.split('-')[0];
    const baseSupportedLocales = Intl.NumberFormat.supportedLocalesOf([
      baseLocale,
    ]);
    if (baseSupportedLocales.length > 0) {
      return baseLocale;
    }

    // If base language also not supported, fall back to English
    return 'en';
  });

  return {
    resolvedLocale,
    // Also expose the raw locale for cases where you need it
    locale,
  };
}
