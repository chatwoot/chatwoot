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
var __spreadArray = (this && this.__spreadArray) || function (to, from, pack) {
    if (pack || arguments.length === 2) for (var i = 0, l = from.length, ar; i < l; i++) {
        if (ar || !(i in from)) {
            if (!ar) ar = Array.prototype.slice.call(from, 0, i);
            ar[i] = from[i];
        }
    }
    return to.concat(ar || Array.prototype.slice.call(from));
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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PostHog = exports.configRenames = exports.defaultConfig = void 0;
exports.init_from_snippet = init_from_snippet;
exports.init_as_module = init_as_module;
var autocapture_1 = require("./autocapture");
var config_1 = __importDefault(require("./config"));
var consent_1 = require("./consent");
var constants_1 = require("./constants");
var dead_clicks_autocapture_1 = require("./extensions/dead-clicks-autocapture");
var exception_autocapture_1 = require("./extensions/exception-autocapture");
var error_conversion_1 = require("./extensions/exception-autocapture/error-conversion");
var history_autocapture_1 = require("./extensions/history-autocapture");
var sessionrecording_1 = require("./extensions/replay/sessionrecording");
var segment_integration_1 = require("./extensions/segment-integration");
var sentry_integration_1 = require("./extensions/sentry-integration");
var toolbar_1 = require("./extensions/toolbar");
var tracing_headers_1 = require("./extensions/tracing-headers");
var web_vitals_1 = require("./extensions/web-vitals");
var heatmaps_1 = require("./heatmaps");
var page_view_1 = require("./page-view");
var posthog_exceptions_1 = require("./posthog-exceptions");
var posthog_featureflags_1 = require("./posthog-featureflags");
var posthog_persistence_1 = require("./posthog-persistence");
var posthog_surveys_1 = require("./posthog-surveys");
var posthog_surveys_types_1 = require("./posthog-surveys-types");
var rate_limiter_1 = require("./rate-limiter");
var remote_config_1 = require("./remote-config");
var request_1 = require("./request");
var request_queue_1 = require("./request-queue");
var retry_queue_1 = require("./retry-queue");
var scroll_manager_1 = require("./scroll-manager");
var session_props_1 = require("./session-props");
var sessionid_1 = require("./sessionid");
var site_apps_1 = require("./site-apps");
var storage_1 = require("./storage");
var types_1 = require("./types");
var utils_1 = require("./utils");
var blocked_uas_1 = require("./utils/blocked-uas");
var event_utils_1 = require("./utils/event-utils");
var globals_1 = require("./utils/globals");
var logger_1 = require("./utils/logger");
var property_utils_1 = require("./utils/property-utils");
var request_router_1 = require("./utils/request-router");
var simple_event_emitter_1 = require("./utils/simple-event-emitter");
var survey_utils_1 = require("./utils/survey-utils");
var core_1 = require("@posthog/core");
var uuidv7_1 = require("./uuidv7");
var web_experiments_1 = require("./web-experiments");
var external_integration_1 = require("./extensions/external-integration");
var instances = {};
// some globals for comparisons
var __NOOP = function () { };
var PRIMARY_INSTANCE_NAME = 'posthog';
/*
 * Dynamic... constants? Is that an oxymoron?
 */
// http://hacks.mozilla.org/2009/07/cross-site-xmlhttprequest-with-cors/
// https://developer.mozilla.org/en-US/docs/DOM/XMLHttpRequest#withCredentials
// IE<10 does not support cross-origin XHR's but script tags
// with defer won't block window.onload; ENQUEUE_REQUESTS
// should only be true for Opera<12
var ENQUEUE_REQUESTS = !request_1.SUPPORTS_REQUEST && (globals_1.userAgent === null || globals_1.userAgent === void 0 ? void 0 : globals_1.userAgent.indexOf('MSIE')) === -1 && (globals_1.userAgent === null || globals_1.userAgent === void 0 ? void 0 : globals_1.userAgent.indexOf('Mozilla')) === -1;
// NOTE: Remember to update `types.ts` when changing a default value
// to guarantee documentation is up to date, make sure to also update our website docs
// NOTE²: This shouldn't ever change because we try very hard to be backwards-compatible
var defaultConfig = function (defaults) {
    var _a;
    return ({
        api_host: 'https://us.i.posthog.com',
        ui_host: null,
        token: '',
        autocapture: true,
        rageclick: true,
        cross_subdomain_cookie: (0, utils_1.isCrossDomainCookie)(globals_1.document === null || globals_1.document === void 0 ? void 0 : globals_1.document.location),
        persistence: 'localStorage+cookie', // up to 1.92.0 this was 'cookie'. It's easy to migrate as 'localStorage+cookie' will migrate data from cookie storage
        persistence_name: '',
        loaded: __NOOP,
        save_campaign_params: true,
        custom_campaign_params: [],
        custom_blocked_useragents: [],
        save_referrer: true,
        capture_pageview: defaults === '2025-05-24' ? 'history_change' : true,
        capture_pageleave: 'if_capture_pageview', // We'll only capture pageleave events if capture_pageview is also true
        defaults: defaults !== null && defaults !== void 0 ? defaults : 'unset',
        debug: (globals_1.location && (0, core_1.isString)(globals_1.location === null || globals_1.location === void 0 ? void 0 : globals_1.location.search) && globals_1.location.search.indexOf('__posthog_debug=true') !== -1) || false,
        cookie_expiration: 365,
        upgrade: false,
        disable_session_recording: false,
        disable_persistence: false,
        disable_web_experiments: true, // disabled in beta.
        disable_surveys: false,
        disable_surveys_automatic_display: false,
        disable_external_dependency_loading: false,
        enable_recording_console_log: undefined, // When undefined, it falls back to the server-side setting
        secure_cookie: ((_a = globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.location) === null || _a === void 0 ? void 0 : _a.protocol) === 'https:',
        ip: false,
        opt_out_capturing_by_default: false,
        opt_out_persistence_by_default: false,
        opt_out_useragent_filter: false,
        opt_out_capturing_persistence_type: 'localStorage',
        consent_persistence_name: null,
        opt_out_capturing_cookie_prefix: null,
        opt_in_site_apps: false,
        property_denylist: [],
        respect_dnt: false,
        sanitize_properties: null,
        request_headers: {}, // { header: value, header2: value }
        request_batching: true,
        properties_string_max_length: 65535,
        session_recording: {},
        mask_all_element_attributes: false,
        mask_all_text: false,
        mask_personal_data_properties: false,
        custom_personal_data_properties: [],
        advanced_disable_flags: false,
        advanced_disable_decide: false,
        advanced_disable_feature_flags: false,
        advanced_disable_feature_flags_on_first_load: false,
        advanced_only_evaluate_survey_feature_flags: false,
        advanced_enable_surveys: false,
        advanced_disable_toolbar_metrics: false,
        feature_flag_request_timeout_ms: 3000,
        surveys_request_timeout_ms: constants_1.SURVEYS_REQUEST_TIMEOUT_MS,
        on_request_error: function (res) {
            var error = 'Bad HTTP status: ' + res.statusCode + ' ' + res.text;
            logger_1.logger.error(error);
        },
        get_device_id: function (uuid) { return uuid; },
        capture_performance: undefined,
        name: 'posthog',
        bootstrap: {},
        disable_compression: false,
        session_idle_timeout_seconds: 30 * 60, // 30 minutes
        person_profiles: 'identified_only',
        before_send: undefined,
        request_queue_config: { flush_interval_ms: request_queue_1.DEFAULT_FLUSH_INTERVAL_MS },
        error_tracking: {},
        // Used for internal testing
        _onCapture: __NOOP,
    });
};
exports.defaultConfig = defaultConfig;
var configRenames = function (origConfig) {
    var renames = {};
    if (!(0, core_1.isUndefined)(origConfig.process_person)) {
        renames.person_profiles = origConfig.process_person;
    }
    if (!(0, core_1.isUndefined)(origConfig.xhr_headers)) {
        renames.request_headers = origConfig.xhr_headers;
    }
    if (!(0, core_1.isUndefined)(origConfig.cookie_name)) {
        renames.persistence_name = origConfig.cookie_name;
    }
    if (!(0, core_1.isUndefined)(origConfig.disable_cookie)) {
        renames.disable_persistence = origConfig.disable_cookie;
    }
    if (!(0, core_1.isUndefined)(origConfig.store_google)) {
        renames.save_campaign_params = origConfig.store_google;
    }
    if (!(0, core_1.isUndefined)(origConfig.verbose)) {
        renames.debug = origConfig.verbose;
    }
    // on_xhr_error is not present, as the type is different to on_request_error
    // the original config takes priority over the renames
    var newConfig = (0, utils_1.extend)({}, renames, origConfig);
    // merge property_blacklist into property_denylist
    if ((0, core_1.isArray)(origConfig.property_blacklist)) {
        if ((0, core_1.isUndefined)(origConfig.property_denylist)) {
            newConfig.property_denylist = origConfig.property_blacklist;
        }
        else if ((0, core_1.isArray)(origConfig.property_denylist)) {
            newConfig.property_denylist = __spreadArray(__spreadArray([], __read(origConfig.property_blacklist), false), __read(origConfig.property_denylist), false);
        }
        else {
            logger_1.logger.error('Invalid value for property_denylist config: ' + origConfig.property_denylist);
        }
    }
    return newConfig;
};
exports.configRenames = configRenames;
var DeprecatedWebPerformanceObserver = /** @class */ (function () {
    function DeprecatedWebPerformanceObserver() {
        this.__forceAllowLocalhost = false;
    }
    Object.defineProperty(DeprecatedWebPerformanceObserver.prototype, "_forceAllowLocalhost", {
        get: function () {
            return this.__forceAllowLocalhost;
        },
        set: function (value) {
            logger_1.logger.error('WebPerformanceObserver is deprecated and has no impact on network capture. Use `_forceAllowLocalhostNetworkCapture` on `posthog.sessionRecording`');
            this.__forceAllowLocalhost = value;
        },
        enumerable: false,
        configurable: true
    });
    return DeprecatedWebPerformanceObserver;
}());
/**
 *
 * This is the SDK reference for the PostHog JavaScript Web SDK.
 * You can learn more about example usage in the
 * [JavaScript Web SDK documentation](/docs/libraries/js).
 * You can also follow [framework specific guides](/docs/frameworks)
 * to integrate PostHog into your project.
 *
 * This SDK is designed for browser environments.
 * Use the PostHog [Node.js SDK](/docs/libraries/node) for server-side usage.
 *
 * @constructor
 */
var PostHog = /** @class */ (function () {
    function PostHog() {
        var _this = this;
        this.webPerformance = new DeprecatedWebPerformanceObserver();
        this._personProcessingSetOncePropertiesSent = false;
        this.version = config_1.default.LIB_VERSION;
        this._internalEventEmitter = new simple_event_emitter_1.SimpleEventEmitter();
        /** @deprecated - deprecated in 1.241.0, use `calculateEventProperties` instead  */
        this._calculate_event_properties = this.calculateEventProperties.bind(this);
        this.config = (0, exports.defaultConfig)();
        this.SentryIntegration = sentry_integration_1.SentryIntegration;
        this.sentryIntegration = function (options) { return (0, sentry_integration_1.sentryIntegration)(_this, options); };
        this.__request_queue = [];
        this.__loaded = false;
        this.analyticsDefaultEndpoint = '/e/';
        this._initialPageviewCaptured = false;
        this._visibilityStateListener = null;
        this._initialPersonProfilesConfig = null;
        this._cachedPersonProperties = null;
        this.featureFlags = new posthog_featureflags_1.PostHogFeatureFlags(this);
        this.toolbar = new toolbar_1.Toolbar(this);
        this.scrollManager = new scroll_manager_1.ScrollManager(this);
        this.pageViewManager = new page_view_1.PageViewManager(this);
        this.surveys = new posthog_surveys_1.PostHogSurveys(this);
        this.experiments = new web_experiments_1.WebExperiments(this);
        this.exceptions = new posthog_exceptions_1.PostHogExceptions(this);
        this.rateLimiter = new rate_limiter_1.RateLimiter(this);
        this.requestRouter = new request_router_1.RequestRouter(this);
        this.consent = new consent_1.ConsentManager(this);
        this.externalIntegrations = new external_integration_1.ExternalIntegrations(this);
        // NOTE: See the property definition for deprecation notice
        this.people = {
            set: function (prop, to, callback) {
                var _a;
                var setProps = (0, core_1.isString)(prop) ? (_a = {}, _a[prop] = to, _a) : prop;
                _this.setPersonProperties(setProps);
                callback === null || callback === void 0 ? void 0 : callback({});
            },
            set_once: function (prop, to, callback) {
                var _a;
                var setProps = (0, core_1.isString)(prop) ? (_a = {}, _a[prop] = to, _a) : prop;
                _this.setPersonProperties(undefined, setProps);
                callback === null || callback === void 0 ? void 0 : callback({});
            },
        };
        this.on('eventCaptured', function (data) { return logger_1.logger.info("send \"".concat(data === null || data === void 0 ? void 0 : data.event, "\""), data); });
    }
    Object.defineProperty(PostHog.prototype, "decideEndpointWasHit", {
        // Legacy property to support existing usage - this isn't technically correct but it's what it has always been - a proxy for flags being loaded
        /** @deprecated Use `flagsEndpointWasHit` instead.  We migrated to using a new feature flag endpoint and the new method is more semantically accurate */
        get: function () {
            var _a, _b;
            return (_b = (_a = this.featureFlags) === null || _a === void 0 ? void 0 : _a.hasLoadedFlags) !== null && _b !== void 0 ? _b : false;
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(PostHog.prototype, "flagsEndpointWasHit", {
        get: function () {
            var _a, _b;
            return (_b = (_a = this.featureFlags) === null || _a === void 0 ? void 0 : _a.hasLoadedFlags) !== null && _b !== void 0 ? _b : false;
        },
        enumerable: false,
        configurable: true
    });
    // Initialization methods
    /**
     * Initializes a new instance of the PostHog capturing object.
     *
     * @remarks
     * All new instances are added to the main posthog object as sub properties (such as
     * `posthog.library_name`) and also returned by this function. [Learn more about configuration options](https://github.com/posthog/posthog-js/blob/6e0e873/src/posthog-core.js#L57-L91)
     *
     * @example
     * ```js
     * // basic initialization
     * posthog.init('<ph_project_api_key>', {
     *     api_host: '<ph_client_api_host>'
     * })
     * ```
     *
     * @example
     * ```js
     * // multiple instances
     * posthog.init('<ph_project_api_key>', {}, 'project1')
     * posthog.init('<ph_project_api_key>', {}, 'project2')
     * ```
     *
     * @public
     *
     * @param token - Your PostHog API token
     * @param config - A dictionary of config options to override
     * @param name - The name for the new posthog instance that you want created
     *
     * {@label Initialization}
     *
     * @returns The newly initialized PostHog instance
     */
    PostHog.prototype.init = function (token, config, name) {
        var _a;
        if (!name || name === PRIMARY_INSTANCE_NAME) {
            // This means we are initializing the primary instance (i.e. this)
            return this._init(token, config, name);
        }
        else {
            var namedPosthog = (_a = instances[name]) !== null && _a !== void 0 ? _a : new PostHog();
            namedPosthog._init(token, config, name);
            instances[name] = namedPosthog;
            instances[PRIMARY_INSTANCE_NAME][name] = namedPosthog;
            return namedPosthog;
        }
    };
    // posthog._init(token:string, config:object, name:string)
    //
    // This function sets up the current instance of the posthog
    // library.  The difference between this method and the init(...)
    // method is this one initializes the actual instance, whereas the
    // init(...) method sets up a new library and calls _init on it.
    //
    // Note that there are operations that can be asynchronous, so we
    // accept a callback that is called when all the asynchronous work
    // is done. Note that we do not use promises because we want to be
    // IE11 compatible. We could use polyfills, which would make the
    // code a bit cleaner, but will add some overhead.
    //
    PostHog.prototype._init = function (token, config, name) {
        var _this = this;
        var _a, _b, _c, _d, _e, _f;
        if (config === void 0) { config = {}; }
        if ((0, core_1.isUndefined)(token) || (0, core_1.isEmptyString)(token)) {
            logger_1.logger.critical('PostHog was initialized without a token. This likely indicates a misconfiguration. Please check the first argument passed to posthog.init()');
            return this;
        }
        if (this.__loaded) {
            logger_1.logger.warn('You have already initialized PostHog! Re-initializing is a no-op');
            return this;
        }
        this.__loaded = true;
        this.config = {}; // will be set right below
        this._originalUserConfig = config; // Store original user config for migration
        this._triggered_notifs = [];
        if (config.person_profiles) {
            this._initialPersonProfilesConfig = config.person_profiles;
        }
        this.set_config((0, utils_1.extend)({}, (0, exports.defaultConfig)(config.defaults), (0, exports.configRenames)(config), {
            name: name,
            token: token,
        }));
        if (this.config.on_xhr_error) {
            logger_1.logger.error('on_xhr_error is deprecated. Use on_request_error instead');
        }
        this.compression = config.disable_compression ? undefined : types_1.Compression.GZipJS;
        var persistenceDisabled = this._is_persistence_disabled();
        this.persistence = new posthog_persistence_1.PostHogPersistence(this.config, persistenceDisabled);
        this.sessionPersistence =
            this.config.persistence === 'sessionStorage' || this.config.persistence === 'memory'
                ? this.persistence
                : new posthog_persistence_1.PostHogPersistence(__assign(__assign({}, this.config), { persistence: 'sessionStorage' }), persistenceDisabled);
        // should I store the initial person profiles config in persistence?
        var initialPersistenceProps = __assign({}, this.persistence.props);
        var initialSessionProps = __assign({}, this.sessionPersistence.props);
        this.register({ $initialization_time: new Date().toISOString() });
        this._requestQueue = new request_queue_1.RequestQueue(function (req) { return _this._send_retriable_request(req); }, this.config.request_queue_config);
        this._retryQueue = new retry_queue_1.RetryQueue(this);
        this.__request_queue = [];
        var startInCookielessMode = this.config.cookieless_mode === 'always' ||
            (this.config.cookieless_mode === 'on_reject' && this.consent.isExplicitlyOptedOut());
        if (!startInCookielessMode) {
            this.sessionManager = new sessionid_1.SessionIdManager(this);
            this.sessionPropsManager = new session_props_1.SessionPropsManager(this, this.sessionManager, this.persistence);
        }
        new tracing_headers_1.TracingHeaders(this).startIfEnabledOrStop();
        this.siteApps = new site_apps_1.SiteApps(this);
        (_a = this.siteApps) === null || _a === void 0 ? void 0 : _a.init();
        if (!startInCookielessMode) {
            this.sessionRecording = new sessionrecording_1.SessionRecording(this);
            this.sessionRecording.startIfEnabledOrStop();
        }
        if (!this.config.disable_scroll_properties) {
            this.scrollManager.startMeasuringScrollPosition();
        }
        this.autocapture = new autocapture_1.Autocapture(this);
        this.autocapture.startIfEnabled();
        this.surveys.loadIfEnabled();
        this.heatmaps = new heatmaps_1.Heatmaps(this);
        this.heatmaps.startIfEnabled();
        this.webVitalsAutocapture = new web_vitals_1.WebVitalsAutocapture(this);
        this.exceptionObserver = new exception_autocapture_1.ExceptionObserver(this);
        this.exceptionObserver.startIfEnabled();
        this.deadClicksAutocapture = new dead_clicks_autocapture_1.DeadClicksAutocapture(this, dead_clicks_autocapture_1.isDeadClicksEnabledForAutocapture);
        this.deadClicksAutocapture.startIfEnabled();
        this.historyAutocapture = new history_autocapture_1.HistoryAutocapture(this);
        this.historyAutocapture.startIfEnabled();
        // if any instance on the page has debug = true, we set the
        // global debug to be true
        config_1.default.DEBUG = config_1.default.DEBUG || this.config.debug;
        if (config_1.default.DEBUG) {
            logger_1.logger.info('Starting in debug mode', {
                this: this,
                config: config,
                thisC: __assign({}, this.config),
                p: initialPersistenceProps,
                s: initialSessionProps,
            });
        }
        // isUndefined doesn't provide typehint here so wouldn't reduce bundle as we'd need to assign
        // eslint-disable-next-line posthog-js/no-direct-undefined-check
        if (((_b = config.bootstrap) === null || _b === void 0 ? void 0 : _b.distinctID) !== undefined) {
            var uuid = this.config.get_device_id((0, uuidv7_1.uuidv7)());
            var deviceID = ((_c = config.bootstrap) === null || _c === void 0 ? void 0 : _c.isIdentifiedID) ? uuid : config.bootstrap.distinctID;
            this.persistence.set_property(constants_1.USER_STATE, ((_d = config.bootstrap) === null || _d === void 0 ? void 0 : _d.isIdentifiedID) ? 'identified' : 'anonymous');
            this.register({
                distinct_id: config.bootstrap.distinctID,
                $device_id: deviceID,
            });
        }
        if (this._hasBootstrappedFeatureFlags()) {
            var activeFlags_1 = Object.keys(((_e = config.bootstrap) === null || _e === void 0 ? void 0 : _e.featureFlags) || {})
                .filter(function (flag) { var _a, _b; return !!((_b = (_a = config.bootstrap) === null || _a === void 0 ? void 0 : _a.featureFlags) === null || _b === void 0 ? void 0 : _b[flag]); })
                .reduce(function (res, key) {
                var _a, _b;
                return ((res[key] = ((_b = (_a = config.bootstrap) === null || _a === void 0 ? void 0 : _a.featureFlags) === null || _b === void 0 ? void 0 : _b[key]) || false), res);
            }, {});
            var featureFlagPayloads = Object.keys(((_f = config.bootstrap) === null || _f === void 0 ? void 0 : _f.featureFlagPayloads) || {})
                .filter(function (key) { return activeFlags_1[key]; })
                .reduce(function (res, key) {
                var _a, _b, _c, _d;
                if ((_b = (_a = config.bootstrap) === null || _a === void 0 ? void 0 : _a.featureFlagPayloads) === null || _b === void 0 ? void 0 : _b[key]) {
                    res[key] = (_d = (_c = config.bootstrap) === null || _c === void 0 ? void 0 : _c.featureFlagPayloads) === null || _d === void 0 ? void 0 : _d[key];
                }
                return res;
            }, {});
            this.featureFlags.receivedFeatureFlags({ featureFlags: activeFlags_1, featureFlagPayloads: featureFlagPayloads });
        }
        if (startInCookielessMode) {
            this.register_once({
                distinct_id: constants_1.COOKIELESS_SENTINEL_VALUE,
                $device_id: null,
            }, '');
        }
        else if (!this.get_distinct_id()) {
            // There is no need to set the distinct id
            // or the device id if something was already stored
            // in the persistence
            var uuid = this.config.get_device_id((0, uuidv7_1.uuidv7)());
            this.register_once({
                distinct_id: uuid,
                $device_id: uuid,
            }, '');
            // distinct id == $device_id is a proxy for anonymous user
            this.persistence.set_property(constants_1.USER_STATE, 'anonymous');
        }
        // Set up event handler for pageleave
        // Use `onpagehide` if available, see https://calendar.perfplanet.com/2020/beaconing-in-practice/#beaconing-reliability-avoiding-abandons
        //
        // Not making it passive to try and force the browser to handle this before the page is unloaded
        (0, utils_1.addEventListener)(globals_1.window, 'onpagehide' in self ? 'pagehide' : 'unload', this._handle_unload.bind(this), {
            passive: false,
        });
        this.toolbar.maybeLoadToolbar();
        // We want to avoid promises for IE11 compatibility, so we use callbacks here
        if (config.segment) {
            (0, segment_integration_1.setupSegmentIntegration)(this, function () { return _this._loaded(); });
        }
        else {
            this._loaded();
        }
        if ((0, core_1.isFunction)(this.config._onCapture) && this.config._onCapture !== __NOOP) {
            logger_1.logger.warn('onCapture is deprecated. Please use `before_send` instead');
            this.on('eventCaptured', function (data) { return _this.config._onCapture(data.event, data); });
        }
        if (this.config.ip) {
            logger_1.logger.warn('The `ip` config option has NO EFFECT AT ALL and has been deprecated. Use a custom transformation or "Discard IP data" project setting instead. See https://posthog.com/tutorials/web-redact-properties#hiding-customer-ip-address for more information.');
        }
        return this;
    };
    PostHog.prototype._onRemoteConfig = function (config) {
        var _this = this;
        var _a, _b, _c, _d, _e, _f, _g, _h;
        if (!(globals_1.document && globals_1.document.body)) {
            logger_1.logger.info('document not ready yet, trying again in 500 milliseconds...');
            setTimeout(function () {
                _this._onRemoteConfig(config);
            }, 500);
            return;
        }
        this.compression = undefined;
        if (config.supportedCompression && !this.config.disable_compression) {
            this.compression = (0, core_1.includes)(config['supportedCompression'], types_1.Compression.GZipJS)
                ? types_1.Compression.GZipJS
                : (0, core_1.includes)(config['supportedCompression'], types_1.Compression.Base64)
                    ? types_1.Compression.Base64
                    : undefined;
        }
        if ((_a = config.analytics) === null || _a === void 0 ? void 0 : _a.endpoint) {
            this.analyticsDefaultEndpoint = config.analytics.endpoint;
        }
        this.set_config({
            person_profiles: this._initialPersonProfilesConfig ? this._initialPersonProfilesConfig : 'identified_only',
        });
        (_b = this.siteApps) === null || _b === void 0 ? void 0 : _b.onRemoteConfig(config);
        (_c = this.sessionRecording) === null || _c === void 0 ? void 0 : _c.onRemoteConfig(config);
        (_d = this.autocapture) === null || _d === void 0 ? void 0 : _d.onRemoteConfig(config);
        (_e = this.heatmaps) === null || _e === void 0 ? void 0 : _e.onRemoteConfig(config);
        this.surveys.onRemoteConfig(config);
        (_f = this.webVitalsAutocapture) === null || _f === void 0 ? void 0 : _f.onRemoteConfig(config);
        (_g = this.exceptionObserver) === null || _g === void 0 ? void 0 : _g.onRemoteConfig(config);
        this.exceptions.onRemoteConfig(config);
        (_h = this.deadClicksAutocapture) === null || _h === void 0 ? void 0 : _h.onRemoteConfig(config);
    };
    PostHog.prototype._loaded = function () {
        var _this = this;
        try {
            this.config.loaded(this);
        }
        catch (err) {
            logger_1.logger.critical('`loaded` function failed', err);
        }
        this._start_queue_if_opted_in();
        // this happens after "loaded" so a user can call identify or any other things before the pageview fires
        if (this.config.capture_pageview) {
            // NOTE: We want to fire this on the next tick as the previous implementation had this side effect
            // and some clients may rely on it
            setTimeout(function () {
                if (_this.consent.isOptedIn()) {
                    _this._captureInitialPageview();
                }
            }, 1);
        }
        new remote_config_1.RemoteConfigLoader(this).load();
        this.featureFlags.flags();
    };
    PostHog.prototype._start_queue_if_opted_in = function () {
        var _a;
        if (this.is_capturing()) {
            if (this.config.request_batching) {
                (_a = this._requestQueue) === null || _a === void 0 ? void 0 : _a.enable();
            }
        }
    };
    PostHog.prototype._dom_loaded = function () {
        var _this = this;
        if (this.is_capturing()) {
            (0, utils_1.eachArray)(this.__request_queue, function (item) { return _this._send_retriable_request(item); });
        }
        this.__request_queue = [];
        this._start_queue_if_opted_in();
    };
    PostHog.prototype._handle_unload = function () {
        var _a, _b;
        if (!this.config.request_batching) {
            if (this._shouldCapturePageleave()) {
                this.capture('$pageleave', null, { transport: 'sendBeacon' });
            }
            return;
        }
        if (this._shouldCapturePageleave()) {
            this.capture('$pageleave');
        }
        (_a = this._requestQueue) === null || _a === void 0 ? void 0 : _a.unload();
        (_b = this._retryQueue) === null || _b === void 0 ? void 0 : _b.unload();
    };
    PostHog.prototype._send_request = function (options) {
        var _this = this;
        if (!this.__loaded) {
            return;
        }
        if (ENQUEUE_REQUESTS) {
            this.__request_queue.push(options);
            return;
        }
        if (this.rateLimiter.isServerRateLimited(options.batchKey)) {
            return;
        }
        options.transport = options.transport || this.config.api_transport;
        options.url = (0, request_1.extendURLParams)(options.url, {
            // Whether to detect ip info or not
            ip: this.config.ip ? 1 : 0,
        });
        options.headers = __assign({}, this.config.request_headers);
        options.compression = options.compression === 'best-available' ? this.compression : options.compression;
        // Specially useful if you're doing SSR with NextJS
        // Users must be careful when tweaking `cache` because they might get out-of-date feature flags
        options.fetchOptions = options.fetchOptions || this.config.fetch_options;
        (0, request_1.request)(__assign(__assign({}, options), { callback: function (response) {
                var _a, _b, _c;
                _this.rateLimiter.checkForLimiting(response);
                if (response.statusCode >= 400) {
                    (_b = (_a = _this.config).on_request_error) === null || _b === void 0 ? void 0 : _b.call(_a, response);
                }
                (_c = options.callback) === null || _c === void 0 ? void 0 : _c.call(options, response);
            } }));
    };
    PostHog.prototype._send_retriable_request = function (options) {
        if (this._retryQueue) {
            this._retryQueue.retriableRequest(options);
        }
        else {
            this._send_request(options);
        }
    };
    /**
     * _execute_array() deals with processing any posthog function
     * calls that were called before the PostHog library were loaded
     * (and are thus stored in an array so they can be called later)
     *
     * Note: we fire off all the posthog function calls && user defined
     * functions BEFORE we fire off posthog capturing calls. This is so
     * identify/register/set_config calls can properly modify early
     * capturing calls.
     *
     * @param {Array} array
     */
    PostHog.prototype._execute_array = function (array) {
        var _this = this;
        var fn_name;
        var alias_calls = [];
        var other_calls = [];
        var capturing_calls = [];
        (0, utils_1.eachArray)(array, function (item) {
            if (item) {
                fn_name = item[0];
                if ((0, core_1.isArray)(fn_name)) {
                    capturing_calls.push(item); // chained call e.g. posthog.get_group().set()
                }
                else if ((0, core_1.isFunction)(item)) {
                    ;
                    item.call(_this);
                }
                else if ((0, core_1.isArray)(item) && fn_name === 'alias') {
                    alias_calls.push(item);
                }
                else if ((0, core_1.isArray)(item) && fn_name.indexOf('capture') !== -1 && (0, core_1.isFunction)(_this[fn_name])) {
                    capturing_calls.push(item);
                }
                else {
                    other_calls.push(item);
                }
            }
        });
        var execute = function (calls, thisArg) {
            (0, utils_1.eachArray)(calls, function (item) {
                if ((0, core_1.isArray)(item[0])) {
                    // chained call
                    var caller_1 = thisArg;
                    (0, utils_1.each)(item, function (call) {
                        caller_1 = caller_1[call[0]].apply(caller_1, call.slice(1));
                    });
                }
                else {
                    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
                    // @ts-ignore
                    this[item[0]].apply(this, item.slice(1));
                }
            }, thisArg);
        };
        execute(alias_calls, this);
        execute(other_calls, this);
        execute(capturing_calls, this);
    };
    PostHog.prototype._hasBootstrappedFeatureFlags = function () {
        var _a, _b;
        return ((((_a = this.config.bootstrap) === null || _a === void 0 ? void 0 : _a.featureFlags) && Object.keys((_b = this.config.bootstrap) === null || _b === void 0 ? void 0 : _b.featureFlags).length > 0) ||
            false);
    };
    /**
     * push() keeps the standard async-array-push
     * behavior around after the lib is loaded.
     * This is only useful for external integrations that
     * do not wish to rely on our convenience methods
     * (created in the snippet).
     *
     * @example
     * ```js
     * posthog.push(['register', { a: 'b' }]);
     * ```
     *
     * @param {Array} item A [function_name, args...] array to be executed
     */
    PostHog.prototype.push = function (item) {
        this._execute_array([item]);
    };
    /**
     * Captures an event with optional properties and configuration.
     *
     * @remarks
     * You can capture arbitrary object-like values as events. [Learn about capture best practices](/docs/product-analytics/capture-events)
     *
     * @example
     * ```js
     * // basic event capture
     * posthog.capture('cta-button-clicked', {
     *     button_name: 'Get Started',
     *     page: 'homepage'
     * })
     * ```
     *
     * {@label Capture}
     *
     * @public
     *
     * @param event_name - The name of the event (e.g., 'Sign Up', 'Button Click', 'Purchase')
     * @param properties - Properties to include with the event describing the user or event details
     * @param options - Optional configuration for the capture request
     *
     * @returns The capture result containing event data, or undefined if capture failed
     */
    PostHog.prototype.capture = function (event_name, properties, options) {
        var _a;
        var _b;
        // While developing, a developer might purposefully _not_ call init(),
        // in this case, we would like capture to be a noop.
        if (!this.__loaded || !this.persistence || !this.sessionPersistence || !this._requestQueue) {
            logger_1.logger.uninitializedWarning('posthog.capture');
            return;
        }
        if (!this.is_capturing()) {
            return;
        }
        // typing doesn't prevent interesting data
        if ((0, core_1.isUndefined)(event_name) || !(0, core_1.isString)(event_name)) {
            logger_1.logger.error('No event name provided to posthog.capture');
            return;
        }
        if (!this.config.opt_out_useragent_filter && this._is_bot()) {
            return;
        }
        var clientRateLimitContext = !(options === null || options === void 0 ? void 0 : options.skip_client_rate_limiting)
            ? this.rateLimiter.clientRateLimitContext()
            : undefined;
        if (clientRateLimitContext === null || clientRateLimitContext === void 0 ? void 0 : clientRateLimitContext.isRateLimited) {
            logger_1.logger.critical('This capture call is ignored due to client rate limiting.');
            return;
        }
        if ((properties === null || properties === void 0 ? void 0 : properties.$current_url) && !(0, core_1.isString)(properties === null || properties === void 0 ? void 0 : properties.$current_url)) {
            logger_1.logger.error('Invalid `$current_url` property provided to `posthog.capture`. Input must be a string. Ignoring provided value.');
            properties === null || properties === void 0 ? true : delete properties.$current_url;
        }
        // update persistence
        this.sessionPersistence.update_search_keyword();
        // The initial campaign/referrer props need to be stored in the regular persistence, as they are there to mimic
        // the person-initial props. The non-initial versions are stored in the sessionPersistence, as they are sent
        // with every event and used by the session table to create session-initial props.
        if (this.config.save_campaign_params) {
            this.sessionPersistence.update_campaign_params();
        }
        if (this.config.save_referrer) {
            this.sessionPersistence.update_referrer_info();
        }
        if (this.config.save_campaign_params || this.config.save_referrer) {
            this.persistence.set_initial_person_info();
        }
        var systemTime = new Date();
        var timestamp = (options === null || options === void 0 ? void 0 : options.timestamp) || systemTime;
        var uuid = (0, uuidv7_1.uuidv7)();
        var data = {
            uuid: uuid,
            event: event_name,
            properties: this.calculateEventProperties(event_name, properties || {}, timestamp, uuid),
        };
        if (clientRateLimitContext) {
            data.properties['$lib_rate_limit_remaining_tokens'] = clientRateLimitContext.remainingTokens;
        }
        var setProperties = options === null || options === void 0 ? void 0 : options.$set;
        if (setProperties) {
            data.$set = options === null || options === void 0 ? void 0 : options.$set;
        }
        var setOnceProperties = this._calculate_set_once_properties(options === null || options === void 0 ? void 0 : options.$set_once);
        if (setOnceProperties) {
            data.$set_once = setOnceProperties;
        }
        data = (0, utils_1._copyAndTruncateStrings)(data, (options === null || options === void 0 ? void 0 : options._noTruncate) ? null : this.config.properties_string_max_length);
        data.timestamp = timestamp;
        if (!(0, core_1.isUndefined)(options === null || options === void 0 ? void 0 : options.timestamp)) {
            data.properties['$event_time_override_provided'] = true;
            data.properties['$event_time_override_system_time'] = systemTime;
        }
        if (event_name === posthog_surveys_types_1.SurveyEventName.DISMISSED || event_name === posthog_surveys_types_1.SurveyEventName.SENT) {
            var surveyId = properties === null || properties === void 0 ? void 0 : properties[posthog_surveys_types_1.SurveyEventProperties.SURVEY_ID];
            var surveyIteration = properties === null || properties === void 0 ? void 0 : properties[posthog_surveys_types_1.SurveyEventProperties.SURVEY_ITERATION];
            (0, survey_utils_1.setSurveySeenOnLocalStorage)({ id: surveyId, current_iteration: surveyIteration });
            data.$set = __assign(__assign({}, data.$set), (_a = {}, _a[(0, survey_utils_1.getSurveyInteractionProperty)({ id: surveyId, current_iteration: surveyIteration }, event_name === posthog_surveys_types_1.SurveyEventName.SENT ? 'responded' : 'dismissed')] = true, _a));
        }
        // Top-level $set overriding values from the one from properties is taken from the plugin-server normalizeEvent
        // This doesn't handle $set_once, because posthog-people doesn't either
        var finalSet = __assign(__assign({}, data.properties['$set']), data['$set']);
        if (!(0, core_1.isEmptyObject)(finalSet)) {
            this.setPersonPropertiesForFlags(finalSet);
        }
        if (!(0, core_1.isNullish)(this.config.before_send)) {
            var beforeSendResult = this._runBeforeSend(data);
            if (!beforeSendResult) {
                return;
            }
            else {
                data = beforeSendResult;
            }
        }
        this._internalEventEmitter.emit('eventCaptured', data);
        var requestOptions = {
            method: 'POST',
            url: (_b = options === null || options === void 0 ? void 0 : options._url) !== null && _b !== void 0 ? _b : this.requestRouter.endpointFor('api', this.analyticsDefaultEndpoint),
            data: data,
            compression: 'best-available',
            batchKey: options === null || options === void 0 ? void 0 : options._batchKey,
        };
        if (this.config.request_batching && (!options || (options === null || options === void 0 ? void 0 : options._batchKey)) && !(options === null || options === void 0 ? void 0 : options.send_instantly)) {
            this._requestQueue.enqueue(requestOptions);
        }
        else {
            this._send_retriable_request(requestOptions);
        }
        return data;
    };
    PostHog.prototype._addCaptureHook = function (callback) {
        return this.on('eventCaptured', function (data) { return callback(data.event, data); });
    };
    /**
     * This method is used internally to calculate the event properties before sending it to PostHog. It can also be
     * used by integrations (e.g. Segment) to enrich events with PostHog properties before sending them to Segment,
     * which is required for some PostHog products to work correctly. (e.g. to have a correct $session_id property).
     *
     * @param {String} eventName The name of the event. This can be anything the user does - 'Button Click', 'Sign Up', '$pageview', etc.
     * @param {Object} eventProperties The properties to include with the event.
     * @param {Date} [timestamp] The timestamp of the event, e.g. for calculating time on page. If not set, it'll automatically be set to the current time.
     * @param {String} [uuid] The uuid of the event, e.g. for storing the $pageview ID.
     * @param {Boolean} [readOnly] Set this if you do not intend to actually send the event, and therefore do not want to update internal state e.g. session timeout
     *
     * @internal
     */
    PostHog.prototype.calculateEventProperties = function (eventName, eventProperties, timestamp, uuid, readOnly) {
        var _a;
        timestamp = timestamp || new Date();
        if (!this.persistence || !this.sessionPersistence) {
            return eventProperties;
        }
        // set defaults
        var startTimestamp = readOnly ? undefined : this.persistence.remove_event_timer(eventName);
        var properties = __assign({}, eventProperties);
        properties['token'] = this.config.token;
        properties['$config_defaults'] = this.config.defaults;
        if (this.config.cookieless_mode == 'always' ||
            (this.config.cookieless_mode == 'on_reject' && this.consent.isExplicitlyOptedOut())) {
            // Set a flag to tell the plugin server to use cookieless server hash mode
            properties[constants_1.COOKIELESS_MODE_FLAG_PROPERTY] = true;
        }
        if (eventName === '$snapshot') {
            var persistenceProps = __assign(__assign({}, this.persistence.properties()), this.sessionPersistence.properties());
            properties['distinct_id'] = persistenceProps.distinct_id;
            if (
            // we spotted one customer that was managing to send `false` for ~9k events a day
            !((0, core_1.isString)(properties['distinct_id']) || (0, core_1.isNumber)(properties['distinct_id'])) ||
                (0, core_1.isEmptyString)(properties['distinct_id'])) {
                logger_1.logger.error('Invalid distinct_id for replay event. This indicates a bug in your implementation');
            }
            return properties;
        }
        var infoProperties = (0, event_utils_1.getEventProperties)(this.config.mask_personal_data_properties, this.config.custom_personal_data_properties);
        if (this.sessionManager) {
            var _b = this.sessionManager.checkAndGetSessionAndWindowId(readOnly, timestamp.getTime()), sessionId = _b.sessionId, windowId = _b.windowId;
            properties['$session_id'] = sessionId;
            properties['$window_id'] = windowId;
        }
        if (this.sessionPropsManager) {
            (0, utils_1.extend)(properties, this.sessionPropsManager.getSessionProps());
        }
        try {
            if (this.sessionRecording) {
                (0, utils_1.extend)(properties, this.sessionRecording.sdkDebugProperties);
            }
            properties['$sdk_debug_retry_queue_size'] = (_a = this._retryQueue) === null || _a === void 0 ? void 0 : _a.length;
        }
        catch (e) {
            properties['$sdk_debug_error_capturing_properties'] = String(e);
        }
        if (this.requestRouter.region === request_router_1.RequestRouterRegion.CUSTOM) {
            properties['$lib_custom_api_host'] = this.config.api_host;
        }
        var pageviewProperties;
        if (eventName === '$pageview' && !readOnly) {
            pageviewProperties = this.pageViewManager.doPageView(timestamp, uuid);
        }
        else if (eventName === '$pageleave' && !readOnly) {
            pageviewProperties = this.pageViewManager.doPageLeave(timestamp);
        }
        else {
            pageviewProperties = this.pageViewManager.doEvent();
        }
        properties = (0, utils_1.extend)(properties, pageviewProperties);
        if (eventName === '$pageview' && globals_1.document) {
            properties['title'] = globals_1.document.title;
        }
        // set $duration if time_event was previously called for this event
        if (!(0, core_1.isUndefined)(startTimestamp)) {
            var duration_in_ms = timestamp.getTime() - startTimestamp;
            properties['$duration'] = parseFloat((duration_in_ms / 1000).toFixed(3));
        }
        // this is only added when this.config.opt_out_useragent_filter is true,
        // or it would always add "browser"
        if (globals_1.userAgent && this.config.opt_out_useragent_filter) {
            properties['$browser_type'] = this._is_bot() ? 'bot' : 'browser';
        }
        // note: extend writes to the first object, so lets make sure we
        // don't write to the persistence properties object and info
        // properties object by passing in a new object
        // update properties with pageview info and super-properties
        properties = (0, utils_1.extend)({}, infoProperties, this.persistence.properties(), this.sessionPersistence.properties(), properties);
        properties['$is_identified'] = this._isIdentified();
        if ((0, core_1.isArray)(this.config.property_denylist)) {
            (0, utils_1.each)(this.config.property_denylist, function (denylisted_prop) {
                delete properties[denylisted_prop];
            });
        }
        else {
            logger_1.logger.error('Invalid value for property_denylist config: ' +
                this.config.property_denylist +
                ' or property_blacklist config: ' +
                this.config.property_blacklist);
        }
        var sanitize_properties = this.config.sanitize_properties;
        if (sanitize_properties) {
            logger_1.logger.error('sanitize_properties is deprecated. Use before_send instead');
            properties = sanitize_properties(properties, eventName);
        }
        // add person processing flag as very last step, so it cannot be overridden
        var hasPersonProcessing = this._hasPersonProcessing();
        properties['$process_person_profile'] = hasPersonProcessing;
        // if the event has person processing, ensure that all future events will too, even if the setting changes
        if (hasPersonProcessing && !readOnly) {
            this._requirePersonProcessing('_calculate_event_properties');
        }
        return properties;
    };
    /**
     * Add additional set_once properties to the event when creating a person profile. This allows us to create the
     * profile with mostly-accurate properties, despite earlier events not setting them. We do this by storing them in
     * persistence.
     * @param dataSetOnce
     */
    PostHog.prototype._calculate_set_once_properties = function (dataSetOnce) {
        var _a;
        if (!this.persistence || !this._hasPersonProcessing()) {
            return dataSetOnce;
        }
        if (this._personProcessingSetOncePropertiesSent) {
            // We only need to send these properties once. Sending them with later events would be redundant and would
            // just require extra work on the server to process them.
            return dataSetOnce;
        }
        // if we're an identified person, send initial params with every event
        var initialProps = this.persistence.get_initial_props();
        var sessionProps = (_a = this.sessionPropsManager) === null || _a === void 0 ? void 0 : _a.getSetOnceProps();
        var setOnceProperties = (0, utils_1.extend)({}, initialProps, sessionProps || {}, dataSetOnce || {});
        var sanitize_properties = this.config.sanitize_properties;
        if (sanitize_properties) {
            logger_1.logger.error('sanitize_properties is deprecated. Use before_send instead');
            setOnceProperties = sanitize_properties(setOnceProperties, '$set_once');
        }
        this._personProcessingSetOncePropertiesSent = true;
        if ((0, core_1.isEmptyObject)(setOnceProperties)) {
            return undefined;
        }
        return setOnceProperties;
    };
    /**
     * Registers super properties that are included with all events.
     *
     * @remarks
     * Super properties are stored in persistence and automatically added to every event you capture.
     * These values will overwrite any existing super properties with the same keys.
     *
     * @example
     * ```js
     * // register a single property
     * posthog.register({ plan: 'premium' })
     * ```
     *
     * {@label Capture}
     *
     * @example
     * ```js
     * // register multiple properties
     * posthog.register({
     *     email: 'user@example.com',
     *     account_type: 'business',
     *     signup_date: '2023-01-15'
     * })
     * ```
     *
     * @example
     * ```js
     * // register with custom expiration
     * posthog.register({ campaign: 'summer_sale' }, 7) // expires in 7 days
     * ```
     *
     * @public
     *
     * @param {Object} properties properties to store about the user
     * @param {Number} [days] How many days since the user's last visit to store the super properties
     */
    PostHog.prototype.register = function (properties, days) {
        var _a;
        (_a = this.persistence) === null || _a === void 0 ? void 0 : _a.register(properties, days);
    };
    /**
     * Registers super properties only if they haven't been set before.
     *
     * @remarks
     * Unlike `register()`, this method will not overwrite existing super properties.
     * Use this for properties that should only be set once, like signup date or initial referrer.
     *
     * {@label Capture}
     *
     * @example
     * ```js
     * // register once-only properties
     * posthog.register_once({
     *     first_login_date: new Date().toISOString(),
     *     initial_referrer: document.referrer
     * })
     * ```
     *
     * @example
     * ```js
     * // override existing value if it matches default
     * posthog.register_once(
     *     { user_type: 'premium' },
     *     'unknown'  // overwrite if current value is 'unknown'
     * )
     * ```
     *
     * @public
     *
     * @param {Object} properties An associative array of properties to store about the user
     * @param {*} [default_value] Value to override if already set in super properties (ex: 'False') Default: 'None'
     * @param {Number} [days] How many days since the users last visit to store the super properties
     */
    PostHog.prototype.register_once = function (properties, default_value, days) {
        var _a;
        (_a = this.persistence) === null || _a === void 0 ? void 0 : _a.register_once(properties, default_value, days);
    };
    /**
     * Registers super properties for the current session only.
     *
     * @remarks
     * Session super properties are automatically added to all events during the current browser session.
     * Unlike regular super properties, these are cleared when the session ends and are stored in sessionStorage.
     *
     * {@label Capture}
     *
     * @example
     * ```js
     * // register session-specific properties
     * posthog.register_for_session({
     *     current_page_type: 'checkout',
     *     ab_test_variant: 'control'
     * })
     * ```
     *
     * @example
     * ```js
     * // register properties for user flow tracking
     * posthog.register_for_session({
     *     selected_plan: 'pro',
     *     completed_steps: 3,
     *     flow_id: 'signup_flow_v2'
     * })
     * ```
     *
     * @public
     *
     * @param {Object} properties An associative array of properties to store about the user
     */
    PostHog.prototype.register_for_session = function (properties) {
        var _a;
        (_a = this.sessionPersistence) === null || _a === void 0 ? void 0 : _a.register(properties);
    };
    /**
     * Removes a super property from persistent storage.
     *
     * @remarks
     * This will stop the property from being automatically included in future events.
     * The property will be permanently removed from the user's profile.
     *
     * {@label Capture}
     *
     * @example
     * ```js
     * // remove a super property
     * posthog.unregister('plan_type')
     * ```
     *
     * @public
     *
     * @param {String} property The name of the super property to remove
     */
    PostHog.prototype.unregister = function (property) {
        var _a;
        (_a = this.persistence) === null || _a === void 0 ? void 0 : _a.unregister(property);
    };
    /**
     * Removes a session super property from the current session.
     *
     * @remarks
     * This will stop the property from being automatically included in future events for this session.
     * The property is removed from sessionStorage.
     *
     * {@label Capture}
     *
     * @example
     * ```js
     * // remove a session property
     * posthog.unregister_for_session('current_flow')
     * ```
     *
     * @public
     *
     * @param {String} property The name of the session super property to remove
     */
    PostHog.prototype.unregister_for_session = function (property) {
        var _a;
        (_a = this.sessionPersistence) === null || _a === void 0 ? void 0 : _a.unregister(property);
    };
    PostHog.prototype._register_single = function (prop, value) {
        var _a;
        this.register((_a = {}, _a[prop] = value, _a));
    };
    /**
     * Gets the value of a feature flag for the current user.
     *
     * @remarks
     * Returns the feature flag value which can be a boolean, string, or undefined.
     * Supports multivariate flags that can return custom string values.
     *
     * {@label Feature flags}
     *
     * @example
     * ```js
     * // check boolean flag
     * if (posthog.getFeatureFlag('new-feature')) {
     *     // show new feature
     * }
     * ```
     *
     * @example
     * ```js
     * // check multivariate flag
     * const variant = posthog.getFeatureFlag('button-color')
     * if (variant === 'red') {
     *     // show red button
     * }
     * ```
     *
     * @public
     *
     * @param {Object|String} prop Key of the feature flag.
     * @param {Object|String} options (optional) If {send_event: false}, we won't send an $feature_flag_call event to PostHog.
     */
    PostHog.prototype.getFeatureFlag = function (key, options) {
        return this.featureFlags.getFeatureFlag(key, options);
    };
    /**
     * Get feature flag payload value matching key for user (supports multivariate flags).
     *
     * {@label Feature flags}
     *
     * @example
     * ```js
     * if(posthog.getFeatureFlag('beta-feature') === 'some-value') {
     *      const someValue = posthog.getFeatureFlagPayload('beta-feature')
     *      // do something
     * }
     * ```
     *
     * @public
     *
     * @param {Object|String} prop Key of the feature flag.
     */
    PostHog.prototype.getFeatureFlagPayload = function (key) {
        var payload = this.featureFlags.getFeatureFlagPayload(key);
        try {
            return JSON.parse(payload);
        }
        catch (_a) {
            return payload;
        }
    };
    /**
     * Checks if a feature flag is enabled for the current user.
     *
     * @remarks
     * Returns true if the flag is enabled, false if disabled, or undefined if not found.
     * This is a convenience method that treats any truthy value as enabled.
     *
     * {@label Feature flags}
     *
     * @example
     * ```js
     * // simple feature flag check
     * if (posthog.isFeatureEnabled('new-checkout')) {
     *     showNewCheckout()
     * }
     * ```
     *
     * @example
     * ```js
     * // disable event tracking
     * if (posthog.isFeatureEnabled('feature', { send_event: false })) {
     *     // flag checked without sending $feature_flag_call event
     * }
     * ```
     *
     * @public
     *
     * @param {Object|String} prop Key of the feature flag.
     * @param {Object|String} options (optional) If {send_event: false}, we won't send an $feature_flag_call event to PostHog.
     */
    PostHog.prototype.isFeatureEnabled = function (key, options) {
        return this.featureFlags.isFeatureEnabled(key, options);
    };
    /**
     * Feature flag values are cached. If something has changed with your user and you'd like to refetch their flag values, call this method.
     *
     * {@label Feature flags}
     *
     * @example
     * ```js
     * posthog.reloadFeatureFlags()
     * ```
     *
     * @public
     */
    PostHog.prototype.reloadFeatureFlags = function () {
        this.featureFlags.reloadFeatureFlags();
    };
    /**
     * Opt the user in or out of an early access feature. [Learn more in the docs](/docs/feature-flags/early-access-feature-management#option-2-custom-implementation)
     *
     * {@label Feature flags}
     *
     * @example
     * ```js
     * const toggleBeta = (betaKey) => {
     *   if (activeBetas.some(
     *     beta => beta.flagKey === betaKey
     *   )) {
     *     posthog.updateEarlyAccessFeatureEnrollment(
     *       betaKey,
     *       false
     *     )
     *     setActiveBetas(
     *       prevActiveBetas => prevActiveBetas.filter(
     *         item => item.flagKey !== betaKey
     *       )
     *     );
     *     return
     *   }
     *
     *   posthog.updateEarlyAccessFeatureEnrollment(
     *     betaKey,
     *     true
     *   )
     *   setInactiveBetas(
     *     prevInactiveBetas => prevInactiveBetas.filter(
     *       item => item.flagKey !== betaKey
     *     )
     *   );
     * }
     *
     * const registerInterest = (featureKey) => {
     *   posthog.updateEarlyAccessFeatureEnrollment(
     *     featureKey,
     *     true
     *   )
     *   // Update UI to show user has registered
     * }
     * ```
     *
     * @public
     *
     * @param {String} key The key of the feature flag to update.
     * @param {Boolean} isEnrolled Whether the user is enrolled in the feature.
     * @param {String} [stage] The stage of the feature flag to update.
     */
    PostHog.prototype.updateEarlyAccessFeatureEnrollment = function (key, isEnrolled, stage) {
        this.featureFlags.updateEarlyAccessFeatureEnrollment(key, isEnrolled, stage);
    };
    /**
     * Get the list of early access features. To check enrollment status, use `isFeatureEnabled`. [Learn more in the docs](/docs/feature-flags/early-access-feature-management#option-2-custom-implementation)
     *
     * {@label Feature flags}
     *
     * @example
     * ```js
     * const posthog = usePostHog()
     * const activeFlags = useActiveFeatureFlags()
     *
     * const [activeBetas, setActiveBetas] = useState([])
     * const [inactiveBetas, setInactiveBetas] = useState([])
     * const [comingSoonFeatures, setComingSoonFeatures] = useState([])
     *
     * useEffect(() => {
     *   posthog.getEarlyAccessFeatures((features) => {
     *     // Filter features by stage
     *     const betaFeatures = features.filter(feature => feature.stage === 'beta')
     *     const conceptFeatures = features.filter(feature => feature.stage === 'concept')
     *
     *     setComingSoonFeatures(conceptFeatures)
     *
     *     if (!activeFlags || activeFlags.length === 0) {
     *       setInactiveBetas(betaFeatures)
     *       return
     *     }
     *
     *     const activeBetas = betaFeatures.filter(
     *             beta => activeFlags.includes(beta.flagKey)
     *         );
     *     const inactiveBetas = betaFeatures.filter(
     *             beta => !activeFlags.includes(beta.flagKey)
     *         );
     *     setActiveBetas(activeBetas)
     *     setInactiveBetas(inactiveBetas)
     *   }, true, ['concept', 'beta'])
     * }, [activeFlags])
     * ```
     *
     * @public
     *
     * @param {Function} callback The callback function will be called when the early access features are loaded.
     * @param {Boolean} [force_reload] Whether to force a reload of the early access features.
     * @param {String[]} [stages] The stages of the early access features to load.
     */
    PostHog.prototype.getEarlyAccessFeatures = function (callback, force_reload, stages) {
        if (force_reload === void 0) { force_reload = false; }
        return this.featureFlags.getEarlyAccessFeatures(callback, force_reload, stages);
    };
    /**
     * Exposes a set of events that PostHog will emit.
     * e.g. `eventCaptured` is emitted immediately before trying to send an event
     *
     * Unlike  `onFeatureFlags` and `onSessionId` these are not called when the
     * listener is registered, the first callback will be the next event
     * _after_ registering a listener
     *
     * {@label Capture}
     *
     * @example
     * ```js
     * posthog.on('eventCaptured', (event) => {
     *   console.log(event)
     * })
     * ```
     *
     * @public
     *
     * @param {String} event The event to listen for.
     * @param {Function} cb The callback function to call when the event is emitted.
     * @returns {Function} A function that can be called to unsubscribe the listener.
     */
    PostHog.prototype.on = function (event, cb) {
        return this._internalEventEmitter.on(event, cb);
    };
    /**
     * Register an event listener that runs when feature flags become available or when they change.
     * If there are flags, the listener is called immediately in addition to being called on future changes.
     * Note that this is not called only when we fetch feature flags from the server, but also when they change in the browser.
     *
     * {@label Feature flags}
     *
     * @example
     * ```js
     * posthog.onFeatureFlags(function(featureFlags, featureFlagsVariants, { errorsLoading }) {
     *     // do something
     * })
     * ```
     *
     * @param callback - The callback function will be called once the feature flags are ready or when they are updated.
     *                   It'll return a list of feature flags enabled for the user, the variants,
     *                   and also a context object indicating whether we succeeded to fetch the flags or not.
     * @returns A function that can be called to unsubscribe the listener. Used by `useEffect` when the component unmounts.
     */
    PostHog.prototype.onFeatureFlags = function (callback) {
        return this.featureFlags.onFeatureFlags(callback);
    };
    /**
     * Register an event listener that runs when surveys are loaded.
     *
     * Callback parameters:
     * - surveys: Survey[]: An array containing all survey objects fetched from PostHog using the getSurveys method
     * - context: { isLoaded: boolean, error?: string }: An object indicating if the surveys were loaded successfully
     *
     * {@label Surveys}
     *
     * @example
     * ```js
     * posthog.onSurveysLoaded((surveys, context) => { // do something })
     * ```
     *
     *
     * @param {Function} callback The callback function will be called when surveys are loaded or updated.
     * @returns {Function} A function that can be called to unsubscribe the listener.
     */
    PostHog.prototype.onSurveysLoaded = function (callback) {
        return this.surveys.onSurveysLoaded(callback);
    };
    /**
     * Register an event listener that runs whenever the session id or window id change.
     * If there is already a session id, the listener is called immediately in addition to being called on future changes.
     *
     * Can be used, for example, to sync the PostHog session id with a backend session.
     *
     * {@label Identification}
     *
     * @example
     * ```js
     * posthog.onSessionId(function(sessionId, windowId) { // do something })
     * ```
     *
     * @param {Function} [callback] The callback function will be called once a session id is present or when it or the window id are updated.
     * @returns {Function} A function that can be called to unsubscribe the listener. E.g. Used by `useEffect` when the component unmounts.
     */
    PostHog.prototype.onSessionId = function (callback) {
        var _a, _b;
        return (_b = (_a = this.sessionManager) === null || _a === void 0 ? void 0 : _a.onSessionId(callback)) !== null && _b !== void 0 ? _b : (function () { });
    };
    /**
     * Get list of all surveys.
     *
     * {@label Surveys}
     *
     * @example
     * ```js
     * function callback(surveys, context) {
     *   // do something
     * }
     *
     * posthog.getSurveys(callback, false)
     * ```
     *
     * @public
     *
     * @param {Function} [callback] Function that receives the array of surveys
     * @param {Boolean} [forceReload] Optional boolean to force an API call for updated surveys
     */
    PostHog.prototype.getSurveys = function (callback, forceReload) {
        if (forceReload === void 0) { forceReload = false; }
        this.surveys.getSurveys(callback, forceReload);
    };
    /**
     * Get surveys that should be enabled for the current user. See [fetching surveys documentation](/docs/surveys/implementing-custom-surveys#fetching-surveys-manually) for more details.
     *
     * {@label Surveys}
     *
     * @example
     * ```js
     * posthog.getActiveMatchingSurveys((surveys) => {
     *      // do something
     * })
     * ```
     *
     * @public
     *
     * @param {Function} [callback] The callback function will be called when the surveys are loaded or updated.
     * @param {Boolean} [forceReload] Whether to force a reload of the surveys.
     */
    PostHog.prototype.getActiveMatchingSurveys = function (callback, forceReload) {
        if (forceReload === void 0) { forceReload = false; }
        this.surveys.getActiveMatchingSurveys(callback, forceReload);
    };
    /**
     * Although we recommend using popover surveys and display conditions,
     * if you want to show surveys programmatically without setting up all
     * the extra logic needed for API surveys, you can render surveys
     * programmatically with the renderSurvey method.
     *
     * This takes a survey ID and an HTML selector to render an unstyled survey.
     *
     * {@label Surveys}
     *
     * @example
     * ```js
     * posthog.renderSurvey(coolSurveyID, '#survey-container')
     * ```
     *
     * @public
     *
     * @param {String} surveyId The ID of the survey to render.
     * @param {String} selector The selector of the HTML element to render the survey on.
     */
    PostHog.prototype.renderSurvey = function (surveyId, selector) {
        this.surveys.renderSurvey(surveyId, selector);
    };
    /**
     * Checks the feature flags associated with this Survey to see if the survey can be rendered.
     * This method is deprecated because it's synchronous and won't return the correct result if surveys are not loaded.
     * Use `canRenderSurveyAsync` instead.
     *
     * {@label Surveys}
     *
     *
     * @deprecated
     *
     * @param surveyId The ID of the survey to check.
     * @returns A SurveyRenderReason object indicating if the survey can be rendered.
     */
    PostHog.prototype.canRenderSurvey = function (surveyId) {
        return this.surveys.canRenderSurvey(surveyId);
    };
    /**
     * Checks the feature flags associated with this Survey to see if the survey can be rendered.
     *
     * {@label Surveys}
     *
     * @example
     * ```js
     * posthog.canRenderSurveyAsync(surveyId).then((result) => {
     *     if (result.visible) {
     *         // Survey can be rendered
     *         console.log('Survey can be rendered')
     *     } else {
     *         // Survey cannot be rendered
     *         console.log('Survey cannot be rendered:', result.disabledReason)
     *     }
     * })
     * ```
     *
     * @public
     *
     * @param surveyId The ID of the survey to check.
     * @param forceReload If true, the survey will be reloaded from the server, Default: false
     * @returns A SurveyRenderReason object indicating if the survey can be rendered.
     */
    PostHog.prototype.canRenderSurveyAsync = function (surveyId, forceReload) {
        if (forceReload === void 0) { forceReload = false; }
        return this.surveys.canRenderSurveyAsync(surveyId, forceReload);
    };
    /**
     * Associates a user with a unique identifier instead of an auto-generated ID.
     * Learn more about [identifying users](/docs/product-analytics/identify)
     *
     * {@label Identification}
     *
     * @remarks
     * By default, PostHog assigns each user a randomly generated `distinct_id`. Use this method to
     * replace that ID with your own unique identifier (like a user ID from your database).
     *
     * @example
     * ```js
     * // basic identification
     * posthog.identify('user_12345')
     * ```
     *
     * @example
     * ```js
     * // identify with user properties
     * posthog.identify('user_12345', {
     *     email: 'user@example.com',
     *     plan: 'premium'
     * })
     * ```
     *
     * @example
     * ```js
     * // identify with set and set_once properties
     * posthog.identify('user_12345',
     *     { last_login: new Date() },  // updates every time
     *     { signup_date: new Date() }  // sets only once
     * )
     * ```
     *
     * @public
     *
     * @param {String} [new_distinct_id] A string that uniquely identifies a user. If not provided, the distinct_id currently in the persistent store (cookie or localStorage) will be used.
     * @param {Object} [userPropertiesToSet] Optional: An associative array of properties to store about the user. Note: For feature flag evaluations, if the same key is present in the userPropertiesToSetOnce,
     *  it will be overwritten by the value in userPropertiesToSet.
     * @param {Object} [userPropertiesToSetOnce] Optional: An associative array of properties to store about the user. If property is previously set, this does not override that value.
     */
    PostHog.prototype.identify = function (new_distinct_id, userPropertiesToSet, userPropertiesToSetOnce) {
        if (!this.__loaded || !this.persistence) {
            return logger_1.logger.uninitializedWarning('posthog.identify');
        }
        if ((0, core_1.isNumber)(new_distinct_id)) {
            new_distinct_id = new_distinct_id.toString();
            logger_1.logger.warn('The first argument to posthog.identify was a number, but it should be a string. It has been converted to a string.');
        }
        //if the new_distinct_id has not been set ignore the identify event
        if (!new_distinct_id) {
            logger_1.logger.error('Unique user id has not been set in posthog.identify');
            return;
        }
        if ((0, core_1.isDistinctIdStringLike)(new_distinct_id)) {
            logger_1.logger.critical("The string \"".concat(new_distinct_id, "\" was set in posthog.identify which indicates an error. This ID should be unique to the user and not a hardcoded string."));
            return;
        }
        if (new_distinct_id === constants_1.COOKIELESS_SENTINEL_VALUE) {
            logger_1.logger.critical("The string \"".concat(constants_1.COOKIELESS_SENTINEL_VALUE, "\" was set in posthog.identify which indicates an error. This ID is only used as a sentinel value."));
            return;
        }
        if (!this._requirePersonProcessing('posthog.identify')) {
            return;
        }
        var previous_distinct_id = this.get_distinct_id();
        this.register({ $user_id: new_distinct_id });
        if (!this.get_property('$device_id')) {
            // The persisted distinct id might not actually be a device id at all
            // it might be a distinct id of the user from before
            var device_id = previous_distinct_id;
            this.register_once({
                $had_persisted_distinct_id: true,
                $device_id: device_id,
            }, '');
        }
        // if the previous distinct id had an alias stored, then we clear it
        if (new_distinct_id !== previous_distinct_id && new_distinct_id !== this.get_property(constants_1.ALIAS_ID_KEY)) {
            this.unregister(constants_1.ALIAS_ID_KEY);
            this.register({ distinct_id: new_distinct_id });
        }
        var isKnownAnonymous = (this.persistence.get_property(constants_1.USER_STATE) || 'anonymous') === 'anonymous';
        // send an $identify event any time the distinct_id is changing and the old ID is an anonymous ID
        // - logic on the server will determine whether or not to do anything with it.
        if (new_distinct_id !== previous_distinct_id && isKnownAnonymous) {
            this.persistence.set_property(constants_1.USER_STATE, 'identified');
            // Update current user properties
            this.setPersonPropertiesForFlags(__assign(__assign({}, (userPropertiesToSetOnce || {})), (userPropertiesToSet || {})), false);
            this.capture('$identify', {
                distinct_id: new_distinct_id,
                $anon_distinct_id: previous_distinct_id,
            }, { $set: userPropertiesToSet || {}, $set_once: userPropertiesToSetOnce || {} });
            this._cachedPersonProperties = (0, property_utils_1.getPersonPropertiesHash)(new_distinct_id, userPropertiesToSet, userPropertiesToSetOnce);
            // let the reload feature flag request know to send this previous distinct id
            // for flag consistency
            this.featureFlags.setAnonymousDistinctId(previous_distinct_id);
        }
        else if (userPropertiesToSet || userPropertiesToSetOnce) {
            // If the distinct_id is not changing, but we have user properties to set, we can check if they have changed
            // and if so, send a $set event
            this.setPersonProperties(userPropertiesToSet, userPropertiesToSetOnce);
        }
        // Reload active feature flags if the user identity changes.
        // Note we don't reload this on property changes as these get processed async
        if (new_distinct_id !== previous_distinct_id) {
            this.reloadFeatureFlags();
            // also clear any stored flag calls
            this.unregister(constants_1.FLAG_CALL_REPORTED);
        }
    };
    /**
     * Sets properties on the person profile associated with the current `distinct_id`.
     * Learn more about [identifying users](/docs/product-analytics/identify)
     *
     * {@label Identification}
     *
     * @remarks
     * Updates user properties that are stored with the person profile in PostHog.
     * If `person_profiles` is set to `identified_only` and no profile exists, this will create one.
     *
     * @example
     * ```js
     * // set user properties
     * posthog.setPersonProperties({
     *     email: 'user@example.com',
     *     plan: 'premium'
     * })
     * ```
     *
     * @example
     * ```js
     * // set properties
     * posthog.setPersonProperties(
     *     { name: 'Max Hedgehog' },  // $set properties
     *     { initial_url: '/blog' }   // $set_once properties
     * )
     * ```
     *
     * @public
     *
     * @param {Object} [userPropertiesToSet] Optional: An associative array of properties to store about the user. Note: For feature flag evaluations, if the same key is present in the userPropertiesToSetOnce,
     *  it will be overwritten by the value in userPropertiesToSet.
     * @param {Object} [userPropertiesToSetOnce] Optional: An associative array of properties to store about the user. If property is previously set, this does not override that value.
     */
    PostHog.prototype.setPersonProperties = function (userPropertiesToSet, userPropertiesToSetOnce) {
        if (!userPropertiesToSet && !userPropertiesToSetOnce) {
            return;
        }
        if (!this._requirePersonProcessing('posthog.setPersonProperties')) {
            return;
        }
        var hash = (0, property_utils_1.getPersonPropertiesHash)(this.get_distinct_id(), userPropertiesToSet, userPropertiesToSetOnce);
        // if exactly this $set call has been sent before, don't send it again - determine based on hash of properties
        if (this._cachedPersonProperties === hash) {
            logger_1.logger.info('A duplicate setPersonProperties call was made with the same properties. It has been ignored.');
            return;
        }
        // Update current user properties
        this.setPersonPropertiesForFlags(__assign(__assign({}, (userPropertiesToSetOnce || {})), (userPropertiesToSet || {})));
        this.capture('$set', { $set: userPropertiesToSet || {}, $set_once: userPropertiesToSetOnce || {} });
        this._cachedPersonProperties = hash;
    };
    /**
     * Associates the user with a group for group-based analytics.
     * Learn more about [groups](/docs/product-analytics/group-analytics)
     *
     * {@label Identification}
     *
     * @remarks
     * Groups allow you to analyze users collectively (e.g., by organization, team, or account).
     * This sets the group association for all subsequent events and reloads feature flags.
     *
     * @example
     * ```js
     * // associate user with an organization
     * posthog.group('organization', 'org_12345', {
     *     name: 'Acme Corp',
     *     plan: 'enterprise'
     * })
     * ```
     *
     * @example
     * ```js
     * // associate with multiple group types
     * posthog.group('organization', 'org_12345')
     * posthog.group('team', 'team_67890')
     * ```
     *
     * @public
     *
     * @param {String} groupType Group type (example: 'organization')
     * @param {String} groupKey Group key (example: 'org::5')
     * @param {Object} groupPropertiesToSet Optional properties to set for group
     */
    PostHog.prototype.group = function (groupType, groupKey, groupPropertiesToSet) {
        var _a, _b;
        if (!groupType || !groupKey) {
            logger_1.logger.error('posthog.group requires a group type and group key');
            return;
        }
        if (!this._requirePersonProcessing('posthog.group')) {
            return;
        }
        var existingGroups = this.getGroups();
        // if group key changes, remove stored group properties
        if (existingGroups[groupType] !== groupKey) {
            this.resetGroupPropertiesForFlags(groupType);
        }
        this.register({ $groups: __assign(__assign({}, existingGroups), (_a = {}, _a[groupType] = groupKey, _a)) });
        if (groupPropertiesToSet) {
            this.capture('$groupidentify', {
                $group_type: groupType,
                $group_key: groupKey,
                $group_set: groupPropertiesToSet,
            });
            this.setGroupPropertiesForFlags((_b = {}, _b[groupType] = groupPropertiesToSet, _b));
        }
        // If groups change and no properties change, reload feature flags.
        // The property change reload case is handled in setGroupPropertiesForFlags.
        if (existingGroups[groupType] !== groupKey && !groupPropertiesToSet) {
            this.reloadFeatureFlags();
        }
    };
    /**
     * Resets only the group properties of the user currently logged in.
     * Learn more about [groups](/docs/product-analytics/group-analytics)
     *
     * {@label Identification}
     *
     * @example
     * ```js
     * posthog.resetGroups()
     * ```
     *
     * @public
     */
    PostHog.prototype.resetGroups = function () {
        this.register({ $groups: {} });
        this.resetGroupPropertiesForFlags();
        // If groups changed, reload feature flags.
        this.reloadFeatureFlags();
    };
    /**
     * Sometimes, you might want to evaluate feature flags using properties that haven't been ingested yet,
     * or were set incorrectly earlier. You can do so by setting properties the flag depends on with these calls:
     *
     * {@label Feature flags}
     *
     * @example
     * ```js
     * // Set properties
     * posthog.setPersonPropertiesForFlags({'property1': 'value', property2: 'value2'})
     * ```
     *
     * @example
     * ```js
     * // Set properties without reloading
     * posthog.setPersonPropertiesForFlags({'property1': 'value', property2: 'value2'}, false)
     * ```
     *
     * @public
     *
     * @param {Object} properties The properties to override.
     * @param {Boolean} [reloadFeatureFlags] Whether to reload feature flags.
     */
    PostHog.prototype.setPersonPropertiesForFlags = function (properties, reloadFeatureFlags) {
        if (reloadFeatureFlags === void 0) { reloadFeatureFlags = true; }
        this.featureFlags.setPersonPropertiesForFlags(properties, reloadFeatureFlags);
    };
    /**
     * Resets the person properties for feature flags.
     *
     * {@label Feature flags}
     *
     * @public
     *
     * @example
     * ```js
     * posthog.resetPersonPropertiesForFlags()
     * ```
     */
    PostHog.prototype.resetPersonPropertiesForFlags = function () {
        this.featureFlags.resetPersonPropertiesForFlags();
    };
    /**
     * Set override group properties for feature flags.
     * This is used when dealing with new groups / where you don't want to wait for ingestion
     * to update properties.
     * Takes in an object, the key of which is the group type.
     *
     * {@label Feature flags}
     *
     * @public
     *
     * @example
     * ```js
     * // Set properties with reload
     * posthog.setGroupPropertiesForFlags({'organization': { name: 'CYZ', employees: '11' } })
     * ```
     *
     * @example
     * ```js
     * // Set properties without reload
     * posthog.setGroupPropertiesForFlags({'organization': { name: 'CYZ', employees: '11' } }, false)
     * ```
     *
     * @param {Object} properties The properties to override, the key of which is the group type.
     * @param {Boolean} [reloadFeatureFlags] Whether to reload feature flags.
     */
    PostHog.prototype.setGroupPropertiesForFlags = function (properties, reloadFeatureFlags) {
        if (reloadFeatureFlags === void 0) { reloadFeatureFlags = true; }
        if (!this._requirePersonProcessing('posthog.setGroupPropertiesForFlags')) {
            return;
        }
        this.featureFlags.setGroupPropertiesForFlags(properties, reloadFeatureFlags);
    };
    /**
     * Resets the group properties for feature flags.
     *
     * {@label Feature flags}
     *
     * @public
     *
     * @example
     * ```js
     * posthog.resetGroupPropertiesForFlags()
     * ```
     */
    PostHog.prototype.resetGroupPropertiesForFlags = function (group_type) {
        this.featureFlags.resetGroupPropertiesForFlags(group_type);
    };
    /**
     * Resets all user data and starts a fresh session.
     *
     * ⚠️ **Warning**: Only call this when a user logs out. Calling at the wrong time can cause split sessions.
     *
     * This clears:
     * - Session ID and super properties
     * - User identification (sets new random distinct_id)
     * - Cached data and consent settings
     *
     * {@label Identification}
     * @example
     * ```js
     * // reset on user logout
     * function logout() {
     *     posthog.reset()
     *     // redirect to login page
     * }
     * ```
     *
     * @example
     * ```js
     * // reset and generate new device ID
     * posthog.reset(true)  // also resets device_id
     * ```
     *
     * @public
     */
    PostHog.prototype.reset = function (reset_device_id) {
        var _a, _b, _c, _d;
        logger_1.logger.info('reset');
        if (!this.__loaded) {
            return logger_1.logger.uninitializedWarning('posthog.reset');
        }
        var device_id = this.get_property('$device_id');
        this.consent.reset();
        (_a = this.persistence) === null || _a === void 0 ? void 0 : _a.clear();
        (_b = this.sessionPersistence) === null || _b === void 0 ? void 0 : _b.clear();
        this.surveys.reset();
        this.featureFlags.reset();
        (_c = this.persistence) === null || _c === void 0 ? void 0 : _c.set_property(constants_1.USER_STATE, 'anonymous');
        (_d = this.sessionManager) === null || _d === void 0 ? void 0 : _d.resetSessionId();
        this._cachedPersonProperties = null;
        if (this.config.cookieless_mode === 'always') {
            this.register_once({
                distinct_id: constants_1.COOKIELESS_SENTINEL_VALUE,
                $device_id: null,
            }, '');
        }
        else {
            var uuid = this.config.get_device_id((0, uuidv7_1.uuidv7)());
            this.register_once({
                distinct_id: uuid,
                $device_id: reset_device_id ? uuid : device_id,
            }, '');
        }
        this.register({
            $last_posthog_reset: new Date().toISOString(),
        }, 1);
    };
    /**
     * Returns the current distinct ID for the user.
     *
     * @remarks
     * This is either the auto-generated ID or the ID set via `identify()`.
     * The distinct ID is used to associate events with users in PostHog.
     *
     * {@label Identification}
     *
     * @example
     * ```js
     * // get the current user ID
     * const userId = posthog.get_distinct_id()
     * console.log('Current user:', userId)
     * ```
     *
     * @example
     * ```js
     * // use in loaded callback
     * posthog.init('token', {
     *     loaded: (posthog) => {
     *         const id = posthog.get_distinct_id()
     *         // use the ID
     *     }
     * })
     * ```
     *
     * @public
     *
     * @returns The current distinct ID
     */
    PostHog.prototype.get_distinct_id = function () {
        return this.get_property('distinct_id');
    };
    /**
     * Returns the current groups.
     *
     * {@label Identification}
     *
     * @public
     *
     * @returns The current groups
     */
    PostHog.prototype.getGroups = function () {
        return this.get_property('$groups') || {};
    };
    /**
     * Returns the current session_id.
     *
     * @remarks
     * This should only be used for informative purposes.
     * Any actual internal use case for the session_id should be handled by the sessionManager.
     *
     * {@label Session replay}
     *
     * @public
     *
     * @returns The current session_id
     */
    PostHog.prototype.get_session_id = function () {
        var _a, _b;
        return (_b = (_a = this.sessionManager) === null || _a === void 0 ? void 0 : _a.checkAndGetSessionAndWindowId(true).sessionId) !== null && _b !== void 0 ? _b : '';
    };
    /**
     * Returns the Replay url for the current session.
     *
     * {@label Session replay}
     *
     * @public
     *
     * @example
     * ```js
     * // basic usage
     * posthog.get_session_replay_url()
     *
     * @example
     * ```js
     * // timestamp
     * posthog.get_session_replay_url({ withTimestamp: true })
     * ```
     *
     * @example
     * ```js
     * // timestamp and lookback
     * posthog.get_session_replay_url({
     *   withTimestamp: true,
     *   timestampLookBack: 30 // look back 30 seconds
     * })
     * ```
     *
     * @param options Options for the url
     * @param options.withTimestamp Whether to include the timestamp in the url (defaults to false)
     * @param options.timestampLookBack How many seconds to look back for the timestamp (defaults to 10)
     */
    PostHog.prototype.get_session_replay_url = function (options) {
        var _a;
        if (!this.sessionManager) {
            return '';
        }
        var _b = this.sessionManager.checkAndGetSessionAndWindowId(true), sessionId = _b.sessionId, sessionStartTimestamp = _b.sessionStartTimestamp;
        var url = this.requestRouter.endpointFor('ui', "/project/".concat(this.config.token, "/replay/").concat(sessionId));
        if ((options === null || options === void 0 ? void 0 : options.withTimestamp) && sessionStartTimestamp) {
            var LOOK_BACK = (_a = options.timestampLookBack) !== null && _a !== void 0 ? _a : 10;
            if (!sessionStartTimestamp) {
                return url;
            }
            var recordingStartTime = Math.max(Math.floor((new Date().getTime() - sessionStartTimestamp) / 1000) - LOOK_BACK, 0);
            url += "?t=".concat(recordingStartTime);
        }
        return url;
    };
    /**
     * Creates an alias linking two distinct user identifiers. Learn more about [identifying users](/docs/product-analytics/identify)
     *
     * {@label Identification}
     *
     * @remarks
     * PostHog will use this to link two distinct_ids going forward (not retroactively).
     * Call this when a user signs up to connect their anonymous session with their account.
     *
     *
     * @example
     * ```js
     * // link anonymous user to account on signup
     * posthog.alias('user_12345')
     * ```
     *
     * @example
     * ```js
     * // explicit alias with original ID
     * posthog.alias('user_12345', 'anonymous_abc123')
     * ```
     *
     * @public
     *
     * @param {String} alias A unique identifier that you want to use for this user in the future.
     * @param {String} [original] The current identifier being used for this user.
     */
    PostHog.prototype.alias = function (alias, original) {
        // If the $people_distinct_id key exists in persistence, there has been a previous
        // posthog.people.identify() call made for this user. It is VERY BAD to make an alias with
        // this ID, as it will duplicate users.
        if (alias === this.get_property(constants_1.PEOPLE_DISTINCT_ID_KEY)) {
            logger_1.logger.critical('Attempting to create alias for existing People user - aborting.');
            return -2;
        }
        if (!this._requirePersonProcessing('posthog.alias')) {
            return;
        }
        if ((0, core_1.isUndefined)(original)) {
            original = this.get_distinct_id();
        }
        if (alias !== original) {
            this._register_single(constants_1.ALIAS_ID_KEY, alias);
            return this.capture('$create_alias', { alias: alias, distinct_id: original });
        }
        else {
            logger_1.logger.warn('alias matches current distinct_id - skipping api call.');
            this.identify(alias);
            return -1;
        }
    };
    /**
     * Updates the configuration of the PostHog instance.
     *
     * {@label Initialization}
     *
     * @public
     *
     * @param {Partial<PostHogConfig>} config A dictionary of new configuration values to update
     */
    PostHog.prototype.set_config = function (config) {
        var _a, _b, _c, _d, _e;
        var oldConfig = __assign({}, this.config);
        if ((0, core_1.isObject)(config)) {
            (0, utils_1.extend)(this.config, (0, exports.configRenames)(config));
            var isPersistenceDisabled = this._is_persistence_disabled();
            (_a = this.persistence) === null || _a === void 0 ? void 0 : _a.update_config(this.config, oldConfig, isPersistenceDisabled);
            this.sessionPersistence =
                this.config.persistence === 'sessionStorage' || this.config.persistence === 'memory'
                    ? this.persistence
                    : new posthog_persistence_1.PostHogPersistence(__assign(__assign({}, this.config), { persistence: 'sessionStorage' }), isPersistenceDisabled);
            if (storage_1.localStore._is_supported() && storage_1.localStore._get('ph_debug') === 'true') {
                this.config.debug = true;
            }
            if (this.config.debug) {
                config_1.default.DEBUG = true;
                logger_1.logger.info('set_config', {
                    config: config,
                    oldConfig: oldConfig,
                    newConfig: __assign({}, this.config),
                });
            }
            (_b = this.sessionRecording) === null || _b === void 0 ? void 0 : _b.startIfEnabledOrStop();
            (_c = this.autocapture) === null || _c === void 0 ? void 0 : _c.startIfEnabled();
            (_d = this.heatmaps) === null || _d === void 0 ? void 0 : _d.startIfEnabled();
            this.surveys.loadIfEnabled();
            this._sync_opt_out_with_persistence();
            (_e = this.externalIntegrations) === null || _e === void 0 ? void 0 : _e.startIfEnabledOrStop();
        }
    };
    /**
     * turns session recording on, and updates the config option `disable_session_recording` to false
     *
     * {@label Session replay}
     *
     * @public
     *
     * @example
     * ```js
     * // Start and ignore controls
     * posthog.startSessionRecording(true)
     * ```
     *
     * @example
     * ```js
     * // Start and override controls
     * posthog.startSessionRecording({
     *   // you don't have to send all of these
     *   sampling: true || false,
     *   linked_flag: true || false,
     *   url_trigger: true || false,
     *   event_trigger: true || false
     * })
     * ```
     *
     * @param override.sampling - optional boolean to override the default sampling behavior - ensures the next session recording to start will not be skipped by sampling config.
     * @param override.linked_flag - optional boolean to override the default linked_flag behavior - ensures the next session recording to start will not be skipped by linked_flag config.
     * @param override.url_trigger - optional boolean to override the default url_trigger behavior - ensures the next session recording to start will not be skipped by url_trigger config.
     * @param override.event_trigger - optional boolean to override the default event_trigger behavior - ensures the next session recording to start will not be skipped by event_trigger config.
     * @param override - optional boolean to override the default sampling behavior - ensures the next session recording to start will not be skipped by sampling or linked_flag config. `true` is shorthand for { sampling: true, linked_flag: true }
     */
    PostHog.prototype.startSessionRecording = function (override) {
        var _a, _b, _c, _d, _e;
        var overrideAll = override === true;
        var overrideConfig = {
            sampling: overrideAll || !!(override === null || override === void 0 ? void 0 : override.sampling),
            linked_flag: overrideAll || !!(override === null || override === void 0 ? void 0 : override.linked_flag),
            url_trigger: overrideAll || !!(override === null || override === void 0 ? void 0 : override.url_trigger),
            event_trigger: overrideAll || !!(override === null || override === void 0 ? void 0 : override.event_trigger),
        };
        if (Object.values(overrideConfig).some(Boolean)) {
            // allow the session id check to rotate session id if necessary
            (_a = this.sessionManager) === null || _a === void 0 ? void 0 : _a.checkAndGetSessionAndWindowId();
            if (overrideConfig.sampling) {
                (_b = this.sessionRecording) === null || _b === void 0 ? void 0 : _b.overrideSampling();
            }
            if (overrideConfig.linked_flag) {
                (_c = this.sessionRecording) === null || _c === void 0 ? void 0 : _c.overrideLinkedFlag();
            }
            if (overrideConfig.url_trigger) {
                (_d = this.sessionRecording) === null || _d === void 0 ? void 0 : _d.overrideTrigger('url');
            }
            if (overrideConfig.event_trigger) {
                (_e = this.sessionRecording) === null || _e === void 0 ? void 0 : _e.overrideTrigger('event');
            }
        }
        this.set_config({ disable_session_recording: false });
    };
    /**
     * turns session recording off, and updates the config option
     * disable_session_recording to true
     *
     * {@label Session replay}
     *
     * @public
     *
     * @example
     * ```js
     * // Stop session recording
     * posthog.stopSessionRecording()
     * ```
     */
    PostHog.prototype.stopSessionRecording = function () {
        this.set_config({ disable_session_recording: true });
    };
    /**
     * returns a boolean indicating whether session recording
     * is currently running
     *
     * {@label Session replay}
     *
     * @public
     *
     * @example
     * ```js
     * // Stop session recording if it's running
     * if (posthog.sessionRecordingStarted()) {
     *   posthog.stopSessionRecording()
     * }
     * ```
     */
    PostHog.prototype.sessionRecordingStarted = function () {
        var _a;
        return !!((_a = this.sessionRecording) === null || _a === void 0 ? void 0 : _a.started);
    };
    /**
     * Capture a caught exception manually
     *
     * {@label Error tracking}
     *
     * @public
     *
     * @example
     * ```js
     * // Capture a caught exception
     * try {
     *   // something that might throw
     * } catch (error) {
     *   posthog.captureException(error)
     * }
     * ```
     *
     * @example
     * ```js
     * // With additional properties
     * posthog.captureException(error, {
     *   customProperty: 'value',
     *   anotherProperty: ['I', 'can be a list'],
     *   ...
     * })
     * ```
     *
     * @param {Error} error The error to capture
     * @param {Object} [additionalProperties] Any additional properties to add to the error event
     * @returns {CaptureResult} The result of the capture
     */
    PostHog.prototype.captureException = function (error, additionalProperties) {
        var syntheticException = new Error('PostHog syntheticException');
        return this.exceptions.sendExceptionEvent(__assign(__assign({}, (0, error_conversion_1.errorToProperties)((0, core_1.isError)(error) ? { error: error, event: error.message } : { event: error }, 
        // create synthetic error to get stack in cases where user input does not contain one
        // creating the exceptions soon into our code as possible means we should only have to
        // remove a single frame (this 'captureException' method) from the resultant stack
        { syntheticException: syntheticException })), additionalProperties));
    };
    /**
     * returns a boolean indicating whether the [toolbar](/docs/toolbar) loaded
     *
     * {@label Toolbar}
     *
     * @public
     *
     * @param toolbarParams
     * @returns {boolean} Whether the toolbar loaded
     */
    PostHog.prototype.loadToolbar = function (params) {
        return this.toolbar.loadToolbar(params);
    };
    /**
     * Returns the value of a super property. Returns undefined if the property doesn't exist.
     *
     * {@label Identification}
     *
     * @remarks
     * get_property() can only be called after the PostHog library has finished loading.
     * init() has a loaded function available to handle this automatically.
     *
     * @example
     * ```js
     * // grab value for '$user_id' after the posthog library has loaded
     * posthog.init('<YOUR PROJECT TOKEN>', {
     *     loaded: function(posthog) {
     *         user_id = posthog.get_property('$user_id');
     *     }
     * });
     * ```
     * @public
     *
     * @param {String} property_name The name of the super property you want to retrieve
     */
    PostHog.prototype.get_property = function (property_name) {
        var _a;
        return (_a = this.persistence) === null || _a === void 0 ? void 0 : _a.props[property_name];
    };
    /**
     * Returns the value of the session super property named property_name. If no such
     * property is set, getSessionProperty() will return the undefined value.
     *
     * {@label Identification}
     *
     * @remarks
     * This is based on browser-level `sessionStorage`, NOT the PostHog session.
     * getSessionProperty() can only be called after the PostHog library has finished loading.
     * init() has a loaded function available to handle this automatically.
     *
     * @example
     * ```js
     * // grab value for 'user_id' after the posthog library has loaded
     * posthog.init('YOUR PROJECT TOKEN', {
     *     loaded: function(posthog) {
     *         user_id = posthog.getSessionProperty('user_id');
     *     }
     * });
     * ```
     *
     * @param {String} property_name The name of the session super property you want to retrieve
     */
    PostHog.prototype.getSessionProperty = function (property_name) {
        var _a;
        return (_a = this.sessionPersistence) === null || _a === void 0 ? void 0 : _a.props[property_name];
    };
    /**
     * Returns a string representation of the PostHog instance.
     *
     * {@label Initialization}
     *
     * @internal
     */
    PostHog.prototype.toString = function () {
        var _a;
        var name = (_a = this.config.name) !== null && _a !== void 0 ? _a : PRIMARY_INSTANCE_NAME;
        if (name !== PRIMARY_INSTANCE_NAME) {
            name = PRIMARY_INSTANCE_NAME + '.' + name;
        }
        return name;
    };
    PostHog.prototype._isIdentified = function () {
        var _a, _b;
        return (((_a = this.persistence) === null || _a === void 0 ? void 0 : _a.get_property(constants_1.USER_STATE)) === 'identified' ||
            ((_b = this.sessionPersistence) === null || _b === void 0 ? void 0 : _b.get_property(constants_1.USER_STATE)) === 'identified');
    };
    PostHog.prototype._hasPersonProcessing = function () {
        var _a, _b, _c, _d;
        return !(this.config.person_profiles === 'never' ||
            (this.config.person_profiles === 'identified_only' &&
                !this._isIdentified() &&
                (0, core_1.isEmptyObject)(this.getGroups()) &&
                !((_b = (_a = this.persistence) === null || _a === void 0 ? void 0 : _a.props) === null || _b === void 0 ? void 0 : _b[constants_1.ALIAS_ID_KEY]) &&
                !((_d = (_c = this.persistence) === null || _c === void 0 ? void 0 : _c.props) === null || _d === void 0 ? void 0 : _d[constants_1.ENABLE_PERSON_PROCESSING])));
    };
    PostHog.prototype._shouldCapturePageleave = function () {
        return (this.config.capture_pageleave === true ||
            (this.config.capture_pageleave === 'if_capture_pageview' &&
                (this.config.capture_pageview === true || this.config.capture_pageview === 'history_change')));
    };
    /**
     *  Creates a person profile for the current user, if they don't already have one and config.person_profiles is set
     *  to 'identified_only'. Produces a warning and does not create a profile if config.person_profiles is set to
     *  'never'. Learn more about [person profiles](/docs/product-analytics/identify)
     *
     * {@label Identification}
     *
     * @public
     *
     * @example
     * ```js
     * posthog.createPersonProfile()
     * ```
     */
    PostHog.prototype.createPersonProfile = function () {
        if (this._hasPersonProcessing()) {
            // if a person profile already exists, don't send an event when we don't need to
            return;
        }
        if (!this._requirePersonProcessing('posthog.createPersonProfile')) {
            return;
        }
        // sent a $set event. We don't set any properties here, but attribution props will be added later
        this.setPersonProperties({}, {});
    };
    /**
     * Enables person processing if possible, returns true if it does so or already enabled, false otherwise
     *
     * @param function_name
     */
    PostHog.prototype._requirePersonProcessing = function (function_name) {
        if (this.config.person_profiles === 'never') {
            logger_1.logger.error(function_name + ' was called, but process_person is set to "never". This call will be ignored.');
            return false;
        }
        this._register_single(constants_1.ENABLE_PERSON_PROCESSING, true);
        return true;
    };
    PostHog.prototype._is_persistence_disabled = function () {
        if (this.config.cookieless_mode === 'always') {
            return true;
        }
        var isOptedOut = this.consent.isOptedOut();
        var defaultPersistenceDisabled = this.config.opt_out_persistence_by_default || this.config.cookieless_mode === 'on_reject';
        // TRICKY: We want a deterministic state for persistence so that a new pageload has the same persistence
        return this.config.disable_persistence || (isOptedOut && !!defaultPersistenceDisabled);
    };
    PostHog.prototype._sync_opt_out_with_persistence = function () {
        var _a, _b, _c, _d;
        var persistenceDisabled = this._is_persistence_disabled();
        if (((_a = this.persistence) === null || _a === void 0 ? void 0 : _a._disabled) !== persistenceDisabled) {
            (_b = this.persistence) === null || _b === void 0 ? void 0 : _b.set_disabled(persistenceDisabled);
        }
        if (((_c = this.sessionPersistence) === null || _c === void 0 ? void 0 : _c._disabled) !== persistenceDisabled) {
            (_d = this.sessionPersistence) === null || _d === void 0 ? void 0 : _d.set_disabled(persistenceDisabled);
        }
        return persistenceDisabled;
    };
    /**
     * Opts the user into data capturing and persistence.
     *
     * {@label Privacy}
     *
     * @remarks
     * Enables event tracking and data persistence (cookies/localStorage) for this PostHog instance.
     * By default, captures an `$opt_in` event unless disabled.
     *
     * @example
     * ```js
     * // simple opt-in
     * posthog.opt_in_capturing()
     * ```
     *
     * @example
     * ```js
     * // opt-in with custom event and properties
     * posthog.opt_in_capturing({
     *     captureEventName: 'Privacy Accepted',
     *     captureProperties: { source: 'banner' }
     * })
     * ```
     *
     * @example
     * ```js
     * // opt-in without capturing event
     * posthog.opt_in_capturing({
     *     captureEventName: false
     * })
     * ```
     *
     * @public
     *
     * @param {Object} [config] A dictionary of config options to override
     * @param {string} [config.capture_event_name=$opt_in] Event name to be used for capturing the opt-in action. Set to `null` or `false` to skip capturing the optin event
     * @param {Object} [config.capture_properties] Set of properties to be captured along with the opt-in action
     */
    PostHog.prototype.opt_in_capturing = function (options) {
        var _a;
        if (this.config.cookieless_mode === 'always') {
            logger_1.logger.warn('Consent opt in/out is not valid with cookieless_mode="always" and will be ignored');
            return;
        }
        if (this.config.cookieless_mode === 'on_reject' && this.consent.isExplicitlyOptedOut()) {
            // If the user has explicitly opted out on_reject mode, then before we can start sending regular non-cookieless events
            // we need to reset the instance to ensure that there is no leaking of state or data between the cookieless and regular events
            this.reset(true);
            this.sessionManager = new sessionid_1.SessionIdManager(this);
            if (this.persistence) {
                this.sessionPropsManager = new session_props_1.SessionPropsManager(this, this.sessionManager, this.persistence);
            }
            this.sessionRecording = new sessionrecording_1.SessionRecording(this);
            this.sessionRecording.startIfEnabledOrStop();
        }
        this.consent.optInOut(true);
        this._sync_opt_out_with_persistence();
        // Don't capture if captureEventName is null or false
        if ((0, core_1.isUndefined)(options === null || options === void 0 ? void 0 : options.captureEventName) || (options === null || options === void 0 ? void 0 : options.captureEventName)) {
            this.capture((_a = options === null || options === void 0 ? void 0 : options.captureEventName) !== null && _a !== void 0 ? _a : '$opt_in', options === null || options === void 0 ? void 0 : options.captureProperties, { send_instantly: true });
        }
        if (this.config.capture_pageview) {
            this._captureInitialPageview();
        }
    };
    /**
     * Opts the user out of data capturing and persistence.
     *
     * {@label Privacy}
     *
     * @remarks
     * Disables event tracking and data persistence (cookies/localStorage) for this PostHog instance.
     * If `opt_out_persistence_by_default` is true, SDK persistence will also be disabled.
     *
     * @example
     * ```js
     * // opt user out (e.g., on privacy settings page)
     * posthog.opt_out_capturing()
     * ```
     *
     * @public
     */
    PostHog.prototype.opt_out_capturing = function () {
        var _a;
        if (this.config.cookieless_mode === 'always') {
            logger_1.logger.warn('Consent opt in/out is not valid with cookieless_mode="always" and will be ignored');
            return;
        }
        if (this.config.cookieless_mode === 'on_reject' && this.consent.isOptedIn()) {
            // If the user has opted in, we need to reset the instance to ensure that there is no leaking of state or data between the cookieless and regular events
            this.reset(true);
        }
        this.consent.optInOut(false);
        this._sync_opt_out_with_persistence();
        if (this.config.cookieless_mode === 'on_reject') {
            // If cookieless_mode is 'on_reject', we start capturing events in cookieless mode
            this.register({
                distinct_id: constants_1.COOKIELESS_SENTINEL_VALUE,
                $device_id: null,
            });
            this.sessionManager = undefined;
            this.sessionPropsManager = undefined;
            (_a = this.sessionRecording) === null || _a === void 0 ? void 0 : _a.stopRecording();
            this.sessionRecording = undefined;
            this._captureInitialPageview();
        }
    };
    /**
     * Checks if the user has opted into data capturing.
     *
     * {@label Privacy}
     *
     * @remarks
     * Returns the current consent status for event tracking and data persistence.
     *
     * @example
     * ```js
     * if (posthog.has_opted_in_capturing()) {
     *     // show analytics features
     * }
     * ```
     *
     * @public
     *
     * @returns {boolean} current opt-in status
     */
    PostHog.prototype.has_opted_in_capturing = function () {
        return this.consent.isOptedIn();
    };
    /**
     * Checks if the user has opted out of data capturing.
     *
     * {@label Privacy}
     *
     * @remarks
     * Returns the current consent status for event tracking and data persistence.
     *
     * @example
     * ```js
     * if (posthog.has_opted_out_capturing()) {
     *     // disable analytics features
     * }
     * ```
     *
     * @public
     *
     * @returns {boolean} current opt-out status
     */
    PostHog.prototype.has_opted_out_capturing = function () {
        return this.consent.isOptedOut();
    };
    /**
     * Checks whether the PostHog library is currently capturing events.
     *
     * Usually this means that the user has not opted out of capturing, but the exact behaviour can be controlled by
     * some config options.
     *
     * Additionally, if the cookieless_mode is set to 'on_reject', we will capture events in cookieless mode if the
     * user has explicitly opted out.
     *
     * {@label Privacy}
     *
     * @see {PostHogConfig.cookieless_mode}
     * @see {PostHogConfig.opt_out_persistence_by_default}
     * @see {PostHogConfig.respect_dnt}
     *
     * @returns {boolean} whether the posthog library is capturing events
     */
    PostHog.prototype.is_capturing = function () {
        if (this.config.cookieless_mode === 'always') {
            return true;
        }
        if (this.config.cookieless_mode === 'on_reject') {
            return this.consent.isExplicitlyOptedOut() || this.consent.isOptedIn();
        }
        else {
            return !this.has_opted_out_capturing();
        }
    };
    /**
     * Clear the user's opt in/out status of data capturing and cookies/localstorage for this PostHog instance
     *
     * {@label Privacy}
     *
     * @public
     *
     */
    PostHog.prototype.clear_opt_in_out_capturing = function () {
        this.consent.reset();
        this._sync_opt_out_with_persistence();
    };
    PostHog.prototype._is_bot = function () {
        if (globals_1.navigator) {
            return (0, blocked_uas_1.isLikelyBot)(globals_1.navigator, this.config.custom_blocked_useragents);
        }
        else {
            return undefined;
        }
    };
    PostHog.prototype._captureInitialPageview = function () {
        if (!globals_1.document) {
            return;
        }
        // If page is not visible, add a listener to detect when the page becomes visible
        // and trigger the pageview only then
        // This is useful to avoid `prerender` calls from Chrome/Wordpress/SPAs
        // that are not visible to the user
        if (globals_1.document.visibilityState !== 'visible') {
            if (!this._visibilityStateListener) {
                this._visibilityStateListener = this._captureInitialPageview.bind(this);
                (0, utils_1.addEventListener)(globals_1.document, 'visibilitychange', this._visibilityStateListener);
            }
            return;
        }
        // Extra check here to guarantee we only ever trigger a single `$pageview` event
        if (!this._initialPageviewCaptured) {
            this._initialPageviewCaptured = true;
            this.capture('$pageview', { title: globals_1.document.title }, { send_instantly: true });
            // After we've captured the initial pageview, we can remove the listener
            if (this._visibilityStateListener) {
                globals_1.document.removeEventListener('visibilitychange', this._visibilityStateListener);
                this._visibilityStateListener = null;
            }
        }
    };
    /**
     * Enables or disables debug mode for detailed logging.
     *
     * @remarks
     * Debug mode logs all PostHog calls to the browser console for troubleshooting.
     * Can also be enabled by adding `?__posthog_debug=true` to the URL.
     *
     * {@label Initialization}
     *
     * @example
     * ```js
     * // enable debug mode
     * posthog.debug(true)
     * ```
     *
     * @example
     * ```js
     * // disable debug mode
     * posthog.debug(false)
     * ```
     *
     * @public
     *
     * @param {boolean} [debug] If true, will enable debug mode.
     */
    PostHog.prototype.debug = function (debug) {
        if (debug === false) {
            globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.console.log("You've disabled debug mode.");
            localStorage && localStorage.removeItem('ph_debug');
            this.set_config({ debug: false });
        }
        else {
            globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.console.log("You're now in debug mode. All calls to PostHog will be logged in your console.\nYou can disable this with `posthog.debug(false)`.");
            localStorage && localStorage.setItem('ph_debug', 'true');
            this.set_config({ debug: true });
        }
    };
    /**
     * Helper method to check if external API calls (flags/decide) should be disabled
     * Handles migration from old `advanced_disable_decide` to new `advanced_disable_flags`
     */
    PostHog.prototype._shouldDisableFlags = function () {
        // Check if advanced_disable_flags was explicitly set in original config
        var originalConfig = this._originalUserConfig || {};
        if ('advanced_disable_flags' in originalConfig) {
            return !!originalConfig.advanced_disable_flags;
        }
        // Check if advanced_disable_flags was set post-init (different from default false)
        if (this.config.advanced_disable_flags !== false) {
            return !!this.config.advanced_disable_flags;
        }
        // Check for post-init changes to advanced_disable_decide
        if (this.config.advanced_disable_decide === true) {
            logger_1.logger.warn("Config field 'advanced_disable_decide' is deprecated. Please use 'advanced_disable_flags' instead. " +
                'The old field will be removed in a future major version.');
            return true;
        }
        // Fall back to migration logic for original user config
        return (0, utils_1.migrateConfigField)(originalConfig, 'advanced_disable_flags', 'advanced_disable_decide', false, logger_1.logger);
    };
    PostHog.prototype._runBeforeSend = function (data) {
        var e_1, _a;
        if ((0, core_1.isNullish)(this.config.before_send)) {
            return data;
        }
        var fns = (0, core_1.isArray)(this.config.before_send) ? this.config.before_send : [this.config.before_send];
        var beforeSendResult = data;
        try {
            for (var fns_1 = __values(fns), fns_1_1 = fns_1.next(); !fns_1_1.done; fns_1_1 = fns_1.next()) {
                var fn = fns_1_1.value;
                beforeSendResult = fn(beforeSendResult);
                if ((0, core_1.isNullish)(beforeSendResult)) {
                    var logMessage = "Event '".concat(data.event, "' was rejected in beforeSend function");
                    if ((0, core_1.isKnownUnsafeEditableEvent)(data.event)) {
                        logger_1.logger.warn("".concat(logMessage, ". This can cause unexpected behavior."));
                    }
                    else {
                        logger_1.logger.info(logMessage);
                    }
                    return null;
                }
                if (!beforeSendResult.properties || (0, core_1.isEmptyObject)(beforeSendResult.properties)) {
                    logger_1.logger.warn("Event '".concat(data.event, "' has no properties after beforeSend function, this is likely an error."));
                }
            }
        }
        catch (e_1_1) { e_1 = { error: e_1_1 }; }
        finally {
            try {
                if (fns_1_1 && !fns_1_1.done && (_a = fns_1.return)) _a.call(fns_1);
            }
            finally { if (e_1) throw e_1.error; }
        }
        return beforeSendResult;
    };
    /**
     * Returns the current page view ID.
     *
     * {@label Initialization}
     *
     * @public
     *
     * @returns {string} The current page view ID
     */
    PostHog.prototype.getPageViewId = function () {
        var _a;
        return (_a = this.pageViewManager._currentPageview) === null || _a === void 0 ? void 0 : _a.pageViewId;
    };
    /**
     * Capture written user feedback for a LLM trace. Numeric values are converted to strings.
     *
     * {@label LLM analytics}
     *
     * @public
     *
     * @param traceId The trace ID to capture feedback for.
     * @param userFeedback The feedback to capture.
     */
    PostHog.prototype.captureTraceFeedback = function (traceId, userFeedback) {
        this.capture('$ai_feedback', {
            $ai_trace_id: String(traceId),
            $ai_feedback_text: userFeedback,
        });
    };
    /**
     * Capture a metric for a LLM trace. Numeric values are converted to strings.
     *
     * {@label LLM analytics}
     *
     * @public
     *
     * @param traceId The trace ID to capture the metric for.
     * @param metricName The name of the metric to capture.
     * @param metricValue The value of the metric to capture.
     */
    PostHog.prototype.captureTraceMetric = function (traceId, metricName, metricValue) {
        this.capture('$ai_metric', {
            $ai_trace_id: String(traceId),
            $ai_metric_name: metricName,
            $ai_metric_value: String(metricValue),
        });
    };
    return PostHog;
}());
exports.PostHog = PostHog;
(0, utils_1.safewrapClass)(PostHog, ['identify']);
var add_dom_loaded_handler = function () {
    // Cross browser DOM Loaded support
    function dom_loaded_handler() {
        // function flag since we only want to execute this once
        if (dom_loaded_handler.done) {
            return;
        }
        ;
        dom_loaded_handler.done = true;
        ENQUEUE_REQUESTS = false;
        (0, utils_1.each)(instances, function (inst) {
            inst._dom_loaded();
        });
    }
    if (globals_1.document === null || globals_1.document === void 0 ? void 0 : globals_1.document.addEventListener) {
        if (globals_1.document.readyState === 'complete') {
            // safari 4 can fire the DOMContentLoaded event before loading all
            // external JS (including this file). you will see some copypasta
            // on the internet that checks for 'complete' and 'loaded', but
            // 'loaded' is an IE thing
            dom_loaded_handler();
        }
        else {
            (0, utils_1.addEventListener)(globals_1.document, 'DOMContentLoaded', dom_loaded_handler, { capture: false });
        }
        return;
    }
    // Only IE6-8 don't support `document.addEventListener` and we don't support them
    // so let's simply log an error stating PostHog couldn't be initialized
    // We're checking for `window` to avoid erroring out on a SSR context
    if (globals_1.window) {
        logger_1.logger.error("Browser doesn't support `document.addEventListener` so PostHog couldn't be initialized");
    }
};
function init_from_snippet() {
    var posthogMain = (instances[PRIMARY_INSTANCE_NAME] = new PostHog());
    var snippetPostHog = globals_1.assignableWindow['posthog'];
    if (snippetPostHog) {
        /**
         * The snippet uses some clever tricks to allow deferred loading of array.js (this code)
         *
         * window.posthog is an array which the queue of calls made before the lib is loaded
         * It has methods attached to it to simulate the posthog object so for instance
         *
         * window.posthog.init("TOKEN", {api_host: "foo" })
         * window.posthog.capture("my-event", {foo: "bar" })
         *
         * ... will mean that window.posthog will look like this:
         * window.posthog == [
         *  ["my-event", {foo: "bar"}]
         * ]
         *
         * window.posthog[_i] == [
         *   ["TOKEN", {api_host: "foo" }, "posthog"]
         * ]
         *
         * If a name is given to the init function then the same as above is true but as a sub-property on the object:
         *
         * window.posthog.init("TOKEN", {}, "ph2")
         * window.posthog.ph2.people.set({foo: "bar"})
         *
         * window.posthog.ph2 == []
         * window.posthog.people == [
         *  ["set", {foo: "bar"}]
         * ]
         *
         */
        // Call all pre-loaded init calls properly
        (0, utils_1.each)(snippetPostHog['_i'], function (item) {
            if (item && (0, core_1.isArray)(item)) {
                var instance = posthogMain.init(item[0], item[1], item[2]);
                var instanceSnippet = snippetPostHog[item[2]] || snippetPostHog;
                if (instance) {
                    // Crunch through the people queue first - we queue this data up &
                    // flush on identify, so it's better to do all these operations first
                    instance._execute_array.call(instance.people, instanceSnippet.people);
                    instance._execute_array(instanceSnippet);
                }
            }
        });
    }
    globals_1.assignableWindow['posthog'] = posthogMain;
    add_dom_loaded_handler();
}
function init_as_module() {
    var posthogMain = (instances[PRIMARY_INSTANCE_NAME] = new PostHog());
    add_dom_loaded_handler();
    return posthogMain;
}
//# sourceMappingURL=posthog-core.js.map