import { __awaiter, __generator, __spreadArray } from "tslib";
/* eslint-disable @typescript-eslint/no-floating-promises */
import { getCDN, setGlobalCDNUrl } from '../lib/parse-cdn';
import { setVersionType } from '../plugins/segmentio/normalize';
if (process.env.ASSET_PATH) {
    if (process.env.ASSET_PATH === '/dist/umd/') {
        // @ts-ignore
        __webpack_public_path__ = '/dist/umd/';
    }
    else {
        var cdn = getCDN();
        setGlobalCDNUrl(cdn);
        // @ts-ignore
        __webpack_public_path__ = cdn
            ? cdn + '/analytics-next/bundles/'
            : 'https://cdn.june.so/analytics-next/bundles/';
    }
}
setVersionType('web');
import { install } from './standalone-analytics';
import '../lib/csp-detection';
import { shouldPolyfill } from '../lib/browser-polyfill';
import { RemoteMetrics } from '../core/stats/remote-metrics';
import { embeddedWriteKey } from '../lib/embedded-write-key';
import { onCSPError } from '../lib/csp-detection';
function onError(err) {
    console.error('[analytics.js]', 'Failed to load Analytics.js', err);
    new RemoteMetrics().increment('analytics_js.invoke.error', __spreadArray(__spreadArray([
        'type:initialization'
    ], (err instanceof Error
        ? ["message:".concat(err === null || err === void 0 ? void 0 : err.message), "name:".concat(err === null || err === void 0 ? void 0 : err.name)]
        : []), true), [
        "wk:".concat(embeddedWriteKey()),
    ], false));
}
document.addEventListener('securitypolicyviolation', function (e) {
    onCSPError(e).catch(console.error);
});
/**
 * Attempts to run a promise and catch both sync and async errors.
 **/
function attempt(promise) {
    return __awaiter(this, void 0, void 0, function () {
        var result, err_1;
        return __generator(this, function (_a) {
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
if (shouldPolyfill()) {
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
        attempt(install);
    };
}
else {
    attempt(install);
}
//# sourceMappingURL=standalone.js.map