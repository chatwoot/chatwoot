/**
 * @file mime.js
 * @since 4.0.0
 */

const EXTRACT_TYPE_REGEXP = /^\s*([^;\s]*)(?:;|\s|$)/;

/**
 * Mimetypes
 * @enum
 */
const Mimetypes = {
    'video/ogg': 'ogv',
    'video/mp4': 'mp4',
    'video/x-matroska': 'mkv',
    'video/webm': 'webm',
    'audio/mp4': 'm4a',
    'audio/mpeg': 'mp3',
    'audio/aac': 'aac',
    'audio/flac': 'flac',
    'audio/ogg': 'oga',
    'audio/wav': 'wav',
    'audio/webm': 'webm',
    'application/x-mpegURL': 'm3u8',
    'image/jpeg': 'jpg',
    'image/gif': 'gif',
    'image/png': 'png',
    'image/svg+xml': 'svg',
    'image/webp': 'webp'
};

/**
 * Get file extension for mime-type.
 *
 * @param {string} mimeType - Mime-type to match against.
 * @returns {string} File extension.
 * @private
 */
const getExtension = function(mimeType) {
    const match = EXTRACT_TYPE_REGEXP.exec(mimeType);
    const result = match && match[1].toLowerCase();
    return Mimetypes[result];
};

export default getExtension;
