Object.defineProperty(exports, '__esModule', { value: true });

const logger = require('../logger.js');
const object = require('../object.js');
const worldwide = require('../worldwide.js');
const handlers = require('./handlers.js');

/**
 * Add an instrumentation handler for when a console.xxx method is called.
 *
 * Use at your own risk, this might break without changelog notice, only used internally.
 * @hidden
 */
function addConsoleInstrumentationHandler(handler) {
  const type = 'console';
  handlers.addHandler(type, handler);
  handlers.maybeInstrument(type, instrumentConsole);
}

function instrumentConsole() {
  if (!('console' in worldwide.GLOBAL_OBJ)) {
    return;
  }

  logger.CONSOLE_LEVELS.forEach(function (level) {
    if (!(level in worldwide.GLOBAL_OBJ.console)) {
      return;
    }

    object.fill(worldwide.GLOBAL_OBJ.console, level, function (originalConsoleMethod) {
      logger.originalConsoleMethods[level] = originalConsoleMethod;

      return function (...args) {
        const handlerData = { args, level };
        handlers.triggerHandlers('console', handlerData);

        const log = logger.originalConsoleMethods[level];
        log && log.apply(worldwide.GLOBAL_OBJ.console, args);
      };
    });
  });
}

exports.addConsoleInstrumentationHandler = addConsoleInstrumentationHandler;
//# sourceMappingURL=console.js.map
