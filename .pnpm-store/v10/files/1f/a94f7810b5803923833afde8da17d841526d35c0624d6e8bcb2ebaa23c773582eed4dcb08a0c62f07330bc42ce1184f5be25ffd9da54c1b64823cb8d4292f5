"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.loadLegacyVideoPlugins = void 0;
var tslib_1 = require("tslib");
function loadLegacyVideoPlugins(analytics) {
    return tslib_1.__awaiter(this, void 0, void 0, function () {
        var plugins;
        return tslib_1.__generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4 /*yield*/, Promise.resolve().then(function () { return tslib_1.__importStar(require(
                    // @ts-expect-error
                    '@segment/analytics.js-video-plugins/dist/index.umd.js')); })];
                case 1:
                    plugins = _a.sent();
                    // This is super gross, but we need to support the `window.analytics.plugins` namespace
                    // that is linked in the segment docs in order to be backwards compatible with ajs-classic
                    // @ts-expect-error
                    analytics._plugins = plugins;
                    return [2 /*return*/];
            }
        });
    });
}
exports.loadLegacyVideoPlugins = loadLegacyVideoPlugins;
//# sourceMappingURL=index.js.map