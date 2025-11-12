Object.defineProperty(exports, '__esModule', { value: true });

const core = require('@sentry/core');
const utils$1 = require('@sentry/utils');
const debugBuild = require('../debug-build.js');
const types = require('../types.js');
const cls = require('./cls.js');
const instrument = require('./instrument.js');
const utils = require('./utils.js');
const getActivationStart = require('./web-vitals/lib/getActivationStart.js');
const getNavigationEntry = require('./web-vitals/lib/getNavigationEntry.js');
const getVisibilityWatcher = require('./web-vitals/lib/getVisibilityWatcher.js');

/* eslint-disable max-lines */

const MAX_INT_AS_BYTES = 2147483647;

let _performanceCursor = 0;

let _measurements = {};
let _lcpEntry;
let _clsEntry;

/**
 * Start tracking web vitals.
 * The callback returned by this function can be used to stop tracking & ensure all measurements are final & captured.
 *
 * @returns A function that forces web vitals collection
 */
function startTrackingWebVitals({ recordClsStandaloneSpans }) {
  const performance = utils.getBrowserPerformanceAPI();
  if (performance && utils$1.browserPerformanceTimeOrigin) {
    // @ts-expect-error we want to make sure all of these are available, even if TS is sure they are
    if (performance.mark) {
      types.WINDOW.performance.mark('sentry-tracing-init');
    }
    const fidCleanupCallback = _trackFID();
    const lcpCleanupCallback = _trackLCP();
    const ttfbCleanupCallback = _trackTtfb();
    const clsCleanupCallback = recordClsStandaloneSpans ? cls.trackClsAsStandaloneSpan() : _trackCLS();

    return () => {
      fidCleanupCallback();
      lcpCleanupCallback();
      ttfbCleanupCallback();
      clsCleanupCallback && clsCleanupCallback();
    };
  }

  return () => undefined;
}

/**
 * Start tracking long tasks.
 */
function startTrackingLongTasks() {
  instrument.addPerformanceInstrumentationHandler('longtask', ({ entries }) => {
    if (!core.getActiveSpan()) {
      return;
    }
    for (const entry of entries) {
      const startTime = utils.msToSec((utils$1.browserPerformanceTimeOrigin ) + entry.startTime);
      const duration = utils.msToSec(entry.duration);

      const span = core.startInactiveSpan({
        name: 'Main UI thread blocked',
        op: 'ui.long-task',
        startTime,
        attributes: {
          [core.SEMANTIC_ATTRIBUTE_SENTRY_ORIGIN]: 'auto.ui.browser.metrics',
        },
      });
      if (span) {
        span.end(startTime + duration);
      }
    }
  });
}

/**
 * Start tracking long animation frames.
 */
function startTrackingLongAnimationFrames() {
  // NOTE: the current web-vitals version (3.5.2) does not support long-animation-frame, so
  // we directly observe `long-animation-frame` events instead of through the web-vitals
  // `observe` helper function.
  const observer = new PerformanceObserver(list => {
    if (!core.getActiveSpan()) {
      return;
    }
    for (const entry of list.getEntries() ) {
      if (!entry.scripts[0]) {
        continue;
      }

      const startTime = utils.msToSec((utils$1.browserPerformanceTimeOrigin ) + entry.startTime);
      const duration = utils.msToSec(entry.duration);

      const attributes = {
        [core.SEMANTIC_ATTRIBUTE_SENTRY_ORIGIN]: 'auto.ui.browser.metrics',
      };

      const initialScript = entry.scripts[0];
      const { invoker, invokerType, sourceURL, sourceFunctionName, sourceCharPosition } = initialScript;
      attributes['browser.script.invoker'] = invoker;
      attributes['browser.script.invoker_type'] = invokerType;
      if (sourceURL) {
        attributes['code.filepath'] = sourceURL;
      }
      if (sourceFunctionName) {
        attributes['code.function'] = sourceFunctionName;
      }
      if (sourceCharPosition !== -1) {
        attributes['browser.script.source_char_position'] = sourceCharPosition;
      }

      const span = core.startInactiveSpan({
        name: 'Main UI thread blocked',
        op: 'ui.long-animation-frame',
        startTime,
        attributes,
      });
      if (span) {
        span.end(startTime + duration);
      }
    }
  });

  observer.observe({ type: 'long-animation-frame', buffered: true });
}

/**
 * Start tracking interaction events.
 */
