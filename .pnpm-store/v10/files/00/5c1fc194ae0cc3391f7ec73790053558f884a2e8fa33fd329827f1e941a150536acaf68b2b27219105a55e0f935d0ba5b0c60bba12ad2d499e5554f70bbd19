Object.defineProperty(exports, '__esModule', { value: true });

const utils = require('@sentry/utils');
const integration = require('../integration.js');

const DEFAULT_LIMIT = 10;
const INTEGRATION_NAME = 'ZodErrors';

// Simplified ZodIssue type definition

function originalExceptionIsZodError(originalException) {
  return (
    utils.isError(originalException) &&
    originalException.name === 'ZodError' &&
    Array.isArray((originalException ).errors)
  );
}

/**
 * Formats child objects or arrays to a string
 * That is preserved when sent to Sentry
 */
function formatIssueTitle(issue) {
  return {
    ...issue,
    path: 'path' in issue && Array.isArray(issue.path) ? issue.path.join('.') : undefined,
    keys: 'keys' in issue ? JSON.stringify(issue.keys) : undefined,
    unionErrors: 'unionErrors' in issue ? JSON.stringify(issue.unionErrors) : undefined,
  };
}

/**
 * Zod error message is a stringified version of ZodError.issues
 * This doesn't display well in the Sentry UI. Replace it with something shorter.
 */
function formatIssueMessage(zodError) {
  const errorKeyMap = new Set();
  for (const iss of zodError.issues) {
    if (iss.path && iss.path[0]) {
      errorKeyMap.add(iss.path[0]);
    }
  }
  const errorKeys = Array.from(errorKeyMap);

  return `Failed to validate keys: ${utils.truncate(errorKeys.join(', '), 100)}`;
}

/**
 * Applies ZodError issues to an event extras and replaces the error message
 */
function applyZodErrorsToEvent(limit, event, hint) {
  if (
    !event.exception ||
    !event.exception.values ||
    !hint ||
    !hint.originalException ||
    !originalExceptionIsZodError(hint.originalException) ||
    hint.originalException.issues.length === 0
  ) {
    return event;
  }

  return {
    ...event,
    exception: {
      ...event.exception,
      values: [
        {
          ...event.exception.values[0],
          value: formatIssueMessage(hint.originalException),
        },
        ...event.exception.values.slice(1),
      ],
    },
    extra: {
      ...event.extra,
      'zoderror.issues': hint.originalException.errors.slice(0, limit).map(formatIssueTitle),
    },
  };
}

const _zodErrorsIntegration = ((options = {}) => {
  const limit = options.limit || DEFAULT_LIMIT;

  return {
    name: INTEGRATION_NAME,
    processEvent(originalEvent, hint) {
      const processedEvent = applyZodErrorsToEvent(limit, originalEvent, hint);
      return processedEvent;
    },
  };
}) ;

const zodErrorsIntegration = integration.defineIntegration(_zodErrorsIntegration);

exports.applyZodErrorsToEvent = applyZodErrorsToEvent;
exports.zodErrorsIntegration = zodErrorsIntegration;
//# sourceMappingURL=zoderrors.js.map
