import { __awaiter, __generator } from "tslib";
import { fetch } from '../../lib/fetch';
import { onPageLeave } from '../../lib/on-page-leave';
var MAX_PAYLOAD_SIZE = 500;
function kilobytes(buffer) {
    var size = encodeURI(JSON.stringify(buffer)).split(/%..|./).length - 1;
    return size / 1024;
}
/**
 * Checks if the payload is over or close to
 * the maximum payload size allowed by tracking
 * API.
 */
function approachingTrackingAPILimit(buffer) {
    return kilobytes(buffer) >= MAX_PAYLOAD_SIZE - 50;
}
function chunks(batch) {
    var result = [];
    var index = 0;
    batch.forEach(function (item) {
        var size = kilobytes(result[index]);
        if (size >= 64) {
            index++;
        }
        if (result[index]) {
            result[index].push(item);
        }
        else {
            result[index] = [item];
        }
    });
    return result;
}
export default function batch(apiHost, config) {
    var _a, _b;
    var buffer = [];
    var pageUnloaded = false;
    var limit = (_a = config === null || config === void 0 ? void 0 : config.size) !== null && _a !== void 0 ? _a : 10;
    var timeout = (_b = config === null || config === void 0 ? void 0 : config.timeout) !== null && _b !== void 0 ? _b : 5000;
    function sendBatch(batch) {
        var _a;
        if (batch.length === 0) {
            return;
        }
        var writeKey = (_a = batch[0]) === null || _a === void 0 ? void 0 : _a.writeKey;
        return fetch("https://".concat(apiHost, "/b"), {
            keepalive: pageUnloaded,
            headers: {
                'Content-Type': 'application/json',
            },
            method: 'post',
            body: JSON.stringify({ batch: batch, writeKey: writeKey }),
        });
    }
    function flush() {
        return __awaiter(this, void 0, void 0, function () {
            var batch_1;
            return __generator(this, function (_a) {
                if (buffer.length) {
                    batch_1 = buffer;
                    buffer = [];
                    return [2 /*return*/, sendBatch(batch_1)];
                }
                return [2 /*return*/];
            });
        });
    }
    var schedule;
    function scheduleFlush() {
        if (schedule) {
            return;
        }
        schedule = setTimeout(function () {
            schedule = undefined;
            flush().catch(console.error);
        }, timeout);
    }
    onPageLeave(function () {
        pageUnloaded = true;
        if (buffer.length) {
            var reqs = chunks(buffer).map(sendBatch);
            Promise.all(reqs).catch(console.error);
        }
    });
    function dispatch(_url, body) {
        return __awaiter(this, void 0, void 0, function () {
            var bufferOverflow;
            return __generator(this, function (_a) {
                buffer.push(body);
                bufferOverflow = buffer.length >= limit || approachingTrackingAPILimit(buffer);
                return [2 /*return*/, bufferOverflow || pageUnloaded ? flush() : scheduleFlush()];
            });
        });
    }
    return {
        dispatch: dispatch,
    };
}
//# sourceMappingURL=batched-dispatcher.js.map