/**
 * Provides a fallback message in case incomplete checks don't provide one
 * This mechanism allows the string to be localized.
 * @return {String}
 */
function incompleteFallbackMessage() {
  return typeof axe._audit.data.incompleteFallbackMessage === 'function'
    ? axe._audit.data.incompleteFallbackMessage()
    : axe._audit.data.incompleteFallbackMessage;
}

export default incompleteFallbackMessage;
