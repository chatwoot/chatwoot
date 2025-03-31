"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.scheduleFlush = void 0;
var tslib_1 = require("tslib");
var connection_1 = require("../../core/connection");
var context_1 = require("../../core/context");
var analytics_core_1 = require("@segment/analytics-core");
var p_while_1 = require("../../lib/p-while");
function flushQueue(xt, queue) {
    return tslib_1.__awaiter(this, void 0, void 0, function () {
        var failedQueue;
        var _this = this;
        return tslib_1.__generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    failedQueue = [];
                    if ((0, connection_1.isOffline)()) {
                        return [2 /*return*/, queue];
                    }
                    return [4 /*yield*/, (0, p_while_1.pWhile)(function () { return queue.length > 0 && !(0, connection_1.isOffline)(); }, function () { return tslib_1.__awaiter(_this, void 0, void 0, function () {
                            var ctx, result, success;
                            return tslib_1.__generator(this, function (_a) {
                                switch (_a.label) {
                                    case 0:
                                        ctx = queue.pop();
                                        if (!ctx) {
                                            return [2 /*return*/];
                                        }
                                        return [4 /*yield*/, (0, analytics_core_1.attempt)(ctx, xt)];
                                    case 1:
                                        result = _a.sent();
                                        success = result instanceof context_1.Context;
                                        if (!success) {
                                            failedQueue.push(ctx);
                                        }
                                        return [2 /*return*/];
                                }
                            });
                        }); })
                        // re-add failed tasks
                    ];
                case 1:
                    _a.sent();
                    // re-add failed tasks
                    failedQueue.map(function (failed) { return queue.pushWithBackoff(failed); });
                    return [2 /*return*/, queue];
            }
        });
    });
}
function scheduleFlush(flushing, buffer, xt, scheduleFlush) {
    var _this = this;
    if (flushing) {
        return;
    }
    // eslint-disable-next-line @typescript-eslint/no-misused-promises
    setTimeout(function () { return tslib_1.__awaiter(_this, void 0, void 0, function () {
        var isFlushing, newBuffer;
        return tslib_1.__generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    isFlushing = true;
                    return [4 /*yield*/, flushQueue(xt, buffer)];
                case 1:
                    newBuffer = _a.sent();
                    isFlushing = false;
                    if (buffer.todo > 0) {
                        scheduleFlush(isFlushing, newBuffer, xt, scheduleFlush);
                    }
                    return [2 /*return*/];
            }
        });
    }); }, Math.random() * 5000);
}
exports.scheduleFlush = scheduleFlush;
//# sourceMappingURL=schedule-flush.js.map