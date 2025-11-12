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
Object.defineProperty(exports, "__esModule", { value: true });
exports.ExceptionObserver = void 0;
var globals_1 = require("../../utils/globals");
var logger_1 = require("../../utils/logger");
var constants_1 = require("../../constants");
var core_1 = require("@posthog/core");
var logger = (0, logger_1.createLogger)('[ExceptionAutocapture]');
var ExceptionObserver = /** @class */ (function () {
    function ExceptionObserver(instance) {
        var _this = this;
        var _a, _b, _c;
        this._startCapturing = function () {
            var _a;
            if (!globals_1.window || !_this.isEnabled || !((_a = globals_1.assignableWindow.__PosthogExtensions__) === null || _a === void 0 ? void 0 : _a.errorWrappingFunctions)) {
                return;
            }
            var wrapOnError = globals_1.assignableWindow.__PosthogExtensions__.errorWrappingFunctions.wrapOnError;
            var wrapUnhandledRejection = globals_1.assignableWindow.__PosthogExtensions__.errorWrappingFunctions.wrapUnhandledRejection;
            var wrapConsoleError = globals_1.assignableWindow.__PosthogExtensions__.errorWrappingFunctions.wrapConsoleError;
            try {
                if (!_this._unwrapOnError && _this._config.capture_unhandled_errors) {
                    _this._unwrapOnError = wrapOnError(_this.captureException.bind(_this));
                }
                if (!_this._unwrapUnhandledRejection && _this._config.capture_unhandled_rejections) {
                    _this._unwrapUnhandledRejection = wrapUnhandledRejection(_this.captureException.bind(_this));
                }
                if (!_this._unwrapConsoleError && _this._config.capture_console_errors) {
                    _this._unwrapConsoleError = wrapConsoleError(_this.captureException.bind(_this));
                }
            }
            catch (e) {
                logger.error('failed to start', e);
                _this._stopCapturing();
            }
        };
        this._instance = instance;
        this._remoteEnabled = !!((_a = this._instance.persistence) === null || _a === void 0 ? void 0 : _a.props[constants_1.EXCEPTION_CAPTURE_ENABLED_SERVER_SIDE]);
        this._config = this._requiredConfig();
        // by default captures ten exceptions before rate limiting by exception type
        // refills at a rate of one token / 10 second period
        // e.g. will capture 1 exception rate limited exception every 10 seconds until burst ends
        this._rateLimiter = new core_1.BucketedRateLimiter({
            refillRate: (_b = this._instance.config.error_tracking.__exceptionRateLimiterRefillRate) !== null && _b !== void 0 ? _b : 1,
            bucketSize: (_c = this._instance.config.error_tracking.__exceptionRateLimiterBucketSize) !== null && _c !== void 0 ? _c : 10,
            refillInterval: 10000, // ten seconds in milliseconds,
            _logger: logger,
        });
        this.startIfEnabled();
    }
    ExceptionObserver.prototype._requiredConfig = function () {
        var providedConfig = this._instance.config.capture_exceptions;
        var config = {
            capture_unhandled_errors: false,
            capture_unhandled_rejections: false,
            capture_console_errors: false,
        };
        if ((0, core_1.isObject)(providedConfig)) {
            config = __assign(__assign({}, config), providedConfig);
        }
        else if ((0, core_1.isUndefined)(providedConfig) ? this._remoteEnabled : providedConfig) {
            config = __assign(__assign({}, config), { capture_unhandled_errors: true, capture_unhandled_rejections: true });
        }
        return config;
    };
    Object.defineProperty(ExceptionObserver.prototype, "isEnabled", {
        get: function () {
            return (this._config.capture_console_errors ||
                this._config.capture_unhandled_errors ||
                this._config.capture_unhandled_rejections);
        },
        enumerable: false,
        configurable: true
    });
    ExceptionObserver.prototype.startIfEnabled = function () {
        if (this.isEnabled) {
            logger.info('enabled');
            this._loadScript(this._startCapturing);
        }
    };
    ExceptionObserver.prototype._loadScript = function (cb) {
        var _a, _b, _c;
        if ((_a = globals_1.assignableWindow.__PosthogExtensions__) === null || _a === void 0 ? void 0 : _a.errorWrappingFunctions) {
            // already loaded
            cb();
        }
        (_c = (_b = globals_1.assignableWindow.__PosthogExtensions__) === null || _b === void 0 ? void 0 : _b.loadExternalDependency) === null || _c === void 0 ? void 0 : _c.call(_b, this._instance, 'exception-autocapture', function (err) {
            if (err) {
                return logger.error('failed to load script', err);
            }
            cb();
        });
    };
    ExceptionObserver.prototype._stopCapturing = function () {
        var _a, _b, _c;
        (_a = this._unwrapOnError) === null || _a === void 0 ? void 0 : _a.call(this);
        this._unwrapOnError = undefined;
        (_b = this._unwrapUnhandledRejection) === null || _b === void 0 ? void 0 : _b.call(this);
        this._unwrapUnhandledRejection = undefined;
        (_c = this._unwrapConsoleError) === null || _c === void 0 ? void 0 : _c.call(this);
        this._unwrapConsoleError = undefined;
    };
    ExceptionObserver.prototype.onRemoteConfig = function (response) {
        var _a;
        var autocaptureExceptionsResponse = response.autocaptureExceptions;
        // store this in-memory in case persistence is disabled
        this._remoteEnabled = !!autocaptureExceptionsResponse || false;
        this._config = this._requiredConfig();
        if (this._instance.persistence) {
            this._instance.persistence.register((_a = {},
                _a[constants_1.EXCEPTION_CAPTURE_ENABLED_SERVER_SIDE] = this._remoteEnabled,
                _a));
        }
        this.startIfEnabled();
    };
    ExceptionObserver.prototype.captureException = function (errorProperties) {
        var _a;
        var posthogHost = this._instance.requestRouter.endpointFor('ui');
        errorProperties.$exception_personURL = "".concat(posthogHost, "/project/").concat(this._instance.config.token, "/person/").concat(this._instance.get_distinct_id());
        var exceptionType = (_a = errorProperties.$exception_list[0].type) !== null && _a !== void 0 ? _a : 'Exception';
        var isRateLimited = this._rateLimiter.consumeRateLimit(exceptionType);
        if (isRateLimited) {
            logger.info('Skipping exception capture because of client rate limiting.', {
                exception: errorProperties.$exception_list[0].type,
            });
            return;
        }
        this._instance.exceptions.sendExceptionEvent(errorProperties);
    };
    return ExceptionObserver;
}());
exports.ExceptionObserver = ExceptionObserver;
//# sourceMappingURL=index.js.map