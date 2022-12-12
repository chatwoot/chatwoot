Object.defineProperty(exports, "__esModule", { value: true });
var tslib_1 = require("tslib");
var utils_1 = require("@sentry/utils");
var flags_1 = require("../flags");
var utils_2 = require("../utils");
var getCLS_1 = require("./web-vitals/getCLS");
var getFID_1 = require("./web-vitals/getFID");
var getLCP_1 = require("./web-vitals/getLCP");
var getVisibilityWatcher_1 = require("./web-vitals/lib/getVisibilityWatcher");
var global = utils_1.getGlobalObject();
/** Class tracking metrics  */
var MetricsInstrumentation = /** @class */ (function () {
    function MetricsInstrumentation(_reportAllChanges) {
        if (_reportAllChanges === void 0) { _reportAllChanges = false; }
        this._reportAllChanges = _reportAllChanges;
        this._measurements = {};
        this._performanceCursor = 0;
        if (!utils_1.isNodeEnv() && global && global.performance && global.document) {
            if (global.performance.mark) {
                global.performance.mark('sentry-tracing-init');
            }
            this._trackCLS();
            this._trackLCP();
            this._trackFID();
        }
    }
    /** Add performance related spans to a transaction */
    MetricsInstrumentation.prototype.addPerformanceEntries = function (transaction) {
        var _this = this;
        if (!global || !global.performance || !global.performance.getEntries || !utils_1.browserPerformanceTimeOrigin) {
            // Gatekeeper if performance API not available
            return;
        }
        flags_1.IS_DEBUG_BUILD && utils_1.logger.log('[Tracing] Adding & adjusting spans using Performance API');
        var timeOrigin = utils_2.msToSec(utils_1.browserPerformanceTimeOrigin);
        var responseStartTimestamp;
        var requestStartTimestamp;
        global.performance
            .getEntries()
            .slice(this._performanceCursor)
            .forEach(function (entry) {
            var startTime = utils_2.msToSec(entry.startTime);
            var duration = utils_2.msToSec(entry.duration);
            if (transaction.op === 'navigation' && timeOrigin + startTime < transaction.startTimestamp) {
                return;
            }
            switch (entry.entryType) {
                case 'navigation': {
                    addNavigationSpans(transaction, entry, timeOrigin);
                    responseStartTimestamp = timeOrigin + utils_2.msToSec(entry.responseStart);
                    requestStartTimestamp = timeOrigin + utils_2.msToSec(entry.requestStart);
                    break;
                }
                case 'mark':
                case 'paint':
                case 'measure': {
                    var startTimestamp = addMeasureSpans(transaction, entry, startTime, duration, timeOrigin);
                    // capture web vitals
                    var firstHidden = getVisibilityWatcher_1.getVisibilityWatcher();
                    // Only report if the page wasn't hidden prior to the web vital.
                    var shouldRecord = entry.startTime < firstHidden.firstHiddenTime;
                    if (entry.name === 'first-paint' && shouldRecord) {
                        flags_1.IS_DEBUG_BUILD && utils_1.logger.log('[Measurements] Adding FP');
                        _this._measurements['fp'] = { value: entry.startTime };
                        _this._measurements['mark.fp'] = { value: startTimestamp };
                    }
                    if (entry.name === 'first-contentful-paint' && shouldRecord) {
                        flags_1.IS_DEBUG_BUILD && utils_1.logger.log('[Measurements] Adding FCP');
                        _this._measurements['fcp'] = { value: entry.startTime };
                        _this._measurements['mark.fcp'] = { value: startTimestamp };
                    }
                    break;
                }
                case 'resource': {
                    var resourceName = entry.name.replace(global.location.origin, '');
                    addResourceSpans(transaction, entry, resourceName, startTime, duration, timeOrigin);
                    break;
                }
                default:
                // Ignore other entry types.
            }
        });
        this._performanceCursor = Math.max(performance.getEntries().length - 1, 0);
        this._trackNavigator(transaction);
        // Measurements are only available for pageload transactions
        if (transaction.op === 'pageload') {
            // normalize applicable web vital values to be relative to transaction.startTimestamp
            var timeOrigin_1 = utils_2.msToSec(utils_1.browserPerformanceTimeOrigin);
            // Generate TTFB (Time to First Byte), which measured as the time between the beginning of the transaction and the
            // start of the response in milliseconds
            if (typeof responseStartTimestamp === 'number') {
                flags_1.IS_DEBUG_BUILD && utils_1.logger.log('[Measurements] Adding TTFB');
                this._measurements['ttfb'] = { value: (responseStartTimestamp - transaction.startTimestamp) * 1000 };
                if (typeof requestStartTimestamp === 'number' && requestStartTimestamp <= responseStartTimestamp) {
                    // Capture the time spent making the request and receiving the first byte of the response.
                    // This is the time between the start of the request and the start of the response in milliseconds.
                    this._measurements['ttfb.requestTime'] = { value: (responseStartTimestamp - requestStartTimestamp) * 1000 };
                }
            }
            ['fcp', 'fp', 'lcp'].forEach(function (name) {
                if (!_this._measurements[name] || timeOrigin_1 >= transaction.startTimestamp) {
                    return;
                }
                // The web vitals, fcp, fp, lcp, and ttfb, all measure relative to timeOrigin.
                // Unfortunately, timeOrigin is not captured within the transaction span data, so these web vitals will need
                // to be adjusted to be relative to transaction.startTimestamp.
                var oldValue = _this._measurements[name].value;
                var measurementTimestamp = timeOrigin_1 + utils_2.msToSec(oldValue);
                // normalizedValue should be in milliseconds
                var normalizedValue = Math.abs((measurementTimestamp - transaction.startTimestamp) * 1000);
                var delta = normalizedValue - oldValue;
                flags_1.IS_DEBUG_BUILD &&
                    utils_1.logger.log("[Measurements] Normalized " + name + " from " + oldValue + " to " + normalizedValue + " (" + delta + ")");
                _this._measurements[name].value = normalizedValue;
            });
            if (this._measurements['mark.fid'] && this._measurements['fid']) {
                // create span for FID
                _startChild(transaction, {
                    description: 'first input delay',
                    endTimestamp: this._measurements['mark.fid'].value + utils_2.msToSec(this._measurements['fid'].value),
                    op: 'web.vitals',
                    startTimestamp: this._measurements['mark.fid'].value,
                });
            }
            // If FCP is not recorded we should not record the cls value
            // according to the new definition of CLS.
            if (!('fcp' in this._measurements)) {
                delete this._measurements.cls;
            }
            transaction.setMeasurements(this._measurements);
            tagMetricInfo(transaction, this._lcpEntry, this._clsEntry);
            transaction.setTag('sentry_reportAllChanges', this._reportAllChanges);
        }
    };
    /**
     * Capture the information of the user agent.
     */
    MetricsInstrumentation.prototype._trackNavigator = function (transaction) {
        var navigator = global.navigator;
        if (!navigator) {
            return;
        }
        // track network connectivity
        var connection = navigator.connection;
        if (connection) {
            if (connection.effectiveType) {
                transaction.setTag('effectiveConnectionType', connection.effectiveType);
            }
            if (connection.type) {
                transaction.setTag('connectionType', connection.type);
            }
            if (isMeasurementValue(connection.rtt)) {
                this._measurements['connection.rtt'] = { value: connection.rtt };
            }
            if (isMeasurementValue(connection.downlink)) {
                this._measurements['connection.downlink'] = { value: connection.downlink };
            }
        }
        if (isMeasurementValue(navigator.deviceMemory)) {
            transaction.setTag('deviceMemory', String(navigator.deviceMemory));
        }
        if (isMeasurementValue(navigator.hardwareConcurrency)) {
            transaction.setTag('hardwareConcurrency', String(navigator.hardwareConcurrency));
        }
    };
    /** Starts tracking the Cumulative Layout Shift on the current page. */
    MetricsInstrumentation.prototype._trackCLS = function () {
        var _this = this;
        // See:
        // https://web.dev/evolving-cls/
        // https://web.dev/cls-web-tooling/
        getCLS_1.getCLS(function (metric) {
            var entry = metric.entries.pop();
            if (!entry) {
                return;
            }
            flags_1.IS_DEBUG_BUILD && utils_1.logger.log('[Measurements] Adding CLS');
            _this._measurements['cls'] = { value: metric.value };
            _this._clsEntry = entry;
        });
    };
    /** Starts tracking the Largest Contentful Paint on the current page. */
    MetricsInstrumentation.prototype._trackLCP = function () {
        var _this = this;
        getLCP_1.getLCP(function (metric) {
            var entry = metric.entries.pop();
            if (!entry) {
                return;
            }
            var timeOrigin = utils_2.msToSec(utils_1.browserPerformanceTimeOrigin);
            var startTime = utils_2.msToSec(entry.startTime);
            flags_1.IS_DEBUG_BUILD && utils_1.logger.log('[Measurements] Adding LCP');
            _this._measurements['lcp'] = { value: metric.value };
            _this._measurements['mark.lcp'] = { value: timeOrigin + startTime };
            _this._lcpEntry = entry;
        }, this._reportAllChanges);
    };
    /** Starts tracking the First Input Delay on the current page. */
    MetricsInstrumentation.prototype._trackFID = function () {
        var _this = this;
        getFID_1.getFID(function (metric) {
            var entry = metric.entries.pop();
            if (!entry) {
                return;
            }
            var timeOrigin = utils_2.msToSec(utils_1.browserPerformanceTimeOrigin);
            var startTime = utils_2.msToSec(entry.startTime);
            flags_1.IS_DEBUG_BUILD && utils_1.logger.log('[Measurements] Adding FID');
            _this._measurements['fid'] = { value: metric.value };
            _this._measurements['mark.fid'] = { value: timeOrigin + startTime };
        });
    };
    return MetricsInstrumentation;
}());
exports.MetricsInstrumentation = MetricsInstrumentation;
/** Instrument navigation entries */
function addNavigationSpans(transaction, entry, timeOrigin) {
    ['unloadEvent', 'redirect', 'domContentLoadedEvent', 'loadEvent', 'connect'].forEach(function (event) {
        addPerformanceNavigationTiming(transaction, entry, event, timeOrigin);
    });
    addPerformanceNavigationTiming(transaction, entry, 'secureConnection', timeOrigin, 'TLS/SSL', 'connectEnd');
    addPerformanceNavigationTiming(transaction, entry, 'fetch', timeOrigin, 'cache', 'domainLookupStart');
    addPerformanceNavigationTiming(transaction, entry, 'domainLookup', timeOrigin, 'DNS');
    addRequest(transaction, entry, timeOrigin);
}
/** Create measure related spans */
function addMeasureSpans(transaction, entry, startTime, duration, timeOrigin) {
    var measureStartTimestamp = timeOrigin + startTime;
    var measureEndTimestamp = measureStartTimestamp + duration;
    _startChild(transaction, {
        description: entry.name,
        endTimestamp: measureEndTimestamp,
        op: entry.entryType,
        startTimestamp: measureStartTimestamp,
    });
    return measureStartTimestamp;
}
/** Create resource-related spans */
function addResourceSpans(transaction, entry, resourceName, startTime, duration, timeOrigin) {
    // we already instrument based on fetch and xhr, so we don't need to
    // duplicate spans here.
    if (entry.initiatorType === 'xmlhttprequest' || entry.initiatorType === 'fetch') {
        return;
    }
    var data = {};
    if ('transferSize' in entry) {
        data['Transfer Size'] = entry.transferSize;
    }
    if ('encodedBodySize' in entry) {
        data['Encoded Body Size'] = entry.encodedBodySize;
    }
    if ('decodedBodySize' in entry) {
        data['Decoded Body Size'] = entry.decodedBodySize;
    }
    var startTimestamp = timeOrigin + startTime;
    var endTimestamp = startTimestamp + duration;
    _startChild(transaction, {
        description: resourceName,
        endTimestamp: endTimestamp,
        op: entry.initiatorType ? "resource." + entry.initiatorType : 'resource',
        startTimestamp: startTimestamp,
        data: data,
    });
}
exports.addResourceSpans = addResourceSpans;
/** Create performance navigation related spans */
function addPerformanceNavigationTiming(transaction, entry, event, timeOrigin, description, eventEnd) {
    var end = eventEnd ? entry[eventEnd] : entry[event + "End"];
    var start = entry[event + "Start"];
    if (!start || !end) {
        return;
    }
    _startChild(transaction, {
        op: 'browser',
        description: (description !== null && description !== void 0 ? description : event),
        startTimestamp: timeOrigin + utils_2.msToSec(start),
        endTimestamp: timeOrigin + utils_2.msToSec(end),
    });
}
/** Create request and response related spans */
function addRequest(transaction, entry, timeOrigin) {
    _startChild(transaction, {
        op: 'browser',
        description: 'request',
        startTimestamp: timeOrigin + utils_2.msToSec(entry.requestStart),
        endTimestamp: timeOrigin + utils_2.msToSec(entry.responseEnd),
    });
    _startChild(transaction, {
        op: 'browser',
        description: 'response',
        startTimestamp: timeOrigin + utils_2.msToSec(entry.responseStart),
        endTimestamp: timeOrigin + utils_2.msToSec(entry.responseEnd),
    });
}
/**
 * Helper function to start child on transactions. This function will make sure that the transaction will
 * use the start timestamp of the created child span if it is earlier than the transactions actual
 * start timestamp.
 */
