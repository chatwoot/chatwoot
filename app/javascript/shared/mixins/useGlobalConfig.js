/**
 * Composable for replacing 'Chatwoot' with a custom installation name in a string.
 * @param {string} installationName - The custom installation name to replace 'Chatwoot' with.
 * @returns {Function} A function that replaces 'Chatwoot' with the custom installation name in a given string.
 */
export function useInstallationName(installationName) {
  return str => {
    if (str && installationName) {
      return str.replace(/Chatwoot/g, installationName);
    }
    return str;
  };
}
