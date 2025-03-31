"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AnalyticsBrowser = exports.loadLegacySettings = void 0;
var tslib_1 = require("tslib");
var get_process_env_1 = require("../lib/get-process-env");
var parse_cdn_1 = require("../lib/parse-cdn");
var analytics_1 = require("../core/analytics");
var merged_options_1 = require("../lib/merged-options");
var create_deferred_1 = require("../lib/create-deferred");
var page_enrichment_1 = require("../plugins/page-enrichment");
var remote_loader_1 = require("../plugins/remote-loader");
var segmentio_1 = require("../plugins/segmentio");
var validation_1 = require("../plugins/validation");
var buffer_1 = require("../core/buffer");
var snippet_1 = require("../core/buffer/snippet");
var inspector_1 = require("../core/inspector");
var stats_1 = require("../core/stats");
function loadLegacySettings(cdnURL) {
    var baseUrl = cdnURL !== null && cdnURL !== void 0 ? cdnURL : (0, parse_cdn_1.getCDN)();
    baseUrl;
    return {
        integrations: {}
    };
}
exports.loadLegacySettings = loadLegacySettings;
function hasLegacyDestinations(settings) {
    return ((0, get_process_env_1.getProcessEnv)().NODE_ENV !== 'test' &&
        // just one integration means segmentio
        Object.keys(settings.integrations).length > 1);
}
function hasTsubMiddleware(settings) {
    var _a, _b, _c;
    return ((0, get_process_env_1.getProcessEnv)().NODE_ENV !== 'test' &&
        ((_c = (_b = (_a = settings.middlewareSettings) === null || _a === void 0 ? void 0 : _a.routingRules) === null || _b === void 0 ? void 0 : _b.length) !== null && _c !== void 0 ? _c : 0) > 0);
}
/**
 * With AJS classic, we allow users to call setAnonymousId before the library initialization.
 * This is important because some of the destinations will use the anonymousId during the initialization,
 * and if we set anonId afterwards, that wouldn’t impact the destination.
 *
 * Also Ensures events can be registered before library initialization.
 * This is important so users can register to 'initialize' and any events that may fire early during setup.
 */
function flushPreBuffer(analytics, buffer) {
    buffer.push.apply(buffer, (0, snippet_1.popSnippetWindowBuffer)());
    (0, buffer_1.flushSetAnonymousID)(analytics, buffer);
    (0, buffer_1.flushOn)(analytics, buffer);
}
/**
 * Finish flushing buffer and cleanup.
 */
