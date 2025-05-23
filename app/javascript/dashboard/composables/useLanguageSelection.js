/**
 * @file useLanguageSelection.js
 * @description A composable for managing language selection throughout the application.
 * This handles language selection, application to the i18n instance, and persistence in user settings.
 */

import { computed, watch } from 'vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

/**
 * Language selection management composable
 *
 * @returns {Object} Language utilities and state
 * @property {Array} languageOptions - Array of language options for select components
 * @property {import('vue').ComputedRef<string>} currentLanguage - Current language from UI settings
 * @property {Function} updateLanguage - Function to update language in settings with alert feedback
 */
export const useLanguageSelection = (
  languages = window.chatwootConfig?.enabledLanguages || []
) => {
  const { uiSettings, updateUISettings } = useUISettings();
  const { t, locale } = useI18n();

  const languageOptions = languages;

  const currentLanguage = computed(() => uiSettings.value.locale || 'en');

  const updateLanguage = async languageCode => {
    try {
      const validLanguage = languageOptions.some(
        option => option.iso_639_1_code === languageCode
      );
      if (!validLanguage) {
        throw new Error(`Invalid language code: ${languageCode}`);
      }

      await updateUISettings({ locale: languageCode });
      locale.value = languageCode;
      useAlert(
        t('PROFILE_SETTINGS.FORM.INTERFACE_SECTION.LANGUAGE.UPDATE_SUCCESS')
      );
    } catch (error) {
      useAlert(
        t('PROFILE_SETTINGS.FORM.INTERFACE_SECTION.LANGUAGE.UPDATE_ERROR')
      );
      throw error;
    }
  };

  watch(
    () => uiSettings.value.locale,
    newLanguage => {
      locale.value = newLanguage || 'en';
    },
    { immediate: true }
  );

  return {
    languageOptions,
    currentLanguage,
    updateLanguage,
  };
};

export default useLanguageSelection;
