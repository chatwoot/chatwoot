import { __awaiter, __generator } from "tslib";
import { isServer } from '../../core/environment';
import { loadScript } from '../../lib/load-script';
import { getNextIntegrationsURL } from '../../lib/parse-cdn';
export function remoteMiddlewares(ctx, settings, obfuscate) {
    var _a;
    return __awaiter(this, void 0, void 0, function () {
        var path, remoteMiddleware, names, scripts, middleware;
        var _this = this;
        return __generator(this, function (_b) {
            switch (_b.label) {
                case 0:
                    if (isServer()) {
                        return [2 /*return*/, []];
                    }
                    path = getNextIntegrationsURL();
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
                    scripts = names.map(function (name) { return __awaiter(_this, void 0, void 0, function () {
                        var nonNamespaced, bundleName, fullPath, error_1;
                        return __generator(this, function (_a) {
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
                                    return [4 /*yield*/, loadScript(fullPath)
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
//# sourceMappingURL=index.js.map