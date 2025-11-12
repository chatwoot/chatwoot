Object.defineProperty(exports, '__esModule', { value: true });

const utils = require('@sentry/utils');
const types = require('../types.js');

let lastHref;

/**
 * Add an instrumentation handler for when a fetch request happens.
 * The handler function is called once when the request starts and once when it ends,
 * which can be identified by checking if it has an `endTimestamp`.
 *
 * Use at your own risk, this might break without changelog notice, only used internally.
 * @hidden
 */
function addHistoryInstrumentationHandler(handler) {
  const type = 'history';
  utils.addHandler(type, handler);
  utils.maybeInstrument(type, instrumentHistory);
}

function instrumentHistory() {
  if (!utils.supportsHistory()) {
    return;
  }

  const oldOnPopState = types.WINDOW.onpopstate;
  types.WINDOW.onpopstate = function ( ...args) {
    const to = types.WINDOW.location.href;
    // keep track of the current URL state, as we always receive only the updated state
    const from = lastHref;
    lastHref = to;
    const handlerData = { from, to };
    utils.triggerHandlers('history', handlerData);
    if (oldOnPopState) {
      // Apparently this can throw in Firefox when incorrectly implemented plugin is installed.
      // https://github.com/getsentry/sentry-javascript/issues/3344
      // https://github.com/bugsnag/bugsnag-js/issues/469
      try {
        return oldOnPopState.apply(this, args);
      } catch (_oO) {
        // no-empty
      }
    }
  };

  function historyReplacementFunction(originalHistoryFunction) {
    return function ( ...args) {
      const url = args.length > 2 ? args[2] : undefined;
      if (url) {
        // coerce to string (this is what pushState does)
        const from = lastHref;
        const to = String(url);
        // keep track of the current URL state, as we always receive only the updated state
        lastHref = to;
        const handlerData = { from, to };
        utils.triggerHandlers('history', handlerData);
      }
      return originalHistoryFunction.apply(this, args);
    };
  }

  utils.fill(types.WINDOW.history, 'pushState', historyReplacementFunction);
  utils.fill(types.WINDOW.history, 'replaceState', historyReplacementFunction);
}

exports.addHistoryInstrumentationHandler = addHistoryInstrumentationHandler;
//# sourceMappingURL=history.js.map
