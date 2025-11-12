"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.HistoryAutocapture = void 0;
var globals_1 = require("../utils/globals");
var utils_1 = require("../utils");
var logger_1 = require("../utils/logger");
var patch_1 = require("./replay/rrweb-plugins/patch");
/**
 * This class is used to capture pageview events when the user navigates using the history API (pushState, replaceState)
 * and when the user navigates using the browser's back/forward buttons.
 *
 * The behavior is controlled by the `capture_pageview` configuration option:
 * - When set to `'history_change'`, this class will capture pageviews on history API changes
 */
var HistoryAutocapture = /** @class */ (function () {
    function HistoryAutocapture(instance) {
        var _a;
        this._instance = instance;
        this._lastPathname = ((_a = globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.location) === null || _a === void 0 ? void 0 : _a.pathname) || '';
    }
    Object.defineProperty(HistoryAutocapture.prototype, "isEnabled", {
        get: function () {
            return this._instance.config.capture_pageview === 'history_change';
        },
        enumerable: false,
        configurable: true
    });
    HistoryAutocapture.prototype.startIfEnabled = function () {
        if (this.isEnabled) {
            logger_1.logger.info('History API monitoring enabled, starting...');
            this.monitorHistoryChanges();
        }
    };
    HistoryAutocapture.prototype.stop = function () {
        if (this._popstateListener) {
            this._popstateListener();
        }
        this._popstateListener = undefined;
        logger_1.logger.info('History API monitoring stopped');
    };
    HistoryAutocapture.prototype.monitorHistoryChanges = function () {
        var _a, _b;
        if (!globals_1.window || !globals_1.window.history) {
            return;
        }
        // Old fashioned, we could also use arrow functions but I think the closure for a patch is more reliable
        // eslint-disable-next-line @typescript-eslint/no-this-alias
        var self = this;
        if (!((_a = globals_1.window.history.pushState) === null || _a === void 0 ? void 0 : _a.__posthog_wrapped__)) {
            (0, patch_1.patch)(globals_1.window.history, 'pushState', function (originalPushState) {
                return function patchedPushState(state, title, url) {
                    ;
                    originalPushState.call(this, state, title, url);
                    self._capturePageview('pushState');
                };
            });
        }
        if (!((_b = globals_1.window.history.replaceState) === null || _b === void 0 ? void 0 : _b.__posthog_wrapped__)) {
            (0, patch_1.patch)(globals_1.window.history, 'replaceState', function (originalReplaceState) {
                return function patchedReplaceState(state, title, url) {
                    ;
                    originalReplaceState.call(this, state, title, url);
                    self._capturePageview('replaceState');
                };
            });
        }
        this._setupPopstateListener();
    };
    HistoryAutocapture.prototype._capturePageview = function (navigationType) {
        var _a;
        try {
            var currentPathname = (_a = globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.location) === null || _a === void 0 ? void 0 : _a.pathname;
            if (!currentPathname) {
                return;
            }
            // Only capture pageview if the pathname has changed and the feature is enabled
            if (currentPathname !== this._lastPathname && this.isEnabled) {
                this._instance.capture('$pageview', { navigation_type: navigationType });
            }
            this._lastPathname = currentPathname;
        }
        catch (error) {
            logger_1.logger.error("Error capturing ".concat(navigationType, " pageview"), error);
        }
    };
    HistoryAutocapture.prototype._setupPopstateListener = function () {
        var _this = this;
        if (this._popstateListener) {
            return;
        }
        var handler = function () {
            _this._capturePageview('popstate');
        };
        (0, utils_1.addEventListener)(globals_1.window, 'popstate', handler);
        this._popstateListener = function () {
            if (globals_1.window) {
                globals_1.window.removeEventListener('popstate', handler);
            }
        };
    };
    return HistoryAutocapture;
}());
exports.HistoryAutocapture = HistoryAutocapture;
//# sourceMappingURL=history-autocapture.js.map