function _startChild(transaction, _a) {
    var startTimestamp = _a.startTimestamp, ctx = tslib_1.__rest(_a, ["startTimestamp"]);
    if (startTimestamp && transaction.startTimestamp > startTimestamp) {
        transaction.startTimestamp = startTimestamp;
    }
    return transaction.startChild(tslib_1.__assign({ startTimestamp: startTimestamp }, ctx));
}
exports._startChild = _startChild;
/**
 * Checks if a given value is a valid measurement value.
 */
function isMeasurementValue(value) {
    return typeof value === 'number' && isFinite(value);
}
/** Add LCP / CLS data to transaction to allow debugging */
function tagMetricInfo(transaction, lcpEntry, clsEntry) {
    if (lcpEntry) {
        flags_1.IS_DEBUG_BUILD && utils_1.logger.log('[Measurements] Adding LCP Data');
        // Capture Properties of the LCP element that contributes to the LCP.
        if (lcpEntry.element) {
            transaction.setTag('lcp.element', utils_1.htmlTreeAsString(lcpEntry.element));
        }
        if (lcpEntry.id) {
            transaction.setTag('lcp.id', lcpEntry.id);
        }
        if (lcpEntry.url) {
            // Trim URL to the first 200 characters.
            transaction.setTag('lcp.url', lcpEntry.url.trim().slice(0, 200));
        }
        transaction.setTag('lcp.size', lcpEntry.size);
    }
    // See: https://developer.mozilla.org/en-US/docs/Web/API/LayoutShift
    if (clsEntry && clsEntry.sources) {
        flags_1.IS_DEBUG_BUILD && utils_1.logger.log('[Measurements] Adding CLS Data');
        clsEntry.sources.forEach(function (source, index) {
            return transaction.setTag("cls.source." + (index + 1), utils_1.htmlTreeAsString(source.node));
        });
    }
}
//# sourceMappingURL=metrics.js.map