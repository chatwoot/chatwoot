/**
 * @file useFontSize.js
 * @description A composable for managing font size settings throughout the application.
 * This handles font size selection, application to the DOM, and persistence in user settings.
 */

import { computed, watch } from 'vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

/**
 * Font size options with their pixel values
 * @type {Object}
 */
const FONT_SIZE_OPTIONS = {
  SMALLER: '14px',
  SMALL: '15px',
  DEFAULT: '16px',
  LARGE: '18px',
  LARGER: '20px',
  EXTRA_LARGE: '22px',
};

/**
 * Array of font size option keys
 * @type {Array<string>}
 */
const FONT_SIZE_NAMES = Object.keys(FONT_SIZE_OPTIONS);

/**
 * Get font size label translation key
 *
 * @param {string} name - Font size name
 * @returns {string} Translation key
 */
const getFontSizeLabelKey = name =>
  `PROFILE_SETTINGS.FORM.INTERFACE_SECTION.FONT_SIZE.OPTIONS.${name}`;

/**
 * Create font size option object
 *
 * @param {Function} t - Translation function
 * @param {string} name - Font size name
 * @returns {Object} Font size option with value and label
 */
const createFontSizeOption = (t, name) => ({
  value: FONT_SIZE_OPTIONS[name],
  label: t(getFontSizeLabelKey(name)),
});

/**
 * Apply font size value to document root
 *
 * @param {string} pixelValue - Font size value in pixels
 */
const applyFontSizeToDOM = pixelValue => {
  document.documentElement.style.setProperty(
    'font-size',
    pixelValue ?? FONT_SIZE_OPTIONS.DEFAULT
  );
};

/**
 * Font size management composable
 *
 * @returns {Object} Font size utilities and state
 * @property {Array} fontSizeOptions - Array of font size options for select components
 * @property {import('vue').ComputedRef<string>} currentFontSize - Current font size from UI settings
 * @property {Function} applyFontSize - Function to apply font size to document
 * @property {Function} updateFontSize - Function to update font size in settings with alert feedback
 */
export const useFontSize = () => {
  const { uiSettings, updateUISettings } = useUISettings();
  const { t } = useI18n();

  /**
   * Font size options for select dropdown
   * @type {Array<{value: string, label: string}>}
   */
  const fontSizeOptions = FONT_SIZE_NAMES.map(name =>
    createFontSizeOption(t, name)
  );

  /**
   * Current font size from UI settings
   * @type {import('vue').ComputedRef<string>}
   */
  const currentFontSize = computed(
    () => uiSettings.value.font_size || FONT_SIZE_OPTIONS.DEFAULT
  );

  /**
   * Apply font size to document root
   * @param {string} pixelValue - Font size in pixels (e.g., '16px')
   * @returns {void}
   */
  const applyFontSize = pixelValue => {
    // Use requestAnimationFrame for better performance
    requestAnimationFrame(() => applyFontSizeToDOM(pixelValue));
  };

  /**
   * Update font size in settings and apply to document
   * Shows success/error alerts
   * @param {string} pixelValue - Font size in pixels (e.g., '16px')
   * @returns {Promise<void>}
   */
  const updateFontSize = async pixelValue => {
    try {
      await updateUISettings({ font_size: pixelValue });
      applyFontSize(pixelValue);
      useAlert(
        t('PROFILE_SETTINGS.FORM.INTERFACE_SECTION.FONT_SIZE.UPDATE_SUCCESS')
      );
    } catch (error) {
      useAlert(
        t('PROFILE_SETTINGS.FORM.INTERFACE_SECTION.FONT_SIZE.UPDATE_ERROR')
      );
    }
  };

  // Watch for changes to the font size in UI settings
  watch(
    () => uiSettings.value.font_size,
    newSize => {
      applyFontSize(newSize);
    },
    { immediate: true }
  );

  return {
    fontSizeOptions,
    currentFontSize,
    applyFontSize,
    updateFontSize,
  };
};

export default useFontSize;
