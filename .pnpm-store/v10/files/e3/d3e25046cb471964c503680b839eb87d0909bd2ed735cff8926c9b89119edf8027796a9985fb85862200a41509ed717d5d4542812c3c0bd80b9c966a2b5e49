"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.remoteMiddlewares = void 0;
var tslib_1 = require("tslib");
var environment_1 = require("../../core/environment");
var load_script_1 = require("../../lib/load-script");
var parse_cdn_1 = require("../../lib/parse-cdn");
function remoteMiddlewares(ctx, settings, obfuscate) {
    var _a;
    return tslib_1.__awaiter(this, void 0, void 0, function () {
        var path, remoteMiddleware, names, scripts, middleware;
        var _this = this;
        return tslib_1.__generator(this, function (_b) {
            switch (_b.label) {
                case 0:
                    if ((0, environment_1.isServer)()) {
                        return [2 /*return*/, []];
                    }
                    path = (0, parse_cdn_1.getNextIntegrationsURL)();
                    remoteMiddleware = (_a = settings.enabledMiddleware) !== null && _a !== void 0 ? _a : {};
                    names = Object.entries(remoteMiddleware)
                        .filter(function (_a) {
                        var _ = _a[0], enabled = _a[1];
                        return enabled;
                    })
                        .map(function (_a) {
                        var name = _a[0];
                        return name;
                    });
                    scripts = names.map(function (name) { return tslib_1.__awaiter(_this, void 0, void 0, function () {
                        var nonNamespaced, bundleName, fullPath, error_1;
                        return tslib_1.__generator(this, function (_a) {
                            switch (_a.label) {
                                case 0:
                                    nonNamespaced = name.replace('@segment/', '');
                                    bundleName = nonNamespaced;
                                    if (obfuscate) {
                                        bundleName = btoa(nonNamespaced).replace(/=/g, '');
                                    }
                                    fullPath = "".concat(path, "/middleware/").concat(bundleName, "/latest/").concat(bundleName, ".js.gz");
                                    _a.label = 1;
                                case 1:
                                    _a.trys.push([1, 3, , 4]);
                                    return [4 /*yield*/, (0, load_script_1.loadScript)(fullPath)
                                        // @ts-ignore
                                    ];
                                case 2:
                                    _a.sent();
                                    // @ts-ignore
                                    return [2 /*return*/, window["".concat(nonNamespaced, "Middleware")]];
                                case 3:
                                    error_1 = _a.sent();
                                    ctx.log('error', error_1);
                                    ctx.stats.increment('failed_remote_middleware');
                                    return [3 /*break*/, 4];
                                case 4: return [2 /*return*/];
                            }
                        });
                    }); });
                    return [4 /*yield*/, Promise.all(scripts)];
                case 1:
                    middleware = _b.sent();
                    middleware = middleware.filter(Boolean);
                    return [2 /*return*/, middleware];
            }
        });
    });
}
exports.remoteMiddlewares = remoteMiddlewares;
//# sourceMappingURL=index.js.map