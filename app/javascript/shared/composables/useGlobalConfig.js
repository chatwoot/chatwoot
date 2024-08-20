/*
 * Composable for  using the installation name in the application.
 * @param {string} str - The string to be processed.
 * @param {string} installationName - The installation name.
 * @returns {string} The processed string with the installation name.
 */

export const useGlobalConfig = () => {
  const useInstallationName = (str, installationName) => {
    if (str && installationName) {
      return str.replace(/Chatwoot/g, installationName);
    }
    return str;
  };
  return {
    useInstallationName,
  };
};