function startTrackingInteractions() {
  instrument.addPerformanceInstrumentationHandler('event', ({ entries }) => {
    if (!core.getActiveSpan()) {
      return;
    }
    for (const entry of entries) {
      if (entry.name === 'click') {
        const startTime = utils.msToSec((utils$1.browserPerformanceTimeOrigin ) + entry.startTime);
        const duration = utils.msToSec(entry.duration);

        const spanOptions = {
          name: utils$1.htmlTreeAsString(entry.target),
          op: `ui.interaction.${entry.name}`,
          startTime: startTime,
          attributes: {
            [core.SEMANTIC_ATTRIBUTE_SENTRY_ORIGIN]: 'auto.ui.browser.metrics',
          },
        };

        const componentName = utils$1.getComponentName(entry.target);
        if (componentName) {
          spanOptions.attributes['ui.component_name'] = componentName;
        }

        const span = core.startInactiveSpan(spanOptions);
        if (span) {
          span.end(startTime + duration);
        }
      }
    }
  });
}

/**
 * Starts tracking the Cumulative Layout Shift on the current page and collects the value and last entry
 * to the `_measurements` object which ultimately is applied to the pageload span's measurements.
 */
function _trackCLS() {
  return instrument.addClsInstrumentationHandler(({ metric }) => {
    const entry = metric.entries[metric.entries.length - 1] ;
    if (!entry) {
      return;
    }
    debugBuild.DEBUG_BUILD && utils$1.logger.log(`[Measurements] Adding CLS ${metric.value}`);
    _measurements['cls'] = { value: metric.value, unit: '' };
    _clsEntry = entry;
  }, true);
}

/** Starts tracking the Largest Contentful Paint on the current page. */
function _trackLCP() {
  return instrument.addLcpInstrumentationHandler(({ metric }) => {
    const entry = metric.entries[metric.entries.length - 1];
    if (!entry) {
      return;
    }

    debugBuild.DEBUG_BUILD && utils$1.logger.log('[Measurements] Adding LCP');
    _measurements['lcp'] = { value: metric.value, unit: 'millisecond' };
    _lcpEntry = entry ;
  }, true);
}

/** Starts tracking the First Input Delay on the current page. */
function _trackFID() {
  return instrument.addFidInstrumentationHandler(({ metric }) => {
    const entry = metric.entries[metric.entries.length - 1];
    if (!entry) {
      return;
    }

    const timeOrigin = utils.msToSec(utils$1.browserPerformanceTimeOrigin );
    const startTime = utils.msToSec(entry.startTime);
    debugBuild.DEBUG_BUILD && utils$1.logger.log('[Measurements] Adding FID');
    _measurements['fid'] = { value: metric.value, unit: 'millisecond' };
    _measurements['mark.fid'] = { value: timeOrigin + startTime, unit: 'second' };
  });
}

function _trackTtfb() {
  return instrument.addTtfbInstrumentationHandler(({ metric }) => {
    const entry = metric.entries[metric.entries.length - 1];
    if (!entry) {
      return;
    }

    debugBuild.DEBUG_BUILD && utils$1.logger.log('[Measurements] Adding TTFB');
    _measurements['ttfb'] = { value: metric.value, unit: 'millisecond' };
  });
}

