"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createDeferred = void 0;
/**
 * Return a promise that can be externally resolved
 */
var createDeferred = function () {
    var resolve;
    var reject;
    var promise = new Promise(function (_resolve, _reject) {
        resolve = _resolve;
        reject = _reject;
    });
    return {
        resolve: resolve,
        reject: reject,
        promise: promise,
    };
};
exports.createDeferred = createDeferred;
//# sourceMappingURL=create-deferred.js.map