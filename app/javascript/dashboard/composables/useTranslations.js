import { computed, unref } from 'vue';
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
 * @param {Ref|boolean} contactSide - Whether the message reads in the contact language (contact or bot authored)
 * @returns {Object} { hasTranslations, translationContent }
 */
export function useTranslations(contentAttributes, contactSide) {
  const { uiSettings } = useUISettings();
  const { currentAccount } = useAccount();
  const autoTranslate = useMapGetter('getAutoTranslate');

  const translationContent = computed(() => {
    const { translations } = contentAttributes.value ?? {};
    if (!translations || !Object.keys(translations).length) return null;
    // Contact-side messages read in the agent language; a reply or template shows its author's own text.
    if (autoTranslate.value.enabled) {
      const own = translations[autoTranslate.value.locale];
      if (unref(contactSide)) return own ?? null;
      return own ?? Object.values(translations)[0];
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
