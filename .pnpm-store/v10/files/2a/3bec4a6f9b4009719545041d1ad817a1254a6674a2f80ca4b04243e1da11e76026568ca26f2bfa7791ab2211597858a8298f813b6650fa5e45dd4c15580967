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
var __read = (this && this.__read) || function (o, n) {
    var m = typeof Symbol === "function" && o[Symbol.iterator];
    if (!m) return o;
    var i = m.call(o), r, ar = [], e;
    try {
        while ((n === void 0 || n-- > 0) && !(r = i.next()).done) ar.push(r.value);
    }
    catch (error) { e = { error: error }; }
    finally {
        try {
            if (r && !r.done && (m = i["return"])) m.call(i);
        }
        finally { if (e) throw e.error; }
    }
    return ar;
};
var __spreadArray = (this && this.__spreadArray) || function (to, from, pack) {
    if (pack || arguments.length === 2) for (var i = 0, l = from.length, ar; i < l; i++) {
        if (ar || !(i in from)) {
            if (!ar) ar = Array.prototype.slice.call(from, 0, i);
            ar[i] = from[i];
        }
    }
    return to.concat(ar || Array.prototype.slice.call(from));
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.RequestQueue = exports.DEFAULT_FLUSH_INTERVAL_MS = void 0;
var utils_1 = require("./utils");
var core_1 = require("@posthog/core");
var logger_1 = require("./utils/logger");
exports.DEFAULT_FLUSH_INTERVAL_MS = 3000;
var RequestQueue = /** @class */ (function () {
    function RequestQueue(sendRequest, config) {
        // We start in a paused state and only start flushing when enabled by the parent
        this._isPaused = true;
        this._queue = [];
        this._flushTimeoutMs = (0, core_1.clampToRange)((config === null || config === void 0 ? void 0 : config.flush_interval_ms) || exports.DEFAULT_FLUSH_INTERVAL_MS, 250, 5000, logger_1.logger.createLogger('flush interval'), exports.DEFAULT_FLUSH_INTERVAL_MS);
        this._sendRequest = sendRequest;
    }
    RequestQueue.prototype.enqueue = function (req) {
        this._queue.push(req);
        if (!this._flushTimeout) {
            this._setFlushTimeout();
        }
    };
    RequestQueue.prototype.unload = function () {
        var _this = this;
        this._clearFlushTimeout();
        var requests = this._queue.length > 0 ? this._formatQueue() : {};
        var requestValues = Object.values(requests);
        // Always force events to be sent before recordings, as events are more important, and recordings are bigger and thus less likely to arrive
        var sortedRequests = __spreadArray(__spreadArray([], __read(requestValues.filter(function (r) { return r.url.indexOf('/e') === 0; })), false), __read(requestValues.filter(function (r) { return r.url.indexOf('/e') !== 0; })), false);
        sortedRequests.map(function (req) {
            _this._sendRequest(__assign(__assign({}, req), { transport: 'sendBeacon' }));
        });
    };
    RequestQueue.prototype.enable = function () {
        this._isPaused = false;
        this._setFlushTimeout();
    };
    RequestQueue.prototype._setFlushTimeout = function () {
        var _this = this;
        if (this._isPaused) {
            return;
        }
        this._flushTimeout = setTimeout(function () {
            _this._clearFlushTimeout();
            if (_this._queue.length > 0) {
                var requests = _this._formatQueue();
                var _loop_1 = function (key) {
                    var req = requests[key];
                    var now = new Date().getTime();
                    if (req.data && (0, core_1.isArray)(req.data)) {
                        (0, utils_1.each)(req.data, function (data) {
                            data['offset'] = Math.abs(data['timestamp'] - now);
                            delete data['timestamp'];
                        });
                    }
                    _this._sendRequest(req);
                };
                for (var key in requests) {
                    _loop_1(key);
                }
            }
        }, this._flushTimeoutMs);
    };
    RequestQueue.prototype._clearFlushTimeout = function () {
        clearTimeout(this._flushTimeout);
        this._flushTimeout = undefined;
    };
    RequestQueue.prototype._formatQueue = function () {
        var requests = {};
        (0, utils_1.each)(this._queue, function (request) {
            var _a;
            var req = request;
            var key = (req ? req.batchKey : null) || req.url;
            if ((0, core_1.isUndefined)(requests[key])) {
                // TODO: What about this -it seems to batch data into an array - do we always want that?
                requests[key] = __assign(__assign({}, req), { data: [] });
            }
            (_a = requests[key].data) === null || _a === void 0 ? void 0 : _a.push(req.data);
        });
        this._queue = [];
        return requests;
    };
    return RequestQueue;
}());
exports.RequestQueue = RequestQueue;
//# sourceMappingURL=request-queue.js.map