/**
 * @file useLanguageSelection.js
 * @description A composable for managing language selection throughout the application.
 * This handles language selection, application to the i18n instance, and persistence in user settings.
 */

import { computed, watch } from 'vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import languages from 'dashboard/components/widgets/conversation/advancedFilterItems/languages'; // Import the languages array

/**
 * Language selection management composable
 *
 * @returns {Object} Language utilities and state
 * @property {Array} languageOptions - Array of language options for select components
 * @property {import('vue').ComputedRef<string>} currentLanguage - Current language from UI settings
 * @property {Function} updateLanguage - Function to update language in settings with alert feedback
 */
export const useLanguageSelection = () => {
  const { uiSettings, updateUISettings } = useUISettings();
  const { t, locale } = useI18n();

  /**
   * Language options for select dropdown
   * Directly use the imported `languages` array
   */
  const languageOptions = languages;

  /**
   * Current language from UI settings
   * @type {import('vue').ComputedRef<string>}
   */
  const currentLanguage = computed(() => uiSettings.value.locale || 'en');

  /**
   * Update language in settings and apply to i18n instance
   * Shows success/error alerts
   * @param {string} languageCode - Language code (e.g., 'en', 'es')
   * @returns {Promise<void>}
   */
  const updateLanguage = async languageCode => {
    try {
      // Validate the language code
      const validLanguage = languageOptions.some(
        option => option.id === languageCode
      );
      if (!validLanguage) {
        throw new Error(`Invalid language code: ${languageCode}`);
      }

      // Update the language in the UI settings
      await updateUISettings({ locale: languageCode });

      // Apply the language to the i18n instance
      locale.value = languageCode;
      // Show a success alert
      useAlert(t('PROFILE_SETTINGS.LANGUAGE_UPDATE_SUCCESS'));
    } catch (error) {
      // Show an error alert
      useAlert(t('PROFILE_SETTINGS.LANGUAGE_UPDATE_FAILED'));
    }
  };

  // Watch for changes to the language in UI settings and apply them
  watch(
    () => uiSettings.value.locale,
    newLanguage => {
      locale.value = newLanguage || 'en'; // Fallback to 'en' if undefined
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
