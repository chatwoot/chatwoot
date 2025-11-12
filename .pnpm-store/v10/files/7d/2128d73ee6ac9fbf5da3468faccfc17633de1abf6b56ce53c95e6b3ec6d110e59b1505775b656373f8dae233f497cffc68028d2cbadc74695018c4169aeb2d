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
Object.defineProperty(exports, "__esModule", { value: true });
var globals_1 = require("../utils/globals");
var core_1 = require("@posthog/core");
var autocapture_utils_1 = require("../autocapture-utils");
var autocapture_1 = require("../autocapture");
var element_utils_1 = require("../utils/element-utils");
var prototype_utils_1 = require("../utils/prototype-utils");
var utils_1 = require("../utils");
function asClick(event) {
    var eventTarget = (0, autocapture_utils_1.getEventTarget)(event);
    if (eventTarget) {
        return {
            node: eventTarget,
            originalEvent: event,
            timestamp: Date.now(),
        };
    }
    return null;
}
function checkTimeout(value, thresholdMs) {
    return (0, core_1.isNumber)(value) && value >= thresholdMs;
}
var LazyLoadedDeadClicksAutocapture = /** @class */ (function () {
    function LazyLoadedDeadClicksAutocapture(instance, config) {
        var _this = this;
        this.instance = instance;
        this._clicks = [];
        this._defaultConfig = function (defaultOnCapture) { return ({
            element_attribute_ignorelist: [],
            scroll_threshold_ms: 100,
            selection_change_threshold_ms: 100,
            mutation_threshold_ms: 2500,
            __onCapture: defaultOnCapture,
        }); };
        this._onClick = function (event) {
            var click = asClick(event);
            if (!(0, core_1.isNull)(click) && !_this._ignoreClick(click)) {
                _this._clicks.push(click);
            }
            if (_this._clicks.length && (0, core_1.isUndefined)(_this._checkClickTimer)) {
                _this._checkClickTimer = globals_1.assignableWindow.setTimeout(function () {
                    _this._checkClicks();
                }, 1000);
            }
        };
        this._onScroll = function () {
            var candidateNow = Date.now();
            // very naive throttle
            if (candidateNow % 50 === 0) {
                // we can see many scrolls between scheduled checks,
                // so we update scroll delay as we see them
                // to avoid false positives
                _this._clicks.forEach(function (click) {
                    if ((0, core_1.isUndefined)(click.scrollDelayMs)) {
                        click.scrollDelayMs = candidateNow - click.timestamp;
                    }
                });
            }
        };
        this._onSelectionChange = function () {
            _this._lastSelectionChanged = Date.now();
        };
        this._config = this._asRequiredConfig(config);
        this._onCapture = this._config.__onCapture;
    }
    LazyLoadedDeadClicksAutocapture.prototype._asRequiredConfig = function (providedConfig) {
        var _a, _b, _c, _d;
        var defaultConfig = this._defaultConfig((providedConfig === null || providedConfig === void 0 ? void 0 : providedConfig.__onCapture) || this._captureDeadClick.bind(this));
        return {
            element_attribute_ignorelist: (_a = providedConfig === null || providedConfig === void 0 ? void 0 : providedConfig.element_attribute_ignorelist) !== null && _a !== void 0 ? _a : defaultConfig.element_attribute_ignorelist,
            scroll_threshold_ms: (_b = providedConfig === null || providedConfig === void 0 ? void 0 : providedConfig.scroll_threshold_ms) !== null && _b !== void 0 ? _b : defaultConfig.scroll_threshold_ms,
            selection_change_threshold_ms: (_c = providedConfig === null || providedConfig === void 0 ? void 0 : providedConfig.selection_change_threshold_ms) !== null && _c !== void 0 ? _c : defaultConfig.selection_change_threshold_ms,
            mutation_threshold_ms: (_d = providedConfig === null || providedConfig === void 0 ? void 0 : providedConfig.mutation_threshold_ms) !== null && _d !== void 0 ? _d : defaultConfig.mutation_threshold_ms,
            __onCapture: defaultConfig.__onCapture,
        };
    };
    LazyLoadedDeadClicksAutocapture.prototype.start = function (observerTarget) {
        this._startClickObserver();
        this._startScrollObserver();
        this._startSelectionChangedObserver();
        this._startMutationObserver(observerTarget);
    };
    LazyLoadedDeadClicksAutocapture.prototype._startMutationObserver = function (observerTarget) {
        var _this = this;
        if (!this._mutationObserver) {
            var NativeMutationObserver = (0, prototype_utils_1.getNativeMutationObserverImplementation)(globals_1.assignableWindow);
            this._mutationObserver = new NativeMutationObserver(function (mutations) {
                _this._onMutation(mutations);
            });
            this._mutationObserver.observe(observerTarget, {
                attributes: true,
                characterData: true,
                childList: true,
                subtree: true,
            });
        }
    };
    LazyLoadedDeadClicksAutocapture.prototype.stop = function () {
        var _a;
        (_a = this._mutationObserver) === null || _a === void 0 ? void 0 : _a.disconnect();
        this._mutationObserver = undefined;
        globals_1.assignableWindow.removeEventListener('click', this._onClick);
        globals_1.assignableWindow.removeEventListener('scroll', this._onScroll, { capture: true });
        globals_1.assignableWindow.removeEventListener('selectionchange', this._onSelectionChange);
    };
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    LazyLoadedDeadClicksAutocapture.prototype._onMutation = function (_mutations) {
        // we don't actually care about the content of the mutations, right now
        this._lastMutation = Date.now();
    };
    LazyLoadedDeadClicksAutocapture.prototype._startClickObserver = function () {
        (0, utils_1.addEventListener)(globals_1.assignableWindow, 'click', this._onClick);
    };
    // `capture: true` is required to get scroll events for other scrollable elements
    // on the page, not just the window
    // see https://developer.mozilla.org/en-US/docs/Web/API/EventTarget/addEventListener#usecapture
    //
    // `passive: true` is used to tell the browser that the scroll event handler will not call `preventDefault()`
    // This allows the browser to optimize scrolling performance by not waiting for our handling of the scroll event
    // see https://developer.mozilla.org/en-US/docs/Web/API/EventTarget/addEventListener#passive
    LazyLoadedDeadClicksAutocapture.prototype._startScrollObserver = function () {
        (0, utils_1.addEventListener)(globals_1.assignableWindow, 'scroll', this._onScroll, { capture: true });
    };
    LazyLoadedDeadClicksAutocapture.prototype._startSelectionChangedObserver = function () {
        (0, utils_1.addEventListener)(globals_1.assignableWindow, 'selectionchange', this._onSelectionChange);
    };
    LazyLoadedDeadClicksAutocapture.prototype._ignoreClick = function (click) {
        if (!click) {
            return true;
        }
        if ((0, element_utils_1.isElementInToolbar)(click.node)) {
            return true;
        }
        var alreadyClickedInLastSecond = this._clicks.some(function (c) {
            return c.node === click.node && Math.abs(c.timestamp - click.timestamp) < 1000;
        });
        if (alreadyClickedInLastSecond) {
            return true;
        }
        if ((0, element_utils_1.isTag)(click.node, 'html') ||
            !(0, element_utils_1.isElementNode)(click.node) ||
            autocapture_utils_1.autocaptureCompatibleElements.includes(click.node.tagName.toLowerCase())) {
            return true;
        }
        return false;
    };
    LazyLoadedDeadClicksAutocapture.prototype._checkClicks = function () {
        var e_1, _a;
        var _this = this;
        var _b;
        if (!this._clicks.length) {
            return;
        }
        clearTimeout(this._checkClickTimer);
        this._checkClickTimer = undefined;
        var clicksToCheck = this._clicks;
        this._clicks = [];
        try {
            for (var clicksToCheck_1 = __values(clicksToCheck), clicksToCheck_1_1 = clicksToCheck_1.next(); !clicksToCheck_1_1.done; clicksToCheck_1_1 = clicksToCheck_1.next()) {
                var click = clicksToCheck_1_1.value;
                click.mutationDelayMs =
                    (_b = click.mutationDelayMs) !== null && _b !== void 0 ? _b : (this._lastMutation && click.timestamp <= this._lastMutation
                        ? this._lastMutation - click.timestamp
                        : undefined);
                click.absoluteDelayMs = Date.now() - click.timestamp;
                click.selectionChangedDelayMs =
                    this._lastSelectionChanged && click.timestamp <= this._lastSelectionChanged
                        ? this._lastSelectionChanged - click.timestamp
                        : undefined;
                var scrollTimeout = checkTimeout(click.scrollDelayMs, this._config.scroll_threshold_ms);
                var selectionChangedTimeout = checkTimeout(click.selectionChangedDelayMs, this._config.selection_change_threshold_ms);
                var mutationTimeout = checkTimeout(click.mutationDelayMs, this._config.mutation_threshold_ms);
                // we want to timeout eventually even if nothing else catches it...
                // we leave a little longer than the maximum threshold to give the other checks a chance to catch it
                var absoluteTimeout = checkTimeout(click.absoluteDelayMs, this._config.mutation_threshold_ms * 1.1);
                var hadScroll = (0, core_1.isNumber)(click.scrollDelayMs) && click.scrollDelayMs < this._config.scroll_threshold_ms;
                var hadMutation = (0, core_1.isNumber)(click.mutationDelayMs) && click.mutationDelayMs < this._config.mutation_threshold_ms;
                var hadSelectionChange = (0, core_1.isNumber)(click.selectionChangedDelayMs) &&
                    click.selectionChangedDelayMs < this._config.selection_change_threshold_ms;
                if (hadScroll || hadMutation || hadSelectionChange) {
                    // ignore clicks that had a scroll or mutation
                    continue;
                }
                if (scrollTimeout || mutationTimeout || absoluteTimeout || selectionChangedTimeout) {
                    this._onCapture(click, {
                        $dead_click_last_mutation_timestamp: this._lastMutation,
                        $dead_click_event_timestamp: click.timestamp,
                        $dead_click_scroll_timeout: scrollTimeout,
                        $dead_click_mutation_timeout: mutationTimeout,
                        $dead_click_absolute_timeout: absoluteTimeout,
                        $dead_click_selection_changed_timeout: selectionChangedTimeout,
                    });
                }
                else if (click.absoluteDelayMs < this._config.mutation_threshold_ms) {
                    // keep waiting until next check
                    this._clicks.push(click);
                }
            }
        }
        catch (e_1_1) { e_1 = { error: e_1_1 }; }
        finally {
            try {
                if (clicksToCheck_1_1 && !clicksToCheck_1_1.done && (_a = clicksToCheck_1.return)) _a.call(clicksToCheck_1);
            }
            finally { if (e_1) throw e_1.error; }
        }
        if (this._clicks.length && (0, core_1.isUndefined)(this._checkClickTimer)) {
            this._checkClickTimer = globals_1.assignableWindow.setTimeout(function () {
                _this._checkClicks();
            }, 1000);
        }
    };
    LazyLoadedDeadClicksAutocapture.prototype._captureDeadClick = function (click, properties) {
        // TODO need to check safe and captur-able as with autocapture
        // TODO autocaputure config
        this.instance.capture('$dead_click', __assign(__assign(__assign({}, properties), (0, autocapture_1.autocapturePropertiesForElement)(click.node, {
            e: click.originalEvent,
            maskAllElementAttributes: this.instance.config.mask_all_element_attributes,
            maskAllText: this.instance.config.mask_all_text,
            elementAttributeIgnoreList: this._config.element_attribute_ignorelist,
            // TRICKY: it appears that we were moving to elementsChainAsString, but the UI still depends on elements, so :shrug:
            elementsChainAsString: false,
        }).props), { $dead_click_scroll_delay_ms: click.scrollDelayMs, $dead_click_mutation_delay_ms: click.mutationDelayMs, $dead_click_absolute_delay_ms: click.absoluteDelayMs, $dead_click_selection_changed_delay_ms: click.selectionChangedDelayMs }), {
            timestamp: new Date(click.timestamp),
        });
    };
    return LazyLoadedDeadClicksAutocapture;
}());
globals_1.assignableWindow.__PosthogExtensions__ = globals_1.assignableWindow.__PosthogExtensions__ || {};
globals_1.assignableWindow.__PosthogExtensions__.initDeadClicksAutocapture = function (ph, config) {
    return new LazyLoadedDeadClicksAutocapture(ph, config);
};
exports.default = LazyLoadedDeadClicksAutocapture;
//# sourceMappingURL=dead-clicks-autocapture.js.map