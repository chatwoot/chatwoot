var {
  _optionalChain
} = require('@sentry/utils');

Object.defineProperty(exports, '__esModule', { value: true });

const core = require('@sentry/core');
const utils = require('@sentry/utils');
const debugBuild = require('../debug-build.js');
const instrument = require('./instrument.js');
const utils$1 = require('./utils.js');
const onHidden = require('./web-vitals/lib/onHidden.js');

/**
 * Starts tracking the Cumulative Layout Shift on the current page and collects the value once
 *
 * - the page visibility is hidden
 * - a navigation span is started (to stop CLS measurement for SPA soft navigations)
 *
 * Once either of these events triggers, the CLS value is sent as a standalone span and we stop
 * measuring CLS.
 */
function trackClsAsStandaloneSpan() {
  let standaloneCLsValue = 0;
  let standaloneClsEntry;
  let pageloadSpanId;

  if (!supportsLayoutShift()) {
    return;
  }

  let sentSpan = false;
  function _collectClsOnce() {
    if (sentSpan) {
      return;
    }
    sentSpan = true;
    if (pageloadSpanId) {
      sendStandaloneClsSpan(standaloneCLsValue, standaloneClsEntry, pageloadSpanId);
    }
    cleanupClsHandler();
  }

  const cleanupClsHandler = instrument.addClsInstrumentationHandler(({ metric }) => {
    const entry = metric.entries[metric.entries.length - 1] ;
    if (!entry) {
      return;
    }
    standaloneCLsValue = metric.value;
    standaloneClsEntry = entry;
  }, true);

  // use pagehide event from web-vitals
  onHidden.onHidden(() => {
    _collectClsOnce();
  });

  // Since the call chain of this function is synchronous and evaluates before the SDK client is created,
  // we need to wait with subscribing to a client hook until the client is created. Therefore, we defer
  // to the next tick after the SDK setup.
  setTimeout(() => {
    const client = core.getClient();

    const unsubscribeStartNavigation = _optionalChain([client, 'optionalAccess', _ => _.on, 'call', _2 => _2('startNavigationSpan', () => {
      _collectClsOnce();
      unsubscribeStartNavigation && unsubscribeStartNavigation();
    })]);

    const activeSpan = core.getActiveSpan();
    const rootSpan = activeSpan && core.getRootSpan(activeSpan);
    const spanJSON = rootSpan && core.spanToJSON(rootSpan);
    if (spanJSON && spanJSON.op === 'pageload') {
      pageloadSpanId = rootSpan.spanContext().spanId;
    }
  }, 0);
}

function sendStandaloneClsSpan(clsValue, entry, pageloadSpanId) {
  debugBuild.DEBUG_BUILD && utils.logger.log(`Sending CLS span (${clsValue})`);

  const startTime = utils$1.msToSec((utils.browserPerformanceTimeOrigin || 0) + (_optionalChain([entry, 'optionalAccess', _3 => _3.startTime]) || 0));
  const routeName = core.getCurrentScope().getScopeData().transactionName;

  const name = entry ? utils.htmlTreeAsString(_optionalChain([entry, 'access', _4 => _4.sources, 'access', _5 => _5[0], 'optionalAccess', _6 => _6.node])) : 'Layout shift';

  const attributes = utils.dropUndefinedKeys({
    [core.SEMANTIC_ATTRIBUTE_SENTRY_ORIGIN]: 'auto.http.browser.cls',
    [core.SEMANTIC_ATTRIBUTE_SENTRY_OP]: 'ui.webvital.cls',
    [core.SEMANTIC_ATTRIBUTE_EXCLUSIVE_TIME]: _optionalChain([entry, 'optionalAccess', _7 => _7.duration]) || 0,
    // attach the pageload span id to the CLS span so that we can link them in the UI
    'sentry.pageload.span_id': pageloadSpanId,
  });

  const span = utils$1.startStandaloneWebVitalSpan({
    name,
    transaction: routeName,
    attributes,
    startTime,
  });

  _optionalChain([span, 'optionalAccess', _8 => _8.addEvent, 'call', _9 => _9('cls', {
    [core.SEMANTIC_ATTRIBUTE_SENTRY_MEASUREMENT_UNIT]: '',
    [core.SEMANTIC_ATTRIBUTE_SENTRY_MEASUREMENT_VALUE]: clsValue,
  })]);

  // LayoutShift performance entries always have a duration of 0, so we don't need to add `entry.duration` here
  // see: https://developer.mozilla.org/en-US/docs/Web/API/PerformanceEntry/duration
  _optionalChain([span, 'optionalAccess', _10 => _10.end, 'call', _11 => _11(startTime)]);
}

function supportsLayoutShift() {
  try {
    return _optionalChain([PerformanceObserver, 'access', _12 => _12.supportedEntryTypes, 'optionalAccess', _13 => _13.includes, 'call', _14 => _14('layout-shift')]);
  } catch (e) {
    return false;
  }
}

exports.trackClsAsStandaloneSpan = trackClsAsStandaloneSpan;
//# sourceMappingURL=cls.js.map
