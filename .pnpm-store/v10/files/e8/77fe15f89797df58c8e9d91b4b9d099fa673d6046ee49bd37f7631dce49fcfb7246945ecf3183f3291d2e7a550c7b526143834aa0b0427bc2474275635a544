/**
 * Return a promise that can be externally resolved
 */
export var createDeferred = function () {
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
//# sourceMappingURL=create-deferred.js.map