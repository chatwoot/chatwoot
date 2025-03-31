"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Stats = void 0;
var tslib_1 = require("tslib");
var analytics_core_1 = require("@segment/analytics-core");
var remote_metrics_1 = require("./remote-metrics");
var remoteMetrics;
var Stats = /** @class */ (function (_super) {
    tslib_1.__extends(Stats, _super);
    function Stats() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    Stats.initRemoteMetrics = function (options) {
        remoteMetrics = new remote_metrics_1.RemoteMetrics(options);
    };
    Stats.prototype.increment = function (metric, by, tags) {
        _super.prototype.increment.call(this, metric, by, tags);
        remoteMetrics === null || remoteMetrics === void 0 ? void 0 : remoteMetrics.increment(metric, tags !== null && tags !== void 0 ? tags : []);
    };
    return Stats;
}(analytics_core_1.CoreStats));
exports.Stats = Stats;
//# sourceMappingURL=index.js.map