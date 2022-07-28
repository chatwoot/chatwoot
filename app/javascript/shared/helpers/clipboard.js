/**
 * Writes a text string to the system clipboard.
 *
 * @param {string} text text to be written to the clipboard
 * @param {function} successCallback callback on successful copy
 * @param {function} errorCallback callback on error copy
 */
export const copyTextToClipboard = (
  text,
  successCallback = () => {},
  errorCallback = () => {}
) => {
  navigator.clipboard
    .writeText(text)
    .then(successCallback)
    .catch(errorCallback);
};
