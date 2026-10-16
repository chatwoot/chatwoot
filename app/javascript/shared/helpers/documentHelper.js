/**
 * Document Helper - utilities for document display and formatting
 */

// Constants for document processing
const PDF_PREFIX = 'PDF:';
const TIMESTAMP_PATTERN = /_\d{14}(?=\.pdf$)/; // Format: _YYYYMMDDHHMMSS before .pdf extension
const URL_DISPLAY_PREFIX_PATTERN = /^https?:\/\/(www\.)?/i;

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
 * Checks if a link is safe to bind to an href attribute (http/https only).
 * Guards against schemes like `javascript:` that would execute on click.
 * @param {string} externalLink - The external link string
 * @returns {boolean} True if the link uses http or https
 */
export const isSafeHttpLink = externalLink => {
  if (!externalLink) return false;
  try {
    const { protocol } = new URL(externalLink);
    return protocol === 'http:' || protocol === 'https:';
  } catch (e) {
    return false;
  }
};

/**
 * Formats the display link for documents
 * For PDF documents: removes 'PDF:' prefix and timestamp suffix
 * For regular URLs: strips http(s):// and www. for a denser list view
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

  return externalLink.replace(URL_DISPLAY_PREFIX_PATTERN, '');
};

/**
 * Returns the path of a URL for compact display in document lists. This avoids
 * repeating the domain while preserving enough context to distinguish pages.
 * Falls back to the bare hostname for root URLs and formatDocumentLink for
 * malformed URLs and PDFs.
 */
export const getDocumentDisplayPath = externalLink => {
  if (!externalLink) return '';
  if (isPdfDocument(externalLink)) return formatDocumentLink(externalLink);
  try {
    const { pathname, hostname } = new URL(externalLink);
    const path = pathname.replace(/^\/+/, '');
    if (!path) return hostname.replace(/^www\./i, '');
    try {
      return decodeURIComponent(path);
    } catch (e) {
      return path;
    }
  } catch (e) {
    return formatDocumentLink(externalLink);
  }
};
