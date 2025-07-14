import { generateSentryTraceHeader, dynamicSamplingContextToSentryBaggageHeader, TRACEPARENT_REGEXP, logger } from '@sentry/utils';
import { getAsyncContextStrategy } from '../asyncContext/index.js';
import { getMainCarrier } from '../carrier.js';
import { getClient, getCurrentScope } from '../currentScopes.js';
import '../tracing/errors.js';
import '../debug-build.js';
import { getActiveSpan, getRootSpan, spanToTraceHeader } from './spanUtils.js';
import { getDynamicSamplingContextFromSpan, getDynamicSamplingContextFromClient } from '../tracing/dynamicSamplingContext.js';

/**
 * Extracts trace propagation data from the current span or from the client's scope (via transaction or propagation
 * context) and serializes it to `sentry-trace` and `baggage` values to strings. These values can be used to propagate
 * a trace via our tracing Http headers or Html `<meta>` tags.
 *
 * This function also applies some validation to the generated sentry-trace and baggage values to ensure that
 * only valid strings are returned.
 *
 * @returns an object with the tracing data values. The object keys are the name of the tracing key to be used as header
 * or meta tag name.
 */
function getTraceData() {
  const carrier = getMainCarrier();
  const acs = getAsyncContextStrategy(carrier);
  if (acs.getTraceData) {
    return acs.getTraceData();
  }

  const client = getClient();
  const scope = getCurrentScope();
  const span = getActiveSpan();

  const { dsc, sampled, traceId } = scope.getPropagationContext();
  const rootSpan = span && getRootSpan(span);

  const sentryTrace = span ? spanToTraceHeader(span) : generateSentryTraceHeader(traceId, undefined, sampled);

  const dynamicSamplingContext = rootSpan
    ? getDynamicSamplingContextFromSpan(rootSpan)
    : dsc
      ? dsc
      : client
        ? getDynamicSamplingContextFromClient(traceId, client)
        : undefined;

  const baggage = dynamicSamplingContextToSentryBaggageHeader(dynamicSamplingContext);

  const isValidSentryTraceHeader = TRACEPARENT_REGEXP.test(sentryTrace);
  if (!isValidSentryTraceHeader) {
    logger.warn('Invalid sentry-trace data. Cannot generate trace data');
    return {};
  }

  const validBaggage = isValidBaggageString(baggage);
  if (!validBaggage) {
    logger.warn('Invalid baggage data. Not returning "baggage" value');
  }

  return {
    'sentry-trace': sentryTrace,
    ...(validBaggage && { baggage }),
  };
}

/**
 * Tests string against baggage spec as defined in:
 *
 * - W3C Baggage grammar: https://www.w3.org/TR/baggage/#definition
 * - RFC7230 token definition: https://datatracker.ietf.org/doc/html/rfc7230#section-3.2.6
 *
 * exported for testing
 */
function isValidBaggageString(baggage) {
  if (!baggage || !baggage.length) {
    return false;
  }
  const keyRegex = "[-!#$%&'*+.^_`|~A-Za-z0-9]+";
  const valueRegex = '[!#-+-./0-9:<=>?@A-Z\\[\\]a-z{-}]+';
  const spaces = '\\s*';
  // eslint-disable-next-line @sentry-internal/sdk/no-regexp-constructor -- RegExp for readability, no user input
  const baggageRegex = new RegExp(
    `^${keyRegex}${spaces}=${spaces}${valueRegex}(${spaces},${spaces}${keyRegex}${spaces}=${spaces}${valueRegex})*$`,
  );
  return baggageRegex.test(baggage);
}

export { getTraceData, isValidBaggageString };
//# sourceMappingURL=traceData.js.map