function flushFinalBuffer(analytics, buffer) {
    return tslib_1.__awaiter(this, void 0, void 0, function () {
        return tslib_1.__generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    // Call popSnippetWindowBuffer before each flush task since there may be
                    // analytics calls during async function calls.
                    buffer.push.apply(buffer, (0, snippet_1.popSnippetWindowBuffer)());
                    return [4 /*yield*/, (0, buffer_1.flushAddSourceMiddleware)(analytics, buffer)];
                case 1:
                    _a.sent();
                    buffer.push.apply(buffer, (0, snippet_1.popSnippetWindowBuffer)());
                    (0, buffer_1.flushAnalyticsCallsInNewTask)(analytics, buffer);
                    // Clear buffer, just in case analytics is loaded twice; we don't want to fire events off again.
                    buffer.clear();
                    return [2 /*return*/];
            }
        });
    });
}
function registerPlugins(legacySettings, analytics, opts, options, plugins, legacyIntegrationSources) {
    var _a, _b, _c;
    return tslib_1.__awaiter(this, void 0, void 0, function () {
        var tsubMiddleware, _d, legacyDestinations, _e, schemaFilter, _f, mergedSettings, remotePlugins, toRegister, shouldIgnoreSegmentio, ctx;
        var _this = this;
        return tslib_1.__generator(this, function (_g) {
            switch (_g.label) {
                case 0:
                    if (!hasTsubMiddleware(legacySettings)) return [3 /*break*/, 2];
                    return [4 /*yield*/, Promise.resolve().then(function () { return tslib_1.__importStar(require(
                        /* webpackChunkName: "tsub-middleware" */ '../plugins/routing-middleware')); }).then(function (mod) {
                            return mod.tsubMiddleware(legacySettings.middlewareSettings.routingRules);
                        })];
                case 1:
                    _d = _g.sent();
                    return [3 /*break*/, 3];
                case 2:
                    _d = undefined;
                    _g.label = 3;
                case 3:
                    tsubMiddleware = _d;
                    if (!(hasLegacyDestinations(legacySettings) || legacyIntegrationSources.length > 0)) return [3 /*break*/, 5];
                    return [4 /*yield*/, Promise.resolve().then(function () { return tslib_1.__importStar(require(
                        /* webpackChunkName: "ajs-destination" */ '../plugins/ajs-destination')); }).then(function (mod) {
                            return mod.ajsDestinations(legacySettings, analytics.integrations, opts, tsubMiddleware, legacyIntegrationSources);
                        })];
                case 4:
                    _e = _g.sent();
                    return [3 /*break*/, 6];
                case 5:
                    _e = [];
                    _g.label = 6;
                case 6:
                    legacyDestinations = _e;
                    if (!legacySettings.legacyVideoPluginsEnabled) return [3 /*break*/, 8];
                    return [4 /*yield*/, Promise.resolve().then(function () { return tslib_1.__importStar(require(
                        /* webpackChunkName: "legacyVideos" */ '../plugins/legacy-video-plugins')); }).then(function (mod) {
                            return mod.loadLegacyVideoPlugins(analytics);
                        })];
                case 7:
                    _g.sent();
                    _g.label = 8;
                case 8:
                    if (!((_a = opts.plan) === null || _a === void 0 ? void 0 : _a.track)) return [3 /*break*/, 10];
                    return [4 /*yield*/, Promise.resolve().then(function () { return tslib_1.__importStar(require(
                        /* webpackChunkName: "schemaFilter" */ '../plugins/schema-filter')); }).then(function (mod) {
                            var _a;
                            return mod.schemaFilter((_a = opts.plan) === null || _a === void 0 ? void 0 : _a.track, legacySettings);
                        })];
                case 9:
                    _f = _g.sent();
                    return [3 /*break*/, 11];
                case 10:
                    _f = undefined;
                    _g.label = 11;
                case 11:
                    schemaFilter = _f;
                    mergedSettings = (0, merged_options_1.mergedOptions)(legacySettings, options);
                    return [4 /*yield*/, (0, remote_loader_1.remoteLoader)(legacySettings, analytics.integrations, mergedSettings, options.obfuscate, tsubMiddleware).catch(function () { return []; })];
                case 12:
                    remotePlugins = _g.sent();
                    toRegister = tslib_1.__spreadArray(tslib_1.__spreadArray(tslib_1.__spreadArray([
                        validation_1.validation,
                        page_enrichment_1.pageEnrichment
                    ], plugins, true), legacyDestinations, true), remotePlugins, true);
                    if (schemaFilter) {
                        toRegister.push(schemaFilter);
                    }
                    shouldIgnoreSegmentio = (((_b = opts.integrations) === null || _b === void 0 ? void 0 : _b.All) === false && !opts.integrations['june.so']) ||
                        (opts.integrations && opts.integrations['june.so'] === false);
                    if (!shouldIgnoreSegmentio) {
                        toRegister.push((0, segmentio_1.segmentio)(analytics, mergedSettings['june.so'], legacySettings.integrations));
                    }
                    return [4 /*yield*/, analytics.register.apply(analytics, toRegister)];
                case 13:
                    ctx = _g.sent();
                    if (!Object.entries((_c = legacySettings.enabledMiddleware) !== null && _c !== void 0 ? _c : {}).some(function (_a) {
                        var enabled = _a[1];
                        return enabled;
                    })) return [3 /*break*/, 15];
                    return [4 /*yield*/, Promise.resolve().then(function () { return tslib_1.__importStar(require(
                        /* webpackChunkName: "remoteMiddleware" */ '../plugins/remote-middleware')); }).then(function (_a) {
                            var remoteMiddlewares = _a.remoteMiddlewares;
                            return tslib_1.__awaiter(_this, void 0, void 0, function () {
                                var middleware, promises;
                                return tslib_1.__generator(this, function (_b) {
                                    switch (_b.label) {
                                        case 0: return [4 /*yield*/, remoteMiddlewares(ctx, legacySettings, options.obfuscate)];
                                        case 1:
                                            middleware = _b.sent();
                                            promises = middleware.map(function (mdw) {
                                                return analytics.addSourceMiddleware(mdw);
                                            });
                                            return [2 /*return*/, Promise.all(promises)];
                                    }
                                });
                            });
                        })];
                case 14:
                    _g.sent();
                    _g.label = 15;
                case 15: return [2 /*return*/, ctx];
            }
        });
    });
}
function loadAnalytics(settings, options, preInitBuffer) {
    var _a, _b, _c, _d, _e;
    if (options === void 0) { options = {}; }
    return tslib_1.__awaiter(this, void 0, void 0, function () {
        var legacySettings, _f, retryQueue, opts, analytics, plugins, classicIntegrations, ctx, search, hash, term;
        return tslib_1.__generator(this, function (_g) {
            switch (_g.label) {
                case 0:
                    // this is an ugly side-effect, but it's for the benefits of the plugins that get their cdn via getCDN()
                    if (settings.cdnURL)
                        (0, parse_cdn_1.setGlobalCDNUrl)(settings.cdnURL);
                    if (!((_a = settings.cdnSettings) !== null && _a !== void 0)) return [3 /*break*/, 1];
                    _f = _a;
                    return [3 /*break*/, 3];
                case 1: return [4 /*yield*/, loadLegacySettings(settings.writeKey)];
                case 2:
                    _f = (_g.sent());
                    _g.label = 3;
                case 3:
                    legacySettings = _f;
                    retryQueue = true;
                    opts = tslib_1.__assign({ retryQueue: retryQueue }, options);
                    analytics = new analytics_1.Analytics(settings, opts);
                    (0, inspector_1.attachInspector)(analytics);
                    plugins = (_b = settings.plugins) !== null && _b !== void 0 ? _b : [];
                    classicIntegrations = (_c = settings.classicIntegrations) !== null && _c !== void 0 ? _c : [];
                    stats_1.Stats.initRemoteMetrics(legacySettings.metrics);
                    // needs to be flushed before plugins are registered
                    flushPreBuffer(analytics, preInitBuffer);
                    return [4 /*yield*/, registerPlugins(legacySettings, analytics, opts, options, plugins, classicIntegrations)];
                case 4:
                    ctx = _g.sent();
                    search = (_d = window.location.search) !== null && _d !== void 0 ? _d : '';
                    hash = (_e = window.location.hash) !== null && _e !== void 0 ? _e : '';
                    term = search.length ? search : hash.replace(/(?=#).*(?=\?)/, '');
                    if (!term.includes('ajs_')) return [3 /*break*/, 6];
                    return [4 /*yield*/, analytics.queryString(term).catch(console.error)];
                case 5:
                    _g.sent();
                    _g.label = 6;
                case 6:
                    analytics.initialized = true;
                    analytics.emit('initialize', settings, options);
                    if (options.initialPageview) {
                        analytics.page().catch(console.error);
                    }
                    return [4 /*yield*/, flushFinalBuffer(analytics, preInitBuffer)];
                case 7:
                    _g.sent();
                    return [2 /*return*/, [analytics, ctx]];
            }
        });
    });
}
/**
 * The public browser interface for Segment Analytics
 *
 * @example
 * ```ts
 *  export const analytics = new AnalyticsBrowser()
 *  analytics.load({ writeKey: 'foo' })
 * ```
 * @link https://github.com/segmentio/analytics-next/#readme
 */
var AnalyticsBrowser = /** @class */ (function (_super) {
    tslib_1.__extends(AnalyticsBrowser, _super);
    function AnalyticsBrowser() {
        var _this = this;
        var _a = (0, create_deferred_1.createDeferred)(), loadStart = _a.promise, resolveLoadStart = _a.resolve;
        _this = _super.call(this, function (buffer) {
            return loadStart.then(function (_a) {
                var settings = _a[0], options = _a[1];
                return loadAnalytics(settings, options, buffer);
            });
        }) || this;
        _this._resolveLoadStart = function (settings, options) {
            return resolveLoadStart([settings, options]);
        };
        return _this;
    }
    /**
     * Fully initialize an analytics instance, including:
     *
     * * Fetching settings from the segment CDN (by default).
     * * Fetching all remote destinations configured by the user (if applicable).
     * * Flushing buffered analytics events.
     * * Loading all middleware.
     *
     * Note:️  This method should only be called *once* in your application.
     *
     * @example
     * ```ts
     * export const analytics = new AnalyticsBrowser()
     * analytics.load({ writeKey: 'foo' })
     * ```
     */
    AnalyticsBrowser.prototype.load = function (settings, options) {
        if (options === void 0) { options = {}; }
        this._resolveLoadStart(settings, options);
        return this;
    };
    /**
     * Instantiates an object exposing Analytics methods.
     *
     * @example
     * ```ts
     * const ajs = AnalyticsBrowser.load({ writeKey: '<YOUR_WRITE_KEY>' })
     *
     * ajs.track("foo")
     * ...
     * ```
     */
    AnalyticsBrowser.load = function (settings, options) {
        if (options === void 0) { options = {}; }
        return new AnalyticsBrowser().load(settings, options);
    };
    AnalyticsBrowser.standalone = function (writeKey, options) {
        return AnalyticsBrowser.load({ writeKey: writeKey }, options).then(function (res) { return res[0]; });
    };
    return AnalyticsBrowser;
}(buffer_1.AnalyticsBuffered));
exports.AnalyticsBrowser = AnalyticsBrowser;
//# sourceMappingURL=index.js.map