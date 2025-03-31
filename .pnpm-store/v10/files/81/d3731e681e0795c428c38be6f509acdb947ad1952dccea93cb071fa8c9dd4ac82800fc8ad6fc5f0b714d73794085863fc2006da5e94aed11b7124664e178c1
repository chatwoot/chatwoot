import { __awaiter, __generator } from "tslib";
import { isOffline } from '../../core/connection';
import { Context } from '../../core/context';
import { attempt } from '@segment/analytics-core';
import { pWhile } from '../../lib/p-while';
function flushQueue(xt, queue) {
    return __awaiter(this, void 0, void 0, function () {
        var failedQueue;
        var _this = this;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    failedQueue = [];
                    if (isOffline()) {
                        return [2 /*return*/, queue];
                    }
                    return [4 /*yield*/, pWhile(function () { return queue.length > 0 && !isOffline(); }, function () { return __awaiter(_this, void 0, void 0, function () {
                            var ctx, result, success;
                            return __generator(this, function (_a) {
                                switch (_a.label) {
                                    case 0:
                                        ctx = queue.pop();
                                        if (!ctx) {
                                            return [2 /*return*/];
                                        }
                                        return [4 /*yield*/, attempt(ctx, xt)];
                                    case 1:
                                        result = _a.sent();
                                        success = result instanceof Context;
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
export function scheduleFlush(flushing, buffer, xt, scheduleFlush) {
    var _this = this;
    if (flushing) {
        return;
    }
    // eslint-disable-next-line @typescript-eslint/no-misused-promises
    setTimeout(function () { return __awaiter(_this, void 0, void 0, function () {
        var isFlushing, newBuffer;
        return __generator(this, function (_a) {
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
//# sourceMappingURL=schedule-flush.js.map