import { emitter } from 'shared/helpers/mitt';

/**
 * Writes a text string to the system clipboard.
 * @deprecated This will be removed in the future. Use `https://vueuse.org/core/useClipboard/` instead.
 *
 * @async
 * @param {string} text text to be written to the clipboard
 * @throws {Error} unable to copy text to clipboard
 */
export const copyTextToClipboard = async text => {
  try {
    const permission = await navigator.permissions.query({
      name: 'clipboard-write',
    });
    if (permission.state === 'granted' || permission.state === 'prompt') {
      await navigator.clipboard.writeText(text);
    } else {
      throw new Error('Clipboard write permission denied');
    }
  } catch (error) {
    const textArea = document.createElement('textarea');
    textArea.value = text;
    textArea.style.position = 'fixed';
    textArea.style.opacity = '0';
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();

    try {
      const successful = document.execCommand('copy');
      if (successful) {
        emitter.emit(
          'newToastMessage',
          'Text successfully copied to clipboard.'
        );
      } else {
        throw new Error('Fallback method failed');
      }
    } catch (execCommandError) {
      emitter.emit(
        'newToastMessage',
        'Network Error: Unable to copy text to clipboard.'
      );
      throw new Error(
        `Unable to copy text to clipboard: ${execCommandError.message}`
      );
    } finally {
      document.body.removeChild(textArea);
    }
  }
};
