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
var __rest = (this && this.__rest) || function (s, e) {
    var t = {};
    for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p) && e.indexOf(p) < 0)
        t[p] = s[p];
    if (s != null && typeof Object.getOwnPropertySymbols === "function")
        for (var i = 0, p = Object.getOwnPropertySymbols(s); i < p.length; i++) {
            if (e.indexOf(p[i]) < 0 && Object.prototype.propertyIsEnumerable.call(s, p[i]))
                t[p[i]] = s[p[i]];
        }
    return t;
};
var __values = (this && this.__values) || function(o) {
    var s = typeof Symbol === "function" && Symbol.iterator, m = s && o[s], i = 0;
    if (m) return m.call(o);
    if (o && typeof o.length === "number") return {
        next: function () {
            if (o && i >= o.length) o = void 0;
            return { value: o && o[i++], done: !o };
        }
    };
    throw new TypeError(s ? "Object is not iterable." : "Symbol.iterator is not defined.");
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.RetryQueue = void 0;
exports.pickNextRetryDelay = pickNextRetryDelay;
var core_1 = require("@posthog/core");
var logger_1 = require("./utils/logger");
var globals_1 = require("./utils/globals");
var request_1 = require("./request");
var utils_1 = require("./utils");
var thirtyMinutes = 30 * 60 * 1000;
/**
 * Generates a jitter-ed exponential backoff delay in milliseconds
 *
 * The base value is 6 seconds, which is doubled with each retry
 * up to the maximum of 30 minutes
 *
 * Each value then has +/- 50% jitter
 *
 * Giving a range of 6 seconds up to 45 minutes
 */
function pickNextRetryDelay(retriesPerformedSoFar) {
    var rawBackoffTime = 3000 * Math.pow(2, retriesPerformedSoFar);
    var minBackoff = rawBackoffTime / 2;
    var cappedBackoffTime = Math.min(thirtyMinutes, rawBackoffTime);
    var jitterFraction = Math.random() - 0.5; // A random number between -0.5 and 0.5
    var jitter = jitterFraction * (cappedBackoffTime - minBackoff);
    return Math.ceil(cappedBackoffTime + jitter);
}
var RetryQueue = /** @class */ (function () {
    function RetryQueue(_instance) {
        var _this = this;
        this._instance = _instance;
        this._isPolling = false; // flag to continue to recursively poll or not
        this._pollIntervalMs = 3000;
        this._queue = [];
        this._queue = [];
        this._areWeOnline = true;
        if (!(0, core_1.isUndefined)(globals_1.window) && 'onLine' in globals_1.window.navigator) {
            this._areWeOnline = globals_1.window.navigator.onLine;
            (0, utils_1.addEventListener)(globals_1.window, 'online', function () {
                _this._areWeOnline = true;
                _this._flush();
            });
            (0, utils_1.addEventListener)(globals_1.window, 'offline', function () {
                _this._areWeOnline = false;
            });
        }
    }
    Object.defineProperty(RetryQueue.prototype, "length", {
        get: function () {
            return this._queue.length;
        },
        enumerable: false,
        configurable: true
    });
    RetryQueue.prototype.retriableRequest = function (_a) {
        var _this = this;
        var retriesPerformedSoFar = _a.retriesPerformedSoFar, options = __rest(_a, ["retriesPerformedSoFar"]);
        if ((0, core_1.isNumber)(retriesPerformedSoFar) && retriesPerformedSoFar > 0) {
            options.url = (0, request_1.extendURLParams)(options.url, { retry_count: retriesPerformedSoFar });
        }
        this._instance._send_request(__assign(__assign({}, options), { callback: function (response) {
                var _a;
                if (response.statusCode !== 200 && (response.statusCode < 400 || response.statusCode >= 500)) {
                    if ((retriesPerformedSoFar !== null && retriesPerformedSoFar !== void 0 ? retriesPerformedSoFar : 0) < 10) {
                        _this._enqueue(__assign({ retriesPerformedSoFar: retriesPerformedSoFar }, options));
                        return;
                    }
                }
                (_a = options.callback) === null || _a === void 0 ? void 0 : _a.call(options, response);
            } }));
    };
    RetryQueue.prototype._enqueue = function (requestOptions) {
        var retriesPerformedSoFar = requestOptions.retriesPerformedSoFar || 0;
        requestOptions.retriesPerformedSoFar = retriesPerformedSoFar + 1;
        var msToNextRetry = pickNextRetryDelay(retriesPerformedSoFar);
        var retryAt = Date.now() + msToNextRetry;
        this._queue.push({ retryAt: retryAt, requestOptions: requestOptions });
        var logMessage = "Enqueued failed request for retry in ".concat(msToNextRetry);
        if (!navigator.onLine) {
            logMessage += ' (Browser is offline)';
        }
        logger_1.logger.warn(logMessage);
        if (!this._isPolling) {
            this._isPolling = true;
            this._poll();
        }
    };
    RetryQueue.prototype._poll = function () {
        var _this = this;
        this._poller && clearTimeout(this._poller);
        this._poller = setTimeout(function () {
            if (_this._areWeOnline && _this._queue.length > 0) {
                _this._flush();
            }
            _this._poll();
        }, this._pollIntervalMs);
    };
    RetryQueue.prototype._flush = function () {
        var e_1, _a;
        var now = Date.now();
        var notToFlush = [];
        var toFlush = this._queue.filter(function (item) {
            if (item.retryAt < now) {
                return true;
            }
            notToFlush.push(item);
            return false;
        });
        this._queue = notToFlush;
        if (toFlush.length > 0) {
            try {
                for (var toFlush_1 = __values(toFlush), toFlush_1_1 = toFlush_1.next(); !toFlush_1_1.done; toFlush_1_1 = toFlush_1.next()) {
                    var requestOptions = toFlush_1_1.value.requestOptions;
                    this.retriableRequest(requestOptions);
                }
            }
            catch (e_1_1) { e_1 = { error: e_1_1 }; }
            finally {
                try {
                    if (toFlush_1_1 && !toFlush_1_1.done && (_a = toFlush_1.return)) _a.call(toFlush_1);
                }
                finally { if (e_1) throw e_1.error; }
            }
        }
    };
    RetryQueue.prototype.unload = function () {
        var e_2, _a;
        if (this._poller) {
            clearTimeout(this._poller);
            this._poller = undefined;
        }
        try {
            for (var _b = __values(this._queue), _c = _b.next(); !_c.done; _c = _b.next()) {
                var requestOptions = _c.value.requestOptions;
                try {
                    // we've had send beacon in place for at least 2 years
                    // eslint-disable-next-line compat/compat
                    this._instance._send_request(__assign(__assign({}, requestOptions), { transport: 'sendBeacon' }));
                }
                catch (e) {
                    // Note sendBeacon automatically retries, and after the first retry it will lose reference to contextual `this`.
                    // This means in some cases `this.getConfig` will be undefined.
                    logger_1.logger.error(e);
                }
            }
        }
        catch (e_2_1) { e_2 = { error: e_2_1 }; }
        finally {
            try {
                if (_c && !_c.done && (_a = _b.return)) _a.call(_b);
            }
            finally { if (e_2) throw e_2.error; }
        }
        this._queue = [];
    };
    return RetryQueue;
}());
exports.RetryQueue = RetryQueue;
//# sourceMappingURL=retry-queue.js.map