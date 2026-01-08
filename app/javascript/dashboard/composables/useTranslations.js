import { computed } from 'vue';
import { useUISettings } from './useUISettings';
import { useAccount } from './useAccount';

/**
 * Composable to extract translation state/content from contentAttributes.
 * @param {Ref|Reactive} contentAttributes - Ref or reactive object containing `translations` property
 * @returns {Object} { hasTranslations, translationContent }
 */
export function useTranslations(contentAttributes) {
  const { uiSettings } = useUISettings();
  const { currentAccount } = useAccount();

  const hasTranslations = computed(() => {
    if (!contentAttributes.value) return false;
    const { translations = {} } = contentAttributes.value;
    return Object.keys(translations || {}).length > 0;
  });

  const translationContent = computed(() => {
    if (!hasTranslations.value) return null;
    const translations = contentAttributes.value.translations;
    const agentLocale = uiSettings.value?.locale;
    const accountLocale = currentAccount.value?.locale;

    // Try agent locale first, then account locale, then fallback to first available
    if (agentLocale && translations[agentLocale]) {
      return translations[agentLocale];
    }
    if (accountLocale && translations[accountLocale]) {
      return translations[accountLocale];
    }
    return translations[Object.keys(translations)[0]];
  });

  return { hasTranslations, translationContent };
}
