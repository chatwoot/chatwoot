import { computed } from 'vue';

/**
 * Composable to extract translation state/content from contentAttributes.
 * @param {Ref|Reactive} contentAttributes - Ref or reactive object containing `translations` property
 * @returns {Object} { hasTranslations, translationContent }
 */
export function useTranslations(contentAttributes) {
  const hasTranslations = computed(() => {
    if (!contentAttributes.value) return false;
    const { translations = {} } = contentAttributes.value;
    return Object.keys(translations || {}).length > 0;
  });

  const translationContent = computed(() => {
    if (!hasTranslations.value) return null;
    const translations = contentAttributes.value.translations;
    return translations[Object.keys(translations)[0]];
  });

  return { hasTranslations, translationContent };
}
