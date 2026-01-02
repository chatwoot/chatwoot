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
 * Get maximum file upload size (in MB) for a specific channel
 * @param {Object} options
 * @param {string} options.channelType - The channel type (e.g., 'Channel::TwilioSms', 'Channel::Whatsapp')
 * @param {string} [options.medium] - The medium for Twilio channels ('sms' | 'whatsapp')
 * @param {string} [options.mime] - The MIME type of the file (e.g., 'image/png')
 * @returns {number} Maximum file size in MB, or DEFAULT_MAXIMUM_FILE_UPLOAD_SIZE if no specific limit
 */
export const getMaxUploadSizeByChannel = ({ channelType, medium, mime }) => {
  // For now, return default size for all channels
  // Channel-specific limits can be added here if needed
  // Common limits:
  // - WhatsApp: 16 MB for media, 100 MB for documents
  // - SMS: Usually very small (e.g., 1-5 MB)
  // - Instagram: 100 MB for videos, 8 MB for images
  
  // Return default - the calling code will use installation limit if this equals DEFAULT_MAXIMUM_FILE_UPLOAD_SIZE
  return DEFAULT_MAXIMUM_FILE_UPLOAD_SIZE;
};
