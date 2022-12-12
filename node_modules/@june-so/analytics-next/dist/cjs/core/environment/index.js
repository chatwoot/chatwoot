"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isServer = exports.isBrowser = void 0;
function isBrowser() {
    return typeof window !== 'undefined';
}
exports.isBrowser = isBrowser;
function isServer() {
    return !isBrowser();
}
exports.isServer = isServer;
//# sourceMappingURL=index.js.map