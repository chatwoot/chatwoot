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
exports.Toolbar = void 0;
var utils_1 = require("../utils");
var request_utils_1 = require("../utils/request-utils");
var logger_1 = require("../utils/logger");
var globals_1 = require("../utils/globals");
var constants_1 = require("../constants");
var core_1 = require("@posthog/core");
// TRICKY: Many web frameworks will modify the route on load, potentially before posthog is initialized.
// To get ahead of this we grab it as soon as the posthog-js is parsed
var STATE_FROM_WINDOW = (globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.location)
    ? (0, request_utils_1._getHashParam)(globals_1.window.location.hash, '__posthog') || (0, request_utils_1._getHashParam)(location.hash, 'state')
    : null;
var LOCALSTORAGE_KEY = '_postHogToolbarParams';
var logger = (0, logger_1.createLogger)('[Toolbar]');
var ToolbarState;
(function (ToolbarState) {
    ToolbarState[ToolbarState["UNINITIALIZED"] = 0] = "UNINITIALIZED";
    ToolbarState[ToolbarState["LOADING"] = 1] = "LOADING";
    ToolbarState[ToolbarState["LOADED"] = 2] = "LOADED";
})(ToolbarState || (ToolbarState = {}));
var Toolbar = /** @class */ (function () {
    function Toolbar(instance) {
        this.instance = instance;
    }
    // NOTE: We store the state of the toolbar in the global scope to avoid multiple instances of the SDK loading the toolbar
    Toolbar.prototype._setToolbarState = function (state) {
        globals_1.assignableWindow['ph_toolbar_state'] = state;
    };
    Toolbar.prototype._getToolbarState = function () {
        var _a;
        return (_a = globals_1.assignableWindow['ph_toolbar_state']) !== null && _a !== void 0 ? _a : ToolbarState.UNINITIALIZED;
    };
    /**
     * To load the toolbar, we need an access token and other state. That state comes from one of three places:
     * 1. In the URL hash params
     * 2. From session storage under the key `toolbarParams` if the toolbar was initialized on a previous page
     */
    Toolbar.prototype.maybeLoadToolbar = function (location, localStorage, history) {
        if (location === void 0) { location = undefined; }
        if (localStorage === void 0) { localStorage = undefined; }
        if (history === void 0) { history = undefined; }
        if (!globals_1.window || !globals_1.document) {
            return false;
        }
        location = location !== null && location !== void 0 ? location : globals_1.window.location;
        history = history !== null && history !== void 0 ? history : globals_1.window.history;
        try {
            // Before running the code we check if we can access localStorage, if not we opt-out
            if (!localStorage) {
                try {
                    globals_1.window.localStorage.setItem('test', 'test');
                    globals_1.window.localStorage.removeItem('test');
                }
                catch (_a) {
                    return false;
                }
                // If localStorage was undefined, and localStorage is supported we set the default value
                localStorage = globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.localStorage;
            }
            /**
             * Info about the state
             * The state is a json object
             * 1. (Legacy) The state can be `state={}` as a urlencoded object of info. In this case
             * 2. The state should now be found in `__posthog={}` and can be base64 encoded or urlencoded.
             * 3. Base64 encoding is preferred and will gradually be rolled out everywhere
             */
            var stateHash_1 = STATE_FROM_WINDOW || (0, request_utils_1._getHashParam)(location.hash, '__posthog') || (0, request_utils_1._getHashParam)(location.hash, 'state');
            var toolbarParams = void 0;
            var state = stateHash_1
                ? (0, utils_1.trySafe)(function () { return JSON.parse(atob(decodeURIComponent(stateHash_1))); }) ||
                    (0, utils_1.trySafe)(function () { return JSON.parse(decodeURIComponent(stateHash_1)); })
                : null;
            var parseFromUrl = state && state['action'] === 'ph_authorize';
            if (parseFromUrl) {
                // happens if they are initializing the toolbar using an old snippet
                toolbarParams = state;
                toolbarParams.source = 'url';
                if (toolbarParams && Object.keys(toolbarParams).length > 0) {
                    if (state['desiredHash']) {
                        // hash that was in the url before the redirect
                        location.hash = state['desiredHash'];
                    }
                    else if (history) {
                        // second param is unused see https://developer.mozilla.org/en-US/docs/Web/API/History/replaceState
                        history.replaceState(history.state, '', location.pathname + location.search); // completely remove hash
                    }
                    else {
                        location.hash = ''; // clear hash (but leaves # unfortunately)
                    }
                }
            }
            else {
                // get credentials from localStorage from a previous initialization
                toolbarParams = JSON.parse(localStorage.getItem(LOCALSTORAGE_KEY) || '{}');
                toolbarParams.source = 'localstorage';
                // delete "add-action" or other intent from toolbarParams, otherwise we'll have the same intent
                // every time we open the page (e.g. you just visiting your own site an hour later)
                delete toolbarParams.userIntent;
            }
            if (toolbarParams['token'] && this.instance.config.token === toolbarParams['token']) {
                this.loadToolbar(toolbarParams);
                return true;
            }
            else {
                return false;
            }
        }
        catch (_b) {
            return false;
        }
    };
    Toolbar.prototype._callLoadToolbar = function (params) {
        var loadFn = globals_1.assignableWindow['ph_load_toolbar'] || globals_1.assignableWindow['ph_load_editor'];
        if ((0, core_1.isNullish)(loadFn) || !(0, core_1.isFunction)(loadFn)) {
            logger.warn('No toolbar load function found');
            return;
        }
        loadFn(params, this.instance);
    };
    Toolbar.prototype.loadToolbar = function (params) {
        var _this = this;
        var _a, _b;
        var toolbarRunning = !!(globals_1.document === null || globals_1.document === void 0 ? void 0 : globals_1.document.getElementById(constants_1.TOOLBAR_ID));
        if (!globals_1.window || toolbarRunning) {
            // The toolbar will clear the localStorage key when it's done with it. If it is present that indicates the toolbar is already open and running
            return false;
        }
        var disableToolbarMetrics = this.instance.requestRouter.region === 'custom' && this.instance.config.advanced_disable_toolbar_metrics;
        var toolbarParams = __assign(__assign(__assign({ token: this.instance.config.token }, params), { apiURL: this.instance.requestRouter.endpointFor('ui') }), (disableToolbarMetrics ? { instrument: false } : {}));
        globals_1.window.localStorage.setItem(LOCALSTORAGE_KEY, JSON.stringify(__assign(__assign({}, toolbarParams), { source: undefined })));
        if (this._getToolbarState() === ToolbarState.LOADED) {
            this._callLoadToolbar(toolbarParams);
        }
        else if (this._getToolbarState() === ToolbarState.UNINITIALIZED) {
            // only load the toolbar once, even if there are multiple instances of PostHogLib
            this._setToolbarState(ToolbarState.LOADING);
            (_b = (_a = globals_1.assignableWindow.__PosthogExtensions__) === null || _a === void 0 ? void 0 : _a.loadExternalDependency) === null || _b === void 0 ? void 0 : _b.call(_a, this.instance, 'toolbar', function (err) {
                if (err) {
                    logger.error('[Toolbar] Failed to load', err);
                    _this._setToolbarState(ToolbarState.UNINITIALIZED);
                    return;
                }
                _this._setToolbarState(ToolbarState.LOADED);
                _this._callLoadToolbar(toolbarParams);
            });
            // Turbolinks doesn't fire an onload event but does replace the entire body, including the toolbar.
            // Thus, we ensure the toolbar is only loaded inside the body, and then reloaded on turbolinks:load.
            (0, utils_1.addEventListener)(globals_1.window, 'turbolinks:load', function () {
                _this._setToolbarState(ToolbarState.UNINITIALIZED);
                _this.loadToolbar(toolbarParams);
            });
        }
        return true;
    };
    /** @deprecated Use "loadToolbar" instead. */
    Toolbar.prototype._loadEditor = function (params) {
        return this.loadToolbar(params);
    };
    /** @deprecated Use "maybeLoadToolbar" instead. */
    Toolbar.prototype.maybeLoadEditor = function (location, localStorage, history) {
        if (location === void 0) { location = undefined; }
        if (localStorage === void 0) { localStorage = undefined; }
        if (history === void 0) { history = undefined; }
        return this.maybeLoadToolbar(location, localStorage, history);
    };
    return Toolbar;
}());
exports.Toolbar = Toolbar;
//# sourceMappingURL=toolbar.js.map