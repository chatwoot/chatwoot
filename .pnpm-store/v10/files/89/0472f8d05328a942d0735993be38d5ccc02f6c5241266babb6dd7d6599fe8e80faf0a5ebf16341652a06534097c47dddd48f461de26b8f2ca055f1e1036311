import { __assign } from "tslib";
import jar from 'js-cookie';
import { gracefulDecodeURIComponent } from '../../core/query-string/gracefulDecodeURIComponent';
import { tld } from '../../core/user/tld';
import { version } from '../../generated/version';
import { getAvailableStorageOptions, UniversalStorage } from '../../core/user';
var cookieOptions;
function getCookieOptions() {
    if (cookieOptions) {
        return cookieOptions;
    }
    var domain = tld(window.location.href);
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
export function setVersionType(version) {
    _version = version;
}
export function getVersionType() {
    return _version;
}
export function ampId() {
    var ampId = jar.get('_ga');
    if (ampId && ampId.startsWith('amp')) {
        return ampId;
    }
}
export function utm(query) {
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
            acc[utmParam] = gracefulDecodeURIComponent(v);
        }
        return acc;
    }, {});
}
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
    var storage = new UniversalStorage(disablePersistance ? [] : ['cookie'], getAvailableStorageOptions(getCookieOptions()));
    var stored = storage.get('s:context.referrer');
    var ad = ads(query);
    ad = ad !== null && ad !== void 0 ? ad : stored;
    if (!ad) {
        return;
    }
    if (ctx) {
        ctx.referrer = __assign(__assign({}, ctx.referrer), ad);
    }
    storage.set('s:context.referrer', ad);
}
export function normalize(analytics, json, settings, integrations) {
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
                version: "next-".concat(version),
            };
        }
        else {
            ctx.library = {
                name: 'analytics.js',
                version: "npm:next-".concat(version),
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
        json._metadata = __assign(__assign({}, json._metadata), { bundled: bundled.sort(), unbundled: unbundled.sort(), bundledIds: bundledConfigIds });
    }
    var amp = ampId();
    if (amp) {
        ctx.amp = { id: amp };
    }
    return json;
}
//# sourceMappingURL=normalize.js.map