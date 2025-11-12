Object.defineProperty(exports, '__esModule', { value: true });

const browserUtils = require('@sentry-internal/browser-utils');
const core = require('@sentry/core');
const utils = require('@sentry/utils');
const debugBuild = require('../debug-build.js');
const helpers = require('../helpers.js');
const backgroundtab = require('./backgroundtab.js');
const request = require('./request.js');

/* eslint-disable max-lines */

const BROWSER_TRACING_INTEGRATION_ID = 'BrowserTracing';

const DEFAULT_BROWSER_TRACING_OPTIONS = {
  ...core.TRACING_DEFAULTS,
  instrumentNavigation: true,
  instrumentPageLoad: true,
  markBackgroundSpan: true,
  enableLongTask: true,
  enableLongAnimationFrame: true,
  enableInp: true,
  _experiments: {},
  ...request.defaultRequestInstrumentationOptions,
};

/**
 * The Browser Tracing integration automatically instruments browser pageload/navigation
 * actions as transactions, and captures requests, metrics and errors as spans.
 *
 * The integration can be configured with a variety of options, and can be extended to use
 * any routing library.
 *
 * We explicitly export the proper type here, as this has to be extended in some cases.
 */
const browserTracingIntegration = ((_options = {}) => {
  core.registerSpanErrorInstrumentation();

  const {
    enableInp,
    enableLongTask,
    enableLongAnimationFrame,
    _experiments: { enableInteractions, enableStandaloneClsSpans },
    beforeStartSpan,
    idleTimeout,
    finalTimeout,
    childSpanTimeout,
    markBackgroundSpan,
    traceFetch,
    traceXHR,
    shouldCreateSpanForRequest,
    enableHTTPTimings,
    instrumentPageLoad,
    instrumentNavigation,
  } = {
    ...DEFAULT_BROWSER_TRACING_OPTIONS,
    ..._options,
  };

  const _collectWebVitals = browserUtils.startTrackingWebVitals({ recordClsStandaloneSpans: enableStandaloneClsSpans || false });

  if (enableInp) {
    browserUtils.startTrackingINP();
  }

  if (
    enableLongAnimationFrame &&
    utils.GLOBAL_OBJ.PerformanceObserver &&
    PerformanceObserver.supportedEntryTypes &&
    PerformanceObserver.supportedEntryTypes.includes('long-animation-frame')
  ) {
    browserUtils.startTrackingLongAnimationFrames();
  } else if (enableLongTask) {
    browserUtils.startTrackingLongTasks();
  }

  if (enableInteractions) {
    browserUtils.startTrackingInteractions();
  }

  const latestRoute = {
    name: undefined,
    source: undefined,
  };

  /** Create routing idle transaction. */
  function _createRouteSpan(client, startSpanOptions) {
    const isPageloadTransaction = startSpanOptions.op === 'pageload';

    const finalStartSpanOptions = beforeStartSpan
      ? beforeStartSpan(startSpanOptions)
      : startSpanOptions;

    const attributes = finalStartSpanOptions.attributes || {};

    // If `finalStartSpanOptions.name` is different than `startSpanOptions.name`
    // it is because `beforeStartSpan` set a custom name. Therefore we set the source to 'custom'.
    if (startSpanOptions.name !== finalStartSpanOptions.name) {
      attributes[core.SEMANTIC_ATTRIBUTE_SENTRY_SOURCE] = 'custom';
      finalStartSpanOptions.attributes = attributes;
    }

    latestRoute.name = finalStartSpanOptions.name;
    latestRoute.source = attributes[core.SEMANTIC_ATTRIBUTE_SENTRY_SOURCE];

    const idleSpan = core.startIdleSpan(finalStartSpanOptions, {
      idleTimeout,
      finalTimeout,
      childSpanTimeout,
      // should wait for finish signal if it's a pageload transaction
      disableAutoFinish: isPageloadTransaction,
      beforeSpanEnd: span => {
        _collectWebVitals();
        browserUtils.addPerformanceEntries(span, { recordClsOnPageloadSpan: !enableStandaloneClsSpans });
      },
    });

    function emitFinish() {
      if (['interactive', 'complete'].includes(helpers.WINDOW.document.readyState)) {
        client.emit('idleSpanEnableAutoFinish', idleSpan);
      }
    }

    if (isPageloadTransaction && helpers.WINDOW.document) {
      helpers.WINDOW.document.addEventListener('readystatechange', () => {
        emitFinish();
      });

      emitFinish();
    }

    return idleSpan;
  }

  return {
    name: BROWSER_TRACING_INTEGRATION_ID,
    afterAllSetup(client) {
      let activeSpan;
      let startingUrl = helpers.WINDOW.location && helpers.WINDOW.location.href;

      client.on('startNavigationSpan', startSpanOptions => {
        if (core.getClient() !== client) {
          return;
        }

        if (activeSpan && !core.spanToJSON(activeSpan).timestamp) {
          debugBuild.DEBUG_BUILD && utils.logger.log(`[Tracing] Finishing current root span with op: ${core.spanToJSON(activeSpan).op}`);
          // If there's an open transaction on the scope, we need to finish it before creating an new one.
          activeSpan.end();
        }

        activeSpan = _createRouteSpan(client, {
          op: 'navigation',
          ...startSpanOptions,
        });
      });

      client.on('startPageLoadSpan', (startSpanOptions, traceOptions = {}) => {
        if (core.getClient() !== client) {
          return;
        }

        if (activeSpan && !core.spanToJSON(activeSpan).timestamp) {
          debugBuild.DEBUG_BUILD && utils.logger.log(`[Tracing] Finishing current root span with op: ${core.spanToJSON(activeSpan).op}`);
          // If there's an open transaction on the scope, we need to finish it before creating an new one.
          activeSpan.end();
        }

        const sentryTrace = traceOptions.sentryTrace || getMetaContent('sentry-trace');
        const baggage = traceOptions.baggage || getMetaContent('baggage');

        const propagationContext = utils.propagationContextFromHeaders(sentryTrace, baggage);
        core.getCurrentScope().setPropagationContext(propagationContext);

        activeSpan = _createRouteSpan(client, {
          op: 'pageload',
          ...startSpanOptions,
        });
      });

      // A trace should to stay the consistent over the entire time span of one route.
      // Therefore, when the initial pageload or navigation root span ends, we update the
      // scope's propagation context to keep span-specific attributes like the `sampled` decision and
      // the dynamic sampling context valid, even after the root span has ended.
      // This ensures that the trace data is consistent for the entire duration of the route.
      client.on('spanEnd', span => {
        const op = core.spanToJSON(span).op;
        if (span !== core.getRootSpan(span) || (op !== 'navigation' && op !== 'pageload')) {
          return;
        }

        const scope = core.getCurrentScope();
        const oldPropagationContext = scope.getPropagationContext();

        scope.setPropagationContext({
          ...oldPropagationContext,
          sampled: oldPropagationContext.sampled !== undefined ? oldPropagationContext.sampled : core.spanIsSampled(span),
          dsc: oldPropagationContext.dsc || core.getDynamicSamplingContextFromSpan(span),
        });
      });

      if (helpers.WINDOW.location) {
        if (instrumentPageLoad) {
          startBrowserTracingPageLoadSpan(client, {
            name: helpers.WINDOW.location.pathname,
            // pageload should always start at timeOrigin (and needs to be in s, not ms)
            startTime: utils.browserPerformanceTimeOrigin ? utils.browserPerformanceTimeOrigin / 1000 : undefined,
            attributes: {
              [core.SEMANTIC_ATTRIBUTE_SENTRY_SOURCE]: 'url',
              [core.SEMANTIC_ATTRIBUTE_SENTRY_ORIGIN]: 'auto.pageload.browser',
            },
          });
        }

        if (instrumentNavigation) {
          browserUtils.addHistoryInstrumentationHandler(({ to, from }) => {
            /**
             * This early return is there to account for some cases where a navigation transaction starts right after
             * long-running pageload. We make sure that if `from` is undefined and a valid `startingURL` exists, we don't
             * create an uneccessary navigation transaction.
             *
             * This was hard to duplicate, but this behavior stopped as soon as this fix was applied. This issue might also
             * only be caused in certain development environments where the usage of a hot module reloader is causing
             * errors.
             */
            if (from === undefined && startingUrl && startingUrl.indexOf(to) !== -1) {
              startingUrl = undefined;
              return;
            }

            if (from !== to) {
              startingUrl = undefined;
              startBrowserTracingNavigationSpan(client, {
                name: helpers.WINDOW.location.pathname,
                attributes: {
                  [core.SEMANTIC_ATTRIBUTE_SENTRY_SOURCE]: 'url',
                  [core.SEMANTIC_ATTRIBUTE_SENTRY_ORIGIN]: 'auto.navigation.browser',
                },
              });
            }
          });
        }
      }

      if (markBackgroundSpan) {
        backgroundtab.registerBackgroundTabDetection();
      }

      if (enableInteractions) {
        registerInteractionListener(idleTimeout, finalTimeout, childSpanTimeout, latestRoute);
      }

      if (enableInp) {
        browserUtils.registerInpInteractionListener();
      }

      request.instrumentOutgoingRequests(client, {
        traceFetch,
        traceXHR,
        tracePropagationTargets: client.getOptions().tracePropagationTargets,
        shouldCreateSpanForRequest,
        enableHTTPTimings,
      });
    },
  };
}) ;

