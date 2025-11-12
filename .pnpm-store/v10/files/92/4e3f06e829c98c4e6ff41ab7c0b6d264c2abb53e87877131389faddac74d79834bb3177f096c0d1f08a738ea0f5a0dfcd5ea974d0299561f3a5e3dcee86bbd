"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DeadClicksAutocapture = exports.isDeadClicksEnabledForAutocapture = exports.isDeadClicksEnabledForHeatmaps = void 0;
var constants_1 = require("../constants");
var core_1 = require("@posthog/core");
var globals_1 = require("../utils/globals");
var logger_1 = require("../utils/logger");
var logger = (0, logger_1.createLogger)('[Dead Clicks]');
var isDeadClicksEnabledForHeatmaps = function () {
    return true;
};
exports.isDeadClicksEnabledForHeatmaps = isDeadClicksEnabledForHeatmaps;
var isDeadClicksEnabledForAutocapture = function (instance) {
    var _a;
    var isRemoteEnabled = !!((_a = instance.instance.persistence) === null || _a === void 0 ? void 0 : _a.get_property(constants_1.DEAD_CLICKS_ENABLED_SERVER_SIDE));
    var clientConfig = instance.instance.config.capture_dead_clicks;
    return (0, core_1.isBoolean)(clientConfig) ? clientConfig : isRemoteEnabled;
};
exports.isDeadClicksEnabledForAutocapture = isDeadClicksEnabledForAutocapture;
var DeadClicksAutocapture = /** @class */ (function () {
    function DeadClicksAutocapture(instance, isEnabled, onCapture) {
        this.instance = instance;
        this.isEnabled = isEnabled;
        this.onCapture = onCapture;
        this.startIfEnabled();
    }
    Object.defineProperty(DeadClicksAutocapture.prototype, "lazyLoadedDeadClicksAutocapture", {
        get: function () {
            return this._lazyLoadedDeadClicksAutocapture;
        },
        enumerable: false,
        configurable: true
    });
    DeadClicksAutocapture.prototype.onRemoteConfig = function (response) {
        var _a;
        if (this.instance.persistence) {
            this.instance.persistence.register((_a = {},
                _a[constants_1.DEAD_CLICKS_ENABLED_SERVER_SIDE] = response === null || response === void 0 ? void 0 : response.captureDeadClicks,
                _a));
        }
        this.startIfEnabled();
    };
    DeadClicksAutocapture.prototype.startIfEnabled = function () {
        var _this = this;
        if (this.isEnabled(this)) {
            this._loadScript(function () {
                _this._start();
            });
        }
    };
    DeadClicksAutocapture.prototype._loadScript = function (cb) {
        var _a, _b, _c;
        if ((_a = globals_1.assignableWindow.__PosthogExtensions__) === null || _a === void 0 ? void 0 : _a.initDeadClicksAutocapture) {
            // already loaded
            cb();
        }
        (_c = (_b = globals_1.assignableWindow.__PosthogExtensions__) === null || _b === void 0 ? void 0 : _b.loadExternalDependency) === null || _c === void 0 ? void 0 : _c.call(_b, this.instance, 'dead-clicks-autocapture', function (err) {
            if (err) {
                logger.error('failed to load script', err);
                return;
            }
            cb();
        });
    };
    DeadClicksAutocapture.prototype._start = function () {
        var _a;
        if (!globals_1.document) {
            logger.error('`document` not found. Cannot start.');
            return;
        }
        if (!this._lazyLoadedDeadClicksAutocapture &&
            ((_a = globals_1.assignableWindow.__PosthogExtensions__) === null || _a === void 0 ? void 0 : _a.initDeadClicksAutocapture)) {
            var config = (0, core_1.isObject)(this.instance.config.capture_dead_clicks)
                ? this.instance.config.capture_dead_clicks
                : {};
            config.__onCapture = this.onCapture;
            this._lazyLoadedDeadClicksAutocapture = globals_1.assignableWindow.__PosthogExtensions__.initDeadClicksAutocapture(this.instance, config);
            this._lazyLoadedDeadClicksAutocapture.start(globals_1.document);
            logger.info("starting...");
        }
    };
    DeadClicksAutocapture.prototype.stop = function () {
        if (this._lazyLoadedDeadClicksAutocapture) {
            this._lazyLoadedDeadClicksAutocapture.stop();
            this._lazyLoadedDeadClicksAutocapture = undefined;
            logger.info("stopping...");
        }
    };
    return DeadClicksAutocapture;
}());
exports.DeadClicksAutocapture = DeadClicksAutocapture;
//# sourceMappingURL=dead-clicks-autocapture.js.map