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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Heatmaps = void 0;
var rageclick_1 = __importDefault(require("./extensions/rageclick"));
var globals_1 = require("./utils/globals");
var autocapture_utils_1 = require("./autocapture-utils");
var constants_1 = require("./constants");
var core_1 = require("@posthog/core");
var logger_1 = require("./utils/logger");
var element_utils_1 = require("./utils/element-utils");
var dead_clicks_autocapture_1 = require("./extensions/dead-clicks-autocapture");
var core_2 = require("@posthog/core");
var utils_1 = require("./utils");
var DEFAULT_FLUSH_INTERVAL = 5000;
var logger = (0, logger_1.createLogger)('[Heatmaps]');
function elementOrParentPositionMatches(el, matches, breakOnElement) {
    var curEl = el;
    while (curEl && (0, element_utils_1.isElementNode)(curEl) && !(0, element_utils_1.isTag)(curEl, 'body')) {
        if (curEl === breakOnElement) {
            return false;
        }
        if ((0, core_2.includes)(matches, globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.getComputedStyle(curEl).position)) {
            return true;
        }
        curEl = (0, autocapture_utils_1.getParentElement)(curEl);
    }
    return false;
}
function isValidMouseEvent(e) {
    return (0, core_1.isObject)(e) && 'clientX' in e && 'clientY' in e && (0, core_1.isNumber)(e.clientX) && (0, core_1.isNumber)(e.clientY);
}
var Heatmaps = /** @class */ (function () {
    function Heatmaps(instance) {
        var _a;
        this.rageclicks = new rageclick_1.default();
        this._enabledServerSide = false;
        this._initialized = false;
        this._flushInterval = null;
        this.instance = instance;
        this._enabledServerSide = !!((_a = this.instance.persistence) === null || _a === void 0 ? void 0 : _a.props[constants_1.HEATMAPS_ENABLED_SERVER_SIDE]);
    }
    Object.defineProperty(Heatmaps.prototype, "flushIntervalMilliseconds", {
        get: function () {
            var flushInterval = DEFAULT_FLUSH_INTERVAL;
            if ((0, core_1.isObject)(this.instance.config.capture_heatmaps) &&
                this.instance.config.capture_heatmaps.flush_interval_milliseconds) {
                flushInterval = this.instance.config.capture_heatmaps.flush_interval_milliseconds;
            }
            return flushInterval;
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(Heatmaps.prototype, "isEnabled", {
        get: function () {
            if (!(0, core_1.isUndefined)(this.instance.config.capture_heatmaps)) {
                return this.instance.config.capture_heatmaps !== false;
            }
            if (!(0, core_1.isUndefined)(this.instance.config.enable_heatmaps)) {
                return this.instance.config.enable_heatmaps;
            }
            return this._enabledServerSide;
        },
        enumerable: false,
        configurable: true
    });
    Heatmaps.prototype.startIfEnabled = function () {
        var _a, _b;
        if (this.isEnabled) {
            // nested if here since we only want to run the else
            // if this.enabled === false
            // not if this method is called more than once
            if (this._initialized) {
                return;
            }
            logger.info('starting...');
            this._setupListeners();
            this._flushInterval = setInterval(this._flush.bind(this), this.flushIntervalMilliseconds);
        }
        else {
            clearInterval((_a = this._flushInterval) !== null && _a !== void 0 ? _a : undefined);
            (_b = this._deadClicksCapture) === null || _b === void 0 ? void 0 : _b.stop();
            this.getAndClearBuffer();
        }
    };
    Heatmaps.prototype.onRemoteConfig = function (response) {
        var _a;
        var optIn = !!response['heatmaps'];
        if (this.instance.persistence) {
            this.instance.persistence.register((_a = {},
                _a[constants_1.HEATMAPS_ENABLED_SERVER_SIDE] = optIn,
                _a));
        }
        // store this in-memory in case persistence is disabled
        this._enabledServerSide = optIn;
        this.startIfEnabled();
    };
    Heatmaps.prototype.getAndClearBuffer = function () {
        var buffer = this._buffer;
        this._buffer = undefined;
        return buffer;
    };
    Heatmaps.prototype._onDeadClick = function (click) {
        this._onClick(click.originalEvent, 'deadclick');
    };
    Heatmaps.prototype._setupListeners = function () {
        var _this = this;
        if (!globals_1.window || !globals_1.document) {
            return;
        }
        (0, utils_1.addEventListener)(globals_1.window, 'beforeunload', this._flush.bind(this));
        (0, utils_1.addEventListener)(globals_1.document, 'click', function (e) { return _this._onClick((e || (globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.event))); }, { capture: true });
        (0, utils_1.addEventListener)(globals_1.document, 'mousemove', function (e) { return _this._onMouseMove((e || (globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.event))); }, {
            capture: true,
        });
        this._deadClicksCapture = new dead_clicks_autocapture_1.DeadClicksAutocapture(this.instance, dead_clicks_autocapture_1.isDeadClicksEnabledForHeatmaps, this._onDeadClick.bind(this));
        this._deadClicksCapture.startIfEnabled();
        this._initialized = true;
    };
    Heatmaps.prototype._getProperties = function (e, type) {
        // We need to know if the target element is fixed or not
        // If fixed then we won't account for scrolling
        // If not then we will account for scrolling
        var scrollY = this.instance.scrollManager.scrollY();
        var scrollX = this.instance.scrollManager.scrollX();
        var scrollElement = this.instance.scrollManager.scrollElement();
        var isFixedOrSticky = elementOrParentPositionMatches((0, autocapture_utils_1.getEventTarget)(e), ['fixed', 'sticky'], scrollElement);
        return {
            x: e.clientX + (isFixedOrSticky ? 0 : scrollX),
            y: e.clientY + (isFixedOrSticky ? 0 : scrollY),
            target_fixed: isFixedOrSticky,
            type: type,
        };
    };
    Heatmaps.prototype._onClick = function (e, type) {
        var _a;
        if (type === void 0) { type = 'click'; }
        if ((0, element_utils_1.isElementInToolbar)(e.target) || !isValidMouseEvent(e)) {
            return;
        }
        var properties = this._getProperties(e, type);
        if ((_a = this.rageclicks) === null || _a === void 0 ? void 0 : _a.isRageClick(e.clientX, e.clientY, new Date().getTime())) {
            this._capture(__assign(__assign({}, properties), { type: 'rageclick' }));
        }
        this._capture(properties);
    };
    Heatmaps.prototype._onMouseMove = function (e) {
        var _this = this;
        if ((0, element_utils_1.isElementInToolbar)(e.target) || !isValidMouseEvent(e)) {
            return;
        }
        clearTimeout(this._mouseMoveTimeout);
        this._mouseMoveTimeout = setTimeout(function () {
            _this._capture(_this._getProperties(e, 'mousemove'));
        }, 500);
    };
    Heatmaps.prototype._capture = function (properties) {
        if (!globals_1.window) {
            return;
        }
        // TODO we should be able to mask this
        var url = globals_1.window.location.href;
        this._buffer = this._buffer || {};
        if (!this._buffer[url]) {
            this._buffer[url] = [];
        }
        this._buffer[url].push(properties);
    };
    Heatmaps.prototype._flush = function () {
        if (!this._buffer || (0, core_1.isEmptyObject)(this._buffer)) {
            return;
        }
        this.instance.capture('$$heatmap', {
            $heatmap_data: this.getAndClearBuffer(),
        });
    };
    return Heatmaps;
}());
exports.Heatmaps = Heatmaps;
//# sourceMappingURL=heatmaps.js.map