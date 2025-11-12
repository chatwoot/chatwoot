import isToday from 'date-fns/isToday';
import isYesterday from 'date-fns/isYesterday';
/**
 * @name Get contrasting text color
 * @description Get contrasting text color from a text color
 * @param bgColor  Background color of text.
 * @returns contrasting text color
 */
export const getContrastingTextColor = (bgColor: string): string => {
  const color = bgColor.replace('#', '');
  const r = parseInt(color.slice(0, 2), 16);
  const g = parseInt(color.slice(2, 4), 16);
  const b = parseInt(color.slice(4, 6), 16);
  // http://stackoverflow.com/a/3943023/112731
  return r * 0.299 + g * 0.587 + b * 0.114 > 186 ? '#000000' : '#FFFFFF';
};

/**
 * @name Get formatted date
 * @description Get date in today, yesterday or any other date format
 * @param date  date
 * @param todayText  Today text
 * @param yesterdayText  Yesterday text
 * @returns formatted date
 */
export const formatDate = ({
  date,
  todayText,
  yesterdayText,
}: {
  date: string;
  todayText: string;
  yesterdayText: string;
}) => {
  const dateValue = new Date(date);
  if (isToday(dateValue)) return todayText;
  if (isYesterday(dateValue)) return yesterdayText;
  return date;
};

/**
 * @name formatTime
 * @description Format time to Hour, Minute and Second
 * @param timeInSeconds  number
 * @returns formatted time
 */

export const formatTime = (timeInSeconds: number) => {
  let formattedTime = '';
  if (timeInSeconds >= 60 && timeInSeconds < 3600) {
    const minutes = Math.floor(timeInSeconds / 60);
    formattedTime = `${minutes} Min`;
    const seconds = minutes === 60 ? 0 : Math.floor(timeInSeconds % 60);
    return formattedTime + `${seconds > 0 ? ' ' + seconds + ' Sec' : ''}`;
  }
  if (timeInSeconds >= 3600 && timeInSeconds < 86400) {
    const hours = Math.floor(timeInSeconds / 3600);
    formattedTime = `${hours} Hr`;
    const minutes =
      timeInSeconds % 3600 < 60 || hours === 24
        ? 0
        : Math.floor((timeInSeconds % 3600) / 60);
    return formattedTime + `${minutes > 0 ? ' ' + minutes + ' Min' : ''}`;
  }
  if (timeInSeconds >= 86400) {
    const days = Math.floor(timeInSeconds / 86400);
    formattedTime = `${days} Day`;
    const hours =
      timeInSeconds % 86400 < 3600 || days >= 364
        ? 0
        : Math.floor((timeInSeconds % 86400) / 3600);
    return formattedTime + `${hours > 0 ? ' ' + hours + ' Hr' : ''}`;
  }
  return `${Math.floor(timeInSeconds)} Sec`;
};

/**
 * @name trimContent
 * @description Trim a string to max length
 * @param content String to trim
 * @param maxLength Length of the string to trim, default 1024
 * @param ellipsis Boolean to add dots at the end of the string, default false
 * @returns trimmed string
 */
export const trimContent = (
  content: string = '',
  maxLength: number = 1024,
  ellipsis: boolean = false
) => {
  let trimmedContent = content;
  if (content.length > maxLength) {
    trimmedContent = content.substring(0, maxLength);
  }
  if (ellipsis) {
    trimmedContent = trimmedContent + '...';
  }
  return trimmedContent;
};

/**
 * @name convertSecondsToTimeUnit
 * @description Convert seconds to time unit
 * @param seconds  number
 * @param unitNames  object
 * @returns time and unit
 * @example
 * convertToUnit(60, { minute: 'm', hour: 'h', day: 'd' }); // { time: 1, unit: 'm' }
 * convertToUnit(60, { minute: 'Minutes', hour: 'Hours', day: 'Days' }); // { time: 1, unit: 'Minutes' }
 */

export const convertSecondsToTimeUnit = (
  seconds: number,
  unitNames: { minute: string; hour: string; day: string }
) => {
  if (seconds === null || seconds === 0) return { time: '', unit: '' };
  if (seconds < 3600)
    return { time: Number((seconds / 60).toFixed(1)), unit: unitNames.minute };
  if (seconds < 86400)
    return { time: Number((seconds / 3600).toFixed(1)), unit: unitNames.hour };
  return { time: Number((seconds / 86400).toFixed(1)), unit: unitNames.day };
};

/**
 * @name fileNameWithEllipsis
 * @description Truncates a filename while preserving the extension
 * @param {Object} file - File object containing filename or name property
 * @param {number} [maxLength=26] - Maximum length of the filename (excluding extension)
 * @param {string} [ellipsis='…'] - Character to use for truncation
 * @returns {string} Truncated filename with extension
 * @example
 * fileNameWithEllipsis({ filename: 'very-long-filename.pdf' }, 10) // 'very-long-f….pdf'
 * fileNameWithEllipsis({ name: 'short.txt' }, 10) // 'short.txt'
 */
export const fileNameWithEllipsis = (
  file: { filename?: string; name?: string },
  maxLength: number = 26,
  ellipsis: string = '…'
): string => {
  const fullName = file?.filename ?? file?.name ?? 'Untitled';

  const dotIndex = fullName.lastIndexOf('.');
  if (dotIndex === -1) return fullName;

  const [name, extension] = [
    fullName.slice(0, dotIndex),
    fullName.slice(dotIndex),
  ];

  if (name.length <= maxLength) return fullName;

  return `${name.slice(0, maxLength)}${ellipsis}${extension}`;
};

