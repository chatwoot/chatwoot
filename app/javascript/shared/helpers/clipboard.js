/**
 * Writes a text string to the system clipboard.
 *
 * @async
 * @param {string} text text to be written to the clipboard
 * @throws {Error} unable to copy text to clipboard
 */
import { emitter } from 'shared/helpers/mitt';

export const copyTextToClipboard = async text => {
  try {
    await navigator.clipboard.writeText(text);
  } catch (error) {
    // TODO: show localized error message
    emitter.emit(
      'newToastMessage',
      'Network Error: Unable to copy text to clipboard.'
    );
    throw new Error(`Unable to copy text to clipboard: ${error.message}`);
  }
};
