"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.patch = patch;
// import { patch } from 'rrweb/typings/utils'
// copied from https://github.com/rrweb-io/rrweb/blob/8aea5b00a4dfe5a6f59bd2ae72bb624f45e51e81/packages/rrweb/src/utils.ts#L129
// which was copied from https://github.com/getsentry/sentry-javascript/blob/b2109071975af8bf0316d3b5b38f519bdaf5dc15/packages/utils/src/object.ts
var core_1 = require("@posthog/core");
function patch(source, name, replacement) {
    try {
        if (!(name in source)) {
            return function () {
                //
            };
        }
        var original_1 = source[name];
        var wrapped = replacement(original_1);
        // Make sure it's a function first, as we need to attach an empty prototype for `defineProperties` to work
        // otherwise it'll throw "TypeError: Object.defineProperties called on non-object"
        if ((0, core_1.isFunction)(wrapped)) {
            // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
            wrapped.prototype = wrapped.prototype || {};
            Object.defineProperties(wrapped, {
                __posthog_wrapped__: {
                    enumerable: false,
                    value: true,
                },
            });
        }
        source[name] = wrapped;
        return function () {
            source[name] = original_1;
        };
    }
    catch (_a) {
        return function () {
            //
        };
        // This can throw if multiple fill happens on a global object like XMLHttpRequest
        // Fixes https://github.com/getsentry/sentry-javascript/issues/2043
    }
}
//# sourceMappingURL=patch.js.map