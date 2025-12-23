/**
 * Composable for branding-related utilities
 * Provides methods to customize text with installation-specific branding
 */
import { useMapGetter } from 'dashboard/composables/store.js';
import BRAND from 'shared/brand';

export function useBranding() {
  const globalConfig = useMapGetter('globalConfig/get');
  
  /**
   * Replaces "Chatwoot" in text with the brand name
   * @param {string} text - The text to process
   * @returns {string} - Text with "Chatwoot" replaced by brand name
   */
  const replaceInstallationName = text => {
    if (!text) return text;

    // Use brand module first, fallback to globalConfig
    const brandName = BRAND.brandName || globalConfig.value?.installationName || 'SynkiCRM';
    
    return text.replace(/Chatwoot/gi, brandName);
  };

  /**
   * Get brand name
   */
  const getBrandName = () => {
    return BRAND.brandName || globalConfig.value?.installationName || 'SynkiCRM';
  };

  return {
    replaceInstallationName,
    getBrandName,
  };
}
