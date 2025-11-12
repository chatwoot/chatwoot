"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TracingHeaders = void 0;
var globals_1 = require("../utils/globals");
var logger_1 = require("../utils/logger");
var core_1 = require("@posthog/core");
var logger = (0, logger_1.createLogger)('[TracingHeaders]');
var TracingHeaders = /** @class */ (function () {
    function TracingHeaders(_instance) {
        var _this = this;
        this._instance = _instance;
        this._restoreXHRPatch = undefined;
        this._restoreFetchPatch = undefined;
        this._startCapturing = function () {
            var _a, _b, _c, _d;
            if ((0, core_1.isUndefined)(_this._restoreXHRPatch)) {
                (_b = (_a = globals_1.assignableWindow.__PosthogExtensions__) === null || _a === void 0 ? void 0 : _a.tracingHeadersPatchFns) === null || _b === void 0 ? void 0 : _b._patchXHR(_this._instance.config.__add_tracing_headers || [], _this._instance.get_distinct_id(), _this._instance.sessionManager);
            }
            if ((0, core_1.isUndefined)(_this._restoreFetchPatch)) {
                (_d = (_c = globals_1.assignableWindow.__PosthogExtensions__) === null || _c === void 0 ? void 0 : _c.tracingHeadersPatchFns) === null || _d === void 0 ? void 0 : _d._patchFetch(_this._instance.config.__add_tracing_headers || [], _this._instance.get_distinct_id(), _this._instance.sessionManager);
            }
        };
    }
    TracingHeaders.prototype._loadScript = function (cb) {
        var _a, _b, _c;
        if ((_a = globals_1.assignableWindow.__PosthogExtensions__) === null || _a === void 0 ? void 0 : _a.tracingHeadersPatchFns) {
            // already loaded
            cb();
        }
        (_c = (_b = globals_1.assignableWindow.__PosthogExtensions__) === null || _b === void 0 ? void 0 : _b.loadExternalDependency) === null || _c === void 0 ? void 0 : _c.call(_b, this._instance, 'tracing-headers', function (err) {
            if (err) {
                return logger.error('failed to load script', err);
            }
            cb();
        });
    };
    TracingHeaders.prototype.startIfEnabledOrStop = function () {
        var _a, _b;
        if (this._instance.config.__add_tracing_headers) {
            this._loadScript(this._startCapturing);
        }
        else {
            (_a = this._restoreXHRPatch) === null || _a === void 0 ? void 0 : _a.call(this);
            (_b = this._restoreFetchPatch) === null || _b === void 0 ? void 0 : _b.call(this);
            // we don't want to call these twice so we reset them
            this._restoreXHRPatch = undefined;
            this._restoreFetchPatch = undefined;
        }
    };
    return TracingHeaders;
}());
exports.TracingHeaders = TracingHeaders;
//# sourceMappingURL=tracing-headers.js.map