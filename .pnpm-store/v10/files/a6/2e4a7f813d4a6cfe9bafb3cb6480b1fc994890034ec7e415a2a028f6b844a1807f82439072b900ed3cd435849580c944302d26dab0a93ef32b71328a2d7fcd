Object.defineProperty(exports, '__esModule', { value: true });

const core = require('@sentry/core');
const utils$1 = require('@sentry/utils');
const debugBuild = require('../debug-build.js');
const helpers = require('../helpers.js');
const utils = require('./utils.js');

/**
 * Wraps startTransaction and stopTransaction with profiling related logic.
 * startProfileForTransaction is called after the call to startTransaction in order to avoid our own code from
 * being profiled. Because of that same reason, stopProfiling is called before the call to stopTransaction.
 */
function startProfileForSpan(span) {
  // Start the profiler and get the profiler instance.
  let startTimestamp;
  if (utils.isAutomatedPageLoadSpan(span)) {
    startTimestamp = utils$1.timestampInSeconds() * 1000;
  }

  const profiler = utils.startJSSelfProfile();

  // We failed to construct the profiler, so we skip.
  // No need to log anything as this has already been logged in startProfile.
  if (!profiler) {
    return;
  }

  if (debugBuild.DEBUG_BUILD) {
    utils$1.logger.log(`[Profiling] started profiling span: ${core.spanToJSON(span).description}`);
  }

  // We create "unique" span names to avoid concurrent spans with same names
  // from being ignored by the profiler. From here on, only this span name should be used when
  // calling the profiler methods. Note: we log the original name to the user to avoid confusion.
  const profileId = utils$1.uuid4();

  core.getCurrentScope().setContext('profile', {
    profile_id: profileId,
    start_timestamp: startTimestamp,
  });

  /**
   * Idempotent handler for profile stop
   */
  async function onProfileHandler() {
    // Check if the profile exists and return it the behavior has to be idempotent as users may call span.finish multiple times.
    if (!span) {
      return;
    }
    // Satisfy the type checker, but profiler will always be defined here.
    if (!profiler) {
      return;
    }

    return profiler
      .stop()
      .then((profile) => {
        if (maxDurationTimeoutID) {
          helpers.WINDOW.clearTimeout(maxDurationTimeoutID);
          maxDurationTimeoutID = undefined;
        }

        if (debugBuild.DEBUG_BUILD) {
          utils$1.logger.log(`[Profiling] stopped profiling of span: ${core.spanToJSON(span).description}`);
        }

        // In case of an overlapping span, stopProfiling may return null and silently ignore the overlapping profile.
        if (!profile) {
          if (debugBuild.DEBUG_BUILD) {
            utils$1.logger.log(
              `[Profiling] profiler returned null profile for: ${core.spanToJSON(span).description}`,
              'this may indicate an overlapping span or a call to stopProfiling with a profile title that was never started',
            );
          }
          return;
        }

        utils.addProfileToGlobalCache(profileId, profile);
      })
      .catch(error => {
        if (debugBuild.DEBUG_BUILD) {
          utils$1.logger.log('[Profiling] error while stopping profiler:', error);
        }
      });
  }

  // Enqueue a timeout to prevent profiles from running over max duration.
  let maxDurationTimeoutID = helpers.WINDOW.setTimeout(() => {
    if (debugBuild.DEBUG_BUILD) {
      utils$1.logger.log('[Profiling] max profile duration elapsed, stopping profiling for:', core.spanToJSON(span).description);
    }
    // If the timeout exceeds, we want to stop profiling, but not finish the span
    // eslint-disable-next-line @typescript-eslint/no-floating-promises
    onProfileHandler();
  }, utils.MAX_PROFILE_DURATION_MS);

  // We need to reference the original end call to avoid creating an infinite loop
  const originalEnd = span.end.bind(span);

  /**
   * Wraps span `end()` with profiling related logic.
   * startProfiling is called after the call to spanStart in order to avoid our own code from
   * being profiled. Because of that same reason, stopProfiling is called before the call to spanEnd.
   */
  function profilingWrappedSpanEnd() {
    if (!span) {
      return originalEnd();
    }
    // onProfileHandler should always return the same profile even if this is called multiple times.
    // Always call onProfileHandler to ensure stopProfiling is called and the timeout is cleared.
    void onProfileHandler().then(
      () => {
        originalEnd();
      },
      () => {
        // If onProfileHandler fails, we still want to call the original finish method.
        originalEnd();
      },
    );

    return span;
  }

  span.end = profilingWrappedSpanEnd;
}

exports.startProfileForSpan = startProfileForSpan;
//# sourceMappingURL=startProfileForSpan.js.map