/** Add performance related spans to a transaction */
function addPerformanceEntries(span, options) {
  const performance = utils.getBrowserPerformanceAPI();
  if (!performance || !types.WINDOW.performance.getEntries || !utils$1.browserPerformanceTimeOrigin) {
    // Gatekeeper if performance API not available
    return;
  }

  debugBuild.DEBUG_BUILD && utils$1.logger.log('[Tracing] Adding & adjusting spans using Performance API');
  const timeOrigin = utils.msToSec(utils$1.browserPerformanceTimeOrigin);

  const performanceEntries = performance.getEntries();

  const { op, start_timestamp: transactionStartTime } = core.spanToJSON(span);

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  performanceEntries.slice(_performanceCursor).forEach((entry) => {
    const startTime = utils.msToSec(entry.startTime);
    const duration = utils.msToSec(
      // Inexplicably, Chrome sometimes emits a negative duration. We need to work around this.
      // There is a SO post attempting to explain this, but it leaves one with open questions: https://stackoverflow.com/questions/23191918/peformance-getentries-and-negative-duration-display
      // The way we clamp the value is probably not accurate, since we have observed this happen for things that may take a while to load, like for example the replay worker.
      // TODO: Investigate why this happens and how to properly mitigate. For now, this is a workaround to prevent transactions being dropped due to negative duration spans.
      Math.max(0, entry.duration),
    );

    if (op === 'navigation' && transactionStartTime && timeOrigin + startTime < transactionStartTime) {
      return;
    }

    switch (entry.entryType) {
      case 'navigation': {
        _addNavigationSpans(span, entry, timeOrigin);
        break;
      }
      case 'mark':
      case 'paint':
      case 'measure': {
        _addMeasureSpans(span, entry, startTime, duration, timeOrigin);

        // capture web vitals
        const firstHidden = getVisibilityWatcher.getVisibilityWatcher();
        // Only report if the page wasn't hidden prior to the web vital.
        const shouldRecord = entry.startTime < firstHidden.firstHiddenTime;

        if (entry.name === 'first-paint' && shouldRecord) {
          debugBuild.DEBUG_BUILD && utils$1.logger.log('[Measurements] Adding FP');
          _measurements['fp'] = { value: entry.startTime, unit: 'millisecond' };
        }
        if (entry.name === 'first-contentful-paint' && shouldRecord) {
          debugBuild.DEBUG_BUILD && utils$1.logger.log('[Measurements] Adding FCP');
          _measurements['fcp'] = { value: entry.startTime, unit: 'millisecond' };
        }
        break;
      }
      case 'resource': {
        _addResourceSpans(span, entry, entry.name , startTime, duration, timeOrigin);
        break;
      }
      // Ignore other entry types.
    }
  });

  _performanceCursor = Math.max(performanceEntries.length - 1, 0);

  _trackNavigator(span);

  // Measurements are only available for pageload transactions
  if (op === 'pageload') {
    _addTtfbRequestTimeToMeasurements(_measurements);

    const fidMark = _measurements['mark.fid'];
    if (fidMark && _measurements['fid']) {
      // create span for FID
      utils.startAndEndSpan(span, fidMark.value, fidMark.value + utils.msToSec(_measurements['fid'].value), {
        name: 'first input delay',
        op: 'ui.action',
        attributes: {
          [core.SEMANTIC_ATTRIBUTE_SENTRY_ORIGIN]: 'auto.ui.browser.metrics',
        },
      });

      // Delete mark.fid as we don't want it to be part of final payload
      delete _measurements['mark.fid'];
    }

    // If FCP is not recorded we should not record the cls value
    // according to the new definition of CLS.
    // TODO: Check if the first condition is still necessary: `onCLS` already only fires once `onFCP` was called.
    if (!('fcp' in _measurements) || !options.recordClsOnPageloadSpan) {
      delete _measurements.cls;
    }

    Object.entries(_measurements).forEach(([measurementName, measurement]) => {
      core.setMeasurement(measurementName, measurement.value, measurement.unit);
    });

    // Set timeOrigin which denotes the timestamp which to base the LCP/FCP/FP/TTFB measurements on
    span.setAttribute('performance.timeOrigin', timeOrigin);

    // In prerendering scenarios, where a page might be prefetched and pre-rendered before the user clicks the link,
    // the navigation starts earlier than when the user clicks it. Web Vitals should always be based on the
    // user-perceived time, so they are not reported from the actual start of the navigation, but rather from the
    // time where the user actively started the navigation, for example by clicking a link.
    // This is user action is called "activation" and the time between navigation and activation is stored in
    // the `activationStart` attribute of the "navigation" PerformanceEntry.
    span.setAttribute('performance.activationStart', getActivationStart.getActivationStart());

    _setWebVitalAttributes(span);
  }

  _lcpEntry = undefined;
  _clsEntry = undefined;
  _measurements = {};
}

/** Create measure related spans */
function _addMeasureSpans(
  span,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  entry,
  startTime,
  duration,
  timeOrigin,
) {
  const navEntry = getNavigationEntry.getNavigationEntry();
  const requestTime = utils.msToSec(navEntry ? navEntry.requestStart : 0);
  // Because performance.measure accepts arbitrary timestamps it can produce
  // spans that happen before the browser even makes a request for the page.
  //
  // An example of this is the automatically generated Next.js-before-hydration
  // spans created by the Next.js framework.
  //
  // To prevent this we will pin the start timestamp to the request start time
  // This does make duration inaccruate, so if this does happen, we will add
  // an attribute to the span
  const measureStartTimestamp = timeOrigin + Math.max(startTime, requestTime);
  const startTimeStamp = timeOrigin + startTime;
  const measureEndTimestamp = startTimeStamp + duration;

  const attributes = {
    [core.SEMANTIC_ATTRIBUTE_SENTRY_ORIGIN]: 'auto.resource.browser.metrics',
  };

  if (measureStartTimestamp !== startTimeStamp) {
    attributes['sentry.browser.measure_happened_before_request'] = true;
    attributes['sentry.browser.measure_start_time'] = measureStartTimestamp;
  }

  utils.startAndEndSpan(span, measureStartTimestamp, measureEndTimestamp, {
    name: entry.name ,
    op: entry.entryType ,
    attributes,
  });

  return measureStartTimestamp;
}

