/**
 * Media URL validation utilities for WhatsApp campaign templates.
 * Validates URL format, reachability, content type, and file size.
 */

export interface MediaValidationResult {
  isValid: boolean;
  error?: string;
  errorKey?: string;
  contentType?: string;
  contentLength?: number;
}

/**
 * WhatsApp media size limits (in bytes)
 * Reference: https://developers.facebook.com/docs/whatsapp/cloud-api/reference/media
 */
export const MEDIA_SIZE_LIMITS = {
  IMAGE: 5 * 1024 * 1024, // 5 MB
  VIDEO: 16 * 1024 * 1024, // 16 MB
  DOCUMENT: 100 * 1024 * 1024, // 100 MB
};

/**
 * Allowed content types per media format
 */
export const ALLOWED_CONTENT_TYPES: Record<string, string[]> = {
  IMAGE: [
    'image/jpeg',
    'image/png',
    'image/webp',
  ],
  VIDEO: [
    'video/mp4',
    'video/3gpp',
  ],
  DOCUMENT: [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'text/plain',
  ],
};

/**
 * Format bytes to human readable string
 */
export function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

/**
 * Validate URL format
 */
export function isValidUrl(url: string): boolean {
  try {
    const parsed = new URL(url);
    return ['http:', 'https:'].includes(parsed.protocol);
  } catch {
    return false;
  }
}

/**
 * Validate media URL by fetching headers and checking content type and size.
 * Uses HEAD request first, falls back to GET with range if HEAD fails.
 */
export async function validateMediaUrl(
  url: string,
  mediaType: 'IMAGE' | 'VIDEO' | 'DOCUMENT'
): Promise<MediaValidationResult> {
  // Check URL format first
  if (!url || !url.trim()) {
    return {
      isValid: false,
      error: 'URL is required',
      errorKey: 'MEDIA_URL_REQUIRED',
    };
  }

  if (!isValidUrl(url)) {
    return {
      isValid: false,
      error: 'Invalid URL format',
      errorKey: 'MEDIA_URL_INVALID_FORMAT',
    };
  }

  try {
    // Try HEAD request first (most efficient)
    let response: Response;
    try {
      response = await fetch(url, {
        method: 'HEAD',
        mode: 'cors',
      });
    } catch {
      // HEAD might be blocked by CORS, try GET with range header
      response = await fetch(url, {
        method: 'GET',
        mode: 'cors',
        headers: {
          Range: 'bytes=0-0',
        },
      });
    }

    if (!response.ok && response.status !== 206) {
      return {
        isValid: false,
        error: `URL not reachable (HTTP ${response.status})`,
        errorKey: 'MEDIA_URL_NOT_REACHABLE',
      };
    }

    // Get content type
    const contentType = response.headers.get('content-type')?.split(';')[0]?.trim().toLowerCase();
    const allowedTypes = ALLOWED_CONTENT_TYPES[mediaType] || [];

    if (contentType && !allowedTypes.some(t => contentType.startsWith(t.split('/')[0]))) {
      const expectedTypes = allowedTypes.map(t => t.split('/')[1]).join(', ');
      return {
        isValid: false,
        error: `Invalid content type: ${contentType}. Expected: ${expectedTypes}`,
        errorKey: 'MEDIA_URL_INVALID_TYPE',
        contentType,
      };
    }

    // Get content length
    const contentLengthHeader = response.headers.get('content-length');
    const contentRangeHeader = response.headers.get('content-range');
    
    let contentLength: number | undefined;
    
    if (contentLengthHeader) {
      contentLength = parseInt(contentLengthHeader, 10);
    } else if (contentRangeHeader) {
      // Parse Content-Range: bytes 0-0/12345
      const match = contentRangeHeader.match(/\/(\d+)$/);
      if (match) {
        contentLength = parseInt(match[1], 10);
      }
    }

    // Check size limit
    const sizeLimit = MEDIA_SIZE_LIMITS[mediaType];
    if (contentLength && contentLength > sizeLimit) {
      return {
        isValid: false,
        error: `File too large: ${formatBytes(contentLength)}. Maximum: ${formatBytes(sizeLimit)}`,
        errorKey: 'MEDIA_URL_TOO_LARGE',
        contentType,
        contentLength,
      };
    }

    return {
      isValid: true,
      contentType,
      contentLength,
    };
  } catch (error) {
    // CORS or network error - we can't validate but shouldn't block
    // WhatsApp will validate on their side
    console.warn('Media URL validation failed (CORS/network):', error);
    return {
      isValid: true, // Allow to proceed, WhatsApp will validate
      error: undefined,
    };
  }
}

/**
 * Validate media URL with user-friendly error messages
 */
export async function validateMediaUrlWithMessages(
  url: string,
  mediaType: 'IMAGE' | 'VIDEO' | 'DOCUMENT',
  locale: 'en' | 'pt_BR' = 'en'
): Promise<MediaValidationResult> {
  const result = await validateMediaUrl(url, mediaType);
  
  if (!result.isValid && result.errorKey) {
    const messages: Record<string, Record<string, string>> = {
      MEDIA_URL_REQUIRED: {
        en: 'Media URL is required',
        pt_BR: 'URL da mídia é obrigatória',
      },
      MEDIA_URL_INVALID_FORMAT: {
        en: 'Please enter a valid URL (http:// or https://)',
        pt_BR: 'Por favor, insira uma URL válida (http:// ou https://)',
      },
      MEDIA_URL_NOT_REACHABLE: {
        en: 'Could not reach the media URL. Please check if the URL is correct and publicly accessible.',
        pt_BR: 'Não foi possível acessar a URL da mídia. Verifique se a URL está correta e acessível publicamente.',
      },
      MEDIA_URL_INVALID_TYPE: {
        en: `Invalid file type for ${mediaType.toLowerCase()}. ${result.error}`,
        pt_BR: `Tipo de arquivo inválido para ${mediaType.toLowerCase()}. ${result.error}`,
      },
      MEDIA_URL_TOO_LARGE: {
        en: result.error || 'File is too large',
        pt_BR: result.error?.replace('File too large', 'Arquivo muito grande').replace('Maximum', 'Máximo') || 'Arquivo muito grande',
      },
    };

    result.error = messages[result.errorKey]?.[locale] || result.error;
  }

  return result;
}

/**
 * Check if a URL is reachable (quick check without full validation)
 */
export async function isUrlReachable(url: string): Promise<boolean> {
  if (!isValidUrl(url)) return false;

  try {
    const response = await fetch(url, {
      method: 'HEAD',
      mode: 'cors',
    });
    return response.ok;
  } catch {
    // Try with GET as fallback
    try {
      const response = await fetch(url, {
        method: 'GET',
        mode: 'cors',
        headers: { Range: 'bytes=0-0' },
      });
      return response.ok || response.status === 206;
    } catch {
      return false;
    }
  }
}

