"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.RemoteConfigLoader = void 0;
var logger_1 = require("./utils/logger");
var globals_1 = require("./utils/globals");
var logger = (0, logger_1.createLogger)('[RemoteConfig]');
var RemoteConfigLoader = /** @class */ (function () {
    function RemoteConfigLoader(_instance) {
        this._instance = _instance;
    }
    Object.defineProperty(RemoteConfigLoader.prototype, "remoteConfig", {
        get: function () {
            var _a, _b;
            return (_b = (_a = globals_1.assignableWindow._POSTHOG_REMOTE_CONFIG) === null || _a === void 0 ? void 0 : _a[this._instance.config.token]) === null || _b === void 0 ? void 0 : _b.config;
        },
        enumerable: false,
        configurable: true
    });
    RemoteConfigLoader.prototype._loadRemoteConfigJs = function (cb) {
        var _this = this;
        var _a, _b, _c;
        if ((_a = globals_1.assignableWindow.__PosthogExtensions__) === null || _a === void 0 ? void 0 : _a.loadExternalDependency) {
            (_c = (_b = globals_1.assignableWindow.__PosthogExtensions__) === null || _b === void 0 ? void 0 : _b.loadExternalDependency) === null || _c === void 0 ? void 0 : _c.call(_b, this._instance, 'remote-config', function () {
                return cb(_this.remoteConfig);
            });
        }
        else {
            logger.error('PostHog Extensions not found. Cannot load remote config.');
            cb();
        }
    };
    RemoteConfigLoader.prototype._loadRemoteConfigJSON = function (cb) {
        this._instance._send_request({
            method: 'GET',
            url: this._instance.requestRouter.endpointFor('assets', "/array/".concat(this._instance.config.token, "/config")),
            callback: function (response) {
                cb(response.json);
            },
        });
    };
    RemoteConfigLoader.prototype.load = function () {
        var _this = this;
        try {
            // Attempt 1 - use the pre-loaded config if it came as part of the token-specific array.js
            if (this.remoteConfig) {
                logger.info('Using preloaded remote config', this.remoteConfig);
                this._onRemoteConfig(this.remoteConfig);
                return;
            }
            if (this._instance._shouldDisableFlags()) {
                // This setting is essentially saying "dont call external APIs" hence we respect it here
                logger.warn('Remote config is disabled. Falling back to local config.');
                return;
            }
            // Attempt 2 - if we have the external deps loader then lets load the script version of the config that includes site apps
            this._loadRemoteConfigJs(function (config) {
                if (!config) {
                    logger.info('No config found after loading remote JS config. Falling back to JSON.');
                    // Attempt 3 Load the config json instead of the script - we won't get site apps etc. but we will get the config
                    _this._loadRemoteConfigJSON(function (config) {
                        _this._onRemoteConfig(config);
                    });
                    return;
                }
                _this._onRemoteConfig(config);
            });
        }
        catch (error) {
            logger.error('Error loading remote config', error);
        }
    };
    RemoteConfigLoader.prototype._onRemoteConfig = function (config) {
        // NOTE: Once this is rolled out we will remove the /flags related code above. Until then the code duplication is fine.
        if (!config) {
            logger.error('Failed to fetch remote config from PostHog.');
            return;
        }
        if (!this._instance.config.__preview_remote_config) {
            logger.info('__preview_remote_config is disabled. Logging config instead', config);
            return;
        }
        this._instance._onRemoteConfig(config);
        // We only need to reload if we haven't already loaded the flags or if the request is in flight
        if (config.hasFeatureFlags !== false) {
            // If the config has feature flags, we need to call /flags to get the feature flags
            // This completely separates it from the config logic which is good in terms of separation of concerns
            this._instance.featureFlags.ensureFlagsLoaded();
        }
    };
    return RemoteConfigLoader;
}());
exports.RemoteConfigLoader = RemoteConfigLoader;
//# sourceMappingURL=remote-config.js.map