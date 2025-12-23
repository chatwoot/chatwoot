/**
 * Central Branding Module for SynkiCRM
 * 
 * This module centralizes all branding constants and provides
 * a single source of truth for brand information across the application.
 * 
 * Values can be overridden via window.globalConfig (from backend)
 * or environment variables.
 */

// Default brand configuration
const DEFAULT_BRAND = {
  brandName: 'SynkiCRM',
  productName: 'SynkiCRM',
  website: 'https://synkicrm.com.br/',
  supportEmail: 'suporte@synkicrm.com.br',
  legalName: 'SynkiCRM',
  domain: 'synkicrm.com.br',
};

/**
 * Get brand configuration
 * Priority: window.globalConfig > DEFAULT_BRAND
 */
export function getBrandConfig() {
  // Get from globalConfig if available (set by backend)
  const globalConfig = window.globalConfig || {};
  
  return {
    brandName: globalConfig.BRAND_NAME || globalConfig.INSTALLATION_NAME || DEFAULT_BRAND.brandName,
    productName: globalConfig.BRAND_NAME || globalConfig.INSTALLATION_NAME || DEFAULT_BRAND.productName,
    website: globalConfig.BRAND_URL || globalConfig.WIDGET_BRAND_URL || DEFAULT_BRAND.website,
    supportEmail: globalConfig.BRAND_SUPPORT_EMAIL || DEFAULT_BRAND.supportEmail,
    legalName: globalConfig.BRAND_LEGAL_NAME || DEFAULT_BRAND.legalName,
    domain: globalConfig.BRAND_DOMAIN || DEFAULT_BRAND.domain,
    // Keep existing configs for compatibility
    installationName: globalConfig.INSTALLATION_NAME || DEFAULT_BRAND.brandName,
    logo: globalConfig.LOGO || '/brand-assets/logo.svg',
    logoDark: globalConfig.LOGO_DARK || '/brand-assets/logo_dark.svg',
    logoThumbnail: globalConfig.LOGO_THUMBNAIL || '/brand-assets/logo_thumbnail.svg',
  };
}

// Export singleton instance
const BRAND = getBrandConfig();

// Export individual constants for convenience
export const BRAND_NAME = BRAND.brandName;
export const PRODUCT_NAME = BRAND.productName;
export const BRAND_WEBSITE = BRAND.website;
export const BRAND_SUPPORT_EMAIL = BRAND.supportEmail;
export const BRAND_LEGAL_NAME = BRAND.legalName;
export const BRAND_DOMAIN = BRAND.domain;

// Export default object
export default BRAND;

