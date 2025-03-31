Object.defineProperty(exports, '__esModule', { value: true });

const utils = require('@sentry/utils');
const integration = require('../integration.js');

const INTEGRATION_NAME = 'Debug';

/**
 * Integration to debug sent Sentry events.
 * This integration should not be used in production.
 */
const _debugIntegration = ((options = {}) => {
  const _options = {
    debugger: false,
    stringify: false,
    ...options,
  };

  return {
    name: INTEGRATION_NAME,
    setup(client) {
      client.on('beforeSendEvent', (event, hint) => {
        if (_options.debugger) {
          // eslint-disable-next-line no-debugger
          debugger;
        }

        /* eslint-disable no-console */
        utils.consoleSandbox(() => {
          if (_options.stringify) {
            console.log(JSON.stringify(event, null, 2));
            if (hint && Object.keys(hint).length) {
              console.log(JSON.stringify(hint, null, 2));
            }
          } else {
            console.log(event);
            if (hint && Object.keys(hint).length) {
              console.log(hint);
            }
          }
        });
        /* eslint-enable no-console */
      });
    },
  };
}) ;

const debugIntegration = integration.defineIntegration(_debugIntegration);

exports.debugIntegration = debugIntegration;
//# sourceMappingURL=debug.js.map
