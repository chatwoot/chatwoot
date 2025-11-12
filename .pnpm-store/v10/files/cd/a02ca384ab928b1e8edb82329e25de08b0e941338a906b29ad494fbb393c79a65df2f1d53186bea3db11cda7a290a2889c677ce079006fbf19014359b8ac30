Object.defineProperty(exports, '__esModule', { value: true });

const utils = require('@sentry/utils');
const carrier = require('../carrier.js');
const currentScopes = require('../currentScopes.js');
const index = require('../asyncContext/index.js');
const debugBuild = require('../debug-build.js');
const semanticAttributes = require('../semanticAttributes.js');
const handleCallbackErrors = require('../utils/handleCallbackErrors.js');
const hasTracingEnabled = require('../utils/hasTracingEnabled.js');
const spanOnScope = require('../utils/spanOnScope.js');
const spanUtils = require('../utils/spanUtils.js');
const dynamicSamplingContext = require('./dynamicSamplingContext.js');
const logSpans = require('./logSpans.js');
const sampling = require('./sampling.js');
const sentryNonRecordingSpan = require('./sentryNonRecordingSpan.js');
const sentrySpan = require('./sentrySpan.js');
const spanstatus = require('./spanstatus.js');
const utils$1 = require('./utils.js');

const SUPPRESS_TRACING_KEY = '__SENTRY_SUPPRESS_TRACING__';

/**
 * Wraps a function with a transaction/span and finishes the span after the function is done.
 * The created span is the active span and will be used as parent by other spans created inside the function
 * and can be accessed via `Sentry.getActiveSpan()`, as long as the function is executed while the scope is active.
 *
 * If you want to create a span that is not set as active, use {@link startInactiveSpan}.
 *
 * You'll always get a span passed to the callback,
 * it may just be a non-recording span if the span is not sampled or if tracing is disabled.
 */
function startSpan(options, callback) {
  const acs = getAcs();
  if (acs.startSpan) {
    return acs.startSpan(options, callback);
  }

  const spanArguments = parseSentrySpanArguments(options);
  const { forceTransaction, parentSpan: customParentSpan } = options;

  return currentScopes.withScope(options.scope, () => {
    // If `options.parentSpan` is defined, we want to wrap the callback in `withActiveSpan`
    const wrapper = getActiveSpanWrapper(customParentSpan);

    return wrapper(() => {
      const scope = currentScopes.getCurrentScope();
      const parentSpan = getParentSpan(scope);

      const shouldSkipSpan = options.onlyIfParent && !parentSpan;
      const activeSpan = shouldSkipSpan
        ? new sentryNonRecordingSpan.SentryNonRecordingSpan()
        : createChildOrRootSpan({
            parentSpan,
            spanArguments,
            forceTransaction,
            scope,
          });

      spanOnScope._setSpanForScope(scope, activeSpan);

      return handleCallbackErrors.handleCallbackErrors(
        () => callback(activeSpan),
        () => {
          // Only update the span status if it hasn't been changed yet, and the span is not yet finished
          const { status } = spanUtils.spanToJSON(activeSpan);
          if (activeSpan.isRecording() && (!status || status === 'ok')) {
            activeSpan.setStatus({ code: spanstatus.SPAN_STATUS_ERROR, message: 'internal_error' });
          }
        },
        () => activeSpan.end(),
      );
    });
  });
}

/**
 * Similar to `Sentry.startSpan`. Wraps a function with a transaction/span, but does not finish the span
 * after the function is done automatically. You'll have to call `span.end()` manually.
 *
 * The created span is the active span and will be used as parent by other spans created inside the function
 * and can be accessed via `Sentry.getActiveSpan()`, as long as the function is executed while the scope is active.
 *
 * You'll always get a span passed to the callback,
 * it may just be a non-recording span if the span is not sampled or if tracing is disabled.
 */
function startSpanManual(options, callback) {
  const acs = getAcs();
  if (acs.startSpanManual) {
    return acs.startSpanManual(options, callback);
  }

  const spanArguments = parseSentrySpanArguments(options);
  const { forceTransaction, parentSpan: customParentSpan } = options;

  return currentScopes.withScope(options.scope, () => {
    // If `options.parentSpan` is defined, we want to wrap the callback in `withActiveSpan`
    const wrapper = getActiveSpanWrapper(customParentSpan);

    return wrapper(() => {
      const scope = currentScopes.getCurrentScope();
      const parentSpan = getParentSpan(scope);

      const shouldSkipSpan = options.onlyIfParent && !parentSpan;
      const activeSpan = shouldSkipSpan
        ? new sentryNonRecordingSpan.SentryNonRecordingSpan()
        : createChildOrRootSpan({
            parentSpan,
            spanArguments,
            forceTransaction,
            scope,
          });

      spanOnScope._setSpanForScope(scope, activeSpan);

      function finishAndSetSpan() {
        activeSpan.end();
      }

      return handleCallbackErrors.handleCallbackErrors(
        () => callback(activeSpan, finishAndSetSpan),
        () => {
          // Only update the span status if it hasn't been changed yet, and the span is not yet finished
          const { status } = spanUtils.spanToJSON(activeSpan);
          if (activeSpan.isRecording() && (!status || status === 'ok')) {
            activeSpan.setStatus({ code: spanstatus.SPAN_STATUS_ERROR, message: 'internal_error' });
          }
        },
      );
    });
  });
}

