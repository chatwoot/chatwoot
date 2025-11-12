"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.window = exports.assignableWindow = exports.userAgent = exports.AbortController = exports.XMLHttpRequest = exports.fetch = exports.location = exports.document = exports.navigator = exports.nativeIndexOf = exports.nativeForEach = exports.ArrayProto = void 0;
/*
 * Global helpers to protect access to browser globals in a way that is safer for different targets
 * like DOM, SSR, Web workers etc.
 *
 * NOTE: Typically we want the "window" but globalThis works for both the typical browser context as
 * well as other contexts such as the web worker context. Window is still exported for any bits that explicitly require it.
 * If in doubt - export the global you need from this file and use that as an optional value. This way the code path is forced
 * to handle the case where the global is not available.
 */
// eslint-disable-next-line no-restricted-globals
var win = typeof window !== 'undefined' ? window : undefined;
exports.window = win;
var global = typeof globalThis !== 'undefined' ? globalThis : win;
exports.ArrayProto = Array.prototype;
exports.nativeForEach = exports.ArrayProto.forEach;
exports.nativeIndexOf = exports.ArrayProto.indexOf;
exports.navigator = global === null || global === void 0 ? void 0 : global.navigator;
exports.document = global === null || global === void 0 ? void 0 : global.document;
exports.location = global === null || global === void 0 ? void 0 : global.location;
exports.fetch = global === null || global === void 0 ? void 0 : global.fetch;
exports.XMLHttpRequest = (global === null || global === void 0 ? void 0 : global.XMLHttpRequest) && 'withCredentials' in new global.XMLHttpRequest() ? global.XMLHttpRequest : undefined;
exports.AbortController = global === null || global === void 0 ? void 0 : global.AbortController;
exports.userAgent = exports.navigator === null || exports.navigator === void 0 ? void 0 : exports.navigator.userAgent;
exports.assignableWindow = win !== null && win !== void 0 ? win : {};
//# sourceMappingURL=globals.js.map