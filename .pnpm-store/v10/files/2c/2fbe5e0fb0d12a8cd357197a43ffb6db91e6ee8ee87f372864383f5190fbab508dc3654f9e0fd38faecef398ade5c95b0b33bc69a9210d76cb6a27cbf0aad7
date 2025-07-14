import { __extends } from "tslib";
import { CoreStats } from '@segment/analytics-core';
import { RemoteMetrics } from './remote-metrics';
var remoteMetrics;
var Stats = /** @class */ (function (_super) {
    __extends(Stats, _super);
    function Stats() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    Stats.initRemoteMetrics = function (options) {
        remoteMetrics = new RemoteMetrics(options);
    };
    Stats.prototype.increment = function (metric, by, tags) {
        _super.prototype.increment.call(this, metric, by, tags);
        remoteMetrics === null || remoteMetrics === void 0 ? void 0 : remoteMetrics.increment(metric, tags !== null && tags !== void 0 ? tags : []);
    };
    return Stats;
}(CoreStats));
export { Stats };
//# sourceMappingURL=index.js.map