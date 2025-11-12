import { logger } from '@sentry/utils';
import { DEBUG_BUILD } from '../debug-build.js';
import { hasTracingEnabled } from '../utils/hasTracingEnabled.js';
import { parseSampleRate } from '../utils/parseSampleRate.js';

/**
 * Makes a sampling decision for the given options.
 *
 * Called every time a root span is created. Only root spans which emerge with a `sampled` value of `true` will be
 * sent to Sentry.
 */
function sampleSpan(
  options,
  samplingContext,
) {
  // nothing to do if tracing is not enabled
  if (!hasTracingEnabled(options)) {
    return [false];
  }

  // we would have bailed already if neither `tracesSampler` nor `tracesSampleRate` nor `enableTracing` were defined, so one of these should
  // work; prefer the hook if so
  let sampleRate;
  if (typeof options.tracesSampler === 'function') {
    sampleRate = options.tracesSampler(samplingContext);
  } else if (samplingContext.parentSampled !== undefined) {
    sampleRate = samplingContext.parentSampled;
  } else if (typeof options.tracesSampleRate !== 'undefined') {
    sampleRate = options.tracesSampleRate;
  } else {
    // When `enableTracing === true`, we use a sample rate of 100%
    sampleRate = 1;
  }

  // Since this is coming from the user (or from a function provided by the user), who knows what we might get.
  // (The only valid values are booleans or numbers between 0 and 1.)
  const parsedSampleRate = parseSampleRate(sampleRate);

  if (parsedSampleRate === undefined) {
    DEBUG_BUILD && logger.warn('[Tracing] Discarding transaction because of invalid sample rate.');
    return [false];
  }

  // if the function returned 0 (or false), or if `tracesSampleRate` is 0, it's a sign the transaction should be dropped
  if (!parsedSampleRate) {
    DEBUG_BUILD &&
      logger.log(
        `[Tracing] Discarding transaction because ${
          typeof options.tracesSampler === 'function'
            ? 'tracesSampler returned 0 or false'
            : 'a negative sampling decision was inherited or tracesSampleRate is set to 0'
        }`,
      );
    return [false, parsedSampleRate];
  }

  // Now we roll the dice. Math.random is inclusive of 0, but not of 1, so strict < is safe here. In case sampleRate is
  // a boolean, the < comparison will cause it to be automatically cast to 1 if it's true and 0 if it's false.
  const shouldSample = Math.random() < parsedSampleRate;

  // if we're not going to keep it, we're done
  if (!shouldSample) {
    DEBUG_BUILD &&
      logger.log(
        `[Tracing] Discarding transaction because it's not included in the random sample (sampling rate = ${Number(
          sampleRate,
        )})`,
      );
    return [false, parsedSampleRate];
  }

  return [true, parsedSampleRate];
}

export { sampleSpan };
//# sourceMappingURL=sampling.js.map
