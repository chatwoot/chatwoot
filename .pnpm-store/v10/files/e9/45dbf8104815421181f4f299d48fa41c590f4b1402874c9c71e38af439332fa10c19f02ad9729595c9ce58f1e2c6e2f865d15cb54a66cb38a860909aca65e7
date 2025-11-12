"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var attribution_1 = require("web-vitals/attribution");
var globals_1 = require("../utils/globals");
var postHogWebVitalsCallbacks = {
    onLCP: attribution_1.onLCP,
    onCLS: attribution_1.onCLS,
    onFCP: attribution_1.onFCP,
    onINP: attribution_1.onINP,
};
globals_1.assignableWindow.__PosthogExtensions__ = globals_1.assignableWindow.__PosthogExtensions__ || {};
globals_1.assignableWindow.__PosthogExtensions__.postHogWebVitalsCallbacks = postHogWebVitalsCallbacks;
// we used to put posthogWebVitalsCallbacks on window, and now we put it on __PosthogExtensions__
// but that means that old clients which lazily load this extension are looking in the wrong place
// yuck,
// so we also put it directly on the window
// when 1.161.1 is the oldest version seen in production we can remove this
globals_1.assignableWindow.postHogWebVitalsCallbacks = postHogWebVitalsCallbacks;
exports.default = postHogWebVitalsCallbacks;
//# sourceMappingURL=web-vitals.js.map