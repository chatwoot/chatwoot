"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ContextCancelation = exports.Context = void 0;
var tslib_1 = require("tslib");
var analytics_core_1 = require("@segment/analytics-core");
Object.defineProperty(exports, "ContextCancelation", { enumerable: true, get: function () { return analytics_core_1.ContextCancelation; } });
var stats_1 = require("../stats");
var Context = /** @class */ (function (_super) {
    tslib_1.__extends(Context, _super);
    function Context(event, id) {
        return _super.call(this, event, id, new stats_1.Stats()) || this;
    }
    Context.system = function () {
        return new this({ type: 'track', event: 'system' });
    };
    return Context;
}(analytics_core_1.CoreContext));
exports.Context = Context;
//# sourceMappingURL=index.js.map