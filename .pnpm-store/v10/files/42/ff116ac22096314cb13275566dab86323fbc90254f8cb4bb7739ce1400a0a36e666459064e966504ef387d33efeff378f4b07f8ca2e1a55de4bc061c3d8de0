"use strict";
var __assign = (this && this.__assign) || function () {
    __assign = Object.assign || function(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
                t[p] = s[p];
        }
        return t;
    };
    return __assign.apply(this, arguments);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.sessionStore = exports.resetSessionStorageSupported = exports.memoryStore = exports.localPlusCookieStore = exports.localStore = exports.resetLocalStorageSupported = exports.cookieStore = exports.resetSubDomainCache = void 0;
exports.seekFirstNonPublicSubDomain = seekFirstNonPublicSubDomain;
exports.chooseCookieDomain = chooseCookieDomain;
var utils_1 = require("./utils");
var constants_1 = require("./constants");
var core_1 = require("@posthog/core");
var logger_1 = require("./utils/logger");
var globals_1 = require("./utils/globals");
var uuidv7_1 = require("./uuidv7");
// we store the discovered subdomain in memory because it might be read multiple times
var firstNonPublicSubDomain = '';
// helper to allow tests to clear this "cache"
var resetSubDomainCache = function () {
    firstNonPublicSubDomain = '';
};
exports.resetSubDomainCache = resetSubDomainCache;
/**
 * Browsers don't offer a way to check if something is a public suffix
 * e.g. `.com.au`, `.io`, `.org.uk`
 *
 * But they do reject cookies set on public suffixes
 * Setting a cookie on `.co.uk` would mean it was sent for every `.co.uk` site visited
 *
 * So, we can use this to check if a domain is a public suffix
 * by trying to set a cookie on a subdomain of the provided hostname
 * until the browser accepts it
 *
 * inspired by https://github.com/AngusFu/browser-root-domain
 */
