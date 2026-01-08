export const escapeHtml = (unsafe = '') => {
  return unsafe
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
};

export const afterSanitizeAttributes = currentNode => {
  if ('target' in currentNode) {
    currentNode.setAttribute('target', '_blank');
  }
};

export const domPurifyConfig = {
  hooks: {
    afterSanitizeAttributes,
  },
};

/**
 * Sanitize text content for safe rendering
 * For plain text content, this ensures the value is a string and handles null/undefined
 * @param {string|null|undefined} text - The text to sanitize
 * @returns {string} Sanitized text (empty string if input is null/undefined)
 */
export const sanitizeTextForRender = (text) => {
  if (text == null) {
    return '';
  }
  return String(text);
};
