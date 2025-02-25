/**
 * @file useFontSize.js
 * @description A composable for managing font size settings throughout the application.
 * This handles font size selection, application to the DOM, and persistence in user settings.
 */

import { computed, ref, watch } from 'vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

/**
 * Mapping of semantic font size names to their pixel values
 * @type {Object}
 */
const FONT_SIZE_MAP = {
  smaller: '14px',
  small: '15px',
  default: null, // null means use browser default
  large: '18px',
  larger: '20px',
  'extra-large': '22px',
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
   * Cache to avoid unnecessary DOM operations
   * @type {import('vue').Ref<string|null>}
   */
  const lastAppliedFontSize = ref(null);

  /**
   * Font size options for select dropdown
   * @type {Array<{value: string, label: string}>}
   */
  const fontSizeOptions = [
    {
      value: 'smaller',
      label: 'Smaller',
    },
    {
      value: 'small',
      label: 'Small',
    },
    {
      value: 'default',
      label: 'Default',
    },
    {
      value: 'large',
      label: 'Large',
    },
    {
      value: 'larger',
      label: 'Larger',
    },
    {
      value: 'extra-large',
      label: 'Extra Large',
    },
  ];

  /**
   * Current font size from UI settings
   * @type {import('vue').ComputedRef<string>}
   */
  const currentFontSize = computed(
    () => uiSettings.value.font_size || 'default'
  );

  /**
   * Convert semantic font size to pixel value
   *
   * @param {string} semanticSize - Semantic font size name
   * @returns {string|null} - Pixel value or null for default
   */
  const getFontSizePixels = semanticSize => {
    return FONT_SIZE_MAP[semanticSize] || null;
  };

  /**
   * Apply font size to document root
   *
   * @param {string} semanticSize - Semantic font size to apply ('smaller', 'small', 'default', etc.)
   * @returns {void}
   */
  const applyFontSize = semanticSize => {
    // For performance, only update DOM when needed
    if (lastAppliedFontSize.value === semanticSize) return;

    // Cache the last applied size
    lastAppliedFontSize.value = semanticSize;

    // Get pixel value for the semantic size
    const pixelValue = getFontSizePixels(semanticSize);

    // Use requestAnimationFrame for better performance
    requestAnimationFrame(() => {
      if (!pixelValue) {
        document.documentElement.style.removeProperty('font-size');
      } else {
        document.documentElement.style.setProperty('font-size', pixelValue);
      }
    });
  };

  /**
   * Update font size in settings and apply to document
   * Shows success/error alerts
   *
   * @param {string} value - Semantic font size value to set
   * @returns {Promise<void>}
   */
  const updateFontSize = async value => {
    try {
      await updateUISettings({ font_size: value });
      applyFontSize(value);
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
