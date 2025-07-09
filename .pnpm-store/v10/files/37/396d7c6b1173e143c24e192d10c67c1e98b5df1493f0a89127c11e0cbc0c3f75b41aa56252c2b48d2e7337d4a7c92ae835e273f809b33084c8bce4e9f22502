"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isOffline = exports.isOnline = void 0;
var environment_1 = require("../environment");
function isOnline() {
    if ((0, environment_1.isBrowser)()) {
        return window.navigator.onLine;
    }
    return true;
}
exports.isOnline = isOnline;
function isOffline() {
    return !isOnline();
}
exports.isOffline = isOffline;
//# sourceMappingURL=index.js.map