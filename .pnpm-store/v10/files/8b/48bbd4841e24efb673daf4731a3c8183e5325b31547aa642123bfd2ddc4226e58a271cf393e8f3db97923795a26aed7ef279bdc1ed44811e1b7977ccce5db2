"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ConsentManager = exports.ConsentStatus = void 0;
var utils_1 = require("./utils");
var globals_1 = require("./utils/globals");
var storage_1 = require("./storage");
var core_1 = require("@posthog/core");
var OPT_OUT_PREFIX = '__ph_opt_in_out_';
var ConsentStatus;
(function (ConsentStatus) {
    ConsentStatus[ConsentStatus["PENDING"] = -1] = "PENDING";
    ConsentStatus[ConsentStatus["DENIED"] = 0] = "DENIED";
    ConsentStatus[ConsentStatus["GRANTED"] = 1] = "GRANTED";
})(ConsentStatus || (exports.ConsentStatus = ConsentStatus = {}));
/**
 * ConsentManager provides tools for managing user consent as configured by the application.
 */
var ConsentManager = /** @class */ (function () {
    function ConsentManager(_instance) {
        this._instance = _instance;
    }
    Object.defineProperty(ConsentManager.prototype, "_config", {
        get: function () {
            return this._instance.config;
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(ConsentManager.prototype, "consent", {
        get: function () {
            if (this._getDnt()) {
                return ConsentStatus.DENIED;
            }
            return this._storedConsent;
        },
        enumerable: false,
        configurable: true
    });
    ConsentManager.prototype.isOptedOut = function () {
        if (this._config.cookieless_mode === 'always') {
            return true;
        }
        // we are opted out if:
        // * consent is explicitly denied
        // * consent is pending, and we are configured to opt out by default
        // * consent is pending, and we are in cookieless mode "on_reject"
        return (this.consent === ConsentStatus.DENIED ||
            (this.consent === ConsentStatus.PENDING &&
                (this._config.opt_out_capturing_by_default || this._config.cookieless_mode === 'on_reject')));
    };
    ConsentManager.prototype.isOptedIn = function () {
        return !this.isOptedOut();
    };
    ConsentManager.prototype.isExplicitlyOptedOut = function () {
        return this.consent === ConsentStatus.DENIED;
    };
    ConsentManager.prototype.optInOut = function (isOptedIn) {
        this._storage._set(this._storageKey, isOptedIn ? 1 : 0, this._config.cookie_expiration, this._config.cross_subdomain_cookie, this._config.secure_cookie);
    };
    ConsentManager.prototype.reset = function () {
        this._storage._remove(this._storageKey, this._config.cross_subdomain_cookie);
    };
    Object.defineProperty(ConsentManager.prototype, "_storageKey", {
        get: function () {
            var _a = this._instance.config, token = _a.token, opt_out_capturing_cookie_prefix = _a.opt_out_capturing_cookie_prefix, consent_persistence_name = _a.consent_persistence_name;
            if (consent_persistence_name) {
                return consent_persistence_name;
            }
            else if (opt_out_capturing_cookie_prefix) {
                // Deprecated, but we still support it for backwards compatibility.
                // This was deprecated because it differed in behaviour from storage.ts, and appends the token.
                // This meant it was not possible to share the same consent state across multiple PostHog instances.
                return opt_out_capturing_cookie_prefix + token;
            }
            else {
                return OPT_OUT_PREFIX + token;
            }
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(ConsentManager.prototype, "_storedConsent", {
        get: function () {
            var value = this._storage._get(this._storageKey);
            return value === '1' ? ConsentStatus.GRANTED : value === '0' ? ConsentStatus.DENIED : ConsentStatus.PENDING;
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(ConsentManager.prototype, "_storage", {
        get: function () {
            if (!this._persistentStore) {
                var persistenceType = this._config.opt_out_capturing_persistence_type;
                this._persistentStore = persistenceType === 'localStorage' ? storage_1.localStore : storage_1.cookieStore;
                var otherStorage = persistenceType === 'localStorage' ? storage_1.cookieStore : storage_1.localStore;
                if (otherStorage._get(this._storageKey)) {
                    if (!this._persistentStore._get(this._storageKey)) {
                        // This indicates we have moved to a new storage format so we migrate the value over
                        this.optInOut(otherStorage._get(this._storageKey) === '1');
                    }
                    otherStorage._remove(this._storageKey, this._config.cross_subdomain_cookie);
                }
            }
            return this._persistentStore;
        },
        enumerable: false,
        configurable: true
    });
    ConsentManager.prototype._getDnt = function () {
        if (!this._config.respect_dnt) {
            return false;
        }
        return !!(0, utils_1.find)([
            globals_1.navigator === null || globals_1.navigator === void 0 ? void 0 : globals_1.navigator.doNotTrack, // standard
            globals_1.navigator === null || globals_1.navigator === void 0 ? void 0 : globals_1.navigator['msDoNotTrack'],
            globals_1.assignableWindow['doNotTrack'],
        ], function (dntValue) {
            return (0, core_1.includes)([true, 1, '1', 'yes'], dntValue);
        });
    };
    return ConsentManager;
}());
exports.ConsentManager = ConsentManager;
//# sourceMappingURL=consent.js.map