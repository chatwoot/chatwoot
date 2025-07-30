/**
 * URL Helper utilities for handling different file storage providers
 * Provides methods to convert storage provider URLs to direct accessible URLs
 */

/**
 * Decodes common escaped characters in URLs
 * @param {string} url - The URL to decode
 * @returns {string} - The decoded URL
 */
export const decodeUrl = url => {
  if (!url) return null;
  return url.replace(/\\u0026/g, '&');
};

/**
 * Converts Google Drive URLs to direct image URLs
 * Supports multiple Google Drive URL formats:
 * - https://drive.google.com/uc?id=FILE_ID&export=download
 * - https://drive.google.com/file/d/FILE_ID/view
 * - https://drive.google.com/open?id=FILE_ID
 *
 * @param {string} url - The Google Drive URL
 * @returns {string|null} - Direct image URL or null if no file ID found
 */
export const getGoogleDriveImageUrl = url => {
  if (!url || !url.includes('drive.google.com')) {
    return null;
  }

  let fileId = null;

  // Format: https://drive.google.com/uc?id=FILE_ID&export=download
  if (url.includes('uc?id=')) {
    fileId = url.match(/uc\?id=([a-zA-Z0-9_-]+)/)?.[1];
  }
  // Format: https://drive.google.com/file/d/FILE_ID/view
  else if (url.includes('/file/d/')) {
    fileId = url.match(/\/file\/d\/([a-zA-Z0-9_-]+)/)?.[1];
  }
  // Format: https://drive.google.com/open?id=FILE_ID
  else if (url.includes('open?id=')) {
    fileId = url.match(/open\?id=([a-zA-Z0-9_-]+)/)?.[1];
  }

  if (fileId) {
    // Convert to direct image URL format with reasonable dimensions
    return `https://drive.google.com/thumbnail?id=${fileId}&sz=w400-h300-c`;
  }

  return null;
};

/**
 * Main URL processor that handles different storage providers
 * Currently supports Google Drive, can be extended for other providers
 *
 * @param {string} originalUrl - The original URL to process
 * @returns {string|null} - Processed URL or null if invalid
 */
export const processStorageUrl = originalUrl => {
  if (!originalUrl) return null;

  // First decode any escaped characters
  let url = decodeUrl(originalUrl);

  // Handle Google Drive URLs
  if (url.includes('drive.google.com')) {
    const processedUrl = getGoogleDriveImageUrl(url);
    return processedUrl || url; // Return processed URL or fallback to original
  }

  // Future: Add other storage providers here
  // if (url.includes('dropbox.com')) {
  //   return getDropboxImageUrl(url);
  // }
  // if (url.includes('onedrive.live.com')) {
  //   return getOneDriveImageUrl(url);
  // }

  return url;
};

/**
 * Extracts media URL from item object supporting multiple field name formats
 * @param {Object} item - Item object that may contain media URL
 * @returns {string|null} - Processed media URL or null
 */
export const getMediaUrl = item => {
  if (!item) return null;

  // Support multiple field name formats: mediaUrl (camelCase), media_url (snake_case), image_url
  const rawUrl = item.mediaUrl || item.media_url || item.image_url;

  return processStorageUrl(rawUrl);
};
