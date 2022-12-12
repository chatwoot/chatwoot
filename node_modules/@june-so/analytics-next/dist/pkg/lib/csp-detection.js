import { __awaiter, __generator } from "tslib";
import { loadScript } from './load-script';
import { getLegacyAJSPath } from './parse-cdn';
var ajsIdentifiedCSP = false;
export function onCSPError(e) {
    return __awaiter(this, void 0, void 0, function () {
        var classicPath;
        return __generator(this, function (_a) {
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
                    classicPath = getLegacyAJSPath();
                    return [4 /*yield*/, loadScript(classicPath)];
                case 1:
                    _a.sent();
                    return [2 /*return*/];
            }
        });
    });
}
//# sourceMappingURL=csp-detection.js.map