/**
 * Manually start a page load span.
 * This will only do something if a browser tracing integration integration has been setup.
 *
 * If you provide a custom `traceOptions` object, it will be used to continue the trace
 * instead of the default behavior, which is to look it up on the <meta> tags.
 */
function startBrowserTracingPageLoadSpan(
  client,
  spanOptions,
  traceOptions,
) {
  client.emit('startPageLoadSpan', spanOptions, traceOptions);

  core.getCurrentScope().setTransactionName(spanOptions.name);

  const span = core.getActiveSpan();
  const op = span && core.spanToJSON(span).op;
  return op === 'pageload' ? span : undefined;
}

/**
 * Manually start a navigation span.
 * This will only do something if a browser tracing integration has been setup.
 */
function startBrowserTracingNavigationSpan(client, spanOptions) {
  core.getIsolationScope().setPropagationContext(utils.generatePropagationContext());
  core.getCurrentScope().setPropagationContext(utils.generatePropagationContext());

  client.emit('startNavigationSpan', spanOptions);

  core.getCurrentScope().setTransactionName(spanOptions.name);

  const span = core.getActiveSpan();
  const op = span && core.spanToJSON(span).op;
  return op === 'navigation' ? span : undefined;
}

/** Returns the value of a meta tag */
function getMetaContent(metaName) {
  // Can't specify generic to `getDomElement` because tracing can be used
  // in a variety of environments, have to disable `no-unsafe-member-access`
  // as a result.
  const metaTag = utils.getDomElement(`meta[name=${metaName}]`);
  // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
  return metaTag ? metaTag.getAttribute('content') : undefined;
}

