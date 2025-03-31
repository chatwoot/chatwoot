Object.defineProperty(exports, '__esModule', { value: true });

const utils = require('@sentry/utils');
const currentScopes = require('./currentScopes.js');
const debugBuild = require('./debug-build.js');

function isProfilingIntegrationWithProfiler(
  integration,
) {
  return (
    !!integration &&
    typeof integration['_profiler'] !== 'undefined' &&
    typeof integration['_profiler']['start'] === 'function' &&
    typeof integration['_profiler']['stop'] === 'function'
  );
}
/**
 * Starts the Sentry continuous profiler.
 * This mode is exclusive with the transaction profiler and will only work if the profilesSampleRate is set to a falsy value.
 * In continuous profiling mode, the profiler will keep reporting profile chunks to Sentry until it is stopped, which allows for continuous profiling of the application.
 */
function startProfiler() {
  const client = currentScopes.getClient();
  if (!client) {
    debugBuild.DEBUG_BUILD && utils.logger.warn('No Sentry client available, profiling is not started');
    return;
  }

  const integration = client.getIntegrationByName('ProfilingIntegration');

  if (!integration) {
    debugBuild.DEBUG_BUILD && utils.logger.warn('ProfilingIntegration is not available');
    return;
  }

  if (!isProfilingIntegrationWithProfiler(integration)) {
    debugBuild.DEBUG_BUILD && utils.logger.warn('Profiler is not available on profiling integration.');
    return;
  }

  integration._profiler.start();
}

/**
 * Stops the Sentry continuous profiler.
 * Calls to stop will stop the profiler and flush the currently collected profile data to Sentry.
 */
function stopProfiler() {
  const client = currentScopes.getClient();
  if (!client) {
    debugBuild.DEBUG_BUILD && utils.logger.warn('No Sentry client available, profiling is not started');
    return;
  }

  const integration = client.getIntegrationByName('ProfilingIntegration');
  if (!integration) {
    debugBuild.DEBUG_BUILD && utils.logger.warn('ProfilingIntegration is not available');
    return;
  }

  if (!isProfilingIntegrationWithProfiler(integration)) {
    debugBuild.DEBUG_BUILD && utils.logger.warn('Profiler is not available on profiling integration.');
    return;
  }

  integration._profiler.stop();
}

const profiler = {
  startProfiler,
  stopProfiler,
};

exports.profiler = profiler;
//# sourceMappingURL=profiling.js.map
