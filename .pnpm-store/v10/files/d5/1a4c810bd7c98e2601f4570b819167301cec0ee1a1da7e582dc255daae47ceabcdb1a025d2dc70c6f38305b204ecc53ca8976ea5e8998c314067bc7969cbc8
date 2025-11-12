Object.defineProperty(exports, '__esModule', { value: true });

const utils = require('@sentry/utils');
const integration = require('../integration.js');

const INTEGRATION_NAME = 'SessionTiming';

const _sessionTimingIntegration = (() => {
  const startTime = utils.timestampInSeconds() * 1000;

  return {
    name: INTEGRATION_NAME,
    processEvent(event) {
      const now = utils.timestampInSeconds() * 1000;

      return {
        ...event,
        extra: {
          ...event.extra,
          ['session:start']: startTime,
          ['session:duration']: now - startTime,
          ['session:end']: now,
        },
      };
    },
  };
}) ;

/**
 * This function adds duration since the sessionTimingIntegration was initialized
 * till the time event was sent.
 */
const sessionTimingIntegration = integration.defineIntegration(_sessionTimingIntegration);

exports.sessionTimingIntegration = sessionTimingIntegration;
//# sourceMappingURL=sessiontiming.js.map
