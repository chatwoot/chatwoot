import * as Sentry from '@sentry/vue';
/**
 * Send error data to Sentry with given context.
 * @param {Error} error Error instance to be reported to Sentry
 * @param {Object} [contextData] Data to be attached as context to Sentry Event.
 * @param {Object} [contextData.extras] Object with extra info
 * @param {Object} [contextData.componentProps] Object with Props to be send as context.
 * @param {Object} [contextData.componentState] Object with State to be send as context.
 * @param {Object} [contextData.requestData] Object with data related with request (if apply).
 * @param {("fatal"|"critical"|"error"|"warning"|"log"|"info"|"debug")} [level] The exception severity level.
 * @param {Array} [fingerprint] Array of values to uniquely identify a Sentry event.
 * @returns {String|null} Generated sentry event ID.
 */

export function captureSentryException(
  error,
  contextData = {},
  level = 'error',
  fingerprint = []
) {
  const { extras, componentProps, componentState, requestData } = contextData;

  Sentry.withScope(scope => {
    scope.setLevel(level);
    if (extras) scope.setExtras(extras);
    if (componentProps) scope.setContext('Props', componentProps);
    if (componentState) scope.setContext('State', componentState);
    if (requestData) scope.setContext('Request_Data', requestData);
    if (fingerprint.length) scope.setFingerprint(fingerprint);

    Sentry.captureException(error, scope);
  });
}
