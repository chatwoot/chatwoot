"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.resolveVersion = exports.unloadIntegration = exports.loadIntegration = exports.buildIntegration = exports.resolveIntegrationNameFromSource = void 0;
var tslib_1 = require("tslib");
var parse_cdn_1 = require("../../lib/parse-cdn");
var load_script_1 = require("../../lib/load-script");
function normalizeName(name) {
    return name.toLowerCase().replace('.', '').replace(/\s+/g, '-');
}
function obfuscatePathName(pathName, obfuscate) {
    if (obfuscate === void 0) { obfuscate = false; }
    return obfuscate ? btoa(pathName).replace(/=/g, '') : undefined;
}
function resolveIntegrationNameFromSource(integrationSource) {
    return ('Integration' in integrationSource
        ? integrationSource.Integration
        : integrationSource).prototype.name;
}
exports.resolveIntegrationNameFromSource = resolveIntegrationNameFromSource;
function recordLoadMetrics(fullPath, ctx, name) {
    var _a, _b;
    try {
        var metric = ((_b = (_a = window === null || window === void 0 ? void 0 : window.performance) === null || _a === void 0 ? void 0 : _a.getEntriesByName(fullPath, 'resource')) !== null && _b !== void 0 ? _b : [])[0];
        // we assume everything that took under 100ms is cached
        metric &&
            ctx.stats.gauge('legacy_destination_time', Math.round(metric.duration), tslib_1.__spreadArray([
                name
            ], (metric.duration < 100 ? ['cached'] : []), true));
    }
    catch (_) {
        // not available
    }
}
function buildIntegration(integrationSource, integrationSettings, analyticsInstance) {
    var integrationCtr;
    // GA and Appcues use a different interface to instantiating integrations
    if ('Integration' in integrationSource) {
        var analyticsStub = {
            user: function () { return analyticsInstance.user(); },
            addIntegration: function () { },
        };
        integrationSource(analyticsStub);
        integrationCtr = integrationSource.Integration;
    }
    else {
        integrationCtr = integrationSource;
    }
    var integration = new integrationCtr(integrationSettings);
    integration.analytics = analyticsInstance;
    return integration;
}
exports.buildIntegration = buildIntegration;
function loadIntegration(ctx, name, version, obfuscate) {
    return tslib_1.__awaiter(this, void 0, void 0, function () {
        var pathName, obfuscatedPathName, path, fullPath, err_1, deps;
        return tslib_1.__generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    pathName = normalizeName(name);
                    obfuscatedPathName = obfuscatePathName(pathName, obfuscate);
                    path = (0, parse_cdn_1.getNextIntegrationsURL)();
                    fullPath = "".concat(path, "/integrations/").concat(obfuscatedPathName !== null && obfuscatedPathName !== void 0 ? obfuscatedPathName : pathName, "/").concat(version, "/").concat(obfuscatedPathName !== null && obfuscatedPathName !== void 0 ? obfuscatedPathName : pathName, ".dynamic.js.gz");
                    _a.label = 1;
                case 1:
                    _a.trys.push([1, 3, , 4]);
                    return [4 /*yield*/, (0, load_script_1.loadScript)(fullPath)];
                case 2:
                    _a.sent();
                    recordLoadMetrics(fullPath, ctx, name);
                    return [3 /*break*/, 4];
                case 3:
                    err_1 = _a.sent();
                    ctx.stats.gauge('legacy_destination_time', -1, ["plugin:".concat(name), "failed"]);
                    throw err_1;
                case 4:
                    deps = window["".concat(pathName, "Deps")];
                    return [4 /*yield*/, Promise.all(deps.map(function (dep) { return (0, load_script_1.loadScript)(path + dep + '.gz'); }))
                        // @ts-ignore
                    ];
                case 5:
                    _a.sent();
                    // @ts-ignore
                    window["".concat(pathName, "Loader")]();
                    return [2 /*return*/, window[
                        // @ts-ignore
                        "".concat(pathName, "Integration")]];
            }
        });
    });
}
exports.loadIntegration = loadIntegration;
function unloadIntegration(name, version, obfuscate) {
    return tslib_1.__awaiter(this, void 0, void 0, function () {
        var path, pathName, obfuscatedPathName, fullPath;
        return tslib_1.__generator(this, function (_a) {
            path = (0, parse_cdn_1.getNextIntegrationsURL)();
            pathName = normalizeName(name);
            obfuscatedPathName = obfuscatePathName(name, obfuscate);
            fullPath = "".concat(path, "/integrations/").concat(obfuscatedPathName !== null && obfuscatedPathName !== void 0 ? obfuscatedPathName : pathName, "/").concat(version, "/").concat(obfuscatedPathName !== null && obfuscatedPathName !== void 0 ? obfuscatedPathName : pathName, ".dynamic.js.gz");
            return [2 /*return*/, (0, load_script_1.unloadScript)(fullPath)];
        });
    });
}
exports.unloadIntegration = unloadIntegration;
function resolveVersion(settings) {
    var _a, _b, _c, _d;
    return ((_d = (_b = (_a = settings === null || settings === void 0 ? void 0 : settings.versionSettings) === null || _a === void 0 ? void 0 : _a.override) !== null && _b !== void 0 ? _b : (_c = settings === null || settings === void 0 ? void 0 : settings.versionSettings) === null || _c === void 0 ? void 0 : _c.version) !== null && _d !== void 0 ? _d : 'latest');
}
exports.resolveVersion = resolveVersion;
//# sourceMappingURL=loader.js.map