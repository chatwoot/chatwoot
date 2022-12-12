Object.defineProperty(exports, "__esModule", { value: true });
var tslib_1 = require("tslib");
var flags_1 = require("./flags");
var global_1 = require("./global");
// TODO: Implement different loggers for different environments
var global = global_1.getGlobalObject();
/** Prefix for logging strings */
var PREFIX = 'Sentry Logger ';
exports.CONSOLE_LEVELS = ['debug', 'info', 'warn', 'error', 'log', 'assert'];
/**
 * Temporarily disable sentry console instrumentations.
 *
 * @param callback The function to run against the original `console` messages
 * @returns The results of the callback
 */
function consoleSandbox(callback) {
    var global = global_1.getGlobalObject();
    if (!('console' in global)) {
        return callback();
    }
    var originalConsole = global.console;
    var wrappedLevels = {};
    // Restore all wrapped console methods
    exports.CONSOLE_LEVELS.forEach(function (level) {
        // TODO(v7): Remove this check as it's only needed for Node 6
        var originalWrappedFunc = originalConsole[level] && originalConsole[level].__sentry_original__;
        if (level in global.console && originalWrappedFunc) {
            wrappedLevels[level] = originalConsole[level];
            originalConsole[level] = originalWrappedFunc;
        }
    });
    try {
        return callback();
    }
    finally {
        // Revert restoration to wrapped state
        Object.keys(wrappedLevels).forEach(function (level) {
            originalConsole[level] = wrappedLevels[level];
        });
    }
}
exports.consoleSandbox = consoleSandbox;
function makeLogger() {
    var enabled = false;
    var logger = {
        enable: function () {
            enabled = true;
        },
        disable: function () {
            enabled = false;
        },
    };
    if (flags_1.IS_DEBUG_BUILD) {
        exports.CONSOLE_LEVELS.forEach(function (name) {
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            logger[name] = function () {
                var args = [];
                for (var _i = 0; _i < arguments.length; _i++) {
                    args[_i] = arguments[_i];
                }
                if (enabled) {
                    consoleSandbox(function () {
                        var _a;
                        (_a = global.console)[name].apply(_a, tslib_1.__spread([PREFIX + "[" + name + "]:"], args));
                    });
                }
            };
        });
    }
    else {
        exports.CONSOLE_LEVELS.forEach(function (name) {
            logger[name] = function () { return undefined; };
        });
    }
    return logger;
}
// Ensure we only have a single logger instance, even if multiple versions of @sentry/utils are being used
var logger;
exports.logger = logger;
if (flags_1.IS_DEBUG_BUILD) {
    exports.logger = logger = global_1.getGlobalSingleton('logger', makeLogger);
}
else {
    exports.logger = logger = makeLogger();
}
//# sourceMappingURL=logger.js.map