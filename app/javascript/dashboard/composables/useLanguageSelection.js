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

  const languageOptions = computed(() => [
    {
      name: t(
        'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.LANGUAGE.USE_ACCOUNT_DEFAULT'
      ),
      iso_639_1_code: '',
    },
    ...(languages || []),
  ]);

  // When unset, keep it empty ('') so the app falls back to account locale
  const currentLanguage = computed(() => uiSettings.value?.locale ?? '');

  const updateLanguage = async languageCode => {
    try {
      if (!languageCode) {
        // Clear preference to use account default
        await updateUISettings({ locale: null });
        useAlert(
          t('PROFILE_SETTINGS.FORM.INTERFACE_SECTION.LANGUAGE.UPDATE_SUCCESS')
        );
        return;
      }

      const valid = (languages || []).some(
        l => l.iso_639_1_code === languageCode
      );
      if (!valid) {
        throw new Error(`Invalid language code: ${languageCode}`);
      }

      await updateUISettings({ locale: languageCode });
      // Apply immediately if the user explicitly chose a preference
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

  // Only push to i18n when the user has an explicit preference
  watch(
    () => uiSettings.value?.locale,
    newLocale => {
      if (newLocale) {
        locale.value = newLocale;
      }
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
