"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getGlobal = void 0;
// This an imperfect polyfill for globalThis
var getGlobal = function () {
    if (typeof globalThis !== 'undefined') {
        return globalThis;
    }
    if (typeof self !== 'undefined') {
        return self;
    }
    if (typeof window !== 'undefined') {
        return window;
    }
    if (typeof global !== 'undefined') {
        return global;
    }
    return null;
};
exports.getGlobal = getGlobal;
//# sourceMappingURL=get-global.js.map