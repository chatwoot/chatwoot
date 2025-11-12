"use strict";
var __assign = (this && this.__assign) || function () {
    __assign = Object.assign || function(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
                t[p] = s[p];
        }
        return t;
    };
    return __assign.apply(this, arguments);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.WebVitalsAutocapture = exports.FIFTEEN_MINUTES_IN_MILLIS = exports.DEFAULT_FLUSH_TO_CAPTURE_TIMEOUT_MILLISECONDS = void 0;
var logger_1 = require("../../utils/logger");
var core_1 = require("@posthog/core");
var constants_1 = require("../../constants");
var globals_1 = require("../../utils/globals");
var logger = (0, logger_1.createLogger)('[Web Vitals]');
exports.DEFAULT_FLUSH_TO_CAPTURE_TIMEOUT_MILLISECONDS = 5000;
var ONE_MINUTE_IN_MILLIS = 60 * 1000;
exports.FIFTEEN_MINUTES_IN_MILLIS = 15 * ONE_MINUTE_IN_MILLIS;
var WebVitalsAutocapture = /** @class */ (function () {
    function WebVitalsAutocapture(_instance) {
        var _this = this;
        var _a;
        this._instance = _instance;
        this._enabledServerSide = false;
        this._initialized = false;
        this._buffer = { url: undefined, metrics: [], firstMetricTimestamp: undefined };
        this._flushToCapture = function () {
            clearTimeout(_this._delayedFlushTimer);
            if (_this._buffer.metrics.length === 0) {
                return;
            }
            _this._instance.capture('$web_vitals', _this._buffer.metrics.reduce(function (acc, metric) {
                var _a;
                return (__assign(__assign({}, acc), (_a = {}, _a["$web_vitals_".concat(metric.name, "_event")] = __assign({}, metric), _a["$web_vitals_".concat(metric.name, "_value")] = metric.value, _a)));
            }, {}));
            _this._buffer = { url: undefined, metrics: [], firstMetricTimestamp: undefined };
        };
        this._addToBuffer = function (metric) {
            var _a;
            var sessionIds = (_a = _this._instance.sessionManager) === null || _a === void 0 ? void 0 : _a.checkAndGetSessionAndWindowId(true);
            if ((0, core_1.isUndefined)(sessionIds)) {
                logger.error('Could not read session ID. Dropping metrics!');
                return;
            }
            _this._buffer = _this._buffer || { url: undefined, metrics: [], firstMetricTimestamp: undefined };
            var $currentUrl = _this._currentURL();
            if ((0, core_1.isUndefined)($currentUrl)) {
                return;
            }
            if ((0, core_1.isNullish)(metric === null || metric === void 0 ? void 0 : metric.name) || (0, core_1.isNullish)(metric === null || metric === void 0 ? void 0 : metric.value)) {
                logger.error('Invalid metric received', metric);
                return;
            }
            // we observe some very large values sometimes, we'll ignore them
            // since the likelihood of LCP > 1 hour being correct is very low
            if (_this._maxAllowedValue && metric.value >= _this._maxAllowedValue) {
                logger.error('Ignoring metric with value >= ' + _this._maxAllowedValue, metric);
                return;
            }
            var urlHasChanged = _this._buffer.url !== $currentUrl;
            if (urlHasChanged) {
                // we need to send what we have
                _this._flushToCapture();
                // poor performance is >4s, we wait twice that time to send
                // this is in case we haven't received all metrics
                // we'll at least gather some
                _this._delayedFlushTimer = setTimeout(_this._flushToCapture, _this.flushToCaptureTimeoutMs);
            }
            if ((0, core_1.isUndefined)(_this._buffer.url)) {
                _this._buffer.url = $currentUrl;
            }
            _this._buffer.firstMetricTimestamp = (0, core_1.isUndefined)(_this._buffer.firstMetricTimestamp)
                ? Date.now()
                : _this._buffer.firstMetricTimestamp;
            if (metric.attribution && metric.attribution.interactionTargetElement) {
                // we don't want to send the entire element
                // they can be very large
                // TODO we could run this through autocapture code so that we get elements chain info
                //  and can display the element in the UI
                metric.attribution.interactionTargetElement = undefined;
            }
            _this._buffer.metrics.push(__assign(__assign({}, metric), { $current_url: $currentUrl, $session_id: sessionIds.sessionId, $window_id: sessionIds.windowId, timestamp: Date.now() }));
            if (_this._buffer.metrics.length === _this.allowedMetrics.length) {
                // we have all allowed metrics
                _this._flushToCapture();
            }
        };
        this._startCapturing = function () {
            var _a;
            var onLCP;
            var onCLS;
            var onFCP;
            var onINP;
            var posthogExtensions = globals_1.assignableWindow.__PosthogExtensions__;
            if (!(0, core_1.isUndefined)(posthogExtensions) && !(0, core_1.isUndefined)(posthogExtensions.postHogWebVitalsCallbacks)) {
                ;
                (_a = posthogExtensions.postHogWebVitalsCallbacks, onLCP = _a.onLCP, onCLS = _a.onCLS, onFCP = _a.onFCP, onINP = _a.onINP);
            }
            if (!onLCP || !onCLS || !onFCP || !onINP) {
                logger.error('web vitals callbacks not loaded - not starting');
                return;
            }
            // register performance observers
            if (_this.allowedMetrics.indexOf('LCP') > -1) {
                onLCP(_this._addToBuffer.bind(_this));
            }
            if (_this.allowedMetrics.indexOf('CLS') > -1) {
                onCLS(_this._addToBuffer.bind(_this));
            }
            if (_this.allowedMetrics.indexOf('FCP') > -1) {
                onFCP(_this._addToBuffer.bind(_this));
            }
            if (_this.allowedMetrics.indexOf('INP') > -1) {
                onINP(_this._addToBuffer.bind(_this));
            }
            _this._initialized = true;
        };
        this._enabledServerSide = !!((_a = this._instance.persistence) === null || _a === void 0 ? void 0 : _a.props[constants_1.WEB_VITALS_ENABLED_SERVER_SIDE]);
        this.startIfEnabled();
    }
    Object.defineProperty(WebVitalsAutocapture.prototype, "allowedMetrics", {
        get: function () {
            var _a, _b;
            var clientConfigMetricAllowList = (0, core_1.isObject)(this._instance.config.capture_performance)
                ? (_a = this._instance.config.capture_performance) === null || _a === void 0 ? void 0 : _a.web_vitals_allowed_metrics
                : undefined;
            return !(0, core_1.isUndefined)(clientConfigMetricAllowList)
                ? clientConfigMetricAllowList
                : ((_b = this._instance.persistence) === null || _b === void 0 ? void 0 : _b.props[constants_1.WEB_VITALS_ALLOWED_METRICS]) || ['CLS', 'FCP', 'INP', 'LCP'];
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(WebVitalsAutocapture.prototype, "flushToCaptureTimeoutMs", {
        get: function () {
            var clientConfig = (0, core_1.isObject)(this._instance.config.capture_performance)
                ? this._instance.config.capture_performance.web_vitals_delayed_flush_ms
                : undefined;
            return clientConfig || exports.DEFAULT_FLUSH_TO_CAPTURE_TIMEOUT_MILLISECONDS;
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(WebVitalsAutocapture.prototype, "_maxAllowedValue", {
        get: function () {
            var configured = (0, core_1.isObject)(this._instance.config.capture_performance) &&
                (0, core_1.isNumber)(this._instance.config.capture_performance.__web_vitals_max_value)
                ? this._instance.config.capture_performance.__web_vitals_max_value
                : exports.FIFTEEN_MINUTES_IN_MILLIS;
            // you can set to 0 to disable the check or any value over ten seconds
            // 1 milli to 1 minute will be set to 15 minutes, cos that would be a silly low maximum
            return 0 < configured && configured <= ONE_MINUTE_IN_MILLIS ? exports.FIFTEEN_MINUTES_IN_MILLIS : configured;
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(WebVitalsAutocapture.prototype, "isEnabled", {
        get: function () {
            // Always disable web vitals if we're not on http or https
            var protocol = globals_1.location === null || globals_1.location === void 0 ? void 0 : globals_1.location.protocol;
            if (protocol !== 'http:' && protocol !== 'https:') {
                logger.info('Web Vitals are disabled on non-http/https protocols');
                return false;
            }
            // Otherwise, check config
            var clientConfig = (0, core_1.isObject)(this._instance.config.capture_performance)
                ? this._instance.config.capture_performance.web_vitals
                : (0, core_1.isBoolean)(this._instance.config.capture_performance)
                    ? this._instance.config.capture_performance
                    : undefined;
            return (0, core_1.isBoolean)(clientConfig) ? clientConfig : this._enabledServerSide;
        },
        enumerable: false,
        configurable: true
    });
    WebVitalsAutocapture.prototype.startIfEnabled = function () {
        if (this.isEnabled && !this._initialized) {
            logger.info('enabled, starting...');
            this._loadScript(this._startCapturing);
        }
    };
    WebVitalsAutocapture.prototype.onRemoteConfig = function (response) {
        var _a, _b;
        var webVitalsOptIn = (0, core_1.isObject)(response.capturePerformance) && !!response.capturePerformance.web_vitals;
        var allowedMetrics = (0, core_1.isObject)(response.capturePerformance)
            ? response.capturePerformance.web_vitals_allowed_metrics
            : undefined;
        if (this._instance.persistence) {
            this._instance.persistence.register((_a = {},
                _a[constants_1.WEB_VITALS_ENABLED_SERVER_SIDE] = webVitalsOptIn,
                _a));
            this._instance.persistence.register((_b = {},
                _b[constants_1.WEB_VITALS_ALLOWED_METRICS] = allowedMetrics,
                _b));
        }
        // store this in-memory in case persistence is disabled
        this._enabledServerSide = webVitalsOptIn;
        this.startIfEnabled();
    };
    WebVitalsAutocapture.prototype._loadScript = function (cb) {
        var _a, _b, _c;
        if ((_a = globals_1.assignableWindow.__PosthogExtensions__) === null || _a === void 0 ? void 0 : _a.postHogWebVitalsCallbacks) {
            // already loaded
            cb();
        }
        (_c = (_b = globals_1.assignableWindow.__PosthogExtensions__) === null || _b === void 0 ? void 0 : _b.loadExternalDependency) === null || _c === void 0 ? void 0 : _c.call(_b, this._instance, 'web-vitals', function (err) {
            if (err) {
                logger.error('failed to load script', err);
                return;
            }
            cb();
        });
    };
    WebVitalsAutocapture.prototype._currentURL = function () {
        // TODO you should be able to mask the URL here
        var href = globals_1.window ? globals_1.window.location.href : undefined;
        if (!href) {
            logger.error('Could not determine current URL');
        }
        return href;
    };
    return WebVitalsAutocapture;
}());
exports.WebVitalsAutocapture = WebVitalsAutocapture;
//# sourceMappingURL=index.js.map