/**
 * Creates a span. This span is not set as active, so will not get automatic instrumentation spans
 * as children or be able to be accessed via `Sentry.getActiveSpan()`.
 *
 * If you want to create a span that is set as active, use {@link startSpan}.
 *
 * This function will always return a span,
 * it may just be a non-recording span if the span is not sampled or if tracing is disabled.
 */
function startInactiveSpan(options) {
  const acs = getAcs();
  if (acs.startInactiveSpan) {
    return acs.startInactiveSpan(options);
  }

  const spanArguments = parseSentrySpanArguments(options);
  const { forceTransaction, parentSpan: customParentSpan } = options;

  // If `options.scope` is defined, we use this as as a wrapper,
  // If `options.parentSpan` is defined, we want to wrap the callback in `withActiveSpan`
  const wrapper = options.scope
    ? (callback) => currentScopes.withScope(options.scope, callback)
    : customParentSpan !== undefined
      ? (callback) => withActiveSpan(customParentSpan, callback)
      : (callback) => callback();

  return wrapper(() => {
    const scope = currentScopes.getCurrentScope();
    const parentSpan = getParentSpan(scope);

    const shouldSkipSpan = options.onlyIfParent && !parentSpan;

    if (shouldSkipSpan) {
      return new sentryNonRecordingSpan.SentryNonRecordingSpan();
    }

    return createChildOrRootSpan({
      parentSpan,
      spanArguments,
      forceTransaction,
      scope,
    });
  });
}

/**
 * Continue a trace from `sentry-trace` and `baggage` values.
 * These values can be obtained from incoming request headers, or in the browser from `<meta name="sentry-trace">`
 * and `<meta name="baggage">` HTML tags.
 *
 * Spans started with `startSpan`, `startSpanManual` and `startInactiveSpan`, within the callback will automatically
 * be attached to the incoming trace.
 */
const continueTrace = (
  {
    sentryTrace,
    baggage,
  }

,
  callback,
) => {
  return currentScopes.withScope(scope => {
    const propagationContext = utils.propagationContextFromHeaders(sentryTrace, baggage);
    scope.setPropagationContext(propagationContext);
    return callback();
  });
};

/**
 * Forks the current scope and sets the provided span as active span in the context of the provided callback. Can be
 * passed `null` to start an entirely new span tree.
 *
 * @param span Spans started in the context of the provided callback will be children of this span. If `null` is passed,
 * spans started within the callback will not be attached to a parent span.
 * @param callback Execution context in which the provided span will be active. Is passed the newly forked scope.
 * @returns the value returned from the provided callback function.
 */
function withActiveSpan(span, callback) {
  const acs = getAcs();
  if (acs.withActiveSpan) {
    return acs.withActiveSpan(span, callback);
  }

  return currentScopes.withScope(scope => {
    spanOnScope._setSpanForScope(scope, span || undefined);
    return callback(scope);
  });
}

/** Suppress tracing in the given callback, ensuring no spans are generated inside of it. */
function suppressTracing(callback) {
  const acs = getAcs();

  if (acs.suppressTracing) {
    return acs.suppressTracing(callback);
  }

  return currentScopes.withScope(scope => {
    scope.setSDKProcessingMetadata({ [SUPPRESS_TRACING_KEY]: true });
    return callback();
  });
}

/**
 * Starts a new trace for the duration of the provided callback. Spans started within the
 * callback will be part of the new trace instead of a potentially previously started trace.
 *
 * Important: Only use this function if you want to override the default trace lifetime and
 * propagation mechanism of the SDK for the duration and scope of the provided callback.
 * The newly created trace will also be the root of a new distributed trace, for example if
 * you make http requests within the callback.
 * This function might be useful if the operation you want to instrument should not be part
 * of a potentially ongoing trace.
 *
 * Default behavior:
 * - Server-side: A new trace is started for each incoming request.
 * - Browser: A new trace is started for each page our route. Navigating to a new route
 *            or page will automatically create a new trace.
 */
function startNewTrace(callback) {
  return currentScopes.withScope(scope => {
    scope.setPropagationContext(utils.generatePropagationContext());
    debugBuild.DEBUG_BUILD && utils.logger.info(`Starting a new trace with id ${scope.getPropagationContext().traceId}`);
    return withActiveSpan(null, callback);
  });
}

