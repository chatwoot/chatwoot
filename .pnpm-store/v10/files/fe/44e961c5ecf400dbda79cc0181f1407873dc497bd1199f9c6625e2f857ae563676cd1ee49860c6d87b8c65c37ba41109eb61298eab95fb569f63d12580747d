"use strict";
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
exports.ExternalIntegrations = void 0;
var globals_1 = require("../utils/globals");
var logger_1 = require("../utils/logger");
var logger = (0, logger_1.createLogger)('[PostHog ExternalIntegrations]');
var MAPPED_INTEGRATIONS = {
    intercom: 'intercom-integration',
    crispChat: 'crisp-chat-integration',
};
var ExternalIntegrations = /** @class */ (function () {
    function ExternalIntegrations(_instance) {
        this._instance = _instance;
    }
    ExternalIntegrations.prototype._loadScript = function (name, cb) {
        var _a, _b;
        (_b = (_a = globals_1.assignableWindow.__PosthogExtensions__) === null || _a === void 0 ? void 0 : _a.loadExternalDependency) === null || _b === void 0 ? void 0 : _b.call(_a, this._instance, name, function (err) {
            if (err) {
                return logger.error('failed to load script', err);
            }
            cb();
        });
    };
    ExternalIntegrations.prototype.startIfEnabledOrStop = function () {
        var e_1, _a;
        var _this = this;
        var _b, _c, _d, _e, _f, _g, _h, _j;
        var _loop_1 = function (key, value) {
            // if the integration is enabled, and not present, then load it
            if (value && !((_d = (_c = globals_1.assignableWindow.__PosthogExtensions__) === null || _c === void 0 ? void 0 : _c.integrations) === null || _d === void 0 ? void 0 : _d[key])) {
                this_1._loadScript(MAPPED_INTEGRATIONS[key], function () {
                    var _a, _b, _c;
                    (_c = (_b = (_a = globals_1.assignableWindow.__PosthogExtensions__) === null || _a === void 0 ? void 0 : _a.integrations) === null || _b === void 0 ? void 0 : _b[key]) === null || _c === void 0 ? void 0 : _c.start(_this._instance);
                });
            }
            // if the integration is disabled, and present, then stop it
            if (!value && ((_f = (_e = globals_1.assignableWindow.__PosthogExtensions__) === null || _e === void 0 ? void 0 : _e.integrations) === null || _f === void 0 ? void 0 : _f[key])) {
                (_j = (_h = (_g = globals_1.assignableWindow.__PosthogExtensions__) === null || _g === void 0 ? void 0 : _g.integrations) === null || _h === void 0 ? void 0 : _h[key]) === null || _j === void 0 ? void 0 : _j.stop();
            }
        };
        var this_1 = this;
        try {
            for (var _k = __values(Object.entries((_b = this._instance.config.integrations) !== null && _b !== void 0 ? _b : {})), _l = _k.next(); !_l.done; _l = _k.next()) {
                var _m = __read(_l.value, 2), key = _m[0], value = _m[1];
                _loop_1(key, value);
            }
        }
        catch (e_1_1) { e_1 = { error: e_1_1 }; }
        finally {
            try {
                if (_l && !_l.done && (_a = _k.return)) _a.call(_k);
            }
            finally { if (e_1) throw e_1.error; }
        }
    };
    return ExternalIntegrations;
}());
exports.ExternalIntegrations = ExternalIntegrations;
//# sourceMappingURL=external-integration.js.map