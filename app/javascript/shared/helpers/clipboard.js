/**
 * Writes a text string to the system clipboard.
 *
 * @async
 * @param {string} text text to be written to the clipboard
 * @throws {Error} unable to copy text to clipboard
 */
export const copyTextToClipboard = async text => {
  try {
    await navigator.clipboard.writeText(text);
  } catch (error) {
    throw new Error(`Unable to copy text to clipboard: ${error.message}`);
  }
};
