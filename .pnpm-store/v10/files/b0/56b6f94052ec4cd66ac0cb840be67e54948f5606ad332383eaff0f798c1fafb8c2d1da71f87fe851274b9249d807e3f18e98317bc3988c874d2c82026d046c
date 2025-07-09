"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AnalyticsNode = void 0;
var tslib_1 = require("tslib");
var analytics_1 = require("../core/analytics");
var validation_1 = require("../plugins/validation");
var analytics_node_1 = require("../plugins/analytics-node");
var event_queue_1 = require("../core/queue/event-queue");
var priority_queue_1 = require("../lib/priority-queue");
var AnalyticsNode = /** @class */ (function () {
    function AnalyticsNode() {
    }
    AnalyticsNode.load = function (settings) {
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            var cookieOptions, queue, options, analytics, nodeSettings, ctx;
            return tslib_1.__generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        cookieOptions = {
                            persist: false,
                        };
                        queue = new event_queue_1.EventQueue(new priority_queue_1.PriorityQueue(3, []));
                        options = { user: cookieOptions, group: cookieOptions };
                        analytics = new analytics_1.Analytics(settings, options, queue);
                        nodeSettings = {
                            writeKey: settings.writeKey,
                            name: 'analytics-node-next',
                            type: 'after',
                            version: 'latest',
                        };
                        return [4 /*yield*/, analytics.register(validation_1.validation, (0, analytics_node_1.analyticsNode)(nodeSettings))];
                    case 1:
                        ctx = _a.sent();
                        analytics.emit('initialize', settings, cookieOptions !== null && cookieOptions !== void 0 ? cookieOptions : {});
                        return [2 /*return*/, [analytics, ctx]];
                }
            });
        });
    };
    return AnalyticsNode;
}());
exports.AnalyticsNode = AnalyticsNode;
//# sourceMappingURL=index.js.map