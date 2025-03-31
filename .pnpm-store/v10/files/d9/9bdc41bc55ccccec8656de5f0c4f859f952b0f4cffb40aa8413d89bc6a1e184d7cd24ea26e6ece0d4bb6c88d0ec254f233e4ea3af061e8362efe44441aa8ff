"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.normalize = exports.utm = exports.ampId = exports.getVersionType = exports.setVersionType = void 0;
var tslib_1 = require("tslib");
var js_cookie_1 = tslib_1.__importDefault(require("js-cookie"));
var gracefulDecodeURIComponent_1 = require("../../core/query-string/gracefulDecodeURIComponent");
var tld_1 = require("../../core/user/tld");
var version_1 = require("../../generated/version");
var user_1 = require("../../core/user");
var cookieOptions;
function getCookieOptions() {
    if (cookieOptions) {
        return cookieOptions;
    }
    var domain = (0, tld_1.tld)(window.location.href);
    cookieOptions = {
        expires: 31536000000,
        secure: false,
        path: '/',
    };
    if (domain) {
        cookieOptions.domain = domain;
    }
    return cookieOptions;
}
// Default value will be updated to 'web' in `bundle-umd.ts` for web build.
var _version = 'npm';
function setVersionType(version) {
    _version = version;
}
exports.setVersionType = setVersionType;
function getVersionType() {
    return _version;
}
exports.getVersionType = getVersionType;
function ampId() {
    var ampId = js_cookie_1.default.get('_ga');
    if (ampId && ampId.startsWith('amp')) {
        return ampId;
    }
}
exports.ampId = ampId;
function utm(query) {
    if (query.startsWith('?')) {
        query = query.substring(1);
    }
    query = query.replace(/\?/g, '&');
    return query.split('&').reduce(function (acc, str) {
        var _a = str.split('='), k = _a[0], _b = _a[1], v = _b === void 0 ? '' : _b;
        if (k.includes('utm_') && k.length > 4) {
            var utmParam = k.substr(4);
            if (utmParam === 'campaign') {
                utmParam = 'name';
            }
            acc[utmParam] = (0, gracefulDecodeURIComponent_1.gracefulDecodeURIComponent)(v);
        }
        return acc;
    }, {});
}
exports.utm = utm;
function ads(query) {
    var queryIds = {
        btid: 'dataxu',
        urid: 'millennial-media',
    };
    if (query.startsWith('?')) {
        query = query.substring(1);
    }
    query = query.replace(/\?/g, '&');
    var parts = query.split('&');
    for (var _i = 0, parts_1 = parts; _i < parts_1.length; _i++) {
        var part = parts_1[_i];
        var _a = part.split('='), k = _a[0], v = _a[1];
        if (queryIds[k]) {
            return {
                id: v,
                type: queryIds[k],
            };
        }
    }
}
function referrerId(query, ctx, disablePersistance) {
    var storage = new user_1.UniversalStorage(disablePersistance ? [] : ['cookie'], (0, user_1.getAvailableStorageOptions)(getCookieOptions()));
    var stored = storage.get('s:context.referrer');
    var ad = ads(query);
    ad = ad !== null && ad !== void 0 ? ad : stored;
    if (!ad) {
        return;
    }
    if (ctx) {
        ctx.referrer = tslib_1.__assign(tslib_1.__assign({}, ctx.referrer), ad);
    }
    storage.set('s:context.referrer', ad);
}
function normalize(analytics, json, settings, integrations) {
    var _a, _b, _c, _d;
    var user = analytics.user();
    var query = window.location.search;
    json.context = (_b = (_a = json.context) !== null && _a !== void 0 ? _a : json.options) !== null && _b !== void 0 ? _b : {};
    var ctx = json.context;
    delete json.options;
    json.writeKey = settings === null || settings === void 0 ? void 0 : settings.apiKey;
    ctx.userAgent = window.navigator.userAgent;
    // @ts-ignore
    var locale = navigator.userLanguage || navigator.language;
    if (typeof ctx.locale === 'undefined' && typeof locale !== 'undefined') {
        ctx.locale = locale;
    }
    if (!ctx.library) {
        var type = getVersionType();
        if (type === 'web') {
            ctx.library = {
                name: 'analytics.js',
                version: "next-".concat(version_1.version),
            };
        }
        else {
            ctx.library = {
                name: 'analytics.js',
                version: "npm:next-".concat(version_1.version),
            };
        }
    }
    if (query && !ctx.campaign) {
        ctx.campaign = utm(query);
    }
    referrerId(query, ctx, (_c = analytics.options.disableClientPersistence) !== null && _c !== void 0 ? _c : false);
    json.userId = json.userId || user.id();
    json.anonymousId = json.anonymousId || user.anonymousId();
    json.sentAt = new Date();
    var failed = analytics.queue.failedInitializations || [];
    if (failed.length > 0) {
        json._metadata = { failedInitializations: failed };
    }
    var bundled = [];
    var unbundled = [];
    for (var key in integrations) {
        var integration = integrations[key];
        if (key === 'june.so') {
            bundled.push(key);
        }
        if (integration.bundlingStatus === 'bundled') {
            bundled.push(key);
        }
        if (integration.bundlingStatus === 'unbundled') {
            unbundled.push(key);
        }
    }
    // This will make sure that the disabled cloud mode destinations will be
    // included in the unbundled list.
    for (var _i = 0, _e = (settings === null || settings === void 0 ? void 0 : settings.unbundledIntegrations) || []; _i < _e.length; _i++) {
        var settingsUnbundled = _e[_i];
        if (!unbundled.includes(settingsUnbundled)) {
            unbundled.push(settingsUnbundled);
        }
    }
    var configIds = (_d = settings === null || settings === void 0 ? void 0 : settings.maybeBundledConfigIds) !== null && _d !== void 0 ? _d : {};
    var bundledConfigIds = [];
    bundled.sort().forEach(function (name) {
        var _a;
        ;
        ((_a = configIds[name]) !== null && _a !== void 0 ? _a : []).forEach(function (id) {
            bundledConfigIds.push(id);
        });
    });
    if ((settings === null || settings === void 0 ? void 0 : settings.addBundledMetadata) !== false) {
        json._metadata = tslib_1.__assign(tslib_1.__assign({}, json._metadata), { bundled: bundled.sort(), unbundled: unbundled.sort(), bundledIds: bundledConfigIds });
    }
    var amp = ampId();
    if (amp) {
        ctx.amp = { id: amp };
    }
    return json;
}
exports.normalize = normalize;
//# sourceMappingURL=normalize.js.map