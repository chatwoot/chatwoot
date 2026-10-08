/**
 * vue-i18n postTranslation handler that swaps "Chatwoot" in every translated
 * string for the installation name. Case-sensitive so lowercase identifiers
 * such as chatwoot.com URLs and window.chatwootSettings stay intact.
 * @param {string} text - The translated message
 * @returns {string} - Message with "Chatwoot" replaced by the installation name
 */
export const replaceInstallationNameInTranslation = text => {
  if (typeof text !== 'string') return text;

  return text.replaceAll('Chatwoot', window.globalConfig.INSTALLATION_NAME);
};
