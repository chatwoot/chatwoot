/**
 * Composable for branding-related utilities
 * Provides methods to customize text with installation-specific branding
 */
import { useMapGetter } from 'dashboard/composables/store.js';
import { DEFAULT_BRAND_NAMES } from 'shared/constants/branding.js';

export function useBranding() {
  const globalConfig = useMapGetter('globalConfig/get');
  /**
   * Replaces default brand names in text with the installation name from global config
   * @param {string} text - The text to process
   * @returns {string} - Text with brand names replaced by installation name
   */
  const replaceInstallationName = text => {
    if (!text) return text;

    const installationName = globalConfig.value?.installationName;
    if (!installationName) return text;

    return DEFAULT_BRAND_NAMES.reduce((result, brand) => {
      const brandRegex = new RegExp(brand, 'g');
      return result.replace(brandRegex, installationName);
    }, text);
  };

  return {
    replaceInstallationName,
  };
}
