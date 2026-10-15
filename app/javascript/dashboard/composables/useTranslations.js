import { computed } from 'vue';
import { useUISettings } from './useUISettings';
import { useAccount } from './useAccount';
import { useMapGetter } from './store';

/**
 * Select translation based on locale priority.
 * @param {Object} translations - Translations object with locale keys
 * @param {string} agentLocale - Agent's preferred locale
 * @param {string} accountLocale - Account's default locale
 * @returns {string|null} Selected translation or null
 */
export function selectTranslation(translations, agentLocale, accountLocale) {
  if (!translations || Object.keys(translations).length === 0) return null;

  if (agentLocale && translations[agentLocale]) {
    return translations[agentLocale];
  }
  if (accountLocale && translations[accountLocale]) {
    return translations[accountLocale];
  }
  return translations[Object.keys(translations)[0]];
}

/**
 * Composable to extract translation state/content from contentAttributes.
 * @param {Ref|Reactive} contentAttributes - Ref or reactive object containing `translations` property
 * @returns {Object} { hasTranslations, translationContent }
 */
export function useTranslations(contentAttributes) {
  const { uiSettings } = useUISettings();
  const { currentAccount } = useAccount();
  const autoTranslate = useMapGetter('getAutoTranslate');

  const translationContent = computed(() => {
    const { translations } = contentAttributes.value ?? {};
    if (!translations || !Object.keys(translations).length) return null;
    // With auto translate on, each agent reads the translation into their own language, or the original until it is there.
    if (autoTranslate.value.enabled) {
      return translations[autoTranslate.value.locale] ?? null;
    }
    return selectTranslation(
      translations,
      uiSettings.value?.locale,
      currentAccount.value?.locale
    );
  });

  const hasTranslations = computed(() => !!translationContent.value);

  return { hasTranslations, translationContent };
}
