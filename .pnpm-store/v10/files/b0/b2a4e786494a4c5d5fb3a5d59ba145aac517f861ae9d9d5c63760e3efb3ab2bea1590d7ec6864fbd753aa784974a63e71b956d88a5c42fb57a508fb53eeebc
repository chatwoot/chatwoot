import { _optionalChain } from '@sentry/utils';
import { getClient, getActiveSpan, getRootSpan, spanToJSON, getCurrentScope, SEMANTIC_ATTRIBUTE_SENTRY_ORIGIN, SEMANTIC_ATTRIBUTE_SENTRY_OP, SEMANTIC_ATTRIBUTE_EXCLUSIVE_TIME, SEMANTIC_ATTRIBUTE_SENTRY_MEASUREMENT_UNIT, SEMANTIC_ATTRIBUTE_SENTRY_MEASUREMENT_VALUE } from '@sentry/core';
import { logger, browserPerformanceTimeOrigin, htmlTreeAsString, dropUndefinedKeys } from '@sentry/utils';
import { DEBUG_BUILD } from '../debug-build.js';
import { addClsInstrumentationHandler } from './instrument.js';
import { msToSec, startStandaloneWebVitalSpan } from './utils.js';
import { onHidden } from './web-vitals/lib/onHidden.js';

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

  const cleanupClsHandler = addClsInstrumentationHandler(({ metric }) => {
    const entry = metric.entries[metric.entries.length - 1] ;
    if (!entry) {
      return;
    }
    standaloneCLsValue = metric.value;
    standaloneClsEntry = entry;
  }, true);

  // use pagehide event from web-vitals
  onHidden(() => {
    _collectClsOnce();
  });

  // Since the call chain of this function is synchronous and evaluates before the SDK client is created,
  // we need to wait with subscribing to a client hook until the client is created. Therefore, we defer
  // to the next tick after the SDK setup.
  setTimeout(() => {
    const client = getClient();

    const unsubscribeStartNavigation = _optionalChain([client, 'optionalAccess', _ => _.on, 'call', _2 => _2('startNavigationSpan', () => {
      _collectClsOnce();
      unsubscribeStartNavigation && unsubscribeStartNavigation();
    })]);

    const activeSpan = getActiveSpan();
    const rootSpan = activeSpan && getRootSpan(activeSpan);
    const spanJSON = rootSpan && spanToJSON(rootSpan);
    if (spanJSON && spanJSON.op === 'pageload') {
      pageloadSpanId = rootSpan.spanContext().spanId;
    }
  }, 0);
}

function sendStandaloneClsSpan(clsValue, entry, pageloadSpanId) {
  DEBUG_BUILD && logger.log(`Sending CLS span (${clsValue})`);

  const startTime = msToSec((browserPerformanceTimeOrigin || 0) + (_optionalChain([entry, 'optionalAccess', _3 => _3.startTime]) || 0));
  const routeName = getCurrentScope().getScopeData().transactionName;

  const name = entry ? htmlTreeAsString(_optionalChain([entry, 'access', _4 => _4.sources, 'access', _5 => _5[0], 'optionalAccess', _6 => _6.node])) : 'Layout shift';

  const attributes = dropUndefinedKeys({
    [SEMANTIC_ATTRIBUTE_SENTRY_ORIGIN]: 'auto.http.browser.cls',
    [SEMANTIC_ATTRIBUTE_SENTRY_OP]: 'ui.webvital.cls',
    [SEMANTIC_ATTRIBUTE_EXCLUSIVE_TIME]: _optionalChain([entry, 'optionalAccess', _7 => _7.duration]) || 0,
    // attach the pageload span id to the CLS span so that we can link them in the UI
    'sentry.pageload.span_id': pageloadSpanId,
  });

  const span = startStandaloneWebVitalSpan({
    name,
    transaction: routeName,
    attributes,
    startTime,
  });

  _optionalChain([span, 'optionalAccess', _8 => _8.addEvent, 'call', _9 => _9('cls', {
    [SEMANTIC_ATTRIBUTE_SENTRY_MEASUREMENT_UNIT]: '',
    [SEMANTIC_ATTRIBUTE_SENTRY_MEASUREMENT_VALUE]: clsValue,
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

export { trackClsAsStandaloneSpan };
//# sourceMappingURL=cls.js.map
