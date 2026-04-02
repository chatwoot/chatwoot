/**
 * Composable for branding-related utilities
 * Provides methods to customize text with installation-specific branding
 */
import { useMapGetter } from 'dashboard/composables/store.js';

export function useBranding() {
  const globalConfig = useMapGetter('globalConfig/get');
  /**
   * Replaces "Converso" in text with the installation name from global config
   * @param {string} text - The text to process
   * @returns {string} - Text with "Converso" replaced by installation name
   */
  const replaceInstallationName = text => {
    if (!text) return text;

    const installationName = globalConfig.value?.installationName;
    if (!installationName) return text;

    return text.replace(/Converso/g, installationName);
  };

  return {
    replaceInstallationName,
  };
}
