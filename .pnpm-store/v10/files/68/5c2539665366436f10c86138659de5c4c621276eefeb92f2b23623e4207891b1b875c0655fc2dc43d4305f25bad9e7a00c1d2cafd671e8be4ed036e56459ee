Object.defineProperty(exports, '__esModule', { value: true });

const utils = require('@sentry/utils');
const currentScopes = require('../currentScopes.js');
const exports$1 = require('../exports.js');
const integration = require('../integration.js');

const INTEGRATION_NAME = 'CaptureConsole';

const _captureConsoleIntegration = ((options = {}) => {
  const levels = options.levels || utils.CONSOLE_LEVELS;

  return {
    name: INTEGRATION_NAME,
    setup(client) {
      if (!('console' in utils.GLOBAL_OBJ)) {
        return;
      }

      utils.addConsoleInstrumentationHandler(({ args, level }) => {
        if (currentScopes.getClient() !== client || !levels.includes(level)) {
          return;
        }

        consoleHandler(args, level);
      });
    },
  };
}) ;

/**
 * Send Console API calls as Sentry Events.
 */
const captureConsoleIntegration = integration.defineIntegration(_captureConsoleIntegration);

function consoleHandler(args, level) {
  const captureContext = {
    level: utils.severityLevelFromString(level),
    extra: {
      arguments: args,
    },
  };

  currentScopes.withScope(scope => {
    scope.addEventProcessor(event => {
      event.logger = 'console';

      utils.addExceptionMechanism(event, {
        handled: false,
        type: 'console',
      });

      return event;
    });

    if (level === 'assert') {
      if (!args[0]) {
        const message = `Assertion failed: ${utils.safeJoin(args.slice(1), ' ') || 'console.assert'}`;
        scope.setExtra('arguments', args.slice(1));
        exports$1.captureMessage(message, captureContext);
      }
      return;
    }

    const error = args.find(arg => arg instanceof Error);
    if (error) {
      exports$1.captureException(error, captureContext);
      return;
    }

    const message = utils.safeJoin(args, ' ');
    exports$1.captureMessage(message, captureContext);
  });
}

exports.captureConsoleIntegration = captureConsoleIntegration;
//# sourceMappingURL=captureconsole.js.map
