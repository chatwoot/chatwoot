Object.defineProperty(exports, '__esModule', { value: true });

const utils = require('@sentry/utils');
const debugBuild = require('../debug-build.js');
const spanUtils = require('../utils/spanUtils.js');
const spanstatus = require('./spanstatus.js');

let errorsInstrumented = false;

/**
 * Ensure that global errors automatically set the active span status.
 */
function registerSpanErrorInstrumentation() {
  if (errorsInstrumented) {
    return;
  }

  errorsInstrumented = true;
  utils.addGlobalErrorInstrumentationHandler(errorCallback);
  utils.addGlobalUnhandledRejectionInstrumentationHandler(errorCallback);
}

/**
 * If an error or unhandled promise occurs, we mark the active root span as failed
 */
function errorCallback() {
  const activeSpan = spanUtils.getActiveSpan();
  const rootSpan = activeSpan && spanUtils.getRootSpan(activeSpan);
  if (rootSpan) {
    const message = 'internal_error';
    debugBuild.DEBUG_BUILD && utils.logger.log(`[Tracing] Root span: ${message} -> Global error occured`);
    rootSpan.setStatus({ code: spanstatus.SPAN_STATUS_ERROR, message });
  }
}

// The function name will be lost when bundling but we need to be able to identify this listener later to maintain the
// node.js default exit behaviour
errorCallback.tag = 'sentry_tracingErrorCallback';

exports.registerSpanErrorInstrumentation = registerSpanErrorInstrumentation;
//# sourceMappingURL=errors.js.map
