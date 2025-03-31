import { __assign, __awaiter, __generator } from "tslib";
import { fetch } from '../../lib/fetch';
import { version } from '../../generated/version';
import { getVersionType } from '../../plugins/segmentio/normalize';
var createRemoteMetric = function (metric, tags, versionType) {
    var formattedTags = tags.reduce(function (acc, t) {
        var _a = t.split(':'), k = _a[0], v = _a[1];
        acc[k] = v;
        return acc;
    }, {});
    return {
        type: 'Counter',
        metric: metric,
        value: 1,
        tags: __assign(__assign({}, formattedTags), { library: 'analytics.js', library_version: versionType === 'web' ? "next-".concat(version) : "npm:next-".concat(version) }),
    };
};
function logError(err) {
    console.error('Error sending segment performance metrics', err);
}
var RemoteMetrics = /** @class */ (function () {
    function RemoteMetrics(options) {
        var _this = this;
        var _a, _b, _c, _d;
        this.host = (_a = options === null || options === void 0 ? void 0 : options.host) !== null && _a !== void 0 ? _a : 'api.june.so/sdk';
        this.sampleRate = (_b = options === null || options === void 0 ? void 0 : options.sampleRate) !== null && _b !== void 0 ? _b : 1;
        this.flushTimer = (_c = options === null || options === void 0 ? void 0 : options.flushTimer) !== null && _c !== void 0 ? _c : 30 * 1000; /* 30s */
        this.maxQueueSize = (_d = options === null || options === void 0 ? void 0 : options.maxQueueSize) !== null && _d !== void 0 ? _d : 20;
        this.queue = [];
        if (this.sampleRate > 0) {
            var flushing_1 = false;
            var run_1 = function () {
                if (flushing_1) {
                    return;
                }
                flushing_1 = true;
                _this.flush().catch(logError);
                flushing_1 = false;
                setTimeout(run_1, _this.flushTimer);
            };
            run_1();
        }
    }
    RemoteMetrics.prototype.increment = function (metric, tags) {
        // All metrics are part of an allow list in Tracking API
        if (!metric.includes('analytics_js.')) {
            return;
        }
        // /m doesn't like empty tags
        if (tags.length === 0) {
            return;
        }
        if (Math.random() > this.sampleRate) {
            return;
        }
        if (this.queue.length >= this.maxQueueSize) {
            return;
        }
        var remoteMetric = createRemoteMetric(metric, tags, getVersionType());
        this.queue.push(remoteMetric);
        if (metric.includes('error')) {
            this.flush().catch(logError);
        }
    };
    RemoteMetrics.prototype.flush = function () {
        return __awaiter(this, void 0, void 0, function () {
            var _this = this;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if (this.queue.length <= 0) {
                            return [2 /*return*/];
                        }
                        return [4 /*yield*/, this.send().catch(function (error) {
                                logError(error);
                                _this.sampleRate = 0;
                            })];
                    case 1:
                        _a.sent();
                        return [2 /*return*/];
                }
            });
        });
    };
    RemoteMetrics.prototype.send = function () {
        return __awaiter(this, void 0, void 0, function () {
            var payload, headers, url;
            return __generator(this, function (_a) {
                payload = { series: this.queue };
                this.queue = [];
                headers = { 'Content-Type': 'text/plain' };
                url = "https://".concat(this.host, "/m");
                return [2 /*return*/, fetch(url, {
                        headers: headers,
                        body: JSON.stringify(payload),
                        method: 'POST',
                    })];
            });
        });
    };
    return RemoteMetrics;
}());
export { RemoteMetrics };
//# sourceMappingURL=remote-metrics.js.map