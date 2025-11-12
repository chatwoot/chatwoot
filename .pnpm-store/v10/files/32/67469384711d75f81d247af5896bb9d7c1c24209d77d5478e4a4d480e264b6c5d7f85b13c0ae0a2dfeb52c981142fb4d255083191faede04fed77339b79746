"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PostHogExceptions = void 0;
var constants_1 = require("./constants");
var logger_1 = require("./utils/logger");
var property_utils_1 = require("./utils/property-utils");
var core_1 = require("@posthog/core");
var logger = (0, logger_1.createLogger)('[Error tracking]');
var PostHogExceptions = /** @class */ (function () {
    function PostHogExceptions(instance) {
        var _a, _b;
        this._suppressionRules = [];
        this._instance = instance;
        this._suppressionRules = (_b = (_a = this._instance.persistence) === null || _a === void 0 ? void 0 : _a.get_property(constants_1.ERROR_TRACKING_SUPPRESSION_RULES)) !== null && _b !== void 0 ? _b : [];
    }
    PostHogExceptions.prototype.onRemoteConfig = function (response) {
        var _a;
        var _b, _c, _d;
        var suppressionRules = (_c = (_b = response.errorTracking) === null || _b === void 0 ? void 0 : _b.suppressionRules) !== null && _c !== void 0 ? _c : [];
        var captureExtensionExceptions = (_d = response.errorTracking) === null || _d === void 0 ? void 0 : _d.captureExtensionExceptions;
        // store this in-memory in case persistence is disabled
        this._suppressionRules = suppressionRules;
        if (this._instance.persistence) {
            this._instance.persistence.register((_a = {},
                _a[constants_1.ERROR_TRACKING_SUPPRESSION_RULES] = this._suppressionRules,
                _a[constants_1.ERROR_TRACKING_CAPTURE_EXTENSION_EXCEPTIONS] = captureExtensionExceptions,
                _a));
        }
    };
    Object.defineProperty(PostHogExceptions.prototype, "_captureExtensionExceptions", {
        get: function () {
            var _a;
            var enabled_server_side = !!this._instance.get_property(constants_1.ERROR_TRACKING_CAPTURE_EXTENSION_EXCEPTIONS);
            var enabled_client_side = this._instance.config.error_tracking.captureExtensionExceptions;
            return (_a = enabled_client_side !== null && enabled_client_side !== void 0 ? enabled_client_side : enabled_server_side) !== null && _a !== void 0 ? _a : false;
        },
        enumerable: false,
        configurable: true
    });
    PostHogExceptions.prototype.sendExceptionEvent = function (properties) {
        if (this._matchesSuppressionRule(properties)) {
            logger.info('Skipping exception capture because a suppression rule matched');
            return;
        }
        if (!this._captureExtensionExceptions && this._isExtensionException(properties)) {
            logger.info('Skipping exception capture because it was thrown by an extension');
            return;
        }
        return this._instance.capture('$exception', properties, {
            _noTruncate: true,
            _batchKey: 'exceptionEvent',
        });
    };
    PostHogExceptions.prototype._matchesSuppressionRule = function (properties) {
        var exceptionList = properties.$exception_list;
        if (!exceptionList || !(0, core_1.isArray)(exceptionList) || exceptionList.length === 0) {
            return false;
        }
        var exceptionValues = exceptionList.reduce(function (acc, _a) {
            var type = _a.type, value = _a.value;
            if ((0, core_1.isString)(type) && type.length > 0) {
                acc['$exception_types'].push(type);
            }
            if ((0, core_1.isString)(value) && value.length > 0) {
                acc['$exception_values'].push(value);
            }
            return acc;
        }, {
            $exception_types: [],
            $exception_values: [],
        });
        return this._suppressionRules.some(function (rule) {
            var results = rule.values.map(function (v) {
                var _a;
                var compare = property_utils_1.propertyComparisons[v.operator];
                var targets = (0, core_1.isArray)(v.value) ? v.value : [v.value];
                var values = (_a = exceptionValues[v.key]) !== null && _a !== void 0 ? _a : [];
                return targets.length > 0 ? compare(targets, values) : false;
            });
            return rule.type === 'OR' ? results.some(Boolean) : results.every(Boolean);
        });
    };
    PostHogExceptions.prototype._isExtensionException = function (properties) {
        var exceptionList = properties.$exception_list;
        if (!exceptionList || !(0, core_1.isArray)(exceptionList)) {
            return false;
        }
        var frames = exceptionList.flatMap(function (e) { var _a, _b; return (_b = (_a = e.stacktrace) === null || _a === void 0 ? void 0 : _a.frames) !== null && _b !== void 0 ? _b : []; });
        return frames.some(function (f) { return f.filename && f.filename.startsWith('chrome-extension://'); });
    };
    return PostHogExceptions;
}());
exports.PostHogExceptions = PostHogExceptions;
//# sourceMappingURL=posthog-exceptions.js.map