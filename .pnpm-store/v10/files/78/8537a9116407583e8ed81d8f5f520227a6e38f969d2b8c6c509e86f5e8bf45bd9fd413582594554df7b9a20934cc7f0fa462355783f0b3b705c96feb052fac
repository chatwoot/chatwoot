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
var __spreadArray = (this && this.__spreadArray) || function (to, from, pack) {
    if (pack || arguments.length === 2) for (var i = 0, l = from.length, ar; i < l; i++) {
        if (ar || !(i in from)) {
            if (!ar) ar = Array.prototype.slice.call(from, 0, i);
            ar[i] = from[i];
        }
    }
    return to.concat(ar || Array.prototype.slice.call(from));
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PostHogFeatureFlags = exports.QuotaLimitedResource = exports.parseFlagsResponse = exports.filterActiveFeatureFlags = void 0;
var utils_1 = require("./utils");
var types_1 = require("./types");
var constants_1 = require("./constants");
var core_1 = require("@posthog/core");
var logger_1 = require("./utils/logger");
var event_utils_1 = require("./utils/event-utils");
var logger = (0, logger_1.createLogger)('[FeatureFlags]');
var PERSISTENCE_ACTIVE_FEATURE_FLAGS = '$active_feature_flags';
var PERSISTENCE_OVERRIDE_FEATURE_FLAGS = '$override_feature_flags';
var PERSISTENCE_FEATURE_FLAG_PAYLOADS = '$feature_flag_payloads';
var PERSISTENCE_OVERRIDE_FEATURE_FLAG_PAYLOADS = '$override_feature_flag_payloads';
var PERSISTENCE_FEATURE_FLAG_REQUEST_ID = '$feature_flag_request_id';
var filterActiveFeatureFlags = function (featureFlags) {
    var e_1, _a;
    var activeFeatureFlags = {};
    try {
        for (var _b = __values((0, utils_1.entries)(featureFlags || {})), _c = _b.next(); !_c.done; _c = _b.next()) {
            var _d = __read(_c.value, 2), key = _d[0], value = _d[1];
            if (value) {
                activeFeatureFlags[key] = value;
            }
        }
    }
    catch (e_1_1) { e_1 = { error: e_1_1 }; }
    finally {
        try {
            if (_c && !_c.done && (_a = _b.return)) _a.call(_b);
        }
        finally { if (e_1) throw e_1.error; }
    }
    return activeFeatureFlags;
};
exports.filterActiveFeatureFlags = filterActiveFeatureFlags;
var parseFlagsResponse = function (response, persistence, currentFlags, currentFlagPayloads, currentFlagDetails) {
    var _a, _b, _c;
    if (currentFlags === void 0) { currentFlags = {}; }
    if (currentFlagPayloads === void 0) { currentFlagPayloads = {}; }
    if (currentFlagDetails === void 0) { currentFlagDetails = {}; }
    var normalizedResponse = normalizeFlagsResponse(response);
    var flagDetails = normalizedResponse.flags;
    var featureFlags = normalizedResponse.featureFlags;
    var flagPayloads = normalizedResponse.featureFlagPayloads;
    if (!featureFlags) {
        return; // <-- This early return means we don't update anything, which is good.
    }
    var requestId = response['requestId'];
    // using the v1 api
    if ((0, core_1.isArray)(featureFlags)) {
        logger.warn('v1 of the feature flags endpoint is deprecated. Please use the latest version.');
        var $enabled_feature_flags = {};
        if (featureFlags) {
            for (var i = 0; i < featureFlags.length; i++) {
                $enabled_feature_flags[featureFlags[i]] = true;
            }
        }
        persistence &&
            persistence.register((_a = {},
                _a[PERSISTENCE_ACTIVE_FEATURE_FLAGS] = featureFlags,
                _a[constants_1.ENABLED_FEATURE_FLAGS] = $enabled_feature_flags,
                _a));
        return;
    }
    // using the v2+ api
    var newFeatureFlags = featureFlags;
    var newFeatureFlagPayloads = flagPayloads;
    var newFeatureFlagDetails = flagDetails;
    if (response.errorsWhileComputingFlags) {
        // if not all flags were computed, we upsert flags instead of replacing them
        newFeatureFlags = __assign(__assign({}, currentFlags), newFeatureFlags);
        newFeatureFlagPayloads = __assign(__assign({}, currentFlagPayloads), newFeatureFlagPayloads);
        newFeatureFlagDetails = __assign(__assign({}, currentFlagDetails), newFeatureFlagDetails);
    }
    persistence &&
        persistence.register(__assign((_b = {}, _b[PERSISTENCE_ACTIVE_FEATURE_FLAGS] = Object.keys((0, exports.filterActiveFeatureFlags)(newFeatureFlags)), _b[constants_1.ENABLED_FEATURE_FLAGS] = newFeatureFlags || {}, _b[PERSISTENCE_FEATURE_FLAG_PAYLOADS] = newFeatureFlagPayloads || {}, _b[constants_1.PERSISTENCE_FEATURE_FLAG_DETAILS] = newFeatureFlagDetails || {}, _b), (requestId ? (_c = {}, _c[PERSISTENCE_FEATURE_FLAG_REQUEST_ID] = requestId, _c) : {})));
};
exports.parseFlagsResponse = parseFlagsResponse;
var normalizeFlagsResponse = function (response) {
    var flagDetails = response['flags'];
    if (flagDetails) {
        // This is a v=4 request.
        // Map of flag keys to flag values: Record<string, string | boolean>
        response.featureFlags = Object.fromEntries(Object.keys(flagDetails).map(function (flag) { var _a; return [flag, (_a = flagDetails[flag].variant) !== null && _a !== void 0 ? _a : flagDetails[flag].enabled]; }));
        // Map of flag keys to flag payloads: Record<string, JsonType>
        response.featureFlagPayloads = Object.fromEntries(Object.keys(flagDetails)
            .filter(function (flag) { return flagDetails[flag].enabled; })
            .filter(function (flag) { var _a; return (_a = flagDetails[flag].metadata) === null || _a === void 0 ? void 0 : _a.payload; })
            .map(function (flag) { var _a; return [flag, (_a = flagDetails[flag].metadata) === null || _a === void 0 ? void 0 : _a.payload]; }));
    }
    else {
        logger.warn('Using an older version of the feature flags endpoint. Please upgrade your PostHog server to the latest version');
    }
    return response;
};
var QuotaLimitedResource;
(function (QuotaLimitedResource) {
    QuotaLimitedResource["FeatureFlags"] = "feature_flags";
    QuotaLimitedResource["Recordings"] = "recordings";
})(QuotaLimitedResource || (exports.QuotaLimitedResource = QuotaLimitedResource = {}));
var PostHogFeatureFlags = /** @class */ (function () {
    function PostHogFeatureFlags(_instance) {
        this._instance = _instance;
        this._override_warning = false;
        this._hasLoadedFlags = false;
        this._requestInFlight = false;
        this._reloadingDisabled = false;
        this._additionalReloadRequested = false;
        this._flagsCalled = false;
        this._flagsLoadedFromRemote = false;
        this.featureFlagEventHandlers = [];
    }
    PostHogFeatureFlags.prototype.flags = function () {
        if (this._instance.config.__preview_remote_config) {
            // If remote config is enabled we don't call /flags and we mark it as called so that we don't simulate it
            this._flagsCalled = true;
            return;
        }
        // TRICKY: We want to disable flags if we don't have a queued reload, and one of the settings exist for disabling on first load
        var disableFlags = !this._reloadDebouncer &&
            (this._instance.config.advanced_disable_feature_flags ||
                this._instance.config.advanced_disable_feature_flags_on_first_load);
        this._callFlagsEndpoint({
            disableFlags: disableFlags,
        });
    };
    Object.defineProperty(PostHogFeatureFlags.prototype, "hasLoadedFlags", {
        get: function () {
            return this._hasLoadedFlags;
        },
        enumerable: false,
        configurable: true
    });
    PostHogFeatureFlags.prototype.getFlags = function () {
        return Object.keys(this.getFlagVariants());
    };
    PostHogFeatureFlags.prototype.getFlagsWithDetails = function () {
        var e_2, _a;
        var _b, _c;
        var flagDetails = this._instance.get_property(constants_1.PERSISTENCE_FEATURE_FLAG_DETAILS);
        var overridenFlags = this._instance.get_property(PERSISTENCE_OVERRIDE_FEATURE_FLAGS);
        var overriddenPayloads = this._instance.get_property(PERSISTENCE_OVERRIDE_FEATURE_FLAG_PAYLOADS);
        if (!overriddenPayloads && !overridenFlags) {
            return flagDetails || {};
        }
        var finalDetails = (0, utils_1.extend)({}, flagDetails || {});
        var overriddenKeys = __spreadArray([], __read(new Set(__spreadArray(__spreadArray([], __read(Object.keys(overriddenPayloads || {})), false), __read(Object.keys(overridenFlags || {})), false))), false);
        try {
            for (var overriddenKeys_1 = __values(overriddenKeys), overriddenKeys_1_1 = overriddenKeys_1.next(); !overriddenKeys_1_1.done; overriddenKeys_1_1 = overriddenKeys_1.next()) {
                var key = overriddenKeys_1_1.value;
                var originalDetail = finalDetails[key];
                var overrideFlagValue = overridenFlags === null || overridenFlags === void 0 ? void 0 : overridenFlags[key];
                var finalEnabled = (0, core_1.isUndefined)(overrideFlagValue)
                    ? ((_b = originalDetail === null || originalDetail === void 0 ? void 0 : originalDetail.enabled) !== null && _b !== void 0 ? _b : false)
                    : !!overrideFlagValue;
                var overrideVariant = (0, core_1.isUndefined)(overrideFlagValue)
                    ? originalDetail.variant
                    : typeof overrideFlagValue === 'string'
                        ? overrideFlagValue
                        : undefined;
                var overridePayload = overriddenPayloads === null || overriddenPayloads === void 0 ? void 0 : overriddenPayloads[key];
                var overridenDetail = __assign(__assign({}, originalDetail), { enabled: finalEnabled, 
                    // If the flag is not enabled, the variant should be undefined, even if the original has a variant value.
                    variant: finalEnabled ? (overrideVariant !== null && overrideVariant !== void 0 ? overrideVariant : originalDetail === null || originalDetail === void 0 ? void 0 : originalDetail.variant) : undefined });
                // Keep track of the original enabled and variant values so we can send them in the $feature_flag_called event.
                // This will be helpful for debugging and for understanding the impact of overrides.
                if (finalEnabled !== (originalDetail === null || originalDetail === void 0 ? void 0 : originalDetail.enabled)) {
                    overridenDetail.original_enabled = originalDetail === null || originalDetail === void 0 ? void 0 : originalDetail.enabled;
                }
                if (overrideVariant !== (originalDetail === null || originalDetail === void 0 ? void 0 : originalDetail.variant)) {
                    overridenDetail.original_variant = originalDetail === null || originalDetail === void 0 ? void 0 : originalDetail.variant;
                }
                if (overridePayload) {
                    overridenDetail.metadata = __assign(__assign({}, originalDetail === null || originalDetail === void 0 ? void 0 : originalDetail.metadata), { payload: overridePayload, original_payload: (_c = originalDetail === null || originalDetail === void 0 ? void 0 : originalDetail.metadata) === null || _c === void 0 ? void 0 : _c.payload });
                }
                finalDetails[key] = overridenDetail;
            }
        }
        catch (e_2_1) { e_2 = { error: e_2_1 }; }
        finally {
            try {
                if (overriddenKeys_1_1 && !overriddenKeys_1_1.done && (_a = overriddenKeys_1.return)) _a.call(overriddenKeys_1);
            }
            finally { if (e_2) throw e_2.error; }
        }
        if (!this._override_warning) {
            logger.warn(' Overriding feature flag details!', {
                flagDetails: flagDetails,
                overriddenPayloads: overriddenPayloads,
                finalDetails: finalDetails,
            });
            this._override_warning = true;
        }
        return finalDetails;
    };
    PostHogFeatureFlags.prototype.getFlagVariants = function () {
        var enabledFlags = this._instance.get_property(constants_1.ENABLED_FEATURE_FLAGS);
        var overriddenFlags = this._instance.get_property(PERSISTENCE_OVERRIDE_FEATURE_FLAGS);
        if (!overriddenFlags) {
            return enabledFlags || {};
        }
        var finalFlags = (0, utils_1.extend)({}, enabledFlags);
        var overriddenKeys = Object.keys(overriddenFlags);
        for (var i = 0; i < overriddenKeys.length; i++) {
            finalFlags[overriddenKeys[i]] = overriddenFlags[overriddenKeys[i]];
        }
        if (!this._override_warning) {
            logger.warn(' Overriding feature flags!', {
                enabledFlags: enabledFlags,
                overriddenFlags: overriddenFlags,
                finalFlags: finalFlags,
            });
            this._override_warning = true;
        }
        return finalFlags;
    };
    PostHogFeatureFlags.prototype.getFlagPayloads = function () {
        var flagPayloads = this._instance.get_property(PERSISTENCE_FEATURE_FLAG_PAYLOADS);
        var overriddenPayloads = this._instance.get_property(PERSISTENCE_OVERRIDE_FEATURE_FLAG_PAYLOADS);
        if (!overriddenPayloads) {
            return flagPayloads || {};
        }
        var finalPayloads = (0, utils_1.extend)({}, flagPayloads || {});
        var overriddenKeys = Object.keys(overriddenPayloads);
        for (var i = 0; i < overriddenKeys.length; i++) {
            finalPayloads[overriddenKeys[i]] = overriddenPayloads[overriddenKeys[i]];
        }
        if (!this._override_warning) {
            logger.warn(' Overriding feature flag payloads!', {
                flagPayloads: flagPayloads,
                overriddenPayloads: overriddenPayloads,
                finalPayloads: finalPayloads,
            });
            this._override_warning = true;
        }
        return finalPayloads;
    };
    /**
     * Reloads feature flags asynchronously.
     *
     * Constraints:
     *
     * 1. Avoid parallel requests
     * 2. Delay a few milliseconds after each reloadFeatureFlags call to batch subsequent changes together
     */
    PostHogFeatureFlags.prototype.reloadFeatureFlags = function () {
        var _this = this;
        if (this._reloadingDisabled || this._instance.config.advanced_disable_feature_flags) {
            // If reloading has been explicitly disabled then we don't want to do anything
            // Or if feature flags are disabled
            return;
        }
        if (this._reloadDebouncer) {
            // If we're already in a debounce then we don't want to do anything
            return;
        }
        // Debounce multiple calls on the same tick
        this._reloadDebouncer = setTimeout(function () {
            _this._callFlagsEndpoint();
        }, 5);
    };
    PostHogFeatureFlags.prototype._clearDebouncer = function () {
        clearTimeout(this._reloadDebouncer);
        this._reloadDebouncer = undefined;
    };
    PostHogFeatureFlags.prototype.ensureFlagsLoaded = function () {
        if (this._hasLoadedFlags || this._requestInFlight || this._reloadDebouncer) {
            // If we are or have already loaded the flags then we don't want to do anything
            return;
        }
        this.reloadFeatureFlags();
    };
    PostHogFeatureFlags.prototype.setAnonymousDistinctId = function (anon_distinct_id) {
        this.$anon_distinct_id = anon_distinct_id;
    };
    PostHogFeatureFlags.prototype.setReloadingPaused = function (isPaused) {
        this._reloadingDisabled = isPaused;
    };
    /**
     * NOTE: This is used both for flags and remote config. Once the RemoteConfig is fully released this will essentially only
     * be for flags and can eventually be replaced with the new flags endpoint
     */
    PostHogFeatureFlags.prototype._callFlagsEndpoint = function (options) {
        var _this = this;
        var _a;
        // Ensure we don't have double queued /flags requests
        this._clearDebouncer();
        if (this._instance._shouldDisableFlags()) {
            // The way this is documented is essentially used to refuse to ever call the /flags endpoint.
            return;
        }
        if (this._requestInFlight) {
            this._additionalReloadRequested = true;
            return;
        }
        var token = this._instance.config.token;
        var data = {
            token: token,
            distinct_id: this._instance.get_distinct_id(),
            groups: this._instance.getGroups(),
            $anon_distinct_id: this.$anon_distinct_id,
            person_properties: __assign(__assign({}, (((_a = this._instance.persistence) === null || _a === void 0 ? void 0 : _a.get_initial_props()) || {})), (this._instance.get_property(constants_1.STORED_PERSON_PROPERTIES_KEY) || {})),
            group_properties: this._instance.get_property(constants_1.STORED_GROUP_PROPERTIES_KEY),
        };
        if ((options === null || options === void 0 ? void 0 : options.disableFlags) || this._instance.config.advanced_disable_feature_flags) {
            data.disable_flags = true;
        }
        // flags supports loading config data with the `config` query param, but if you're using remote config, you
        // don't need to add that parameter because all the config data is loaded from the remote config endpoint.
        var useRemoteConfigWithFlags = this._instance.config.__preview_remote_config;
        var flagsRoute = useRemoteConfigWithFlags ? '/flags/?v=2' : '/flags/?v=2&config=true';
        var queryParams = this._instance.config.advanced_only_evaluate_survey_feature_flags
            ? '&only_evaluate_survey_feature_flags=true'
            : '';
        var url = this._instance.requestRouter.endpointFor('api', flagsRoute + queryParams);
        if (useRemoteConfigWithFlags) {
            data.timezone = (0, event_utils_1.getTimezone)();
        }
        this._requestInFlight = true;
        this._instance._send_request({
            method: 'POST',
            url: url,
            data: data,
            compression: this._instance.config.disable_compression ? undefined : types_1.Compression.Base64,
            timeout: this._instance.config.feature_flag_request_timeout_ms,
            callback: function (response) {
                var _a, _b, _c;
                var errorsLoading = true;
                if (response.statusCode === 200) {
                    // successful request
                    // reset anon_distinct_id after at least a single request with it
                    // makes it through
                    if (!_this._additionalReloadRequested) {
                        _this.$anon_distinct_id = undefined;
                    }
                    errorsLoading = false;
                }
                _this._requestInFlight = false;
                // NB: this block is only reached if this._instance.config.__preview_remote_config is false
                if (!_this._flagsCalled) {
                    _this._flagsCalled = true;
                    _this._instance._onRemoteConfig((_a = response.json) !== null && _a !== void 0 ? _a : {});
                }
                if (data.disable_flags && !_this._additionalReloadRequested) {
                    // If flags are disabled then there is no need to call /flags again (flags are the only thing that may change)
                    // UNLESS, an additional reload is requested.
                    return;
                }
                _this._flagsLoadedFromRemote = !errorsLoading;
                if (response.json && ((_b = response.json.quotaLimited) === null || _b === void 0 ? void 0 : _b.includes(QuotaLimitedResource.FeatureFlags))) {
                    // log a warning and then early return
                    logger.warn('You have hit your feature flags quota limit, and will not be able to load feature flags until the quota is reset.  Please visit https://posthog.com/docs/billing/limits-alerts to learn more.');
                    return;
                }
                if (!data.disable_flags) {
                    _this.receivedFeatureFlags((_c = response.json) !== null && _c !== void 0 ? _c : {}, errorsLoading);
                }
                if (_this._additionalReloadRequested) {
                    _this._additionalReloadRequested = false;
                    _this._callFlagsEndpoint();
                }
            },
        });
    };
    /*
     * Get feature flag's value for user.
     *
     * ### Usage:
     *
     *     if(posthog.getFeatureFlag('my-flag') === 'some-variant') { // do something }
     *
     * @param {Object|String} key Key of the feature flag.
     * @param {Object|String} options (optional) If {send_event: false}, we won't send an $feature_flag_called event to PostHog.
     */
    PostHogFeatureFlags.prototype.getFeatureFlag = function (key, options) {
        var _a;
        var _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o;
        if (options === void 0) { options = {}; }
        if (!this._hasLoadedFlags && !(this.getFlags() && this.getFlags().length > 0)) {
            logger.warn('getFeatureFlag for key "' + key + '" failed. Feature flags didn\'t load in time.');
            return undefined;
        }
        var flagValue = this.getFlagVariants()[key];
        var flagReportValue = "".concat(flagValue);
        var requestId = this._instance.get_property(PERSISTENCE_FEATURE_FLAG_REQUEST_ID) || undefined;
        var flagCallReported = this._instance.get_property(constants_1.FLAG_CALL_REPORTED) || {};
        if (options.send_event || !('send_event' in options)) {
            if (!(key in flagCallReported) || !flagCallReported[key].includes(flagReportValue)) {
                if ((0, core_1.isArray)(flagCallReported[key])) {
                    flagCallReported[key].push(flagReportValue);
                }
                else {
                    flagCallReported[key] = [flagReportValue];
                }
                (_b = this._instance.persistence) === null || _b === void 0 ? void 0 : _b.register((_a = {}, _a[constants_1.FLAG_CALL_REPORTED] = flagCallReported, _a));
                var flagDetails = this.getFeatureFlagDetails(key);
                var properties = {
                    $feature_flag: key,
                    $feature_flag_response: flagValue,
                    $feature_flag_payload: this.getFeatureFlagPayload(key) || null,
                    $feature_flag_request_id: requestId,
                    $feature_flag_bootstrapped_response: ((_d = (_c = this._instance.config.bootstrap) === null || _c === void 0 ? void 0 : _c.featureFlags) === null || _d === void 0 ? void 0 : _d[key]) || null,
                    $feature_flag_bootstrapped_payload: ((_f = (_e = this._instance.config.bootstrap) === null || _e === void 0 ? void 0 : _e.featureFlagPayloads) === null || _f === void 0 ? void 0 : _f[key]) || null,
                    // If we haven't yet received a response from the /flags endpoint, we must have used the bootstrapped value
                    $used_bootstrap_value: !this._flagsLoadedFromRemote,
                };
                if (!(0, core_1.isUndefined)((_g = flagDetails === null || flagDetails === void 0 ? void 0 : flagDetails.metadata) === null || _g === void 0 ? void 0 : _g.version)) {
                    properties.$feature_flag_version = flagDetails.metadata.version;
                }
                var reason = (_j = (_h = flagDetails === null || flagDetails === void 0 ? void 0 : flagDetails.reason) === null || _h === void 0 ? void 0 : _h.description) !== null && _j !== void 0 ? _j : (_k = flagDetails === null || flagDetails === void 0 ? void 0 : flagDetails.reason) === null || _k === void 0 ? void 0 : _k.code;
                if (reason) {
                    properties.$feature_flag_reason = reason;
                }
                if ((_l = flagDetails === null || flagDetails === void 0 ? void 0 : flagDetails.metadata) === null || _l === void 0 ? void 0 : _l.id) {
                    properties.$feature_flag_id = flagDetails.metadata.id;
                }
                // It's possible that flag values were overridden by calling overrideFeatureFlags.
                // We want to capture the original values in case someone forgets they were using overrides
                // and is wondering why their app is acting weird.
                if (!(0, core_1.isUndefined)(flagDetails === null || flagDetails === void 0 ? void 0 : flagDetails.original_variant) || !(0, core_1.isUndefined)(flagDetails === null || flagDetails === void 0 ? void 0 : flagDetails.original_enabled)) {
                    properties.$feature_flag_original_response = !(0, core_1.isUndefined)(flagDetails.original_variant)
                        ? flagDetails.original_variant
                        : flagDetails.original_enabled;
                }
                if ((_m = flagDetails === null || flagDetails === void 0 ? void 0 : flagDetails.metadata) === null || _m === void 0 ? void 0 : _m.original_payload) {
                    properties.$feature_flag_original_payload = (_o = flagDetails === null || flagDetails === void 0 ? void 0 : flagDetails.metadata) === null || _o === void 0 ? void 0 : _o.original_payload;
                }
                this._instance.capture('$feature_flag_called', properties);
            }
        }
        return flagValue;
    };
    /*
     * Retrieves the details for a feature flag.
     *
     * ### Usage:
     *
     *     const details = getFeatureFlagDetails("my-flag")
     *     console.log(details.metadata.version)
     *     console.log(details.reason)
     *
     * @param {String} key Key of the feature flag.
     */
    PostHogFeatureFlags.prototype.getFeatureFlagDetails = function (key) {
        var details = this.getFlagsWithDetails();
        return details[key];
    };
    PostHogFeatureFlags.prototype.getFeatureFlagPayload = function (key) {
        var payloads = this.getFlagPayloads();
        return payloads[key];
    };
    /*
     * Fetches the payload for a remote config feature flag. This method will bypass any cached values and fetch the latest
     * value from the PostHog API.
     *
     * Note: Because the posthog-js SDK is primarily used with public project API keys, encrypted remote config payloads will
     * be redacted, never decrypted in the response.
     *
     * ### Usage:
     *
     *     getRemoteConfigPayload("home-page-welcome-message", (payload) => console.log(`Fetched remote config: ${payload}`))
     *
     * @param {String} key Key of the feature flag.
     * @param {Function} [callback] The callback function will be called once the remote config feature flag payload has been fetched.
     */
    PostHogFeatureFlags.prototype.getRemoteConfigPayload = function (key, callback) {
        var token = this._instance.config.token;
        this._instance._send_request({
            method: 'POST',
            url: this._instance.requestRouter.endpointFor('api', '/flags/?v=2&config=true'),
            data: {
                distinct_id: this._instance.get_distinct_id(),
                token: token,
            },
            compression: this._instance.config.disable_compression ? undefined : types_1.Compression.Base64,
            timeout: this._instance.config.feature_flag_request_timeout_ms,
            callback: function (response) {
                var _a;
                var flagPayloads = (_a = response.json) === null || _a === void 0 ? void 0 : _a['featureFlagPayloads'];
                callback((flagPayloads === null || flagPayloads === void 0 ? void 0 : flagPayloads[key]) || undefined);
            },
        });
    };
    /*
     * See if feature flag is enabled for user.
     *
     * ### Usage:
     *
     *     if(posthog.isFeatureEnabled('beta-feature')) { // do something }
     *
     * @param {Object|String} key Key of the feature flag.
     * @param {Object|String} options (optional) If {send_event: false}, we won't send an $feature_flag_call event to PostHog.
     */
    PostHogFeatureFlags.prototype.isFeatureEnabled = function (key, options) {
        if (options === void 0) { options = {}; }
        if (!this._hasLoadedFlags && !(this.getFlags() && this.getFlags().length > 0)) {
            logger.warn('isFeatureEnabled for key "' + key + '" failed. Feature flags didn\'t load in time.');
            return undefined;
        }
        return !!this.getFeatureFlag(key, options);
    };
    PostHogFeatureFlags.prototype.addFeatureFlagsHandler = function (handler) {
        this.featureFlagEventHandlers.push(handler);
    };
    PostHogFeatureFlags.prototype.removeFeatureFlagsHandler = function (handler) {
        this.featureFlagEventHandlers = this.featureFlagEventHandlers.filter(function (h) { return h !== handler; });
    };
    PostHogFeatureFlags.prototype.receivedFeatureFlags = function (response, errorsLoading) {
        if (!this._instance.persistence) {
            return;
        }
        this._hasLoadedFlags = true;
        var currentFlags = this.getFlagVariants();
        var currentFlagPayloads = this.getFlagPayloads();
        var currentFlagDetails = this.getFlagsWithDetails();
        (0, exports.parseFlagsResponse)(response, this._instance.persistence, currentFlags, currentFlagPayloads, currentFlagDetails);
        this._fireFeatureFlagsCallbacks(errorsLoading);
    };
    /**
     * @deprecated Use overrideFeatureFlags instead. This will be removed in a future version.
     */
    PostHogFeatureFlags.prototype.override = function (flags, suppressWarning) {
        if (suppressWarning === void 0) { suppressWarning = false; }
        logger.warn('override is deprecated. Please use overrideFeatureFlags instead.');
        this.overrideFeatureFlags({
            flags: flags,
            suppressWarning: suppressWarning,
        });
    };
    /**
     * Override feature flags on the client-side. Useful for setting non-persistent feature flags,
     * or for testing/debugging feature flags in the PostHog app.
     *
     * ### Usage:
     *
     *     - posthog.featureFlags.overrideFeatureFlags(false) // clear all overrides
     *     - posthog.featureFlags.overrideFeatureFlags(['beta-feature']) // enable flags
     *     - posthog.featureFlags.overrideFeatureFlags({'beta-feature': 'variant'}) // set variants
     *     - posthog.featureFlags.overrideFeatureFlags({ // set both flags and payloads
     *         flags: {'beta-feature': 'variant'},
     *         payloads: { 'beta-feature': { someData: true } }
     *       })
     *     - posthog.featureFlags.overrideFeatureFlags({ // only override payloads
     *         payloads: { 'beta-feature': { someData: true } }
     *       })
     */
    PostHogFeatureFlags.prototype.overrideFeatureFlags = function (overrideOptions) {
        var _a, _b, _c;
        var _d;
        if (!this._instance.__loaded || !this._instance.persistence) {
            return logger.uninitializedWarning('posthog.featureFlags.overrideFeatureFlags');
        }
        // Clear all overrides if false, lets you do something like posthog.featureFlags.overrideFeatureFlags(false)
        if (overrideOptions === false) {
            this._instance.persistence.unregister(PERSISTENCE_OVERRIDE_FEATURE_FLAGS);
            this._instance.persistence.unregister(PERSISTENCE_OVERRIDE_FEATURE_FLAG_PAYLOADS);
            this._fireFeatureFlagsCallbacks();
            return;
        }
        if (overrideOptions &&
            typeof overrideOptions === 'object' &&
            ('flags' in overrideOptions || 'payloads' in overrideOptions)) {
            var options = overrideOptions;
            this._override_warning = Boolean((_d = options.suppressWarning) !== null && _d !== void 0 ? _d : false);
            // Handle flags if provided, lets you do something like posthog.featureFlags.overrideFeatureFlags({flags: ['beta-feature']})
            if ('flags' in options) {
                if (options.flags === false) {
                    this._instance.persistence.unregister(PERSISTENCE_OVERRIDE_FEATURE_FLAGS);
                }
                else if (options.flags) {
                    if ((0, core_1.isArray)(options.flags)) {
                        var flagsObj = {};
                        for (var i = 0; i < options.flags.length; i++) {
                            flagsObj[options.flags[i]] = true;
                        }
                        this._instance.persistence.register((_a = {}, _a[PERSISTENCE_OVERRIDE_FEATURE_FLAGS] = flagsObj, _a));
                    }
                    else {
                        this._instance.persistence.register((_b = {}, _b[PERSISTENCE_OVERRIDE_FEATURE_FLAGS] = options.flags, _b));
                    }
                }
            }
            // Handle payloads independently, lets you do something like posthog.featureFlags.overrideFeatureFlags({payloads: { 'beta-feature': { someData: true } }})
            if ('payloads' in options) {
                if (options.payloads === false) {
                    this._instance.persistence.unregister(PERSISTENCE_OVERRIDE_FEATURE_FLAG_PAYLOADS);
                }
                else if (options.payloads) {
                    this._instance.persistence.register((_c = {},
                        _c[PERSISTENCE_OVERRIDE_FEATURE_FLAG_PAYLOADS] = options.payloads,
                        _c));
                }
            }
            this._fireFeatureFlagsCallbacks();
            return;
        }
        this._fireFeatureFlagsCallbacks();
    };
    /*
     * Register an event listener that runs when feature flags become available or when they change.
     * If there are flags, the listener is called immediately in addition to being called on future changes.
     *
     * ### Usage:
     *
     *     posthog.onFeatureFlags(function(featureFlags, featureFlagsVariants, { errorsLoading }) { // do something })
     *
     * @param {Function} [callback] The callback function will be called once the feature flags are ready or when they are updated.
     *                              It'll return a list of feature flags enabled for the user, the variants,
     *                              and also a context object indicating whether we succeeded to fetch the flags or not.
     * @returns {Function} A function that can be called to unsubscribe the listener. Used by useEffect when the component unmounts.
     */
    PostHogFeatureFlags.prototype.onFeatureFlags = function (callback) {
        var _this = this;
        this.addFeatureFlagsHandler(callback);
        if (this._hasLoadedFlags) {
            var _a = this._prepareFeatureFlagsForCallbacks(), flags = _a.flags, flagVariants = _a.flagVariants;
            callback(flags, flagVariants);
        }
        return function () { return _this.removeFeatureFlagsHandler(callback); };
    };
    PostHogFeatureFlags.prototype.updateEarlyAccessFeatureEnrollment = function (key, isEnrolled, stage) {
        var _a, _b, _c;
        var _d;
        var existing_early_access_features = this._instance.get_property(constants_1.PERSISTENCE_EARLY_ACCESS_FEATURES) || [];
        var feature = existing_early_access_features.find(function (f) { return f.flagKey === key; });
        var enrollmentPersonProp = (_a = {},
            _a["$feature_enrollment/".concat(key)] = isEnrolled,
            _a);
        var properties = {
            $feature_flag: key,
            $feature_enrollment: isEnrolled,
            $set: enrollmentPersonProp,
        };
        if (feature) {
            properties['$early_access_feature_name'] = feature.name;
        }
        if (stage) {
            properties['$feature_enrollment_stage'] = stage;
        }
        this._instance.capture('$feature_enrollment_update', properties);
        this.setPersonPropertiesForFlags(enrollmentPersonProp, false);
        var newFlags = __assign(__assign({}, this.getFlagVariants()), (_b = {}, _b[key] = isEnrolled, _b));
        (_d = this._instance.persistence) === null || _d === void 0 ? void 0 : _d.register((_c = {},
            _c[PERSISTENCE_ACTIVE_FEATURE_FLAGS] = Object.keys((0, exports.filterActiveFeatureFlags)(newFlags)),
            _c[constants_1.ENABLED_FEATURE_FLAGS] = newFlags,
            _c));
        this._fireFeatureFlagsCallbacks();
    };
    PostHogFeatureFlags.prototype.getEarlyAccessFeatures = function (callback, force_reload, stages) {
        var _this = this;
        if (force_reload === void 0) { force_reload = false; }
        var existing_early_access_features = this._instance.get_property(constants_1.PERSISTENCE_EARLY_ACCESS_FEATURES);
        var stageParams = stages ? "&".concat(stages.map(function (s) { return "stage=".concat(s); }).join('&')) : '';
        if (!existing_early_access_features || force_reload) {
            this._instance._send_request({
                url: this._instance.requestRouter.endpointFor('api', "/api/early_access_features/?token=".concat(this._instance.config.token).concat(stageParams)),
                method: 'GET',
                callback: function (response) {
                    var _a;
                    var _b, _c;
                    if (!response.json) {
                        return;
                    }
                    var earlyAccessFeatures = response.json.earlyAccessFeatures;
                    // Unregister first to ensure complete replacement, not merge
                    // This prevents accumulation of stale features in persistence
                    (_b = _this._instance.persistence) === null || _b === void 0 ? void 0 : _b.unregister(constants_1.PERSISTENCE_EARLY_ACCESS_FEATURES);
                    (_c = _this._instance.persistence) === null || _c === void 0 ? void 0 : _c.register((_a = {}, _a[constants_1.PERSISTENCE_EARLY_ACCESS_FEATURES] = earlyAccessFeatures, _a));
                    return callback(earlyAccessFeatures);
                },
            });
        }
        else {
            return callback(existing_early_access_features);
        }
    };
    PostHogFeatureFlags.prototype._prepareFeatureFlagsForCallbacks = function () {
        var flags = this.getFlags();
        var flagVariants = this.getFlagVariants();
        // Return truthy
        var truthyFlags = flags.filter(function (flag) { return flagVariants[flag]; });
        var truthyFlagVariants = Object.keys(flagVariants)
            .filter(function (variantKey) { return flagVariants[variantKey]; })
            .reduce(function (res, key) {
            res[key] = flagVariants[key];
            return res;
        }, {});
        return {
            flags: truthyFlags,
            flagVariants: truthyFlagVariants,
        };
    };
    PostHogFeatureFlags.prototype._fireFeatureFlagsCallbacks = function (errorsLoading) {
        var _a = this._prepareFeatureFlagsForCallbacks(), flags = _a.flags, flagVariants = _a.flagVariants;
        this.featureFlagEventHandlers.forEach(function (handler) { return handler(flags, flagVariants, { errorsLoading: errorsLoading }); });
    };
    /**
     * Set override person properties for feature flags.
     * This is used when dealing with new persons / where you don't want to wait for ingestion
     * to update user properties.
     */
    PostHogFeatureFlags.prototype.setPersonPropertiesForFlags = function (properties, reloadFeatureFlags) {
        var _a;
        if (reloadFeatureFlags === void 0) { reloadFeatureFlags = true; }
        // Get persisted person properties
        var existingProperties = this._instance.get_property(constants_1.STORED_PERSON_PROPERTIES_KEY) || {};
        this._instance.register((_a = {},
            _a[constants_1.STORED_PERSON_PROPERTIES_KEY] = __assign(__assign({}, existingProperties), properties),
            _a));
        if (reloadFeatureFlags) {
            this._instance.reloadFeatureFlags();
        }
    };
    PostHogFeatureFlags.prototype.resetPersonPropertiesForFlags = function () {
        this._instance.unregister(constants_1.STORED_PERSON_PROPERTIES_KEY);
    };
    /**
     * Set override group properties for feature flags.
     * This is used when dealing with new groups / where you don't want to wait for ingestion
     * to update properties.
     * Takes in an object, the key of which is the group type.
     * For example:
     *     setGroupPropertiesForFlags({'organization': { name: 'CYZ', employees: '11' } })
     */
    PostHogFeatureFlags.prototype.setGroupPropertiesForFlags = function (properties, reloadFeatureFlags) {
        var _a;
        if (reloadFeatureFlags === void 0) { reloadFeatureFlags = true; }
        // Get persisted group properties
        var existingProperties = this._instance.get_property(constants_1.STORED_GROUP_PROPERTIES_KEY) || {};
        if (Object.keys(existingProperties).length !== 0) {
            Object.keys(existingProperties).forEach(function (groupType) {
                existingProperties[groupType] = __assign(__assign({}, existingProperties[groupType]), properties[groupType]);
                delete properties[groupType];
            });
        }
        this._instance.register((_a = {},
            _a[constants_1.STORED_GROUP_PROPERTIES_KEY] = __assign(__assign({}, existingProperties), properties),
            _a));
        if (reloadFeatureFlags) {
            this._instance.reloadFeatureFlags();
        }
    };
    PostHogFeatureFlags.prototype.resetGroupPropertiesForFlags = function (group_type) {
        var _a, _b;
        if (group_type) {
            var existingProperties = this._instance.get_property(constants_1.STORED_GROUP_PROPERTIES_KEY) || {};
            this._instance.register((_a = {},
                _a[constants_1.STORED_GROUP_PROPERTIES_KEY] = __assign(__assign({}, existingProperties), (_b = {}, _b[group_type] = {}, _b)),
                _a));
        }
        else {
            this._instance.unregister(constants_1.STORED_GROUP_PROPERTIES_KEY);
        }
    };
    PostHogFeatureFlags.prototype.reset = function () {
        this._hasLoadedFlags = false;
        this._requestInFlight = false;
        this._reloadingDisabled = false;
        this._additionalReloadRequested = false;
        this._flagsCalled = false;
        this._flagsLoadedFromRemote = false;
        this.$anon_distinct_id = undefined;
        this._clearDebouncer();
        this._override_warning = false;
    };
    return PostHogFeatureFlags;
}());
exports.PostHogFeatureFlags = PostHogFeatureFlags;
//# sourceMappingURL=posthog-featureflags.js.map