function createChildOrRootSpan({
  parentSpan,
  spanArguments,
  forceTransaction,
  scope,
}

) {
  if (!hasTracingEnabled.hasTracingEnabled()) {
    return new sentryNonRecordingSpan.SentryNonRecordingSpan();
  }

  const isolationScope = currentScopes.getIsolationScope();

  let span;
  if (parentSpan && !forceTransaction) {
    span = _startChildSpan(parentSpan, scope, spanArguments);
    spanUtils.addChildSpanToSpan(parentSpan, span);
  } else if (parentSpan) {
    // If we forced a transaction but have a parent span, make sure to continue from the parent span, not the scope
    const dsc = dynamicSamplingContext.getDynamicSamplingContextFromSpan(parentSpan);
    const { traceId, spanId: parentSpanId } = parentSpan.spanContext();
    const parentSampled = spanUtils.spanIsSampled(parentSpan);

    span = _startRootSpan(
      {
        traceId,
        parentSpanId,
        ...spanArguments,
      },
      scope,
      parentSampled,
    );

    dynamicSamplingContext.freezeDscOnSpan(span, dsc);
  } else {
    const {
      traceId,
      dsc,
      parentSpanId,
      sampled: parentSampled,
    } = {
      ...isolationScope.getPropagationContext(),
      ...scope.getPropagationContext(),
    };

    span = _startRootSpan(
      {
        traceId,
        parentSpanId,
        ...spanArguments,
      },
      scope,
      parentSampled,
    );

    if (dsc) {
      dynamicSamplingContext.freezeDscOnSpan(span, dsc);
    }
  }

  logSpans.logSpanStart(span);

  utils$1.setCapturedScopesOnSpan(span, scope, isolationScope);

  return span;
}

/**
 * This converts StartSpanOptions to SentrySpanArguments.
 * For the most part (for now) we accept the same options,
 * but some of them need to be transformed.
 */
function parseSentrySpanArguments(options) {
  const exp = options.experimental || {};
  const initialCtx = {
    isStandalone: exp.standalone,
    ...options,
  };

  if (options.startTime) {
    const ctx = { ...initialCtx };
    ctx.startTimestamp = spanUtils.spanTimeInputToSeconds(options.startTime);
    delete ctx.startTime;
    return ctx;
  }

  return initialCtx;
}

function getAcs() {
  const carrier$1 = carrier.getMainCarrier();
  return index.getAsyncContextStrategy(carrier$1);
}

function _startRootSpan(spanArguments, scope, parentSampled) {
  const client = currentScopes.getClient();
  const options = (client && client.getOptions()) || {};

  const { name = '', attributes } = spanArguments;
  const [sampled, sampleRate] = scope.getScopeData().sdkProcessingMetadata[SUPPRESS_TRACING_KEY]
    ? [false]
    : sampling.sampleSpan(options, {
        name,
        parentSampled,
        attributes,
        transactionContext: {
          name,
          parentSampled,
        },
      });

  const rootSpan = new sentrySpan.SentrySpan({
    ...spanArguments,
    attributes: {
      [semanticAttributes.SEMANTIC_ATTRIBUTE_SENTRY_SOURCE]: 'custom',
      ...spanArguments.attributes,
    },
    sampled,
  });
  if (sampleRate !== undefined) {
    rootSpan.setAttribute(semanticAttributes.SEMANTIC_ATTRIBUTE_SENTRY_SAMPLE_RATE, sampleRate);
  }

  if (client) {
    client.emit('spanStart', rootSpan);
  }

  return rootSpan;
}

/**
 * Creates a new `Span` while setting the current `Span.id` as `parentSpanId`.
 * This inherits the sampling decision from the parent span.
 */
function _startChildSpan(parentSpan, scope, spanArguments) {
  const { spanId, traceId } = parentSpan.spanContext();
  const sampled = scope.getScopeData().sdkProcessingMetadata[SUPPRESS_TRACING_KEY] ? false : spanUtils.spanIsSampled(parentSpan);

  const childSpan = sampled
    ? new sentrySpan.SentrySpan({
        ...spanArguments,
        parentSpanId: spanId,
        traceId,
        sampled,
      })
    : new sentryNonRecordingSpan.SentryNonRecordingSpan({ traceId });

  spanUtils.addChildSpanToSpan(parentSpan, childSpan);

  const client = currentScopes.getClient();
  if (client) {
    client.emit('spanStart', childSpan);
    // If it has an endTimestamp, it's already ended
    if (spanArguments.endTimestamp) {
      client.emit('spanEnd', childSpan);
    }
  }

  return childSpan;
}

function getParentSpan(scope) {
  const span = spanOnScope._getSpanForScope(scope) ;

  if (!span) {
    return undefined;
  }

  const client = currentScopes.getClient();
  const options = client ? client.getOptions() : {};
  if (options.parentSpanIsAlwaysRootSpan) {
    return spanUtils.getRootSpan(span) ;
  }

  return span;
}

function getActiveSpanWrapper(parentSpan) {
  return parentSpan !== undefined
    ? (callback) => {
        return withActiveSpan(parentSpan, callback);
      }
    : (callback) => callback();
}

exports.continueTrace = continueTrace;
exports.startInactiveSpan = startInactiveSpan;
exports.startNewTrace = startNewTrace;
exports.startSpan = startSpan;
exports.startSpanManual = startSpanManual;
exports.suppressTracing = suppressTracing;
exports.withActiveSpan = withActiveSpan;
//# sourceMappingURL=trace.js.map
