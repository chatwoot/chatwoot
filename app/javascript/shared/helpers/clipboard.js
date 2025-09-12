/**
 * Writes a text string to the system clipboard.
 *
 * @async
 * @param {string} data text to be written to the clipboard
 * @throws {Error} unable to copy text to clipboard
 */
export const copyTextToClipboard = async data => {
  try {
    const text =
      typeof data === 'object' && data !== null
        ? JSON.stringify(data, null, 2)
        : String(data ?? '');

    await navigator.clipboard.writeText(text);
  } catch (error) {
    throw new Error(`Unable to copy text to clipboard: ${error.message}`);
  }
};
