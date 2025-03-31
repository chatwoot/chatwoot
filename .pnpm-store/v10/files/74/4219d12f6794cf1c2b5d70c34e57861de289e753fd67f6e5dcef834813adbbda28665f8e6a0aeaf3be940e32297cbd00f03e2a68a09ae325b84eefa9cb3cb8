import { __awaiter, __generator } from "tslib";
export function loadLegacyVideoPlugins(analytics) {
    return __awaiter(this, void 0, void 0, function () {
        var plugins;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4 /*yield*/, import(
                    // @ts-expect-error
                    '@segment/analytics.js-video-plugins/dist/index.umd.js')
                    // This is super gross, but we need to support the `window.analytics.plugins` namespace
                    // that is linked in the segment docs in order to be backwards compatible with ajs-classic
                    // @ts-expect-error
                ];
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
//# sourceMappingURL=index.js.map