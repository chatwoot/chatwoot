import { __awaiter, __generator } from "tslib";
import { Analytics } from '../core/analytics';
import { validation } from '../plugins/validation';
import { analyticsNode } from '../plugins/analytics-node';
import { EventQueue } from '../core/queue/event-queue';
import { PriorityQueue } from '../lib/priority-queue';
var AnalyticsNode = /** @class */ (function () {
    function AnalyticsNode() {
    }
    AnalyticsNode.load = function (settings) {
        return __awaiter(this, void 0, void 0, function () {
            var cookieOptions, queue, options, analytics, nodeSettings, ctx;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        cookieOptions = {
                            persist: false,
                        };
                        queue = new EventQueue(new PriorityQueue(3, []));
                        options = { user: cookieOptions, group: cookieOptions };
                        analytics = new Analytics(settings, options, queue);
                        nodeSettings = {
                            writeKey: settings.writeKey,
                            name: 'analytics-node-next',
                            type: 'after',
                            version: 'latest',
                        };
                        return [4 /*yield*/, analytics.register(validation, analyticsNode(nodeSettings))];
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
export { AnalyticsNode };
//# sourceMappingURL=index.js.map