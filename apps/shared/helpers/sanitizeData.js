export const labelSanitizePattern = /[^a-zA-Z0-9_-]/g;
export const spacesPattern = /\s+/g;

/**
 * Sanitizes a label by removing unwanted characters and replacing spaces with hyphens.
 *
 * @param {string | undefined | null} label - The label to sanitize.
 * @returns {string} The sanitized label.
 *
 * @example
 * const label = 'My Label 123';
 * const sanitizedLabel = sanitizeLabel(label); // 'my-label-123'
 */
export const sanitizeLabel = (label = '') => {
  if (!label) return '';

  return label
    .trim()
    .toLowerCase()
    .replace(spacesPattern, '-')
    .replace(labelSanitizePattern, '');
};
