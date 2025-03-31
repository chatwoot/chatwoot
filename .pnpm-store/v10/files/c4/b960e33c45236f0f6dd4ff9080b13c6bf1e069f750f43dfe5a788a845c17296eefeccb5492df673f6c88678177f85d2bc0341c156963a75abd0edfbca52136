"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getLegacyAJSPath = exports.getNextIntegrationsURL = exports.getCDN = exports.setGlobalCDNUrl = void 0;
var embedded_write_key_1 = require("./embedded-write-key");
var analyticsScriptRegex = /(https:\/\/.*)\/analytics\.js\/v1\/(?:.*?)\/(?:platform|analytics.*)?/;
var getCDNUrlFromScriptTag = function () {
    var cdn;
    var scripts = Array.prototype.slice.call(document.querySelectorAll('script'));
    scripts.forEach(function (s) {
        var _a;
        var src = (_a = s.getAttribute('src')) !== null && _a !== void 0 ? _a : '';
        var result = analyticsScriptRegex.exec(src);
        if (result && result[1]) {
            cdn = result[1];
        }
    });
    return cdn;
};
var _globalCDN; // set globalCDN as in-memory singleton
var getGlobalCDNUrl = function () {
    var _a;
    var result = _globalCDN !== null && _globalCDN !== void 0 ? _globalCDN : (_a = window.analytics) === null || _a === void 0 ? void 0 : _a._cdn;
    return result;
};
var setGlobalCDNUrl = function (cdn) {
    if (window.analytics) {
        window.analytics._cdn = cdn;
    }
    _globalCDN = cdn;
};
exports.setGlobalCDNUrl = setGlobalCDNUrl;
var getCDN = function () {
    var globalCdnUrl = getGlobalCDNUrl();
    if (globalCdnUrl)
        return globalCdnUrl;
    var cdnFromScriptTag = getCDNUrlFromScriptTag();
    if (cdnFromScriptTag) {
        return cdnFromScriptTag;
    }
    else {
        // it's possible that the CDN is not found in the page because:
        // - the script is loaded through a proxy
        // - the script is removed after execution
        // in this case, we fall back to the default Segment CDN
        return "https://cdn.june.so";
    }
};
exports.getCDN = getCDN;
var getNextIntegrationsURL = function () {
    var cdn = (0, exports.getCDN)();
    return "".concat(cdn, "/next-integrations");
};
exports.getNextIntegrationsURL = getNextIntegrationsURL;
/**
 * Replaces the CDN URL in the script tag with the one from Analytics.js 1.0
 *
 * @returns the path to Analytics JS 1.0
 **/
function getLegacyAJSPath() {
    var _a, _b;
    var writeKey = (_a = (0, embedded_write_key_1.embeddedWriteKey)()) !== null && _a !== void 0 ? _a : window.analytics._writeKey;
    var scripts = Array.prototype.slice.call(document.querySelectorAll('script'));
    var path = undefined;
    for (var _i = 0, scripts_1 = scripts; _i < scripts_1.length; _i++) {
        var s = scripts_1[_i];
        var src = (_b = s.getAttribute('src')) !== null && _b !== void 0 ? _b : '';
        var result = analyticsScriptRegex.exec(src);
        if (result && result[1]) {
            path = src;
            break;
        }
    }
    if (path) {
        return path.replace('analytics.min.js', 'analytics.classic.js');
    }
    return "https://cdn.june.so/analytics.js/v1/".concat(writeKey, "/analytics.classic.js");
}
exports.getLegacyAJSPath = getLegacyAJSPath;
//# sourceMappingURL=parse-cdn.js.map