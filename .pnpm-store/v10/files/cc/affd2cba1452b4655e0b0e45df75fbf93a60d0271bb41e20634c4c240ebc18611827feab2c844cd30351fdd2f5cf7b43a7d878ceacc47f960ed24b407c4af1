"use strict";
/* eslint camelcase: "off" */
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
exports.PostHogPersistence = void 0;
var utils_1 = require("./utils");
var storage_1 = require("./storage");
var constants_1 = require("./constants");
var core_1 = require("@posthog/core");
var event_utils_1 = require("./utils/event-utils");
var logger_1 = require("./utils/logger");
var core_2 = require("@posthog/core");
var CASE_INSENSITIVE_PERSISTENCE_TYPES = [
    'cookie',
    'localstorage',
    'localstorage+cookie',
    'sessionstorage',
    'memory',
];
var parseName = function (config) {
    var token = '';
    if (config['token']) {
        token = config['token'].replace(/\+/g, 'PL').replace(/\//g, 'SL').replace(/=/g, 'EQ');
    }
    if (config['persistence_name']) {
        return 'ph_' + config['persistence_name'];
    }
    else {
        return 'ph_' + token + '_posthog';
    }
};
/**
 * PostHog Persistence Object
 * @constructor
 */
var PostHogPersistence = /** @class */ (function () {
    /**
     * @param {PostHogConfig} config initial PostHog configuration
     * @param {boolean=} isDisabled should persistence be disabled (e.g. because of consent management)
     */
    function PostHogPersistence(config, isDisabled) {
        this._config = config;
        this.props = {};
        this._campaign_params_saved = false;
        this._name = parseName(config);
        this._storage = this._buildStorage(config);
        this.load();
        if (config.debug) {
            logger_1.logger.info('Persistence loaded', config['persistence'], __assign({}, this.props));
        }
        this.update_config(config, config, isDisabled);
        this.save();
    }
    PostHogPersistence.prototype.isDisabled = function () {
        return !!this._disabled;
    };
    PostHogPersistence.prototype._buildStorage = function (config) {
        if (CASE_INSENSITIVE_PERSISTENCE_TYPES.indexOf(config['persistence'].toLowerCase()) === -1) {
            logger_1.logger.critical('Unknown persistence type ' + config['persistence'] + '; falling back to localStorage+cookie');
            config['persistence'] = 'localStorage+cookie';
        }
        var store;
        // We handle storage type in a case-insensitive way for backwards compatibility
        var storage_type = config['persistence'].toLowerCase();
        if (storage_type === 'localstorage' && storage_1.localStore._is_supported()) {
            store = storage_1.localStore;
        }
        else if (storage_type === 'localstorage+cookie' && storage_1.localPlusCookieStore._is_supported()) {
            store = storage_1.localPlusCookieStore;
        }
        else if (storage_type === 'sessionstorage' && storage_1.sessionStore._is_supported()) {
            store = storage_1.sessionStore;
        }
        else if (storage_type === 'memory') {
            store = storage_1.memoryStore;
        }
        else if (storage_type === 'cookie') {
            store = storage_1.cookieStore;
        }
        else if (storage_1.localPlusCookieStore._is_supported()) {
            // selected storage type wasn't supported, fallback to 'localstorage+cookie' if possible
            store = storage_1.localPlusCookieStore;
        }
        else {
            store = storage_1.cookieStore;
        }
        return store;
    };
    PostHogPersistence.prototype.properties = function () {
        var p = {};
        // Filter out reserved properties
        (0, utils_1.each)(this.props, function (v, k) {
            if (k === constants_1.ENABLED_FEATURE_FLAGS && (0, core_2.isObject)(v)) {
                var keys = Object.keys(v);
                for (var i = 0; i < keys.length; i++) {
                    p["$feature/".concat(keys[i])] = v[keys[i]];
                }
            }
            else if (!(0, utils_1.include)(constants_1.PERSISTENCE_RESERVED_PROPERTIES, k)) {
                p[k] = v;
            }
        });
        return p;
    };
    PostHogPersistence.prototype.load = function () {
        if (this._disabled) {
            return;
        }
        var entry = this._storage._parse(this._name);
        if (entry) {
            this.props = (0, utils_1.extend)({}, entry);
        }
    };
    /**
     * NOTE: Saving frequently causes issues with Recordings and Consent Management Platform (CMP) tools which
     * observe cookie changes, and modify their UI, often causing infinite loops.
     * As such callers of this should ideally check that the data has changed beforehand
     */
    PostHogPersistence.prototype.save = function () {
        if (this._disabled) {
            return;
        }
        this._storage._set(this._name, this.props, this._expire_days, this._cross_subdomain, this._secure, this._config.debug);
    };
    PostHogPersistence.prototype.remove = function () {
        // remove both domain and subdomain cookies
        this._storage._remove(this._name, false);
        this._storage._remove(this._name, true);
    };
    // removes the storage entry and deletes all loaded data
    // forced name for tests
    PostHogPersistence.prototype.clear = function () {
        this.remove();
        this.props = {};
    };
    /**
     * @param {Object} props
     * @param {*=} default_value
     * @param {number=} days
     */
    PostHogPersistence.prototype.register_once = function (props, default_value, days) {
        var _this = this;
        if ((0, core_2.isObject)(props)) {
            if ((0, core_1.isUndefined)(default_value)) {
                default_value = 'None';
            }
            this._expire_days = (0, core_1.isUndefined)(days) ? this._default_expiry : days;
            var hasChanges_1 = false;
            (0, utils_1.each)(props, function (val, prop) {
                if (!_this.props.hasOwnProperty(prop) || _this.props[prop] === default_value) {
                    _this.props[prop] = val;
                    hasChanges_1 = true;
                }
            });
            if (hasChanges_1) {
                this.save();
                return true;
            }
        }
        return false;
    };
    /**
     * @param {Object} props
     * @param {number=} days
     */
    PostHogPersistence.prototype.register = function (props, days) {
        var _this = this;
        if ((0, core_2.isObject)(props)) {
            this._expire_days = (0, core_1.isUndefined)(days) ? this._default_expiry : days;
            var hasChanges_2 = false;
            (0, utils_1.each)(props, function (val, prop) {
                if (props.hasOwnProperty(prop) && _this.props[prop] !== val) {
                    _this.props[prop] = val;
                    hasChanges_2 = true;
                }
            });
            if (hasChanges_2) {
                this.save();
                return true;
            }
        }
        return false;
    };
    PostHogPersistence.prototype.unregister = function (prop) {
        if (prop in this.props) {
            delete this.props[prop];
            this.save();
        }
    };
    PostHogPersistence.prototype.update_campaign_params = function () {
        if (!this._campaign_params_saved) {
            var campaignParams = (0, event_utils_1.getCampaignParams)(this._config.custom_campaign_params, this._config.mask_personal_data_properties, this._config.custom_personal_data_properties);
            // only save campaign params if there were any
            if (!(0, core_2.isEmptyObject)((0, utils_1.stripEmptyProperties)(campaignParams))) {
                this.register(campaignParams);
            }
            this._campaign_params_saved = true;
        }
    };
    PostHogPersistence.prototype.update_search_keyword = function () {
        this.register((0, event_utils_1.getSearchInfo)());
    };
    PostHogPersistence.prototype.update_referrer_info = function () {
        this.register_once((0, event_utils_1.getReferrerInfo)(), undefined);
    };
    PostHogPersistence.prototype.set_initial_person_info = function () {
        var _a;
        if (this.props[constants_1.INITIAL_CAMPAIGN_PARAMS] || this.props[constants_1.INITIAL_REFERRER_INFO]) {
            // the user has initial properties stored the previous way, don't save them again
            return;
        }
        this.register_once((_a = {},
            _a[constants_1.INITIAL_PERSON_INFO] = (0, event_utils_1.getPersonInfo)(this._config.mask_personal_data_properties, this._config.custom_personal_data_properties),
            _a), undefined);
    };
    PostHogPersistence.prototype.get_initial_props = function () {
        var _this = this;
        var p = {};
        // this section isn't written to anymore, but we should keep reading from it for backwards compatibility
        // for a while
        (0, utils_1.each)([constants_1.INITIAL_REFERRER_INFO, constants_1.INITIAL_CAMPAIGN_PARAMS], function (key) {
            var initialReferrerInfo = _this.props[key];
            if (initialReferrerInfo) {
                (0, utils_1.each)(initialReferrerInfo, function (v, k) {
                    p['$initial_' + (0, core_2.stripLeadingDollar)(k)] = v;
                });
            }
        });
        var initialPersonInfo = this.props[constants_1.INITIAL_PERSON_INFO];
        if (initialPersonInfo) {
            var initialPersonProps = (0, event_utils_1.getInitialPersonPropsFromInfo)(initialPersonInfo);
            (0, utils_1.extend)(p, initialPersonProps);
        }
        return p;
    };
    // safely fills the passed in object with stored properties,
    // does not override any properties defined in both
    // returns the passed in object
    PostHogPersistence.prototype.safe_merge = function (props) {
        (0, utils_1.each)(this.props, function (val, prop) {
            if (!(prop in props)) {
                props[prop] = val;
            }
        });
        return props;
    };
    PostHogPersistence.prototype.update_config = function (config, oldConfig, isDisabled) {
        this._default_expiry = this._expire_days = config['cookie_expiration'];
        this.set_disabled(config['disable_persistence'] || !!isDisabled);
        this.set_cross_subdomain(config['cross_subdomain_cookie']);
        this.set_secure(config['secure_cookie']);
        if (config.persistence !== oldConfig.persistence) {
            // If the persistence type has changed, we need to migrate the data.
            var newStore = this._buildStorage(config);
            var props = this.props;
            // clear the old store
            this.clear();
            this._storage = newStore;
            this.props = props;
            this.save();
        }
    };
    PostHogPersistence.prototype.set_disabled = function (disabled) {
        this._disabled = disabled;
        if (this._disabled) {
            this.remove();
        }
        else {
            this.save();
        }
    };
    PostHogPersistence.prototype.set_cross_subdomain = function (cross_subdomain) {
        if (cross_subdomain !== this._cross_subdomain) {
            this._cross_subdomain = cross_subdomain;
            this.remove();
            this.save();
        }
    };
    PostHogPersistence.prototype.set_secure = function (secure) {
        if (secure !== this._secure) {
            this._secure = secure;
            this.remove();
            this.save();
        }
    };
    PostHogPersistence.prototype.set_event_timer = function (event_name, timestamp) {
        var timers = this.props[constants_1.EVENT_TIMERS_KEY] || {};
        timers[event_name] = timestamp;
        this.props[constants_1.EVENT_TIMERS_KEY] = timers;
        this.save();
    };
    PostHogPersistence.prototype.remove_event_timer = function (event_name) {
        var timers = this.props[constants_1.EVENT_TIMERS_KEY] || {};
        var timestamp = timers[event_name];
        if (!(0, core_1.isUndefined)(timestamp)) {
            delete this.props[constants_1.EVENT_TIMERS_KEY][event_name];
            this.save();
        }
        return timestamp;
    };
    PostHogPersistence.prototype.get_property = function (prop) {
        return this.props[prop];
    };
    PostHogPersistence.prototype.set_property = function (prop, to) {
        this.props[prop] = to;
        this.save();
    };
    return PostHogPersistence;
}());
exports.PostHogPersistence = PostHogPersistence;
//# sourceMappingURL=posthog-persistence.js.map