/** Instrument navigation entries */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function _addNavigationSpans(span, entry, timeOrigin) {
  ['unloadEvent', 'redirect', 'domContentLoadedEvent', 'loadEvent', 'connect'].forEach(event => {
    _addPerformanceNavigationTiming(span, entry, event, timeOrigin);
  });
  _addPerformanceNavigationTiming(span, entry, 'secureConnection', timeOrigin, 'TLS/SSL', 'connectEnd');
  _addPerformanceNavigationTiming(span, entry, 'fetch', timeOrigin, 'cache', 'domainLookupStart');
  _addPerformanceNavigationTiming(span, entry, 'domainLookup', timeOrigin, 'DNS');
  _addRequest(span, entry, timeOrigin);
}

/** Create performance navigation related spans */
function _addPerformanceNavigationTiming(
  span,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  entry,
  event,
  timeOrigin,
  name,
  eventEnd,
) {
  const end = eventEnd ? (entry[eventEnd] ) : (entry[`${event}End`] );
  const start = entry[`${event}Start`] ;
  if (!start || !end) {
    return;
  }
  utils.startAndEndSpan(span, timeOrigin + utils.msToSec(start), timeOrigin + utils.msToSec(end), {
    op: 'browser',
    name: name || event,
    attributes: {
      [core.SEMANTIC_ATTRIBUTE_SENTRY_ORIGIN]: 'auto.ui.browser.metrics',
    },
  });
}

/** Create request and response related spans */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function _addRequest(span, entry, timeOrigin) {
  const requestStartTimestamp = timeOrigin + utils.msToSec(entry.requestStart );
  const responseEndTimestamp = timeOrigin + utils.msToSec(entry.responseEnd );
  const responseStartTimestamp = timeOrigin + utils.msToSec(entry.responseStart );
  if (entry.responseEnd) {
    // It is possible that we are collecting these metrics when the page hasn't finished loading yet, for example when the HTML slowly streams in.
    // In this case, ie. when the document request hasn't finished yet, `entry.responseEnd` will be 0.
    // In order not to produce faulty spans, where the end timestamp is before the start timestamp, we will only collect
    // these spans when the responseEnd value is available. The backend (Relay) would drop the entire span if it contained faulty spans.
    utils.startAndEndSpan(span, requestStartTimestamp, responseEndTimestamp, {
      op: 'browser',
      name: 'request',
      attributes: {
        [core.SEMANTIC_ATTRIBUTE_SENTRY_ORIGIN]: 'auto.ui.browser.metrics',
      },
    });

    utils.startAndEndSpan(span, responseStartTimestamp, responseEndTimestamp, {
      op: 'browser',
      name: 'response',
      attributes: {
        [core.SEMANTIC_ATTRIBUTE_SENTRY_ORIGIN]: 'auto.ui.browser.metrics',
      },
    });
  }
}

/** Create resource-related spans */
function _addResourceSpans(
  span,
  entry,
  resourceUrl,
  startTime,
  duration,
  timeOrigin,
) {
  // we already instrument based on fetch and xhr, so we don't need to
  // duplicate spans here.
  if (entry.initiatorType === 'xmlhttprequest' || entry.initiatorType === 'fetch') {
    return;
  }

  const parsedUrl = utils$1.parseUrl(resourceUrl);

  const attributes = {
    [core.SEMANTIC_ATTRIBUTE_SENTRY_ORIGIN]: 'auto.resource.browser.metrics',
  };
  setResourceEntrySizeData(attributes, entry, 'transferSize', 'http.response_transfer_size');
  setResourceEntrySizeData(attributes, entry, 'encodedBodySize', 'http.response_content_length');
  setResourceEntrySizeData(attributes, entry, 'decodedBodySize', 'http.decoded_response_content_length');

  if ('renderBlockingStatus' in entry) {
    attributes['resource.render_blocking_status'] = entry.renderBlockingStatus;
  }
  if (parsedUrl.protocol) {
    attributes['url.scheme'] = parsedUrl.protocol.split(':').pop(); // the protocol returned by parseUrl includes a :, but OTEL spec does not, so we remove it.
  }

  if (parsedUrl.host) {
    attributes['server.address'] = parsedUrl.host;
  }

  attributes['url.same_origin'] = resourceUrl.includes(types.WINDOW.location.origin);

  const startTimestamp = timeOrigin + startTime;
  const endTimestamp = startTimestamp + duration;

  utils.startAndEndSpan(span, startTimestamp, endTimestamp, {
    name: resourceUrl.replace(types.WINDOW.location.origin, ''),
    op: entry.initiatorType ? `resource.${entry.initiatorType}` : 'resource.other',
    attributes,
  });
}

