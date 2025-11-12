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
Object.defineProperty(exports, "__esModule", { value: true });
exports.ScrollManager = void 0;
var globals_1 = require("./utils/globals");
var utils_1 = require("./utils");
var core_1 = require("@posthog/core");
// This class is responsible for tracking scroll events and maintaining the scroll context
var ScrollManager = /** @class */ (function () {
    function ScrollManager(_instance) {
        var _this = this;
        this._instance = _instance;
        this._updateScrollData = function () {
            var _a, _b, _c, _d;
            if (!_this._context) {
                _this._context = {};
            }
            var el = _this.scrollElement();
            var scrollY = _this.scrollY();
            var scrollHeight = el ? Math.max(0, el.scrollHeight - el.clientHeight) : 0;
            var contentY = scrollY + ((el === null || el === void 0 ? void 0 : el.clientHeight) || 0);
            var contentHeight = (el === null || el === void 0 ? void 0 : el.scrollHeight) || 0;
            _this._context.lastScrollY = Math.ceil(scrollY);
            _this._context.maxScrollY = Math.max(scrollY, (_a = _this._context.maxScrollY) !== null && _a !== void 0 ? _a : 0);
            _this._context.maxScrollHeight = Math.max(scrollHeight, (_b = _this._context.maxScrollHeight) !== null && _b !== void 0 ? _b : 0);
            _this._context.lastContentY = contentY;
            _this._context.maxContentY = Math.max(contentY, (_c = _this._context.maxContentY) !== null && _c !== void 0 ? _c : 0);
            _this._context.maxContentHeight = Math.max(contentHeight, (_d = _this._context.maxContentHeight) !== null && _d !== void 0 ? _d : 0);
        };
    }
    ScrollManager.prototype.getContext = function () {
        return this._context;
    };
    ScrollManager.prototype.resetContext = function () {
        var ctx = this._context;
        // update the scroll properties for the new page, but wait until the next tick
        // of the event loop
        setTimeout(this._updateScrollData, 0);
        return ctx;
    };
    // `capture: true` is required to get scroll events for other scrollable elements
    // on the page, not just the window
    // see https://developer.mozilla.org/en-US/docs/Web/API/EventTarget/addEventListener#usecapture
    ScrollManager.prototype.startMeasuringScrollPosition = function () {
        (0, utils_1.addEventListener)(globals_1.window, 'scroll', this._updateScrollData, { capture: true });
        (0, utils_1.addEventListener)(globals_1.window, 'scrollend', this._updateScrollData, { capture: true });
        (0, utils_1.addEventListener)(globals_1.window, 'resize', this._updateScrollData);
    };
    ScrollManager.prototype.scrollElement = function () {
        var e_1, _a;
        if (this._instance.config.scroll_root_selector) {
            var selectors = (0, core_1.isArray)(this._instance.config.scroll_root_selector)
                ? this._instance.config.scroll_root_selector
                : [this._instance.config.scroll_root_selector];
            try {
                for (var selectors_1 = __values(selectors), selectors_1_1 = selectors_1.next(); !selectors_1_1.done; selectors_1_1 = selectors_1.next()) {
                    var selector = selectors_1_1.value;
                    var element = globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.document.querySelector(selector);
                    if (element) {
                        return element;
                    }
                }
            }
            catch (e_1_1) { e_1 = { error: e_1_1 }; }
            finally {
                try {
                    if (selectors_1_1 && !selectors_1_1.done && (_a = selectors_1.return)) _a.call(selectors_1);
                }
                finally { if (e_1) throw e_1.error; }
            }
            return undefined;
        }
        else {
            return globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.document.documentElement;
        }
    };
    ScrollManager.prototype.scrollY = function () {
        if (this._instance.config.scroll_root_selector) {
            var element = this.scrollElement();
            return (element && element.scrollTop) || 0;
        }
        else {
            return globals_1.window ? globals_1.window.scrollY || globals_1.window.pageYOffset || globals_1.window.document.documentElement.scrollTop || 0 : 0;
        }
    };
    ScrollManager.prototype.scrollX = function () {
        if (this._instance.config.scroll_root_selector) {
            var element = this.scrollElement();
            return (element && element.scrollLeft) || 0;
        }
        else {
            return globals_1.window ? globals_1.window.scrollX || globals_1.window.pageXOffset || globals_1.window.document.documentElement.scrollLeft || 0 : 0;
        }
    };
    return ScrollManager;
}());
exports.ScrollManager = ScrollManager;
//# sourceMappingURL=scroll-manager.js.map