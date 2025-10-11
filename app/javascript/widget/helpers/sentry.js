/**
 * Lazy-load Sentry and set user context
 * Only loads Sentry when needed to keep bundle lightweight
 *
 * @param {Object} contact - Contact data from Chatwoot
 */
export const setSentryUser = async (contact) => {
  if (
    !contact ||
    !window.errorLoggingConfig ||
    !window.__CHATWOOT_SENTRY_LOADED__
  ) {
    return;
  }

  try {
    // Lazy import Sentry (only if already loaded)
    const Sentry = await import('@sentry/vue');

    // Map contact data to Sentry user context
    const sentryUser = {
      id: contact.id?.toString(),
      email: contact.email,
      username: contact.name || contact.identifier,
    };

    // Add additional contact attributes as extra data
    const extraData = {};

    if (contact.identifier) {
      extraData.identifier = contact.identifier;
    }

    if (contact.phone_number) {
      extraData.phone_number = contact.phone_number;
    }

    if (contact.availability_status) {
      extraData.availability_status = contact.availability_status;
    }

    if (contact.created_at) {
      extraData.created_at = contact.created_at;
    }

    if (contact.last_activity_at) {
      extraData.last_activity_at = contact.last_activity_at;
    }

    // Add custom attributes if present (excluding sensitive data like auth_token)
    if (contact.custom_attributes) {
      const safeCustomAttributes = { ...contact.custom_attributes };
      // Remove sensitive fields
      delete safeCustomAttributes.auth_token;
      delete safeCustomAttributes.password;
      delete safeCustomAttributes.secret;

      if (Object.keys(safeCustomAttributes).length > 0) {
        extraData.custom_attributes = safeCustomAttributes;
      }
    }

    // Set user context in Sentry
    Sentry.setUser(sentryUser);

    // Set additional context
    Sentry.setContext('contact', extraData);
  } catch (error) {
    // Sentry not loaded yet, silently skip
  }
};

/**
 * Clear Sentry user context (e.g., on logout)
 */
export const clearSentryUser = async () => {
  if (!window.errorLoggingConfig || !window.__CHATWOOT_SENTRY_LOADED__) {
    return;
  }

  try {
    const Sentry = await import('@sentry/vue');
    Sentry.setUser(null);
    Sentry.setContext('contact', null);
  } catch (error) {
    // Sentry not loaded yet, silently skip
  }
};

/**
 * Capture exception to Sentry (lazy-loaded)
 * Use this helper in components instead of direct Sentry import
 *
 * @param {Error} error - Error to capture
 * @param {Object} context - Additional context
 */
export const captureSentryException = async (error, context = {}) => {
  if (!window.errorLoggingConfig) {
    // Fallback to console if Sentry not configured
    console.error('Widget error:', error, context);
    return;
  }

  try {
    // Lazy import Sentry
    const Sentry = await import('@sentry/vue');
    Sentry.captureException(error, context);
  } catch (err) {
    // Sentry failed to load, log to console
    console.error('Widget error (Sentry unavailable):', error, context);
  }
};
