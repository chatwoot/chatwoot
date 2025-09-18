Object.defineProperty(exports, '__esModule', { value: true });

const utils = require('@sentry/utils');
const currentScopes = require('./currentScopes.js');
const semanticAttributes = require('./semanticAttributes.js');
require('./tracing/errors.js');
require('./debug-build.js');
const hasTracingEnabled = require('./utils/hasTracingEnabled.js');
const spanUtils = require('./utils/spanUtils.js');
const sentryNonRecordingSpan = require('./tracing/sentryNonRecordingSpan.js');
const spanstatus = require('./tracing/spanstatus.js');
const trace = require('./tracing/trace.js');
const dynamicSamplingContext = require('./tracing/dynamicSamplingContext.js');

/**
 * Create and track fetch request spans for usage in combination with `addFetchInstrumentationHandler`.
 *
 * @returns Span if a span was created, otherwise void.
 */
function instrumentFetchRequest(
  handlerData,
  shouldCreateSpan,
  shouldAttachHeaders,
  spans,
  spanOrigin = 'auto.http.browser',
) {
  if (!handlerData.fetchData) {
    return undefined;
  }

  const shouldCreateSpanResult = hasTracingEnabled.hasTracingEnabled() && shouldCreateSpan(handlerData.fetchData.url);

  if (handlerData.endTimestamp && shouldCreateSpanResult) {
    const spanId = handlerData.fetchData.__span;
    if (!spanId) return;

    const span = spans[spanId];
    if (span) {
      endSpan(span, handlerData);

      // eslint-disable-next-line @typescript-eslint/no-dynamic-delete
      delete spans[spanId];
    }
    return undefined;
  }

  const scope = currentScopes.getCurrentScope();
  const client = currentScopes.getClient();

  const { method, url } = handlerData.fetchData;

  const fullUrl = getFullURL(url);
  const host = fullUrl ? utils.parseUrl(fullUrl).host : undefined;

  const hasParent = !!spanUtils.getActiveSpan();

  const span =
    shouldCreateSpanResult && hasParent
      ? trace.startInactiveSpan({
          name: `${method} ${url}`,
          attributes: {
            url,
            type: 'fetch',
            'http.method': method,
            'http.url': fullUrl,
            'server.address': host,
            [semanticAttributes.SEMANTIC_ATTRIBUTE_SENTRY_ORIGIN]: spanOrigin,
            [semanticAttributes.SEMANTIC_ATTRIBUTE_SENTRY_OP]: 'http.client',
          },
        })
      : new sentryNonRecordingSpan.SentryNonRecordingSpan();

  handlerData.fetchData.__span = span.spanContext().spanId;
  spans[span.spanContext().spanId] = span;

  if (shouldAttachHeaders(handlerData.fetchData.url) && client) {
    const request = handlerData.args[0];

    // In case the user hasn't set the second argument of a fetch call we default it to `{}`.
    handlerData.args[1] = handlerData.args[1] || {};

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const options = handlerData.args[1];

    options.headers = addTracingHeadersToFetchRequest(
      request,
      client,
      scope,
      options,
      // If performance is disabled (TWP) or there's no active root span (pageload/navigation/interaction),
      // we do not want to use the span as base for the trace headers,
      // which means that the headers will be generated from the scope and the sampling decision is deferred
      hasTracingEnabled.hasTracingEnabled() && hasParent ? span : undefined,
    );
  }

  return span;
}

/**
 * Adds sentry-trace and baggage headers to the various forms of fetch headers
 */
function addTracingHeadersToFetchRequest(
  request, // unknown is actually type Request but we can't export DOM types from this package,
  client,
  scope,
  options

,
  span,
) {
  const isolationScope = currentScopes.getIsolationScope();

  const { traceId, spanId, sampled, dsc } = {
    ...isolationScope.getPropagationContext(),
    ...scope.getPropagationContext(),
  };

  const sentryTraceHeader = span ? spanUtils.spanToTraceHeader(span) : utils.generateSentryTraceHeader(traceId, spanId, sampled);

  const sentryBaggageHeader = utils.dynamicSamplingContextToSentryBaggageHeader(
    dsc || (span ? dynamicSamplingContext.getDynamicSamplingContextFromSpan(span) : dynamicSamplingContext.getDynamicSamplingContextFromClient(traceId, client)),
  );

  const headers =
    options.headers ||
    (typeof Request !== 'undefined' && utils.isInstanceOf(request, Request) ? (request ).headers : undefined);

  if (!headers) {
    return { 'sentry-trace': sentryTraceHeader, baggage: sentryBaggageHeader };
  } else if (typeof Headers !== 'undefined' && utils.isInstanceOf(headers, Headers)) {
    const newHeaders = new Headers(headers );

    newHeaders.append('sentry-trace', sentryTraceHeader);

    if (sentryBaggageHeader) {
      // If the same header is appended multiple times the browser will merge the values into a single request header.
      // Its therefore safe to simply push a "baggage" entry, even though there might already be another baggage header.
      newHeaders.append(utils.BAGGAGE_HEADER_NAME, sentryBaggageHeader);
    }

    return newHeaders ;
  } else if (Array.isArray(headers)) {
    const newHeaders = [...headers, ['sentry-trace', sentryTraceHeader]];

    if (sentryBaggageHeader) {
      // If there are multiple entries with the same key, the browser will merge the values into a single request header.
      // Its therefore safe to simply push a "baggage" entry, even though there might already be another baggage header.
      newHeaders.push([utils.BAGGAGE_HEADER_NAME, sentryBaggageHeader]);
    }

    return newHeaders ;
  } else {
    const existingBaggageHeader = 'baggage' in headers ? headers.baggage : undefined;
    const newBaggageHeaders = [];

    if (Array.isArray(existingBaggageHeader)) {
      newBaggageHeaders.push(...existingBaggageHeader);
    } else if (existingBaggageHeader) {
      newBaggageHeaders.push(existingBaggageHeader);
    }

    if (sentryBaggageHeader) {
      newBaggageHeaders.push(sentryBaggageHeader);
    }

    return {
      ...(headers ),
      'sentry-trace': sentryTraceHeader,
      baggage: newBaggageHeaders.length > 0 ? newBaggageHeaders.join(',') : undefined,
    };
  }
}

function getFullURL(url) {
  try {
    const parsed = new URL(url);
    return parsed.href;
  } catch (e) {
    return undefined;
  }
}

function endSpan(span, handlerData) {
  if (handlerData.response) {
    spanstatus.setHttpStatus(span, handlerData.response.status);

    const contentLength =
      handlerData.response && handlerData.response.headers && handlerData.response.headers.get('content-length');

    if (contentLength) {
      const contentLengthNum = parseInt(contentLength);
      if (contentLengthNum > 0) {
        span.setAttribute('http.response_content_length', contentLengthNum);
      }
    }
  } else if (handlerData.error) {
    span.setStatus({ code: spanstatus.SPAN_STATUS_ERROR, message: 'internal_error' });
  }
  span.end();
}

exports.addTracingHeadersToFetchRequest = addTracingHeadersToFetchRequest;
exports.instrumentFetchRequest = instrumentFetchRequest;
//# sourceMappingURL=fetch.js.map