function seekFirstNonPublicSubDomain(hostname, cookieJar) {
    if (cookieJar === void 0) { cookieJar = globals_1.document; }
    if (firstNonPublicSubDomain) {
        return firstNonPublicSubDomain;
    }
    if (!cookieJar) {
        return '';
    }
    if (['localhost', '127.0.0.1'].includes(hostname))
        return '';
    var list = hostname.split('.');
    var len = Math.min(list.length, 8); // paranoia - we know this number should be small
    var key = 'dmn_chk_' + (0, uuidv7_1.uuidv7)();
    while (!firstNonPublicSubDomain && len--) {
        var candidate = list.slice(len).join('.');
        var candidateCookieValue = key + '=1;domain=.' + candidate + ';path=/';
        // try to set cookie, include a short expiry in seconds since we'll check immediately
        cookieJar.cookie = candidateCookieValue + ';max-age=3';
        if (cookieJar.cookie.includes(key)) {
            // the cookie was accepted by the browser, remove the test cookie
            cookieJar.cookie = candidateCookieValue + ';max-age=0';
            firstNonPublicSubDomain = candidate;
        }
    }
    return firstNonPublicSubDomain;
}
var DOMAIN_MATCH_REGEX = /[a-z0-9][a-z0-9-]+\.[a-z]{2,}$/i;
var originalCookieDomainFn = function (hostname) {
    var matches = hostname.match(DOMAIN_MATCH_REGEX);
    return matches ? matches[0] : '';
};
function chooseCookieDomain(hostname, cross_subdomain) {
    if (cross_subdomain) {
        // NOTE: Could we use this for cross domain tracking?
        var matchedSubDomain = seekFirstNonPublicSubDomain(hostname);
        if (!matchedSubDomain) {
            var originalMatch = originalCookieDomainFn(hostname);
            if (originalMatch !== matchedSubDomain) {
                logger_1.logger.info('Warning: cookie subdomain discovery mismatch', originalMatch, matchedSubDomain);
            }
            matchedSubDomain = originalMatch;
        }
        return matchedSubDomain ? '; domain=.' + matchedSubDomain : '';
    }
    return '';
}
// Methods partially borrowed from quirksmode.org/js/cookies.html
exports.cookieStore = {
    _is_supported: function () { return !!globals_1.document; },
    _error: function (msg) {
        logger_1.logger.error('cookieStore error: ' + msg);
    },
    _get: function (name) {
        if (!globals_1.document) {
            return;
        }
        try {
            var nameEQ = name + '=';
            var ca = globals_1.document.cookie.split(';').filter(function (x) { return x.length; });
            for (var i = 0; i < ca.length; i++) {
                var c = ca[i];
                while (c.charAt(0) == ' ') {
                    c = c.substring(1, c.length);
                }
                if (c.indexOf(nameEQ) === 0) {
                    return decodeURIComponent(c.substring(nameEQ.length, c.length));
                }
            }
        }
        catch (_a) { }
        return null;
    },
    _parse: function (name) {
        var cookie;
        try {
            cookie = JSON.parse(exports.cookieStore._get(name)) || {};
        }
        catch (_a) {
            // noop
        }
        return cookie;
    },
    _set: function (name, value, days, cross_subdomain, is_secure) {
        if (!globals_1.document) {
            return;
        }
        try {
            var expires = '', secure = '';
            var cdomain = chooseCookieDomain(globals_1.document.location.hostname, cross_subdomain);
            if (days) {
                var date = new Date();
                date.setTime(date.getTime() + days * 24 * 60 * 60 * 1000);
                expires = '; expires=' + date.toUTCString();
            }
            if (is_secure) {
                secure = '; secure';
            }
            var new_cookie_val = name +
                '=' +
                encodeURIComponent(JSON.stringify(value)) +
                expires +
                '; SameSite=Lax; path=/' +
                cdomain +
                secure;
            // 4096 bytes is the size at which some browsers (e.g. firefox) will not store a cookie, warn slightly before that
            if (new_cookie_val.length > 4096 * 0.9) {
                logger_1.logger.warn('cookieStore warning: large cookie, len=' + new_cookie_val.length);
            }
            globals_1.document.cookie = new_cookie_val;
            return new_cookie_val;
        }
        catch (_a) {
            return;
        }
    },
    _remove: function (name, cross_subdomain) {
        if (!(globals_1.document === null || globals_1.document === void 0 ? void 0 : globals_1.document.cookie)) {
            return;
        }
        try {
            exports.cookieStore._set(name, '', -1, cross_subdomain);
        }
        catch (_a) {
            return;
        }
    },
};
var _localStorage_supported = null;
var resetLocalStorageSupported = function () {
    _localStorage_supported = null;
};
exports.resetLocalStorageSupported = resetLocalStorageSupported;
exports.localStore = {
    _is_supported: function () {
        if (!(0, core_1.isNull)(_localStorage_supported)) {
            return _localStorage_supported;
        }
        var supported = true;
        if (!(0, core_1.isUndefined)(globals_1.window)) {
            try {
                var key = '__mplssupport__', val = 'xyz';
                exports.localStore._set(key, val);
                if (exports.localStore._get(key) !== '"xyz"') {
                    supported = false;
                }
                exports.localStore._remove(key);
            }
            catch (_a) {
                supported = false;
            }
        }
        else {
            supported = false;
        }
        if (!supported) {
            logger_1.logger.error('localStorage unsupported; falling back to cookie store');
        }
        _localStorage_supported = supported;
        return supported;
    },
    _error: function (msg) {
        logger_1.logger.error('localStorage error: ' + msg);
    },
    _get: function (name) {
        try {
            return globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.localStorage.getItem(name);
        }
        catch (err) {
            exports.localStore._error(err);
        }
        return null;
    },
    _parse: function (name) {
        try {
            return JSON.parse(exports.localStore._get(name)) || {};
        }
        catch (_a) {
            // noop
        }
        return null;
    },
    _set: function (name, value) {
        try {
            globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.localStorage.setItem(name, JSON.stringify(value));
        }
        catch (err) {
            exports.localStore._error(err);
        }
    },
    _remove: function (name) {
        try {
            globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.localStorage.removeItem(name);
        }
        catch (err) {
            exports.localStore._error(err);
        }
    },
};
// Use localstorage for most data but still use cookie for COOKIE_PERSISTED_PROPERTIES
// This solves issues with cookies having too much data in them causing headers too large
// Also makes sure we don't have to send a ton of data to the server
var COOKIE_PERSISTED_PROPERTIES = [
    constants_1.DISTINCT_ID,
    constants_1.SESSION_ID,
    constants_1.SESSION_RECORDING_IS_SAMPLED,
    constants_1.ENABLE_PERSON_PROCESSING,
    constants_1.INITIAL_PERSON_INFO,
];
exports.localPlusCookieStore = __assign(__assign({}, exports.localStore), { _parse: function (name) {
        try {
            var cookieProperties = {};
            try {
                // See if there's a cookie stored with data.
                cookieProperties = exports.cookieStore._parse(name) || {};
            }
            catch (_a) { }
            var value = (0, utils_1.extend)(cookieProperties, JSON.parse(exports.localStore._get(name) || '{}'));
            exports.localStore._set(name, value);
            return value;
        }
        catch (_b) {
            // noop
        }
        return null;
    }, _set: function (name, value, days, cross_subdomain, is_secure, debug) {
        try {
            exports.localStore._set(name, value, undefined, undefined, debug);
            var cookiePersistedProperties_1 = {};
            COOKIE_PERSISTED_PROPERTIES.forEach(function (key) {
                if (value[key]) {
                    cookiePersistedProperties_1[key] = value[key];
                }
            });
            if (Object.keys(cookiePersistedProperties_1).length) {
                exports.cookieStore._set(name, cookiePersistedProperties_1, days, cross_subdomain, is_secure, debug);
            }
        }
        catch (err) {
            exports.localStore._error(err);
        }
    }, _remove: function (name, cross_subdomain) {
        try {
            globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.localStorage.removeItem(name);
            exports.cookieStore._remove(name, cross_subdomain);
        }
        catch (err) {
            exports.localStore._error(err);
        }
    } });
