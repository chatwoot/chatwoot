"use strict";
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.MutationThrottler = void 0;
var sessionrecording_utils_1 = require("./sessionrecording-utils");
var core_1 = require("@posthog/core");
var logger_1 = require("../../utils/logger");
var MutationThrottler = /** @class */ (function () {
    function MutationThrottler(_rrweb, _options) {
        if (_options === void 0) { _options = {}; }
        var _this = this;
        var _a, _b;
        this._rrweb = _rrweb;
        this._options = _options;
        this._loggedTracker = {};
        this._onNodeRateLimited = function (key) {
            var _a, _b;
            if (!_this._loggedTracker[key]) {
                _this._loggedTracker[key] = true;
                var node = _this._getNode(key);
                (_b = (_a = _this._options).onBlockedNode) === null || _b === void 0 ? void 0 : _b.call(_a, key, node);
            }
        };
        this._getNodeOrRelevantParent = function (id) {
            // For some nodes we know they are part of a larger tree such as an SVG.
            // For those we want to block the entire node, not just the specific attribute
            var node = _this._getNode(id);
            // Check if the node is an Element and then find the closest parent that is an SVG
            if ((node === null || node === void 0 ? void 0 : node.nodeName) !== 'svg' && node instanceof Element) {
                var closestSVG = node.closest('svg');
                if (closestSVG) {
                    return [_this._rrweb.mirror.getId(closestSVG), closestSVG];
                }
            }
            return [id, node];
        };
        this._getNode = function (id) { return _this._rrweb.mirror.getNode(id); };
        this._numberOfChanges = function (data) {
            var _a, _b, _c, _d, _e, _f, _g, _h;
            return (((_b = (_a = data.removes) === null || _a === void 0 ? void 0 : _a.length) !== null && _b !== void 0 ? _b : 0) +
                ((_d = (_c = data.attributes) === null || _c === void 0 ? void 0 : _c.length) !== null && _d !== void 0 ? _d : 0) +
                ((_f = (_e = data.texts) === null || _e === void 0 ? void 0 : _e.length) !== null && _f !== void 0 ? _f : 0) +
                ((_h = (_g = data.adds) === null || _g === void 0 ? void 0 : _g.length) !== null && _h !== void 0 ? _h : 0));
        };
        this.throttleMutations = function (event) {
            if (event.type !== sessionrecording_utils_1.INCREMENTAL_SNAPSHOT_EVENT_TYPE || event.data.source !== sessionrecording_utils_1.MUTATION_SOURCE_TYPE) {
                return event;
            }
            var data = event.data;
            var initialMutationCount = _this._numberOfChanges(data);
            if (data.attributes) {
                // Most problematic mutations come from attrs where the style or minor properties are changed rapidly
                data.attributes = data.attributes.filter(function (attr) {
                    var _a = __read(_this._getNodeOrRelevantParent(attr.id), 1), nodeId = _a[0];
                    var isRateLimited = _this._rateLimiter.consumeRateLimit(nodeId);
                    if (isRateLimited) {
                        return false;
                    }
                    return attr;
                });
            }
            // Check if every part of the mutation is empty in which case there is nothing to do
            var mutationCount = _this._numberOfChanges(data);
            if (mutationCount === 0 && initialMutationCount !== mutationCount) {
                // If we have modified the mutation count and the remaining count is 0, then we don't need the event.
                return;
            }
            return event;
        };
        this._rateLimiter = new core_1.BucketedRateLimiter({
            bucketSize: (_a = this._options.bucketSize) !== null && _a !== void 0 ? _a : 100,
            refillRate: (_b = this._options.refillRate) !== null && _b !== void 0 ? _b : 10,
            refillInterval: 1000, // one second
            _onBucketRateLimited: this._onNodeRateLimited,
            _logger: logger_1.logger,
        });
    }
    return MutationThrottler;
}());
exports.MutationThrottler = MutationThrottler;
//# sourceMappingURL=mutation-throttler.js.map