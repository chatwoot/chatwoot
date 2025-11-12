"use strict";
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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createLogger = exports.logger = void 0;
var config_1 = __importDefault(require("../config"));
var core_1 = require("@posthog/core");
var globals_1 = require("./globals");
var _createLogger = function (prefix) {
    var logger = {
        _log: function (level) {
            var args = [];
            for (var _i = 1; _i < arguments.length; _i++) {
                args[_i - 1] = arguments[_i];
            }
            if (globals_1.window &&
                (config_1.default.DEBUG || globals_1.assignableWindow.POSTHOG_DEBUG) &&
                !(0, core_1.isUndefined)(globals_1.window.console) &&
                globals_1.window.console) {
                var consoleLog = '__rrweb_original__' in globals_1.window.console[level]
                    ? globals_1.window.console[level]['__rrweb_original__']
                    : globals_1.window.console[level];
                // eslint-disable-next-line no-console
                consoleLog.apply(void 0, __spreadArray([prefix], __read(args), false));
            }
        },
        info: function () {
            var args = [];
            for (var _i = 0; _i < arguments.length; _i++) {
                args[_i] = arguments[_i];
            }
            logger._log.apply(logger, __spreadArray(['log'], __read(args), false));
        },
        warn: function () {
            var args = [];
            for (var _i = 0; _i < arguments.length; _i++) {
                args[_i] = arguments[_i];
            }
            logger._log.apply(logger, __spreadArray(['warn'], __read(args), false));
        },
        error: function () {
            var args = [];
            for (var _i = 0; _i < arguments.length; _i++) {
                args[_i] = arguments[_i];
            }
            logger._log.apply(logger, __spreadArray(['error'], __read(args), false));
        },
        critical: function () {
            var args = [];
            for (var _i = 0; _i < arguments.length; _i++) {
                args[_i] = arguments[_i];
            }
            // Critical errors are always logged to the console
            // eslint-disable-next-line no-console
            console.error.apply(console, __spreadArray([prefix], __read(args), false));
        },
        uninitializedWarning: function (methodName) {
            logger.error("You must initialize PostHog before calling ".concat(methodName));
        },
        createLogger: function (additionalPrefix) { return _createLogger("".concat(prefix, " ").concat(additionalPrefix)); },
    };
    return logger;
};
exports.logger = _createLogger('[PostHog.js]');
exports.createLogger = exports.logger.createLogger;
//# sourceMappingURL=logger.js.map