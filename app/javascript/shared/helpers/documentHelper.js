/**
 * Document Helper - utilities for document display and formatting
 */

// Constants for document processing
const PDF_PREFIX = 'PDF:';
const TIMESTAMP_PATTERN = /_\d{14}(?=\.pdf$)/; // Format: _YYYYMMDDHHMMSS before .pdf extension

/**
 * Checks if a document is a PDF based on its external link
 * @param {string} externalLink - The external link string
 * @returns {boolean} True if the document is a PDF
 */
export const isPdfDocument = externalLink => {
  if (!externalLink) return false;
  return externalLink.startsWith(PDF_PREFIX);
};

/**
 * Formats the display link for documents
 * For PDF documents: removes 'PDF:' prefix and timestamp suffix
 * For regular URLs: returns as-is
 *
 * @param {string} externalLink - The external link string
 * @returns {string} Formatted display link
 */
export const formatDocumentLink = externalLink => {
  if (!externalLink) return '';

  if (isPdfDocument(externalLink)) {
    // Remove 'PDF:' prefix
    const fullName = externalLink.substring(PDF_PREFIX.length);
    // Remove timestamp suffix if present
    return fullName.replace(TIMESTAMP_PATTERN, '');
  }

  return externalLink;
};