var memoryStorage = {};
// Storage that only lasts the length of the pageview if we don't want to use cookies
exports.memoryStore = {
    _is_supported: function () {
        return true;
    },
    _error: function (msg) {
        logger_1.logger.error('memoryStorage error: ' + msg);
    },
    _get: function (name) {
        return memoryStorage[name] || null;
    },
    _parse: function (name) {
        return memoryStorage[name] || null;
    },
    _set: function (name, value) {
        memoryStorage[name] = value;
    },
    _remove: function (name) {
        delete memoryStorage[name];
    },
};
var sessionStorageSupported = null;
var resetSessionStorageSupported = function () {
    sessionStorageSupported = null;
};
exports.resetSessionStorageSupported = resetSessionStorageSupported;
// Storage that only lasts the length of a tab/window. Survives page refreshes
exports.sessionStore = {
    _is_supported: function () {
        if (!(0, core_1.isNull)(sessionStorageSupported)) {
            return sessionStorageSupported;
        }
        sessionStorageSupported = true;
        if (!(0, core_1.isUndefined)(globals_1.window)) {
            try {
                var key = '__support__', val = 'xyz';
                exports.sessionStore._set(key, val);
                if (exports.sessionStore._get(key) !== '"xyz"') {
                    sessionStorageSupported = false;
                }
                exports.sessionStore._remove(key);
            }
            catch (_a) {
                sessionStorageSupported = false;
            }
        }
        else {
            sessionStorageSupported = false;
        }
        return sessionStorageSupported;
    },
    _error: function (msg) {
        logger_1.logger.error('sessionStorage error: ', msg);
    },
    _get: function (name) {
        try {
            return globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.sessionStorage.getItem(name);
        }
        catch (err) {
            exports.sessionStore._error(err);
        }
        return null;
    },
    _parse: function (name) {
        try {
            return JSON.parse(exports.sessionStore._get(name)) || null;
        }
        catch (_a) {
            // noop
        }
        return null;
    },
    _set: function (name, value) {
        try {
            globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.sessionStorage.setItem(name, JSON.stringify(value));
        }
        catch (err) {
            exports.sessionStore._error(err);
        }
    },
    _remove: function (name) {
        try {
            globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.sessionStorage.removeItem(name);
        }
        catch (err) {
            exports.sessionStore._error(err);
        }
    },
};
//# sourceMappingURL=storage.js.map