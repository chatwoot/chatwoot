"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isDocument = exports.isAngularZonePresent = void 0;
var globals_1 = require("./globals");
// When angular patches functions they pass the above `isNativeFunction` check (at least the MutationObserver)
var isAngularZonePresent = function () {
    return !!globals_1.window.Zone;
};
exports.isAngularZonePresent = isAngularZonePresent;
var isDocument = function (x) {
    // eslint-disable-next-line posthog-js/no-direct-document-check
    return x instanceof Document;
};
exports.isDocument = isDocument;
//# sourceMappingURL=type-utils.js.map