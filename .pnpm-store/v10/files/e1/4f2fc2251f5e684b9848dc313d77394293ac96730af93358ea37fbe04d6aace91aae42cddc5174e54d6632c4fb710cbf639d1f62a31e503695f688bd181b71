"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onCSPError = void 0;
var tslib_1 = require("tslib");
var load_script_1 = require("./load-script");
var parse_cdn_1 = require("./parse-cdn");
var ajsIdentifiedCSP = false;
function onCSPError(e) {
    return tslib_1.__awaiter(this, void 0, void 0, function () {
        var classicPath;
        return tslib_1.__generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    if (e.disposition === 'report') {
                        return [2 /*return*/];
                    }
                    if (!e.blockedURI.includes('cdn.segment') || ajsIdentifiedCSP) {
                        return [2 /*return*/];
                    }
                    ajsIdentifiedCSP = true;
                    console.warn('Your CSP policy is missing permissions required in order to run Analytics.js 2.0');
                    console.warn('Reverting to Analytics.js 1.0');
                    classicPath = (0, parse_cdn_1.getLegacyAJSPath)();
                    return [4 /*yield*/, (0, load_script_1.loadScript)(classicPath)];
                case 1:
                    _a.sent();
                    return [2 /*return*/];
            }
        });
    });
}
exports.onCSPError = onCSPError;
//# sourceMappingURL=csp-detection.js.map