"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PageViewManager = void 0;
var globals_1 = require("./utils/globals");
var core_1 = require("@posthog/core");
var utils_1 = require("./utils");
var logger_1 = require("./utils/logger");
// This keeps track of the PageView state (such as the previous PageView's path, timestamp, id, and scroll properties).
// We store the state in memory, which means that for non-SPA sites, the state will be lost on page reload. This means
// that non-SPA sites should always send a $pageleave event on any navigation, before the page unloads. For SPA sites,
// they only need to send a $pageleave event when the user navigates away from the site, as the information is not lost
// on an internal navigation, and is included as the $prev_pageview_ properties in the next $pageview event.
// Practically, this means that to find the scroll properties for a given pageview, you need to find the event where
// event name is $pageview or $pageleave and where $prev_pageview_id matches the original pageview event's id.
var PageViewManager = /** @class */ (function () {
    function PageViewManager(instance) {
        this._instance = instance;
    }
    PageViewManager.prototype.doPageView = function (timestamp, pageViewId) {
        var _a;
        var response = this._previousPageViewProperties(timestamp, pageViewId);
        // On a pageview we reset the contexts
        this._currentPageview = { pathname: (_a = globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.location.pathname) !== null && _a !== void 0 ? _a : '', pageViewId: pageViewId, timestamp: timestamp };
        this._instance.scrollManager.resetContext();
        return response;
    };
    PageViewManager.prototype.doPageLeave = function (timestamp) {
        var _a;
        return this._previousPageViewProperties(timestamp, (_a = this._currentPageview) === null || _a === void 0 ? void 0 : _a.pageViewId);
    };
    PageViewManager.prototype.doEvent = function () {
        var _a;
        return { $pageview_id: (_a = this._currentPageview) === null || _a === void 0 ? void 0 : _a.pageViewId };
    };
    PageViewManager.prototype._previousPageViewProperties = function (timestamp, pageviewId) {
        var previousPageView = this._currentPageview;
        if (!previousPageView) {
            return { $pageview_id: pageviewId };
        }
        var properties = {
            $pageview_id: pageviewId,
            $prev_pageview_id: previousPageView.pageViewId,
        };
        var scrollContext = this._instance.scrollManager.getContext();
        if (scrollContext && !this._instance.config.disable_scroll_properties) {
            var maxScrollHeight = scrollContext.maxScrollHeight, lastScrollY = scrollContext.lastScrollY, maxScrollY = scrollContext.maxScrollY, maxContentHeight = scrollContext.maxContentHeight, lastContentY = scrollContext.lastContentY, maxContentY = scrollContext.maxContentY;
            if (!(0, core_1.isUndefined)(maxScrollHeight) &&
                !(0, core_1.isUndefined)(lastScrollY) &&
                !(0, core_1.isUndefined)(maxScrollY) &&
                !(0, core_1.isUndefined)(maxContentHeight) &&
                !(0, core_1.isUndefined)(lastContentY) &&
                !(0, core_1.isUndefined)(maxContentY)) {
                // Use ceil, so that e.g. scrolling 999.5px of a 1000px page is considered 100% scrolled
                maxScrollHeight = Math.ceil(maxScrollHeight);
                lastScrollY = Math.ceil(lastScrollY);
                maxScrollY = Math.ceil(maxScrollY);
                maxContentHeight = Math.ceil(maxContentHeight);
                lastContentY = Math.ceil(lastContentY);
                maxContentY = Math.ceil(maxContentY);
                // if the maximum scroll height is near 0, then the percentage is 1
                var lastScrollPercentage = maxScrollHeight <= 1 ? 1 : (0, core_1.clampToRange)(lastScrollY / maxScrollHeight, 0, 1, logger_1.logger);
                var maxScrollPercentage = maxScrollHeight <= 1 ? 1 : (0, core_1.clampToRange)(maxScrollY / maxScrollHeight, 0, 1, logger_1.logger);
                var lastContentPercentage = maxContentHeight <= 1 ? 1 : (0, core_1.clampToRange)(lastContentY / maxContentHeight, 0, 1, logger_1.logger);
                var maxContentPercentage = maxContentHeight <= 1 ? 1 : (0, core_1.clampToRange)(maxContentY / maxContentHeight, 0, 1, logger_1.logger);
                properties = (0, utils_1.extend)(properties, {
                    $prev_pageview_last_scroll: lastScrollY,
                    $prev_pageview_last_scroll_percentage: lastScrollPercentage,
                    $prev_pageview_max_scroll: maxScrollY,
                    $prev_pageview_max_scroll_percentage: maxScrollPercentage,
                    $prev_pageview_last_content: lastContentY,
                    $prev_pageview_last_content_percentage: lastContentPercentage,
                    $prev_pageview_max_content: maxContentY,
                    $prev_pageview_max_content_percentage: maxContentPercentage,
                });
            }
        }
        if (previousPageView.pathname) {
            properties.$prev_pageview_pathname = previousPageView.pathname;
        }
        if (previousPageView.timestamp) {
            // Use seconds, for consistency with our other duration-related properties like $duration
            properties.$prev_pageview_duration = (timestamp.getTime() - previousPageView.timestamp.getTime()) / 1000;
        }
        return properties;
    };
    return PageViewManager;
}());
exports.PageViewManager = PageViewManager;
//# sourceMappingURL=page-view.js.map