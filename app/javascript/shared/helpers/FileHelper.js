export const formatBytes = (bytes, decimals = 2) => {
  if (bytes === 0) return '0 Bytes';

  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];

  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return parseFloat((bytes / k ** i).toFixed(dm)) + ' ' + sizes[i];
};

export const fileSizeInMegaBytes = (bytes) => {
  return bytes / (1024 * 1024);
};

export const checkFileSizeLimit = (file, maximumUploadLimit) => {
  const fileSize = file?.file?.size || file?.size;
  const fileSizeInMB = fileSizeInMegaBytes(fileSize);
  return fileSizeInMB <= maximumUploadLimit;
};

/**
 * Extracts filename from URL, handling both Rails Active Storage URLs and S3 direct URLs
 * @param {string} url - The file URL (Rails redirect URL or S3 signed URL)
 * @returns {string} The extracted filename
 */
export const extractFilenameFromUrl = (url) => {
  if (!url) return '';

  try {
    // Check if URL has query parameters (S3 direct URL)
    if (url.includes('?')) {
      // Try to extract filename from response-content-disposition parameter
      const urlParams = new URLSearchParams(url.split('?')[1]);
      const disposition = urlParams.get('response-content-disposition');

      if (disposition) {
        // Extract filename from: inline; filename="IMG_4870.jpeg"
        const match = disposition.match(/filename[*]?=['"]?([^'";\s]+)['"]?/i);
        if (match && match[1]) {
          return match[1];
        }
      }

      // Fallback: strip query params and get last path segment
      const pathWithoutQuery = url.split('?')[0];
      return pathWithoutQuery.split('/').pop() || '';
    }

    // Old format (Rails Active Storage URL): extract filename from path
    return url.split('/').pop() || '';
  } catch (error) {
    // Fallback to simple extraction if parsing fails
    const pathWithoutQuery = url.split('?')[0];
    return pathWithoutQuery.split('/').pop() || '';
  }
};
