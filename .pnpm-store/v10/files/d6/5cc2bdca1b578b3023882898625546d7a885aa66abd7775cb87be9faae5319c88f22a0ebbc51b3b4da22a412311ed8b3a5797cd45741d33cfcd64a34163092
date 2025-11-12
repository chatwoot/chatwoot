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
var __rest = (this && this.__rest) || function (s, e) {
    var t = {};
    for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p) && e.indexOf(p) < 0)
        t[p] = s[p];
    if (s != null && typeof Object.getOwnPropertySymbols === "function")
        for (var i = 0, p = Object.getOwnPropertySymbols(s); i < p.length; i++) {
            if (e.indexOf(p[i]) < 0 && Object.prototype.propertyIsEnumerable.call(s, p[i]))
                t[p[i]] = s[p[i]];
        }
    return t;
};
var __values = (this && this.__values) || function(o) {
    var s = typeof Symbol === "function" && Symbol.iterator, m = s && o[s], i = 0;
    if (m) return m.call(o);
    if (o && typeof o.length === "number") return {
        next: function () {
            if (o && i >= o.length) o = void 0;
            return { value: o && o[i++], done: !o };
        }
    };
    throw new TypeError(s ? "Object is not iterable." : "Symbol.iterator is not defined.");
};
var __read = (this && this.__read) || function (o, n) {
    var m = typeof Symbol === "function" && o[Symbol.iterator];
    if (!m) return o;
    var i = m.call(o), r, ar = [], e;
    try {
        while ((n === void 0 || n-- > 0) && !(r = i.next()).done) ar.push(r.value);
    }
    catch (error) { e = { error: error }; }
    finally {
        try {
            if (r && !r.done && (m = i["return"])) m.call(i);
        }
        finally { if (e) throw e.error; }
    }
    return ar;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SiteApps = void 0;
var globals_1 = require("./utils/globals");
var logger_1 = require("./utils/logger");
var logger = (0, logger_1.createLogger)('[SiteApps]');
var SiteApps = /** @class */ (function () {
    function SiteApps(_instance) {
        this._instance = _instance;
        // events captured between loading posthog-js and the site app; up to 1000 events
        this._bufferedInvocations = [];
        this.apps = {};
    }
    Object.defineProperty(SiteApps.prototype, "isEnabled", {
        get: function () {
            return !!this._instance.config.opt_in_site_apps;
        },
        enumerable: false,
        configurable: true
    });
    SiteApps.prototype._eventCollector = function (_eventName, eventPayload) {
        if (!eventPayload) {
            return;
        }
        var globals = this.globalsForEvent(eventPayload);
        this._bufferedInvocations.push(globals);
        if (this._bufferedInvocations.length > 1000) {
            this._bufferedInvocations = this._bufferedInvocations.slice(10);
        }
    };
    Object.defineProperty(SiteApps.prototype, "siteAppLoaders", {
        get: function () {
            var _a, _b;
            return (_b = (_a = globals_1.assignableWindow._POSTHOG_REMOTE_CONFIG) === null || _a === void 0 ? void 0 : _a[this._instance.config.token]) === null || _b === void 0 ? void 0 : _b.siteApps;
        },
        enumerable: false,
        configurable: true
    });
    SiteApps.prototype.init = function () {
        var _this = this;
        if (this.isEnabled) {
            var stop_1 = this._instance._addCaptureHook(this._eventCollector.bind(this));
            this._stopBuffering = function () {
                stop_1();
                _this._bufferedInvocations = [];
                _this._stopBuffering = undefined;
            };
        }
    };
    SiteApps.prototype.globalsForEvent = function (event) {
        var e_1, _a;
        var _b, _c, _d, _e, _f, _g, _h;
        if (!event) {
            throw new Error('Event payload is required');
        }
        var groups = {};
        var groupIds = this._instance.get_property('$groups') || [];
        var groupProperties = this._instance.get_property('$stored_group_properties') || {};
        try {
            for (var _j = __values(Object.entries(groupProperties)), _k = _j.next(); !_k.done; _k = _j.next()) {
                var _l = __read(_k.value, 2), type = _l[0], properties = _l[1];
                groups[type] = { id: groupIds[type], type: type, properties: properties };
            }
        }
        catch (e_1_1) { e_1 = { error: e_1_1 }; }
        finally {
            try {
                if (_k && !_k.done && (_a = _j.return)) _a.call(_j);
            }
            finally { if (e_1) throw e_1.error; }
        }
        var $set_once = event.$set_once, $set = event.$set, _event = __rest(event, ["$set_once", "$set"]);
        var globals = {
            event: __assign(__assign({}, _event), { properties: __assign(__assign(__assign({}, event.properties), ($set ? { $set: __assign(__assign({}, ((_c = (_b = event.properties) === null || _b === void 0 ? void 0 : _b.$set) !== null && _c !== void 0 ? _c : {})), $set) } : {})), ($set_once ? { $set_once: __assign(__assign({}, ((_e = (_d = event.properties) === null || _d === void 0 ? void 0 : _d.$set_once) !== null && _e !== void 0 ? _e : {})), $set_once) } : {})), elements_chain: (_g = (_f = event.properties) === null || _f === void 0 ? void 0 : _f['$elements_chain']) !== null && _g !== void 0 ? _g : '', 
                // TODO:
                // - elements_chain_href: '',
                // - elements_chain_texts: [] as string[],
                // - elements_chain_ids: [] as string[],
                // - elements_chain_elements: [] as string[],
                distinct_id: (_h = event.properties) === null || _h === void 0 ? void 0 : _h['distinct_id'] }),
            person: {
                properties: this._instance.get_property('$stored_person_properties'),
            },
            groups: groups,
        };
        return globals;
    };
    SiteApps.prototype.setupSiteApp = function (loader) {
        var _this = this;
        var app = this.apps[loader.id];
        var processBufferedEvents = function () {
            var _a;
            if (!app.errored && _this._bufferedInvocations.length) {
                logger.info("Processing ".concat(_this._bufferedInvocations.length, " events for site app with id ").concat(loader.id));
                _this._bufferedInvocations.forEach(function (globals) { var _a; return (_a = app.processEvent) === null || _a === void 0 ? void 0 : _a.call(app, globals); });
                app.processedBuffer = true;
            }
            if (Object.values(_this.apps).every(function (app) { return app.processedBuffer || app.errored; })) {
                (_a = _this._stopBuffering) === null || _a === void 0 ? void 0 : _a.call(_this);
            }
        };
        var hasInitReturned = false;
        var onLoaded = function (success) {
            app.errored = !success;
            app.loaded = true;
            logger.info("Site app with id ".concat(loader.id, " ").concat(success ? 'loaded' : 'errored'));
            // ensure that we don't call processBufferedEvents until after init() returns and we've set up processEvent
            if (hasInitReturned) {
                processBufferedEvents();
            }
        };
        try {
            var processEvent = loader.init({
                posthog: this._instance,
                callback: function (success) {
                    onLoaded(success);
                },
            }).processEvent;
            if (processEvent) {
                app.processEvent = processEvent;
            }
            hasInitReturned = true;
        }
        catch (e) {
            logger.error("Error while initializing PostHog app with config id ".concat(loader.id), e);
            onLoaded(false);
        }
        // if the app loaded synchronously, process the events now
        if (hasInitReturned && app.loaded) {
            try {
                processBufferedEvents();
            }
            catch (e) {
                logger.error("Error while processing buffered events PostHog app with config id ".concat(loader.id), e);
                app.errored = true;
            }
        }
    };
    SiteApps.prototype._setupSiteApps = function () {
        var e_2, _a, e_3, _b;
        var siteAppLoaders = this.siteAppLoaders || [];
        try {
            // do this in 2 passes, so that this.apps is populated before we call init
            for (var siteAppLoaders_1 = __values(siteAppLoaders), siteAppLoaders_1_1 = siteAppLoaders_1.next(); !siteAppLoaders_1_1.done; siteAppLoaders_1_1 = siteAppLoaders_1.next()) {
                var loader = siteAppLoaders_1_1.value;
                this.apps[loader.id] = {
                    id: loader.id,
                    loaded: false,
                    errored: false,
                    processedBuffer: false,
                };
            }
        }
        catch (e_2_1) { e_2 = { error: e_2_1 }; }
        finally {
            try {
                if (siteAppLoaders_1_1 && !siteAppLoaders_1_1.done && (_a = siteAppLoaders_1.return)) _a.call(siteAppLoaders_1);
            }
            finally { if (e_2) throw e_2.error; }
        }
        try {
            for (var siteAppLoaders_2 = __values(siteAppLoaders), siteAppLoaders_2_1 = siteAppLoaders_2.next(); !siteAppLoaders_2_1.done; siteAppLoaders_2_1 = siteAppLoaders_2.next()) {
                var loader = siteAppLoaders_2_1.value;
                this.setupSiteApp(loader);
            }
        }
        catch (e_3_1) { e_3 = { error: e_3_1 }; }
        finally {
            try {
                if (siteAppLoaders_2_1 && !siteAppLoaders_2_1.done && (_b = siteAppLoaders_2.return)) _b.call(siteAppLoaders_2);
            }
            finally { if (e_3) throw e_3.error; }
        }
    };
    SiteApps.prototype._onCapturedEvent = function (event) {
        var e_4, _a;
        var _b;
        if (Object.keys(this.apps).length === 0) {
            return;
        }
        var globals = this.globalsForEvent(event);
        try {
            for (var _c = __values(Object.values(this.apps)), _d = _c.next(); !_d.done; _d = _c.next()) {
                var app = _d.value;
                try {
                    (_b = app.processEvent) === null || _b === void 0 ? void 0 : _b.call(app, globals);
                }
                catch (e) {
                    logger.error("Error while processing event ".concat(event.event, " for site app ").concat(app.id), e);
                }
            }
        }
        catch (e_4_1) { e_4 = { error: e_4_1 }; }
        finally {
            try {
                if (_d && !_d.done && (_a = _c.return)) _a.call(_c);
            }
            finally { if (e_4) throw e_4.error; }
        }
    };
    SiteApps.prototype.onRemoteConfig = function (response) {
        var e_5, _a;
        var _this = this;
        var _b, _c, _d, _e, _f;
        if ((_b = this.siteAppLoaders) === null || _b === void 0 ? void 0 : _b.length) {
            if (!this.isEnabled) {
                logger.error("PostHog site apps are disabled. Enable the \"opt_in_site_apps\" config to proceed.");
                return;
            }
            this._setupSiteApps();
            // NOTE: We could improve this to only fire if we actually have listeners for the event
            this._instance.on('eventCaptured', function (event) { return _this._onCapturedEvent(event); });
            return;
        }
        // NOTE: Below this is now only the fallback for legacy site app support. Once we have fully removed to the remote config loader we can get rid of this
        (_c = this._stopBuffering) === null || _c === void 0 ? void 0 : _c.call(this);
        if (!((_d = response['siteApps']) === null || _d === void 0 ? void 0 : _d.length)) {
            return;
        }
        if (!this.isEnabled) {
            logger.error("PostHog site apps are disabled. Enable the \"opt_in_site_apps\" config to proceed.");
            return;
        }
        var _loop_1 = function (id, url) {
            globals_1.assignableWindow["__$$ph_site_app_".concat(id)] = this_1._instance;
            (_f = (_e = globals_1.assignableWindow.__PosthogExtensions__) === null || _e === void 0 ? void 0 : _e.loadSiteApp) === null || _f === void 0 ? void 0 : _f.call(_e, this_1._instance, url, function (err) {
                if (err) {
                    return logger.error("Error while initializing PostHog app with config id ".concat(id), err);
                }
            });
        };
        var this_1 = this;
        try {
            for (var _g = __values(response['siteApps']), _h = _g.next(); !_h.done; _h = _g.next()) {
                var _j = _h.value, id = _j.id, url = _j.url;
                _loop_1(id, url);
            }
        }
        catch (e_5_1) { e_5 = { error: e_5_1 }; }
        finally {
            try {
                if (_h && !_h.done && (_a = _g.return)) _a.call(_g);
            }
            finally { if (e_5) throw e_5.error; }
        }
    };
    return SiteApps;
}());
exports.SiteApps = SiteApps;
//# sourceMappingURL=site-apps.js.map