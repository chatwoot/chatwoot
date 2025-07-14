Object.defineProperty(exports, '__esModule', { value: true });

const baggage = require('./baggage.js');
const misc = require('./misc.js');

// eslint-disable-next-line @sentry-internal/sdk/no-regexp-constructor -- RegExp is used for readability here
const TRACEPARENT_REGEXP = new RegExp(
  '^[ \\t]*' + // whitespace
    '([0-9a-f]{32})?' + // trace_id
    '-?([0-9a-f]{16})?' + // span_id
    '-?([01])?' + // sampled
    '[ \\t]*$', // whitespace
);

/**
 * Extract transaction context data from a `sentry-trace` header.
 *
 * @param traceparent Traceparent string
 *
 * @returns Object containing data from the header, or undefined if traceparent string is malformed
 */
function extractTraceparentData(traceparent) {
  if (!traceparent) {
    return undefined;
  }

  const matches = traceparent.match(TRACEPARENT_REGEXP);
  if (!matches) {
    return undefined;
  }

  let parentSampled;
  if (matches[3] === '1') {
    parentSampled = true;
  } else if (matches[3] === '0') {
    parentSampled = false;
  }

  return {
    traceId: matches[1],
    parentSampled,
    parentSpanId: matches[2],
  };
}

/**
 * Create a propagation context from incoming headers or
 * creates a minimal new one if the headers are undefined.
 */
function propagationContextFromHeaders(
  sentryTrace,
  baggage$1,
) {
  const traceparentData = extractTraceparentData(sentryTrace);
  const dynamicSamplingContext = baggage.baggageHeaderToDynamicSamplingContext(baggage$1);

  const { traceId, parentSpanId, parentSampled } = traceparentData || {};

  if (!traceparentData) {
    return {
      traceId: traceId || misc.uuid4(),
      spanId: misc.uuid4().substring(16),
    };
  } else {
    return {
      traceId: traceId || misc.uuid4(),
      parentSpanId: parentSpanId || misc.uuid4().substring(16),
      spanId: misc.uuid4().substring(16),
      sampled: parentSampled,
      dsc: dynamicSamplingContext || {}, // If we have traceparent data but no DSC it means we are not head of trace and we must freeze it
    };
  }
}

/**
 * Create sentry-trace header from span context values.
 */
function generateSentryTraceHeader(
  traceId = misc.uuid4(),
  spanId = misc.uuid4().substring(16),
  sampled,
) {
  let sampledString = '';
  if (sampled !== undefined) {
    sampledString = sampled ? '-1' : '-0';
  }
  return `${traceId}-${spanId}${sampledString}`;
}

exports.TRACEPARENT_REGEXP = TRACEPARENT_REGEXP;
exports.extractTraceparentData = extractTraceparentData;
exports.generateSentryTraceHeader = generateSentryTraceHeader;
exports.propagationContextFromHeaders = propagationContextFromHeaders;
//# sourceMappingURL=tracing.js.map
