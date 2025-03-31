import { dropUndefinedKeys, baggageHeaderToDynamicSamplingContext, dynamicSamplingContextToSentryBaggageHeader, addNonEnumerableProperty } from '@sentry/utils';
import { DEFAULT_ENVIRONMENT } from '../constants.js';
import { getClient } from '../currentScopes.js';
import { SEMANTIC_ATTRIBUTE_SENTRY_SAMPLE_RATE, SEMANTIC_ATTRIBUTE_SENTRY_SOURCE } from '../semanticAttributes.js';
import { spanToJSON, getRootSpan, spanIsSampled } from '../utils/spanUtils.js';

/**
 * If you change this value, also update the terser plugin config to
 * avoid minification of the object property!
 */
const FROZEN_DSC_FIELD = '_frozenDsc';

/**
 * Freeze the given DSC on the given span.
 */
function freezeDscOnSpan(span, dsc) {
  const spanWithMaybeDsc = span ;
  addNonEnumerableProperty(spanWithMaybeDsc, FROZEN_DSC_FIELD, dsc);
}

/**
 * Creates a dynamic sampling context from a client.
 *
 * Dispatches the `createDsc` lifecycle hook as a side effect.
 */
function getDynamicSamplingContextFromClient(trace_id, client) {
  const options = client.getOptions();

  const { publicKey: public_key } = client.getDsn() || {};

  const dsc = dropUndefinedKeys({
    environment: options.environment || DEFAULT_ENVIRONMENT,
    release: options.release,
    public_key,
    trace_id,
  }) ;

  client.emit('createDsc', dsc);

  return dsc;
}

/**
 * Creates a dynamic sampling context from a span (and client and scope)
 *
 * @param span the span from which a few values like the root span name and sample rate are extracted.
 *
 * @returns a dynamic sampling context
 */
function getDynamicSamplingContextFromSpan(span) {
  const client = getClient();
  if (!client) {
    return {};
  }

  const dsc = getDynamicSamplingContextFromClient(spanToJSON(span).trace_id || '', client);

  const rootSpan = getRootSpan(span);

  // For core implementation, we freeze the DSC onto the span as a non-enumerable property
  const frozenDsc = (rootSpan )[FROZEN_DSC_FIELD];
  if (frozenDsc) {
    return frozenDsc;
  }

  // For OpenTelemetry, we freeze the DSC on the trace state
  const traceState = rootSpan.spanContext().traceState;
  const traceStateDsc = traceState && traceState.get('sentry.dsc');

  // If the span has a DSC, we want it to take precedence
  const dscOnTraceState = traceStateDsc && baggageHeaderToDynamicSamplingContext(traceStateDsc);

  if (dscOnTraceState) {
    return dscOnTraceState;
  }

  // Else, we generate it from the span
  const jsonSpan = spanToJSON(rootSpan);
  const attributes = jsonSpan.data || {};
  const maybeSampleRate = attributes[SEMANTIC_ATTRIBUTE_SENTRY_SAMPLE_RATE];

  if (maybeSampleRate != null) {
    dsc.sample_rate = `${maybeSampleRate}`;
  }

  // We don't want to have a transaction name in the DSC if the source is "url" because URLs might contain PII
  const source = attributes[SEMANTIC_ATTRIBUTE_SENTRY_SOURCE];

  // after JSON conversion, txn.name becomes jsonSpan.description
  const name = jsonSpan.description;
  if (source !== 'url' && name) {
    dsc.transaction = name;
  }

  dsc.sampled = String(spanIsSampled(rootSpan));

  client.emit('createDsc', dsc, rootSpan);

  return dsc;
}

/**
 * Convert a Span to a baggage header.
 */
function spanToBaggageHeader(span) {
  const dsc = getDynamicSamplingContextFromSpan(span);
  return dynamicSamplingContextToSentryBaggageHeader(dsc);
}

export { freezeDscOnSpan, getDynamicSamplingContextFromClient, getDynamicSamplingContextFromSpan, spanToBaggageHeader };
//# sourceMappingURL=dynamicSamplingContext.js.map
