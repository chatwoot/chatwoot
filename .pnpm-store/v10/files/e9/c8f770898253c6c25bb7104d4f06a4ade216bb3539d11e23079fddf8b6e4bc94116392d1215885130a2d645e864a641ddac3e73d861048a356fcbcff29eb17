"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.EventQueue = void 0;
var tslib_1 = require("tslib");
var persisted_1 = require("../../lib/priority-queue/persisted");
var analytics_core_1 = require("@segment/analytics-core");
var EventQueue = /** @class */ (function (_super) {
    tslib_1.__extends(EventQueue, _super);
    function EventQueue(priorityQueue) {
        return _super.call(this, priorityQueue !== null && priorityQueue !== void 0 ? priorityQueue : new persisted_1.PersistedPriorityQueue(4, 'event-queue')) || this;
    }
    return EventQueue;
}(analytics_core_1.CoreEventQueue));
exports.EventQueue = EventQueue;
//# sourceMappingURL=event-queue.js.map