/**
 * Capture the information of the user agent.
 */
function _trackNavigator(span) {
  const navigator = types.WINDOW.navigator ;
  if (!navigator) {
    return;
  }

  // track network connectivity
  const connection = navigator.connection;
  if (connection) {
    if (connection.effectiveType) {
      span.setAttribute('effectiveConnectionType', connection.effectiveType);
    }

    if (connection.type) {
      span.setAttribute('connectionType', connection.type);
    }

    if (utils.isMeasurementValue(connection.rtt)) {
      _measurements['connection.rtt'] = { value: connection.rtt, unit: 'millisecond' };
    }
  }

  if (utils.isMeasurementValue(navigator.deviceMemory)) {
    span.setAttribute('deviceMemory', `${navigator.deviceMemory} GB`);
  }

  if (utils.isMeasurementValue(navigator.hardwareConcurrency)) {
    span.setAttribute('hardwareConcurrency', String(navigator.hardwareConcurrency));
  }
}

/** Add LCP / CLS data to span to allow debugging */
function _setWebVitalAttributes(span) {
  if (_lcpEntry) {
    debugBuild.DEBUG_BUILD && utils$1.logger.log('[Measurements] Adding LCP Data');

    // Capture Properties of the LCP element that contributes to the LCP.

    if (_lcpEntry.element) {
      span.setAttribute('lcp.element', utils$1.htmlTreeAsString(_lcpEntry.element));
    }

    if (_lcpEntry.id) {
      span.setAttribute('lcp.id', _lcpEntry.id);
    }

    if (_lcpEntry.url) {
      // Trim URL to the first 200 characters.
      span.setAttribute('lcp.url', _lcpEntry.url.trim().slice(0, 200));
    }

    span.setAttribute('lcp.size', _lcpEntry.size);
  }

  // See: https://developer.mozilla.org/en-US/docs/Web/API/LayoutShift
  if (_clsEntry && _clsEntry.sources) {
    debugBuild.DEBUG_BUILD && utils$1.logger.log('[Measurements] Adding CLS Data');
    _clsEntry.sources.forEach((source, index) =>
      span.setAttribute(`cls.source.${index + 1}`, utils$1.htmlTreeAsString(source.node)),
    );
  }
}

function setResourceEntrySizeData(
  attributes,
  entry,
  key,
  dataKey,
) {
  const entryVal = entry[key];
  if (entryVal != null && entryVal < MAX_INT_AS_BYTES) {
    attributes[dataKey] = entryVal;
  }
}

/**
 * Add ttfb request time information to measurements.
 *
 * ttfb information is added via vendored web vitals library.
 */
function _addTtfbRequestTimeToMeasurements(_measurements) {
  const navEntry = getNavigationEntry.getNavigationEntry();
  if (!navEntry) {
    return;
  }

  const { responseStart, requestStart } = navEntry;

  if (requestStart <= responseStart) {
    debugBuild.DEBUG_BUILD && utils$1.logger.log('[Measurements] Adding TTFB Request Time');
    _measurements['ttfb.requestTime'] = {
      value: responseStart - requestStart,
      unit: 'millisecond',
    };
  }
}

exports._addMeasureSpans = _addMeasureSpans;
exports._addResourceSpans = _addResourceSpans;
exports.addPerformanceEntries = addPerformanceEntries;
exports.startTrackingInteractions = startTrackingInteractions;
exports.startTrackingLongAnimationFrames = startTrackingLongAnimationFrames;
exports.startTrackingLongTasks = startTrackingLongTasks;
exports.startTrackingWebVitals = startTrackingWebVitals;
//# sourceMappingURL=browserMetrics.js.map
