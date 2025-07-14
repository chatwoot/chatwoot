Object.defineProperty(exports, '__esModule', { value: true });

const utils = require('@sentry/utils');
const index = require('../asyncContext/index.js');
const carrier = require('../carrier.js');
const currentScopes = require('../currentScopes.js');
require('../tracing/errors.js');
require('../debug-build.js');
const spanUtils = require('./spanUtils.js');
const dynamicSamplingContext = require('../tracing/dynamicSamplingContext.js');

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
  const carrier$1 = carrier.getMainCarrier();
  const acs = index.getAsyncContextStrategy(carrier$1);
  if (acs.getTraceData) {
    return acs.getTraceData();
  }

  const client = currentScopes.getClient();
  const scope = currentScopes.getCurrentScope();
  const span = spanUtils.getActiveSpan();

  const { dsc, sampled, traceId } = scope.getPropagationContext();
  const rootSpan = span && spanUtils.getRootSpan(span);

  const sentryTrace = span ? spanUtils.spanToTraceHeader(span) : utils.generateSentryTraceHeader(traceId, undefined, sampled);

  const dynamicSamplingContext$1 = rootSpan
    ? dynamicSamplingContext.getDynamicSamplingContextFromSpan(rootSpan)
    : dsc
      ? dsc
      : client
        ? dynamicSamplingContext.getDynamicSamplingContextFromClient(traceId, client)
        : undefined;

  const baggage = utils.dynamicSamplingContextToSentryBaggageHeader(dynamicSamplingContext$1);

  const isValidSentryTraceHeader = utils.TRACEPARENT_REGEXP.test(sentryTrace);
  if (!isValidSentryTraceHeader) {
    utils.logger.warn('Invalid sentry-trace data. Cannot generate trace data');
    return {};
  }

  const validBaggage = isValidBaggageString(baggage);
  if (!validBaggage) {
    utils.logger.warn('Invalid baggage data. Not returning "baggage" value');
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

exports.getTraceData = getTraceData;
exports.isValidBaggageString = isValidBaggageString;
//# sourceMappingURL=traceData.js.map
