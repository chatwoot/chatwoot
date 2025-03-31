"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var tslib_1 = require("tslib");
/* eslint-disable @typescript-eslint/no-floating-promises */
var parse_cdn_1 = require("../lib/parse-cdn");
var normalize_1 = require("../plugins/segmentio/normalize");
if (process.env.ASSET_PATH) {
    if (process.env.ASSET_PATH === '/dist/umd/') {
        // @ts-ignore
        __webpack_public_path__ = '/dist/umd/';
    }
    else {
        var cdn = (0, parse_cdn_1.getCDN)();
        (0, parse_cdn_1.setGlobalCDNUrl)(cdn);
        // @ts-ignore
        __webpack_public_path__ = cdn
            ? cdn + '/analytics-next/bundles/'
            : 'https://cdn.june.so/analytics-next/bundles/';
    }
}
(0, normalize_1.setVersionType)('web');
var standalone_analytics_1 = require("./standalone-analytics");
require("../lib/csp-detection");
var browser_polyfill_1 = require("../lib/browser-polyfill");
var remote_metrics_1 = require("../core/stats/remote-metrics");
var embedded_write_key_1 = require("../lib/embedded-write-key");
var csp_detection_1 = require("../lib/csp-detection");
function onError(err) {
    console.error('[analytics.js]', 'Failed to load Analytics.js', err);
    new remote_metrics_1.RemoteMetrics().increment('analytics_js.invoke.error', tslib_1.__spreadArray(tslib_1.__spreadArray([
        'type:initialization'
    ], (err instanceof Error
        ? ["message:".concat(err === null || err === void 0 ? void 0 : err.message), "name:".concat(err === null || err === void 0 ? void 0 : err.name)]
        : []), true), [
        "wk:".concat((0, embedded_write_key_1.embeddedWriteKey)()),
    ], false));
}
document.addEventListener('securitypolicyviolation', function (e) {
    (0, csp_detection_1.onCSPError)(e).catch(console.error);
});
/**
 * Attempts to run a promise and catch both sync and async errors.
 **/
function attempt(promise) {
    return tslib_1.__awaiter(this, void 0, void 0, function () {
        var result, err_1;
        return tslib_1.__generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    _a.trys.push([0, 2, , 3]);
                    return [4 /*yield*/, promise()];
                case 1:
                    result = _a.sent();
                    return [2 /*return*/, result];
                case 2:
                    err_1 = _a.sent();
                    onError(err_1);
                    return [3 /*break*/, 3];
                case 3: return [2 /*return*/];
            }
        });
    });
}
if ((0, browser_polyfill_1.shouldPolyfill)()) {
    // load polyfills in order to get AJS to work with old browsers
    var script_1 = document.createElement('script');
    script_1.setAttribute('src', 'https://cdnjs.cloudflare.com/ajax/libs/babel-polyfill/7.7.0/polyfill.min.js');
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function () {
            return document.body.appendChild(script_1);
        });
    }
    else {
        document.body.appendChild(script_1);
    }
    script_1.onload = function () {
        attempt(standalone_analytics_1.install);
    };
}
else {
    attempt(standalone_analytics_1.install);
}
//# sourceMappingURL=standalone.js.map