/** Start listener for interaction transactions */
function registerInteractionListener(
  idleTimeout,
  finalTimeout,
  childSpanTimeout,
  latestRoute,
) {
  let inflightInteractionSpan;
  const registerInteractionTransaction = () => {
    const op = 'ui.action.click';

    const activeSpan = core.getActiveSpan();
    const rootSpan = activeSpan && core.getRootSpan(activeSpan);
    if (rootSpan) {
      const currentRootSpanOp = core.spanToJSON(rootSpan).op;
      if (['navigation', 'pageload'].includes(currentRootSpanOp )) {
        debugBuild.DEBUG_BUILD &&
          utils.logger.warn(`[Tracing] Did not create ${op} span because a pageload or navigation span is in progress.`);
        return undefined;
      }
    }

    if (inflightInteractionSpan) {
      inflightInteractionSpan.setAttribute(core.SEMANTIC_ATTRIBUTE_SENTRY_IDLE_SPAN_FINISH_REASON, 'interactionInterrupted');
      inflightInteractionSpan.end();
      inflightInteractionSpan = undefined;
    }

    if (!latestRoute.name) {
      debugBuild.DEBUG_BUILD && utils.logger.warn(`[Tracing] Did not create ${op} transaction because _latestRouteName is missing.`);
      return undefined;
    }

    inflightInteractionSpan = core.startIdleSpan(
      {
        name: latestRoute.name,
        op,
        attributes: {
          [core.SEMANTIC_ATTRIBUTE_SENTRY_SOURCE]: latestRoute.source || 'url',
        },
      },
      {
        idleTimeout,
        finalTimeout,
        childSpanTimeout,
      },
    );
  };

  if (helpers.WINDOW.document) {
    addEventListener('click', registerInteractionTransaction, { once: false, capture: true });
  }
}

exports.BROWSER_TRACING_INTEGRATION_ID = BROWSER_TRACING_INTEGRATION_ID;
exports.browserTracingIntegration = browserTracingIntegration;
exports.getMetaContent = getMetaContent;
exports.startBrowserTracingNavigationSpan = startBrowserTracingNavigationSpan;
exports.startBrowserTracingPageLoadSpan = startBrowserTracingPageLoadSpan;
//# sourceMappingURL=browserTracingIntegration.js.map
