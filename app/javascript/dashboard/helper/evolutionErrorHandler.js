/**
 * Evolution API Error Handler
 * Provides specific error message mapping for Evolution API integration errors
 */

// HTTP status codes and their meanings in Evolution API context
const EVOLUTION_ERROR_CODES = {
  400: 'EVOLUTION_INVALID_CREDENTIALS',
  401: 'EVOLUTION_AUTHENTICATION_FAILED',
  403: 'EVOLUTION_AUTHENTICATION_FAILED',
  404: 'EVOLUTION_API_UNAVAILABLE',
  409: 'EVOLUTION_PHONE_ALREADY_EXISTS',
  422: 'EVOLUTION_INSTANCE_CREATION_FAILED',
  500: 'EVOLUTION_API_UNAVAILABLE',
  502: 'EVOLUTION_CONNECTION_FAILED',
  503: 'EVOLUTION_API_UNAVAILABLE',
  504: 'EVOLUTION_CONNECTION_FAILED',
};

// Common error message patterns from Evolution API
const EVOLUTION_ERROR_PATTERNS = [
  {
    pattern:
      /already.*exists|duplicate.*phone|phone.*taken|instance.*exists|phone.*already/i,
    key: 'EVOLUTION_PHONE_ALREADY_EXISTS',
  },
  {
    pattern: /invalid.*key|invalid.*token|unauthorized|authentication.*failed/i,
    key: 'EVOLUTION_AUTHENTICATION_FAILED',
  },
  {
    pattern: /connection.*refused|connect.*failed|network.*error/i,
    key: 'EVOLUTION_CONNECTION_FAILED',
  },
  {
    pattern: /service.*unavailable|server.*error|internal.*error/i,
    key: 'EVOLUTION_API_UNAVAILABLE',
  },
  {
    pattern: /timeout|timed.*out/i,
    key: 'EVOLUTION_CONNECTION_FAILED',
  },
  {
    pattern: /webhook.*failed|callback.*error/i,
    key: 'EVOLUTION_WEBHOOK_SETUP_FAILED',
  },
];

/**
 * Maps Evolution API errors to user-friendly i18n keys
 * @param {Object} error - The error object from API call
 * @returns {string} i18n key for the specific error message
 */
export function getEvolutionErrorKey(error) {
  // Handle network errors first
  if (!error.response) {
    if (error.code === 'ECONNREFUSED' || error.code === 'NETWORK_ERROR') {
      return 'INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_CONNECTION_FAILED';
    }
    if (error.code === 'ENOTFOUND') {
      return 'INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_API_UNAVAILABLE';
    }
    return 'INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_CONNECTION_FAILED';
  }

  const { status, data } = error.response;

  // Try to extract error message from response first for pattern matching
  const errorMessage = data?.message || data?.error || data?.details || '';

  // Check error message patterns first (more specific)
  const matchedPattern = EVOLUTION_ERROR_PATTERNS.find(({ pattern }) =>
    pattern.test(errorMessage)
  );
  if (matchedPattern) {
    return `INBOX_MGMT.ADD.WHATSAPP.API.${matchedPattern.key}`;
  }

  // Map specific HTTP status codes as fallback
  if (EVOLUTION_ERROR_CODES[status]) {
    return `INBOX_MGMT.ADD.WHATSAPP.API.${EVOLUTION_ERROR_CODES[status]}`;
  }

  // Default fallback for Evolution API errors
  return 'INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_INSTANCE_CREATION_FAILED';
}

/**
 * Checks if an error is related to Evolution API
 * @param {Object} error - The error object from API call
 * @returns {boolean} true if this is an Evolution API related error
 */
export function isEvolutionAPIError(error) {
  // Check URL patterns
  if (error.config?.url) {
    return error.config.url.includes('/channels/evolution_channel');
  }

  // Check response data for Evolution-specific indicators
  if (error.response?.data) {
    const data = error.response.data;
    const errorText = JSON.stringify(data).toLowerCase();
    return (
      errorText.includes('evolution') ||
      errorText.includes('whatsapp') ||
      error.response.config?.url?.includes('evolution')
    );
  }

  return false;
}

/**
 * Determines if an error is retryable
 * @param {Object} error - The error object from API call
 * @returns {boolean} true if the error is retryable
 */
function isRetryableError(error) {
  const retryableStatuses = [500, 502, 503, 504];
  const status = error.response?.status;

  // Network errors are retryable
  if (!error.response) return true;

  // Server errors are retryable
  if (retryableStatuses.includes(status)) return true;

  return false;
}

/**
 * Gets troubleshooting tips for the specific error
 * @param {Object} error - The error object from API call
 * @param {Function} t - i18n translation function
 * @returns {Array} array of troubleshooting tip strings
 */
function getTroubleshootingTips(error, t) {
  const tips = [];
  const status = error.response?.status;

  if (!error.response || [502, 503, 504].includes(status)) {
    tips.push(
      t('INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_TROUBLESHOOTING.CHECK_URL')
    );
    tips.push(
      t('INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_TROUBLESHOOTING.CHECK_NETWORK')
    );
  }

  if ([401, 403].includes(status)) {
    tips.push(
      t(
        'INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_TROUBLESHOOTING.CHECK_CREDENTIALS'
      )
    );
  }

  if (status === 409) {
    tips.push(
      t(
        'INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_TROUBLESHOOTING.CHECK_CREDENTIALS'
      )
    );
  }

  tips.push(
    t('INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_TROUBLESHOOTING.CONTACT_SUPPORT')
  );

  return tips;
}

/**
 * Formats Evolution API errors with retry and troubleshooting information
 * @param {Object} error - The error object from API call
 * @param {Function} t - i18n translation function
 * @returns {Object} formatted error object with message and additional info
 */
export function formatEvolutionError(error, t) {
  const errorKey = getEvolutionErrorKey(error);
  const baseMessage = t(errorKey);
  const retryMessage = t('INBOX_MGMT.ADD.WHATSAPP.API.EVOLUTION_RETRY_MESSAGE');

  return {
    message: `${baseMessage} ${retryMessage}`,
    originalError: error,
    canRetry: isRetryableError(error),
    troubleshooting: getTroubleshootingTips(error, t),
  };
}
