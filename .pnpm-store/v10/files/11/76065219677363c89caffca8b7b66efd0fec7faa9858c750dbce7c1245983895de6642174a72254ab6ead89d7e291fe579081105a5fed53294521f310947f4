"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.invokeCallback = exports.sleep = exports.pTimeout = void 0;
function pTimeout(promise, timeout) {
    return new Promise(function (resolve, reject) {
        var timeoutId = setTimeout(function () {
            reject(Error('Promise timed out'));
        }, timeout);
        promise
            .then(function (val) {
            clearTimeout(timeoutId);
            return resolve(val);
        })
            .catch(reject);
    });
}
exports.pTimeout = pTimeout;
function sleep(timeoutInMs) {
    return new Promise(function (resolve) { return setTimeout(resolve, timeoutInMs); });
}
exports.sleep = sleep;
/**
 * @param ctx
 * @param callback - the function to invoke
 * @param delay - aka "timeout". The amount of time in ms to wait before invoking the callback.
 */
function invokeCallback(ctx, callback, delay) {
    var cb = function () {
        try {
            return Promise.resolve(callback(ctx));
        }
        catch (err) {
            return Promise.reject(err);
        }
    };
    return (sleep(delay)
        // pTimeout ensures that the callback can't cause the context to hang
        .then(function () { return pTimeout(cb(), 1000); })
        .catch(function (err) {
        ctx === null || ctx === void 0 ? void 0 : ctx.log('warn', 'Callback Error', { error: err });
        ctx === null || ctx === void 0 ? void 0 : ctx.stats.increment('callback_error');
    })
        .then(function () { return ctx; }));
}
exports.invokeCallback = invokeCallback;
//# sourceMappingURL=index.js.map