/**
 * @name splitName
 * @description Splits a full name into firstName and lastName
 * @param {string} name - Full name of the user
 * @returns {Object} Object with firstName and lastName
 * @example
 * splitName('Mary Jane Smith') // { firstName: 'Mary Jane', lastName: 'Smith' }
 * splitName('Alice') // { firstName: 'Alice', lastName: '' }
 * splitName('John Doe') // { firstName: 'John', lastName: 'Doe' }
 * splitName('') // { firstName: '', lastName: '' }
 */
export const splitName = (
  fullName: string
): { firstName: string; lastName: string } => {
  const trimmedName = fullName.trim();
  if (!trimmedName) {
    return {
      firstName: '',
      lastName: '',
    };
  }

  // Split the name by spaces
  const nameParts = trimmedName.split(/\s+/);

  // If only one word, treat it as firstName
  if (nameParts.length === 1) {
    return {
      firstName: nameParts[0],
      lastName: '',
    };
  }

  // Last element is lastName, everything else is firstName
  const lastName = nameParts.pop() || '';
  const firstName = nameParts.join(' ');

  return { firstName, lastName };
};

interface DownloadFileOptions {
  url: string;
  type: string;
  extension?: string | null;
}
/**
 * Downloads a file from a URL with proper file type handling
 * @name downloadFile
 * @description Downloads file from URL with proper type handling and cleanup
 * @param {Object} options Download configuration options
 * @param {string} options.url File URL to download
 * @param {string} options.type File type identifier
 * @param {string} [options.extension] Optional file extension
 * @returns {Promise<boolean>} Returns true if download successful, false otherwise
 */
export const downloadFile = async ({
  url,
  type,
  extension = null,
}: DownloadFileOptions): Promise<void> => {
  if (!url || !type) {
    throw new Error('Invalid download parameters');
  }

  try {
    const response = await fetch(url, { cache: 'no-store' });

    if (!response.ok) {
      throw new Error(`Download failed: ${response.status}`);
    }

    const blobData = await response.blob();

    const contentType = response.headers.get('content-type');

    const fileExtension =
      extension || (contentType ? contentType.split('/')[1] : type);

    const dispositionHeader = response.headers.get('content-disposition');
    const filenameMatch = dispositionHeader?.match(/filename="(.*?)"/);

    const filename =
      filenameMatch?.[1] ?? `attachment_${Date.now()}.${fileExtension}`;

    const blobUrl = URL.createObjectURL(blobData);
    const link = Object.assign(document.createElement('a'), {
      href: blobUrl,
      download: filename,
      style: 'display: none',
    });

    document.body.append(link);
    link.click();
    link.remove();
    URL.revokeObjectURL(blobUrl);
  } catch (error) {
    throw error instanceof Error ? error : new Error('Download failed');
  }
};

interface FileInfo {
  name: string; // Full filename with extension
  type: string; // File extension only
  base: string; // Filename without extension
}
/**
 * Extracts file information from a URL or file path.
 *
 * @param {string} url - The URL or file path to process
 * @returns {FileInfo} Object containing file information
 *
 * @example
 * getFileInfo('https://example.com/path/Document%20Name.PDF')
 * returns {
 *   name: 'Document Name.PDF',
 *   type: 'pdf',
 *   base: 'Document Name'
 * }
 *
 * getFileInfo('invalid/url')
 * returns {
 *   name: 'Unknown File',
 *   type: '',
 *   base: 'Unknown File'
 * }
 */
export const getFileInfo = (url: string): FileInfo => {
  const defaultInfo: FileInfo = {
    name: 'Unknown File',
    type: '',
    base: 'Unknown File',
  };

  if (!url || typeof url !== 'string') {
    return defaultInfo;
  }

  try {
    // Handle both URL and file path cases
    const cleanUrl = url
      .split(/[?#]/)[0] // Remove query params and hash
      .replace(/\\/g, '/'); // Normalize path separators

    const encodedFilename = cleanUrl.split('/').pop();
    if (!encodedFilename) {
      return defaultInfo;
    }

    const fileName = decodeURIComponent(encodedFilename);

    // Handle hidden files (starting with dot)
    if (fileName.startsWith('.') && !fileName.includes('.', 1)) {
      return { name: fileName, type: '', base: fileName };
    }

    // last index is where the file extension starts
    // This will handle cases where the file name has multiple dots
    const lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex === -1 || lastDotIndex === 0) {
      return { name: fileName, type: '', base: fileName };
    }

    const base = fileName.slice(0, lastDotIndex);
    const type = fileName.slice(lastDotIndex + 1).toLowerCase();

    return { name: fileName, type, base };
  } catch (error) {
    console.error('Error processing file info:', error);
    return defaultInfo;
  }
};

/**
 * Formats a number with K/M/B/T suffixes using Intl.NumberFormat
 * @param {number | string | null | undefined} num - The number to format
 * @returns {string} Formatted string (e.g., "1.2K", "2.3M", "999")
 * @example
 * formatNumber(1234)     // "1.2K"
 * formatNumber(1000000)  // "1M"
 * formatNumber(999)      // "999"
 * formatNumber(12344)    // "12.3K"
 */
export const formatNumber = (
  num: number | string | null | undefined
): string => {
  const n = Number(num) || 0;
  return new Intl.NumberFormat('en', {
    notation: 'compact',
    maximumFractionDigits: 1,
  } as Intl.NumberFormatOptions).format(n);
};
