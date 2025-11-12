import { CONSOLE_LEVELS, GLOBAL_OBJ, addConsoleInstrumentationHandler, severityLevelFromString, addExceptionMechanism, safeJoin } from '@sentry/utils';
import { getClient, withScope } from '../currentScopes.js';
import { captureMessage, captureException } from '../exports.js';
import { defineIntegration } from '../integration.js';

const INTEGRATION_NAME = 'CaptureConsole';

const _captureConsoleIntegration = ((options = {}) => {
  const levels = options.levels || CONSOLE_LEVELS;

  return {
    name: INTEGRATION_NAME,
    setup(client) {
      if (!('console' in GLOBAL_OBJ)) {
        return;
      }

      addConsoleInstrumentationHandler(({ args, level }) => {
        if (getClient() !== client || !levels.includes(level)) {
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
const captureConsoleIntegration = defineIntegration(_captureConsoleIntegration);

function consoleHandler(args, level) {
  const captureContext = {
    level: severityLevelFromString(level),
    extra: {
      arguments: args,
    },
  };

  withScope(scope => {
    scope.addEventProcessor(event => {
      event.logger = 'console';

      addExceptionMechanism(event, {
        handled: false,
        type: 'console',
      });

      return event;
    });

    if (level === 'assert') {
      if (!args[0]) {
        const message = `Assertion failed: ${safeJoin(args.slice(1), ' ') || 'console.assert'}`;
        scope.setExtra('arguments', args.slice(1));
        captureMessage(message, captureContext);
      }
      return;
    }

    const error = args.find(arg => arg instanceof Error);
    if (error) {
      captureException(error, captureContext);
      return;
    }

    const message = safeJoin(args, ' ');
    captureMessage(message, captureContext);
  });
}

export { captureConsoleIntegration };
//# sourceMappingURL=captureconsole.js.map
