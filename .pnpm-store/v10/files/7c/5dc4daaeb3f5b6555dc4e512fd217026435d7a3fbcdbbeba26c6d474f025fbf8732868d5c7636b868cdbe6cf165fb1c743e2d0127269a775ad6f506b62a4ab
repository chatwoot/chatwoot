"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.popSnippetWindowBuffer = exports.transformSnippetCall = void 0;
function transformSnippetCall(_a) {
    var methodName = _a[0], args = _a.slice(1);
    return {
        method: methodName,
        resolve: function () { },
        reject: console.error,
        args: args,
        called: false,
    };
}
exports.transformSnippetCall = transformSnippetCall;
var normalizeSnippetBuffer = function (buffer) {
    return buffer.map(transformSnippetCall);
};
/**
 * Fetch the buffered method calls from the window object and normalize them.
 * This removes existing buffered calls from the window object.
 */
var popSnippetWindowBuffer = function () {
    var wa = window.analytics;
    if (!Array.isArray(wa))
        return [];
    var buffered = wa.splice(0, wa.length);
    return normalizeSnippetBuffer(buffered);
};
exports.popSnippetWindowBuffer = popSnippetWindowBuffer;
//# sourceMappingURL=snippet.js.map