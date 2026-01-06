import { getAllowedFileTypesByChannel } from '@chatwoot/utils';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

export const DEFAULT_MAXIMUM_FILE_UPLOAD_SIZE = 40;

export const formatBytes = (bytes, decimals = 2) => {
  if (bytes === 0) return '0 Bytes';

  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];

  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return parseFloat((bytes / k ** i).toFixed(dm)) + ' ' + sizes[i];
};

export const fileSizeInMegaBytes = bytes => {
  return bytes / (1024 * 1024);
};

export const checkFileSizeLimit = (file, maximumUploadLimit) => {
  const fileSize = file?.file?.size || file?.size;
  const fileSizeInMB = fileSizeInMegaBytes(fileSize);
  return fileSizeInMB <= maximumUploadLimit;
};

export const resolveMaximumFileUploadSize = value => {
  const parsedValue = Number(value);

  if (!Number.isFinite(parsedValue) || parsedValue <= 0) {
    return DEFAULT_MAXIMUM_FILE_UPLOAD_SIZE;
  }

  return parsedValue;
};

/**
 * Validates if a file type is allowed for a specific channel
 * @param {File} file - The file to validate
 * @param {Object} options - Validation options
 * @param {string} options.channelType - The channel type
 * @param {string} options.medium - The channel medium
 * @param {string} options.conversationType - The conversation type (for Instagram DM detection)
 * @param {boolean} options.isInstagramChannel - Whether it's an Instagram channel
 * @returns {boolean} - True if file type is allowed, false otherwise
 */
export const isFileTypeAllowedForChannel = (file, options = {}) => {
  if (!file || file.size === 0) return false;

  const {
    channelType: originalChannelType,
    medium,
    conversationType,
    isInstagramChannel,
  } = options;

  // Handle Instagram special case
  let channelType = originalChannelType;
  const isInstagramDM = conversationType === 'instagram_direct_message';
  if (isInstagramChannel || isInstagramDM) {
    channelType = INBOX_TYPES.INSTAGRAM;
  }

  // Get allowed file types for the channel
  const allowedFileTypes = getAllowedFileTypesByChannel({
    channelType,
    medium,
  });

  // Convert to array and validate
  const allowedTypesArray = allowedFileTypes.split(',').map(t => t.trim());
  const fileExtension = `.${file.name.split('.').pop()}`;

  return allowedTypesArray.some(allowedType => {
    // Check for exact file extension match
    if (allowedType === fileExtension) return true;

    // Check for wildcard MIME type (e.g., image/*)
    if (allowedType.endsWith('/*')) {
      const prefix = allowedType.slice(0, -2); // Remove '/*'
      return file.type.startsWith(prefix + '/');
    }

    // Check for exact MIME type match
    return allowedType === file.type;
  });
};
