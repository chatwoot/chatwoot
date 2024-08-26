/**
 * Replaces occurrences of "Chatwoot" with the provided installation name in a given string.
 *
 * @param {string} str - The original string that may contain "Chatwoot".
 * @param {string} installationName - The name to replace "Chatwoot" with.
 * @returns {string} The modified string with "Chatwoot" replaced by the installation name,
 *                   or the original string if either input is falsy.
 */
export const useInstallationName = (str, installationName) => {
  if (str && installationName) {
    return str.replace(/Chatwoot/g, installationName);
  }
  return str;
};
